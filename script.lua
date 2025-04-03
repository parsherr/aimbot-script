--[[

	Universal Aimbot Module by Exunys © CC0 1.0 Universal (2023 - 2024)
	https://github.com/Exunys

]]

--// Cache

local game, workspace = game, workspace
local getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick = getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick
local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV, Drawingnew, TweenInfonew = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV, Drawing.new, TweenInfo.new
local getupvalue, mousemoverel, tablefind, tableremove, stringlower, stringsub, mathclamp = debug.getupvalue, mousemoverel or (Input and Input.MouseMove), table.find, table.remove, string.lower, string.sub, math.clamp
local Instancenew = Instance.new

local GameMetatable = getrawmetatable and getrawmetatable(game) or {
	-- Auxillary functions - if the executor doesn't support "getrawmetatable".

	__index = function(self, Index)
		return self[Index]
	end,

	__newindex = function(self, Index, Value)
		self[Index] = Value
	end
}

local __index = GameMetatable.__index
local __newindex = GameMetatable.__newindex

local getrenderproperty, setrenderproperty = getrenderproperty or __index, setrenderproperty or __newindex

local GetService = __index(game, "GetService")

--// Services

local RunService = GetService(game, "RunService")
local UserInputService = GetService(game, "UserInputService")
local TweenService = GetService(game, "TweenService")
local Players = GetService(game, "Players")
local CoreGui = game:GetService("CoreGui")

--// Service Methods

local LocalPlayer = __index(Players, "LocalPlayer")
local Camera = __index(workspace, "CurrentCamera")

local FindFirstChild, FindFirstChildOfClass = __index(game, "FindFirstChild"), __index(game, "FindFirstChildOfClass")
local GetDescendants = __index(game, "GetDescendants")
local WorldToViewportPoint = __index(Camera, "WorldToViewportPoint")
local GetPartsObscuringTarget = __index(Camera, "GetPartsObscuringTarget")
local GetMouseLocation = __index(UserInputService, "GetMouseLocation")
local GetPlayers = __index(Players, "GetPlayers")

--// Variables

local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity = 2000, false, false, {}
local Connect, Disconnect = __index(game, "DescendantAdded").Connect

local BeamFolder = Instancenew("Folder")
BeamFolder.Name = "ESP_Beams"
BeamFolder.Parent = workspace

local ScreenBeamPart = Instancenew("Part")
ScreenBeamPart.Anchored = true
ScreenBeamPart.CanCollide = false
ScreenBeamPart.Transparency = 1
ScreenBeamPart.Size = Vector3.new(1, 1, 1)
ScreenBeamPart.Parent = BeamFolder

local GUI = {
	TeamCheckEnabled = true,
	ESPEnabled = true
}

