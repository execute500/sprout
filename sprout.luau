local version = "v0.1.2"
local librepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(librepo .. "Library.lua"))()
local SaveManager = loadstring(game:HttpGet(librepo .. "addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet(librepo .. "addons/ThemeManager.lua"))()
local Toggles = Library.Toggles
local Options = Library.Options

-- 初始化
local Loading = Library:CreateLoading({
	Title = "Sprout",
	Icon = 95816097006870,
	TotalSteps = 3,
})

Loading:SetMessage("初始化中...")
Loading:SetDescription("加载库中...")
Services = setmetatable({}, {
	__index = function(self, name)
		local success, cache = pcall(function()
			return cloneref(game:GetService(name))
		end)
		if success then
			rawset(self, name, cache)
			return cache
		else
			error("无效服务: " .. tostring(name))
		end
	end,
})

local Workspace = Services.Workspace
local Players = Services.Players
local RunService = Services.RunService
local ProximityPromptService = Services.ProximityPromptService
local Lighting = Services.Lighting
local HttpService = Services.HttpService
local TeleportService = Services.TeleportService
local TextChatService = Services.TextChatService
local ReplicatedStorage = Services.ReplicatedStorage

local ESPLibrary =
	loadstring(game:HttpGet("https://raw.githubusercontent.com/TheHunterSolo1/Scripts/main/ESPLibrary"))()
ESPLibrary:SetFadeTime(0)
ESPLibrary:SetTracers(false)

Loading:SetCurrentStep(1)
Loading:SetDescription("创建页面中...")

local Window = Library:CreateWindow({
	Title = "Sprout",
	Footer = "当前版本: " .. version,
	Icon = 95816097006870,
	NotifySide = "Right",
})

local Tabs = {
	Main = Window:AddTab("主要", "user"),
	Games = Window:AddTab("游戏", "gamepad-2"),
	Vision = Window:AddTab("视觉", "eye"),
	["UI Settings"] = Window:AddTab("UI设置", "settings"),
}

-- 主要
local MainTab = Tabs.Main:AddLeftGroupbox("主要", "sliders-horizontal")
MainTab:AddSlider("SpeedControl", { Text = "速度", Default = 16, AllowRightClickInput = true })
MainTab:AddToggle("EnableSpeedControl", { Text = "启用速度修改" })
MainTab:AddSlider("JumpPower", { Text = "跳跃高度", Max = 300, Default = 50, AllowRightClickInput = true })
MainTab:AddToggle("EnableJumpPower", { Text = "启用跳跃高度修改" })
MainTab:AddSlider("FlySpeed", { Text = "飞行速度", Max = 10, Default = 1, AllowRightClickInput = true })
MainTab:AddToggle("EnableFly", { Text = "飞行" })
MainTab:AddToggle("EnableNoclip", { Text = "穿墙" })
MainTab:AddToggle("instantproximityprompts", { Text = "瞬间交互" })

local SessionTab = Tabs.Main:AddRightGroupbox("会话")
SessionTab:AddButton({
	Text = "重置角色",
	DoubleClick = true,
	Func = function()
		reset()
	end,
})
SessionTab:AddButton({
	Text = "重新加入",
	DoubleClick = true,
	Func = function()
		rejoin()
	end,
})

local DownloadTab = Tabs.Main:AddRightGroupbox("下载", "download")
DownloadTab:AddInput("FileURL", { Text = "文件URL", Placeholder = "https://example.com/file.txt" })
DownloadTab:AddButton({
	Text = "下载",
	Func = function()
		local fileName = getFileNameFromURL(Options.FileURL.Value)
		local processN = Library:Notify({
			Title = fileName,
			Description = "下载文件中...",
			Persist = true,
		})
		local success, result = pcall(function()
			return HttpService:RequestAsync({
				Url = Options.FileURL.Value,
			})
		end)
		if success and result and result.Success then
			Library:Notify("下载成功!")
			writefile(fileName, result.Body)
		else
			Library:Notify("下载失败!")
		end
		processN:Destroy()
	end,
})

local OtherScripts = Tabs.Main:AddRightGroupbox("其他脚本", "ellipsis")
local Scripts = {
	["Infinite Yield"] = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
	["甩飞"] = "https://raw.githubusercontent.com/alinurb295-coder/ALINUR-FLING-SCRIPT/refs/heads/main/ALINUR-FLING.lua",
	["Dex++"] = "https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua",
	["飞行GUI"] = "https://raw.githubusercontent.com/execute500/scripts/refs/heads/main/飞行GUI",
}
for name, url in pairs(Scripts) do
	OtherScripts:AddButton({
		Text = name,
		DoubleClick = true,
		Func = function()
			local func, err = loadstring(game:HttpGet(url))
			if func == nil then
				warn("获取脚本失败: " .. err)
				Library:Notify("[" .. name .. "] 获取脚本失败!")
				return
			end
			func()
		end,
	})
end

-- 游戏
local DoorsBox = Tabs.Games:AddLeftGroupbox("Doors")
DoorsBox:AddToggle("MonsterNotify", { Text = "实体通知" })
DoorsBox:AddToggle("MonsterChat", { Text = "聊天通知" })
local BeSCPBox = Tabs.Games:AddRightGroupbox("成为SCP或守卫")
BeSCPBox:AddToggle("SCPESP", { Text = "SCP ESP" })
BeSCPBox:AddToggle("MTFESP", { Text = "MTF ESP" })
BeSCPBox:AddToggle("GuardESP", { Text = "守卫ESP" })
BeSCPBox:AddDivider()
BeSCPBox:AddToggle("Auto035", { Text = "自动035" })
BeSCPBox:AddToggle("AutoClothes", { Text = "自动穿衣😀" })

-- 视觉
local ESPTabbox = Tabs.Vision:AddLeftTabbox("ESP")
local ESPBox = ESPTabbox:AddTab("ESP")
ESPBox:AddToggle("PlayerESP", { Text = "玩家ESP" })
	:AddColorPicker("PlayerESPColorPicker", { Default = Color3.new(1, 1, 1) })
ESPBox:AddDivider()
local CustomESPs = {}
ESPBox:AddInput("CustomESP", { Text = "自定义ESP", Placeholder = "部件位置" })
ESPBox:AddLabel("默认颜色"):AddColorPicker("DefaultCustomESPColorPicker", { Default = Color3.new(1, 1, 1) })
ESPBox:AddButton("确定", function()
	local func, err = loadstring("return " .. Options.CustomESP.Value)
	if func == nil then
		warn("获取部件失败: " .. err)
		Library:Notify("获取部件失败!")
		return
	end
	local success, result = pcall(func)
	if not success then
		warn("获取部件失败: " .. result)
		Library:Notify("获取部件失败!")
		return
	end
	if result == nil then
		Library:Notify("未知部件!")
		return
	end
	if CustomESPs[result] then
		Library:Notify("已存在该部件!")
		return
	end
	CustomESP(result)
end)
ESPBox:AddDivider()
ESPBox:AddDropdown("CustomESPs", {
	Text = "当前自定义ESP",
	Multi = true,
})
ESPBox:AddInput("CustomESPName", { Text = "ESP名称", ClearTextOnFocus = false })
ESPBox:AddLabel("ESP颜色"):AddColorPicker("CustomESPColorPicker")
ESPBox:AddButton("重命名", function()
	for _, data in pairs(Options.CustomESPs.Values) do
		local newName = Options.CustomESPName.Value
		Library:Notify("成功重命名 " .. data.Name .. " -> " .. newName, 2)
		data.Name = newName
		ESPLibrary:UpdateESP(data.Object, newName, data.Color)
	end
	Options.CustomESPs:SetValues(CustomESPs)
end):AddButton("删除ESP", function()
	for _, Table in pairs(Options.CustomESPs.Values) do
		RemoveCustomESP(Table.Object)
		Library:Notify("成功删除 " .. Table.Name .. " ESP", 2)
	end
end)

local ESPBoxSettings = ESPTabbox:AddTab("设置")
ESPBoxSettings:AddToggle("RainbowESP", { Text = "彩色ESP", DisabledTooltip = "与 玩家队伍颜色 不兼容!" })
ESPBoxSettings:AddToggle(
	"EnableTeamColor",
	{ Text = "玩家队伍颜色", DisabledTooltip = "与 彩色ESP 不兼容!" }
)
ESPBoxSettings:AddSlider("ESPTransitingTime", { Text = "过渡时间", Max = 4, Default = 0 })
ESPBoxSettings:AddToggle("ESPArrows", { Text = "启用箭头" })
ESPBoxSettings:AddToggle("ESPTracers", { Text = "启用射线" })
ESPBoxSettings:AddToggle("ESPShowDistance", { Text = "显示距离", Default = true })
ESPBoxSettings:AddDropdown(
	"ESPMode",
	{ Text = "ESP模式", Values = { "Highlight/Text", "Highlight", "Text" }, Default = "Highlight/Text" }
)

local LightBox = Tabs.Vision:AddRightGroupbox("环境")
LightBox:AddSlider("Brightness", { Text = "亮度", Max = 10, Default = 2 })
LightBox:AddToggle("FullBright", { Text = "全亮" })
LightBox:AddToggle("Nofog", { Text = "无雾" })

local SelfBox = Tabs.Vision:AddRightGroupbox("自身")
SelfBox:AddToggle(
	"CameraMode",
	{ Text = "第三人称", Default = Players.LocalPlayer.CameraMode == Enum.CameraMode.Classic }
)
SelfBox:AddSlider("Fov", { Text = "视野范围", Min = 1, Max = 120, Default = 70, AllowRightClickInput = true })

-- UI设置
local Menu = Tabs["UI Settings"]:AddRightGroupbox("菜单选项", "wrench")
Menu:AddToggle("KeybindMenu", {
	Text = "打开快捷键菜单",
	Callback = function(enabled)
		Library.KeybindFrame.Visible = enabled
	end,
})
Menu:AddToggle("KeepHub", { Text = "在传送中执行" })
local TeleportCheck = false
Players.LocalPlayer.OnTeleport:Connect(function(state)
	if Toggles.KeepHub.Value and not TeleportCheck then
		TeleportCheck = true
		queue_on_teleport(
			"loadstring(game:HttpGet('https://raw.githubusercontent.com/execute500/sprout/refs/heads/main/sprout.luau')()"
		)
	end
end)
Menu:AddToggle("ForceCheckbox", {
	Text = "强制复选框",
	Callback = function(enabled)
		Library.ForceCheckbox = enabled
	end,
})
Menu:AddDropdown("NotificationSide", {
	Text = "通知方向",
	Values = { "Left", "Right" },
	Default = "Right",
	Callback = function(side)
		Library:SetNotifySide(side)
	end,
})
Menu:AddDropdown("DPIScale", {
	Text = "DPI缩放",
	Values = { "75%", "100%", "125%", "150%" },
	Default = "100%",
	Callback = function(scale)
		Library:SetDPIScale(tonumber(scale:sub(1, -2)))
	end,
})
Menu:AddDivider()
Menu:AddButton("卸载菜单", function()
	ESPLibrary:Unload()
	Library:Unload()
end)

Loading:SetCurrentStep(2)
Loading:SetDescription("加载配置中...")
-- SaveManager
SaveManager:IgnoreThemeSettings()
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("sprout")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()
-- ThemeManager
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("sprout")
ThemeManager:ApplyToTab(Tabs["UI Settings"])
ThemeManager:LoadDefault()

Loading:SetCurrentStep(3)
Loading:ShowSidebarPage(true)
Loading.Sidebar:AddLabel("用户: " .. Players.LocalPlayer.Name)
Loading.Sidebar:AddLabel("当前版本: " .. version)
Loading:SetDescription("加载完成!")
task.wait(1)
Loading:Continue()

function getFileNameFromURL(url)
	local path = url:split("?")[1]
	local segments = path:split("/")
	return segments[#segments]
end

function getRoot(char)
	if char and char:FindFirstChildOfClass("Humanoid") then
		return char:FindFirstChildOfClass("Humanoid").RootPart
	else
		return nil
	end
end

function randomString()
	local length = math.random(10, 20)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

function reset()
	local humanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Dead)
	else
		Players.LocalPlayer.Character:BreakJoints()
	end
end

function rejoin()
	if #Players:GetPlayers() <= 1 then
		Players.LocalPlayer:Kick("\n重新加入中...")
		wait()
		TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
	else
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
	end
end

function chatMessage(str)
	str = tostring(str)
	if not TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
		TextChatService.TextChannels.RBXGeneral:SendAsync(str)
	else
		ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(str, "All")
	end
end

function ESP(plr)
	if plr == Players.LocalPlayer then
		return
	end

	local color
	if Toggles.EnableTeamColor.Value then
		color = plr.TeamColor.Color
	else
		color = Options.PlayerESPColorPicker.Value
	end

	if not plr.Character then
		plr.CharacterAdded:Wait()
	end
	ESPLibrary:AddESP({
		Object = plr.Character,
		Text = plr.Name,
		Color = color,
	})

	local addedFunc
	local teamChange
	addedFunc = plr.CharacterAdded:Connect(function()
		if not Toggles.PlayerESP.Value then
			addedFunc:Disconnect()
			return
		end
		ESPLibrary:AddESP({
			Object = plr.Character,
			Text = plr.Name,
			Color = color,
		})
	end)
	teamChange = plr:GetPropertyChangedSignal("TeamColor"):Connect(function()
		if not Toggles.PlayerESP.Value then
			teamChange:Disconnect()
			return
		end
		if not Toggles.EnableTeamColor.Value then
			return
		end
		ESPLibrary:UpdateESP(plr.Character, plr.Name, plr.TeamColor)
	end)
end

local velocityHandlerName = randomString()
local gyroHandlerName = randomString()
local mfly1
local mfly2
function fly()
	local plr = Players.LocalPlayer
	local root = getRoot(plr.Character)
	local camera = workspace.CurrentCamera
	local v3none = Vector3.new()
	local v3zero = Vector3.new(0, 0, 0)
	local v3inf = Vector3.new(9e9, 9e9, 9e9)

	local controlModule = require(plr.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
	local bv = Instance.new("BodyVelocity")
	bv.Name = velocityHandlerName
	bv.Parent = root
	bv.MaxForce = v3zero
	bv.Velocity = v3zero

	local bg = Instance.new("BodyGyro")
	bg.Name = gyroHandlerName
	bg.Parent = root
	bg.MaxTorque = v3inf
	bg.P = 1000
	bg.D = 50

	mfly1 = plr.CharacterAdded:Connect(function()
		local bv = Instance.new("BodyVelocity")
		bv.Name = velocityHandlerName
		bv.Parent = root
		bv.MaxForce = v3zero
		bv.Velocity = v3zero

		local bg = Instance.new("BodyGyro")
		bg.Name = gyroHandlerName
		bg.Parent = root
		bg.MaxTorque = v3inf
		bg.P = 1000
		bg.D = 50
	end)

	mfly2 = RunService.RenderStepped:Connect(function()
		root = getRoot(plr.Character)
		camera = workspace.CurrentCamera
		if
			plr.Character:FindFirstChildWhichIsA("Humanoid")
			and root
			and root:FindFirstChild(velocityHandlerName)
			and root:FindFirstChild(gyroHandlerName)
		then
			local humanoid = plr.Character:FindFirstChildWhichIsA("Humanoid")
			local VelocityHandler = root:FindFirstChild(velocityHandlerName)
			local GyroHandler = root:FindFirstChild(gyroHandlerName)
			local flyspeed = Options.FlySpeed.Value

			VelocityHandler.MaxForce = v3inf
			GyroHandler.MaxTorque = v3inf
			humanoid.PlatformStand = true
			GyroHandler.CFrame = camera.CoordinateFrame
			VelocityHandler.Velocity = v3none

			local direction = controlModule:GetMoveVector()
			if direction.X > 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity
					+ camera.CFrame.RightVector * (direction.X * (flyspeed * 50))
			end
			if direction.X < 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity
					+ camera.CFrame.RightVector * (direction.X * (flyspeed * 50))
			end
			if direction.Z > 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity
					- camera.CFrame.LookVector * (direction.Z * (flyspeed * 50))
			end
			if direction.Z < 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity
					- camera.CFrame.LookVector * (direction.Z * (flyspeed * 50))
			end
		end
	end)
end

function unfly()
	pcall(function()
		local plr = Players.LocalPlayer
		local root = getRoot(plr.Character)
		root:FindFirstChild(velocityHandlerName):Destroy()
		root:FindFirstChild(gyroHandlerName):Destroy()
		plr.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
		mfly1:Disconnect()
		mfly2:Disconnect()
	end)
end

local playerAdded
Toggles.PlayerESP:OnChanged(function(state)
	if state then
		playerAdded = Players.PlayerAdded:Connect(function(plr)
			ESP(plr)
		end)
		for _, plr in Players:GetPlayers() do
			ESP(plr)
		end
	else
		playerAdded:Disconnect()
		for _, plr in Players:GetPlayers() do
			if plr == Players.LocalPlayer then
				continue
			end
			ESPLibrary:RemoveESP(plr.Character)
		end
	end
end)

Options.PlayerESPColorPicker:OnChanged(function(color)
	if Toggles.PlayerESP.Value and not Toggles.EnableTeamColor.Value then
		for _, plr in Players:GetPlayers() do
			if plr == Players.LocalPlayer then
				continue
			end

			ESPLibrary:UpdateESP(plr.Character, plr.Name, color)
		end
	end
end)

Toggles.RainbowESP:OnChanged(function(state)
	Toggles.EnableTeamColor:SetDisabled(state)
	ESPLibrary:SetRainbow(state)
end)

Toggles.EnableTeamColor:OnChanged(function(state)
	Toggles.RainbowESP:SetDisabled(state)

	if not Toggles.PlayerESP.Value then
		return
	end

	for _, plr in Players:GetPlayers() do
		if plr == Players.LocalPlayer then
			continue
		end

		local color
		if state then
			color = plr.TeamColor.Color
		else
			color = Options.PlayerESPColorPicker.Value
		end

		ESPLibrary:UpdateESP(plr.Character, plr.Name, color)
	end
end)

Options.ESPTransitingTime:OnChanged(function(value)
	ESPLibrary:SetFadeTime(value)
end)

Toggles.ESPArrows:OnChanged(function(state)
	ESPLibrary:SetArrows(state)
end)

Toggles.ESPTracers:OnChanged(function(state)
	ESPLibrary:SetTracers(state)
end)

Toggles.ESPShowDistance:OnChanged(function(state)
	ESPLibrary:SetShowDistance(state)
end)

Options.ESPMode:OnChanged(function()
	ESPLibrary:SetESPMode(Options.ESPMode.Value)
end)

function CustomESP(part)
	if CustomESPs[part] then
		return
	end
	local dtr = part.Destroying:Connect(function()
		RemoveCustomESP(part)
	end)
	ESPLibrary:AddESP({
		Object = part,
		Text = part.Name,
		Color = Options.DefaultCustomESPColorPicker.Value,
	})
	CustomESPs[part] = setmetatable({
		Name = part.Name,
		Object = part,
		Color = Options.DefaultCustomESPColorPicker.Value,
		DestroyFunc = dtr,
	}, {
		__tostring = function(Table)
			return Table["Name"] or "未知名称"
		end,
	})
	Options.CustomESPs:SetValues(CustomESPs)
end

function RemoveCustomESP(part)
	if not CustomESPs[part] then
		return
	end
	ESPLibrary:RemoveESP(part)
	CustomESPs[part].DestroyFunc:Disconnect()
	CustomESPs[part] = nil
	Options.CustomESPs:SetValues(CustomESPs)
end

Options.CustomESPColorPicker:OnChanged(function(color)
	for i, Table in pairs(Options.CustomESPs:GetActiveValues()) do
		local part = Table.Object
		Table["Color"] = color
		ESPLibrary:UpdateESP(part, part.Name, color)
	end
end)

Options.CustomESPs:OnChanged(function()
	local values = Options.CustomESPs:GetActiveValues()
	if #values == 1 then
		Options.CustomESPName:SetValue(values[1].Name)
		Options.CustomESPColorPicker:SetValueRGB(values[1].Color)
	end
end)

Toggles.EnableSpeedControl:OnChanged(function(state)
	if state then
		Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = Options.SpeedControl.Value
	else
		Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
	end
end)

Options.SpeedControl:OnChanged(function(value)
	if Toggles.EnableSpeedControl.Value then
		Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = value
	end
end)

Toggles.EnableJumpPower:OnChanged(function(state)
	local plr = Players.LocalPlayer
	local jpower = if state then Options.JumpPower.Value else 50
	if plr.Character:FindFirstChildOfClass("Humanoid").UseJumpPower then
		plr.Character:FindFirstChildOfClass("Humanoid").JumpPower = jpower
	else
		plr.Character:FindFirstChildOfClass("Humanoid").JumpHeight = jpower
	end
end)

Options.JumpPower:OnChanged(function(value)
	if Toggles.EnableJumpPower.Value then
		local plr = Players.LocalPlayer
		if plr.Character:FindFirstChildOfClass("Humanoid").UseJumpPower then
			plr.Character:FindFirstChildOfClass("Humanoid").JumpPower = value
		else
			plr.Character:FindFirstChildOfClass("Humanoid").JumpHeight = value
		end
	end
end)

Toggles.EnableFly:OnChanged(function(state)
	if state then
		fly()
	else
		unfly()
	end
end)

local NoclipParts = {}
local Noclipping = nil
Toggles.EnableNoclip:OnChanged(function(state)
	if state then
		pcall(function()
			Noclipping:Disconnect()
		end)
		task.wait(0.1)
		NoclipParts = {}
		Noclipping = RunService.Stepped:Connect(function()
			if Players.LocalPlayer.Character ~= nil then
				for _, child in pairs(Players.LocalPlayer.Character:GetDescendants()) do
					if child:IsA("BasePart") and child.CanCollide == true then
						child.CanCollide = false
						NoclipParts[child] = true
					end
				end
			end
		end)
	else
		pcall(function()
			Noclipping:Disconnect()
		end)
		task.wait(0.1)
		for child, _ in pairs(NoclipParts) do
			if typeof(child) == "Instance" and child:IsA("BasePart") and child.Parent then
				child.CanCollide = true
			end
		end
		NoclipParts = {}
	end
end)

local PromptButtonHoldBegan = nil
Toggles.instantproximityprompts:OnChanged(function(state)
	if state then
		PromptButtonHoldBegan = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
			fireproximityprompt(prompt)
		end)
	else
		PromptButtonHoldBegan:Disconnect()
		PromptButtonHoldBegan = nil
	end
end)

local originalLighting = {}
local fullbrightEffects = {}
Toggles.FullBright:OnChanged(function(state)
	if state then
		originalLighting = {
			Brightness = Lighting.Brightness,
			ClockTime = Lighting.ClockTime,
			FogEnd = Lighting.FogEnd,
			GlobalShadows = Lighting.GlobalShadows,
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
		}
		for _, e in ipairs(Lighting:GetChildren()) do
			if
				e:IsA("BlurEffect")
				or e:IsA("ColorCorrectionEffect")
				or e:IsA("DepthOfFieldEffect")
				or e:IsA("SunRaysEffect")
			then
				fullbrightEffects[e] = e.Enabled
				e.Enabled = false
			end
		end
		Lighting.Brightness = Options.Brightness.Value
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
	else
		Lighting.Brightness = originalLighting.Brightness
		Lighting.ClockTime = originalLighting.ClockTime
		Lighting.FogEnd = originalLighting.FogEnd
		Lighting.GlobalShadows = originalLighting.GlobalShadows
		Lighting.Ambient = originalLighting.Ambient
		Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
		for effect, wasEnabled in pairs(fullbrightEffects) do
			if effect and effect.Parent then
				effect.Enabled = wasEnabled
			end
		end
		fullbrightEffects = {}
	end
end)

Options.Brightness:OnChanged(function(value)
	if Toggles.FullBright.Value then
		Lighting.Brightness = value
	end
end)

Toggles.Nofog:OnChanged(function(state)
	if state then
		Lighting.FogEnd = 100000
		for i, v in pairs(Lighting:GetDescendants()) do
			if v:IsA("Atmosphere") then
				v:Destroy()
			end
		end
	else
		Library:Notify("温馨提示: 无法关闭:)")
	end
end)

Toggles.CameraMode:OnChanged(function(state)
	if state then
		Players.LocalPlayer.CameraMode = Enum.CameraMode.Classic
	else
		Players.LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end)

Options.Fov:OnChanged(function(value)
	Workspace.CurrentCamera.FieldOfView = value
end)

local objAdded
Toggles.MonsterNotify:OnChanged(function(state)
	if state then
		objAdded = Workspace.ChildAdded:Connect(function(obj)
			if obj.Name == "RushMoving" then
				Library:Notify("Rush 生成!")
				if Toggles.MonsterChat.Value then
					chatMessage("Rush 生成!")
				end
			end
		end)
	else
		objAdded:Disconnect()
		objAdded = nil
	end
end)

local scpRemovedSignal
local scpNotify
Toggles.Auto035:OnChanged(function(state)
	if state then
		if Workspace:FindFirstChild("SCP-035") then
			scpNotify = Library:Notify({
				Title = "警告",
				Description = "SCP-035存在,等待消灭SCP-035中...",
				Persist = true,
			})
		else
			fireclickdetector(Workspace.Facility.Special["SCP-035"].ClickDetector)
		end
		scpRemovedSignal = Workspace.ChildRemoved:Connect(function(child)
			if child.Name == "SCP-035" then
				if scpNotify then
					scpNotify:Destroy()
				end
				fireclickdetector(Workspace.Facility.Special["SCP-035"].ClickDetector)
			end
		end)
	else
		scpRemovedSignal:Disconnect()
		scpRemovedSignal = nil
	end
end)

local scpchrAdded
Toggles.AutoClothes:OnChanged(function(state)
	if state then
		fireclickdetector(Workspace.Facility.Special["Clothes Giver"].ClickPart.ClickDetector)
		scpchrAdded = Players.LocalPlayer.CharacterAdded:Connect(function()
			fireclickdetector(Workspace.Facility.Special["Clothes Giver"].ClickPart.ClickDetector)
		end)
	else
		scpchrAdded:Disconnect()
		scpchrAdded = nil
	end
end)
