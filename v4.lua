--[[

	Universal Aimbot Module by Exunys © CC0 1.0 Universal (2023 - 2024)
	https://github.com/Exunys

]]

--// Cache

local game, workspace = game, workspace
local getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick = getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick
local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV, Drawingnew, TweenInfonew = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV, Drawing.new, TweenInfo.new
local getupvalue, mousemoverel, tablefind, tableremove, stringlower, stringsub, mathclamp = debug.getupvalue, mousemoverel or (Input and Input.MouseMove), table.find, table.remove, string.lower, string.sub, math.clamp

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
local CoreGui = GetService(game, "CoreGui")

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
local ESPFolder
local ESPEnabled = true
local TeamCheck = true

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
		
		ESPEnabled = true, -- ESP ayarı eklendi
		ESPTeamCheck = true, -- ESP için team check ayarı

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

local GetClosestPlayer = function()
	local Settings = Environment.Settings
	local LockPart = Settings.LockPart

	if not Environment.Locked then
		RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2000

		for _, Value in next, GetPlayers(Players) do
			local Character = __index(Value, "Character")
			local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")

			if Value ~= LocalPlayer and not tablefind(Environment.Blacklisted, __index(Value, "Name")) and Character and FindFirstChild(Character, LockPart) and Humanoid then
				local PartPosition, TeamCheckOption = __index(Character[LockPart], "Position"), Environment.DeveloperSettings.TeamCheckOption

				if Settings.TeamCheck and __index(Value, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then
					continue
				end

				if Settings.AliveCheck and __index(Humanoid, "Health") <= 0 then
					continue
				end

				if Settings.WallCheck then
					local BlacklistTable = GetDescendants(__index(LocalPlayer, "Character"))

					for _, Value in next, GetDescendants(Character) do
						BlacklistTable[#BlacklistTable + 1] = Value
					end

					if #GetPartsObscuringTarget(Camera, {PartPosition}, BlacklistTable) > 0 then
						continue
					end
				end

				local Vector, OnScreen, Distance = WorldToViewportPoint(Camera, PartPosition)
				Vector = ConvertVector(Vector)
				Distance = (GetMouseLocation(UserInputService) - Vector).Magnitude

				if Distance < RequiredDistance and OnScreen then
					RequiredDistance, Environment.Locked = Distance, Value
				end
			end
		end
	elseif (GetMouseLocation(UserInputService) - ConvertVector(WorldToViewportPoint(Camera, __index(__index(__index(Environment.Locked, "Character"), LockPart), "Position")))).Magnitude > RequiredDistance then
		CancelLock()
	end
end

-- ESP için gerekli fonksiyonlar
local function CleanESP()
	if ESPFolder then
		for _, child in pairs(ESPFolder:GetChildren()) do
			child:Destroy()
		end
	end
end

local function SetupESP()
	-- Eski ESP'yi temizle
	if ESPFolder then
		ESPFolder:Destroy()
	end
	
	-- Yeni ESP klasörü oluştur
	ESPFolder = Instance.new("Folder")
	ESPFolder.Name = "ESP_Objects"
	ESPFolder.Parent = workspace
	
	-- Düzenli güncelleme
	return RunService.RenderStepped:Connect(UpdatePlayerESP)
end

local function UpdatePlayerESP()
	if not ESPFolder then return end
	
	-- Tüm mevcut ESP'leri temizle
	for _, child in pairs(ESPFolder:GetChildren()) do
		child:Destroy()
	end
	
	-- Sadece ESP etkinse devam et
	if not Environment.Settings.ESPEnabled then return end
	
	-- Her oyuncu için ESP oluştur
	for _, player in pairs(GetPlayers(Players)) do
		if player ~= LocalPlayer then
			-- Karakter kontrolü
			local Character = __index(player, "Character")
			if Character and FindFirstChild(Character, "HumanoidRootPart") then
				local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
				
				-- AliveCheck kontrolü
				if Environment.Settings.AliveCheck and Humanoid and __index(Humanoid, "Health") <= 0 then
					continue
				end
				
				-- Team Check kontrolü
				if Environment.Settings.ESPTeamCheck then
					local TeamCheckOption = Environment.DeveloperSettings.TeamCheckOption
					if __index(player, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then
						continue
					end
				end
				
				-- ESP sembolü oluştur
				local HumanoidRootPart = Character.HumanoidRootPart
				local billboard = Instance.new("BillboardGui")
				billboard.Name = player.Name .. "_ESP"
				billboard.AlwaysOnTop = true
				billboard.Size = UDim2.new(0, 200, 0, 50)
				billboard.StudsOffset = Vector3.new(0, 3, 0)
				billboard.Adornee = HumanoidRootPart
				billboard.Parent = ESPFolder
				
				-- Okun arkaplanı
				local background = Instance.new("Frame")
				background.Size = UDim2.new(0, 30, 0, 30)
				background.Position = UDim2.new(0.5, -15, 0.5, -15)
				background.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				background.BackgroundTransparency = 0.2
				background.BorderSizePixel = 0
				background.Parent = billboard
				
				local UICorner = Instance.new("UICorner")
				UICorner.CornerRadius = UDim.new(1, 0)
				UICorner.Parent = background
				
				-- Ok işareti
				local arrow = Instance.new("TextLabel")
				arrow.AnchorPoint = Vector2.new(0.5, 0.5)
				arrow.Position = UDim2.new(0.5, 0, 0.5, 0)
				arrow.Size = UDim2.new(1, 0, 1, 0)
				arrow.BackgroundTransparency = 1
				arrow.TextColor3 = Color3.fromRGB(255, 0, 0)
				arrow.Text = "▼"
				arrow.TextSize = 24
				arrow.Font = Enum.Font.GothamBold
				arrow.Parent = background
			end
		end
	end
end

local Load = function()
	OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")
	
	-- Modern GUI'yi oluştur
	CreateModernGUI()
	
	-- ESP'yi başlat
	if not ServiceConnections.ESPConnection then
		ServiceConnections.ESPConnection = SetupESP()
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
	
	-- ESP güncelleme bağlantısı
	if not ServiceConnections.ESPUpdateConnection then
		ServiceConnections.ESPUpdateConnection = Connect(__index(RunService, "RenderStepped"), UpdatePlayerESP)
	end
end

--// Typing Check

ServiceConnections.TypingStartedConnection = Connect(__index(UserInputService, "TextBoxFocused"), function()
	Typing = true
end)

ServiceConnections.TypingEndedConnection = Connect(__index(UserInputService, "TextBoxFocusReleased"), function()
	Typing = false
end)

--// Functions

function Environment.Exit(self) -- METHOD | ExunysDeveloperAimbot:Exit(<void>)
	assert(self, "EXUNYS_AIMBOT-V3.Exit: Missing parameter #1 \"self\" <table>.")

	for Index, _ in next, ServiceConnections do
		Disconnect(ServiceConnections[Index])
	end

	-- ESP'yi temizle
	if ESPFolder then
		ESPFolder:Destroy()
	end
	
	-- GUI'yi temizle
	if CoreGui:FindFirstChild("AimbotESPGUI") then
		CoreGui.AimbotESPGUI:Destroy()
	end

	Load = nil; ConvertVector = nil; CancelLock = nil; GetClosestPlayer = nil; GetRainbowColor = nil; FixUsername = nil

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

--// ESP kontrolleri için fonksiyonlar ekle
function Environment.ToggleESP(self, enabled)
	self.Settings.ESPEnabled = enabled
	if not enabled then
		CleanESP()
	end
end

function Environment.ToggleESPTeamCheck(self, enabled)
	self.Settings.ESPTeamCheck = enabled
end

Environment.Load = Load -- ExunysDeveloperAimbot.Load()

setmetatable(Environment, {__call = Load})

-- Modern GUI oluşturma fonksiyonu
local function CreateModernGUI()
	-- Eski GUI'yi temizle
	if CoreGui:FindFirstChild("AimbotESPGUI") then
		CoreGui.AimbotESPGUI:Destroy()
	end
	
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AimbotESPGUI"
	ScreenGui.Parent = CoreGui
	
	-- Ana Frame
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 250, 0, 200) -- Boyutu büyüttüm
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
	TitleText.Text = "Aimbot & ESP Kontrolleri"
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
	TeamCheckButton.Position = UDim2.new(0.05, 0, 0.2, 0)
	TeamCheckButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	TeamCheckButton.Text = "Aimbot Team Check: " .. (Environment.Settings.TeamCheck and "AÇIK" or "KAPALI")
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
	ESPButton.Position = UDim2.new(0.05, 0, 0.4, 0)
	ESPButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	ESPButton.Text = "ESP: " .. (Environment.Settings.ESPEnabled and "AÇIK" or "KAPALI")
	ESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ESPButton.TextSize = 14
	ESPButton.Font = Enum.Font.GothamSemibold
	ESPButton.Parent = MainFrame
	
	local ESPButtonCorner = Instance.new("UICorner")
	ESPButtonCorner.CornerRadius = UDim.new(0, 8)
	ESPButtonCorner.Parent = ESPButton
	
	-- ESP Team Check Toggle
	local ESPTeamCheckButton = Instance.new("TextButton")
	ESPTeamCheckButton.Name = "ESPTeamCheckButton"
	ESPTeamCheckButton.Size = UDim2.new(0.9, 0, 0, 35)
	ESPTeamCheckButton.Position = UDim2.new(0.05, 0, 0.6, 0)
	ESPTeamCheckButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	ESPTeamCheckButton.Text = "ESP Team Check: " .. (Environment.Settings.ESPTeamCheck and "AÇIK" or "KAPALI")
	ESPTeamCheckButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ESPTeamCheckButton.TextSize = 14
	ESPTeamCheckButton.Font = Enum.Font.GothamSemibold
	ESPTeamCheckButton.Parent = MainFrame
	
	local ESPTeamCheckCorner = Instance.new("UICorner")
	ESPTeamCheckCorner.CornerRadius = UDim.new(0, 8)
	ESPTeamCheckCorner.Parent = ESPTeamCheckButton
	
	-- Aimbot Toggle
	local AimbotButton = Instance.new("TextButton")
	AimbotButton.Name = "AimbotButton"
	AimbotButton.Size = UDim2.new(0.9, 0, 0, 35)
	AimbotButton.Position = UDim2.new(0.05, 0, 0.8, 0)
	AimbotButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	AimbotButton.Text = "Aimbot: " .. (Environment.Settings.Enabled and "AÇIK" or "KAPALI")
	AimbotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	AimbotButton.TextSize = 14
	AimbotButton.Font = Enum.Font.GothamSemibold
	AimbotButton.Parent = MainFrame
	
	local AimbotButtonCorner = Instance.new("UICorner")
	AimbotButtonCorner.CornerRadius = UDim.new(0, 8)
	AimbotButtonCorner.Parent = AimbotButton
	
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
	CreateButtonEffect(ESPTeamCheckButton)
	CreateButtonEffect(AimbotButton)
	
	-- Buton fonksiyonları
	TeamCheckButton.MouseButton1Click:Connect(function()
		Environment.Settings.TeamCheck = not Environment.Settings.TeamCheck
		TeamCheckButton.Text = "Aimbot Team Check: " .. (Environment.Settings.TeamCheck and "AÇIK" or "KAPALI")
	end)
	
	ESPButton.MouseButton1Click:Connect(function()
		Environment.Settings.ESPEnabled = not Environment.Settings.ESPEnabled
		ESPButton.Text = "ESP: " .. (Environment.Settings.ESPEnabled and "AÇIK" or "KAPALI")
		if not Environment.Settings.ESPEnabled then
			CleanESP()
		end
	end)
	
	ESPTeamCheckButton.MouseButton1Click:Connect(function()
		Environment.Settings.ESPTeamCheck = not Environment.Settings.ESPTeamCheck
		ESPTeamCheckButton.Text = "ESP Team Check: " .. (Environment.Settings.ESPTeamCheck and "AÇIK" or "KAPALI")
	end)
	
	AimbotButton.MouseButton1Click:Connect(function()
		Environment.Settings.Enabled = not Environment.Settings.Enabled
		AimbotButton.Text = "Aimbot: " .. (Environment.Settings.Enabled and "AÇIK" or "KAPALI")
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

return Environment