-- Modern GUI oluşturma fonksiyonu
local function CreateModernGUI()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "ModernAimbotGUI"
	ScreenGui.Parent = CoreGui
	
	-- Ana Frame
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 250, 0, 150)
	MainFrame.Position = UDim2.new(0.8, 0, 0.5, 0)
	MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui
	
	-- Yuvarlatılmış köşeler
	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 10)
	UICorner.Parent = MainFrame
	
	-- Başlık
	local TitleBar = Instance.new("Frame")
	TitleBar.Name = "TitleBar"
	TitleBar.Size = UDim2.new(1, 0, 0, 30)
	TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	TitleBar.BorderSizePixel = 0
	TitleBar.Parent = MainFrame
	
	local TitleCorner = Instance.new("UICorner")
	TitleCorner.CornerRadius = UDim.new(0, 10)
	TitleCorner.Parent = TitleBar
	
	local TitleText = Instance.new("TextLabel")
	TitleText.Text = "Aimbot Controls"
	TitleText.Size = UDim2.new(1, 0, 1, 0)
	TitleText.BackgroundTransparency = 1
	TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	TitleText.TextSize = 16
	TitleText.Font = Enum.Font.GothamBold
	TitleText.Parent = TitleBar
	
	-- Team Check Toggle
	local TeamCheckButton = Instance.new("TextButton")
	TeamCheckButton.Name = "TeamCheckButton"
	TeamCheckButton.Size = UDim2.new(0.9, 0, 0, 35)
	TeamCheckButton.Position = UDim2.new(0.05, 0, 0.3, 0)
	TeamCheckButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	TeamCheckButton.Text = "Team Check: ON"
	TeamCheckButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	TeamCheckButton.TextSize = 14
	TeamCheckButton.Font = Enum.Font.GothamSemibold
	TeamCheckButton.Parent = MainFrame
	
	local ButtonCorner = Instance.new("UICorner")
	ButtonCorner.CornerRadius = UDim.new(0, 8)
	ButtonCorner.Parent = TeamCheckButton
	
	-- ESP Toggle
	local ESPButton = Instance.new("TextButton")
	ESPButton.Name = "ESPButton"
	ESPButton.Size = UDim2.new(0.9, 0, 0, 35)
	ESPButton.Position = UDim2.new(0.05, 0, 0.6, 0)
	ESPButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	ESPButton.Text = "ESP: ON"
	ESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ESPButton.TextSize = 14
	ESPButton.Font = Enum.Font.GothamSemibold
	ESPButton.Parent = MainFrame
	
	local ESPButtonCorner = Instance.new("UICorner")
	ESPButtonCorner.CornerRadius = UDim.new(0, 8)
	ESPButtonCorner.Parent = ESPButton
	
	-- Hover ve Click efektleri
	local function CreateButtonEffect(button)
		local originalColor = button.BackgroundColor3
		
		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(55, 55, 55)
			}):Play()
		end)
		
		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.2), {
				BackgroundColor3 = originalColor
			}):Play()
		end)
		
		button.MouseButton1Down:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.1), {
				BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			}):Play()
		end)
		
		button.MouseButton1Up:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.1), {
				BackgroundColor3 = Color3.fromRGB(55, 55, 55)
			}):Play()
		end)
	end
	
	CreateButtonEffect(TeamCheckButton)
	CreateButtonEffect(ESPButton)
	
	-- Buton fonksiyonları
	TeamCheckButton.MouseButton1Click:Connect(function()
		GUI.TeamCheckEnabled = not GUI.TeamCheckEnabled
		TeamCheckButton.Text = "Team Check: " .. (GUI.TeamCheckEnabled and "ON" or "OFF")
	end)
	
	ESPButton.MouseButton1Click:Connect(function()
		GUI.ESPEnabled = not GUI.ESPEnabled
		ESPButton.Text = "ESP: " .. (GUI.ESPEnabled and "ON" or "OFF")
		if not GUI.ESPEnabled then
			CleanBeams()
		end
	end)
	
	-- Sürükleme özelliği
	local dragging
	local dragInput
	local dragStart
	local startPos
	
	local function update(input)
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	
	TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
		end
	end)
	
	TitleBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	
	return ScreenGui
end

local function UpdateScreenBeamPosition()
	local viewportSize = Camera.ViewportSize
	local screenPosition = Vector2new(viewportSize.X / 2, viewportSize.Y)
	local worldPosition = Camera:ScreenPointToWorld(screenPosition.X, screenPosition.Y, 10)
	ScreenBeamPart.Position = worldPosition
end

local function CreateBeam(target)
	local attachment0 = Instancenew("Attachment")
	local attachment1 = Instancenew("Attachment")
	local beam = Instancenew("Beam")
	
	attachment0.Parent = ScreenBeamPart
	attachment1.Parent = target
	
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Width0 = 0.2
	beam.Width1 = 0.2
	beam.Color = ColorSequence.new(Color3fromRGB(255, 0, 0))
	beam.Parent = BeamFolder
	
	return {beam = beam, attachments = {attachment0, attachment1}}
end

local function CleanBeams()
	for _, child in pairs(BeamFolder:GetChildren()) do
		if child:IsA("Beam") or child:IsA("Attachment") then
			child:Destroy()
		end
	end
end

--[[
local Degrade = false

do
	xpcall(function()
		local TemporaryDrawing = Drawingnew("Line")
		getrenderproperty = getupvalue(getmetatable(TemporaryDrawing).__index, 4)
		setrenderproperty = getupvalue(getmetatable(TemporaryDrawing).__newindex, 4)
		TemporaryDrawing.Remove(TemporaryDrawing)
	end, function()
		Degrade, getrenderproperty, setrenderproperty = true, function(Object, Key)
			return Object[Key]
		end, function(Object, Key, Value)
			Object[Key] = Value
		end
	end)

	local TemporaryConnection = Connect(__index(game, "DescendantAdded"), function() end)
	Disconnect = TemporaryConnection.Disconnect
	Disconnect(TemporaryConnection)
end
]]

--// Checking for multiple processes

