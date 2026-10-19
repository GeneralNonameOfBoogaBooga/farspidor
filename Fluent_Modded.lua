-- Bloomware UI 1.4.1, based on Fluent 1.1.0 by dawid (MIT).
local function formatFluentError(message)
    local text = tostring(message)
    if debug and type(debug.traceback) == "function" then
        local ok, traceback = pcall(debug.traceback, text, 2)
        if ok then return traceback end
    end
    return text
end

local function runFluentStartup(stage, callback)
    print("[Fluent] " .. stage .. " started")
    local completed = false
    local timeout = task.delay(15, function()
        if not completed then
            warn("[Fluent] " .. stage .. " is still waiting after 15 seconds.")
        end
    end)
    local result = table.pack(xpcall(callback, formatFluentError))
    completed = true
    if timeout and type(task.cancel) == "function" then pcall(task.cancel, timeout) end
    if not result[1] then
        local message = "[Fluent] " .. stage .. " failed:\n" .. tostring(result[2])
        warn(message)
        error(message, 0)
    end
    print("[Fluent] " .. stage .. " finished")
    return table.unpack(result, 2, result.n)
end

local moduleTree, getModuleContext = {
	{1, "ModuleScript", {"MainModule"}, {
		{2, "ModuleScript", {"Acrylic"}, {
			{3, "ModuleScript", {"AcrylicBlur"}},
			{4, "ModuleScript", {"AcrylicPaint"}},
			{5, "ModuleScript", {"CreateAcrylic"}},
			{6, "ModuleScript", {"Utils"}}
		}},
		{7, "Folder", {"Components"}, {
			{8, "ModuleScript", {"Assets"}},
			{9, "ModuleScript", {"Button"}},
			{10, "ModuleScript", {"Dialog"}},
			{11, "ModuleScript", {"Element"}},
			{12, "ModuleScript", {"Notification"}},
			{13, "ModuleScript", {"Section"}},
			{14, "ModuleScript", {"Tab"}},
			{15, "ModuleScript", {"Textbox"}},
			{16, "ModuleScript", {"TitleBar"}},
			{17, "ModuleScript", {"Window"}},
			{54, "ModuleScript", {"ProfilePanel"}},
			{55, "ModuleScript", {"SearchPanel"}}
		}},
		{18, "ModuleScript", {"Creator"}},
		{19, "ModuleScript", {"Elements"}, {
			{20, "ModuleScript", {"Button"}},
			{21, "ModuleScript", {"Colorpicker"}},
			{22, "ModuleScript", {"Dropdown"}},
			{23, "ModuleScript", {"Input"}},
			{24, "ModuleScript", {"Keybind"}},
			{25, "ModuleScript", {"Paragraph"}},
			{26, "ModuleScript", {"Slider"}},
			{27, "ModuleScript", {"Toggle"}}
		}},
		{28, "ModuleScript", {"Icons"}},
		{29, "Folder", {"Packages"}, {
			{30, "ModuleScript", {"Flipper"}, {
				{31, "ModuleScript", {"BaseMotor"}},
				{32, "ModuleScript", {"BaseMotor.spec"}},
				{33, "ModuleScript", {"GroupMotor"}},
				{34, "ModuleScript", {"GroupMotor.spec"}},
				{35, "ModuleScript", {"Instant"}},
				{36, "ModuleScript", {"Instant.spec"}},
				{37, "ModuleScript", {"Linear"}},
				{38, "ModuleScript", {"Linear.spec"}},
				{39, "ModuleScript", {"Signal"}},
				{40, "ModuleScript", {"Signal.spec"}},
				{41, "ModuleScript", {"SingleMotor"}},
				{42, "ModuleScript", {"SingleMotor.spec"}},
				{43, "ModuleScript", {"Spring"}},
				{44, "ModuleScript", {"Spring.spec"}},
				{45, "ModuleScript", {"isMotor"}},
				{46, "ModuleScript", {"isMotor.spec"}}
			}}
		}},
		{47, "ModuleScript", {"Themes"}, {
			{48, "ModuleScript", {"Amethyst"}},
			{49, "ModuleScript", {"Aqua"}},
			{50, "ModuleScript", {"Dark"}},
			{51, "ModuleScript", {"Darker"}},
			{52, "ModuleScript", {"Light"}},
			{53, "ModuleScript", {"Rose"}}
		}},
		{56, "ModuleScript", {"Profiles"}},
		{57, "ModuleScript", {"SearchIndex"}},
		{58, "ModuleScript", {"Appearance"}}
	}}
}
local moduleFactories = {
	-- Module: MainModule
	[1] = function()
		local __context, script, require = getModuleContext(1)
		-- Bloomware UI 1.4, based on Fluent 1.1.0 by dawid (MIT).
		local Players = game:GetService("Players")
		local LocalPlayer = Players.LocalPlayer
		if not LocalPlayer then
		    local deadline = os.clock() + 10
		    repeat
		        task.wait(0.05)
		        LocalPlayer = Players.LocalPlayer
		    until LocalPlayer or os.clock() >= deadline
		end
		assert(LocalPlayer, "LocalPlayer was not available within 10 seconds; run this library on the client.")
		local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
		assert(PlayerGui and PlayerGui:IsA("PlayerGui"), "PlayerGui was not available within 10 seconds.")
		local Creator = require(script.Creator)
		local Elements = require(script.Elements)
		local Acrylic = require(script.Acrylic)
		local Notification = require(script.Components.Notification)
		local ScreenGui = Creator.New("ScreenGui", { Name = "BloomwareUI" })
		ScreenGui.Parent = PlayerGui
		Notification:Init(ScreenGui)

		local Fluent = {
		    Version = "1.4.1-bloom", OpenFrames = {}, Options = {},
		    Themes = require(script.Themes).Names,
		    Window = nil, WindowFrame = nil, Unloaded = false, Theme = "Dark",
		    DialogOpen = false, UseAcrylic = false, Acrylic = false, Transparency = true,
		    MinimizeKeybind = nil, MinimizeKey = Enum.KeyCode.LeftControl, GUI = ScreenGui,
		}

		local layoutEvent = Instance.new("BindableEvent")
		layoutEvent.Name = "LayoutChanged"
		layoutEvent.Parent = ScreenGui
		Fluent.LayoutChanged = layoutEvent.Event
		Fluent._LayoutEvent = layoutEvent
		Fluent.Search = require(script.SearchIndex).new()

		function Fluent:SafeCallback(callback, ...)
		    if not callback or self.Unloaded then return true end
		    if self._CallbackQueue then
		        table.insert(self._CallbackQueue, { Callback=callback, Args=table.pack(...) })
		        return true
		    end
		    local success, result = pcall(callback, ...)
		    if not success then
		        result = tostring(result)
		        warn("[Fluent] Callback failed: " .. result)
		        self:Notify({ Title = "Interface", Content = "Callback error", SubContent = result:gsub("^.-:%d+: ", ""), Duration = 5 })
		    end
		    return success, result
		end

		function Fluent:Round(value, decimals)
		    local factor = 10 ^ (decimals or 0)
		    return math.floor(tonumber(value) * factor + 0.5) / factor
		end

		local icons = require(script.Icons).assets
		function Fluent:GetIcon(name)
		    if type(name) == "string" then return icons["lucide-" .. name] end
		    return nil
		end

		local elementMethods = {}
		elementMethods.__index = elementMethods
		for _, element in ipairs(Elements) do
		    elementMethods["Add" .. element.__type] = function(container, ...)
		        -- Per-call context prevents callbacks from being redirected to a later tab.
		        local context = setmetatable({
		            Container = container.Container, Type = container.Type,
		            ScrollFrame = container.ScrollFrame, Library = Fluent,
		        }, { __index = element })
		        local args = table.pack(...)
		        local option = element.New(context, table.unpack(args, 1, args.n))
		        local config = type(args[1]) == "table" and args[1] or args[2] or {}
		        local id = type(args[1]) ~= "table" and args[1] or nil
		        local card = option._Element or (option.Frame and option)
		        if card then
		            if config.Searchable ~= false then
		                Fluent.Search:Add(card, { Tab=container.Tab, Section=container.SectionName, Id=id })
		                local function refreshSearch() if Fluent.Search.Changed then Fluent.Search.Changed() end end
		                Creator.AddSignal(card.TitleLabel:GetPropertyChangedSignal("Text"), refreshSearch, card.Frame)
		                Creator.AddSignal(card.DescLabel:GetPropertyChangedSignal("Text"), refreshSearch, card.Frame)
		            end
		            if Fluent.Profiles then Fluent.Profiles:Register(id, option, config) end
		            Creator.AddSignal(card.Frame.Destroying, function()
		                Fluent.Search:Remove(card)
		                if Fluent.Profiles then Fluent.Profiles:Unregister(id, option) end
		            end)
		        end
		        return option
		    end
		end
		Fluent.Elements = elementMethods

		local function createWindow(self, config)
		    assert(type(config) == "table" and config.Title, "Window - Missing Title")
		    if self.Unloaded then error("This interface has been destroyed; load a new instance.") end
		    if self.Window then return self.Window end
		    self.MinimizeKey = config.MinimizeKey or self.MinimizeKey
		    self.UseAcrylic = config.Acrylic == true
		    self.Acrylic = self.UseAcrylic
		    if self.UseAcrylic then Acrylic.init() end
		    self.Profiles = require(script.Profiles).new(self, config)
		    local window = require(script.Components.Window)({
		        Parent = ScreenGui, Size = config.Size or UDim2.fromOffset(840, 560),
		        Title = config.Title, SubTitle = config.SubTitle or "", TabWidth = config.TabWidth or 174,
		        Logo = config.Logo, AutoScale = config.AutoScale ~= false, MobileMode=config.MobileMode, Search=config.Search ~= false, Profiles=config.Profiles ~= false,
		    })
		    self.Window = window
		    self.WindowFrame = window.Root
		    self:SetTheme(config.Theme or "Dark")
		    self:ToggleTransparency(config.Transparency ~= false)
		    self.Appearance = require(script.Appearance).new(self, config)
		    if config.Appearance ~= false then self.Appearance:BindWindow(window) end
		    return window
		end

		function Fluent:CreateWindow(config)
		    return runFluentStartup("CreateWindow", function()
		        return createWindow(self, config)
		    end)
		end

		function Fluent:SetBackgroundImage(source)
		    if not self.Appearance then return false, "Create an interface window first." end
		    return self.Appearance:Apply(source)
		end

		function Fluent:ClearBackgroundImage()
		    if not self.Appearance then return false end
		    return self.Appearance:Clear()
		end

		function Fluent:SetBackgroundTransparency(value)
		    if not self.Appearance then return false end
		    local ok = self.Appearance:SetTransparency(value)
		    self.Appearance:_Sync(false)
		    return ok
		end

		function Fluent:SetBackgroundDarkness(value)
		    if not self.Appearance then return false end
		    local ok = self.Appearance:SetDarkness(value)
		    self.Appearance:_Sync(false)
		    return ok
		end

		function Fluent:SetBackgroundScaleType(value)
		    if not self.Appearance then return false end
		    local ok = self.Appearance:SetScaleType(value)
		    self.Appearance:_Sync(false)
		    return ok
		end

		function Fluent:SetTheme(name)
		    if table.find(self.Themes, name) then
		        local changed = self.Theme ~= name
		        self.Theme = name; Creator.UpdateTheme()
		        if changed and self.Profiles then self.Profiles:MarkDirty() end
		    end
		end

		function Fluent:ClosePopups()
		    for _, option in pairs(self.Options) do
		        if option.Type == "Dropdown" and option.Opened then option:Close() end
		    end
		end

		function Fluent:Destroy()
		    if self.Unloaded then return end
		    self:ClosePopups()
		    self.Unloaded = true
		    if self.Appearance then self.Appearance:Destroy() end
		    if self.Window then self.Window:Destroy() end
		    Acrylic.Destroy()
		    Creator.Disconnect()
		    ScreenGui:Destroy()
		    table.clear(self.Options)
		    table.clear(self.OpenFrames)
		    self.Search:Destroy()
		    if self.Profiles then self.Profiles:Destroy() end
		    self.Window = nil
		    self.WindowFrame = nil
		    self.Appearance = nil
		    if getgenv and getgenv().Fluent == self then getgenv().Fluent = nil end
		end

		function Fluent:ToggleAcrylic(enabled)
		    if not self.Window or not self.UseAcrylic then return end
		    self.Acrylic = enabled == true
		    if self.Acrylic then Acrylic.Enable() else Acrylic.Disable() end
		    self.Window.AcrylicPaint.SetVisibility(not self.Window.Minimized)
		end

		function Fluent:ToggleTransparency(enabled)
		    local changed = self.Transparency ~= (enabled == true)
		    self.Transparency = enabled == true
		    if changed and self.Profiles then self.Profiles:MarkDirty() end
		    if self.Window then self.Window.AcrylicPaint.Frame.Background.BackgroundTransparency = self.Transparency and 0.06 or 0 end
		end

		function Fluent:Notify(config)
		    if self.Unloaded then return nil end
		    return Notification:New(config)
		end

		if getgenv then getgenv().Fluent = Fluent end
		return Fluent
	end,
	-- Module: MainModule/Acrylic
	[2] = function()
		local __context, script, require = getModuleContext(2)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local Lighting = game:GetService("Lighting")
		local Workspace = game:GetService("Workspace")
		local Acrylic = {
		    AcrylicBlur = require(script.AcrylicBlur),
		    CreateAcrylic = require(script.CreateAcrylic),
		    AcrylicPaint = require(script.AcrylicPaint),
		}
		local effect, enabled = nil, false
		local previous = {}
		local connections = {}

		local function capture(object)
		    if object ~= effect and object:IsA("DepthOfFieldEffect") and previous[object] == nil then
		        previous[object] = object.Enabled
		        if enabled then object.Enabled = false end
		    end
		end

		local function watch(parent)
		    if not parent then return end
		    for _, object in ipairs(parent:GetChildren()) do capture(object) end
		    table.insert(connections, parent.ChildAdded:Connect(capture))
		end

		function Acrylic.Enable()
		    if not effect then return end
		    enabled = true
		    for object in pairs(previous) do
		        if object.Parent then object.Enabled = false end
		    end
		    effect.Parent = Lighting
		end

		function Acrylic.Disable()
		    enabled = false
		    for object, wasEnabled in pairs(previous) do
		        if object.Parent then object.Enabled = wasEnabled end
		    end
		    if effect then effect.Parent = nil end
		end

		function Acrylic.Destroy()
		    Acrylic.Disable()
		    for _, connection in ipairs(connections) do connection:Disconnect() end
		    table.clear(connections)
		    table.clear(previous)
		    if effect then effect:Destroy(); effect = nil end
		end

		function Acrylic.init()
		    if effect then Acrylic.Enable(); return end
		    effect = Instance.new("DepthOfFieldEffect")
		    effect.Name = "BloomwareAcrylic"
		    effect.FarIntensity = 0
		    effect.InFocusRadius = 0.1
		    effect.NearIntensity = 1
		    watch(Lighting)
		    watch(Workspace.CurrentCamera)
		    table.insert(connections, Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() watch(Workspace.CurrentCamera) end))
		    Acrylic.Enable()
		end

		return Acrylic
	end,
	-- Module: MainModule/Acrylic/AcrylicBlur
	[3] = function()
		local __context, script, require = getModuleContext(3)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local Workspace = game:GetService("Workspace")
		local Creator = require(script.Parent.Parent.Creator)
		local CreateAcrylic = require(script.Parent.CreateAcrylic)
		local project, inset = unpack(require(script.Parent.Utils))
		return function(distance)
		    distance = distance or 0.001
		    local frame = Creator.New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) })
		    local model = CreateAcrylic()
		    model.Parent = Workspace
		    local blur = { Frame = frame, Model = model }
		    local parent, cameraConnections, destroyed = nil, {}, false
		    local function update()
		        local camera = Workspace.CurrentCamera
		        if destroyed or not camera or not frame.Parent then return end
		        local margin = inset()
		        local position = frame.AbsolutePosition + Vector2.new(margin / 2, margin / 2)
		        local size = frame.AbsoluteSize - Vector2.new(margin, margin)
		        local a = project(position, distance)
		        local b = project(position + Vector2.new(size.X, 0), distance)
		        local c = project(position + size, distance)
		        local cf = camera.CFrame
		        model.CFrame = CFrame.fromMatrix((a + c) / 2, cf.XVector, cf.YVector, cf.ZVector)
		        model.Mesh.Scale = Vector3.new((b - a).Magnitude, (b - c).Magnitude, 0)
		    end
		    local function bindCamera()
		        for _, connection in ipairs(cameraConnections) do connection:Disconnect() end
		        table.clear(cameraConnections)
		        local camera = Workspace.CurrentCamera
		        if camera then
		            for _, property in ipairs({ "CFrame", "ViewportSize", "FieldOfView" }) do
		                table.insert(cameraConnections, camera:GetPropertyChangedSignal(property):Connect(update))
		            end
		        end
		        update()
		    end
		    function blur.SetVisibility(visible)
		        if destroyed then return end
		        local Library = require(script.Parent.Parent)
		        model.Transparency = visible and Library.Acrylic and (not parent or parent.Visible) and 0.98 or 1
		    end
		    function blur.AddParent(object)
		        parent = object
		        Creator.AddSignal(object:GetPropertyChangedSignal("Visible"), function() blur.SetVisibility(object.Visible) end, frame)
		        blur.SetVisibility(object.Visible)
		    end
		    local function cleanup()
		        if destroyed then return end
		        destroyed = true
		        for _, connection in ipairs(cameraConnections) do connection:Disconnect() end
		        table.clear(cameraConnections)
		        model:Destroy()
		    end
		    Creator.AddSignal(frame.Destroying, cleanup)
		    Creator.AddSignal(frame:GetPropertyChangedSignal("AbsolutePosition"), update, frame)
		    Creator.AddSignal(frame:GetPropertyChangedSignal("AbsoluteSize"), update, frame)
		    Creator.AddSignal(Workspace:GetPropertyChangedSignal("CurrentCamera"), bindCamera, frame)
		    bindCamera()
		    return blur
		end
	end,
	-- Module: MainModule/Acrylic/AcrylicPaint
	[4] = function()
		local __context, script, require = getModuleContext(4)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local Creator = require(script.Parent.Parent.Creator)
		local New = Creator.New
		return function()
		    local paint = {}
		    local background = New("Frame", {
		        Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.06,
		        ThemeTag = { BackgroundColor3 = "AcrylicMain" },
		    }, { New("UICorner", { CornerRadius = UDim.new(0, 14) }) })
		    paint.BackgroundImage = New("ImageLabel", {
		        Name = "CustomBackground", Size = UDim2.fromScale(1, 1), Visible = false,
		        BackgroundTransparency = 1, Image = "", ImageTransparency = 0.25,
		        ScaleType = Enum.ScaleType.Crop, Active = false,
		    }, { New("UICorner", { CornerRadius = UDim.new(0, 14) }) })
		    paint.BackgroundOverlay = New("Frame", {
		        Name = "BackgroundDim", Size = UDim2.fromScale(1, 1), Visible = false,
		        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.65, Active = false,
		    }, { New("UICorner", { CornerRadius = UDim.new(0, 14) }) })
		    paint.Frame = New("Frame", {
		        Name = "WindowSurface", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		    }, {
		        New("ImageLabel", {
		            Image = "rbxassetid://8992230677", ScaleType = Enum.ScaleType.Slice,
		            SliceCenter = Rect.new(Vector2.new(99, 99), Vector2.new(99, 99)),
		            Size = UDim2.new(1, 70, 1, 70), Position = UDim2.fromOffset(-35, -28),
		            ImageColor3 = Color3.fromRGB(0, 0, 0), ImageTransparency = 0.48,
		        }), background, paint.BackgroundImage, paint.BackgroundOverlay,
		        New("Frame", {
		            Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.94,
		        }, {
		            New("UICorner", { CornerRadius = UDim.new(0, 14) }),
		            New("UIGradient", { Rotation = 115, ThemeTag = { Color = "AcrylicGradient" } }),
		        }),
		        New("ImageLabel", {
		            Image = "rbxassetid://9968344227", ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(128, 128),
		            Size = UDim2.fromScale(1, 1), ThemeTag = { ImageTransparency = "AcrylicNoise" },
		        }, { New("UICorner", { CornerRadius = UDim.new(0, 14) }) }),
		        New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, {
		            New("UICorner", { CornerRadius = UDim.new(0, 14) }),
		            New("UIStroke", { Transparency = 0.3, Thickness = 1, ThemeTag = { Color = "AcrylicBorder" } }),
		        }),
		    })
		    paint.SetVisibility = function() end
		    paint.AddParent = function() end
		    if require(script.Parent.Parent).UseAcrylic then
		        local blur = require(script.Parent.AcrylicBlur)()
		        blur.Frame.Parent = paint.Frame
		        paint.Model, paint.AddParent, paint.SetVisibility = blur.Model, blur.AddParent, blur.SetVisibility
		    end
		    return paint
		end
	end,
	-- Module: MainModule/Acrylic/CreateAcrylic
	[5] = function()
		local __context, script, require = getModuleContext(5)
		-- Reconstructed module: MainModule/Acrylic/CreateAcrylic
		-- Author: dawid | License: MIT (original Fluent header).
		local Parent = script.Parent.Parent
		local Creator_4 = require(Parent.Creator)
		local callback_10 = function()
			local Part = Creator_4.New("Part", {
				Name = "Body",
				Color = Color3.new(0, 0, 0),
				Material = Enum.Material.Glass,
				Size = Vector3.new(1, 1, 0),
				Anchored = true,
				CanCollide = false,
				Locked = true,
				CastShadow = false,
				Transparency = 0.98,
			}, {
				Creator_4.New("SpecialMesh", {
					MeshType = Enum.MeshType.Brick,
					Offset = Vector3.new(0, 0, -1e-06),
				}),
			})
			return Part
		end
		return callback_10
	end,
	-- Module: MainModule/Acrylic/Utils
	[6] = function()
		local __context, script, require = getModuleContext(6)
		-- Reconstructed module: MainModule/Acrylic/Utils
		-- Author: dawid | License: MIT (original Fluent header).
		local callback_11, callback_12 =
			function(argument_15, argument_16, argument_17, argument_18, argument_19)
				return (argument_15 - argument_16) * (argument_19 - argument_18) / (argument_17 - argument_16) + argument_18
			end, function(argument_20, argument_21)
				local ray = game:GetService("Workspace").CurrentCamera:ViewportPointToRay(argument_20.X, argument_20.Y)
				return ray.Origin + ray.Direction * argument_21
			end
		local callback_13 = function()
			local Y = game:GetService("Workspace").CurrentCamera.ViewportSize.Y
			return callback_11(Y, 0, 2560, 8, 56)
		end
		return {
			callback_12,
			callback_13,
		}
	end,
	-- Module: MainModule/Components/Assets
	[8] = function()
		local __context, script, require = getModuleContext(8)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local Assets = {
		    Close = "rbxassetid://9886659671", Min = "rbxassetid://9886659276",
		    Max = "rbxassetid://9886659406", Restore = "rbxassetid://9886659001",
		    LogoURL = "https://raw.githubusercontent.com/GeneralNonameOfBoogaBooga/farspidor/refs/heads/main/bloom-logo.png",
		}
		local cached = {}

		-- ImageLabel needs an asset URI. Raw PNGs require a supported local-asset bridge.
		-- Native Roblox clients can supply CreateWindow({ Logo = "rbxassetid://..." }).
		function Assets.ResolveLogo(source)
		    if source == false then return nil end
		    source = source or Assets.LogoURL
		    if type(source) == "number" then return "rbxassetid://" .. tostring(source) end
		    if type(source) ~= "string" then return nil end
		    if not source:match("^https?://") or source:find("roblox.com/asset", 1, true) then return source end
		    if cached[source] then return cached[source] end
		    local registerAsset = getcustomasset or getsynasset
		    if type(registerAsset) ~= "function" or type(writefile) ~= "function" then return nil end
		    local fileName = source == Assets.LogoURL and "bloomware-ui-logo.png" or "bloomware-ui-custom-logo.png"
		    local ok, uri = pcall(function()
		        if source ~= Assets.LogoURL or not (type(isfile) == "function" and isfile(fileName)) then
		            local bytes = game:HttpGet(source)
		            assert(type(bytes) == "string" and bytes:sub(1, 8) == "\137PNG\13\10\26\10", "Logo response is not a PNG")
		            writefile(fileName, bytes)
		        end
		        return registerAsset(fileName)
		    end)
		    if ok and type(uri) == "string" and uri ~= "" then cached[source] = uri; return uri end
		    return nil
		end

		local imageCache = {}
		local imageCacheOrder = {}
		local maxImageBytes = 12 * 1024 * 1024

		function Assets.NormalizeImageSource(source)
		    if type(source) == "number" and source > 0 and source % 1 == 0 and source < math.huge then
		        source = string.format("%.0f", source)
		    end
		    if type(source) ~= "string" then return nil, "Enter a direct PNG/JPG URL or a Roblox asset ID." end
		    source = source:match("^%s*(.-)%s*$")
		    if source == "" then return "" end
		    if #source > 4096 or source:find("[%c]") then return nil, "The URL is too long or contains invalid characters." end
		    local id = source:match("^rbxassetid://(%d+)$") or source:match("^(%d+)$")
		    if id then
		        if #id > 20 or not id:find("[1-9]") then return nil, "Invalid Roblox asset ID." end
		        return "rbxassetid://" .. id
		    end
		    if source:match("^https?://[^/%s?#]+[^%s]*$") then return source end
		    return nil, "Use a direct http/https image URL or a Roblox asset ID."
		end

		local function cacheName(source, extension)
		    local a, b = 5381, 2166136261
		    for i = 1, #source do
		        local byte = source:byte(i)
		        a = (a * 33 + byte) % 4294967296
		        b = (b * 65599 + byte) % 4294967296
		    end
		    return string.format("bloomware-ui-background-%08x%08x.%s", a, b, extension)
		end

		-- Check downloaded bytes and register a local image URI before changing the background.
		function Assets.ResolveImage(source)
		    local normalized, message = Assets.NormalizeImageSource(source)
		    if not normalized then return nil, message end
		    if normalized == "" then return nil, "No image URL was provided." end
		    if normalized:match("^rbxassetid://") then return normalized end
		    if imageCache[normalized] then return imageCache[normalized] end
		    local registerAsset = getcustomasset or getsynasset
		    if type(registerAsset) ~= "function" or type(writefile) ~= "function" then
		        return nil, "Image URLs are unavailable in this environment. Use rbxassetid://ID."
		    end
		    local downloaded, bytes = pcall(function() return game:HttpGet(normalized) end)
		    if not downloaded or type(bytes) ~= "string" or #bytes == 0 then
		        return nil, "Could not download the image. Check the URL and your connection."
		    end
		    if #bytes > maxImageBytes then return nil, "The image exceeds 12 MB. Choose a smaller file." end
		    local extension
		    if bytes:sub(1, 8) == "\137PNG\13\10\26\10" then extension = "png"
		    elseif bytes:sub(1, 3) == "\255\216\255" then extension = "jpg"
		    else return nil, "The URL must point directly to a PNG or JPG image file." end
		    local ok, uri = pcall(function()
		        local fileName = cacheName(normalized, extension)
		        writefile(fileName, bytes)
		        return registerAsset(fileName)
		    end)
		    if not ok or type(uri) ~= "string" or uri == "" then
		        return nil, "Could not open the downloaded image. Try a Roblox asset ID."
		    end
		    imageCache[normalized] = uri
		    table.insert(imageCacheOrder, normalized)
		    if #imageCacheOrder > 16 then imageCache[table.remove(imageCacheOrder, 1)] = nil end
		    return uri
		end

		return Assets
	end,
	-- Module: MainModule/Components/Button
	[9] = function()
		local __context, script, require = getModuleContext(9)
		-- Reconstructed module: MainModule/Components/Button
		-- Author: dawid | License: MIT (original Fluent header).
		local Parent_2 = script.Parent.Parent
		local Flipper, Creator_5 = require(Parent_2.Packages.Flipper), require(Parent_2.Creator)
		local New_3, new = Creator_5.New, Flipper.Spring.new
		return function(argument_22, argument_23, argument_24)
			argument_24 = argument_24 or false
			local object_8 = {}
			object_8.Title = New_3("TextLabel", {
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ThemeTag = {
					TextColor3 = "Text",
				},
			})
			object_8.HoverFrame = New_3("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ThemeTag = {
					BackgroundColor3 = "Hover",
				},
			}, {
				New_3("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}),
			})
			object_8.Frame = New_3("TextButton", {
				Size = UDim2.new(0, 0, 0, require(Parent_2).Mobile and 44 or 32),
				Parent = argument_23,
				ThemeTag = {
					BackgroundColor3 = "DialogButton",
				},
			}, {
				New_3("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}),
				New_3("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Transparency = 0.65,
					ThemeTag = {
						Color = "DialogButtonBorder",
					},
				}),
				object_8.HoverFrame,
				object_8.Title,
			})
			local SpringMotor, result_2 =
				Creator_5.SpringMotor(1, object_8.HoverFrame, "BackgroundTransparency", argument_24)
			Creator_5.AddSignal(object_8.Frame.MouseEnter, function()
				result_2(0.97)
			end)
			Creator_5.AddSignal(object_8.Frame.MouseLeave, function()
				result_2(1)
			end)
			Creator_5.AddSignal(object_8.Frame.MouseButton1Down, function()
				result_2(1)
			end)
			Creator_5.AddSignal(object_8.Frame.MouseButton1Up, function()
				result_2(0.97)
			end)
			return object_8
		end
	end,
	-- Module: MainModule/Components/Dialog
	[10] = function()
		local __context, script, require = getModuleContext(10)
		-- Reconstructed module: MainModule/Components/Dialog
		-- Author: dawid | License: MIT (original Fluent header).
		local UserInputService_2, Mouse_2, CurrentCamera_5, Parent_3 =
			game:GetService("UserInputService"),
			game:GetService("Players").LocalPlayer:GetMouse(),
			game:GetService("Workspace").CurrentCamera,
			script.Parent.Parent
		local Flipper_2, Creator_6 = require(Parent_3.Packages.Flipper), require(Parent_3.Creator)
		local new_2, new_3, New_4, object_9 =
			Flipper_2.Spring.new, Flipper_2.Instant.new, Creator_6.New, {
				Window = nil,
			}
		function object_9.Init(self_11, argument_25)
			object_9.Window = argument_25
			return object_9
		end
		function object_9.Create(self_12)
			local object_10 = {
				Buttons = 0,
		        Closed = false,
			}
			object_10.TintFrame = New_4("TextButton", {
				Text = "",
		        ZIndex = 70,
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 1,
				Parent = object_9.Window.Root,
			}, {
				New_4("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			})
			local SpringMotor_2, result_3 =
				Creator_6.SpringMotor(1, object_10.TintFrame, "BackgroundTransparency", true)
			object_10.ButtonHolder = New_4("Frame", {
				Size = UDim2.new(1, -40, 1, -40),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,
			}, {
				New_4("UIListLayout", {
					Padding = UDim.new(0, 10),
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			})
			object_10.ButtonHolderFrame = New_4("Frame", {
				Size = UDim2.new(1, 0, 0, 70),
				Position = UDim2.new(0, 0, 1, -70),
				ThemeTag = {
					BackgroundColor3 = "DialogHolder",
				},
			}, {
				New_4("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					ThemeTag = {
						BackgroundColor3 = "DialogHolderLine",
					},
				}),
				object_10.ButtonHolder,
			})
			object_10.Title = New_4("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.SemiBold,
					Enum.FontStyle.Normal
				),
				Text = "Dialog",
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, -40, 0, 22),
		        TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.fromOffset(20, 25),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				ThemeTag = {
					TextColor3 = "Text",
				},
			})
			object_10.Scale = New_4("UIScale", {
				Scale = 1,
			})
			local SpringMotor_3, result_4 = Creator_6.SpringMotor(1.1, object_10.Scale, "Scale")
			object_10.Root = New_4("CanvasGroup", {
				Size = UDim2.fromOffset(300, 165),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				GroupTransparency = 1,
				Parent = object_10.TintFrame,
				ThemeTag = {
					BackgroundColor3 = "Dialog",
				},
			}, {
				New_4("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
				New_4("UIStroke", {
					Transparency = 0.5,
					ThemeTag = {
						Color = "DialogBorder",
					},
				}),
				object_10.Scale,
				object_10.Title,
				object_10.ButtonHolderFrame,
			})
			local SpringMotor_4, result_5 = Creator_6.SpringMotor(1, object_10.Root, "GroupTransparency")
		    local function fitScale()
		        local window = object_9.Window
		        object_10.BaseScale = math.max(0.1, math.min(1,
		            (window.Size.X.Offset - 24) / math.max(1, object_10.Root.Size.X.Offset),
		            (window.Size.Y.Offset - 24) / math.max(1, object_10.Root.Size.Y.Offset)))
		        return object_10.BaseScale
		    end
		    Creator_6.AddSignal(object_9.Window.Root:GetPropertyChangedSignal("Size"), function()
		        if not object_10.Closed then result_4(fitScale()) end
		    end, object_10.Root)
		    Creator_6.AddSignal(object_10.TintFrame.Destroying, function()
		        object_10.Closed = true
		        if object_9.Active == object_10 then object_9.Active = nil; require(Parent_3).DialogOpen = false end
		    end)
			function object_10.Open(self_13)
				object_9.Active = object_10
		        require(Parent_3).DialogOpen = true
				object_10.Scale.Scale = fitScale() * 1.03
				result_3(0.75)
				result_5(0)
				result_4(object_10.BaseScale)
			end
			function object_10.Close(self_14)
		        if object_10.Closed then return end
		        object_10.Closed = true
				if object_9.Active == object_10 then object_9.Active = nil; require(Parent_3).DialogOpen = false end
				result_3(1)
				result_5(1)
				result_4((object_10.BaseScale or 1) * 1.03)
				object_10.Root.UIStroke:Destroy()
				task.wait(0.15)
				object_10.TintFrame:Destroy()
			end
			function object_10.Button(self_15, argument_26, argument_27)
				object_10.Buttons = object_10.Buttons + 1
				argument_26 = argument_26 or "Button"
				argument_27 = argument_27 or function() end
				local value_10 = require(Parent_3.Components.Button)("", object_10.ButtonHolder, true)
				value_10.Title.Text = argument_26
				for key_7, item_7 in next, object_10.ButtonHolder:GetChildren() do
					if item_7:IsA("TextButton") then
						item_7.Size = UDim2.new(
							1 / object_10.Buttons,
							-(((object_10.Buttons - 1) * 10) / object_10.Buttons),
							0,
							require(Parent_3).Mobile and 44 or 32
						)
					end
				end
				Creator_6.AddSignal(value_10.Frame.Activated, function()
					require(Parent_3):SafeCallback(argument_27)
					pcall(function()
						object_10:Close()
					end)
				end)
				return value_10
			end
			return object_10
		end
		return object_9
	end,
	-- Module: MainModule/Components/Element
	[11] = function()
		local __context, script, require = getModuleContext(11)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local Creator = require(script.Parent.Parent.Creator)
		local Library = require(script.Parent.Parent)
		local New = Creator.New
		return function(title, description, parent, interactive)
		    local element = { Destroyed = false }
		    element.TitleLabel = New("TextLabel", {
		        Text = title or "", TextSize = 13, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
		        Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left,
		        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		        ThemeTag = { TextColor3 = "Text" },
		    })
		    element.DescLabel = New("TextLabel", {
		        Text = description or "", TextSize = 11, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
		        Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Left,
		        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		        Visible = description ~= nil and description ~= "", LayoutOrder = 1,
		        ThemeTag = { TextColor3 = "SubText" },
		    })
		    local layout = New("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
		    element.LabelHolder = New("Frame", {
		        BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 14), Size = UDim2.new(1, -28, 0, 0),
		        AutomaticSize = Enum.AutomaticSize.Y,
		    }, { layout, element.TitleLabel, element.DescLabel })
		    element.Border = New("UIStroke", {
		        Thickness = 1, Transparency = 0.52, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		        ThemeTag = { Color = "ElementBorder" },
		    })
		    element.Frame = New("TextButton", {
		        Name = "SettingCard", Text = "", BackgroundTransparency = 0.12, Size = UDim2.new(1, 0, 0, 56),
		        LayoutOrder = 7, Parent = parent,
		        ThemeTag = { BackgroundColor3 = "Element", BackgroundTransparency = "ElementTransparency" },
		    }, { New("UICorner", { CornerRadius = UDim.new(0, 10) }), element.Border, element.LabelHolder })
		    local control, options
		    local function update()
		        if element.Destroyed then return end
		        local mobile = Library.Mobile == true
		        element.TitleLabel.TextSize = mobile and 14 or 13
		        element.DescLabel.TextSize = mobile and 12 or 11
		        local scale = Creator.GetScale(element.Frame)
		        local width = element.Frame.AbsoluteSize.X / scale
		        local stacked = control and width < (options.StackWidth or 430)
		        local controlHeight = control and (mobile and (options.Height or 32) >= 28 and 44 or (options.Height or 32)) or 0
		        local controlWidth = control and math.min(options.Width or 176, math.max(40, width - 28)) or 0
		        element.LabelHolder.Size = UDim2.new(1, control and not stacked and -(controlWidth + 42) or -28, 0, 0)
		        local textHeight = layout.AbsoluteContentSize.Y / scale
		        local height = math.max(mobile and 64 or 56, textHeight + 28 + (stacked and (controlHeight + 12) or 0))
		        if element.Frame.Size.Y.Offset ~= height then element.Frame.Size = UDim2.new(1, 0, 0, height) end
		        if control then
		            control.Size = UDim2.fromOffset(controlWidth, controlHeight)
		            control.AnchorPoint = Vector2.new(1, stacked and 1 or 0.5)
		            control.Position = stacked and UDim2.new(1, -14, 1, -14) or UDim2.new(1, -14, 0.5, 0)
		        end
		    end
		    function element:SetControl(object, config)
		        control, options = object, config or {}
		        object.Parent = self.Frame
		        update()
		    end
		    function element:SetTitle(text) element.TitleLabel.Text = text or "" end
		    function element:SetDesc(text)
		        element.DescLabel.Text = text or ""
		        element.DescLabel.Visible = text ~= nil and text ~= ""
		        update()
		    end
		    function element:Destroy()
		        if self.Destroyed then return end
		        self.Destroyed = true
		        self.Frame:Destroy()
		    end
		    Creator.AddSignal(element.Frame.Destroying, function() element.Destroyed = true end)
		    Creator.AddSignal(element.Frame:GetPropertyChangedSignal("AbsoluteSize"), update, element.Frame)
		    Creator.AddSignal(layout:GetPropertyChangedSignal("AbsoluteContentSize"), update, element.Frame)
		    if interactive then
		        local _, transparency = Creator.SpringMotor(Creator.GetThemeProperty("ElementTransparency"), element.Frame, "BackgroundTransparency", false, true)
		        Creator.AddSignal(element.Frame.MouseEnter, function()
		            transparency(math.clamp(Creator.GetThemeProperty("ElementTransparency") - Creator.GetThemeProperty("HoverChange"), 0, 1))
		        end)
		        Creator.AddSignal(element.Frame.MouseLeave, function() transparency(Creator.GetThemeProperty("ElementTransparency")) end)
		    end
		    Creator.AddSignal(Library.LayoutChanged, update, element.Frame)
		    task.defer(update)
		    return element
		end
	end,
	-- Module: MainModule/Components/Notification
	[12] = function()
		local __context, script, require = getModuleContext(12)
		-- Reconstructed module: MainModule/Components/Notification
		-- Author: dawid | License: MIT (original Fluent header).
		local Parent_5 = script.Parent.Parent
		local Flipper_4, Creator_8, Acrylic_2 =
			require(Parent_5.Packages.Flipper), require(Parent_5.Creator), require(Parent_5.Acrylic)
		local new_5, new_6, New_6, object_12 = Flipper_4.Spring.new, Flipper_4.Instant.new, Creator_8.New, {}
		function object_12.Init(self_19, argument_32)
			object_12.Holder = New_6("Frame", {
				Position = UDim2.new(1, -30, 1, -30),
				Size = UDim2.new(0, 310, 1, -30),
				AnchorPoint = Vector2.new(1, 1),
				BackgroundTransparency = 1,
				Parent = argument_32,
			}, {
				New_6("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					Padding = UDim.new(0, 20),
				}),
			})
		end
		function object_12.New(self_20, argument_33)
			argument_33.Title = argument_33.Title or "Title"
			argument_33.Content = argument_33.Content or "Content"
			argument_33.SubContent = argument_33.SubContent or ""
			argument_33.Duration = argument_33.Duration or nil
			argument_33.Buttons = argument_33.Buttons or {}
			local object_13 = {
				Closed = false,
			}
			object_13.AcrylicPaint = Acrylic_2.AcrylicPaint()
			object_13.Title = New_6("TextLabel", {
				Position = UDim2.new(0, 14, 0, 17),
				Text = argument_33.Title,
				RichText = true,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextTransparency = 0,
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
				TextSize = 13,
				TextXAlignment = "Left",
				TextYAlignment = "Center",
				Size = UDim2.new(1, -12, 0, 12),
				TextWrapped = true,
				BackgroundTransparency = 1,
				ThemeTag = {
					TextColor3 = "Text",
				},
			})
			object_13.ContentLabel = New_6("TextLabel", {
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
				Text = argument_33.Content,
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 14),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				TextWrapped = true,
				ThemeTag = {
					TextColor3 = "Text",
				},
			})
			object_13.SubContentLabel = New_6("TextLabel", {
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
				Text = argument_33.SubContent,
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 14),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				TextWrapped = true,
				ThemeTag = {
					TextColor3 = "SubText",
				},
			})
			object_13.LabelHolder = New_6("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(14, 40),
				Size = UDim2.new(1, -28, 0, 0),
			}, {
				New_6("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 3),
				}),
				object_13.ContentLabel,
				object_13.SubContentLabel,
			})
			object_13.CloseButton = New_6("TextButton", {
				Text = "",
				Position = UDim2.new(1, -14, 0, 13),
				Size = UDim2.fromOffset(20, 20),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
			}, {
				New_6("ImageLabel", {
					Image = require(script.Parent.Assets).Close,
					Size = UDim2.fromOffset(16, 16),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					ThemeTag = {
						ImageColor3 = "Text",
					},
				}),
			})
			object_13.Root = New_6("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.fromScale(1, 0),
			}, {
				object_13.AcrylicPaint.Frame,
				object_13.Title,
				object_13.CloseButton,
				object_13.LabelHolder,
			})
			if argument_33.Content == "" then
				object_13.ContentLabel.Visible = false
			end
			if argument_33.SubContent == "" then
				object_13.SubContentLabel.Visible = false
			end
			object_13.Holder = New_6("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 200),
				Parent = object_12.Holder,
			}, {
				object_13.Root,
			})
			local GroupMotor = Flipper_4.GroupMotor.new({
				Scale = 1,
				Offset = 60,
			})
			GroupMotor:onStep(function(argument_34)
				object_13.Root.Position = UDim2.new(argument_34.Scale, argument_34.Offset, 0, 0)
			end)
			Creator_8.AddSignal(object_13.CloseButton.MouseButton1Click, function()
				object_13:Close()
			end)
			function object_13.Open(self_21)
				local Y_2 = object_13.LabelHolder.AbsoluteSize.Y
				object_13.Holder.Size = UDim2.new(1, 0, 0, 58 + Y_2)
				GroupMotor:setGoal({
					Scale = new_5(0, {
						frequency = 5,
					}),
					Offset = new_5(0, {
						frequency = 5,
					}),
				})
			end
			function object_13.Close(self_22)
				if not object_13.Closed then
					object_13.Closed = true
					task.spawn(function()
						GroupMotor:setGoal({
							Scale = new_5(1, {
								frequency = 5,
							}),
							Offset = new_5(60, {
								frequency = 5,
							}),
						})
						task.wait(0.4)
						if object_13.AcrylicPaint.Model then
							object_13.AcrylicPaint.Model:Destroy()
						end
						object_13.Holder:Destroy()
					end)
				end
			end
			object_13:Open()
			if argument_33.Duration then
				task.delay(argument_33.Duration, function()
					object_13:Close()
				end)
			end
			return object_13
		end
		return object_12
	end,
	-- Module: MainModule/Components/Section
	[13] = function()
		local __context, script, require = getModuleContext(13)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local Creator = require(script.Parent.Parent.Creator)
		local New = Creator.New
		return function(title, parent)
		    local section = {}
		    local layout = New("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder })
		    section.Container = New("Frame", {
		        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(0, 32),
		    }, { layout })
		    section.Root = New("Frame", {
		        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 7, Parent = parent,
		    }, {
		        New("Frame", {
		            Size = UDim2.fromOffset(3, 12), Position = UDim2.fromOffset(1, 7),
		            ThemeTag = { BackgroundColor3 = "Accent" },
		        }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
		        New("TextLabel", {
		            Text = title, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
		            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
		            TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -18, 0, 26),
		            Position = UDim2.fromOffset(12, 0), ThemeTag = { TextColor3 = "SubText" },
		        }), section.Container,
		    })
		    Creator.AddSignal(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		        local height = layout.AbsoluteContentSize.Y / Creator.GetScale(section.Root)
		        section.Container.Size = UDim2.new(1, 0, 0, height)
		        section.Root.Size = UDim2.new(1, 0, 0, height + 32)
		    end, section.Root)
		    return section
		end
	end,
	-- Module: MainModule/Components/Tab
	[14] = function()
		local __context, script, require = getModuleContext(14)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local Creator = require(script.Parent.Parent.Creator)
		local Flipper = require(script.Parent.Parent.Packages.Flipper)
		local New = Creator.New
		local Tabs = { Window = nil, Tabs = {}, Containers = {}, SelectedTab = 0, TabCount = 0, Generation = 0 }
		local defaultIcons = {
		    farm = "sprout", combat = "swords", progress = "trending-up", shop = "shopping-bag",
		    teleport = "map-pin", esp = "eye", stats = "bar-chart", misc = "layout-grid", webhooks = "link", settings = "settings",
		}
		function Tabs:Init(window)
		    self.Window, self.Tabs, self.Containers, self.SelectedTab, self.TabCount = window, {}, {}, 0, 0
		    self.Generation = self.Generation + 1
		    return self
		end
		function Tabs:GetCurrentTabPos()
		    local tab = self.Tabs[self.SelectedTab]
		    return tab and tab.Frame.AbsolutePosition.Y - self.Window.TabHolder.AbsolutePosition.Y or 0
		end
		function Tabs:New(title, iconName, parent)
		    assert(type(title) == "string", "Tab - Missing Title")
		    local Library = require(script.Parent.Parent)
		    self.TabCount = self.TabCount + 1
		    local index = self.TabCount
		    if iconName == nil then iconName = defaultIcons[title:lower()] end
		    local icon = Library:GetIcon(iconName) or iconName
		    if icon == "" then icon = nil end
		    local tab = { Selected = false, Name = title, Type = "Tab", Index=index }
		    tab.Tab = tab
		    tab.Frame = New("TextButton", {
		        Text = "", Size = UDim2.new(1, -2, 0, self.Window.Mobile and 44 or 40), BackgroundTransparency = 1, LayoutOrder = index,
		        Parent = parent, ThemeTag = { BackgroundColor3 = "Tab" },
		    }, { New("UICorner", { CornerRadius = UDim.new(0, 9) }) })
		    tab.Marker = New("Frame", {
		        Size = UDim2.fromOffset(3, 16), Position = UDim2.new(0, 0, 0.5, -8),
		        Visible = false, Parent = tab.Frame, ThemeTag = { BackgroundColor3 = "Accent" },
		    }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		    tab.Label = New("TextLabel", {
		        Text = title, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
		        TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, icon and -46 or -24, 1, 0),
		        Position = UDim2.fromOffset(icon and 38 or 14, 0), Parent = tab.Frame,
		        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		        ThemeTag = { TextColor3 = "SubText" },
		    })
		    if icon then
		        tab.Icon = New("ImageLabel", {
		            Image = icon, Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 14, 0.5, -8),
		            Parent = tab.Frame, ThemeTag = { ImageColor3 = "SubText" },
		        })
		    end
		    local layout = New("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder })
		    tab.ContainerFrame = New("ScrollingFrame", {
		        BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.fromOffset(0, 0),
		        Visible = false, ScrollBarThickness = 3, ScrollBarImageTransparency = 0.6,
		        ScrollingDirection = Enum.ScrollingDirection.Y, Parent = self.Window.ContainerHolder,
		        ThemeTag = { ScrollBarImageColor3 = "SubText" },
		    }, { layout, New("UIPadding", {
		        PaddingLeft = UDim.new(0, 1), PaddingRight = UDim.new(0, 7), PaddingTop = UDim.new(0, 1), PaddingBottom = UDim.new(0, 5),
		    }) })
		    Creator.AddSignal(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		        tab.ContainerFrame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y / Creator.GetScale(tab.ContainerFrame) + 6)
		    end, tab.ContainerFrame)
		    Creator.AddSignal(Library.LayoutChanged, function(mobile)
		        tab.Frame.Size = UDim2.new(1, -2, 0, mobile and 44 or 40)
		    end, tab.Frame)
		    tab.Motor, tab.SetTransparency = Creator.SpringMotor(1, tab.Frame, "BackgroundTransparency")
		    Creator.AddSignal(tab.Frame.MouseEnter, function() tab.SetTransparency(tab.Selected and 0.84 or 0.94) end)
		    Creator.AddSignal(tab.Frame.MouseLeave, function() tab.SetTransparency(tab.Selected and 0.89 or 1) end)
		    Creator.AddSignal(tab.Frame.Activated, function() self:SelectTab(index) end)
		    tab.Container, tab.ScrollFrame = tab.ContainerFrame, tab.ContainerFrame
		    function tab:AddSection(name)
		        local section = require(script.Parent.Section)(name, tab.Container)
		        return setmetatable({ Type = "Section", Container = section.Container, ScrollFrame = tab.Container, Tab=tab, SectionName=name }, Library.Elements)
		    end
		    setmetatable(tab, Library.Elements)
		    self.Tabs[index], self.Containers[index] = tab, tab.ContainerFrame
		    if index == 1 then self:SelectTab(1, true) end
		    return tab
		end
		function Tabs:SelectTab(index, instant)
		    if type(index) ~= "number" or not self.Tabs[index] then return false end
		    local window = self.Window
		    if window.Destroyed then return false end
		    require(script.Parent.Parent):ClosePopups()
		    if window.CloseTools then window:CloseTools() end
		    if window.SetDrawer then window:SetDrawer(false) end
		    self.SelectedTab = index
		    self.Generation = self.Generation + 1
		    local generation = self.Generation
		    for number, tab in ipairs(self.Tabs) do
		        tab.Selected = number == index
		        tab.Marker.Visible = tab.Selected
		        tab.SetTransparency(tab.Selected and 0.89 or 1)
		        Creator.OverrideTag(tab.Label, { TextColor3 = tab.Selected and "Accent" or "SubText" })
		        if tab.Icon then Creator.OverrideTag(tab.Icon, { ImageColor3 = tab.Selected and "Accent" or "SubText" }) end
		    end
		    window.TabDisplay.Text = self.Tabs[index].Name
		    local function show()
		        if generation ~= self.Generation or window.Destroyed then return end
		        for number, container in ipairs(self.Containers) do container.Visible = number == index end
		        window.ContainerPosMotor:setGoal(Flipper[instant and "Instant" or "Spring"].new(window.ContentTop or 120, { frequency = 7 }))
		        window.ContainerBackMotor:setGoal(Flipper[instant and "Instant" or "Spring"].new(0, { frequency = 9 }))
		    end
		    if instant then show() else
		        window.ContainerBackMotor:setGoal(Flipper.Spring.new(1, { frequency = 13 }))
		        window.ContainerPosMotor:setGoal(Flipper.Spring.new((window.ContentTop or 120) + 8, { frequency = 12 }))
		        task.delay(0.08, show)
		    end
		    return true
		end
		return Tabs
	end,
	-- Module: MainModule/Components/Textbox
	[15] = function()
		local __context, script, require = getModuleContext(15)
		-- Reconstructed module: MainModule/Components/Textbox
		-- Author: dawid | License: MIT (original Fluent header).
		local TextService, Parent_9 = game:GetService("TextService"), script.Parent.Parent
		local Flipper_6, Creator_11 = require(Parent_9.Packages.Flipper), require(Parent_9.Creator)
		local New_9 = Creator_11.New
		return function(argument_43, argument_44)
			argument_44 = argument_44 or false
			local object_18 = {}
			object_18.Input = New_9("TextBox", {
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromOffset(10, 0),
				ThemeTag = {
					TextColor3 = "Text",
					PlaceholderColor3 = "SubText",
				},
			})
			object_18.Container = New_9("Frame", {
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Position = UDim2.new(0, 6, 0, 0),
				Size = UDim2.new(1, -12, 1, 0),
			}, {
				object_18.Input,
			})
			object_18.Indicator = New_9("Frame", {
				Size = UDim2.new(1, -4, 0, 1),
				Position = UDim2.new(0, 2, 1, 0),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundTransparency = argument_44 and 0.5 or 0,
				ThemeTag = {
					BackgroundColor3 = argument_44 and "InputIndicator" or "DialogInputLine",
				},
			})
			object_18.Frame = New_9("Frame", {
				Size = UDim2.new(0, 0, 0, 30),
				BackgroundTransparency = argument_44 and 0.9 or 0,
				Parent = argument_43,
				ThemeTag = {
					BackgroundColor3 = argument_44 and "Input" or "DialogInput",
				},
			}, {
				New_9("UICorner", {
					CornerRadius = UDim.new(0, 7),
				}),
				New_9("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Transparency = argument_44 and 0.5 or 0.65,
					ThemeTag = {
						Color = argument_44 and "InElementBorder" or "DialogButtonBorder",
					},
				}),
				object_18.Indicator,
				object_18.Container,
			})
			local callback_14 = function()
				local number, X = 2, object_18.Container.AbsoluteSize.X
				if not object_18.Input:IsFocused() or object_18.Input.TextBounds.X <= X - 2 * number then
					object_18.Input.Position = UDim2.new(0, number, 0, 0)
				else
					local CursorPosition = object_18.Input.CursorPosition
					if CursorPosition ~= -1 then
						local sub = string.sub(object_18.Input.Text, 1, CursorPosition - 1)
						local X_2 = TextService:GetTextSize(
							sub,
							object_18.Input.TextSize,
							object_18.Input.Font,
							Vector2.new(math.huge, math.huge)
						).X
						local value_13 = object_18.Input.Position.X.Offset + X_2
						if value_13 < number then
							object_18.Input.Position = UDim2.fromOffset(number - X_2, 0)
						elseif value_13 > X - number - 1 then
							object_18.Input.Position = UDim2.fromOffset(X - X_2 - number - 1, 0)
						end
					end
				end
			end
			task.spawn(callback_14)
			Creator_11.AddSignal(object_18.Input:GetPropertyChangedSignal("Text"), callback_14)
			Creator_11.AddSignal(object_18.Input:GetPropertyChangedSignal("CursorPosition"), callback_14)
			Creator_11.AddSignal(object_18.Input.Focused, function()
				callback_14()
				object_18.Indicator.Size = UDim2.new(1, -2, 0, 2)
				object_18.Indicator.Position = UDim2.new(0, 1, 1, 0)
				object_18.Indicator.BackgroundTransparency = 0
				Creator_11.OverrideTag(object_18.Frame, {
					BackgroundColor3 = argument_44 and "InputFocused" or "DialogHolder",
				})
				Creator_11.OverrideTag(object_18.Indicator, {
					BackgroundColor3 = "Accent",
				})
			end)
			Creator_11.AddSignal(object_18.Input.FocusLost, function()
				callback_14()
				object_18.Indicator.Size = UDim2.new(1, -4, 0, 1)
				object_18.Indicator.Position = UDim2.new(0, 2, 1, 0)
				object_18.Indicator.BackgroundTransparency = 0.5
				Creator_11.OverrideTag(object_18.Frame, {
					BackgroundColor3 = argument_44 and "Input" or "DialogInput",
				})
				Creator_11.OverrideTag(object_18.Indicator, {
					BackgroundColor3 = argument_44 and "InputIndicator" or "DialogInputLine",
				})
			end)
			return object_18
		end
	end,
	-- Module: MainModule/Components/TitleBar
	[16] = function()
		local __context, script, require = getModuleContext(16)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local Creator = require(script.Parent.Parent.Creator)
		local Assets = require(script.Parent.Assets)
		local New = Creator.New
		return function(config)
		    local Library = require(script.Parent.Parent)
		    local bar = {}
		    bar.Frame = New("Frame", {
		        Name = "TitleBar", Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1, Parent = config.Parent,
		    })
		    bar.DragArea = New("TextButton", {
		        Name = "DragArea", Size = UDim2.new(1, -124, 1, 0), BackgroundTransparency = 1, Text = "", Parent = bar.Frame,
		    })
		    New("Frame", {
		        Size = UDim2.new(1, -32, 0, 1), Position = UDim2.new(0, 16, 1, -1),
		        BackgroundTransparency = 0.25, Parent = bar.Frame, ThemeTag = { BackgroundColor3 = "TitleBarLine" },
		    })
		    local badge = New("Frame", {
		        Name = "LogoBadge", Size = UDim2.fromOffset(38, 38), Position = UDim2.fromOffset(18, 13),
		        BackgroundTransparency = 0.86, Visible = config.Logo ~= false, Parent = bar.DragArea,
		        ThemeTag = { BackgroundColor3 = "Accent" },
		    }, { New("UICorner", { CornerRadius = UDim.new(0, 11) }) })
		    local fallback = New("TextLabel", {
		        Text = "B", TextSize = 20, Size = UDim2.fromScale(1, 1), Parent = badge,
		        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
		        ThemeTag = { TextColor3 = "Accent" },
		    })
		    local logo = New("ImageLabel", {
		        Name = "BloomLogo", Image = "", Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(2, 2),
		        ScaleType = Enum.ScaleType.Fit, Visible = false, Parent = badge,
		    })
		    local left = config.Logo == false and 20 or 68
		    bar.Title = New("TextLabel", {
		        Text = config.Title, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left,
		        TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -left - 12, 0, 22),
		        Position = UDim2.fromOffset(left, config.SubTitle == "" and 21 or 13), Parent = bar.DragArea,
		        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
		        ThemeTag = { TextColor3 = "Text" },
		    })
		    bar.SubTitle = New("TextLabel", {
		        Text = config.SubTitle, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
		        TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -left - 12, 0, 16),
		        Position = UDim2.fromOffset(left, 35), Parent = bar.DragArea,
		        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		        ThemeTag = { TextColor3 = "SubText" },
		    })
		    local alive = true
		    Creator.AddSignal(bar.Frame.Destroying, function() alive = false end)
		    if config.Logo ~= false then
		        task.spawn(function()
		            local uri = Assets.ResolveLogo(config.Logo)
		            if not alive or not uri then return end
		            logo.Image = uri
		            logo.Visible = true
		            fallback.Visible = false
		        end)
		    end
		    local function button(icon, right, callback)
		        local result = {}
		        result.Frame = New("TextButton", {
		            Text = "", Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -right, 0, 18),
		            BackgroundTransparency = 1, Parent = bar.Frame, ThemeTag = { BackgroundColor3 = "Tab" },
		        }, {
		            New("UICorner", { CornerRadius = UDim.new(0, 8) }),
		            New("ImageLabel", {
		                Name = "Icon", Image = icon, Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(7, 7),
		                ThemeTag = { ImageColor3 = "SubText" },
		            }),
		        })
		        local _, transparency = Creator.SpringMotor(1, result.Frame, "BackgroundTransparency")
		        Creator.AddSignal(result.Frame.MouseEnter, function() transparency(0.86) end)
		        Creator.AddSignal(result.Frame.MouseLeave, function() transparency(1, true) end)
		        result.Callback = callback
		        function result.SetCallback(nextCallback) result.Callback = nextCallback end
		        Creator.AddSignal(result.Frame.Activated, function() if result.Callback then result.Callback() end end)
		        return result
		    end
		    bar.MenuButton = button(Library:GetIcon("menu") or "", 0, function() config.Window:SetDrawer(not config.Window.DrawerOpen) end)
		    bar.MenuButton.Frame.Name = "OpenNavigation"
		    bar.MenuButton.Frame.Visible = false
		    bar.MinButton = button(Assets.Min, 110, function() config.Window:Minimize() end)
		    bar.MaxButton = button(Assets.Max, 76, function() config.Window.Maximize(not config.Window.Maximized) end)
		    bar.CloseButton = button(Assets.Close, 42, function()
		        config.Window:Dialog({ Title = "Close interface", Content = "Unload Bloomware UI?", Buttons = {
		            { Title = "Cancel" }, { Title = "Unload", Callback = function() Library:Destroy() end },
		        } })
		    end)
		    function bar:Layout(mobile)
		        self.MenuButton.Frame.Visible = mobile
		        self.MenuButton.Frame.Position = UDim2.fromOffset(6,10)
		        self.MenuButton.Frame.Size = UDim2.fromOffset(44,44)
		        self.MenuButton.Frame.Icon.Position = UDim2.fromOffset(14,14)
		        self.MenuButton.Frame.Icon.Size = UDim2.fromOffset(16,16)
		        self.MaxButton.Frame.Visible = not mobile
		        self.DragArea.Position = UDim2.fromOffset(mobile and 52 or 0,0)
		        self.DragArea.Size = UDim2.new(1,mobile and -152 or -124,1,0)
		        badge.Size = UDim2.fromOffset(mobile and 32 or 38,mobile and 32 or 38)
		        badge.Position = UDim2.fromOffset(mobile and 0 or 18,mobile and 16 or 13)
		        logo.Size = UDim2.fromOffset(mobile and 30 or 34,mobile and 30 or 34)
		        logo.Position = UDim2.fromOffset(mobile and 1 or 2,mobile and 1 or 2)
		        local textLeft = config.Logo == false and (mobile and 0 or 20) or (mobile and 42 or 68)
		        self.Title.Position = UDim2.fromOffset(textLeft,config.SubTitle == "" and 21 or 13)
		        self.Title.Size = UDim2.new(1,-textLeft-8,0,22)
		        self.Title.TextSize = mobile and 14 or 16
		        self.SubTitle.Position = UDim2.fromOffset(textLeft,35)
		        self.SubTitle.Size = UDim2.new(1,-textLeft-8,0,16)
		        for _,item in ipairs({{self.MinButton,mobile and 94 or 110},{self.CloseButton,mobile and 48 or 42}}) do
		            local frame=item[1].Frame
		            frame.Size = UDim2.fromOffset(mobile and 44 or 28,mobile and 44 or 28)
		            frame.Position = UDim2.new(1,-item[2],0,mobile and 10 or 18)
		            frame.Icon.Position = UDim2.fromOffset(mobile and 15 or 7,mobile and 15 or 7)
		        end
		    end
		    return bar
		end
	end,
	-- Module: MainModule/Components/Window
	[17] = function()
		local __context, script, require = getModuleContext(17)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local UserInputService=game:GetService("UserInputService")
		local Workspace=game:GetService("Workspace")
		local Creator=require(script.Parent.Parent.Creator)
		local Flipper=require(script.Parent.Parent.Packages.Flipper)
		local Acrylic=require(script.Parent.Parent.Acrylic)
		local Assets=require(script.Parent.Assets)
		local New=Creator.New
		return function(config)
		    local Library=require(script.Parent.Parent)
		    local camera=Workspace.CurrentCamera
		    local viewport=camera and camera.ViewportSize or Vector2.new(1280,720)
		    local width=math.max(560,config.Size.X.Offset+config.Size.X.Scale*viewport.X)
		    local height=math.max(380,config.Size.Y.Offset+config.Size.Y.Scale*viewport.Y)
		    local Window={Minimized=false,Maximized=false,Destroyed=false,CurrentPos=0,Mobile=false,
		        Size=UDim2.fromOffset(width,height),Position=UDim2.fromOffset(0,0),TabWidth=config.TabWidth,
		        ContentTop=120,ContentLeft=config.TabWidth+30,ToolActive=nil,DrawerOpen=false}
		    Window.AcrylicPaint=Acrylic.AcrylicPaint()
		    Window.Scale=New("UIScale",{Scale=1})
		    Window.Root=New("Frame",{Name="BloomwareWindow",BackgroundTransparency=1,Size=Window.Size,Parent=config.Parent},{Window.AcrylicPaint.Frame,Window.Scale})
		    local root=Window.Root
		    local sidebar=New("Frame",{Name="Sidebar",Position=UDim2.fromOffset(10,74),Size=UDim2.new(0,Window.TabWidth,1,-86),
		        BackgroundTransparency=0.12,Parent=root,ThemeTag={BackgroundColor3="Sidebar"}},{New("UICorner",{CornerRadius=UDim.new(0,12)})})
		    New("TextLabel",{Text="WORKSPACE",TextSize=10,FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json",Enum.FontWeight.Bold),
		        TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,-24,0,16),Position=UDim2.fromOffset(14,12),Parent=sidebar,ThemeTag={TextColor3="SubText"}})
		    Window.TabHolder=New("ScrollingFrame",{Name="Tabs",Size=UDim2.new(1,-16,1,-74),Position=UDim2.fromOffset(8,36),BackgroundTransparency=1,
		        ScrollBarThickness=2,ScrollBarImageTransparency=0.6,CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y,Parent=sidebar,
		        ThemeTag={ScrollBarImageColor3="Accent"}},{New("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})})
		    New("Frame",{Size=UDim2.new(1,-24,0,1),Position=UDim2.new(0,12,1,-31),BackgroundTransparency=0.35,Parent=sidebar,ThemeTag={BackgroundColor3="TitleBarLine"}})
		    New("TextLabel",{Text="BLOOMWARE  /  UI",TextSize=9,FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json",Enum.FontWeight.Medium),
		        Size=UDim2.new(1,-24,0,20),Position=UDim2.new(0,12,1,-26),TextXAlignment=Enum.TextXAlignment.Left,Parent=sidebar,ThemeTag={TextColor3="SubText"}})
		    Window.TabDisplay=New("TextLabel",{Name="PageTitle",Text="",TextSize=26,RichText=true,FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json",Enum.FontWeight.Bold),
		        TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Size=UDim2.new(1,-Window.TabWidth-52,0,32),
		        Position=UDim2.fromOffset(Window.TabWidth+30,78),Parent=root,ThemeTag={TextColor3="Text"}})
		    Window.ContainerHolder=New("CanvasGroup",{Name="PageContent",BackgroundTransparency=1,Size=UDim2.new(1,-Window.TabWidth-46,1,-136),
		        Position=UDim2.fromOffset(Window.TabWidth+30,120),Parent=root})
		    Window.ContainerBackMotor=Flipper.SingleMotor.new(0)
		    Window.ContainerPosMotor=Flipper.SingleMotor.new(120)
		    Window.SelectorPosMotor=Flipper.SingleMotor.new(0)
		    Window.SelectorSizeMotor=Flipper.SingleMotor.new(16)
		    Window.ContainerBackMotor:onStep(function(value)Window.ContainerHolder.GroupTransparency=value end)
		    Window.ContainerPosMotor:onStep(function(value)Window.ContainerHolder.Position=UDim2.fromOffset(Window.ContentLeft,value)end)
		    Window.TitleBar=require(script.Parent.TitleBar)({Title=config.Title,SubTitle=config.SubTitle,Logo=config.Logo,Parent=root,Window=Window})
		    if Library.UseAcrylic then Window.AcrylicPaint.AddParent(root)end
		    local scrim=New("TextButton",{Name="NavigationBackdrop",Text="",Visible=false,ZIndex=20,Size=UDim2.new(1,0,1,-64),Position=UDim2.fromOffset(0,64),
		        BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.35,Parent=root})
		    function Window:SetDrawer(open)
		        self.DrawerOpen=self.Mobile and open==true
		        sidebar.Visible=not self.Mobile or self.DrawerOpen
		        scrim.Visible=self.DrawerOpen
		        if self.DrawerOpen then Library:ClosePopups()end
		    end
		    Creator.AddSignal(scrim.Activated,function()Window:SetDrawer(false)end)

		    local function toolButton(name,icon,text)
		        local frame=New("TextButton",{Name=name,Text="",Size=UDim2.fromOffset(100,36),BackgroundTransparency=0.88,Parent=root,
		            ThemeTag={BackgroundColor3="Tab"}},{New("UICorner",{CornerRadius=UDim.new(0,9)})})
		        local image=New("ImageLabel",{Image=Library:GetIcon(icon) or "",Size=UDim2.fromOffset(16,16),Position=UDim2.new(0,10,0.5,-8),Parent=frame,ThemeTag={ImageColor3="SubText"}})
		        local label=New("TextLabel",{Text=text,TextSize=12,Size=UDim2.new(1,-36,1,0),Position=UDim2.fromOffset(32,0),TextXAlignment=Enum.TextXAlignment.Left,
		            FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json",Enum.FontWeight.Medium),Parent=frame,ThemeTag={TextColor3="SubText"}})
		        return {Frame=frame,Icon=image,Label=label}
		    end
		    Window.SearchButton=toolButton("OpenSearch","search","Search")
		    Window.ProfileButton=toolButton("OpenProfiles","folder","Profiles")
		    Window.SearchButton.Frame.Visible=config.Search
		    Window.ProfileButton.Frame.Visible=config.Profiles
		    Window.SearchPanel=config.Search and require(script.Parent.SearchPanel)(Window,Library) or nil
		    Window.ProfilePanel=config.Profiles and require(script.Parent.ProfilePanel)(Window,Library) or nil
		    local tabs=require(script.Parent.Tab):Init(Window)
		    function Window:CloseTools()
		        self.ToolActive=nil
		        if self.SearchPanel then self.SearchPanel:Close()end
		        if self.ProfilePanel then self.ProfilePanel:Close()end
		        self.ContainerHolder.Visible=true
		        local selected=tabs.Tabs[tabs.SelectedTab]
		        self.TabDisplay.Text=selected and selected.Name or ""
		    end
		    function Window:ShowSearch(query)
		        if not self.SearchPanel or Library.DialogOpen then return false end
		        self:CloseTools();self:SetDrawer(false);Library:ClosePopups()
		        self.ToolActive="Search";self.TabDisplay.Text="Search";self.ContainerHolder.Visible=false
		        self.SearchPanel:Open(query)
		        return true
		    end
		    function Window:ShowProfiles()
		        if not self.ProfilePanel or Library.DialogOpen then return false end
		        self:CloseTools();self:SetDrawer(false);Library:ClosePopups()
		        self.ToolActive="Profiles";self.TabDisplay.Text="Profiles";self.ContainerHolder.Visible=false
		        self.ProfilePanel:Open()
		        return true
		    end
		    Creator.AddSignal(Window.SearchButton.Frame.Activated,function()if Window.ToolActive=="Search"then Window:CloseTools()else Window:ShowSearch()end end)
		    Creator.AddSignal(Window.ProfileButton.Frame.Activated,function()if Window.ToolActive=="Profiles"then Window:CloseTools()else Window:ShowProfiles()end end)
		    function Window:Reveal(entry)
		        local card,tab=entry.Card,entry.Tab
		        if not card or card.Destroyed or not tab or not tabs.Tabs[tab.Index]then return false end
		        self:SelectTab(tab.Index,true)
		        task.defer(function()
		            if self.Destroyed or card.Destroyed or tabs.SelectedTab~=tab.Index then return end
		            local scroll=tab.Container
		            local scale=Creator.GetScale(scroll)
		            local position=scroll.CanvasPosition or Vector2.new(0,0)
		            local target=position.Y+(card.Frame.AbsolutePosition.Y-scroll.AbsolutePosition.Y)/scale-12
		            local maximum=math.max(0,scroll.CanvasSize.Y.Offset-scroll.AbsoluteSize.Y/scale)
		            scroll.CanvasPosition=Vector2.new(0,math.clamp(target,0,maximum))
		            card.SearchGeneration=(card.SearchGeneration or 0)+1
		            local generation=card.SearchGeneration
		            Creator.OverrideTag(card.Border,{Color="Accent"});card.Border.Transparency=0.05
		            task.delay(1.4,function()
		                if not card.Destroyed and card.SearchGeneration==generation then Creator.OverrideTag(card.Border,{Color="ElementBorder"});card.Border.Transparency=0.52 end
		            end)
		        end)
		        return true
		    end
		    function Window:AddTab(options)return tabs:New(options.Title,options.Icon,self.TabHolder)end
		    function Window:SelectTab(index,instant)return tabs:SelectTab(index,instant)end

		    local grip=New("TextButton",{Name="ResizeGrip",Text="",Size=UDim2.fromOffset(26,26),Position=UDim2.new(1,-26,1,-26),BackgroundTransparency=1,Parent=root})
		    for index=1,3 do New("Frame",{Size=UDim2.fromOffset(2,2),Position=UDim2.fromOffset(9+index*3,20-index*3),BackgroundTransparency=0.2,Parent=grip,
		        ThemeTag={BackgroundColor3="SubText"}},{New("UICorner",{CornerRadius=UDim.new(1,0)})})end
		    Window.RestoreButton=New("TextButton",{Name="BloomwareRestore",Text="B",TextSize=22,Visible=false,Size=UDim2.fromOffset(52,52),
		        Position=UDim2.fromOffset(viewport.X-68,math.max(8,viewport.Y/2-26)),ZIndex=100,Parent=config.Parent,
		        FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json",Enum.FontWeight.Bold),ThemeTag={BackgroundColor3="Sidebar",TextColor3="Accent"}},
		        {New("UICorner",{CornerRadius=UDim.new(0,16)}),New("UIStroke",{Thickness=1,Transparency=0.2,ThemeTag={Color="Accent"}})})
		    local floatingInput,floatingOrigin,floatingPosition,floatingMoved,lastFloatingDrag
		    Creator.AddSignal(Window.RestoreButton.InputBegan,function(input)
		        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
		            floatingInput,floatingOrigin,floatingPosition,floatingMoved=input,input.Position,Window.RestoreButton.Position,false
		        end
		    end,root)
		    Creator.AddSignal(Window.RestoreButton.Activated,function()
		        if not lastFloatingDrag or os.clock()-lastFloatingDrag>0.18 then Window:SetMinimized(false)end
		    end,root)
		    local function keyboardHeight()
		        if not Window.Mobile or not UserInputService.OnScreenKeyboardVisible then return 0 end
		        local size=UserInputService.OnScreenKeyboardSize
		        return size and math.clamp(size.Y,0,math.max(0,viewport.Y-180)) or 0
		    end
		    local lastMobile,desktopSize,desktopPosition=nil,Window.Size,nil
		    local cameraConnection
		    local function fit(center)
		        if Window.Destroyed then return end
		        camera=Workspace.CurrentCamera;viewport=camera and camera.ViewportSize or viewport
		        local mobile=config.MobileMode
		        if mobile==nil then mobile=viewport.X<=720 or UserInputService.TouchEnabled==true and math.min(viewport.X,viewport.Y)<600 end
		        local modeChanged=lastMobile~=mobile
		        if mobile and lastMobile==false then desktopSize,desktopPosition=Window.Size,Window.Position end
		        if not mobile and lastMobile==true then Window.Size=desktopSize;Window.Position=desktopPosition or Window.Position;Window.Maximized=false;center=true end
		        Window.Mobile=mobile;Library.Mobile=mobile
		        local scale,x,y=1,Window.Position.X.Offset,Window.Position.Y.Offset
		        if mobile then
		            Window.Maximized=false
		            Window.Size=UDim2.fromOffset(math.max(1,viewport.X-16),math.max(1,viewport.Y-keyboardHeight()-16))
		            x,y=8,8
		        else
		            if Window.Maximized then Window.Size=UDim2.fromOffset(viewport.X,viewport.Y)end
		            if not Window.Maximized and config.AutoScale then scale=math.max(0.05,math.min(1,(viewport.X-24)/Window.Size.X.Offset,(viewport.Y-24)/Window.Size.Y.Offset))end
		            if center then x,y=(viewport.X-Window.Size.X.Offset*scale)/2,(viewport.Y-Window.Size.Y.Offset*scale)/2 end
		            if Window.Maximized then x,y=0,0 else
		                x=math.clamp(x,0,math.max(0,viewport.X-Window.Size.X.Offset*scale));y=math.clamp(y,0,math.max(0,viewport.Y-Window.Size.Y.Offset*scale))
		            end
		        end
		        Window.Scale.Scale=scale;root.Size=Window.Size
		        Window.Position=UDim2.fromOffset(x,y);root.Position=Window.Position
		        Window.TabWidth=mobile and math.min(260,Window.Size.X.Offset-32) or math.clamp(config.TabWidth,128,math.min(220,Window.Size.X.Offset*0.28))
		        Window.ContentLeft=mobile and 16 or Window.TabWidth+30
		        Window.ContentTop=120
		        sidebar.Size=UDim2.new(0,Window.TabWidth,1,-86);sidebar.ZIndex=mobile and 30 or 1
		        sidebar.BackgroundTransparency=mobile and 0 or 0.12
		        if modeChanged then Window:SetDrawer(false)end
		        Window.TitleBar:Layout(mobile)
		        Window.TabDisplay.Position=UDim2.fromOffset(Window.ContentLeft,78);Window.TabDisplay.TextSize=mobile and 22 or 26
		        local toolWidth=mobile and 44 or 100
		        local toolCount=(config.Search and 1 or 0)+(config.Profiles and 1 or 0)
		        local reserved=toolCount>0 and toolCount*(toolWidth+8) or 0
		        Window.TabDisplay.Size=UDim2.new(1,-Window.ContentLeft-16-reserved,0,32)
		        local right=16
		        for _,button in ipairs({Window.ProfileButton,Window.SearchButton})do
		            if button.Frame.Visible then
		                button.Frame.Size=UDim2.fromOffset(toolWidth,mobile and 44 or 36)
		                button.Frame.Position=UDim2.new(1,-right-toolWidth,0,mobile and 72 or 76)
		                button.Label.Visible=not mobile;button.Icon.Position=UDim2.new(0,mobile and 14 or 10,0.5,-8)
		                right=right+toolWidth+8
		            end
		        end
		        for _,frame in ipairs({Window.ContainerHolder,Window.SearchPanel and Window.SearchPanel.Frame or false,Window.ProfilePanel and Window.ProfilePanel.Frame or false})do
		            if frame then frame.Position=UDim2.fromOffset(Window.ContentLeft,Window.ContentTop);frame.Size=UDim2.new(1,-Window.ContentLeft-16,1,-Window.ContentTop-16)end
		        end
		        if Window.ProfilePanel then Window.ProfilePanel:Layout(mobile)end
		        grip.Visible=not mobile and not Window.Maximized
		        local fp=Window.RestoreButton.Position
		        Window.RestoreButton.Position=UDim2.fromOffset(math.clamp(fp.X.Offset,8,math.max(8,viewport.X-60)),math.clamp(fp.Y.Offset,8,math.max(8,viewport.Y-60)))
		        if modeChanged then Library._LayoutEvent:Fire(mobile)end
		        lastMobile=mobile
		        Library:ClosePopups()
		    end
		    Window.RefreshLayout=function()fit(false)end
		    local function keepFocusVisible()
		        if not Window.Mobile then return end
		        local focused=UserInputService:GetFocusedTextBox()
		        if not focused or focused.MultiLine then return end
		        local ancestor=focused.Parent
		        while ancestor and ancestor~=root do
		            if ancestor:IsA("ScrollingFrame")then
		                local scale=Creator.GetScale(ancestor)
		                local pos=ancestor.CanvasPosition or Vector2.new(0,0)
		                local delta=focused.AbsolutePosition.Y+focused.AbsoluteSize.Y-(ancestor.AbsolutePosition.Y+ancestor.AbsoluteSize.Y-10)
		                if focused.AbsolutePosition.Y<ancestor.AbsolutePosition.Y+10 then delta=focused.AbsolutePosition.Y-ancestor.AbsolutePosition.Y-10 end
		                if delta>0 or focused.AbsolutePosition.Y<ancestor.AbsolutePosition.Y+10 then
		                    ancestor.CanvasPosition=Vector2.new(pos.X,math.clamp(pos.Y+delta/scale,0,math.max(0,ancestor.CanvasSize.Y.Offset-ancestor.AbsoluteSize.Y/scale)))
		                end
		            end
		            ancestor=ancestor.Parent
		        end
		    end
		    local function bindCamera()
		        if cameraConnection then cameraConnection:Disconnect()end
		        camera=Workspace.CurrentCamera
		        if camera then cameraConnection=Creator.AddSignal(camera:GetPropertyChangedSignal("ViewportSize"),function()fit(false)end,root)end
		        fit(false)
		    end
		    Creator.AddSignal(Workspace:GetPropertyChangedSignal("CurrentCamera"),bindCamera,root)
		    for _,property in ipairs({"OnScreenKeyboardVisible","OnScreenKeyboardSize"})do
		        Creator.AddSignal(UserInputService:GetPropertyChangedSignal(property),function()fit(false);task.defer(keepFocusVisible)end,root)
		    end
		    Creator.AddSignal(UserInputService:GetPropertyChangedSignal("TouchEnabled"),function()fit(false)end,root)
		    fit(true);bindCamera()
		    local restoredSize,restoredPosition
		    Window.Maximize=function(enabled,keepPosition)
		        if Window.Mobile then return false end
		        enabled=enabled==true;if enabled==Window.Maximized then return end
		        if enabled then restoredSize,restoredPosition=Window.Size,Window.Position;Window.Size=UDim2.fromOffset(viewport.X,viewport.Y)
		        else Window.Size=restoredSize or UDim2.fromOffset(width,height);if not keepPosition then Window.Position=restoredPosition or Window.Position end end
		        Window.Maximized=enabled;Window.TitleBar.MaxButton.Frame.Icon.Image=enabled and Assets.Restore or Assets.Max;fit(false)
		        return true
		    end
		    local dragInput,dragOrigin,dragPosition,resizeInput,resizeOrigin,resizeSize
		    Creator.AddSignal(Window.TitleBar.DragArea.InputBegan,function(input)
		        if Window.Mobile then return end
		        if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
		        if Window.Maximized then Window.Maximize(false)end
		        dragInput,dragOrigin,dragPosition=input,input.Position,Window.Position;Library:ClosePopups()
		    end,root)
		    Creator.AddSignal(grip.InputBegan,function(input)
		        if Window.Maximized or Window.Mobile then return end
		        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
		            resizeInput,resizeOrigin,resizeSize=input,input.Position,Window.Size;Library:ClosePopups()
		        end
		    end,root)
		    Creator.AddSignal(UserInputService.InputChanged,function(input)
		        local mouse=input.UserInputType==Enum.UserInputType.MouseMovement
		        if floatingInput and (mouse and floatingInput.UserInputType==Enum.UserInputType.MouseButton1 or input==floatingInput)then
		            local delta=input.Position-floatingOrigin
		            if delta.Magnitude>6 then floatingMoved=true end
		            Window.RestoreButton.Position=UDim2.fromOffset(math.clamp(floatingPosition.X.Offset+delta.X,8,math.max(8,viewport.X-60)),math.clamp(floatingPosition.Y.Offset+delta.Y,8,math.max(8,viewport.Y-60)))
		        end
		        if dragInput and not Window.Mobile and (mouse and dragInput.UserInputType==Enum.UserInputType.MouseButton1 or input==dragInput)then
		            local delta=input.Position-dragOrigin;Window.Position=UDim2.fromOffset(dragPosition.X.Offset+delta.X,dragPosition.Y.Offset+delta.Y);fit(false)
		        end
		        if resizeInput and not Window.Mobile and (mouse and resizeInput.UserInputType==Enum.UserInputType.MouseButton1 or input==resizeInput)then
		            local delta=(input.Position-resizeOrigin)/Window.Scale.Scale
		            Window.Size=UDim2.fromOffset(math.clamp(resizeSize.X.Offset+delta.X,560,2048),math.clamp(resizeSize.Y.Offset+delta.Y,380,2048));fit(false)
		        end
		    end,root)
		    local controlPending,controlUsed
		    Creator.AddSignal(UserInputService.InputEnded,function(input)
		        if controlPending and input.KeyCode.Name==controlPending then
		            if not controlUsed and not UserInputService:GetFocusedTextBox() then Window:Minimize() end
		            controlPending,controlUsed=nil,false
		        end
		        if input==dragInput or input.UserInputType==Enum.UserInputType.MouseButton1 then dragInput=nil end
		        if input==resizeInput or input.UserInputType==Enum.UserInputType.MouseButton1 then resizeInput=nil end
		        if input==floatingInput or input.UserInputType==Enum.UserInputType.MouseButton1 then
		            if floatingInput and floatingMoved then lastFloatingDrag=os.clock()end
		            floatingInput=nil
		        end
		    end,root)
		    Creator.AddSignal(Window.TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"),function()
		        Window.TabHolder.CanvasSize=UDim2.fromOffset(0,Window.TabHolder.UIListLayout.AbsoluteContentSize.Y/Creator.GetScale(Window.TabHolder))
		    end,root)
		    Creator.AddSignal(UserInputService.InputBegan,function(input)
		        if controlPending and input.KeyCode.Name~=controlPending then controlUsed=true end
		        if input.KeyCode==Enum.KeyCode.Escape then
		            if Window.ToolActive then Window:CloseTools()elseif Window.DrawerOpen then Window:SetDrawer(false)end
		            return
		        end
		        local ctrl=UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
		        if ctrl and input.KeyCode==Enum.KeyCode.K and not Window.Minimized then Window:ShowSearch();return end
		        if UserInputService:GetFocusedTextBox()then return end
		        local keybind=Library.MinimizeKeybind
		        local expected=type(keybind)=="table"and keybind.Type=="Keybind"and keybind.Value or Library.MinimizeKey.Name
		        if input.KeyCode.Name==expected then
		            if input.KeyCode==Enum.KeyCode.LeftControl or input.KeyCode==Enum.KeyCode.RightControl then controlPending,controlUsed=expected,false
		            elseif not ctrl then Window:Minimize()end
		        end
		    end,root)
		    function Window:SetMinimized(minimized)
		        self.Minimized=minimized==true;self:SetDrawer(false);self:CloseTools();Library:ClosePopups()
		        root.Visible=not self.Minimized;self.RestoreButton.Visible=self.Minimized
		        if Library.UseAcrylic then self.AcrylicPaint.SetVisibility(not self.Minimized)end
		    end
		    function Window:Minimize()self:SetMinimized(not self.Minimized)end
		    local dialogs=require(script.Parent.Dialog):Init(Window)
		    function Window:Dialog(options)
		        if Library.DialogOpen then return nil end
		        Library:ClosePopups();self:SetDrawer(false)
		        local dialog=dialogs:Create();dialog.Title.Text=options.Title or "Dialog"
		        local available=math.max(200,math.min(520,Window.Size.X.Offset-32))
		        local content=New("TextLabel",{Text=options.Content or "",TextSize=14,TextWrapped=true,
		            FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json"),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
		            AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,-40,0,0),Position=UDim2.fromOffset(20,60),Parent=dialog.Root,ThemeTag={TextColor3="Text"}})
		        dialog.Root.Size=UDim2.fromOffset(available,190)
		        Creator.AddSignal(content:GetPropertyChangedSignal("AbsoluteSize"),function()
		            dialog.Root.Size=UDim2.fromOffset(available,math.max(190,content.AbsoluteSize.Y/Window.Scale.Scale+150))
		        end,dialog.Root)
		        for _,button in ipairs(options.Buttons or{})do dialog:Button(button.Title,button.Callback)end
		        dialog:Open();return dialog
		    end
		    function Window:Destroy()
		        if self.Destroyed then return end
		        self:CloseTools();self.Destroyed=true;Library:ClosePopups();tabs.Generation=tabs.Generation+1
		        Library.Search.Changed=nil;Library.Profiles.Changed=nil
		        for _,motor in ipairs({self.ContainerBackMotor,self.ContainerPosMotor,self.SelectorPosMotor,self.SelectorSizeMotor})do motor:destroy()end
		        if self.AcrylicPaint.Model then self.AcrylicPaint.Model:Destroy()end
		        if cameraConnection then cameraConnection:Disconnect()end
		        self.RestoreButton:Destroy();root:Destroy()
		    end
		    return Window
		end
	end,
	-- Module: MainModule/Creator
	[18] = function()
		local __context, script, require = getModuleContext(18)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local Themes = require(script.Parent.Themes)
		local Flipper = require(script.Parent.Packages.Flipper)
		local Creator = {
		    Registry = {}, Signals = {}, TransparencyMotors = {},
		    DefaultProperties = {
		        ScreenGui = { ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling },
		        Frame = { BorderSizePixel = 0 },
		        ScrollingFrame = { BorderSizePixel = 0 },
		        TextLabel = { BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", TextSize = 14 },
		        TextButton = { BorderSizePixel = 0, AutoButtonColor = false, Text = "", TextSize = 14 },
		        TextBox = { BorderSizePixel = 0, ClearTextOnFocus = false, Text = "", TextSize = 14 },
		        ImageLabel = { BackgroundTransparency = 1, BorderSizePixel = 0 },
		        ImageButton = { BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false },
		        CanvasGroup = { BorderSizePixel = 0 },
		    },
		}

		function Creator.AddSignal(signal, callback, owner)
		    local connection = signal:Connect(callback)
		    table.insert(Creator.Signals, connection)
		    if owner then
		        local destroyConnection
		        destroyConnection = owner.Destroying:Connect(function()
		            connection:Disconnect()
		            local index = table.find(Creator.Signals, connection)
		            if index then table.remove(Creator.Signals, index) end
		            local destroyIndex = table.find(Creator.Signals, destroyConnection)
		            if destroyIndex then table.remove(Creator.Signals, destroyIndex) end
		            destroyConnection:Disconnect()
		        end)
		        table.insert(Creator.Signals, destroyConnection)
		    end
		    return connection
		end

		function Creator.Disconnect()
		    for _, connection in ipairs(Creator.Signals) do connection:Disconnect() end
		    table.clear(Creator.Signals)
		    for motor in pairs(Creator.TransparencyMotors) do motor:destroy() end
		    table.clear(Creator.TransparencyMotors)
		    table.clear(Creator.Registry)
		end

		function Creator.GetThemeProperty(key)
		    local theme = Themes[require(script.Parent).Theme] or Themes.Dark
		    local value = theme[key]
		    if value ~= nil then return value end
		    if key == "Sidebar" then return theme.DialogHolder or theme.AcrylicMain end
		    return Themes.Dark[key]
		end

		local function applyTheme(object, tags)
		    for property, tag in pairs(tags) do
		        local value = Creator.GetThemeProperty(tag)
		        if value ~= nil then object[property] = value end
		    end
		end

		function Creator.UpdateTheme()
		    for object, entry in pairs(Creator.Registry) do applyTheme(object, entry.Properties) end
		    for motor in pairs(Creator.TransparencyMotors) do
		        motor:setGoal(Flipper.Instant.new(Creator.GetThemeProperty("ElementTransparency")))
		    end
		end

		function Creator.AddThemeObject(object, tags)
		    if not Creator.Registry[object] then
		        object.Destroying:Connect(function() Creator.Registry[object] = nil end)
		    end
		    Creator.Registry[object] = { Object = object, Properties = tags }
		    applyTheme(object, tags)
		    return object
		end

		function Creator.OverrideTag(object, tags)
		    if Creator.Registry[object] then
		        Creator.Registry[object].Properties = tags
		        applyTheme(object, tags)
		    else
		        Creator.AddThemeObject(object, tags)
		    end
		end

		function Creator.New(className, properties, children)
		    local object = Instance.new(className)
		    for key, value in pairs(Creator.DefaultProperties[className] or {}) do object[key] = value end
		    for key, value in pairs(properties or {}) do
		        if key ~= "ThemeTag" then object[key] = value end
		    end
		    for _, child in ipairs(children or {}) do child.Parent = object end
		    if properties and properties.ThemeTag then Creator.AddThemeObject(object, properties.ThemeTag) end
		    return object
		end

		function Creator.GetScale(object)
		    local current, factor = object, 1
		    while current do
		        local scale = current:FindFirstChildOfClass("UIScale")
		        if scale then factor = factor * math.max(scale.Scale, 0.01) end
		        if current:IsA("ScreenGui") then break end
		        current = current.Parent
		    end
		    return factor
		end

		function Creator.SpringMotor(value, object, property, ignoreDialog, themed)
		    local motor = Flipper.SingleMotor.new(value)
		    motor:onStep(function(nextValue) object[property] = nextValue end)
		    if themed then Creator.TransparencyMotors[motor] = true end
		    object.Destroying:Connect(function()
		        motor:destroy()
		        Creator.TransparencyMotors[motor] = nil
		    end)
		    return motor, function(goal, force)
		        if not ignoreDialog and not force and property == "BackgroundTransparency" and require(script.Parent).DialogOpen then return end
		        motor:setGoal(Flipper.Spring.new(goal, { frequency = 8 }))
		    end
		end

		return Creator
	end,
	-- Module: MainModule/Elements
	[19] = function()
		local __context, script, require = getModuleContext(19)
		-- Reconstructed module: MainModule/Elements
		-- Author: dawid | License: MIT (original Fluent header).
		local object_24 = {}
		for key_17, item_17 in next, script:GetChildren() do
			table.insert(object_24, require(item_17))
		end
		return object_24
	end,
	-- Module: MainModule/Elements/Button
	[20] = function()
		local __context, script, require = getModuleContext(20)
		-- Reconstructed module: MainModule/Elements/Button
		-- Author: dawid | License: MIT (original Fluent header).
		local Parent_16 = script.Parent.Parent
		local Creator_14 = require(Parent_16.Creator)
		local New_12, Components_3, object_25 = Creator_14.New, Parent_16.Components, {}
		object_25.__index = object_25
		object_25.__type = "Button"
		function object_25.New(self_39, argument_84)
			assert(argument_84.Title, "Button - Missing Title")
			argument_84.Callback = argument_84.Callback or function() end
			local value_28 =
				require(Components_3.Element)(argument_84.Title, argument_84.Description, self_39.Container, true)
			local ImageLabel = New_12("ImageLabel", {
				Image = "rbxassetid://10709791437",
				Size = UDim2.fromOffset(16, 16),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				BackgroundTransparency = 1,
				Parent = value_28.Frame,
				ThemeTag = {
					ImageColor3 = "Text",
				},
			})
			value_28:SetControl(ImageLabel, { Width = 18, Height = 18, StackWidth = 220 })
			Creator_14.AddSignal(value_28.Frame.Activated, function()
				self_39.Library:SafeCallback(argument_84.Callback)
			end)
			return value_28
		end
		return object_25
	end,
	-- Module: MainModule/Elements/Colorpicker
	[21] = function()
		local __context, script, require = getModuleContext(21)
		-- Reconstructed module: MainModule/Elements/Colorpicker
		-- Author: dawid | License: MIT (original Fluent header).
		local UserInputService_4 = game:GetService("UserInputService")
		local Parent_17 = script.Parent.Parent
		local Creator_15 = require(Parent_17.Creator)
		local New_13, Components_4, object_26 = Creator_15.New, Parent_17.Components, {}
		object_26.__index = object_26
		object_26.__type = "Colorpicker"
		function object_26.New(self_40, argument_85, argument_86)
			local Library = self_40.Library
			assert(argument_86.Title, "Colorpicker - Missing Title")
			assert(argument_86.Default, "AddColorPicker: Missing default value.")
			local config_3 = {
				Value = argument_86.Default,
				Transparency = argument_86.Transparency or 0,
				Type = "Colorpicker",
				Title = type(argument_86.Title) == "string" and argument_86.Title or "Colorpicker",
				Callback = argument_86.Callback or function(argument_87) end,
			}
			function config_3.SetHSVFromRGB(self_41, argument_88)
				local toHSV, result_7, extraResult = Color3.toHSV(argument_88)
				config_3.Hue = toHSV
				config_3.Sat = result_7
				config_3.Vib = extraResult
			end
			config_3:SetHSVFromRGB(config_3.Value)
			local value_29 =
				require(Components_4.Element)(argument_86.Title, argument_86.Description, self_40.Container, true)
			config_3._Element = value_29
			config_3.SetTitle = value_29.SetTitle
			config_3.SetDesc = value_29.SetDesc
			local Frame_5 = New_13("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = config_3.Value,
				Parent = value_29.Frame,
			}, {
				New_13("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}),
			})
			local ImageLabel_7, callback_29 =
				New_13("ImageLabel", {
					Size = UDim2.fromOffset(26, 26),
					Position = UDim2.new(1, -10, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					Parent = value_29.Frame,
					Image = "http://www.roblox.com/asset/?id=14204231522",
					ImageTransparency = 0.45,
					ScaleType = Enum.ScaleType.Tile,
					TileSize = UDim2.fromOffset(40, 40),
				}, {
					New_13("UICorner", {
						CornerRadius = UDim.new(0, 4),
					}),
					Frame_5,
				}), function()
					if Library.DialogOpen then return end
					Library:ClosePopups()
					local create_2 = require(Components_4.Dialog):Create()
					create_2.Title.Text = config_3.Title
					create_2.Root.Size = UDim2.fromOffset(430, 330)
					local Hue, Sat, Vib, Transparency, callback_18, callback_19 = config_3.Hue, config_3.Sat, config_3.Vib, config_3.Transparency, function()
						local value_30 = require(Components_4.Textbox)()
						value_30.Frame.Parent = create_2.Root
						value_30.Frame.Size = UDim2.new(0, 90, 0, 32)
						return value_30
					end, function(argument_89, argument_90)
						return New_13("TextLabel", {
							FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
							Text = argument_89,
							TextColor3 = Color3.fromRGB(240, 240, 240),
							TextSize = 13,
							TextXAlignment = Enum.TextXAlignment.Left,
							Size = UDim2.new(1, 0, 0, 32),
							Position = argument_90,
							BackgroundTransparency = 1,
							Parent = create_2.Root,
							ThemeTag = {
								TextColor3 = "Text",
							},
						})
					end
					local callback_20, ImageLabel_2 = function()
						local fromHSV = Color3.fromHSV(Hue, Sat, Vib)
						return {
							R = math.floor(fromHSV.r * 255),
							G = math.floor(fromHSV.g * 255),
							B = math.floor(fromHSV.b * 255),
						}
					end, New_13("ImageLabel", {
						Size = UDim2.new(0, 18, 0, 18),
						ScaleType = Enum.ScaleType.Fit,
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Image = "http://www.roblox.com/asset/?id=4805639000",
					})
					local ImageLabel_3, Frame_6 = New_13("ImageLabel", {
						Size = UDim2.fromOffset(180, 160),
						Position = UDim2.fromOffset(20, 55),
						Image = "rbxassetid://4155801252",
						BackgroundColor3 = config_3.Value,
						BackgroundTransparency = 0,
						Parent = create_2.Root,
					}, {
						New_13("UICorner", {
							CornerRadius = UDim.new(0, 4),
						}),
						ImageLabel_2,
					}), New_13("Frame", {
						BackgroundColor3 = config_3.Value,
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = config_3.Transparency,
					}, {
						New_13("UICorner", {
							CornerRadius = UDim.new(0, 4),
						}),
					})
					local ImageLabel_4, Frame_7 = New_13("ImageLabel", {
						Image = "http://www.roblox.com/asset/?id=14204231522",
						ImageTransparency = 0.45,
						ScaleType = Enum.ScaleType.Tile,
						TileSize = UDim2.fromOffset(40, 40),
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(112, 220),
						Size = UDim2.fromOffset(88, 24),
						Parent = create_2.Root,
					}, {
						New_13("UICorner", {
							CornerRadius = UDim.new(0, 4),
						}),
						New_13("UIStroke", {
							Thickness = 2,
							Transparency = 0.75,
						}),
						Frame_6,
					}), New_13("Frame", {
						BackgroundColor3 = config_3.Value,
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 0,
					}, {
						New_13("UICorner", {
							CornerRadius = UDim.new(0, 4),
						}),
					})
					local ImageLabel_5, object_27 = New_13("ImageLabel", {
						Image = "http://www.roblox.com/asset/?id=14204231522",
						ImageTransparency = 0.45,
						ScaleType = Enum.ScaleType.Tile,
						TileSize = UDim2.fromOffset(40, 40),
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(20, 220),
						Size = UDim2.fromOffset(88, 24),
						Parent = create_2.Root,
					}, {
						New_13("UICorner", {
							CornerRadius = UDim.new(0, 4),
						}),
						New_13("UIStroke", {
							Thickness = 2,
							Transparency = 0.75,
						}),
						Frame_7,
					}), {}
					for index_2 = 0, 1, 0.1 do
						table.insert(object_27, ColorSequenceKeypoint.new(index_2, Color3.fromHSV(index_2, 1, 1)))
					end
					local UIGradient, Frame_8 = New_13("UIGradient", {
						Color = ColorSequence.new(object_27),
						Rotation = 90,
					}), New_13("Frame", {
						Size = UDim2.new(1, 0, 1, -10),
						Position = UDim2.fromOffset(0, 5),
						BackgroundTransparency = 1,
					})
					local ImageLabel_6, Frame_9, callback_21 = New_13("ImageLabel", {
						Size = UDim2.fromOffset(14, 14),
						Image = "http://www.roblox.com/asset/?id=12266946128",
						Parent = Frame_8,
						ThemeTag = {
							ImageColor3 = "DialogInput",
						},
					}), New_13("Frame", {
						Size = UDim2.fromOffset(12, 190),
						Position = UDim2.fromOffset(210, 55),
						Parent = create_2.Root,
					}, {
						New_13("UICorner", {
							CornerRadius = UDim.new(1, 0),
						}),
						UIGradient,
						Frame_8,
					}), callback_18()
					callback_21.Frame.Position = UDim2.fromOffset(argument_86.Transparency and 260 or 240, 55)
					callback_19("Hex", UDim2.fromOffset(argument_86.Transparency and 360 or 340, 55))
					local callback_22 = callback_18()
					callback_22.Frame.Position = UDim2.fromOffset(argument_86.Transparency and 260 or 240, 95)
					callback_19("Red", UDim2.fromOffset(argument_86.Transparency and 360 or 340, 95))
					local callback_23 = callback_18()
					callback_23.Frame.Position = UDim2.fromOffset(argument_86.Transparency and 260 or 240, 135)
					callback_19("Green", UDim2.fromOffset(argument_86.Transparency and 360 or 340, 135))
					local callback_24 = callback_18()
					callback_24.Frame.Position = UDim2.fromOffset(argument_86.Transparency and 260 or 240, 175)
					callback_19("Blue", UDim2.fromOffset(argument_86.Transparency and 360 or 340, 175))
					local value_31
					if argument_86.Transparency then
						value_31 = callback_18()
						value_31.Frame.Position = UDim2.fromOffset(260, 215)
						callback_19("Alpha", UDim2.fromOffset(360, 215))
					end
					local value_32, value_33, value_34
					if argument_86.Transparency then
						local Frame_10 = New_13("Frame", {
							Size = UDim2.new(1, 0, 1, -10),
							Position = UDim2.fromOffset(0, 5),
							BackgroundTransparency = 1,
						})
						value_33 = New_13("ImageLabel", {
							Size = UDim2.fromOffset(14, 14),
							Image = "http://www.roblox.com/asset/?id=12266946128",
							Parent = Frame_10,
							ThemeTag = {
								ImageColor3 = "DialogInput",
							},
						})
						value_34 = New_13("Frame", {
							Size = UDim2.fromScale(1, 1),
						}, {
							New_13("UIGradient", {
								Transparency = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 0),
									NumberSequenceKeypoint.new(1, 1),
								}),
								Rotation = 270,
							}),
							New_13("UICorner", {
								CornerRadius = UDim.new(1, 0),
							}),
						})
						value_32 = New_13("Frame", {
							Size = UDim2.fromOffset(12, 190),
							Position = UDim2.fromOffset(230, 55),
							Parent = create_2.Root,
							BackgroundTransparency = 1,
						}, {
							New_13("UICorner", {
								CornerRadius = UDim.new(1, 0),
							}),
							New_13("ImageLabel", {
								Image = "http://www.roblox.com/asset/?id=14204231522",
								ImageTransparency = 0.45,
								ScaleType = Enum.ScaleType.Tile,
								TileSize = UDim2.fromOffset(40, 40),
								BackgroundTransparency = 1,
								Size = UDim2.fromScale(1, 1),
								Parent = create_2.Root,
							}, {
								New_13("UICorner", {
									CornerRadius = UDim.new(1, 0),
								}),
							}),
							value_34,
							Frame_10,
						})
					end
					local callback_25 = function()
						ImageLabel_3.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
						ImageLabel_6.Position = UDim2.new(0, -1, Hue, -6)
						ImageLabel_2.Position = UDim2.new(Sat, 0, 1 - Vib, 0)
						Frame_7.BackgroundColor3 = Color3.fromHSV(Hue, Sat, Vib)
						callback_21.Input.Text = "#" .. Color3.fromHSV(Hue, Sat, Vib):ToHex()
						callback_22.Input.Text = callback_20().R
						callback_23.Input.Text = callback_20().G
						callback_24.Input.Text = callback_20().B
						if argument_86.Transparency then
							value_34.BackgroundColor3 = Color3.fromHSV(Hue, Sat, Vib)
							Frame_7.BackgroundTransparency = Transparency
							value_33.Position = UDim2.new(0, -1, 1 - Transparency, -6)
							value_31.Input.Text = require(Parent_17):Round((1 - Transparency) * 100, 0) .. "%"
						end
					end
					Creator_15.AddSignal(callback_21.Input.FocusLost, function(argument_91)
						if argument_91 then
							local success_2, result_8 = pcall(Color3.fromHex, callback_21.Input.Text)
							if success_2 and typeof(result_8) == "Color3" then
								Hue, Sat, Vib = Color3.toHSV(result_8)
							end
						end
						callback_25()
					end)
					Creator_15.AddSignal(callback_22.Input.FocusLost, function(argument_92)
						if argument_92 then
							local callback_26 = callback_20()
							local success_3, result_9 = pcall(Color3.fromRGB, callback_22.Input.Text, callback_26.G, callback_26.B)
							if success_3 and typeof(result_9) == "Color3" then
								if tonumber(callback_22.Input.Text) <= 255 then
									Hue, Sat, Vib = Color3.toHSV(result_9)
								end
							end
						end
						callback_25()
					end)
					Creator_15.AddSignal(callback_23.Input.FocusLost, function(argument_93)
						if argument_93 then
							local callback_27 = callback_20()
							local success_4, result_10 = pcall(Color3.fromRGB, callback_27.R, callback_23.Input.Text, callback_27.B)
							if success_4 and typeof(result_10) == "Color3" then
								if tonumber(callback_23.Input.Text) <= 255 then
									Hue, Sat, Vib = Color3.toHSV(result_10)
								end
							end
						end
						callback_25()
					end)
					Creator_15.AddSignal(callback_24.Input.FocusLost, function(argument_94)
						if argument_94 then
							local callback_28 = callback_20()
							local success_5, result_11 = pcall(Color3.fromRGB, callback_28.R, callback_28.G, callback_24.Input.Text)
							if success_5 and typeof(result_11) == "Color3" then
								if tonumber(callback_24.Input.Text) <= 255 then
									Hue, Sat, Vib = Color3.toHSV(result_11)
								end
							end
						end
						callback_25()
					end)
					if argument_86.Transparency then
						Creator_15.AddSignal(value_31.Input.FocusLost, function(argument_95)
							if argument_95 then
								pcall(function()
									local number_4 = tonumber(value_31.Input.Text)
									if number_4 >= 0 and number_4 <= 100 then
										Transparency = 1 - number_4 * 0.01
									end
								end)
							end
							callback_25()
						end)
					end
		            local dragKind, dragInput
		            local function applyPointer(input)
		                if dragKind == "sv" then
		                    local p, size = ImageLabel_3.AbsolutePosition, ImageLabel_3.AbsoluteSize
		                    if size.X > 0 and size.Y > 0 then
		                        Sat = math.clamp((input.Position.X - p.X) / size.X, 0, 1)
		                        Vib = 1 - math.clamp((input.Position.Y - p.Y) / size.Y, 0, 1)
		                    end
		                elseif dragKind == "hue" then
		                    local p, size = Frame_9.AbsolutePosition, Frame_9.AbsoluteSize
		                    if size.Y > 0 then Hue = math.clamp((input.Position.Y - p.Y) / size.Y, 0, 1) end
		                elseif dragKind == "alpha" then
		                    local p, size = value_32.AbsolutePosition, value_32.AbsoluteSize
		                    if size.Y > 0 then Transparency = 1 - math.clamp((input.Position.Y - p.Y) / size.Y, 0, 1) end
		                end
		                callback_25()
		            end
		            local function bindDrag(target, kind)
		                Creator_15.AddSignal(target.InputBegan, function(input)
		                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		                        dragKind, dragInput = kind, input
		                        applyPointer(input)
		                    end
		                end, create_2.Root)
		            end
		            bindDrag(ImageLabel_3, "sv")
		            bindDrag(Frame_9, "hue")
		            if argument_86.Transparency then bindDrag(value_32, "alpha") end
		            Creator_15.AddSignal(UserInputService_4.InputChanged, function(input)
		                if dragInput and (input == dragInput or dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then applyPointer(input) end
		            end, create_2.Root)
		            Creator_15.AddSignal(UserInputService_4.InputEnded, function(input)
		                if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then dragInput, dragKind = nil, nil end
		            end, create_2.Root)
					callback_25()
					create_2:Button("Done", function()
						config_3:SetValue({
							Hue,
							Sat,
							Vib,
						}, Transparency)
					end)
					create_2:Button("Cancel")
					create_2:Open()
				end
			function config_3.Display(self_42)
				config_3.Value = Color3.fromHSV(config_3.Hue, config_3.Sat, config_3.Vib)
				Frame_5.BackgroundColor3 = config_3.Value
				Frame_5.BackgroundTransparency = config_3.Transparency
				Library:SafeCallback(config_3.Callback, config_3.Value)
				Library:SafeCallback(config_3.Changed, config_3.Value)
			end
			function config_3.SetValue(self_43, value_39, argument_99)
				local fromHSV_2 = Color3.fromHSV(value_39[1], value_39[2], value_39[3])
				config_3.Transparency = argument_99 or 0
				config_3:SetHSVFromRGB(fromHSV_2)
				config_3:Display()
			end
			function config_3.SetValueRGB(self_44, argument_100, argument_101)
				config_3.Transparency = argument_101 or 0
				config_3:SetHSVFromRGB(argument_100)
				config_3:Display()
			end
			function config_3.OnChanged(self_45, callback_30)
				config_3.Changed = callback_30
				callback_30(config_3.Value)
			end
			function config_3.Destroy(self_46)
				value_29:Destroy()
				Library.Options[argument_85] = nil
			end
			Creator_15.AddSignal(value_29.Frame.Activated, function()
				callback_29()
			end)
			value_29:SetControl(Frame_5.Parent, { Width = 44, Height = 28, StackWidth = 260 })
			config_3:Display()
			Library.Options[argument_85] = config_3
			return config_3
		end
		return object_26
	end,
	-- Module: MainModule/Elements/Dropdown
	[22] = function()
		local __context, script, require = getModuleContext(22)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local UserInputService = game:GetService("UserInputService")
		local Workspace = game:GetService("Workspace")
		local Creator = require(script.Parent.Parent.Creator)
		local New = Creator.New
		local Dropdown = { __type = "Dropdown" }
		function Dropdown:New(id, config)
		    assert(config.Title, "Dropdown - Missing Title")
		    local Library = self.Library
		    local scrollFrame = self.ScrollFrame
		    local card = require(script.Parent.Parent.Components.Element)(config.Title, config.Description, self.Container, false)
		    local option = {
		        Values = config.Values or {}, Value = config.Multi and {} or nil, Multi = config.Multi == true,
		        Buttons = {}, Opened = false, Type = "Dropdown", Callback = config.Callback or function() end,
		    }
		    option.SetTitle, option.SetDesc = card.SetTitle, card.SetDesc
		    option._Element = card
		    local button = New("TextButton", {
		        Text = "", BackgroundTransparency = 0.12,
		        ThemeTag = { BackgroundColor3 = "DropdownFrame" },
		    }, {
		        New("UICorner", { CornerRadius = UDim.new(0, 7) }),
		        New("UIStroke", { Transparency = 0.55, ThemeTag = { Color = "InElementBorder" } }),
		    })
		    card:SetControl(button, { Width = 176, Height = 32 })
		    local label = New("TextLabel", {
		        Text = "Select...", TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
		        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		        TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -36, 1, 0), Position = UDim2.fromOffset(10, 0),
		        Parent = button, ThemeTag = { TextColor3 = "Text" },
		    })
		    New("ImageLabel", {
		        Image = "rbxassetid://10709790948", Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -24, 0.5, -7),
		        Parent = button, ThemeTag = { ImageColor3 = "SubText" },
		    })
		    local popupScale = New("UIScale", { Scale = 1 })
		    local popup = New("Frame", {
		        Name = "DropdownPopup", Visible = false, Size = UDim2.fromOffset(200, 200), ZIndex = 50,
		        Parent = Library.GUI, ThemeTag = { BackgroundColor3 = "DropdownHolder" },
		    }, {
		        popupScale, New("UICorner", { CornerRadius = UDim.new(0, 10) }),
		        New("UIStroke", { Transparency = 0.12, ThemeTag = { Color = "DropdownBorder" } }),
		    })
		    local list = New("ScrollingFrame", {
		        Size = UDim2.new(1, -12, 1, -12), Position = UDim2.fromOffset(6, 6),
		        BackgroundTransparency = 1, ScrollBarThickness = 3, ScrollBarImageTransparency = 0.55,
		        ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.fromOffset(0, 0),
		        ZIndex = 51, Parent = popup, ThemeTag = { ScrollBarImageColor3 = "SubText" },
		    }, { New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }) })
		    table.insert(Library.OpenFrames, popup)
		    local destroyed, previousScroll = false, true
		    local function normalize(value)
		        if not option.Multi then
		            if type(value) == "number" and not table.find(option.Values,value) then value = option.Values[value] end
		            return table.find(option.Values, value) and value or nil
		        end
		        local result = {}
		        if type(value) == "table" then
		            for key, item in pairs(value) do
		                local selected = type(key) == "number" and type(item) ~= "boolean" and item or (item and key or nil)
		                if selected and table.find(option.Values, selected) then result[selected] = true end
		            end
		        elseif value ~= nil then
		            local selected = type(value) == "number" and option.Values[value] or value
		            if table.find(option.Values, selected) then result[selected] = true end
		        end
		        return result
		    end
		    option.Value = normalize(config.Default)
		    function option:Display()
		        if self.Multi then
		            local selected = {}
		            for _, value in ipairs(self.Values) do if self.Value[value] then table.insert(selected, tostring(value)) end end
		            label.Text = #selected > 0 and table.concat(selected, ", ") or "Select..."
		        else label.Text = self.Value ~= nil and tostring(self.Value) or "Select..." end
		    end
		    function option:GetActiveValues()
		        if not self.Multi then return self.Value ~= nil and 1 or 0 end
		        local result = {}
		        for _, value in ipairs(self.Values) do if self.Value[value] then table.insert(result, value) end end
		        return result
		    end
		    local function place()
		        if destroyed or not option.Opened then return end
		        local camera = Workspace.CurrentCamera
		        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
		        local scale = Creator.GetScale(card.Frame)
		        popupScale.Scale = scale
		        local popupWidth = math.min(260, math.max(176, button.AbsoluteSize.X / scale))
		        popupWidth = math.min(popupWidth, math.max(40, (viewport.X - 16) / scale))
		        local desiredHeight = math.min(312, math.max(46, #option.Values * 37 + 9))
		        local position, size = button.AbsolutePosition, button.AbsoluteSize
		        local below, above = viewport.Y - position.Y - size.Y - 14, position.Y - 14
		        local openBelow = below >= desiredHeight * scale or below >= above
		        local available = math.max(28, openBelow and below or above)
		        local height = math.min(desiredHeight, available / scale)
		        popup.Size = UDim2.fromOffset(popupWidth, height)
		        popup.Position = UDim2.fromOffset(
		            math.clamp(position.X + size.X - popupWidth * scale, 8, math.max(8, viewport.X - popupWidth * scale - 8)),
		            openBelow and (position.Y + size.Y + 6) or math.max(8, position.Y - height * scale - 6)
		        )
		    end
		    function option:Close()
		        if not self.Opened then return end
		        self.Opened = false
		        popup.Visible = false
		        if scrollFrame and scrollFrame.Parent then scrollFrame.ScrollingEnabled = previousScroll end
		    end
		    function option:Open()
		        if destroyed or Library.DialogOpen then return end
		        Library:ClosePopups()
		        if scrollFrame then previousScroll = scrollFrame.ScrollingEnabled; scrollFrame.ScrollingEnabled = false end
		        self.Opened = true
		        place()
		        popup.Visible = true
		    end
		    function option:BuildDropdownList()
		        for _, child in ipairs(list:GetChildren()) do if not child:IsA("UIListLayout") then child:Destroy() end end
		        table.clear(self.Buttons)
		        for index, value in ipairs(self.Values) do
		            local selected = self.Multi and self.Value[value] == true or not self.Multi and self.Value == value
		            local row = New("TextButton", {
		                Text = "", Size = UDim2.new(1, -4, 0, 34), LayoutOrder = index, ZIndex = 52,
		                BackgroundTransparency = selected and 0.87 or 1, Parent = list,
		                ThemeTag = { BackgroundColor3 = "DropdownOption" },
		            }, { New("UICorner", { CornerRadius = UDim.new(0, 6) }) })
		            New("TextLabel", {
		                Text = tostring(value), TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
		                TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(10, 0),
		                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), ZIndex = 53, Parent = row,
		                ThemeTag = { TextColor3 = selected and "Accent" or "Text" },
		            })
		            if selected then New("TextLabel", {
		                Text = "✓", TextSize = 14, Size = UDim2.fromOffset(24, 34), Position = UDim2.new(1, -28, 0, 0),
		                ZIndex = 53, Parent = row, ThemeTag = { TextColor3 = "Accent" },
		            }) end
		            Creator.AddSignal(row.MouseEnter, function() row.BackgroundTransparency = selected and 0.82 or 0.94 end, row)
		            Creator.AddSignal(row.MouseLeave, function() row.BackgroundTransparency = selected and 0.87 or 1 end, row)
		            Creator.AddSignal(row.Activated, function()
		                if self.Multi then
		                    local active = self:GetActiveValues()
		                    if self.Value[value] and #active == 1 and not config.AllowNull then return end
		                    self.Value[value] = not self.Value[value] and true or nil
		                else
		                    if self.Value == value then
		                        if config.AllowNull then self.Value = nil end
		                    else self.Value = value end
		                    self:Close()
		                end
		                self:Display()
		                self:BuildDropdownList()
		                Library:SafeCallback(self.Callback, self.Value)
		                Library:SafeCallback(self.Changed, self.Value)
		            end, row)
		            self.Buttons[index] = row
		        end
		        if #self.Values == 0 then New("TextLabel", {
		            Text = "No options", TextSize = 12, Size = UDim2.new(1, 0, 0, 34), Parent = list,
		            ZIndex = 52, ThemeTag = { TextColor3 = "SubText" },
		        }) end
		        list.CanvasSize = UDim2.fromOffset(0, #self.Values * 37)
		        place()
		    end
		    function option:SetValue(value)
		        self.Value = normalize(value)
		        self:Display()
		        self:BuildDropdownList()
		        Library:SafeCallback(self.Callback, self.Value)
		        Library:SafeCallback(self.Changed, self.Value)
		    end
		    function option:SetValues(values)
		        if values then self.Values = values end
		        self.Value = normalize(self.Value)
		        self:Display()
		        self:BuildDropdownList()
		    end
		    function option:OnChanged(callback) self.Changed = callback; callback(self.Value) end
		    local function inside(point, frame)
		        local p, s = frame.AbsolutePosition, frame.AbsoluteSize
		        return point.X >= p.X and point.X <= p.X + s.X and point.Y >= p.Y and point.Y <= p.Y + s.Y
		    end
		    Creator.AddSignal(button.Activated, function() if option.Opened then option:Close() else option:Open() end end)
		    Creator.AddSignal(button:GetPropertyChangedSignal("AbsolutePosition"), place, card.Frame)
		    Creator.AddSignal(UserInputService.InputBegan, function(input)
		        if not option.Opened then return end
		        if input.KeyCode == Enum.KeyCode.Escape then option:Close(); return end
		        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		            if not inside(input.Position, popup) and not inside(input.Position, button) then option:Close() end
		        end
		    end, card.Frame)
		    local function cleanup()
		        if destroyed then return end
		        option:Close()
		        destroyed = true
		        local index = table.find(Library.OpenFrames, popup)
		        if index then table.remove(Library.OpenFrames, index) end
		        popup:Destroy()
		        if Library.Options[id] == option then Library.Options[id] = nil end
		    end
		    Creator.AddSignal(card.Frame.Destroying, cleanup)
		    function option:Destroy() cleanup(); card:Destroy() end
		    option:Display()
		    option:BuildDropdownList()
		    Library.Options[id] = option
		    return option
		end
		return Dropdown
	end,
	-- Module: MainModule/Elements/Input
	[23] = function()
		local __context, script, require = getModuleContext(23)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local Creator = require(script.Parent.Parent.Creator)
		local Input = { __type = "Input" }
		function Input:New(id, config)
		    assert(config.Title, "Input - Missing Title")
		    local Library = self.Library
		    local card = require(script.Parent.Parent.Components.Element)(config.Title, config.Description, self.Container, false)
		    local field = require(script.Parent.Parent.Components.Textbox)(card.Frame, true)
		    card:SetControl(field.Frame, { Width = 176, Height = 32 })
		    local option = {
		        Value = tostring(config.Default or ""), Numeric = config.Numeric == true,
		        Finished = config.Finished == true, Callback = config.Callback or function() end, Type = "Input",
		    }
		    option.SetTitle, option.SetDesc = card.SetTitle, card.SetDesc
		    option._Element = card
		    field.Input.Text = option.Value
		    field.Input.PlaceholderText = config.Placeholder or "Enter a value"
		    local changing = false
		    function option:SetValue(value)
		        value = tostring(value or "")
		        if config.MaxLength then
		            local length = utf8.len(value)
		            if length and length > config.MaxLength then
		                local offset = utf8.offset(value, config.MaxLength + 1)
		                value = value:sub(1, offset - 1)
		            end
		        end
		        if self.Numeric and value ~= "" and not tonumber(value) then value = self.Value end
		        local changed = value ~= self.Value
		        self.Value = value
		        changing = true
		        field.Input.Text = value
		        changing = false
		        if changed then
		            Library:SafeCallback(self.Callback, value)
		            Library:SafeCallback(self.Changed, value)
		        end
		    end
		    if option.Finished then
		        -- Commit on Enter, clicking elsewhere, and dismissing a touch keyboard.
		        Creator.AddSignal(field.Input.FocusLost, function() option:SetValue(field.Input.Text) end)
		    else
		        Creator.AddSignal(field.Input:GetPropertyChangedSignal("Text"), function()
		            if not changing then option:SetValue(field.Input.Text) end
		        end)
		    end
		    function option:OnChanged(callback) self.Changed = callback; callback(self.Value) end
		    function option:Destroy()
		        card:Destroy()
		        if Library.Options[id] == self then Library.Options[id] = nil end
		    end
		    Library.Options[id] = option
		    return option
		end
		return Input
	end,
	-- Module: MainModule/Elements/Keybind
	[24] = function()
		local __context, script, require = getModuleContext(24)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local UserInputService = game:GetService("UserInputService")
		local Creator = require(script.Parent.Parent.Creator)
		local New = Creator.New
		local Keybind = { __type = "Keybind" }
		function Keybind:New(id, config)
		    assert(config.Title and config.Default, "Keybind - Missing Title or Default")
		    local Library = self.Library
		    local card = require(script.Parent.Parent.Components.Element)(config.Title, config.Description, self.Container, true)
		    local option = {
		        Value = config.Default, Mode = config.Mode or "Toggle", Toggled = false, Type = "Keybind",
		        Callback = config.Callback or function() end, ChangedCallback = config.ChangedCallback or function() end,
		    }
		    option.SetTitle, option.SetDesc = card.SetTitle, card.SetDesc
		    option._Element = card
		    local button = New("TextButton", {
		        Text = option.Value, TextSize = 12, BackgroundTransparency = 0.78,
		        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		        ThemeTag = { TextColor3 = "Text", BackgroundColor3 = "Keybind" },
		    }, { New("UICorner", { CornerRadius = UDim.new(0, 7) }), New("UIStroke", { Transparency = 0.55, ThemeTag = { Color = "InElementBorder" } }) })
		    card:SetControl(button, { Width = 118, Height = 32, StackWidth = 320 })
		    local picking, ready = false, false
		    local function inputName(input)
		        if input.UserInputType == Enum.UserInputType.Keyboard then return input.KeyCode.Name end
		        if input.UserInputType == Enum.UserInputType.MouseButton1 then return "MouseLeft" end
		        if input.UserInputType == Enum.UserInputType.MouseButton2 then return "MouseRight" end
		        return nil
		    end
		    function option:GetState()
		        if self.Mode == "Always" then return true end
		        if UserInputService:GetFocusedTextBox() then return false end
		        if self.Mode == "Toggle" then return self.Toggled end
		        if self.Value == "None" then return false end
		        if self.Value == "MouseLeft" or self.Value == "MouseRight" then
		            return UserInputService:IsMouseButtonPressed(self.Value == "MouseLeft" and Enum.UserInputType.MouseButton1 or Enum.UserInputType.MouseButton2)
		        end
		        local ok, pressed = pcall(function() return UserInputService:IsKeyDown(Enum.KeyCode[self.Value]) end)
		        return ok and pressed or false
		    end
		    function option:SetValue(value, mode)
		        self.Value = value or self.Value
		        self.Mode = mode or self.Mode
		        button.Text = self.Value
		    end
		    function option:DoClick()
		        Library:SafeCallback(self.Callback, self.Toggled)
		        Library:SafeCallback(self.Clicked, self.Toggled)
		    end
		    function option:OnClick(callback) self.Clicked = callback end
		    function option:OnChanged(callback) self.Changed = callback; callback(self.Value) end
		    Creator.AddSignal(button.Activated, function()
		        picking, ready = true, false
		        button.Text = "Press a key..."
		        task.delay(0.15, function() if not card.Destroyed then ready = true end end)
		    end)
		    Creator.AddSignal(UserInputService.InputBegan, function(input)
		        if picking then
		            if not ready then return end
		            if input.KeyCode == Enum.KeyCode.Escape then picking = false; button.Text = option.Value; return end
		            local value = inputName(input)
		            if value then
		                if value == "Backspace" then value = "None" end
		                picking = false
		                option:SetValue(value)
		                Library:SafeCallback(option.ChangedCallback, input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType)
		                Library:SafeCallback(option.Changed, option.Value)
		            end
		            return
		        end
		        if not UserInputService:GetFocusedTextBox() and inputName(input) == option.Value and option.Mode == "Toggle" then
		            option.Toggled = not option.Toggled
		            option:DoClick()
		        end
		    end, card.Frame)
		    function option:Destroy() picking = false; card:Destroy(); if Library.Options[id] == self then Library.Options[id] = nil end end
		    Library.Options[id] = option
		    return option
		end
		return Keybind
	end,
	-- Module: MainModule/Elements/Paragraph
	[25] = function()
		local __context, script, require = getModuleContext(25)
		-- Reconstructed module: MainModule/Elements/Paragraph
		-- Author: dawid | License: MIT (original Fluent header).
		local Parent_21 = script.Parent.Parent
		local Components_8, Flipper_11, Creator_19, object_39 =
			Parent_21.Components, require(Parent_21.Packages.Flipper), require(Parent_21.Creator), {}
		object_39.__index = object_39
		object_39.__type = "Paragraph"
		function object_39.New(self_69, argument_122)
			assert(argument_122.Title, "Paragraph - Missing Title")
			argument_122.Content = argument_122.Content or ""
			local value_52 =
				require(Components_8.Element)(argument_122.Title, argument_122.Content, self_69.Container, false)
			value_52.Frame.BackgroundTransparency = Creator_19.GetThemeProperty("ElementTransparency")
			value_52.Border.Transparency = 0.6
			return value_52
		end
		return object_39
	end,
	-- Module: MainModule/Elements/Slider
	[26] = function()
		local __context, script, require = getModuleContext(26)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local UserInputService = game:GetService("UserInputService")
		local Creator = require(script.Parent.Parent.Creator)
		local New = Creator.New
		local Slider = { __type = "Slider" }
		function Slider:New(id, config)
		    assert(config.Title, "Slider - Missing Title")
		    assert(type(config.Default) == "number", "Slider - Missing default value")
		    assert(type(config.Min) == "number" and type(config.Max) == "number" and config.Max > config.Min, "Slider - Max must be greater than Min")
		    local Library = self.Library
		    local card = require(script.Parent.Parent.Components.Element)(config.Title, config.Description, self.Container, false)
		    local option = {
		        Value = config.Default, Min = config.Min, Max = config.Max, Rounding = config.Rounding or 0,
		        Callback = config.Callback or function() end, Type = "Slider",
		    }
		    option.SetTitle, option.SetDesc = card.SetTitle, card.SetDesc
		    option._Element = card
		    local holder = New("Frame", { BackgroundTransparency = 1 })
		    card:SetControl(holder, { Width = 204, Height = 32 })
		    local label = New("TextLabel", {
		        TextSize = 12, Size = UDim2.fromOffset(48, 32), TextXAlignment = Enum.TextXAlignment.Right, Parent = holder,
		        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		        ThemeTag = { TextColor3 = "Accent" },
		    })
		    local hit = New("TextButton", {
		        Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(60, 0), Parent = holder,
		    })
		    local rail = New("Frame", {
		        Size = UDim2.new(1, -14, 0, 4), Position = UDim2.new(0, 7, 0.5, -2), Parent = hit,
		        BackgroundTransparency = 0.45, ThemeTag = { BackgroundColor3 = "SliderRail" },
		    }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		    local fill = New("Frame", {
		        Size = UDim2.fromScale(0, 1), Parent = rail, ThemeTag = { BackgroundColor3 = "Accent" },
		    }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		    local knob = New("Frame", {
		        Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Parent = rail,
		        ThemeTag = { BackgroundColor3 = "Accent" },
		    }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		    function option:SetValue(value)
		        value = tonumber(value)
		        if not value then return end
		        self.Value = math.clamp(Library:Round(math.clamp(value, self.Min, self.Max), self.Rounding), self.Min, self.Max)
		        local ratio = (self.Value - self.Min) / (self.Max - self.Min)
		        fill.Size, knob.Position, label.Text = UDim2.fromScale(ratio, 1), UDim2.fromScale(ratio, 0.5), tostring(self.Value)
		        Library:SafeCallback(self.Callback, self.Value)
		        Library:SafeCallback(self.Changed, self.Value)
		    end
		    function option:OnChanged(callback) self.Changed = callback; callback(self.Value) end
		    local dragging
		    local function point(input)
		        if rail.AbsoluteSize.X <= 0 then return end
		        option:SetValue(option.Min + (option.Max - option.Min) * math.clamp((input.Position.X - rail.AbsolutePosition.X) / rail.AbsoluteSize.X, 0, 1))
		    end
		    Creator.AddSignal(hit.InputBegan, function(input)
		        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = input; point(input) end
		    end)
		    Creator.AddSignal(UserInputService.InputChanged, function(input)
		        if dragging and (input == dragging or dragging.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then point(input) end
		    end, card.Frame)
		    Creator.AddSignal(UserInputService.InputEnded, function(input)
		        if input == dragging or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = nil end
		    end, card.Frame)
		    function option:Destroy() card:Destroy(); if Library.Options[id] == self then Library.Options[id] = nil end end
		    Library.Options[id] = option
		    option:SetValue(config.Default)
		    return option
		end
		return Slider
	end,
	-- Module: MainModule/Elements/Toggle
	[27] = function()
		local __context, script, require = getModuleContext(27)
		-- Bloomware UI, based on Fluent by dawid (MIT).
		local TweenService = game:GetService("TweenService")
		local Creator = require(script.Parent.Parent.Creator)
		local New = Creator.New
		local Toggle = { __type = "Toggle" }
		function Toggle:New(id, config)
		    assert(config.Title, "Toggle - Missing Title")
		    local Library = self.Library
		    local card = require(script.Parent.Parent.Components.Element)(config.Title, config.Description, self.Container, true)
		    local option = { Value = config.Default == true, Callback = config.Callback or function() end, Type = "Toggle" }
		    option.SetTitle, option.SetDesc = card.SetTitle, card.SetDesc
		    option._Element = card
		    local stroke = New("UIStroke", { Transparency = 0.55, ThemeTag = { Color = "ToggleSlider" } })
		    local knob = New("Frame", {
		        Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(3, 3),
		        ThemeTag = { BackgroundColor3 = "ToggleSlider" },
		    }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		    local track = New("Frame", {
		        BackgroundTransparency = 0.88, ThemeTag = { BackgroundColor3 = "ToggleSlider" },
		    }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke, knob })
		    card:SetControl(track, { Width = 42, Height = 22, StackWidth = 240 })
		    local animation
		    function option:OnChanged(callback) self.Changed = callback; callback(self.Value) end
		    function option:SetValue(value)
		        self.Value = not not value
		        Creator.OverrideTag(track, { BackgroundColor3 = self.Value and "Accent" or "ToggleSlider" })
		        Creator.OverrideTag(knob, { BackgroundColor3 = self.Value and "ToggleToggled" or "ToggleSlider" })
		        Creator.OverrideTag(stroke, { Color = self.Value and "Accent" or "ToggleSlider" })
		        track.BackgroundTransparency = self.Value and 0 or 0.88
		        if animation then animation:Cancel() end
		        animation = TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		            Position = UDim2.fromOffset(self.Value and 23 or 3, 3),
		        })
		        animation:Play()
		        Library:SafeCallback(self.Callback, self.Value)
		        Library:SafeCallback(self.Changed, self.Value)
		    end
		    function option:Destroy()
		        if animation then animation:Cancel() end
		        card:Destroy()
		        if Library.Options[id] == self then Library.Options[id] = nil end
		    end
		    Creator.AddSignal(card.Frame.Activated, function() option:SetValue(not option.Value) end)
		    Library.Options[id] = option
		    option:SetValue(option.Value)
		    return option
		end
		return Toggle
	end,
	-- Module: MainModule/Icons
	[28] = function()
		local __context, script, require = getModuleContext(28)
		-- Reconstructed module: MainModule/Icons
		-- Author: dawid | License: MIT (original Fluent header).
		return {
			assets = {
				["lucide-accessibility"] = "rbxassetid://10709751939",
				["lucide-activity"] = "rbxassetid://10709752035",
				["lucide-air-vent"] = "rbxassetid://10709752131",
				["lucide-airplay"] = "rbxassetid://10709752254",
				["lucide-alarm-check"] = "rbxassetid://10709752405",
				["lucide-alarm-clock"] = "rbxassetid://10709752630",
				["lucide-alarm-clock-off"] = "rbxassetid://10709752508",
				["lucide-alarm-minus"] = "rbxassetid://10709752732",
				["lucide-alarm-plus"] = "rbxassetid://10709752825",
				["lucide-album"] = "rbxassetid://10709752906",
				["lucide-alert-circle"] = "rbxassetid://10709752996",
				["lucide-alert-octagon"] = "rbxassetid://10709753064",
				["lucide-alert-triangle"] = "rbxassetid://10709753149",
				["lucide-align-center"] = "rbxassetid://10709753570",
				["lucide-align-center-horizontal"] = "rbxassetid://10709753272",
				["lucide-align-center-vertical"] = "rbxassetid://10709753421",
				["lucide-align-end-horizontal"] = "rbxassetid://10709753692",
				["lucide-align-end-vertical"] = "rbxassetid://10709753808",
				["lucide-align-horizontal-distribute-center"] = "rbxassetid://10747779791",
				["lucide-align-horizontal-distribute-end"] = "rbxassetid://10747784534",
				["lucide-align-horizontal-distribute-start"] = "rbxassetid://10709754118",
				["lucide-align-horizontal-justify-center"] = "rbxassetid://10709754204",
				["lucide-align-horizontal-justify-end"] = "rbxassetid://10709754317",
				["lucide-align-horizontal-justify-start"] = "rbxassetid://10709754436",
				["lucide-align-horizontal-space-around"] = "rbxassetid://10709754590",
				["lucide-align-horizontal-space-between"] = "rbxassetid://10709754749",
				["lucide-align-justify"] = "rbxassetid://10709759610",
				["lucide-align-left"] = "rbxassetid://10709759764",
				["lucide-align-right"] = "rbxassetid://10709759895",
				["lucide-align-start-horizontal"] = "rbxassetid://10709760051",
				["lucide-align-start-vertical"] = "rbxassetid://10709760244",
				["lucide-align-vertical-distribute-center"] = "rbxassetid://10709760351",
				["lucide-align-vertical-distribute-end"] = "rbxassetid://10709760434",
				["lucide-align-vertical-distribute-start"] = "rbxassetid://10709760612",
				["lucide-align-vertical-justify-center"] = "rbxassetid://10709760814",
				["lucide-align-vertical-justify-end"] = "rbxassetid://10709761003",
				["lucide-align-vertical-justify-start"] = "rbxassetid://10709761176",
				["lucide-align-vertical-space-around"] = "rbxassetid://10709761324",
				["lucide-align-vertical-space-between"] = "rbxassetid://10709761434",
				["lucide-anchor"] = "rbxassetid://10709761530",
				["lucide-angry"] = "rbxassetid://10709761629",
				["lucide-annoyed"] = "rbxassetid://10709761722",
				["lucide-aperture"] = "rbxassetid://10709761813",
				["lucide-apple"] = "rbxassetid://10709761889",
				["lucide-archive"] = "rbxassetid://10709762233",
				["lucide-archive-restore"] = "rbxassetid://10709762058",
				["lucide-armchair"] = "rbxassetid://10709762327",
				["lucide-arrow-big-down"] = "rbxassetid://10747796644",
				["lucide-arrow-big-left"] = "rbxassetid://10709762574",
				["lucide-arrow-big-right"] = "rbxassetid://10709762727",
				["lucide-arrow-big-up"] = "rbxassetid://10709762879",
				["lucide-arrow-down"] = "rbxassetid://10709767827",
				["lucide-arrow-down-circle"] = "rbxassetid://10709763034",
				["lucide-arrow-down-left"] = "rbxassetid://10709767656",
				["lucide-arrow-down-right"] = "rbxassetid://10709767750",
				["lucide-arrow-left"] = "rbxassetid://10709768114",
				["lucide-arrow-left-circle"] = "rbxassetid://10709767936",
				["lucide-arrow-left-right"] = "rbxassetid://10709768019",
				["lucide-arrow-right"] = "rbxassetid://10709768347",
				["lucide-arrow-right-circle"] = "rbxassetid://10709768226",
				["lucide-arrow-up"] = "rbxassetid://10709768939",
				["lucide-arrow-up-circle"] = "rbxassetid://10709768432",
				["lucide-arrow-up-down"] = "rbxassetid://10709768538",
				["lucide-arrow-up-left"] = "rbxassetid://10709768661",
				["lucide-arrow-up-right"] = "rbxassetid://10709768787",
				["lucide-asterisk"] = "rbxassetid://10709769095",
				["lucide-at-sign"] = "rbxassetid://10709769286",
				["lucide-award"] = "rbxassetid://10709769406",
				["lucide-axe"] = "rbxassetid://10709769508",
				["lucide-axis-3d"] = "rbxassetid://10709769598",
				["lucide-baby"] = "rbxassetid://10709769732",
				["lucide-backpack"] = "rbxassetid://10709769841",
				["lucide-baggage-claim"] = "rbxassetid://10709769935",
				["lucide-banana"] = "rbxassetid://10709770005",
				["lucide-banknote"] = "rbxassetid://10709770178",
				["lucide-bar-chart"] = "rbxassetid://10709773755",
				["lucide-bar-chart-2"] = "rbxassetid://10709770317",
				["lucide-bar-chart-3"] = "rbxassetid://10709770431",
				["lucide-bar-chart-4"] = "rbxassetid://10709770560",
				["lucide-bar-chart-horizontal"] = "rbxassetid://10709773669",
				["lucide-barcode"] = "rbxassetid://10747360675",
				["lucide-baseline"] = "rbxassetid://10709773863",
				["lucide-bath"] = "rbxassetid://10709773963",
				["lucide-battery"] = "rbxassetid://10709774640",
				["lucide-battery-charging"] = "rbxassetid://10709774068",
				["lucide-battery-full"] = "rbxassetid://10709774206",
				["lucide-battery-low"] = "rbxassetid://10709774370",
				["lucide-battery-medium"] = "rbxassetid://10709774513",
				["lucide-beaker"] = "rbxassetid://10709774756",
				["lucide-bed"] = "rbxassetid://10709775036",
				["lucide-bed-double"] = "rbxassetid://10709774864",
				["lucide-bed-single"] = "rbxassetid://10709774968",
				["lucide-beer"] = "rbxassetid://10709775167",
				["lucide-bell"] = "rbxassetid://10709775704",
				["lucide-bell-minus"] = "rbxassetid://10709775241",
				["lucide-bell-off"] = "rbxassetid://10709775320",
				["lucide-bell-plus"] = "rbxassetid://10709775448",
				["lucide-bell-ring"] = "rbxassetid://10709775560",
				["lucide-bike"] = "rbxassetid://10709775894",
				["lucide-binary"] = "rbxassetid://10709776050",
				["lucide-bitcoin"] = "rbxassetid://10709776126",
				["lucide-bluetooth"] = "rbxassetid://10709776655",
				["lucide-bluetooth-connected"] = "rbxassetid://10709776240",
				["lucide-bluetooth-off"] = "rbxassetid://10709776344",
				["lucide-bluetooth-searching"] = "rbxassetid://10709776501",
				["lucide-bold"] = "rbxassetid://10747813908",
				["lucide-bomb"] = "rbxassetid://10709781460",
				["lucide-bone"] = "rbxassetid://10709781605",
				["lucide-book"] = "rbxassetid://10709781824",
				["lucide-book-open"] = "rbxassetid://10709781717",
				["lucide-bookmark"] = "rbxassetid://10709782154",
				["lucide-bookmark-minus"] = "rbxassetid://10709781919",
				["lucide-bookmark-plus"] = "rbxassetid://10709782044",
				["lucide-bot"] = "rbxassetid://10709782230",
				["lucide-box"] = "rbxassetid://10709782497",
				["lucide-box-select"] = "rbxassetid://10709782342",
				["lucide-boxes"] = "rbxassetid://10709782582",
				["lucide-briefcase"] = "rbxassetid://10709782662",
				["lucide-brush"] = "rbxassetid://10709782758",
				["lucide-bug"] = "rbxassetid://10709782845",
				["lucide-building"] = "rbxassetid://10709783051",
				["lucide-building-2"] = "rbxassetid://10709782939",
				["lucide-bus"] = "rbxassetid://10709783137",
				["lucide-cake"] = "rbxassetid://10709783217",
				["lucide-calculator"] = "rbxassetid://10709783311",
				["lucide-calendar"] = "rbxassetid://10709789505",
				["lucide-calendar-check"] = "rbxassetid://10709783474",
				["lucide-calendar-check-2"] = "rbxassetid://10709783392",
				["lucide-calendar-clock"] = "rbxassetid://10709783577",
				["lucide-calendar-days"] = "rbxassetid://10709783673",
				["lucide-calendar-heart"] = "rbxassetid://10709783835",
				["lucide-calendar-minus"] = "rbxassetid://10709783959",
				["lucide-calendar-off"] = "rbxassetid://10709788784",
				["lucide-calendar-plus"] = "rbxassetid://10709788937",
				["lucide-calendar-range"] = "rbxassetid://10709789053",
				["lucide-calendar-search"] = "rbxassetid://10709789200",
				["lucide-calendar-x"] = "rbxassetid://10709789407",
				["lucide-calendar-x-2"] = "rbxassetid://10709789329",
				["lucide-camera"] = "rbxassetid://10709789686",
				["lucide-camera-off"] = "rbxassetid://10747822677",
				["lucide-car"] = "rbxassetid://10709789810",
				["lucide-carrot"] = "rbxassetid://10709789960",
				["lucide-cast"] = "rbxassetid://10709790097",
				["lucide-charge"] = "rbxassetid://10709790202",
				["lucide-check"] = "rbxassetid://10709790644",
				["lucide-check-circle"] = "rbxassetid://10709790387",
				["lucide-check-circle-2"] = "rbxassetid://10709790298",
				["lucide-check-square"] = "rbxassetid://10709790537",
				["lucide-chef-hat"] = "rbxassetid://10709790757",
				["lucide-cherry"] = "rbxassetid://10709790875",
				["lucide-chevron-down"] = "rbxassetid://10709790948",
				["lucide-chevron-first"] = "rbxassetid://10709791015",
				["lucide-chevron-last"] = "rbxassetid://10709791130",
				["lucide-chevron-left"] = "rbxassetid://10709791281",
				["lucide-chevron-right"] = "rbxassetid://10709791437",
				["lucide-chevron-up"] = "rbxassetid://10709791523",
				["lucide-chevrons-down"] = "rbxassetid://10709796864",
				["lucide-chevrons-down-up"] = "rbxassetid://10709791632",
				["lucide-chevrons-left"] = "rbxassetid://10709797151",
				["lucide-chevrons-left-right"] = "rbxassetid://10709797006",
				["lucide-chevrons-right"] = "rbxassetid://10709797382",
				["lucide-chevrons-right-left"] = "rbxassetid://10709797274",
				["lucide-chevrons-up"] = "rbxassetid://10709797622",
				["lucide-chevrons-up-down"] = "rbxassetid://10709797508",
				["lucide-chrome"] = "rbxassetid://10709797725",
				["lucide-circle"] = "rbxassetid://10709798174",
				["lucide-circle-dot"] = "rbxassetid://10709797837",
				["lucide-circle-ellipsis"] = "rbxassetid://10709797985",
				["lucide-circle-slashed"] = "rbxassetid://10709798100",
				["lucide-citrus"] = "rbxassetid://10709798276",
				["lucide-clapperboard"] = "rbxassetid://10709798350",
				["lucide-clipboard"] = "rbxassetid://10709799288",
				["lucide-clipboard-check"] = "rbxassetid://10709798443",
				["lucide-clipboard-copy"] = "rbxassetid://10709798574",
				["lucide-clipboard-edit"] = "rbxassetid://10709798682",
				["lucide-clipboard-list"] = "rbxassetid://10709798792",
				["lucide-clipboard-signature"] = "rbxassetid://10709798890",
				["lucide-clipboard-type"] = "rbxassetid://10709798999",
				["lucide-clipboard-x"] = "rbxassetid://10709799124",
				["lucide-clock"] = "rbxassetid://10709805144",
				["lucide-clock-1"] = "rbxassetid://10709799535",
				["lucide-clock-10"] = "rbxassetid://10709799718",
				["lucide-clock-11"] = "rbxassetid://10709799818",
				["lucide-clock-12"] = "rbxassetid://10709799962",
				["lucide-clock-2"] = "rbxassetid://10709803876",
				["lucide-clock-3"] = "rbxassetid://10709803989",
				["lucide-clock-4"] = "rbxassetid://10709804164",
				["lucide-clock-5"] = "rbxassetid://10709804291",
				["lucide-clock-6"] = "rbxassetid://10709804435",
				["lucide-clock-7"] = "rbxassetid://10709804599",
				["lucide-clock-8"] = "rbxassetid://10709804784",
				["lucide-clock-9"] = "rbxassetid://10709804996",
				["lucide-cloud"] = "rbxassetid://10709806740",
				["lucide-cloud-cog"] = "rbxassetid://10709805262",
				["lucide-cloud-drizzle"] = "rbxassetid://10709805371",
				["lucide-cloud-fog"] = "rbxassetid://10709805477",
				["lucide-cloud-hail"] = "rbxassetid://10709805596",
				["lucide-cloud-lightning"] = "rbxassetid://10709805727",
				["lucide-cloud-moon"] = "rbxassetid://10709805942",
				["lucide-cloud-moon-rain"] = "rbxassetid://10709805838",
				["lucide-cloud-off"] = "rbxassetid://10709806060",
				["lucide-cloud-rain"] = "rbxassetid://10709806277",
				["lucide-cloud-rain-wind"] = "rbxassetid://10709806166",
				["lucide-cloud-snow"] = "rbxassetid://10709806374",
				["lucide-cloud-sun"] = "rbxassetid://10709806631",
				["lucide-cloud-sun-rain"] = "rbxassetid://10709806475",
				["lucide-cloudy"] = "rbxassetid://10709806859",
				["lucide-clover"] = "rbxassetid://10709806995",
				["lucide-code"] = "rbxassetid://10709810463",
				["lucide-code-2"] = "rbxassetid://10709807111",
				["lucide-codepen"] = "rbxassetid://10709810534",
				["lucide-codesandbox"] = "rbxassetid://10709810676",
				["lucide-coffee"] = "rbxassetid://10709810814",
				["lucide-cog"] = "rbxassetid://10709810948",
				["lucide-coins"] = "rbxassetid://10709811110",
				["lucide-columns"] = "rbxassetid://10709811261",
				["lucide-command"] = "rbxassetid://10709811365",
				["lucide-compass"] = "rbxassetid://10709811445",
				["lucide-component"] = "rbxassetid://10709811595",
				["lucide-concierge-bell"] = "rbxassetid://10709811706",
				["lucide-connection"] = "rbxassetid://10747361219",
				["lucide-contact"] = "rbxassetid://10709811834",
				["lucide-contrast"] = "rbxassetid://10709811939",
				["lucide-cookie"] = "rbxassetid://10709812067",
				["lucide-copy"] = "rbxassetid://10709812159",
				["lucide-copyleft"] = "rbxassetid://10709812251",
				["lucide-copyright"] = "rbxassetid://10709812311",
				["lucide-corner-down-left"] = "rbxassetid://10709812396",
				["lucide-corner-down-right"] = "rbxassetid://10709812485",
				["lucide-corner-left-down"] = "rbxassetid://10709812632",
				["lucide-corner-left-up"] = "rbxassetid://10709812784",
				["lucide-corner-right-down"] = "rbxassetid://10709812939",
				["lucide-corner-right-up"] = "rbxassetid://10709813094",
				["lucide-corner-up-left"] = "rbxassetid://10709813185",
				["lucide-corner-up-right"] = "rbxassetid://10709813281",
				["lucide-cpu"] = "rbxassetid://10709813383",
				["lucide-croissant"] = "rbxassetid://10709818125",
				["lucide-crop"] = "rbxassetid://10709818245",
				["lucide-cross"] = "rbxassetid://10709818399",
				["lucide-crosshair"] = "rbxassetid://10709818534",
				["lucide-crown"] = "rbxassetid://10709818626",
				["lucide-cup-soda"] = "rbxassetid://10709818763",
				["lucide-curly-braces"] = "rbxassetid://10709818847",
				["lucide-currency"] = "rbxassetid://10709818931",
				["lucide-database"] = "rbxassetid://10709818996",
				["lucide-delete"] = "rbxassetid://10709819059",
				["lucide-diamond"] = "rbxassetid://10709819149",
				["lucide-dice-1"] = "rbxassetid://10709819266",
				["lucide-dice-2"] = "rbxassetid://10709819361",
				["lucide-dice-3"] = "rbxassetid://10709819508",
				["lucide-dice-4"] = "rbxassetid://10709819670",
				["lucide-dice-5"] = "rbxassetid://10709819801",
				["lucide-dice-6"] = "rbxassetid://10709819896",
				["lucide-dices"] = "rbxassetid://10723343321",
				["lucide-diff"] = "rbxassetid://10723343416",
				["lucide-disc"] = "rbxassetid://10723343537",
				["lucide-divide"] = "rbxassetid://10723343805",
				["lucide-divide-circle"] = "rbxassetid://10723343636",
				["lucide-divide-square"] = "rbxassetid://10723343737",
				["lucide-dollar-sign"] = "rbxassetid://10723343958",
				["lucide-download"] = "rbxassetid://10723344270",
				["lucide-download-cloud"] = "rbxassetid://10723344088",
				["lucide-droplet"] = "rbxassetid://10723344432",
				["lucide-droplets"] = "rbxassetid://10734883356",
				["lucide-drumstick"] = "rbxassetid://10723344737",
				["lucide-edit"] = "rbxassetid://10734883598",
				["lucide-edit-2"] = "rbxassetid://10723344885",
				["lucide-edit-3"] = "rbxassetid://10723345088",
				["lucide-egg"] = "rbxassetid://10723345518",
				["lucide-egg-fried"] = "rbxassetid://10723345347",
				["lucide-electricity"] = "rbxassetid://10723345749",
				["lucide-electricity-off"] = "rbxassetid://10723345643",
				["lucide-equal"] = "rbxassetid://10723345990",
				["lucide-equal-not"] = "rbxassetid://10723345866",
				["lucide-eraser"] = "rbxassetid://10723346158",
				["lucide-euro"] = "rbxassetid://10723346372",
				["lucide-expand"] = "rbxassetid://10723346553",
				["lucide-external-link"] = "rbxassetid://10723346684",
				["lucide-eye"] = "rbxassetid://10723346959",
				["lucide-eye-off"] = "rbxassetid://10723346871",
				["lucide-factory"] = "rbxassetid://10723347051",
				["lucide-fan"] = "rbxassetid://10723354359",
				["lucide-fast-forward"] = "rbxassetid://10723354521",
				["lucide-feather"] = "rbxassetid://10723354671",
				["lucide-figma"] = "rbxassetid://10723354801",
				["lucide-file"] = "rbxassetid://10723374641",
				["lucide-file-archive"] = "rbxassetid://10723354921",
				["lucide-file-audio"] = "rbxassetid://10723355148",
				["lucide-file-audio-2"] = "rbxassetid://10723355026",
				["lucide-file-axis-3d"] = "rbxassetid://10723355272",
				["lucide-file-badge"] = "rbxassetid://10723355622",
				["lucide-file-badge-2"] = "rbxassetid://10723355451",
				["lucide-file-bar-chart"] = "rbxassetid://10723355887",
				["lucide-file-bar-chart-2"] = "rbxassetid://10723355746",
				["lucide-file-box"] = "rbxassetid://10723355989",
				["lucide-file-check"] = "rbxassetid://10723356210",
				["lucide-file-check-2"] = "rbxassetid://10723356100",
				["lucide-file-clock"] = "rbxassetid://10723356329",
				["lucide-file-code"] = "rbxassetid://10723356507",
				["lucide-file-cog"] = "rbxassetid://10723356830",
				["lucide-file-cog-2"] = "rbxassetid://10723356676",
				["lucide-file-diff"] = "rbxassetid://10723357039",
				["lucide-file-digit"] = "rbxassetid://10723357151",
				["lucide-file-down"] = "rbxassetid://10723357322",
				["lucide-file-edit"] = "rbxassetid://10723357495",
				["lucide-file-heart"] = "rbxassetid://10723357637",
				["lucide-file-image"] = "rbxassetid://10723357790",
				["lucide-file-input"] = "rbxassetid://10723357933",
				["lucide-file-json"] = "rbxassetid://10723364435",
				["lucide-file-json-2"] = "rbxassetid://10723364361",
				["lucide-file-key"] = "rbxassetid://10723364605",
				["lucide-file-key-2"] = "rbxassetid://10723364515",
				["lucide-file-line-chart"] = "rbxassetid://10723364725",
				["lucide-file-lock"] = "rbxassetid://10723364957",
				["lucide-file-lock-2"] = "rbxassetid://10723364861",
				["lucide-file-minus"] = "rbxassetid://10723365254",
				["lucide-file-minus-2"] = "rbxassetid://10723365086",
				["lucide-file-output"] = "rbxassetid://10723365457",
				["lucide-file-pie-chart"] = "rbxassetid://10723365598",
				["lucide-file-plus"] = "rbxassetid://10723365877",
				["lucide-file-plus-2"] = "rbxassetid://10723365766",
				["lucide-file-question"] = "rbxassetid://10723365987",
				["lucide-file-scan"] = "rbxassetid://10723366167",
				["lucide-file-search"] = "rbxassetid://10723366550",
				["lucide-file-search-2"] = "rbxassetid://10723366340",
				["lucide-file-signature"] = "rbxassetid://10723366741",
				["lucide-file-spreadsheet"] = "rbxassetid://10723366962",
				["lucide-file-symlink"] = "rbxassetid://10723367098",
				["lucide-file-terminal"] = "rbxassetid://10723367244",
				["lucide-file-text"] = "rbxassetid://10723367380",
				["lucide-file-type"] = "rbxassetid://10723367606",
				["lucide-file-type-2"] = "rbxassetid://10723367509",
				["lucide-file-up"] = "rbxassetid://10723367734",
				["lucide-file-video"] = "rbxassetid://10723373884",
				["lucide-file-video-2"] = "rbxassetid://10723367834",
				["lucide-file-volume"] = "rbxassetid://10723374172",
				["lucide-file-volume-2"] = "rbxassetid://10723374030",
				["lucide-file-warning"] = "rbxassetid://10723374276",
				["lucide-file-x"] = "rbxassetid://10723374544",
				["lucide-file-x-2"] = "rbxassetid://10723374378",
				["lucide-files"] = "rbxassetid://10723374759",
				["lucide-film"] = "rbxassetid://10723374981",
				["lucide-filter"] = "rbxassetid://10723375128",
				["lucide-fingerprint"] = "rbxassetid://10723375250",
				["lucide-flag"] = "rbxassetid://10723375890",
				["lucide-flag-off"] = "rbxassetid://10723375443",
				["lucide-flag-triangle-left"] = "rbxassetid://10723375608",
				["lucide-flag-triangle-right"] = "rbxassetid://10723375727",
				["lucide-flame"] = "rbxassetid://10723376114",
				["lucide-flashlight"] = "rbxassetid://10723376471",
				["lucide-flashlight-off"] = "rbxassetid://10723376365",
				["lucide-flask-conical"] = "rbxassetid://10734883986",
				["lucide-flask-round"] = "rbxassetid://10723376614",
				["lucide-flip-horizontal"] = "rbxassetid://10723376884",
				["lucide-flip-horizontal-2"] = "rbxassetid://10723376745",
				["lucide-flip-vertical"] = "rbxassetid://10723377138",
				["lucide-flip-vertical-2"] = "rbxassetid://10723377026",
				["lucide-flower"] = "rbxassetid://10747830374",
				["lucide-flower-2"] = "rbxassetid://10723377305",
				["lucide-focus"] = "rbxassetid://10723377537",
				["lucide-folder"] = "rbxassetid://10723387563",
				["lucide-folder-archive"] = "rbxassetid://10723384478",
				["lucide-folder-check"] = "rbxassetid://10723384605",
				["lucide-folder-clock"] = "rbxassetid://10723384731",
				["lucide-folder-closed"] = "rbxassetid://10723384893",
				["lucide-folder-cog"] = "rbxassetid://10723385213",
				["lucide-folder-cog-2"] = "rbxassetid://10723385036",
				["lucide-folder-down"] = "rbxassetid://10723385338",
				["lucide-folder-edit"] = "rbxassetid://10723385445",
				["lucide-folder-heart"] = "rbxassetid://10723385545",
				["lucide-folder-input"] = "rbxassetid://10723385721",
				["lucide-folder-key"] = "rbxassetid://10723385848",
				["lucide-folder-lock"] = "rbxassetid://10723386005",
				["lucide-folder-minus"] = "rbxassetid://10723386127",
				["lucide-folder-open"] = "rbxassetid://10723386277",
				["lucide-folder-output"] = "rbxassetid://10723386386",
				["lucide-folder-plus"] = "rbxassetid://10723386531",
				["lucide-folder-search"] = "rbxassetid://10723386787",
				["lucide-folder-search-2"] = "rbxassetid://10723386674",
				["lucide-folder-symlink"] = "rbxassetid://10723386930",
				["lucide-folder-tree"] = "rbxassetid://10723387085",
				["lucide-folder-up"] = "rbxassetid://10723387265",
				["lucide-folder-x"] = "rbxassetid://10723387448",
				["lucide-folders"] = "rbxassetid://10723387721",
				["lucide-form-input"] = "rbxassetid://10723387841",
				["lucide-forward"] = "rbxassetid://10723388016",
				["lucide-frame"] = "rbxassetid://10723394389",
				["lucide-framer"] = "rbxassetid://10723394565",
				["lucide-frown"] = "rbxassetid://10723394681",
				["lucide-fuel"] = "rbxassetid://10723394846",
				["lucide-function-square"] = "rbxassetid://10723395041",
				["lucide-gamepad"] = "rbxassetid://10723395457",
				["lucide-gamepad-2"] = "rbxassetid://10723395215",
				["lucide-gauge"] = "rbxassetid://10723395708",
				["lucide-gavel"] = "rbxassetid://10723395896",
				["lucide-gem"] = "rbxassetid://10723396000",
				["lucide-ghost"] = "rbxassetid://10723396107",
				["lucide-gift"] = "rbxassetid://10723396402",
				["lucide-gift-card"] = "rbxassetid://10723396225",
				["lucide-git-branch"] = "rbxassetid://10723396676",
				["lucide-git-branch-plus"] = "rbxassetid://10723396542",
				["lucide-git-commit"] = "rbxassetid://10723396812",
				["lucide-git-compare"] = "rbxassetid://10723396954",
				["lucide-git-fork"] = "rbxassetid://10723397049",
				["lucide-git-merge"] = "rbxassetid://10723397165",
				["lucide-git-pull-request"] = "rbxassetid://10723397431",
				["lucide-git-pull-request-closed"] = "rbxassetid://10723397268",
				["lucide-git-pull-request-draft"] = "rbxassetid://10734884302",
				["lucide-glass"] = "rbxassetid://10723397788",
				["lucide-glass-2"] = "rbxassetid://10723397529",
				["lucide-glass-water"] = "rbxassetid://10723397678",
				["lucide-glasses"] = "rbxassetid://10723397895",
				["lucide-globe"] = "rbxassetid://10723404337",
				["lucide-globe-2"] = "rbxassetid://10723398002",
				["lucide-grab"] = "rbxassetid://10723404472",
				["lucide-graduation-cap"] = "rbxassetid://10723404691",
				["lucide-grape"] = "rbxassetid://10723404822",
				["lucide-grid"] = "rbxassetid://10723404936",
				["lucide-grip-horizontal"] = "rbxassetid://10723405089",
				["lucide-grip-vertical"] = "rbxassetid://10723405236",
				["lucide-hammer"] = "rbxassetid://10723405360",
				["lucide-hand"] = "rbxassetid://10723405649",
				["lucide-hand-metal"] = "rbxassetid://10723405508",
				["lucide-hard-drive"] = "rbxassetid://10723405749",
				["lucide-hard-hat"] = "rbxassetid://10723405859",
				["lucide-hash"] = "rbxassetid://10723405975",
				["lucide-haze"] = "rbxassetid://10723406078",
				["lucide-headphones"] = "rbxassetid://10723406165",
				["lucide-heart"] = "rbxassetid://10723406885",
				["lucide-heart-crack"] = "rbxassetid://10723406299",
				["lucide-heart-handshake"] = "rbxassetid://10723406480",
				["lucide-heart-off"] = "rbxassetid://10723406662",
				["lucide-heart-pulse"] = "rbxassetid://10723406795",
				["lucide-help-circle"] = "rbxassetid://10723406988",
				["lucide-hexagon"] = "rbxassetid://10723407092",
				["lucide-highlighter"] = "rbxassetid://10723407192",
				["lucide-history"] = "rbxassetid://10723407335",
				["lucide-home"] = "rbxassetid://10723407389",
				["lucide-hourglass"] = "rbxassetid://10723407498",
				["lucide-ice-cream"] = "rbxassetid://10723414308",
				["lucide-image"] = "rbxassetid://10723415040",
				["lucide-image-minus"] = "rbxassetid://10723414487",
				["lucide-image-off"] = "rbxassetid://10723414677",
				["lucide-image-plus"] = "rbxassetid://10723414827",
				["lucide-import"] = "rbxassetid://10723415205",
				["lucide-inbox"] = "rbxassetid://10723415335",
				["lucide-indent"] = "rbxassetid://10723415494",
				["lucide-indian-rupee"] = "rbxassetid://10723415642",
				["lucide-infinity"] = "rbxassetid://10723415766",
				["lucide-info"] = "rbxassetid://10723415903",
				["lucide-inspect"] = "rbxassetid://10723416057",
				["lucide-italic"] = "rbxassetid://10723416195",
				["lucide-japanese-yen"] = "rbxassetid://10723416363",
				["lucide-joystick"] = "rbxassetid://10723416527",
				["lucide-key"] = "rbxassetid://10723416652",
				["lucide-keyboard"] = "rbxassetid://10723416765",
				["lucide-lamp"] = "rbxassetid://10723417513",
				["lucide-lamp-ceiling"] = "rbxassetid://10723416922",
				["lucide-lamp-desk"] = "rbxassetid://10723417016",
				["lucide-lamp-floor"] = "rbxassetid://10723417131",
				["lucide-lamp-wall-down"] = "rbxassetid://10723417240",
				["lucide-lamp-wall-up"] = "rbxassetid://10723417356",
				["lucide-landmark"] = "rbxassetid://10723417608",
				["lucide-languages"] = "rbxassetid://10723417703",
				["lucide-laptop"] = "rbxassetid://10723423881",
				["lucide-laptop-2"] = "rbxassetid://10723417797",
				["lucide-lasso"] = "rbxassetid://10723424235",
				["lucide-lasso-select"] = "rbxassetid://10723424058",
				["lucide-laugh"] = "rbxassetid://10723424372",
				["lucide-layers"] = "rbxassetid://10723424505",
				["lucide-layout"] = "rbxassetid://10723425376",
				["lucide-layout-dashboard"] = "rbxassetid://10723424646",
				["lucide-layout-grid"] = "rbxassetid://10723424838",
				["lucide-layout-list"] = "rbxassetid://10723424963",
				["lucide-layout-template"] = "rbxassetid://10723425187",
				["lucide-leaf"] = "rbxassetid://10723425539",
				["lucide-library"] = "rbxassetid://10723425615",
				["lucide-life-buoy"] = "rbxassetid://10723425685",
				["lucide-lightbulb"] = "rbxassetid://10723425852",
				["lucide-lightbulb-off"] = "rbxassetid://10723425762",
				["lucide-line-chart"] = "rbxassetid://10723426393",
				["lucide-link"] = "rbxassetid://10723426722",
				["lucide-link-2"] = "rbxassetid://10723426595",
				["lucide-link-2-off"] = "rbxassetid://10723426513",
				["lucide-list"] = "rbxassetid://10723433811",
				["lucide-list-checks"] = "rbxassetid://10734884548",
				["lucide-list-end"] = "rbxassetid://10723426886",
				["lucide-list-minus"] = "rbxassetid://10723426986",
				["lucide-list-music"] = "rbxassetid://10723427081",
				["lucide-list-ordered"] = "rbxassetid://10723427199",
				["lucide-list-plus"] = "rbxassetid://10723427334",
				["lucide-list-start"] = "rbxassetid://10723427494",
				["lucide-list-video"] = "rbxassetid://10723427619",
				["lucide-list-x"] = "rbxassetid://10723433655",
				["lucide-loader"] = "rbxassetid://10723434070",
				["lucide-loader-2"] = "rbxassetid://10723433935",
				["lucide-locate"] = "rbxassetid://10723434557",
				["lucide-locate-fixed"] = "rbxassetid://10723434236",
				["lucide-locate-off"] = "rbxassetid://10723434379",
				["lucide-lock"] = "rbxassetid://10723434711",
				["lucide-log-in"] = "rbxassetid://10723434830",
				["lucide-log-out"] = "rbxassetid://10723434906",
				["lucide-luggage"] = "rbxassetid://10723434993",
				["lucide-magnet"] = "rbxassetid://10723435069",
				["lucide-mail"] = "rbxassetid://10734885430",
				["lucide-mail-check"] = "rbxassetid://10723435182",
				["lucide-mail-minus"] = "rbxassetid://10723435261",
				["lucide-mail-open"] = "rbxassetid://10723435342",
				["lucide-mail-plus"] = "rbxassetid://10723435443",
				["lucide-mail-question"] = "rbxassetid://10723435515",
				["lucide-mail-search"] = "rbxassetid://10734884739",
				["lucide-mail-warning"] = "rbxassetid://10734885015",
				["lucide-mail-x"] = "rbxassetid://10734885247",
				["lucide-mails"] = "rbxassetid://10734885614",
				["lucide-map"] = "rbxassetid://10734886202",
				["lucide-map-pin"] = "rbxassetid://10734886004",
				["lucide-map-pin-off"] = "rbxassetid://10734885803",
				["lucide-maximize"] = "rbxassetid://10734886735",
				["lucide-maximize-2"] = "rbxassetid://10734886496",
				["lucide-medal"] = "rbxassetid://10734887072",
				["lucide-megaphone"] = "rbxassetid://10734887454",
				["lucide-megaphone-off"] = "rbxassetid://10734887311",
				["lucide-meh"] = "rbxassetid://10734887603",
				["lucide-menu"] = "rbxassetid://10734887784",
				["lucide-message-circle"] = "rbxassetid://10734888000",
				["lucide-message-square"] = "rbxassetid://10734888228",
				["lucide-mic"] = "rbxassetid://10734888864",
				["lucide-mic-2"] = "rbxassetid://10734888430",
				["lucide-mic-off"] = "rbxassetid://10734888646",
				["lucide-microscope"] = "rbxassetid://10734889106",
				["lucide-microwave"] = "rbxassetid://10734895076",
				["lucide-milestone"] = "rbxassetid://10734895310",
				["lucide-minimize"] = "rbxassetid://10734895698",
				["lucide-minimize-2"] = "rbxassetid://10734895530",
				["lucide-minus"] = "rbxassetid://10734896206",
				["lucide-minus-circle"] = "rbxassetid://10734895856",
				["lucide-minus-square"] = "rbxassetid://10734896029",
				["lucide-monitor"] = "rbxassetid://10734896881",
				["lucide-monitor-off"] = "rbxassetid://10734896360",
				["lucide-monitor-speaker"] = "rbxassetid://10734896512",
				["lucide-moon"] = "rbxassetid://10734897102",
				["lucide-more-horizontal"] = "rbxassetid://10734897250",
				["lucide-more-vertical"] = "rbxassetid://10734897387",
				["lucide-mountain"] = "rbxassetid://10734897956",
				["lucide-mountain-snow"] = "rbxassetid://10734897665",
				["lucide-mouse"] = "rbxassetid://10734898592",
				["lucide-mouse-pointer"] = "rbxassetid://10734898476",
				["lucide-mouse-pointer-2"] = "rbxassetid://10734898194",
				["lucide-mouse-pointer-click"] = "rbxassetid://10734898355",
				["lucide-move"] = "rbxassetid://10734900011",
				["lucide-move-3d"] = "rbxassetid://10734898756",
				["lucide-move-diagonal"] = "rbxassetid://10734899164",
				["lucide-move-diagonal-2"] = "rbxassetid://10734898934",
				["lucide-move-horizontal"] = "rbxassetid://10734899414",
				["lucide-move-vertical"] = "rbxassetid://10734899821",
				["lucide-music"] = "rbxassetid://10734905958",
				["lucide-music-2"] = "rbxassetid://10734900215",
				["lucide-music-3"] = "rbxassetid://10734905665",
				["lucide-music-4"] = "rbxassetid://10734905823",
				["lucide-navigation"] = "rbxassetid://10734906744",
				["lucide-navigation-2"] = "rbxassetid://10734906332",
				["lucide-navigation-2-off"] = "rbxassetid://10734906144",
				["lucide-navigation-off"] = "rbxassetid://10734906580",
				["lucide-network"] = "rbxassetid://10734906975",
				["lucide-newspaper"] = "rbxassetid://10734907168",
				["lucide-octagon"] = "rbxassetid://10734907361",
				["lucide-option"] = "rbxassetid://10734907649",
				["lucide-outdent"] = "rbxassetid://10734907933",
				["lucide-package"] = "rbxassetid://10734909540",
				["lucide-package-2"] = "rbxassetid://10734908151",
				["lucide-package-check"] = "rbxassetid://10734908384",
				["lucide-package-minus"] = "rbxassetid://10734908626",
				["lucide-package-open"] = "rbxassetid://10734908793",
				["lucide-package-plus"] = "rbxassetid://10734909016",
				["lucide-package-search"] = "rbxassetid://10734909196",
				["lucide-package-x"] = "rbxassetid://10734909375",
				["lucide-paint-bucket"] = "rbxassetid://10734909847",
				["lucide-paintbrush"] = "rbxassetid://10734910187",
				["lucide-paintbrush-2"] = "rbxassetid://10734910030",
				["lucide-palette"] = "rbxassetid://10734910430",
				["lucide-palmtree"] = "rbxassetid://10734910680",
				["lucide-paperclip"] = "rbxassetid://10734910927",
				["lucide-party-popper"] = "rbxassetid://10734918735",
				["lucide-pause"] = "rbxassetid://10734919336",
				["lucide-pause-circle"] = "rbxassetid://10735024209",
				["lucide-pause-octagon"] = "rbxassetid://10734919143",
				["lucide-pen-tool"] = "rbxassetid://10734919503",
				["lucide-pencil"] = "rbxassetid://10734919691",
				["lucide-percent"] = "rbxassetid://10734919919",
				["lucide-person-standing"] = "rbxassetid://10734920149",
				["lucide-phone"] = "rbxassetid://10734921524",
				["lucide-phone-call"] = "rbxassetid://10734920305",
				["lucide-phone-forwarded"] = "rbxassetid://10734920508",
				["lucide-phone-incoming"] = "rbxassetid://10734920694",
				["lucide-phone-missed"] = "rbxassetid://10734920845",
				["lucide-phone-off"] = "rbxassetid://10734921077",
				["lucide-phone-outgoing"] = "rbxassetid://10734921288",
				["lucide-pie-chart"] = "rbxassetid://10734921727",
				["lucide-piggy-bank"] = "rbxassetid://10734921935",
				["lucide-pin"] = "rbxassetid://10734922324",
				["lucide-pin-off"] = "rbxassetid://10734922180",
				["lucide-pipette"] = "rbxassetid://10734922497",
				["lucide-pizza"] = "rbxassetid://10734922774",
				["lucide-plane"] = "rbxassetid://10734922971",
				["lucide-play"] = "rbxassetid://10734923549",
				["lucide-play-circle"] = "rbxassetid://10734923214",
				["lucide-plus"] = "rbxassetid://10734924532",
				["lucide-plus-circle"] = "rbxassetid://10734923868",
				["lucide-plus-square"] = "rbxassetid://10734924219",
				["lucide-podcast"] = "rbxassetid://10734929553",
				["lucide-pointer"] = "rbxassetid://10734929723",
				["lucide-pound-sterling"] = "rbxassetid://10734929981",
				["lucide-power"] = "rbxassetid://10734930466",
				["lucide-power-off"] = "rbxassetid://10734930257",
				["lucide-printer"] = "rbxassetid://10734930632",
				["lucide-puzzle"] = "rbxassetid://10734930886",
				["lucide-quote"] = "rbxassetid://10734931234",
				["lucide-radio"] = "rbxassetid://10734931596",
				["lucide-radio-receiver"] = "rbxassetid://10734931402",
				["lucide-rectangle-horizontal"] = "rbxassetid://10734931777",
				["lucide-rectangle-vertical"] = "rbxassetid://10734932081",
				["lucide-recycle"] = "rbxassetid://10734932295",
				["lucide-redo"] = "rbxassetid://10734932822",
				["lucide-redo-2"] = "rbxassetid://10734932586",
				["lucide-refresh-ccw"] = "rbxassetid://10734933056",
				["lucide-refresh-cw"] = "rbxassetid://10734933222",
				["lucide-refrigerator"] = "rbxassetid://10734933465",
				["lucide-regex"] = "rbxassetid://10734933655",
				["lucide-repeat"] = "rbxassetid://10734933966",
				["lucide-repeat-1"] = "rbxassetid://10734933826",
				["lucide-reply"] = "rbxassetid://10734934252",
				["lucide-reply-all"] = "rbxassetid://10734934132",
				["lucide-rewind"] = "rbxassetid://10734934347",
				["lucide-rocket"] = "rbxassetid://10734934585",
				["lucide-rocking-chair"] = "rbxassetid://10734939942",
				["lucide-rotate-3d"] = "rbxassetid://10734940107",
				["lucide-rotate-ccw"] = "rbxassetid://10734940376",
				["lucide-rotate-cw"] = "rbxassetid://10734940654",
				["lucide-rss"] = "rbxassetid://10734940825",
				["lucide-ruler"] = "rbxassetid://10734941018",
				["lucide-russian-ruble"] = "rbxassetid://10734941199",
				["lucide-sailboat"] = "rbxassetid://10734941354",
				["lucide-save"] = "rbxassetid://10734941499",
				["lucide-scale"] = "rbxassetid://10734941912",
				["lucide-scale-3d"] = "rbxassetid://10734941739",
				["lucide-scaling"] = "rbxassetid://10734942072",
				["lucide-scan"] = "rbxassetid://10734942565",
				["lucide-scan-face"] = "rbxassetid://10734942198",
				["lucide-scan-line"] = "rbxassetid://10734942351",
				["lucide-scissors"] = "rbxassetid://10734942778",
				["lucide-screen-share"] = "rbxassetid://10734943193",
				["lucide-screen-share-off"] = "rbxassetid://10734942967",
				["lucide-scroll"] = "rbxassetid://10734943448",
				["lucide-search"] = "rbxassetid://10734943674",
				["lucide-send"] = "rbxassetid://10734943902",
				["lucide-separator-horizontal"] = "rbxassetid://10734944115",
				["lucide-separator-vertical"] = "rbxassetid://10734944326",
				["lucide-server"] = "rbxassetid://10734949856",
				["lucide-server-cog"] = "rbxassetid://10734944444",
				["lucide-server-crash"] = "rbxassetid://10734944554",
				["lucide-server-off"] = "rbxassetid://10734944668",
				["lucide-settings"] = "rbxassetid://10734950309",
				["lucide-settings-2"] = "rbxassetid://10734950020",
				["lucide-share"] = "rbxassetid://10734950813",
				["lucide-share-2"] = "rbxassetid://10734950553",
				["lucide-sheet"] = "rbxassetid://10734951038",
				["lucide-shield"] = "rbxassetid://10734951847",
				["lucide-shield-alert"] = "rbxassetid://10734951173",
				["lucide-shield-check"] = "rbxassetid://10734951367",
				["lucide-shield-close"] = "rbxassetid://10734951535",
				["lucide-shield-off"] = "rbxassetid://10734951684",
				["lucide-shirt"] = "rbxassetid://10734952036",
				["lucide-shopping-bag"] = "rbxassetid://10734952273",
				["lucide-shopping-cart"] = "rbxassetid://10734952479",
				["lucide-shovel"] = "rbxassetid://10734952773",
				["lucide-shower-head"] = "rbxassetid://10734952942",
				["lucide-shrink"] = "rbxassetid://10734953073",
				["lucide-shrub"] = "rbxassetid://10734953241",
				["lucide-shuffle"] = "rbxassetid://10734953451",
				["lucide-sidebar"] = "rbxassetid://10734954301",
				["lucide-sidebar-close"] = "rbxassetid://10734953715",
				["lucide-sidebar-open"] = "rbxassetid://10734954000",
				["lucide-sigma"] = "rbxassetid://10734954538",
				["lucide-signal"] = "rbxassetid://10734961133",
				["lucide-signal-high"] = "rbxassetid://10734954807",
				["lucide-signal-low"] = "rbxassetid://10734955080",
				["lucide-signal-medium"] = "rbxassetid://10734955336",
				["lucide-signal-zero"] = "rbxassetid://10734960878",
				["lucide-siren"] = "rbxassetid://10734961284",
				["lucide-skip-back"] = "rbxassetid://10734961526",
				["lucide-skip-forward"] = "rbxassetid://10734961809",
				["lucide-skull"] = "rbxassetid://10734962068",
				["lucide-slack"] = "rbxassetid://10734962339",
				["lucide-slash"] = "rbxassetid://10734962600",
				["lucide-slice"] = "rbxassetid://10734963024",
				["lucide-sliders"] = "rbxassetid://10734963400",
				["lucide-sliders-horizontal"] = "rbxassetid://10734963191",
				["lucide-smartphone"] = "rbxassetid://10734963940",
				["lucide-smartphone-charging"] = "rbxassetid://10734963671",
				["lucide-smile"] = "rbxassetid://10734964441",
				["lucide-smile-plus"] = "rbxassetid://10734964188",
				["lucide-snowflake"] = "rbxassetid://10734964600",
				["lucide-sofa"] = "rbxassetid://10734964852",
				["lucide-sort-asc"] = "rbxassetid://10734965115",
				["lucide-sort-desc"] = "rbxassetid://10734965287",
				["lucide-speaker"] = "rbxassetid://10734965419",
				["lucide-sprout"] = "rbxassetid://10734965572",
				["lucide-square"] = "rbxassetid://10734965702",
				["lucide-star"] = "rbxassetid://10734966248",
				["lucide-star-half"] = "rbxassetid://10734965897",
				["lucide-star-off"] = "rbxassetid://10734966097",
				["lucide-stethoscope"] = "rbxassetid://10734966384",
				["lucide-sticker"] = "rbxassetid://10734972234",
				["lucide-sticky-note"] = "rbxassetid://10734972463",
				["lucide-stop-circle"] = "rbxassetid://10734972621",
				["lucide-stretch-horizontal"] = "rbxassetid://10734972862",
				["lucide-stretch-vertical"] = "rbxassetid://10734973130",
				["lucide-strikethrough"] = "rbxassetid://10734973290",
				["lucide-subscript"] = "rbxassetid://10734973457",
				["lucide-sun"] = "rbxassetid://10734974297",
				["lucide-sun-dim"] = "rbxassetid://10734973645",
				["lucide-sun-medium"] = "rbxassetid://10734973778",
				["lucide-sun-moon"] = "rbxassetid://10734973999",
				["lucide-sun-snow"] = "rbxassetid://10734974130",
				["lucide-sunrise"] = "rbxassetid://10734974522",
				["lucide-sunset"] = "rbxassetid://10734974689",
				["lucide-superscript"] = "rbxassetid://10734974850",
				["lucide-swiss-franc"] = "rbxassetid://10734975024",
				["lucide-switch-camera"] = "rbxassetid://10734975214",
				["lucide-sword"] = "rbxassetid://10734975486",
				["lucide-swords"] = "rbxassetid://10734975692",
				["lucide-syringe"] = "rbxassetid://10734975932",
				["lucide-table"] = "rbxassetid://10734976230",
				["lucide-table-2"] = "rbxassetid://10734976097",
				["lucide-tablet"] = "rbxassetid://10734976394",
				["lucide-tag"] = "rbxassetid://10734976528",
				["lucide-tags"] = "rbxassetid://10734976739",
				["lucide-target"] = "rbxassetid://10734977012",
				["lucide-tent"] = "rbxassetid://10734981750",
				["lucide-terminal"] = "rbxassetid://10734982144",
				["lucide-terminal-square"] = "rbxassetid://10734981995",
				["lucide-text-cursor"] = "rbxassetid://10734982395",
				["lucide-text-cursor-input"] = "rbxassetid://10734982297",
				["lucide-thermometer"] = "rbxassetid://10734983134",
				["lucide-thermometer-snowflake"] = "rbxassetid://10734982571",
				["lucide-thermometer-sun"] = "rbxassetid://10734982771",
				["lucide-thumbs-down"] = "rbxassetid://10734983359",
				["lucide-thumbs-up"] = "rbxassetid://10734983629",
				["lucide-ticket"] = "rbxassetid://10734983868",
				["lucide-timer"] = "rbxassetid://10734984606",
				["lucide-timer-off"] = "rbxassetid://10734984138",
				["lucide-timer-reset"] = "rbxassetid://10734984355",
				["lucide-toggle-left"] = "rbxassetid://10734984834",
				["lucide-toggle-right"] = "rbxassetid://10734985040",
				["lucide-tornado"] = "rbxassetid://10734985247",
				["lucide-toy-brick"] = "rbxassetid://10747361919",
				["lucide-train"] = "rbxassetid://10747362105",
				["lucide-trash"] = "rbxassetid://10747362393",
				["lucide-trash-2"] = "rbxassetid://10747362241",
				["lucide-tree-deciduous"] = "rbxassetid://10747362534",
				["lucide-tree-pine"] = "rbxassetid://10747362748",
				["lucide-trees"] = "rbxassetid://10747363016",
				["lucide-trending-down"] = "rbxassetid://10747363205",
				["lucide-trending-up"] = "rbxassetid://10747363465",
				["lucide-triangle"] = "rbxassetid://10747363621",
				["lucide-trophy"] = "rbxassetid://10747363809",
				["lucide-truck"] = "rbxassetid://10747364031",
				["lucide-tv"] = "rbxassetid://10747364593",
				["lucide-tv-2"] = "rbxassetid://10747364302",
				["lucide-type"] = "rbxassetid://10747364761",
				["lucide-umbrella"] = "rbxassetid://10747364971",
				["lucide-underline"] = "rbxassetid://10747365191",
				["lucide-undo"] = "rbxassetid://10747365484",
				["lucide-undo-2"] = "rbxassetid://10747365359",
				["lucide-unlink"] = "rbxassetid://10747365771",
				["lucide-unlink-2"] = "rbxassetid://10747397871",
				["lucide-unlock"] = "rbxassetid://10747366027",
				["lucide-upload"] = "rbxassetid://10747366434",
				["lucide-upload-cloud"] = "rbxassetid://10747366266",
				["lucide-usb"] = "rbxassetid://10747366606",
				["lucide-user"] = "rbxassetid://10747373176",
				["lucide-user-check"] = "rbxassetid://10747371901",
				["lucide-user-cog"] = "rbxassetid://10747372167",
				["lucide-user-minus"] = "rbxassetid://10747372346",
				["lucide-user-plus"] = "rbxassetid://10747372702",
				["lucide-user-x"] = "rbxassetid://10747372992",
				["lucide-users"] = "rbxassetid://10747373426",
				["lucide-utensils"] = "rbxassetid://10747373821",
				["lucide-utensils-crossed"] = "rbxassetid://10747373629",
				["lucide-venetian-mask"] = "rbxassetid://10747374003",
				["lucide-verified"] = "rbxassetid://10747374131",
				["lucide-vibrate"] = "rbxassetid://10747374489",
				["lucide-vibrate-off"] = "rbxassetid://10747374269",
				["lucide-video"] = "rbxassetid://10747374938",
				["lucide-video-off"] = "rbxassetid://10747374721",
				["lucide-view"] = "rbxassetid://10747375132",
				["lucide-voicemail"] = "rbxassetid://10747375281",
				["lucide-volume"] = "rbxassetid://10747376008",
				["lucide-volume-1"] = "rbxassetid://10747375450",
				["lucide-volume-2"] = "rbxassetid://10747375679",
				["lucide-volume-x"] = "rbxassetid://10747375880",
				["lucide-wallet"] = "rbxassetid://10747376205",
				["lucide-wand"] = "rbxassetid://10747376565",
				["lucide-wand-2"] = "rbxassetid://10747376349",
				["lucide-watch"] = "rbxassetid://10747376722",
				["lucide-waves"] = "rbxassetid://10747376931",
				["lucide-webcam"] = "rbxassetid://10747381992",
				["lucide-wifi"] = "rbxassetid://10747382504",
				["lucide-wifi-off"] = "rbxassetid://10747382268",
				["lucide-wind"] = "rbxassetid://10747382750",
				["lucide-wrap-text"] = "rbxassetid://10747383065",
				["lucide-wrench"] = "rbxassetid://10747383470",
				["lucide-x"] = "rbxassetid://10747384394",
				["lucide-x-circle"] = "rbxassetid://10747383819",
				["lucide-x-octagon"] = "rbxassetid://10747384037",
				["lucide-x-square"] = "rbxassetid://10747384217",
				["lucide-zoom-in"] = "rbxassetid://10747384552",
				["lucide-zoom-out"] = "rbxassetid://10747384679",
			},
		}
	end,
	-- Module: MainModule/Packages/Flipper
	[30] = function()
		local __context, script, require = getModuleContext(30)
		-- Reconstructed module: MainModule/Packages/Flipper
		-- Author: dawid | License: MIT (original Fluent header).
		local object_44 = {
			SingleMotor = require(script.SingleMotor),
			GroupMotor = require(script.GroupMotor),
			Instant = require(script.Instant),
			Linear = require(script.Linear),
			Spring = require(script.Spring),
			isMotor = require(script.isMotor),
		}
		return object_44
	end,
	-- Module: MainModule/Packages/Flipper/BaseMotor
	[31] = function()
		local __context, script, require = getModuleContext(31)
		-- Reconstructed module: MainModule/Packages/Flipper/BaseMotor
		-- Author: dawid | License: MIT (original Fluent header).
		local RunService_3, Signal, callback_39, object_45 =
			game:GetService("RunService"), require(script.Parent.Signal), function() end, {}
		object_45.__index = object_45
		function object_45.new()
			return setmetatable({
				_onStep = Signal.new(),
				_onStart = Signal.new(),
				_onComplete = Signal.new(),
			}, object_45)
		end
		function object_45.onStep(self_78, argument_132)
			return self_78._onStep:connect(argument_132)
		end
		function object_45.onStart(self_79, argument_133)
			return self_79._onStart:connect(argument_133)
		end
		function object_45.onComplete(self_80, argument_134)
			return self_80._onComplete:connect(argument_134)
		end
		function object_45.start(self_81)
			if not self_81._connection then
				self_81._connection = RunService_3.RenderStepped:Connect(function(argument_135)
					self_81:step(argument_135)
				end)
			end
		end
		function object_45.stop(self_82)
			if self_82._connection then
				self_82._connection:Disconnect()
				self_82._connection = nil
			end
		end
		object_45.destroy = object_45.stop
		object_45.step = callback_39
		object_45.getValue = callback_39
		object_45.setGoal = callback_39
		function object_45.__tostring(self_83)
			return "Motor"
		end
		return object_45
	end,
	-- Module: MainModule/Packages/Flipper/BaseMotor.spec
	[32] = function()
		local __context, script, require = getModuleContext(32)
		-- Reconstructed module: MainModule/Packages/Flipper/BaseMotor.spec
		-- Author: dawid | License: MIT (original Fluent header).
		return function()
			local RunService_4, BaseMotor = game:GetService("RunService"), require(script.Parent.BaseMotor)
			describe("connection management", function()
				local BaseMotor_2 = BaseMotor.new()
				it("should hook up connections on :start()", function()
					BaseMotor_2:start()
					expect(typeof(BaseMotor_2._connection)).to.equal("RBXScriptConnection")
				end)
				it("should remove connections on :stop() or :destroy()", function()
					BaseMotor_2:stop()
					expect(BaseMotor_2._connection).to.equal(nil)
				end)
			end)
			it("should call :step() with deltaTime", function()
				local BaseMotor_3, result_15 = (BaseMotor.new())
				function BaseMotor_3.step(self_84, ...)
					result_15 = {
						...,
					}
					BaseMotor_3:stop()
				end
				BaseMotor_3:start()
				local wait_2 = RunService_4.RenderStepped:Wait()
				RunService_4.RenderStepped:Wait()
				expect(result_15).to.be.ok()
				expect(result_15[1]).to.equal(wait_2)
			end)
		end
	end,
	-- Module: MainModule/Packages/Flipper/GroupMotor
	[33] = function()
		local __context, script, require = getModuleContext(33)
		-- Reconstructed module: MainModule/Packages/Flipper/GroupMotor
		-- Author: dawid | License: MIT (original Fluent header).
		local BaseMotor_4, SingleMotor_3, isMotor =
			require(script.Parent.BaseMotor), require(script.Parent.SingleMotor), require(script.Parent.isMotor)
		local object_46 = setmetatable({}, BaseMotor_4)
		object_46.__index = object_46
		local callback_40 = function(argument_136)
			if isMotor(argument_136) then
				return argument_136
			end
			local typeof_2 = typeof(argument_136)
			if typeof_2 == "number" then
				return SingleMotor_3.new(argument_136, false)
			elseif typeof_2 == "table" then
				return object_46.new(argument_136, false)
			end
			error(("Unable to convert %q to motor; type %s is unsupported"):format(argument_136, typeof_2), 2)
		end
		function object_46.new(argument_137, argument_138)
			assert(argument_137, "Missing argument #1: initialValues")
			assert(typeof(argument_137) == "table", "initialValues must be a table!")
			assert(
				not argument_137.step,
				[[initialValues contains disallowed property "step". Did you mean to put a table of values here?]]
			)
			local object_47 = setmetatable(BaseMotor_4.new(), object_46)
			if argument_138 ~= nil then
				object_47._useImplicitConnections = argument_138
			else
				object_47._useImplicitConnections = true
			end
			object_47._complete = true
			object_47._motors = {}
			for key_26, item_26 in pairs(argument_137) do
				object_47._motors[key_26] = callback_40(item_26)
			end
			return object_47
		end
		function object_46.step(self_85, deltaTime)
			if self_85._complete then
				return true
			end
			local enabled_8 = true
			for key_27, item_27 in pairs(self_85._motors) do
				local step = item_27:step(deltaTime)
				if not step then
					enabled_8 = false
				end
			end
			self_85._onStep:fire(self_85:getValue())
			if enabled_8 then
				if self_85._useImplicitConnections then
					self_85:stop()
				end
				self_85._complete = true
				self_85._onComplete:fire()
			end
			return enabled_8
		end
		function object_46.setGoal(self_86, goal)
			assert(
				not goal.step,
				[[goals contains disallowed property "step". Did you mean to put a table of goals here?]]
			)
			self_86._complete = false
			self_86._onStart:fire()
			for key_28, item_28 in pairs(goal) do
				local assert_2 = assert(self_86._motors[key_28], ("Unknown motor for key %s"):format(key_28))
				assert_2:setGoal(item_28)
			end
			if self_86._useImplicitConnections then
				self_86:start()
			end
		end
		function object_46.getValue(self_87)
			local object_48 = {}
			for key_29, item_29 in pairs(self_87._motors) do
				object_48[key_29] = item_29:getValue()
			end
			return object_48
		end
		function object_46.__tostring(self_88)
			return "Motor(Group)"
		end
		return object_46
	end,
	-- Module: MainModule/Packages/Flipper/GroupMotor.spec
	[34] = function()
		local __context, script, require = getModuleContext(34)
		-- Reconstructed module: MainModule/Packages/Flipper/GroupMotor.spec
		-- Author: dawid | License: MIT (original Fluent header).
		return function()
			local GroupMotor_4, Instant, Spring =
				require(script.Parent.GroupMotor), require(script.Parent.Instant), require(script.Parent.Spring)
			it("should complete when all child motors are complete", function()
				local GroupMotor_5 = GroupMotor_4.new({
					A = 1,
					B = 2,
				}, false)
				expect(GroupMotor_5._complete).to.equal(true)
				GroupMotor_5:setGoal({
					A = Instant.new(3),
					B = Spring.new(4, {
						frequency = 7.5,
						dampingRatio = 1,
					}),
				})
				expect(GroupMotor_5._complete).to.equal(false)
				GroupMotor_5:step(0.016666666666666666)
				expect(GroupMotor_5._complete).to.equal(false)
				for index_4 = 1, 30 do
					GroupMotor_5:step(0.016666666666666666)
				end
				expect(GroupMotor_5._complete).to.equal(true)
			end)
			it("should start when the goal is set", function()
				local GroupMotor_6, enabled_9 = GroupMotor_4.new({
					A = 0,
				}, false), false
				GroupMotor_6:onStart(function()
					enabled_9 = not enabled_9
				end)
				GroupMotor_6:setGoal({
					A = Instant.new(1),
				})
				expect(enabled_9).to.equal(true)
				GroupMotor_6:setGoal({
					A = Instant.new(1),
				})
				expect(enabled_9).to.equal(false)
			end)
			it("should properly return all values", function()
				local GroupMotor_7 = GroupMotor_4.new({
					A = 1,
					B = 2,
				}, false)
				local getValue = GroupMotor_7:getValue()
				expect(getValue.A).to.equal(1)
				expect(getValue.B).to.equal(2)
			end)
			it("should error when a goal is given to GroupMotor.new", function()
				local success_6 = pcall(function()
					GroupMotor_4.new(Instant.new(0))
				end)
				expect(success_6).to.equal(false)
			end)
			it([[should error when a single goal is provided to GroupMotor:step]], function()
				local success_7 = pcall(function()
					GroupMotor_4.new({
						a = 1,
					}):setGoal(Instant.new(0))
				end)
				expect(success_7).to.equal(false)
			end)
		end
	end,
	-- Module: MainModule/Packages/Flipper/Instant
	[35] = function()
		local __context, script, require = getModuleContext(35)
		-- Reconstructed module: MainModule/Packages/Flipper/Instant
		-- Author: dawid | License: MIT (original Fluent header).
		local object_49 = {}
		object_49.__index = object_49
		function object_49.new(argument_139)
			return setmetatable({
				_targetValue = argument_139,
			}, object_49)
		end
		function object_49.step(self_89)
			return {
				complete = true,
				value = self_89._targetValue,
			}
		end
		return object_49
	end,
	-- Module: MainModule/Packages/Flipper/Instant.spec
	[36] = function()
		local __context, script, require = getModuleContext(36)
		-- Reconstructed module: MainModule/Packages/Flipper/Instant.spec
		-- Author: dawid | License: MIT (original Fluent header).
		return function()
			local Instant_2 = require(script.Parent.Instant)
			it("should return a completed state with the provided value", function()
				local Instant_3 = Instant_2.new(1.23)
				local step_2 = Instant_3:step(0.1, {
					value = 0,
					complete = false,
				})
				expect(step_2.complete).to.equal(true)
				expect(step_2.value).to.equal(1.23)
			end)
		end
	end,
	-- Module: MainModule/Packages/Flipper/Linear
	[37] = function()
		local __context, script, require = getModuleContext(37)
		-- Reconstructed module: MainModule/Packages/Flipper/Linear
		-- Author: dawid | License: MIT (original Fluent header).
		local object_50 = {}
		object_50.__index = object_50
		function object_50.new(argument_140, argument_141)
			assert(argument_140, "Missing argument #1: targetValue")
			argument_141 = argument_141 or {}
			return setmetatable({
				_targetValue = argument_140,
				_velocity = argument_141.velocity or 1,
			}, object_50)
		end
		function object_50.step(self_90, deltaTime_2, argument_142)
			local value_57, _velocity, _targetValue = deltaTime_2.value, self_90._velocity, self_90._targetValue
			local value_58 = argument_142 * _velocity
			local value_59 = value_58 >= math.abs(_targetValue - value_57)
			value_57 = value_57 + value_58 * (_targetValue > value_57 and 1 or -1)
			if value_59 then
				value_57 = self_90._targetValue
				_velocity = 0
			end
			return {
				complete = value_59,
				value = value_57,
				velocity = _velocity,
			}
		end
		return object_50
	end,
	-- Module: MainModule/Packages/Flipper/Linear.spec
	[38] = function()
		local __context, script, require = getModuleContext(38)
		-- Reconstructed module: MainModule/Packages/Flipper/Linear.spec
		-- Author: dawid | License: MIT (original Fluent header).
		return function()
			local SingleMotor_4, Linear = require(script.Parent.SingleMotor), require(script.Parent.Linear)
			describe("completed state", function()
				local SingleMotor_5, Linear_2 = SingleMotor_4.new(0, false), Linear.new(1, {
					velocity = 1,
				})
				SingleMotor_5:setGoal(Linear_2)
				for index_5 = 1, 60 do
					SingleMotor_5:step(0.016666666666666666)
				end
				it("should complete", function()
					expect(SingleMotor_5._state.complete).to.equal(true)
				end)
				it("should be exactly the goal value when completed", function()
					expect(SingleMotor_5._state.value).to.equal(1)
				end)
			end)
			describe("uncompleted state", function()
				local SingleMotor_6, Linear_3 = SingleMotor_4.new(0, false), Linear.new(1, {
					velocity = 1,
				})
				SingleMotor_6:setGoal(Linear_3)
				for index_6 = 1, 59 do
					SingleMotor_6:step(0.016666666666666666)
				end
				it("should be uncomplete", function()
					expect(SingleMotor_6._state.complete).to.equal(false)
				end)
			end)
			describe("negative velocity", function()
				local SingleMotor_7, Linear_4 = SingleMotor_4.new(1, false), Linear.new(0, {
					velocity = 1,
				})
				SingleMotor_7:setGoal(Linear_4)
				for index_7 = 1, 60 do
					SingleMotor_7:step(0.016666666666666666)
				end
				it("should complete", function()
					expect(SingleMotor_7._state.complete).to.equal(true)
				end)
				it("should be exactly the goal value when completed", function()
					expect(SingleMotor_7._state.value).to.equal(0)
				end)
			end)
		end
	end,
	-- Module: MainModule/Packages/Flipper/Signal
	[39] = function()
		local __context, script, require = getModuleContext(39)
		-- Reconstructed module: MainModule/Packages/Flipper/Signal
		-- Author: dawid | License: MIT (original Fluent header).
		local object_51 = {}
		object_51.__index = object_51
		function object_51.new(argument_143, argument_144)
			return setmetatable({
				signal = argument_143,
				connected = true,
				_handler = argument_144,
			}, object_51)
		end
		function object_51.disconnect(self_91)
			if self_91.connected then
				self_91.connected = false
				for key_30, item_30 in pairs(self_91.signal._connections) do
					if item_30 == self_91 then
						table.remove(self_91.signal._connections, key_30)
						return
					end
				end
			end
		end
		local object_52 = {}
		object_52.__index = object_52
		function object_52.new()
			return setmetatable({
				_connections = {},
				_threads = {},
			}, object_52)
		end
		function object_52.fire(self_92, ...)
			for key_31, item_31 in pairs(self_92._connections) do
				item_31._handler(...)
			end
			for key_32, item_32 in pairs(self_92._threads) do
				coroutine.resume(item_32, ...)
			end
			self_92._threads = {}
		end
		function object_52.connect(self_93, argument_145)
			local object_53 = object_51.new(self_93, argument_145)
			table.insert(self_93._connections, object_53)
			return object_53
		end
		function object_52.wait(self_94)
			table.insert(self_94._threads, coroutine.running())
			return coroutine.yield()
		end
		return object_52
	end,
	-- Module: MainModule/Packages/Flipper/Signal.spec
	[40] = function()
		local __context, script, require = getModuleContext(40)
		-- Reconstructed module: MainModule/Packages/Flipper/Signal.spec
		-- Author: dawid | License: MIT (original Fluent header).
		return function()
			local Signal_2 = require(script.Parent.Signal)
			it("should invoke all connections, instantly", function()
				local Signal_3, result_16, extraResult_2 = (Signal_2.new())
				Signal_3:connect(function(argument_146)
					result_16 = argument_146
				end)
				Signal_3:connect(function(argument_147)
					extraResult_2 = argument_147
				end)
				Signal_3:fire("hello")
				expect(result_16).to.equal("hello")
				expect(extraResult_2).to.equal("hello")
			end)
			it("should return values when :wait() is called", function()
				local Signal_4 = Signal_2.new()
				spawn(function()
					Signal_4:fire(123, "hello")
				end)
				local wait_3, value_60 = Signal_4:wait()
				expect(wait_3).to.equal(123)
				expect(value_60).to.equal("hello")
			end)
			it("should properly handle disconnections", function()
				local Signal_5, enabled_10 = Signal_2.new(), false
				local connect = Signal_5:connect(function()
					enabled_10 = true
				end)
				connect:disconnect()
				Signal_5:fire()
				expect(enabled_10).to.equal(false)
			end)
		end
	end,
	-- Module: MainModule/Packages/Flipper/SingleMotor
	[41] = function()
		local __context, script, require = getModuleContext(41)
		-- Reconstructed module: MainModule/Packages/Flipper/SingleMotor
		-- Author: dawid | License: MIT (original Fluent header).
		local BaseMotor_5 = require(script.Parent.BaseMotor)
		local object_54 = setmetatable({}, BaseMotor_5)
		object_54.__index = object_54
		function object_54.new(argument_148, argument_149)
			assert(argument_148, "Missing argument #1: initialValue")
			assert(typeof(argument_148) == "number", "initialValue must be a number!")
			local object_55 = setmetatable(BaseMotor_5.new(), object_54)
			if argument_149 ~= nil then
				object_55._useImplicitConnections = argument_149
			else
				object_55._useImplicitConnections = true
			end
			object_55._goal = nil
			object_55._state = {
				complete = true,
				value = argument_148,
			}
			return object_55
		end
		function object_54.step(self_95, deltaTime_3)
			if self_95._state.complete then
				return true
			end
			local step_3 = self_95._goal:step(self_95._state, deltaTime_3)
			self_95._state = step_3
			self_95._onStep:fire(step_3.value)
			if step_3.complete then
				if self_95._useImplicitConnections then
					self_95:stop()
				end
				self_95._onComplete:fire()
			end
			return step_3.complete
		end
		function object_54.getValue(self_96)
			return self_96._state.value
		end
		function object_54.setGoal(self_97, goal_2)
			self_97._state.complete = false
			self_97._goal = goal_2
			self_97._onStart:fire()
			if self_97._useImplicitConnections then
				self_97:start()
			end
		end
		function object_54.__tostring(self_98)
			return "Motor(Single)"
		end
		return object_54
	end,
	-- Module: MainModule/Packages/Flipper/SingleMotor.spec
	[42] = function()
		local __context, script, require = getModuleContext(42)
		-- Reconstructed module: MainModule/Packages/Flipper/SingleMotor.spec
		-- Author: dawid | License: MIT (original Fluent header).
		return function()
			local SingleMotor_8, Instant_4 = require(script.Parent.SingleMotor), require(script.Parent.Instant)
			it("should assign new state on step", function()
				local SingleMotor_9 = SingleMotor_8.new(0, false)
				SingleMotor_9:setGoal(Instant_4.new(5))
				SingleMotor_9:step(0.016666666666666666)
				expect(SingleMotor_9._state.complete).to.equal(true)
				expect(SingleMotor_9._state.value).to.equal(5)
			end)
			it([[should invoke onComplete listeners when the goal is completed]], function()
				local SingleMotor_10, enabled_11 = SingleMotor_8.new(0, false), false
				SingleMotor_10:onComplete(function()
					enabled_11 = true
				end)
				SingleMotor_10:setGoal(Instant_4.new(5))
				SingleMotor_10:step(0.016666666666666666)
				expect(enabled_11).to.equal(true)
			end)
			it("should start when the goal is set", function()
				local SingleMotor_11, enabled_12 = SingleMotor_8.new(0, false), false
				SingleMotor_11:onStart(function()
					enabled_12 = not enabled_12
				end)
				SingleMotor_11:setGoal(Instant_4.new(5))
				expect(enabled_12).to.equal(true)
				SingleMotor_11:setGoal(Instant_4.new(5))
				expect(enabled_12).to.equal(false)
			end)
		end
	end,
	-- Module: MainModule/Packages/Flipper/Spring
	[43] = function()
		local __context, script, require = getModuleContext(43)
		-- Reconstructed module: MainModule/Packages/Flipper/Spring
		-- Author: dawid | License: MIT (original Fluent header).
		local number_8, number_9, number_10, object_56 = 0.001, 0.001, 0.0001, {}
		object_56.__index = object_56
		function object_56.new(argument_150, argument_151)
			assert(argument_150, "Missing argument #1: targetValue")
			argument_151 = argument_151 or {}
			return setmetatable({
				_targetValue = argument_150,
				_frequency = argument_151.frequency or 4,
				_dampingRatio = argument_151.dampingRatio or 1,
			}, object_56)
		end
		function object_56.step(self_99, deltaTime_4, argument_152)
			local _dampingRatio, value_61, _targetValue_2, value_62, value_63 =
				self_99._dampingRatio,
				self_99._frequency * 2 * math.pi,
				self_99._targetValue,
				deltaTime_4.value,
				deltaTime_4.velocity or 0
			local value_64, exp, value_65, value_66 =
				value_62 - _targetValue_2, (math.exp(-_dampingRatio * value_61 * argument_152))
			if _dampingRatio == 1 then
				value_65 = (value_64 * (1 + value_61 * argument_152) + value_63 * argument_152) * exp + _targetValue_2
				value_66 = (
					value_63 * (1 - value_61 * argument_152) - value_64 * (value_61 * value_61 * argument_152)
				) * exp
			elseif _dampingRatio < 1 then
				local sqrt = math.sqrt(1 - _dampingRatio * _dampingRatio)
				local cos, sin, value_67 =
					math.cos(value_61 * sqrt * argument_152), (math.sin(value_61 * sqrt * argument_152))
				if sqrt > number_10 then
					value_67 = sin / sqrt
				else
					local value_68 = argument_152 * value_61
					value_67 = value_68
						+ ((value_68 * value_68) * (sqrt * sqrt) * (sqrt * sqrt) / 20 - sqrt * sqrt)
							* (value_68 * value_68 * value_68)
							/ 6
				end
				local value_69
				if value_61 * sqrt > number_10 then
					value_69 = sin / (value_61 * sqrt)
				else
					local value_70 = value_61 * sqrt
					value_69 = argument_152
						+ (
								(argument_152 * argument_152) * (value_70 * value_70) * (value_70 * value_70) / 20
								- value_70 * value_70
							)
							* (argument_152 * argument_152 * argument_152)
							/ 6
				end
				value_65 = (value_64 * (cos + _dampingRatio * value_67) + value_63 * value_69) * exp + _targetValue_2
				value_66 = (value_63 * (cos - value_67 * _dampingRatio) - value_64 * (value_67 * value_61)) * exp
			else
				local sqrt_2 = math.sqrt(_dampingRatio * _dampingRatio - 1)
				local value_71, value_72 = -value_61 * (_dampingRatio - sqrt_2), -value_61 * (_dampingRatio + sqrt_2)
				local value_73 = (value_63 - value_64 * value_71) / (2 * value_61 * sqrt_2)
				local value_74 = value_64 - value_73
				local value_75, value_76 =
					value_74 * math.exp(value_71 * argument_152), value_73 * math.exp(value_72 * argument_152)
				value_65 = value_75 + value_76 + _targetValue_2
				value_66 = value_75 * value_71 + value_76 * value_72
			end
			local value_77 = math.abs(value_66) < number_8 and math.abs(value_65 - _targetValue_2) < number_9
			return {
				complete = value_77,
				value = value_77 and _targetValue_2 or value_65,
				velocity = value_66,
			}
		end
		return object_56
	end,
	-- Module: MainModule/Packages/Flipper/Spring.spec
	[44] = function()
		local __context, script, require = getModuleContext(44)
		-- Reconstructed module: MainModule/Packages/Flipper/Spring.spec
		-- Author: dawid | License: MIT (original Fluent header).
		return function()
			local SingleMotor_12, Spring_2 = require(script.Parent.SingleMotor), require(script.Parent.Spring)
			describe("completed state", function()
				local SingleMotor_13, Spring_3 =
					SingleMotor_12.new(0, false), Spring_2.new(1, {
						frequency = 2,
						dampingRatio = 0.75,
					})
				SingleMotor_13:setGoal(Spring_3)
				for index_8 = 1, 100 do
					SingleMotor_13:step(0.016666666666666666)
				end
				it("should complete", function()
					expect(SingleMotor_13._state.complete).to.equal(true)
				end)
				it("should be exactly the goal value when completed", function()
					expect(SingleMotor_13._state.value).to.equal(1)
				end)
			end)
			it("should inherit velocity", function()
				local SingleMotor_14 = SingleMotor_12.new(0, false)
				SingleMotor_14._state = {
					complete = false,
					value = 0,
					velocity = -5,
				}
				local Spring_4 = Spring_2.new(1, {
					frequency = 2,
					dampingRatio = 1,
				})
				SingleMotor_14:setGoal(Spring_4)
				SingleMotor_14:step(0.016666666666666666)
				expect(SingleMotor_14._state.velocity < 0).to.equal(true)
			end)
		end
	end,
	-- Module: MainModule/Packages/Flipper/isMotor
	[45] = function()
		local __context, script, require = getModuleContext(45)
		-- Reconstructed module: MainModule/Packages/Flipper/isMotor
		-- Author: dawid | License: MIT (original Fluent header).
		local callback_41 = function(argument_153)
			local match = tostring(argument_153):match("^Motor%((.+)%)$")
			if match then
				return true, match
			else
				return false
			end
		end
		return callback_41
	end,
	-- Module: MainModule/Packages/Flipper/isMotor.spec
	[46] = function()
		local __context, script, require = getModuleContext(46)
		-- Reconstructed module: MainModule/Packages/Flipper/isMotor.spec
		-- Author: dawid | License: MIT (original Fluent header).
		return function()
			local isMotor_2, SingleMotor_15, GroupMotor_8 =
				require(script.Parent.isMotor), require(script.Parent.SingleMotor), require(script.Parent.GroupMotor)
			local SingleMotor_16, GroupMotor_9 = SingleMotor_15.new(0), GroupMotor_8.new({})
			it("should properly detect motors", function()
				expect(isMotor_2(SingleMotor_16)).to.equal(true)
				expect(isMotor_2(GroupMotor_9)).to.equal(true)
			end)
			it("shouldn't detect things that aren't motors", function()
				expect(isMotor_2({})).to.equal(false)
			end)
			it("should return the proper motor type", function()
				local isMotor_3, result_17 = isMotor_2(SingleMotor_16)
				local isMotor_4, result_18 = isMotor_2(GroupMotor_9)
				expect(result_17).to.equal("Single")
				expect(result_18).to.equal("Group")
			end)
		end
	end,
	-- Module: MainModule/Themes
	[47] = function()
		local __context, script, require = getModuleContext(47)
		-- Reconstructed module: MainModule/Themes
		-- Author: dawid | License: MIT (original Fluent header).
		local object_57 = {
			Names = {
				"Dark",
				"Darker",
				"Light",
				"Aqua",
				"Amethyst",
				"Rose",
			},
		}
		for key_33, item_33 in next, script:GetChildren() do
			local item_34 = require(item_33)
			object_57[item_34.Name] = item_34
		end
		return object_57
	end,
	-- Module: MainModule/Themes/Amethyst
	[48] = function()
		local __context, script, require = getModuleContext(48)
		-- Reconstructed module: MainModule/Themes/Amethyst
		-- Author: dawid | License: MIT (original Fluent header).
		return {
			Name = "Amethyst",
			Accent = Color3.fromRGB(97, 62, 167),
			AcrylicMain = Color3.fromRGB(20, 20, 20),
			AcrylicBorder = Color3.fromRGB(110, 90, 130),
			AcrylicGradient = ColorSequence.new(Color3.fromRGB(85, 57, 139), Color3.fromRGB(40, 25, 65)),
			AcrylicNoise = 0.92,
			TitleBarLine = Color3.fromRGB(95, 75, 110),
			Tab = Color3.fromRGB(160, 140, 180),
			Element = Color3.fromRGB(140, 120, 160),
			ElementBorder = Color3.fromRGB(60, 50, 70),
			InElementBorder = Color3.fromRGB(100, 90, 110),
			ElementTransparency = 0.87,
			ToggleSlider = Color3.fromRGB(140, 120, 160),
			ToggleToggled = Color3.fromRGB(0, 0, 0),
			SliderRail = Color3.fromRGB(140, 120, 160),
			DropdownFrame = Color3.fromRGB(170, 160, 200),
			DropdownHolder = Color3.fromRGB(60, 45, 80),
			DropdownBorder = Color3.fromRGB(50, 40, 65),
			DropdownOption = Color3.fromRGB(140, 120, 160),
			Keybind = Color3.fromRGB(140, 120, 160),
			Input = Color3.fromRGB(140, 120, 160),
			InputFocused = Color3.fromRGB(20, 10, 30),
			InputIndicator = Color3.fromRGB(170, 150, 190),
			Dialog = Color3.fromRGB(60, 45, 80),
			DialogHolder = Color3.fromRGB(45, 30, 65),
			DialogHolderLine = Color3.fromRGB(40, 25, 60),
			DialogButton = Color3.fromRGB(60, 45, 80),
			DialogButtonBorder = Color3.fromRGB(95, 80, 110),
			DialogBorder = Color3.fromRGB(85, 70, 100),
			DialogInput = Color3.fromRGB(70, 55, 85),
			DialogInputLine = Color3.fromRGB(175, 160, 190),
			Text = Color3.fromRGB(240, 240, 240),
			SubText = Color3.fromRGB(170, 170, 170),
			Hover = Color3.fromRGB(140, 120, 160),
			HoverChange = 0.04,
		}
	end,
	-- Module: MainModule/Themes/Aqua
	[49] = function()
		local __context, script, require = getModuleContext(49)
		-- Reconstructed module: MainModule/Themes/Aqua
		-- Author: dawid | License: MIT (original Fluent header).
		return {
			Name = "Aqua",
			Accent = Color3.fromRGB(60, 165, 165),
			AcrylicMain = Color3.fromRGB(20, 20, 20),
			AcrylicBorder = Color3.fromRGB(50, 100, 100),
			AcrylicGradient = ColorSequence.new(Color3.fromRGB(60, 140, 140), Color3.fromRGB(40, 80, 80)),
			AcrylicNoise = 0.92,
			TitleBarLine = Color3.fromRGB(60, 120, 120),
			Tab = Color3.fromRGB(140, 180, 180),
			Element = Color3.fromRGB(110, 160, 160),
			ElementBorder = Color3.fromRGB(40, 70, 70),
			InElementBorder = Color3.fromRGB(80, 110, 110),
			ElementTransparency = 0.84,
			ToggleSlider = Color3.fromRGB(110, 160, 160),
			ToggleToggled = Color3.fromRGB(0, 0, 0),
			SliderRail = Color3.fromRGB(110, 160, 160),
			DropdownFrame = Color3.fromRGB(160, 200, 200),
			DropdownHolder = Color3.fromRGB(40, 80, 80),
			DropdownBorder = Color3.fromRGB(40, 65, 65),
			DropdownOption = Color3.fromRGB(110, 160, 160),
			Keybind = Color3.fromRGB(110, 160, 160),
			Input = Color3.fromRGB(110, 160, 160),
			InputFocused = Color3.fromRGB(20, 10, 30),
			InputIndicator = Color3.fromRGB(130, 170, 170),
			Dialog = Color3.fromRGB(40, 80, 80),
			DialogHolder = Color3.fromRGB(30, 60, 60),
			DialogHolderLine = Color3.fromRGB(25, 50, 50),
			DialogButton = Color3.fromRGB(40, 80, 80),
			DialogButtonBorder = Color3.fromRGB(80, 110, 110),
			DialogBorder = Color3.fromRGB(50, 100, 100),
			DialogInput = Color3.fromRGB(45, 90, 90),
			DialogInputLine = Color3.fromRGB(130, 170, 170),
			Text = Color3.fromRGB(240, 240, 240),
			SubText = Color3.fromRGB(170, 170, 170),
			Hover = Color3.fromRGB(110, 160, 160),
			HoverChange = 0.04,
		}
	end,
	-- Module: MainModule/Themes/Dark
	[50] = function()
		local __context, script, require = getModuleContext(50)
		-- Bloomware Midnight theme; Fluent theme keys are preserved.
		return {
		    Name = "Dark",
		    Error = Color3.fromRGB(255, 138, 148),
		    Accent = Color3.fromRGB(102, 215, 245),
		    AcrylicMain = Color3.fromRGB(14, 19, 32),
		    AcrylicBorder = Color3.fromRGB(44, 60, 84),
		    AcrylicGradient = ColorSequence.new(Color3.fromRGB(25, 40, 62), Color3.fromRGB(14, 19, 32)),
		    AcrylicNoise = 0.99,
		    Sidebar = Color3.fromRGB(17, 25, 41),
		    TitleBarLine = Color3.fromRGB(40, 53, 74),
		    Tab = Color3.fromRGB(102, 215, 245),
		    Element = Color3.fromRGB(28, 39, 59),
		    ElementBorder = Color3.fromRGB(47, 62, 85),
		    InElementBorder = Color3.fromRGB(59, 77, 103),
		    ElementTransparency = 0.12,
		    ToggleSlider = Color3.fromRGB(115, 135, 162),
		    ToggleToggled = Color3.fromRGB(13, 29, 43),
		    SliderRail = Color3.fromRGB(67, 85, 112),
		    DropdownFrame = Color3.fromRGB(18, 27, 43),
		    DropdownHolder = Color3.fromRGB(20, 29, 46),
		    DropdownBorder = Color3.fromRGB(54, 72, 99),
		    DropdownOption = Color3.fromRGB(102, 215, 245),
		    Keybind = Color3.fromRGB(65, 83, 112),
		    Input = Color3.fromRGB(18, 27, 43),
		    InputFocused = Color3.fromRGB(25, 39, 58),
		    InputIndicator = Color3.fromRGB(86, 109, 139),
		    Dialog = Color3.fromRGB(20, 29, 46),
		    DialogHolder = Color3.fromRGB(16, 24, 39),
		    DialogHolderLine = Color3.fromRGB(42, 57, 79),
		    DialogButton = Color3.fromRGB(35, 49, 71),
		    DialogButtonBorder = Color3.fromRGB(60, 80, 108),
		    DialogBorder = Color3.fromRGB(57, 76, 102),
		    DialogInput = Color3.fromRGB(15, 23, 38),
		    DialogInputLine = Color3.fromRGB(86, 109, 139),
		    Text = Color3.fromRGB(237, 243, 255),
		    SubText = Color3.fromRGB(147, 164, 190),
		    Hover = Color3.fromRGB(102, 215, 245),
		    HoverChange = 0.06,
		}
	end,
	-- Module: MainModule/Themes/Darker
	[51] = function()
		local __context, script, require = getModuleContext(51)
		-- Reconstructed module: MainModule/Themes/Darker
		-- Author: dawid | License: MIT (original Fluent header).
		return {
			Name = "Darker",
			Accent = Color3.fromRGB(72, 138, 182),
			AcrylicMain = Color3.fromRGB(30, 30, 30),
			AcrylicBorder = Color3.fromRGB(60, 60, 60),
			AcrylicGradient = ColorSequence.new(Color3.fromRGB(25, 25, 25), Color3.fromRGB(15, 15, 15)),
			AcrylicNoise = 0.94,
			TitleBarLine = Color3.fromRGB(65, 65, 65),
			Tab = Color3.fromRGB(100, 100, 100),
			Element = Color3.fromRGB(70, 70, 70),
			ElementBorder = Color3.fromRGB(25, 25, 25),
			InElementBorder = Color3.fromRGB(55, 55, 55),
			ElementTransparency = 0.82,
			DropdownFrame = Color3.fromRGB(120, 120, 120),
			DropdownHolder = Color3.fromRGB(35, 35, 35),
			DropdownBorder = Color3.fromRGB(25, 25, 25),
			Dialog = Color3.fromRGB(35, 35, 35),
			DialogHolder = Color3.fromRGB(25, 25, 25),
			DialogHolderLine = Color3.fromRGB(20, 20, 20),
			DialogButton = Color3.fromRGB(35, 35, 35),
			DialogButtonBorder = Color3.fromRGB(55, 55, 55),
			DialogBorder = Color3.fromRGB(50, 50, 50),
			DialogInput = Color3.fromRGB(45, 45, 45),
			DialogInputLine = Color3.fromRGB(120, 120, 120),
		}
	end,
	-- Module: MainModule/Themes/Light
	[52] = function()
		local __context, script, require = getModuleContext(52)
		-- Reconstructed module: MainModule/Themes/Light
		-- Author: dawid | License: MIT (original Fluent header).
		return {
			Name = "Light",
			Accent = Color3.fromRGB(0, 103, 192),
			AcrylicMain = Color3.fromRGB(200, 200, 200),
			AcrylicBorder = Color3.fromRGB(120, 120, 120),
			AcrylicGradient = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
			AcrylicNoise = 0.96,
			TitleBarLine = Color3.fromRGB(160, 160, 160),
			Tab = Color3.fromRGB(90, 90, 90),
			Element = Color3.fromRGB(255, 255, 255),
			ElementBorder = Color3.fromRGB(180, 180, 180),
			InElementBorder = Color3.fromRGB(150, 150, 150),
			ElementTransparency = 0.65,
			ToggleSlider = Color3.fromRGB(40, 40, 40),
			ToggleToggled = Color3.fromRGB(255, 255, 255),
			SliderRail = Color3.fromRGB(40, 40, 40),
			DropdownFrame = Color3.fromRGB(200, 200, 200),
			DropdownHolder = Color3.fromRGB(240, 240, 240),
			DropdownBorder = Color3.fromRGB(200, 200, 200),
			DropdownOption = Color3.fromRGB(150, 150, 150),
			Keybind = Color3.fromRGB(120, 120, 120),
			Input = Color3.fromRGB(200, 200, 200),
			InputFocused = Color3.fromRGB(100, 100, 100),
			InputIndicator = Color3.fromRGB(80, 80, 80),
			Dialog = Color3.fromRGB(255, 255, 255),
			DialogHolder = Color3.fromRGB(240, 240, 240),
			DialogHolderLine = Color3.fromRGB(228, 228, 228),
			DialogButton = Color3.fromRGB(255, 255, 255),
			DialogButtonBorder = Color3.fromRGB(190, 190, 190),
			DialogBorder = Color3.fromRGB(140, 140, 140),
			DialogInput = Color3.fromRGB(250, 250, 250),
			DialogInputLine = Color3.fromRGB(160, 160, 160),
			Text = Color3.fromRGB(0, 0, 0),
			SubText = Color3.fromRGB(40, 40, 40),
			Hover = Color3.fromRGB(50, 50, 50),
			HoverChange = 0.16,
		}
	end,
	-- Module: MainModule/Themes/Rose
	[53] = function()
		local __context, script, require = getModuleContext(53)
		-- Reconstructed module: MainModule/Themes/Rose
		-- Author: dawid | License: MIT (original Fluent header).
		return {
			Name = "Rose",
			Accent = Color3.fromRGB(180, 55, 90),
			AcrylicMain = Color3.fromRGB(40, 40, 40),
			AcrylicBorder = Color3.fromRGB(130, 90, 110),
			AcrylicGradient = ColorSequence.new(Color3.fromRGB(190, 60, 135), Color3.fromRGB(165, 50, 70)),
			AcrylicNoise = 0.92,
			TitleBarLine = Color3.fromRGB(140, 85, 105),
			Tab = Color3.fromRGB(180, 140, 160),
			Element = Color3.fromRGB(200, 120, 170),
			ElementBorder = Color3.fromRGB(110, 70, 85),
			InElementBorder = Color3.fromRGB(120, 90, 90),
			ElementTransparency = 0.86,
			ToggleSlider = Color3.fromRGB(200, 120, 170),
			ToggleToggled = Color3.fromRGB(0, 0, 0),
			SliderRail = Color3.fromRGB(200, 120, 170),
			DropdownFrame = Color3.fromRGB(200, 160, 180),
			DropdownHolder = Color3.fromRGB(120, 50, 75),
			DropdownBorder = Color3.fromRGB(90, 40, 55),
			DropdownOption = Color3.fromRGB(200, 120, 170),
			Keybind = Color3.fromRGB(200, 120, 170),
			Input = Color3.fromRGB(200, 120, 170),
			InputFocused = Color3.fromRGB(20, 10, 30),
			InputIndicator = Color3.fromRGB(170, 150, 190),
			Dialog = Color3.fromRGB(120, 50, 75),
			DialogHolder = Color3.fromRGB(95, 40, 60),
			DialogHolderLine = Color3.fromRGB(90, 35, 55),
			DialogButton = Color3.fromRGB(120, 50, 75),
			DialogButtonBorder = Color3.fromRGB(155, 90, 115),
			DialogBorder = Color3.fromRGB(100, 70, 90),
			DialogInput = Color3.fromRGB(135, 55, 80),
			DialogInputLine = Color3.fromRGB(190, 160, 180),
			Text = Color3.fromRGB(240, 240, 240),
			SubText = Color3.fromRGB(170, 170, 170),
			Hover = Color3.fromRGB(200, 120, 170),
			HoverChange = 0.04,
		}
	end,
	-- Module: MainModule/Components/ProfilePanel
	[54] = function()
		local __context, script, require = getModuleContext(54)
		-- Bloomware UI: profile browser, save/load and JSON import/export.
		local Creator = require(script.Parent.Parent.Creator)
		local New = Creator.New
		return function(window,library)
		    local manager=library.Profiles
		    local panel={Selected=nil,Rows={}}
		    local layout=New("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})
		    panel.Frame=New("ScrollingFrame",{
		        Name="ProfilePanel",Visible=false,BackgroundTransparency=1,CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,
		        ScrollingDirection=Enum.ScrollingDirection.Y,Parent=window.Root,ThemeTag={ScrollBarImageColor3="SubText"},
		    },{layout,New("UIPadding",{PaddingLeft=UDim.new(0,1),PaddingRight=UDim.new(0,7),PaddingBottom=UDim.new(0,12)})})
		    local function label(text,order,height)
		        return New("TextLabel",{Text=text,TextSize=12,TextWrapped=true,AutomaticSize=Enum.AutomaticSize.Y,
		            Size=UDim2.new(1,0,0,height or 20),LayoutOrder=order,Parent=panel.Frame,TextXAlignment=Enum.TextXAlignment.Left,
		            FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json"),ThemeTag={TextColor3="SubText"}})
		    end
		    local back=New("TextButton",{
		        Text="‹  Back to settings",TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,0,0,44),LayoutOrder=1,
		        BackgroundTransparency=1,Parent=panel.Frame,ThemeTag={TextColor3="Accent"},
		    })
		    panel.Storage=label("",2,30)
		    panel.Active=label("No active profile",3)
		    local field=require(script.Parent.Textbox)(panel.Frame,true)
		    field.Frame.Size=UDim2.new(1,0,0,44);field.Frame.LayoutOrder=4
		    field.Input.PlaceholderText="Profile name";panel.NameInput=field.Input
		    panel.List=New("ScrollingFrame",{
		        Name="SavedProfiles",Size=UDim2.new(1,0,0,140),LayoutOrder=5,BackgroundTransparency=0.35,
		        CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,ScrollingDirection=Enum.ScrollingDirection.Y,Parent=panel.Frame,
		        ThemeTag={BackgroundColor3="DropdownHolder",ScrollBarImageColor3="SubText"},
		    },{New("UICorner",{CornerRadius=UDim.new(0,9)}),New("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder}),New("UIPadding",{PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5),PaddingTop=UDim.new(0,5)})})
		    local grid=New("UIGridLayout",{CellPadding=UDim2.fromOffset(8,8),CellSize=UDim2.new(1/3,-6,0,44),SortOrder=Enum.SortOrder.LayoutOrder})
		    local actions=New("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,96),LayoutOrder=6,Parent=panel.Frame},{grid})
		    label("JSON import / export",7)
		    local jsonScroll=New("ScrollingFrame",{
		        Size=UDim2.new(1,0,0,160),LayoutOrder=8,CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,
		        ScrollingDirection=Enum.ScrollingDirection.Y,Parent=panel.Frame,
		        ThemeTag={BackgroundColor3="Input",ScrollBarImageColor3="SubText"},
		    },{New("UICorner",{CornerRadius=UDim.new(0,9)}),New("UIStroke",{Transparency=0.6,ThemeTag={Color="InElementBorder"}})})
		    panel.JSON=New("TextBox",{
		        Name="ProfileJSON",Text="",PlaceholderText="Export a profile or paste JSON here, then press Import.",TextSize=12,
		        FontFace=Font.new("rbxasset://fonts/families/RobotoMono.json"),BackgroundTransparency=1,ClearTextOnFocus=false,
		        MultiLine=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
		        AutomaticSize=Enum.AutomaticSize.Y,Size=UDim2.new(1,-24,0,140),Position=UDim2.fromOffset(12,10),Parent=jsonScroll,
		        ThemeTag={TextColor3="Text",PlaceholderColor3="SubText"},
		    })
		    panel.Status=label("Save your current settings, or select a profile to load.",9,30)
		    function panel:SetStatus(message,success)
		        self.Status.Text=message or ""
		        Creator.OverrideTag(self.Status,{TextColor3=success==false and "Error" or "SubText"})
		    end
		    function panel:Refresh()
		        if window.Destroyed then return end
		        self.Storage.Text=manager.StorageError or (manager.Mode=="session" and "Session storage · export JSON to keep profiles after closing." or "Profile storage is available. Press Save to keep changes.")
		        self.Active.Text=manager.Active and ("Active: "..manager.Active..(manager.Dirty and " · unsaved changes" or "")) or "No active profile"
		        for _,row in ipairs(self.Rows)do row:Destroy()end
		        table.clear(self.Rows)
		        local names=manager:List()
		        if self.Selected and not manager.Data[self.Selected]then self.Selected=nil end
		        for index,name in ipairs(names)do
		            local row=New("TextButton",{
		                Text="  "..name,TextSize=13,TextTruncate=Enum.TextTruncate.AtEnd,TextXAlignment=Enum.TextXAlignment.Left,
		                Size=UDim2.new(1,-3,0,44),LayoutOrder=index,BackgroundTransparency=self.Selected==name and 0.86 or 1,Parent=self.List,
		                FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json",Enum.FontWeight.Medium),
		                ThemeTag={BackgroundColor3="Tab",TextColor3=self.Selected==name and "Accent" or "Text"},
		            },{New("UICorner",{CornerRadius=UDim.new(0,7)})})
		            Creator.AddSignal(row.Activated,function()self.Selected=name;self.NameInput.Text=name;self:Refresh()end,row)
		            self.Rows[#self.Rows+1]=row
		        end
		        if #names==0 then
		            local empty=New("TextLabel",{Text="No saved profiles yet",TextSize=12,Size=UDim2.new(1,0,0,44),Parent=self.List,ThemeTag={TextColor3="SubText"}})
		            self.Rows[1]=empty
		        end
		        self.List.CanvasSize=UDim2.fromOffset(0,math.max(1,#names)*48+10)
		    end
		    local function confirm(title,content,callback)
		        window:Dialog({Title=title,Content=content,Buttons={{Title="Cancel"},{Title="Continue",Callback=callback}}})
		    end
		    local function action(text,order,callback)
		        local button=New("TextButton",{
		            Text=text,TextSize=13,LayoutOrder=order,Parent=actions,BackgroundTransparency=0.3,
		            FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json",Enum.FontWeight.Medium),
		            ThemeTag={TextColor3="Text",BackgroundColor3="DialogButton"},
		        },{New("UICorner",{CornerRadius=UDim.new(0,8)}),New("UIStroke",{Transparency=0.6,ThemeTag={Color="DialogButtonBorder"}})})
		        Creator.AddSignal(button.Activated,callback)
		        return button
		    end
		    panel.SaveButton=action("Save",1,function()
		        local name=panel.NameInput.Text:match("^%s*(.-)%s*$")
		        local function save(overwrite)
		            local ok,message=manager:Save(name,overwrite);panel:SetStatus(message,ok)
		            if ok then panel.Selected=name;panel:Refresh()end
		        end
		        if manager.Data[name]then confirm("Overwrite profile",'Replace "'..name..'" with the current settings?',function()save(true)end)else save(false)end
		    end)
		    panel.LoadButton=action("Load",2,function()
		        local ok,message=manager:Load(panel.Selected);panel:SetStatus(message,ok)
		    end)
		    panel.DeleteButton=action("Delete",3,function()
		        local name=panel.Selected
		        if not name then panel:SetStatus("Choose an existing profile.",false);return end
		        confirm("Delete profile",'Delete "'..name..'"?',function()local ok,message=manager:Delete(name);panel:SetStatus(message,ok)end)
		    end)
		    panel.ExportButton=action("Export JSON",4,function()
		        local text,message=manager:Export(panel.Selected)
		        if text then panel.JSON.Text=text;panel:SetStatus("JSON is ready. Select the text to copy it.",true)else panel:SetStatus(message,false)end
		    end)
		    panel.ImportButton=action("Import JSON",5,function()
		        local name=panel.NameInput.Text:match("^%s*(.-)%s*$")
		        local function import(overwrite)local ok,message=manager:Import(panel.JSON.Text,name,overwrite);panel:SetStatus(message,ok);if ok then panel:Refresh()end end
		        if name~="" and manager.Data[name]then confirm("Overwrite profile",'Replace "'..name..'" with imported JSON?',function()import(true)end)else import(false)end
		    end)
		    panel.CopyButton=action(type(setclipboard)=="function" and "Copy JSON" or "Select JSON",6,function()
		        if type(setclipboard)=="function" then
		            local ok=pcall(setclipboard,panel.JSON.Text);panel:SetStatus(ok and "JSON copied." or "Could not copy. Select the JSON text manually.",ok)
		        else panel.JSON:CaptureFocus();panel.JSON.CursorPosition=#panel.JSON.Text+1;panel.JSON.SelectionStart=1 end
		    end)
		    function panel:Layout(mobile)
		        local columns=mobile and 2 or 3
		        grid.CellSize=UDim2.new(1/columns,-(columns-1)*8/columns,0,44)
		        grid.FillDirectionMaxCells=columns
		        actions.Size=UDim2.new(1,0,0,math.ceil(6/columns)*52-8)
		    end
		    function panel:Open()self.Frame.Visible=true;self:Refresh()end
		    function panel:Close()self.Frame.Visible=false;self.NameInput:ReleaseFocus();self.JSON:ReleaseFocus()end
		    Creator.AddSignal(back.Activated,function()window:CloseTools()end)
		    Creator.AddSignal(layout:GetPropertyChangedSignal("AbsoluteContentSize"),function()
		        panel.Frame.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y/Creator.GetScale(panel.Frame)+12)
		    end,panel.Frame)
		    Creator.AddSignal(panel.JSON:GetPropertyChangedSignal("AbsoluteSize"),function()
		        jsonScroll.CanvasSize=UDim2.fromOffset(0,panel.JSON.AbsoluteSize.Y/Creator.GetScale(panel.JSON)+20)
		    end,panel.Frame)
		    manager.Changed=function()if panel.Frame.Visible then panel:Refresh()end end
		    panel:Layout(window.Mobile)
		    return panel
		end
	end,
	-- Module: MainModule/Components/SearchPanel
	[55] = function()
		local __context, script, require = getModuleContext(55)
		-- Bloomware UI: global settings search and navigation.
		local Creator = require(script.Parent.Parent.Creator)
		local UserInputService = game:GetService("UserInputService")
		local New = Creator.New
		return function(window, library)
		    local panel = { Results={}, Rows={}, Selected=1, Generation=0 }
		    panel.Frame = New("Frame", { Name="SearchPanel",BackgroundTransparency=1,Visible=false,Parent=window.Root })
		    local field = require(script.Parent.Textbox)(panel.Frame,true)
		    panel.Input = field.Input
		    field.Frame.Position=UDim2.fromOffset(0,0);field.Frame.Size=UDim2.new(1,-56,0,44)
		    field.Input.PlaceholderText="Search settings, descriptions or tabs..."
		    local close=New("TextButton",{
		        Text="×",TextSize=22,Size=UDim2.fromOffset(44,44),Position=UDim2.new(1,-44,0,0),
		        BackgroundTransparency=0.85,Parent=panel.Frame,
		        ThemeTag={BackgroundColor3="Tab",TextColor3="Text"},
		    },{New("UICorner",{CornerRadius=UDim.new(0,9)})})
		    panel.Status=New("TextLabel",{
		        Text="Type a setting name, description or tab.",TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,
		        TextWrapped=true,Size=UDim2.new(1,0,0,34),Position=UDim2.fromOffset(0,50),Parent=panel.Frame,
		        FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json"),ThemeTag={TextColor3="SubText"},
		    })
		    panel.List=New("ScrollingFrame",{
		        Size=UDim2.new(1,0,1,-90),Position=UDim2.fromOffset(0,90),BackgroundTransparency=1,
		        CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,ScrollingDirection=Enum.ScrollingDirection.Y,
		        Parent=panel.Frame,ThemeTag={ScrollBarImageColor3="SubText"},
		    },{New("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder}),New("UIPadding",{PaddingRight=UDim.new(0,6),PaddingLeft=UDim.new(0,1),PaddingTop=UDim.new(0,1)})})
		    function panel:Select(index)
		        self.Selected=math.clamp(index,1,math.max(1,#self.Results))
		        for i,row in ipairs(self.Rows)do
		            Creator.OverrideTag(row.Title,{TextColor3=i==self.Selected and "Accent" or "Text"})
		            row.Frame.BackgroundTransparency=i==self.Selected and 0 or Creator.GetThemeProperty("ElementTransparency")
		        end
		    end
		    function panel:Choose(index)
		        local result=self.Results[index or self.Selected]
		        if result then return window:Reveal(result.Entry) end
		        return false
		    end
		    function panel:Refresh()
		        if window.Destroyed or not self.Frame.Visible then return end
		        for _,row in ipairs(self.Rows)do row.Frame:Destroy()end
		        table.clear(self.Rows)
		        local results,total=library.Search:Search(self.Input.Text,100)
		        self.Results=results
		        local query=library.Search.Fold(self.Input.Text)
		        self.Status.Text=query=="" and "Type a setting name, description or tab." or (total==0 and "No settings found. Try another word." or (tostring(total).." settings found"..(total>#results and " · showing the first 100" or "")))
		        for index,result in ipairs(results)do
		            local row=New("TextButton",{
		                Text="",Size=UDim2.new(1,0,0,70),LayoutOrder=index,Parent=self.List,
		                ThemeTag={BackgroundColor3="Element",BackgroundTransparency="ElementTransparency"},
		            },{New("UICorner",{CornerRadius=UDim.new(0,10)}),New("UIStroke",{Transparency=0.6,ThemeTag={Color="ElementBorder"}})})
		            local title=New("TextLabel",{
		                Text=result.Title,TextSize=13,TextTruncate=Enum.TextTruncate.AtEnd,TextXAlignment=Enum.TextXAlignment.Left,
		                Size=UDim2.new(1,-28,0,22),Position=UDim2.fromOffset(14,10),Parent=row,
		                FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json",Enum.FontWeight.Medium),ThemeTag={TextColor3="Text"},
		            })
		            New("TextLabel",{
		                Text=result.Path,TextSize=11,TextTruncate=Enum.TextTruncate.AtEnd,TextXAlignment=Enum.TextXAlignment.Left,
		                Size=UDim2.new(1,-28,0,20),Position=UDim2.fromOffset(14,36),Parent=row,
		                FontFace=Font.new("rbxasset://fonts/families/GothamSSm.json"),ThemeTag={TextColor3="SubText"},
		            })
		            Creator.AddSignal(row.Activated,function()self:Choose(index)end,row)
		            self.Rows[index]={Frame=row,Title=title}
		        end
		        self.List.CanvasSize=UDim2.fromOffset(0,#results*78)
		        self:Select(1)
		    end
		    function panel:Open(query)
		        self.Frame.Visible=true
		        if query~=nil then self.Input.Text=query end
		        self:Refresh()
		        self.Input:CaptureFocus()
		    end
		    function panel:Close()
		        self.Generation=self.Generation+1
		        self.Frame.Visible=false
		        self.Input:ReleaseFocus()
		    end
		    Creator.AddSignal(close.Activated,function()window:CloseTools()end)
		    Creator.AddSignal(panel.Input:GetPropertyChangedSignal("Text"),function()
		        panel.Generation=panel.Generation+1
		        local generation=panel.Generation
		        task.delay(0.08,function()if generation==panel.Generation and not window.Destroyed then panel:Refresh()end end)
		    end,panel.Frame)
		    Creator.AddSignal(panel.Input.FocusLost,function(entered)if entered and panel.Frame.Visible then panel:Choose()end end,panel.Frame)
		    Creator.AddSignal(UserInputService.InputBegan,function(input)
		        if not panel.Frame.Visible or UserInputService:GetFocusedTextBox()~=panel.Input then return end
		        if input.KeyCode==Enum.KeyCode.Down then panel:Select(panel.Selected+1)
		        elseif input.KeyCode==Enum.KeyCode.Up then panel:Select(panel.Selected-1)end
		    end,panel.Frame)
		    library.Search.Changed=function()if panel.Frame.Visible then panel:Refresh()end end
		    return panel
		end
	end,
	-- Module: MainModule/Profiles
	[56] = function()
		local __context, script, require = getModuleContext(56)
		-- Bloomware UI: typed JSON profiles. No code is executed from profile data.
		local HttpService = game:GetService("HttpService")
		local Appearance = require(script.Parent.Appearance)
		local Profiles = {}
		Profiles.__index = Profiles
		local supported = { Toggle=true, Slider=true, Input=true, Dropdown=true, Keybind=true, Colorpicker=true }
		local modes = { Toggle=true, Hold=true, Always=true }
		local function finite(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
		local function clone(value)
		    if type(value) ~= "table" then return value end
		    local result = {}; for key, item in pairs(value) do result[key] = clone(item) end; return result
		end
		local function validName(name)
		    if type(name) ~= "string" then return nil, "Enter a profile name." end
		    name = name:match("^%s*(.-)%s*$")
		    local length = utf8.len(name)
		    if not length or length < 1 or length > 40 or name:find("[%c]") then return nil, "Use a name of 1–40 characters without control characters." end
		    return name
		end
		local function validData(data)
		    if type(data) ~= "table" or data.Format ~= "BloomwareProfile" or data.Version ~= 1 or type(data.Options) ~= "table" then return false, "Unsupported profile format or version." end
		    local count = 0
		    for id, entry in pairs(data.Options) do
		        count = count + 1
		        if count > 2000 or type(id) ~= "string" or #id > 256 or type(entry) ~= "table" or not supported[entry.Type] then return false, "Invalid profile options." end
		        if entry.Type == "Toggle" and type(entry.Value) ~= "boolean" then return false, "Invalid toggle value: " .. id end
		        if entry.Type == "Slider" and not finite(entry.Value) then return false, "Invalid slider value: " .. id end
		        if entry.Type == "Input" and (type(entry.Value) ~= "string" or #entry.Value > 16384) then return false, "Invalid input value: " .. id end
		        if entry.Type == "Keybind" and (type(entry.Value) ~= "string" or #entry.Value > 64 or not modes[entry.Mode]) then return false, "Invalid key binding: " .. id end
		        if entry.Type == "Dropdown" then
		            if type(entry.Multi) ~= "boolean" then return false, "Invalid dropdown mode: " .. id end
		            if entry.Multi then
		                if type(entry.Value) ~= "table" or #entry.Value > 2000 then return false, "Invalid dropdown selection: " .. id end
		                local n = 0
		                for key, value in pairs(entry.Value) do
		                    n = n + 1
		                    if type(key) ~= "number" or key < 1 or key % 1 ~= 0 or key > #entry.Value or type(value) ~= "string" and not finite(value) then return false, "Invalid dropdown selection: " .. id end
		                end
		                if n ~= #entry.Value then return false, "Invalid dropdown selection: " .. id end
		            elseif entry.Value ~= nil and type(entry.Value) ~= "string" and not finite(entry.Value) then return false, "Invalid dropdown value: " .. id end
		        end
		        if entry.Type == "Colorpicker" then
		            if type(entry.Value) ~= "table" then return false, "Invalid color: " .. id end
		            for _, key in ipairs({"R","G","B","Transparency"}) do
		                local value = entry.Value[key]
		                if not finite(value) or value < 0 or value > 1 then return false, "Invalid color: " .. id end
		            end
		        end
		    end
		    if data.UI ~= nil then
		        if type(data.UI) ~= "table" or data.UI.Theme ~= nil and type(data.UI.Theme) ~= "string" or data.UI.Transparency ~= nil and type(data.UI.Transparency) ~= "boolean" then return false, "Invalid interface settings." end
		        if data.UI.Background ~= nil and not Appearance.ValidateState(data.UI.Background) then return false, "Invalid background settings." end
		    end
		    return true
		end

		function Profiles.new(library, config)
		    config = config or {}
		    local self = setmetatable({ Library=library, Entries={}, Data={}, Active=nil, Dirty=false, Applying=false, Changed=nil, Mode="session" }, Profiles)
		    local adapter = config.ProfileStorage
		    if type(adapter) == "table" and type(adapter.Read) == "function" and type(adapter.Write) == "function" then
		        self.Mode, self.Read, self.Write = "custom", adapter.Read, adapter.Write
		    elseif type(readfile) == "function" and type(writefile) == "function" and type(isfile) == "function" then
		        local namespace = tostring(game.GameId or game.PlaceId or "default"):gsub("[^%w_-]", "_")
		        self.File = config.ProfileFile or ("bloomware-ui-profiles-" .. namespace .. ".json")
		        self.Mode = "file"
		        self.Read = function() if isfile(self.File) then return readfile(self.File) end; return nil end
		        self.Write = function(text) return writefile(self.File, text) end
		    end
		    if self.Read then
		        local ok, text = pcall(self.Read)
		        if ok and text ~= nil then
		            if type(text) ~= "string" or #text > 524288 then self.StorageError = "Saved profiles are too large or unreadable."
		            else
		                local decoded, document = pcall(HttpService.JSONDecode, HttpService, text)
		                if not decoded or type(document) ~= "table" or document.Format ~= "BloomwareProfiles" or document.Version ~= 1 or type(document.Profiles) ~= "table" then
		                    self.StorageError = "Saved profiles could not be read. The file has been preserved."
		                else
		                    local count = 0
		                    for name, profile in pairs(document.Profiles) do
		                        count = count + 1
		                        if count > 64 or not validName(name) or not validData(profile) then self.StorageError = "Saved profiles contain invalid data. The file has been preserved."; break end
		                    end
		                    if not self.StorageError then self.Data = document.Profiles end
		                end
		            end
		        elseif not ok then self.StorageError = "Profile storage could not be read: " .. tostring(text) end
		    end
		    return self
		end
		function Profiles:NotifyChanged() if self.Changed then self.Changed() end end
		function Profiles:MarkDirty()
		    if self.Active and not self.Applying then self.Dirty = true; self:NotifyChanged() end
		end
		function Profiles:Register(id, option, config)
		    if id == nil or not supported[option.Type] or config.IgnoreProfile == true then return end
		    local key = tostring(id)
		    self.Entries[key] = { Option=option, Id=id, Config=config }
		    local function state(target)
		        if target.Type == "Colorpicker" then return {target.Value.R,target.Value.G,target.Value.B,target.Transparency or 0} end
		        if target.Type == "Keybind" then return {target.Value,target.Mode} end
		        return {clone(target.Value)}
		    end
		    local function equal(a,b)
		        if type(a) ~= type(b) then return false end
		        if type(a) ~= "table" then return a == b end
		        for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
		        for k in pairs(b) do if a[k] == nil then return false end end
		        return true
		    end
		    local function wrap(original)
		        return function(target, ...)
		            local before = self.Active and not self.Applying and state(target) or nil
		            local result = table.pack(original(target, ...))
		            if before and self.Entries[key] and self.Entries[key].Option == target and not equal(before,state(target)) then self:MarkDirty() end
		            return table.unpack(result, 1, result.n)
		        end
		    end
		    option.SetValue = wrap(option.SetValue)
		    if option.Type == "Colorpicker" then option.SetValueRGB = wrap(option.SetValueRGB) end
		end
		function Profiles:Unregister(id, option)
		    local entry = self.Entries[tostring(id)]
		    if entry and entry.Option == option then self.Entries[tostring(id)] = nil end
		end
		function Profiles:Capture(name)
		    local data = { Format="BloomwareProfile", Version=1, Name=name or self.Active or "Profile", Options={}, UI={Theme=self.Library.Theme, Transparency=self.Library.Transparency} }
		    if self.Library.Appearance then data.UI.Background = self.Library.Appearance:Snapshot() end
		    for id, entry in pairs(self.Entries) do
		        local option = entry.Option
		        if not option.IgnoreProfile and self.Library.Options[entry.Id] == option then
		            local item = { Type=option.Type, Value=option.Value }
		            if option.Type == "Dropdown" then
		                item.Multi = option.Multi
		                if option.Multi then item.Value = clone(option:GetActiveValues()) end
		            elseif option.Type == "Keybind" then item.Mode = option.Mode
		            elseif option.Type == "Colorpicker" then item.Value = { R=option.Value.R,G=option.Value.G,B=option.Value.B,Transparency=option.Transparency or 0 } end
		            data.Options[id] = item
		        end
		    end
		    return data
		end
		function Profiles:List()
		    local names = {};for name in pairs(self.Data) do names[#names+1]=name end
		    table.sort(names, function(a,b) return a:lower()<b:lower() end)
		    return names
		end
		function Profiles:Commit(nextData)
		    if self.StorageError then return false, self.StorageError end
		    if self.Write then
		        local encoded, text = pcall(HttpService.JSONEncode, HttpService, {Format="BloomwareProfiles",Version=1,Profiles=nextData})
		        if not encoded or #text > 524288 then return false, "Profiles could not be encoded or exceed 512 KB." end
		        local ok, result = pcall(self.Write, text)
		        if not ok or result == false then return false, "Profiles could not be saved: " .. tostring(result) end
		    end
		    self.Data = nextData
		    self:NotifyChanged()
		    return true
		end
		function Profiles:Save(name, overwrite)
		    if self.Library.Appearance and self.Library.Appearance.Loading then return false, "Wait for the background to load before saving a profile." end
		    local normalized, message = validName(name); if not normalized then return false, message end
		    name = normalized
		    if self.Data[name] and not overwrite then return false, "A profile with this name already exists." end
		    if not self.Data[name] and #self:List() >= 64 then return false, "The limit is 64 profiles." end
		    local data = self:Capture(name)
		    local valid, errorMessage = validData(data);if not valid then return false,errorMessage end
		    local nextData = clone(self.Data);nextData[name]=data
		    local ok, errorText = self:Commit(nextData)
		    if ok then self.Active=name;self.Dirty=false;self:NotifyChanged() end
		    return ok, ok and (self.Mode=="session" and "Saved for this session. Export JSON to keep a copy." or "Profile saved.") or errorText
		end
		local function validateForOption(entry, registered)
		    local option,config = registered.Option,registered.Config
		    if entry.Type ~= option.Type then return false, "Option type changed." end
		    if option.Type == "Slider" and (entry.Value < option.Min or entry.Value > option.Max) then return false,"Slider value is outside its current range." end
		    if option.Type == "Input" then
		        if option.Numeric and entry.Value ~= "" and not tonumber(entry.Value) then return false,"Expected a numeric input." end
		        if config.MaxLength and (not utf8.len(entry.Value) or utf8.len(entry.Value)>config.MaxLength) then return false,"Input exceeds its maximum length." end
		    end
		    if option.Type == "Dropdown" then
		        if option.Multi ~= entry.Multi then return false,"Dropdown mode changed." end
		        local values = entry.Multi and entry.Value or (entry.Value~=nil and {entry.Value} or {})
		        for _,value in ipairs(values) do if not table.find(option.Values,value) then return false,"Dropdown option is no longer available." end end
		    end
		    if option.Type == "Keybind" and entry.Value ~= "None" and entry.Value ~= "MouseLeft" and entry.Value ~= "MouseRight" then
		        local valid,key = pcall(function()return Enum.KeyCode[entry.Value]end)
		        if not valid or not key then return false,"Unknown key binding." end
		    end
		    return true
		end
		local function applyEntry(option, entry)
		    if entry.Type == "Colorpicker" then option:SetValueRGB(Color3.new(entry.Value.R,entry.Value.G,entry.Value.B),entry.Value.Transparency)
		    elseif entry.Type == "Keybind" then option:SetValue(entry.Value,entry.Mode)
		    else option:SetValue(clone(entry.Value)) end
		end
		function Profiles:Load(name)
		    if self.Applying then return false,"Another profile is being applied." end
		    local data = self.Data[name];if not data then return false,"Choose an existing profile." end
		    local valid,message = validData(data);if not valid then return false,message end
		    local changes, skipped = {},0
		    for id,entry in pairs(data.Options) do
		        local registered = self.Entries[id]
		        if registered and not registered.Option.IgnoreProfile and self.Library.Options[registered.Id]==registered.Option then
		            local good,reason=validateForOption(entry,registered)
		            if not good then return false,id .. ": " .. reason end
		            changes[#changes+1]={Id=id,Option=registered.Option,Value=entry}
		        else skipped=skipped+1 end
		    end
		    table.sort(changes,function(a,b)return a.Id<b.Id end)
		    if data.UI and data.UI.Theme and not table.find(self.Library.Themes,data.UI.Theme) then return false,"The profile theme is unavailable." end
		    local library,before=self.Library,self:Capture()
		    self.Applying=true;library._CallbackQueue={}
		    local applied,reason=pcall(function()
		        for _,change in ipairs(changes)do applyEntry(change.Option,change.Value)end
		        if data.UI then
		            if data.UI.Theme then library:SetTheme(data.UI.Theme) end
		            if data.UI.Transparency~=nil then library:ToggleTransparency(data.UI.Transparency) end
		        end
		    end)
		    local queue=library._CallbackQueue
		    if not applied then
		        for _,change in ipairs(changes)do if before.Options[change.Id] then pcall(applyEntry,change.Option,before.Options[change.Id])end end
		        pcall(library.SetTheme,library,before.UI.Theme);pcall(library.ToggleTransparency,library,before.UI.Transparency)
		    end
		    library._CallbackQueue=nil;self.Applying=false
		    if not applied then return false,"Profile was not applied: " .. tostring(reason) end
		    self.Active=name;self.Dirty=false
		    -- Restore after the callback queue closes so internal control syncing stays silent.
		    -- Old version-1 profiles without Background preserve the current wallpaper.
		    if data.UI and data.UI.Background and library.Appearance then library.Appearance:Restore(data.UI.Background) end
		    local errors=0
		    for _,call in ipairs(queue)do
		        if library.Unloaded then break end
		        if library:SafeCallback(call.Callback,table.unpack(call.Args,1,call.Args.n))==false then errors=errors+1 end
		    end
		    self:NotifyChanged()
		    return true,"Profile loaded." .. (skipped>0 and (" Skipped unavailable options: "..skipped..".")or"") .. (errors>0 and (" Callback errors: "..errors..".")or"")
		end
		function Profiles:Delete(name)
		    if not self.Data[name] then return false,"Choose an existing profile." end
		    local nextData=clone(self.Data);nextData[name]=nil
		    local ok,message=self:Commit(nextData)
		    if ok and self.Active==name then self.Active=nil;self.Dirty=false;self:NotifyChanged()end
		    return ok,ok and "Profile deleted." or message
		end
		function Profiles:Export(name)
		    if not name and self.Library.Appearance and self.Library.Appearance.Loading then return nil, "Wait for the background to load before exporting a profile." end
		    local data = name and self.Data[name] or self:Capture()
		    if not data then return nil,"Choose an existing profile." end
		    local ok,text=pcall(HttpService.JSONEncode,HttpService,data)
		    return ok and text or nil,not ok and tostring(text) or nil
		end
		function Profiles:Import(text,name,overwrite)
		    if type(text)~="string" or #text>524288 then return false,"Paste a JSON profile smaller than 512 KB." end
		    local decoded,data=pcall(HttpService.JSONDecode,HttpService,text)
		    if not decoded then return false,"Invalid JSON." end
		    local valid,message=validData(data);if not valid then return false,message end
		    local normalized,errorText=validName(name~="" and name or data.Name)
		    if not normalized then return false,errorText end
		    if self.Data[normalized] and not overwrite then return false,"A profile with this name already exists." end
		    if not self.Data[normalized] and #self:List()>=64 then return false,"The limit is 64 profiles." end
		    local nextData=clone(self.Data);data.Name=normalized;nextData[normalized]=clone(data)
		    local ok,reason=self:Commit(nextData)
		    return ok,ok and "Profile imported. Select it and press Load to apply it." or reason
		end
		function Profiles:Destroy() self.Changed=nil;table.clear(self.Entries);table.clear(self.Data)end
		return Profiles
	end,
	-- Module: MainModule/SearchIndex
	[57] = function()
		local __context, script, require = getModuleContext(57)
		-- Bloomware UI: searchable settings registry, independent of the rendering layer.
		local SearchIndex = {}
		SearchIndex.__index = SearchIndex

		local lowerExtra = { [0x401]=0x451, [0x404]=0x454, [0x406]=0x456, [0x407]=0x457, [0x490]=0x491 }
		function SearchIndex.Fold(text)
		    text = tostring(text or ""):gsub("<[^>]->", "")
		    local output = {}
		    local ok = pcall(function()
		        for _, code in utf8.codes(text) do
		            if code >= 0x41 and code <= 0x5A or code >= 0x410 and code <= 0x42F then code = code + 32
		            elseif code >= 0xC0 and code <= 0xDE and code ~= 0xD7 then code = code + 32
		            else code = lowerExtra[code] or code end
		            output[#output + 1] = utf8.char(code)
		        end
		    end)
		    return (ok and table.concat(output) or text:lower()):gsub("%s+", " "):match("^%s*(.-)%s*$")
		end

		function SearchIndex.new()
		    return setmetatable({ Entries = {}, Sequence = 0, Changed = nil }, SearchIndex)
		end
		function SearchIndex:Add(card, metadata)
		    self.Sequence = self.Sequence + 1
		    local entry = {
		        Card = card, Tab = metadata.Tab, Section = metadata.Section or "",
		        Id = metadata.Id ~= nil and tostring(metadata.Id) or "", Order = self.Sequence,
		    }
		    self.Entries[card] = entry
		    if self.Changed then self.Changed() end
		    return entry
		end
		function SearchIndex:Remove(card)
		    self.Entries[card] = nil
		    if self.Changed then self.Changed() end
		end
		function SearchIndex:Search(query, limit)
		    query = self.Fold(query)
		    if query == "" then return {}, 0 end
		    local tokens = {}
		    for token in query:gmatch("%S+") do tokens[#tokens + 1] = token end
		    local matches = {}
		    for _, entry in pairs(self.Entries) do
		        local card = entry.Card
		        if not card.Destroyed and entry.Tab then
		            local title = card.TitleLabel.Text
		            local description = card.DescLabel.Text
		            local path = entry.Tab.Name .. (entry.Section ~= "" and (" / " .. entry.Section) or "")
		            local foldedTitle = self.Fold(title)
		            local haystack = self.Fold(title .. " " .. description .. " " .. path .. " " .. entry.Id)
		            local found = true
		            for _, token in ipairs(tokens) do if not haystack:find(token, 1, true) then found = false; break end end
		            if found then
		                local score = foldedTitle == query and 100 or (foldedTitle:sub(1, #query) == query and 60 or 0)
		                for _, token in ipairs(tokens) do if foldedTitle:find(token, 1, true) then score = score + 10 end end
		                matches[#matches + 1] = { Entry = entry, Title = title, Description = description, Path = path, Score = score }
		            end
		        end
		    end
		    table.sort(matches, function(a, b) return a.Score == b.Score and a.Entry.Order < b.Entry.Order or a.Score > b.Score end)
		    local total = #matches
		    while #matches > (limit or 100) do table.remove(matches) end
		    return matches, total
		end
		function SearchIndex:Destroy() self.Changed = nil; table.clear(self.Entries) end
		return SearchIndex
	end,
	-- Module: MainModule/Appearance
	[58] = function()
		local __context, script, require = getModuleContext(58)
		-- Bloomware UI: background settings shared by Settings and JSON profiles.
		local ContentProvider = game:GetService("ContentProvider")
		local Creator = require(script.Parent.Creator)
		local Assets = require(script.Parent.Components.Assets)
		local Appearance = {}
		Appearance.__index = Appearance
		local scaleLabels = { Crop = "Fill", Fit = "Fit", Stretch = "Stretch" }
		local scaleValues = { Fill = "Crop", Fit = "Fit", Stretch = "Stretch" }
		local function finite(value) return type(value) == "number" and value == value and math.abs(value) < math.huge end
		local function fraction(value, fallback) return finite(value) and math.clamp(value, 0, 1) or fallback end

		function Appearance.ValidateState(state)
		    if type(state) ~= "table" or type(state.Source) ~= "string" then return false end
		    local source = Assets.NormalizeImageSource(state.Source)
		    return source ~= nil and finite(state.Transparency) and state.Transparency >= 0 and state.Transparency <= 1
		        and finite(state.Darkness) and state.Darkness >= 0 and state.Darkness <= 1 and scaleLabels[state.ScaleType] ~= nil
		end

		function Appearance.new(library, config)
		    local self = setmetatable({
		        Library = library, Paint = library.Window.AcrylicPaint, Generation = 0,
		        State = { Source = "", Transparency = fraction(config.BackgroundTransparency, 0.25),
		            Darkness = fraction(config.BackgroundDarkness, 0.35), ScaleType = scaleLabels[config.BackgroundScaleType] and config.BackgroundScaleType or "Crop" },
		        Status = "No background selected. Enter a direct PNG/JPG URL or a Roblox asset ID.",
		    }, Appearance)
		    self:_Render()
		    Creator.AddSignal(library.Window.Root.Destroying, function() self:Destroy() end)
		    if config.BackgroundImage and config.BackgroundImage ~= "" then
		        self:Apply(config.BackgroundImage, true)
		    end
		    return self
		end

		function Appearance:Snapshot()
		    return { Source = self.State.Source, Transparency = self.State.Transparency,
		        Darkness = self.State.Darkness, ScaleType = self.State.ScaleType }
		end

		function Appearance:_Status(message, failed)
		    if self.Destroyed then return end
		    self.Status = message
		    if self.StatusCard then self.StatusCard:SetDesc(message) end
		    if failed then self.Library:Notify({Title = "Appearance", Content = message, Duration = 6}) end
		end

		function Appearance:_Dirty()
		    if self.Library.Profiles then self.Library.Profiles:MarkDirty() end
		end

		function Appearance:_Render()
		    if self.Destroyed then return end
		    local state = self.State
		    self.Paint.BackgroundImage.ImageTransparency = state.Transparency
		    self.Paint.BackgroundImage.ScaleType = Enum.ScaleType[state.ScaleType]
		    self.Paint.BackgroundImage.Visible = state.Source ~= ""
		    self.Paint.BackgroundOverlay.BackgroundTransparency = 1 - state.Darkness
		    self.Paint.BackgroundOverlay.Visible = state.Source ~= ""
		end

		function Appearance:_Sync(includeSource)
		    if not self.Controls or self.Destroyed then return end
		    self.Syncing = true
		    if includeSource then self.Controls.Source:SetValue(self.State.Source) end
		    self.Controls.Transparency:SetValue(self.State.Transparency * 100)
		    self.Controls.Darkness:SetValue(self.State.Darkness * 100)
		    self.Controls.ScaleType:SetValue(scaleLabels[self.State.ScaleType])
		    self.Syncing = false
		end

		function Appearance:SetTransparency(value, quiet)
		    if self.Destroyed or not finite(value) then return false end
		    value = math.clamp(value, 0, 1)
		    local changed = self.State.Transparency ~= value
		    self.State.Transparency = value
		    self:_Render()
		    if changed and not quiet then self:_Dirty() end
		    return true
		end

		function Appearance:SetDarkness(value, quiet)
		    if self.Destroyed or not finite(value) then return false end
		    value = math.clamp(value, 0, 1)
		    local changed = self.State.Darkness ~= value
		    self.State.Darkness = value
		    self:_Render()
		    if changed and not quiet then self:_Dirty() end
		    return true
		end

		function Appearance:SetScaleType(value, quiet)
		    if self.Destroyed or not scaleLabels[value] then return false end
		    local changed = self.State.ScaleType ~= value
		    self.State.ScaleType = value
		    self:_Render()
		    if changed and not quiet then self:_Dirty() end
		    return true
		end

		function Appearance:_Cancel()
		    self.Generation = self.Generation + 1
		    self.Loading = false
		    self.PendingSource = nil
		    if self.Timeout then pcall(task.cancel, self.Timeout); self.Timeout = nil end
		    if self.Probe then self.Probe:Destroy(); self.Probe = nil end
		end

		function Appearance:Clear(quiet)
		    if self.Destroyed then return false end
		    self:_Cancel()
		    local changed = self.State.Source ~= ""
		    self.State.Source = ""
		    self.Paint.BackgroundImage.Image = ""
		    self:_Render()
		    self:_Sync(true)
		    self:_Status("Background removed. You can choose another image.")
		    if changed and not quiet then self:_Dirty() end
		    return true
		end

		function Appearance:Apply(source, quiet)
		    if self.Destroyed then return false, "The interface is closed." end
		    self:_Cancel()
		    local normalized, message = Assets.NormalizeImageSource(source)
		    if not normalized then self:_Status(message, true); return false, message end
		    if normalized == "" then return self:Clear(quiet) end
		    local generation = self.Generation
		    self.Loading = true
		    self.PendingSource = normalized
		    self:_Status("Loading image… The current background will stay until loading finishes.")
		    if self.Controls then self.Controls.Source:SetValue(normalized) end
		    local function current() return not self.Destroyed and self.Generation == generation end
		    local function fail(reason)
		        if not current() then return end
		        self:_Cancel()
		        self:_Status(reason, true)
		    end
		    local function commit(uri)
		        if not current() then return end
		        -- Assign only after URL/file validation, preserving the previous image on error.
		        local assigned = pcall(function() self.Paint.BackgroundImage.Image = uri end)
		        if not assigned then
		            fail("Could not set the background image. Try another PNG/JPG or a Roblox asset ID.")
		            return
		        end
		        self:_Cancel()
		        local changed = self.State.Source ~= normalized
		        self.State.Source = normalized
		        self:_Render()
		        self:_Status("Background applied. Appearance settings are included when saving profiles.")
		        if changed and not quiet then self:_Dirty() end
		    end
		    self.Timeout = task.delay(20, function()
		        self.Timeout = nil
		        fail(normalized:match("^rbxassetid://")
		            and "Roblox image loading timed out. Check the asset ID and try again."
		            or "Image loading took too long. Check the URL and try again.")
		    end)
		    task.spawn(function()
		        local ok, uri, reason = pcall(Assets.ResolveImage, normalized)
		        if not current() then return end
		        if not ok or not uri then fail(ok and reason or "Could not load the image."); return end
		        -- URL images already passed PNG/JPG validation and the local-asset bridge.
		        -- Native PreloadAsync/hidden IsLoaded are not authoritative for these URIs.
		        -- Use the same direct Image assignment as the existing logo loader.
		        if not normalized:match("^rbxassetid://") then commit(uri); return end
		        local probe = Creator.New("ImageLabel", {
		            Name = "BackgroundPreload", BackgroundTransparency = 1, Visible = false,
		            Image = uri, Size = UDim2.fromOffset(1, 1), Parent = self.Library.GUI,
		        })
		        self.Probe = probe
		        Creator.AddSignal(probe:GetPropertyChangedSignal("IsLoaded"), function()
		            if current() and probe.IsLoaded then commit(uri) end
		        end, probe)
		        local fetchStatus
		        local loaded = pcall(function()
		            ContentProvider:PreloadAsync({probe}, function(_, status) fetchStatus = status end)
		        end)
		        if not current() then return end
		        if probe.IsLoaded or fetchStatus == Enum.AssetFetchStatus.Success then
		            commit(uri)
		        elseif not loaded then
		            fail("Could not verify the Roblox asset ID. Try a direct PNG/JPG URL.")
		        elseif fetchStatus == Enum.AssetFetchStatus.Failure then
		            fail("Roblox could not load this image. Check that the asset ID is accessible.")
		        elseif fetchStatus == Enum.AssetFetchStatus.TimedOut then
		            fail("Roblox image loading timed out. Check the asset ID and try again.")
		        else
		            -- A false IsLoaded flag alone is inconclusive. Observe changes until timeout.
		            self:_Status("Waiting for Roblox to load the image…")
		        end
		    end)
		    return true, "Background is loading."
		end

		function Appearance:Restore(state)
		    if self.Destroyed or not Appearance.ValidateState(state) then return false end
		    self:SetTransparency(state.Transparency, true)
		    self:SetDarkness(state.Darkness, true)
		    self:SetScaleType(state.ScaleType, true)
		    self:_Sync(false)
		    return self:Apply(state.Source, true)
		end

		function Appearance:Attach(tab)
		    if self.Destroyed or self.Attached then return end
		    self.Attached = tab
		    local section = tab:AddSection("Appearance")
		    local source = section:AddInput("Bloomware_BackgroundURL", {
		        Title = "Background Image", Description = "Direct PNG/JPG URL or rbxassetid://ID",
		        Default = self.PendingSource or self.State.Source, Placeholder = "https://…/background.png", Finished = true, MaxLength = 4096, IgnoreProfile = true,
		    })
		    section:AddButton({Title = "Apply Background", Description = "Load the image from the URL above",
		        Callback = function() self:Apply(source.Value) end})
		    section:AddButton({Title = "Remove Background", Description = "Restore the default interface background",
		        Callback = function() self:Clear() end})
		    local transparency = section:AddSlider("Bloomware_BackgroundTransparency", {
		        Title = "Image Transparency", Description = "0 = opaque, 100 = invisible",
		        Default = self.State.Transparency * 100, Min = 0, Max = 100, Rounding = 0, IgnoreProfile = true,
		        Callback = function(value) if not self.Syncing then self:SetTransparency(value / 100) end end,
		    })
		    local darkness = section:AddSlider("Bloomware_BackgroundDarkness", {
		        Title = "Background Dimming", Description = "Darken the image to keep text readable",
		        Default = self.State.Darkness * 100, Min = 0, Max = 100, Rounding = 0, IgnoreProfile = true,
		        Callback = function(value) if not self.Syncing then self:SetDarkness(value / 100) end end,
		    })
		    local scaleType = section:AddDropdown("Bloomware_BackgroundScaleType", {
		        Title = "Image Scaling", Values = {"Fill", "Fit", "Stretch"},
		        Default = scaleLabels[self.State.ScaleType], Multi = false, IgnoreProfile = true,
		        Callback = function(value) if not self.Syncing then self:SetScaleType(scaleValues[value]) end end,
		    })
		    self.Controls = {Source = source, Transparency = transparency, Darkness = darkness, ScaleType = scaleType}
		    self.StatusCard = section:AddParagraph({Title = "Interface Background", Content = self.Status})
		end

		-- Reuse Settings from the host script, or add it after the first user tab.
		-- Deferring creation preserves the first tab's index and normal startup page.
		function Appearance:BindWindow(window)
		    local manager, addTab = self, window.AddTab
		    function window:AddTab(options)
		        local title = manager.Library.Search.Fold(options.Title)
		        local isSettings = title == "settings" or title == "настройки"
		        if isSettings and self.AppearanceTab then return self.AppearanceTab end
		        local tab = addTab(self, options)
		        if isSettings then
		            self.AppearanceTab = tab
		            manager:Attach(tab)
		        elseif not self.AppearanceTab and not self._AppearanceScheduled then
		            self._AppearanceScheduled = true
		            task.defer(function()
		                self._AppearanceScheduled = false
		                if not self.Destroyed and not manager.Destroyed and not self.AppearanceTab then
		                    self:AddTab({Title = "Settings", Icon = "settings"})
		                end
		            end)
		        end
		        return tab
		    end
		end

		function Appearance:Destroy()
		    if self.Destroyed then return end
		    self:_Cancel()
		    self.Destroyed = true
		    self.Controls, self.StatusCard, self.Attached = nil, nil, nil
		end

		return Appearance
	end,
}
do
	local taskApi, setMetatable, raiseError, newProxy, getMetatable, nextEntry, tableApi, unpackValues, coroutineApi, originalScript, valueType, originalRequire, protectedCall, originalGetEnvironment, originalSetEnvironment, rawGet =
		task,
		setmetatable,
		error,
		newproxy,
		getmetatable,
		next,
		table,
		unpack,
		coroutine,
		script,
		type,
		require,
		pcall,
		getfenv,
		setfenv,
		rawget
	local insertValue, removeValue, freezeTable, deferTask, environmentVersion, instancesById, factoriesByInstance, cachedModuleResults, scriptsToRun, sharedState, childrenByInstance =
		tableApi.insert, tableApi.remove, tableApi.freeze or function(argument_154)
			return argument_154
		end, taskApi and taskApi.defer or function(argument_155, ...)
			local create_3 = coroutineApi.create(argument_155)
			coroutineApi.resume(create_3, ...)
			return create_3
		end, "0.0.0-venv", {}, {}, {}, {}, {}, {}
	local virtualMethods, checkedVirtualMethods =
		{
			GetChildren = function(argument_156)
				local value_78, object_58 = childrenByInstance[argument_156], {}
				for key_34 in nextEntry, value_78 do
					insertValue(object_58, key_34)
				end
				return object_58
			end,
			FindFirstChild = function(argument_157, argument_158)
				if not argument_158 then
					raiseError("Argument 1 missing or nil", 2)
				end
				for key_35 in nextEntry, childrenByInstance[argument_157] do
					if key_35.Name == argument_158 then
						return key_35
					end
				end
				return
			end,
			GetFullName = function(argument_159)
				local Name, Parent_24 = argument_159.Name, argument_159.Parent
				while Parent_24 do
					Name = Parent_24.Name .. "." .. Name
					Parent_24 = Parent_24.Parent
				end
				return "VirtualEnv." .. Name
			end,
		}, {}
	for key_36, item_35 in nextEntry, virtualMethods do
		checkedVirtualMethods[key_36] = function(argument_160, ...)
			if not childrenByInstance[argument_160] then
				raiseError("Expected ':' not '.' calling member function " .. key_36, 1)
			end
			return item_35(argument_160, ...)
		end
	end
	local createVirtualInstance = function(className, instanceName, parentInstance)
		local instanceChildren, invalidMember, readOnlyProperty, instanceProxy, stringValue =
			setMetatable({}, {
				__mode = "k",
			}), function(argument_161)
				raiseError(argument_161 .. " is not a valid (virtual) member of " .. className .. ' "' .. instanceName .. '"', 1)
			end, function(argument_162)
				raiseError("Unable to assign (virtual) property " .. argument_162 .. ". Property is read only", 1)
			end, (newProxy(true))
		local instanceMetatable = getMetatable(instanceProxy)
		instanceMetatable.__index = function(argument_163, argument_164)
			if argument_164 == "ClassName" then
				return className
			elseif argument_164 == "Name" then
				return instanceName
			elseif argument_164 == "Parent" then
				return parentInstance
			elseif className == "StringValue" and argument_164 == "Value" then
				return stringValue
			else
				local value_79 = checkedVirtualMethods[argument_164]
				if value_79 then
					return value_79
				end
			end
			for key_37 in nextEntry, instanceChildren do
				if key_37.Name == argument_164 then
					return key_37
				end
			end
			invalidMember(argument_164)
		end
		instanceMetatable.__newindex = function(argument_165, argument_166, argument_167)
			if argument_166 == "ClassName" then
				readOnlyProperty(argument_166)
			elseif argument_166 == "Name" then
				instanceName = argument_167
			elseif argument_166 == "Parent" then
				if argument_167 == instanceProxy then
					return
				end
				if parentInstance ~= nil then
					childrenByInstance[parentInstance][instanceProxy] = nil
				end
				parentInstance = argument_167
				if argument_167 ~= nil then
					childrenByInstance[argument_167][instanceProxy] = true
				end
			elseif className == "StringValue" and argument_166 == "Value" then
				stringValue = argument_167
			else
				invalidMember(argument_166)
			end
		end
		instanceMetatable.__tostring = function()
			return instanceName
		end
		childrenByInstance[instanceProxy] = instanceChildren
		if parentInstance ~= nil then
			childrenByInstance[parentInstance][instanceProxy] = true
		end
		return instanceProxy
	end
	local function buildInstanceTree(instanceDefinition, parentInstance_2)
		local instanceId, className_2, properties, childDefinitions =
			instanceDefinition[1], instanceDefinition[2], instanceDefinition[3], instanceDefinition[4]
		local instanceName_2 = removeValue(properties, 1)
		local virtualInstance = createVirtualInstance(className_2, instanceName_2, parentInstance_2)
		instancesById[instanceId] = virtualInstance
		if properties then
			for key_38, item_36 in nextEntry, properties do
				virtualInstance[key_38] = item_36
			end
		end
		if childDefinitions then
			for key_39, item_37 in nextEntry, childDefinitions do
				buildInstanceTree(item_37, virtualInstance)
			end
		end
		return virtualInstance
	end
	local rootInstances = {}
	for key_40, item_38 in nextEntry, moduleTree do
		insertValue(rootInstances, buildInstanceTree(item_38))
	end
	for key_41, item_39 in nextEntry, moduleFactories do
		local value_80 = instancesById[key_41]
		factoriesByInstance[value_80] = item_39
		local ClassName = value_80.ClassName
		if ClassName == "LocalScript" or ClassName == "Script" then
			insertValue(scriptsToRun, value_80)
		end
	end
	local runModule = function(moduleInstance)
		local className_3, cachedResults = moduleInstance.ClassName, cachedModuleResults[moduleInstance]
		if cachedResults and className_3 == "ModuleScript" then
			return unpackValues(cachedResults)
		end
		local moduleFactory = factoriesByInstance[moduleInstance]
		if not moduleFactory then
			return
		end
		if className_3 == "LocalScript" or className_3 == "Script" then
			moduleFactory()
			return
		else
			local object_59 = {
				moduleFactory(),
			}
			cachedModuleResults[moduleInstance] = object_59
			return unpackValues(object_59)
		end
	end
	function getModuleContext(moduleId)
		local moduleInstance_2 = instancesById[moduleId]
		local moduleFactory_2 = factoriesByInstance[moduleInstance_2]
		if not moduleFactory_2 then
			return
		end
		local environmentInitialized, environmentInfo, virtualScript, requireVirtualModule, originalEnvironment, virtualEnvironment, initializeEnvironment =
			false, freezeTable({
				Version = environmentVersion,
				Script = originalScript,
				Shared = sharedState,
				GetScript = function()
					return originalScript
				end,
				GetShared = function()
					return sharedState
				end,
			}), moduleInstance_2, function(argument_168, ...)
				if childrenByInstance[argument_168] and argument_168.ClassName == "ModuleScript" and factoriesByInstance[argument_168] then
					return runModule(argument_168)
				end
				return originalRequire(argument_168, ...)
			end
		local getVirtualEnvironment, setVirtualEnvironment =
			function(argument_169, ...)
				if not environmentInitialized then
					initializeEnvironment()
				end
				if valueType(argument_169) == "number" and argument_169 >= 0 then
					if argument_169 == 0 then
						return virtualEnvironment
					else
						argument_169 = argument_169 + 1
						local protectedCall_2, result_19 = protectedCall(originalGetEnvironment, argument_169)
						if protectedCall_2 and result_19 == originalEnvironment then
							return virtualEnvironment
						end
					end
				end
				return originalGetEnvironment(argument_169, ...)
			end, function(argument_170, argument_171, ...)
				if not environmentInitialized then
					initializeEnvironment()
				end
				if valueType(argument_170) == "number" and argument_170 >= 0 then
					if argument_170 == 0 then
						return originalSetEnvironment(virtualEnvironment, argument_171)
					else
						argument_170 = argument_170 + 1
						local protectedCall_3, result_20 = protectedCall(originalGetEnvironment, argument_170)
						if protectedCall_3 and result_20 == originalEnvironment then
							return originalSetEnvironment(virtualEnvironment, argument_171)
						end
					end
				end
				return originalSetEnvironment(argument_170, argument_171, ...)
			end
		function initializeEnvironment()
			originalEnvironment = originalGetEnvironment(0)
			local object_60 = {
				maui = environmentInfo,
				script = virtualScript,
				require = requireVirtualModule,
				getfenv = getVirtualEnvironment,
				setfenv = setVirtualEnvironment,
			}
			virtualEnvironment = setMetatable({}, {
				__index = function(argument_172, argument_173)
					local rawGet_2 = rawGet(virtualEnvironment, argument_173)
					if rawGet_2 ~= nil then
						return rawGet_2
					end
					local value_81 = object_60[argument_173]
					if value_81 ~= nil then
						return value_81
					end
					return originalEnvironment[argument_173]
				end,
			})
			originalSetEnvironment(moduleFactory_2, virtualEnvironment)
			environmentInitialized = true
		end
		return environmentInfo,
			virtualScript,
			requireVirtualModule,
			getVirtualEnvironment,
			setVirtualEnvironment
	end
	for key_42, item_40 in nextEntry, scriptsToRun do
		deferTask(runModule, item_40)
	end
	do
		local value_82
		for key_43, item_41 in nextEntry, rootInstances do
			if item_41.ClassName == "ModuleScript" and item_41.Name == "MainModule" then
				value_82 = item_41
				break
			end
		end
		if value_82 then
			return runFluentStartup("library initialization", function()
				return runModule(value_82)
			end)
		end
	end
end
