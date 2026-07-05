local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- STATES
local flying = false
local noclip = false
local espEnabled = false

local flySpeed = 60
local walkSpeed = 16

-- CHARACTER
local char, hum, root

local function bindCharacter(c)
	char = c
	hum = c:WaitForChild("Humanoid")
	root = c:WaitForChild("HumanoidRootPart")

	task.wait(0.1)
	if hum then hum.WalkSpeed = walkSpeed end
end

bindCharacter(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(bindCharacter)

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "DevPanel"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 330)
frame.Position = UDim2.new(0.1, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.Parent = gui

-- TOGGLE GUI (L)
UIS.InputBegan:Connect(function(i, gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.L then
		gui.Enabled = not gui.Enabled
	end
end)

-- DRAG
do
	local dragging, start, pos
	frame.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			start = i.Position
			pos = frame.Position
		end
	end)

	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - start
			frame.Position = UDim2.new(pos.X.Scale,pos.X.Offset+d.X,pos.Y.Scale,pos.Y.Offset+d.Y)
		end
	end)
end

-- UI HELPERS
local function button(text, y)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -20, 0, 28)
	b.Position = UDim2.new(0, 10, 0, y)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(35,35,35)
	b.TextColor3 = Color3.new(1,1,1)
	b.Parent = frame
	return b
end

local function box(ph, y)
	local t = Instance.new("TextBox")
	t.Size = UDim2.new(1, -20, 0, 25)
	t.Position = UDim2.new(0, 10, 0, y)
	t.PlaceholderText = ph
	t.Text = ""
	t.BackgroundColor3 = Color3.fromRGB(40,40,40)
	t.TextColor3 = Color3.new(1,1,1)
	t.ClearTextOnFocus = false
	t.Parent = frame
	return t
end

--------------------------------------------------
-- ESP (FIX)
--------------------------------------------------
local espFolder = Instance.new("Folder")
espFolder.Parent = gui

local espObjects = {}

local function createESP(p)
	if p == player then return end

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 120, 0, 25)
	bb.AlwaysOnTop = true
	bb.Enabled = false

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1,0,1,0)
	txt.BackgroundTransparency = 1
	txt.TextColor3 = Color3.fromRGB(255,255,255)
	txt.TextScaled = true
	txt.Text = p.Name
	txt.Parent = bb

	bb.Parent = espFolder
	espObjects[p] = bb
end

for _,p in ipairs(Players:GetPlayers()) do
	createESP(p)
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
	if espObjects[p] then
		espObjects[p]:Destroy()
		espObjects[p] = nil
	end
end)

RunService.RenderStepped:Connect(function()
	for p,bb in pairs(espObjects) do
		if espEnabled and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			bb.Adornee = p.Character.HumanoidRootPart
			bb.Enabled = true
		else
			bb.Enabled = false
		end
	end
end)

--------------------------------------------------
-- BUTTONS (ORGANIZADO)
--------------------------------------------------
button("Toggle ESP", 10).MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
end)

button("Toggle Fly", 40).MouseButton1Click:Connect(function()
	flying = not flying
	if flying then
		task.spawn(function()
			while flying do
				task.wait()
				if root and workspace.CurrentCamera then
					root.AssemblyLinearVelocity =
						workspace.CurrentCamera.CFrame.LookVector * math.clamp(flySpeed,0,700)
				end
			end
		end)
	end
end)

button("Toggle Noclip", 70).MouseButton1Click:Connect(function()
	noclip = not noclip
end)

--------------------------------------------------
-- SPEED
--------------------------------------------------
local wsBox = box("WalkSpeed", 110)
wsBox.FocusLost:Connect(function()
	walkSpeed = math.clamp(tonumber(wsBox.Text) or 16, 0, 700)
end)

local fsBox = box("FlySpeed", 150)
fsBox.FocusLost:Connect(function()
	flySpeed = math.clamp(tonumber(fsBox.Text) or 60, 0, 700)
end)

RunService.Heartbeat:Connect(function()
	if hum then
		hum.WalkSpeed = math.clamp(walkSpeed, 0, 700)
	end
end)

--------------------------------------------------
-- TP (ABREVIAÇÃO)
--------------------------------------------------
local tpBox = box("Nick / Início Nick", 200)
local tpBtn = button("Teleport", 230)

tpBtn.MouseButton1Click:Connect(function()
	local input = tpBox.Text:lower()

	local target
	for _,p in ipairs(Players:GetPlayers()) do
		local n = p.Name:lower()
		local d = p.DisplayName:lower()

		if n:sub(1,#input) == input or d:sub(1,#input) == input then
			target = p
			break
		end
	end

	if target and target.Character and root then
		local hrp = target.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			root.CFrame = hrp.CFrame + Vector3.new(0,3,0)
		end
	end
end)

--------------------------------------------------
-- NOCLIP
--------------------------------------------------
RunService.Stepped:Connect(function()
	if noclip and char then
		for _,v in ipairs(char:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end
	end
end)