if ExunysDeveloperAimbot and ExunysDeveloperAimbot.Exit then
	ExunysDeveloperAimbot:Exit()
end

--// Environment

getgenv().ExunysDeveloperAimbot = {
	DeveloperSettings = {
		UpdateMode = "RenderStepped",
		TeamCheckOption = "TeamColor",
		RainbowSpeed = 1 -- Bigger = Slower
	},

	Settings = {
		Enabled = true,

		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,

		OffsetToMoveDirection = false,
		OffsetIncrement = 15,

		Sensitivity = 0, -- Animation length (in seconds) before fully locking onto target
		Sensitivity2 = 3.5, -- mousemoverel Sensitivity

		LockMode = 1, -- 1 = CFrame; 2 = mousemoverel
		LockPart = "Head", -- Body part to lock on

		TriggerKey = Enum.UserInputType.MouseButton2,
		Toggle = false
	},

	FOVSettings = {
		Enabled = true,
		Visible = true,

		Radius = 90,
		NumSides = 60,

		Thickness = 1,
		Transparency = 1,
		Filled = false,

		RainbowColor = false,
		RainbowOutlineColor = false,
		Color = Color3fromRGB(255, 255, 255),
		OutlineColor = Color3fromRGB(0, 0, 0),
		LockedColor = Color3fromRGB(255, 150, 150)
	},

	Blacklisted = {},
	FOVCircleOutline = Drawingnew("Circle"),
	FOVCircle = Drawingnew("Circle")
}

local Environment = getgenv().ExunysDeveloperAimbot

setrenderproperty(Environment.FOVCircle, "Visible", false)
setrenderproperty(Environment.FOVCircleOutline, "Visible", false)

--// Core Functions

local FixUsername = function(String)
	local Result

	for _, Value in next, GetPlayers(Players) do
		local Name = __index(Value, "Name")

		if stringsub(stringlower(Name), 1, #String) == stringlower(String) then
			Result = Name
		end
	end

	return Result
end

local GetRainbowColor = function()
	local RainbowSpeed = Environment.DeveloperSettings.RainbowSpeed

	return Color3fromHSV(tick() % RainbowSpeed / RainbowSpeed, 1, 1)
end

local ConvertVector = function(Vector)
	return Vector2new(Vector.X, Vector.Y)
end

local CancelLock = function()
	Environment.Locked = nil

	local FOVCircle = Environment.FOVCircle--Degrade and Environment.FOVCircle or Environment.FOVCircle.__OBJECT

	setrenderproperty(FOVCircle, "Color", Environment.FOVSettings.Color)
	__newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)

	if Animation then
		Animation:Cancel()
	end
end

local function UpdateESP()
	CleanBeams()
	UpdateScreenBeamPosition()

	for _, player in pairs(game.Players:GetPlayers()) do
		if player ~= game.Players.LocalPlayer then
			local character = player.Character
			if character and character:FindFirstChild("Head") then
				local localTeam = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Team")
				local playerTeam = character:FindFirstChild("Team")

				-- Team Check kontrolü
				if GUI.TeamCheckEnabled then
					if localTeam and playerTeam and localTeam.Value == playerTeam.Value then
						continue
					end
				end

				CreateBeam(character.Head)
			end
		end
	end
end

local GetClosestPlayer = function()
	local Settings = Environment.Settings
	local LockPart = Settings.LockPart

	if not Environment.Locked then
		RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2000

		for _, Value in next, GetPlayers(Players) do
			local Character = __index(Value, "Character")
			local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")
			local PlayerTeam = Character and Character:FindFirstChild("Team")
			local LocalCharacter = __index(LocalPlayer, "Character")

			if Value ~= LocalPlayer and not tablefind(Environment.Blacklisted, __index(Value, "Name")) and Character and FindFirstChild(Character, LockPart) and Humanoid and LocalCharacter then
				-- Team Check kontrolü
				if GUI.TeamCheckEnabled and PlayerTeam and LocalCharacter:FindFirstChild("Team") then
					if PlayerTeam.Value == LocalCharacter:FindFirstChild("Team").Value then
						continue
					end
				end

				local PartPosition = __index(Character[LockPart], "Position")
				local Vector = WorldToViewportPoint(Camera, PartPosition)
				local Distance = (GetMouseLocation(UserInputService) - ConvertVector(Vector)).Magnitude

				if Distance < RequiredDistance and Vector.Z > 0 then
					RequiredDistance = Distance
					Environment.Locked = Value
				end
			end
		end
	elseif Environment.Locked then
		local Character = __index(Environment.Locked, "Character")
		if Character then
			local LockPartObject = FindFirstChild(Character, LockPart)
			if LockPartObject then
				local PartPosition = __index(LockPartObject, "Position")
				local Vector = WorldToViewportPoint(Camera, PartPosition)
				
				-- Hedef görüş dışına çıktıysa veya team check açıkken aynı takımdaysa kilidi kaldır
				if Vector.Z < 0 or (GUI.TeamCheckEnabled and Character:FindFirstChild("Team") and LocalPlayer.Character:FindFirstChild("Team") and Character.Team.Value == LocalPlayer.Character.Team.Value) then
					CancelLock()
				end
			else
				CancelLock()
			end
		else
			CancelLock()
		end
	end
end

local function StartESP()
	-- Eski bağlantıyı temizle
	if ServiceConnections.ESPConnection then
		ServiceConnections.ESPConnection:Disconnect()
	end
	
	-- Yeni ESP bağlantısı
	ServiceConnections.ESPConnection = RunService.RenderStepped:Connect(function()
		UpdateESP()
	end)
end

local Load = function()
	OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")
	
	-- Eski GUI'yi temizle
	if CoreGui:FindFirstChild("ModernAimbotGUI") then
		CoreGui.ModernAimbotGUI:Destroy()
	end
	
	-- Yeni GUI'yi oluştur
	CreateModernGUI()
	
	-- ESP'yi başlat
	if not ServiceConnections.ESPConnection then
		ServiceConnections.ESPConnection = RunService.RenderStepped:Connect(function()
			if GUI.ESPEnabled then
				UpdateESP()
			end
		end)
	end

	local Settings, FOVCircle, FOVCircleOutline, FOVSettings, Offset = Environment.Settings, Environment.FOVCircle, Environment.FOVCircleOutline, Environment.FOVSettings

	--[[
	if not Degrade then
		FOVCircle, FOVCircleOutline = FOVCircle.__OBJECT, FOVCircleOutline.__OBJECT
	end
	]]

	ServiceConnections.RenderSteppedConnection = Connect(__index(RunService, Environment.DeveloperSettings.UpdateMode), function()
		local OffsetToMoveDirection, LockPart = Settings.OffsetToMoveDirection, Settings.LockPart

		if FOVSettings.Enabled and Settings.Enabled then
			for Index, Value in next, FOVSettings do
				if Index == "Color" then
					continue
				end

				if pcall(getrenderproperty, FOVCircle, Index) then
					setrenderproperty(FOVCircle, Index, Value)
					setrenderproperty(FOVCircleOutline, Index, Value)
				end
			end

			setrenderproperty(FOVCircle, "Color", (Environment.Locked and FOVSettings.LockedColor) or FOVSettings.RainbowColor and GetRainbowColor() or FOVSettings.Color)
			setrenderproperty(FOVCircleOutline, "Color", FOVSettings.RainbowOutlineColor and GetRainbowColor() or FOVSettings.OutlineColor)

			setrenderproperty(FOVCircleOutline, "Thickness", FOVSettings.Thickness + 1)
			setrenderproperty(FOVCircle, "Position", GetMouseLocation(UserInputService))
			setrenderproperty(FOVCircleOutline, "Position", GetMouseLocation(UserInputService))
		else
			setrenderproperty(FOVCircle, "Visible", false)
			setrenderproperty(FOVCircleOutline, "Visible", false)
		end

		if Running and Settings.Enabled then
			GetClosestPlayer()

			Offset = OffsetToMoveDirection and __index(FindFirstChildOfClass(__index(Environment.Locked, "Character"), "Humanoid"), "MoveDirection") * (mathclamp(Settings.OffsetIncrement, 1, 30) / 10) or Vector3zero

			if Environment.Locked then
				local LockedPosition_Vector3 = __index(__index(Environment.Locked, "Character")[LockPart], "Position")
				local LockedPosition = WorldToViewportPoint(Camera, LockedPosition_Vector3 + Offset)

				if Environment.Settings.LockMode == 2 then
					mousemoverel((LockedPosition.X - GetMouseLocation(UserInputService).X) / Settings.Sensitivity2, (LockedPosition.Y - GetMouseLocation(UserInputService).Y) / Settings.Sensitivity2)
				else
					if Settings.Sensitivity > 0 then
						Animation = TweenService:Create(Camera, TweenInfonew(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFramenew(Camera.CFrame.Position, LockedPosition_Vector3)})
						Animation:Play()
					else
						__newindex(Camera, "CFrame", CFramenew(Camera.CFrame.Position, LockedPosition_Vector3 + Offset))
					end

					__newindex(UserInputService, "MouseDeltaSensitivity", 0)
				end

				setrenderproperty(FOVCircle, "Color", FOVSettings.LockedColor)
			end
		end
	end)

	ServiceConnections.InputBeganConnection = Connect(__index(UserInputService, "InputBegan"), function(Input)
		local TriggerKey, Toggle = Settings.TriggerKey, Settings.Toggle

		if Typing then
			return
		end

		if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey or Input.UserInputType == TriggerKey then
			if Toggle then
				Running = not Running

				if not Running then
					CancelLock()
				end
			else
				Running = true
			end
		end
	end)

	ServiceConnections.InputEndedConnection = Connect(__index(UserInputService, "InputEnded"), function(Input)
		local TriggerKey, Toggle = Settings.TriggerKey, Settings.Toggle

		if Toggle or Typing then
			return
		end

		if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey or Input.UserInputType == TriggerKey then
			Running = false
			CancelLock()
		end
	end)

	ServiceConnections.ESPUpdateConnection = Connect(__index(RunService, "RenderStepped"), UpdateESP)
end

--// Typing Check

ServiceConnections.TypingStartedConnection = Connect(__index(UserInputService, "TextBoxFocused"), function()
	Typing = true
end)

ServiceConnections.TypingEndedConnection = Connect(__index(UserInputService, "TextBoxFocusReleased"), function()
	Typing = false
end)

--// Functions

function Environment.Exit(self)
	assert(self, "EXUNYS_AIMBOT-V3.Exit: Missing parameter #1 \"self\" <table>.")

	-- Bağlantıları temizle
	for Index, _ in next, ServiceConnections do
		Disconnect(ServiceConnections[Index])
	end

	-- GUI'yi temizle
	if CoreGui:FindFirstChild("ModernAimbotGUI") then
		CoreGui.ModernAimbotGUI:Destroy()
	end

	-- BeamFolder'ı temizle
	if BeamFolder then
		BeamFolder:Destroy()
	end

	self.FOVCircle:Remove()
	self.FOVCircleOutline:Remove()
	getgenv().ExunysDeveloperAimbot = nil
end

function Environment.Restart() -- ExunysDeveloperAimbot.Restart(<void>)
	for Index, _ in next, ServiceConnections do
		Disconnect(ServiceConnections[Index])
	end

	Load()
end

function Environment.Blacklist(self, Username) -- METHOD | ExunysDeveloperAimbot:Blacklist(<string> Player Name)
	assert(self, "EXUNYS_AIMBOT-V3.Blacklist: Missing parameter #1 \"self\" <table>.")
	assert(Username, "EXUNYS_AIMBOT-V3.Blacklist: Missing parameter #2 \"Username\" <string>.")

	Username = FixUsername(Username)

	assert(self, "EXUNYS_AIMBOT-V3.Blacklist: User "..Username.." couldn't be found.")

	self.Blacklisted[#self.Blacklisted + 1] = Username
end

function Environment.Whitelist(self, Username) -- METHOD | ExunysDeveloperAimbot:Whitelist(<string> Player Name)
	assert(self, "EXUNYS_AIMBOT-V3.Whitelist: Missing parameter #1 \"self\" <table>.")
	assert(Username, "EXUNYS_AIMBOT-V3.Whitelist: Missing parameter #2 \"Username\" <string>.")

	Username = FixUsername(Username)

	assert(Username, "EXUNYS_AIMBOT-V3.Whitelist: User "..Username.." couldn't be found.")

	local Index = tablefind(self.Blacklisted, Username)

	assert(Index, "EXUNYS_AIMBOT-V3.Whitelist: User "..Username.." is not blacklisted.")

	tableremove(self.Blacklisted, Index)
end

function Environment.GetClosestPlayer() -- ExunysDeveloperAimbot.GetClosestPlayer(<void>)
	GetClosestPlayer()
	local Value = Environment.Locked
	CancelLock()

	return Value
end

Environment.Load = Load -- ExunysDeveloperAimbot.Load()

setmetatable(Environment, {__call = Load})

return Environment
