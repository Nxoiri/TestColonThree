
--==============================================================
-- SILLY QoL SUITE
-- Version: 0.2.1
--==============================================================
--
-- INSTALLATION:
-- Execute through your supported Roblox executor while in World Zero.
--
-- SECTIONS:
-- 01. Services
-- 02. Configuration
-- 03. Theme & Design System
-- 04. Runtime & Cleanup Manager
-- 05. UI Helper Functions
-- 06. Main Window & Native Shadows
-- 07. Top Bar
-- 08. Main Layout & Sidebar
-- 09. Page Components
-- 10. Home Page
-- 11. Visuals Page
-- 12. Inventory Page
-- 13. Alerts Page
-- 14. Settings Page
-- 15. Navigation
-- 16. Window Dragging
-- 17. Minimize & Restore
-- 18. Unload System
-- 19. Initialization
--
--==============================================================


--==============================================================
-- SECTION 01 - SERVICES
--==============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CloneReference = cloneref or clonereference or function(instance)
    return instance
end

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")


--==============================================================
-- SECTION 02 - CONFIGURATION
--==============================================================

local CONFIG = {
    Name = "SILLY",
    Version = "0.2.1",

    WindowSize = UDim2.fromOffset(760, 510),

    MinimumSize = Vector2.new(620, 420),

    Accent = Color3.fromRGB(151, 104, 255),
}


--==============================================================
-- SECTION 03 - THEME & DESIGN SYSTEM
--==============================================================

local THEME = {

    -- Main colours
    Background = Color3.fromRGB(17, 17, 23),
    Sidebar = Color3.fromRGB(21, 21, 29),

    Panel = Color3.fromRGB(28, 27, 37),
    PanelLight = Color3.fromRGB(35, 33, 45),

    Border = Color3.fromRGB(53, 49, 65),

    Text = Color3.fromRGB(241, 238, 248),
    Font = Enum.Font.FredokaOne,
    Muted = Color3.fromRGB(151, 146, 166),

    Accent = CONFIG.Accent,
    AccentLight = Color3.fromRGB(183, 148, 255),

    Success = Color3.fromRGB(105, 210, 153),
    Danger = Color3.fromRGB(235, 100, 115),

    -- Corner radius
    Radius = {
        Window = 24,
        Panel = 14,
        Button = 11,
        Modal = 18,
        Logo = 12,
        Toggle = 20,
    },

    -- Animation timings
    Animation = {
        Fast = 0.16,
        Normal = 0.22,
        Slow = 0.35,
    },

    -- Native UIShadow settings
    Shadow = {
        GlowBlur = 34,
        GlowTransparency = 0.48,
        GlowOffset = 10,
        GlowSpread = 8,

        DepthBlur = 24,
        DepthTransparency = 0.65,
    },
}


--==============================================================
-- SECTION 04 - RUNTIME & CLEANUP MANAGER
--==============================================================

local GLOBAL_KEY = "SILLY_QOL_RUNTIME"

-- Clean up an existing SILLY session before starting.
if _G[GLOBAL_KEY] then
    pcall(function()
        _G[GLOBAL_KEY]:Unload()
    end)
end

-- Also remove a leftover interface if one exists.
local PreviousGui = PlayerGui:FindFirstChild("SILLY_Interface")

if PreviousGui then
    PreviousGui:Destroy()
end

local Runtime = {
    Connections = {},
    Instances = {},
    Tweens = {},
    FeatureStates = {},

    Unloaded = false,
}

function Runtime:TrackConnection(connection)
    table.insert(self.Connections, connection)
    return connection
end

function Runtime:TrackInstance(instance)
    table.insert(self.Instances, instance)
    return instance
end

function Runtime:TrackTween(tween)
    table.insert(self.Tweens, tween)
    return tween
end

function Runtime:Connect(signal, callback)
    return self:TrackConnection(signal:Connect(callback))
end

function Runtime:Tween(instance, duration, properties, style)
    if self.Unloaded or not instance then
        return
    end

    local tween = TweenService:Create(
        instance,
        TweenInfo.new(
            duration,
            style or Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        ),
        properties
    )

    self:TrackTween(tween)
    tween:Play()

    return tween
end

function Runtime:Unload()
    if self.Unloaded then
        return
    end

    self.Unloaded = true

    -- Cancel active tweens.
    for _, tween in ipairs(self.Tweens) do
        pcall(function()
            tween:Cancel()
        end)
    end

    -- Disconnect every registered connection.
    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    -- Destroy all tracked instances.
    for _, instance in ipairs(self.Instances) do
        pcall(function()
            instance:Destroy()
        end)
    end

    table.clear(self.Connections)
    table.clear(self.Instances)
    table.clear(self.Tweens)
    table.clear(self.FeatureStates)

    if _G[GLOBAL_KEY] == self then
        _G[GLOBAL_KEY] = nil
    end

    print("[SILLY] Successfully unloaded.")
end

_G[GLOBAL_KEY] = Runtime


--==============================================================
-- SECTION 05 - UI HELPER FUNCTIONS
--==============================================================

local function Create(className, properties, parent)
    local instance = Instance.new(className)

    for property, value in pairs(properties or {}) do
        instance[property] = value
    end

    -- Apply the global font to text objects
    if instance:IsA("TextLabel")
        or instance:IsA("TextButton")
        or instance:IsA("TextBox") then

        instance.Font = THEME.Font
    end

    if parent then
        instance.Parent = parent
    end

    Runtime:TrackInstance(instance)

    return instance
end

local function Corner(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius),
    }, parent)
end

local function Stroke(parent, color, transparency)
    return Create("UIStroke", {
        Color = color or THEME.Border,
        Transparency = transparency or 0,
        Thickness = 1,
    }, parent)
end

local function Padding(parent, left, right, top, bottom)
    return Create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, parent)
end

local function Label(parent, text, size, color, bold)
    return Create("TextLabel", {
        BackgroundTransparency = 1,

        Text = text,
        TextSize = size or 14,
        TextColor3 = color or THEME.Text,

        Font = bold
            and Enum.Font.GothamSemibold
            or Enum.Font.Gotham,

        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,

        TextWrapped = true,
    }, parent)
end

local function Button(parent, text, size)
    local button = Create("TextButton", {
        AutoButtonColor = false,

        Text = text,
        TextSize = 13,

        Font = Enum.Font.GothamMedium,
        TextColor3 = THEME.Text,

        BackgroundColor3 = THEME.PanelLight,

        Size = size or UDim2.fromOffset(100, 34),
    }, parent)

    Corner(button, THEME.Radius.Button)
    Stroke(button, THEME.Border)

    return button
end

local function ApplyPanelShadow(parent)
    -- Softer, centered violet underglow
    Create("UIShadow", {
        Enabled = true,
        Color = THEME.Accent,

        BlurRadius = UDim.new(
            0,
            math.floor(THEME.Shadow.GlowBlur * 0.7)
        ),

        Transparency = math.min(
            0.9,
            THEME.Shadow.GlowTransparency + 0.15
        ),

        Offset = UDim2.fromOffset(0, 0),

        Spread = UDim2.fromOffset(
            math.floor(THEME.Shadow.GlowSpread * 0.6),
            math.floor(THEME.Shadow.GlowSpread * 0.6)
        ),

        ShowBehindParent = true,
        Inset = false,
        Mode = Enum.ApplyShadowMode.Shape,
        ZIndex = -2,
    }, parent)

    -- Keep the subtle depth shadow unchanged
    Create("UIShadow", {
        Enabled = true,
        Color = Color3.fromRGB(0, 0, 0),
        BlurRadius = UDim.new(0, THEME.Shadow.DepthBlur),
        Transparency = THEME.Shadow.DepthTransparency,
        Offset = UDim2.fromOffset(0, 6),
        Spread = UDim2.fromOffset(2, 3),
        ShowBehindParent = true,
        Inset = false,
        Mode = Enum.ApplyShadowMode.Shape,
        ZIndex = -1,
    }, parent)
end

--==============================================================
-- SECTION 06 - MAIN WINDOW & NATIVE SHADOWS
--==============================================================

local ScreenGui = Create("ScreenGui", {
    Name = "SILLY_Interface",

    ResetOnSpawn = false,
    IgnoreGuiInset = true,

    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 50,
}, PlayerGui)

local Main = Create("Frame", {
    Name = "MainWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = CONFIG.WindowSize,
    BackgroundColor3 = THEME.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, ScreenGui)

Corner(Main, 24)
Stroke(Main, THEME.Border)

-- Main window gradient.
Create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(
            0,
            Color3.fromRGB(25, 23, 34)
        ),

        ColorSequenceKeypoint.new(
            1,
            THEME.Background
        ),
    }),

    Rotation = 45,
}, Main)

-- Native violet underglow.
-- Requires Roblox UIShadow support.

local GlowShadow = Create("UIShadow", {
    Enabled = true,

    Color = THEME.Accent,

    BlurRadius = UDim.new(
        0,
        THEME.Shadow.GlowBlur
    ),

    Transparency = THEME.Shadow.GlowTransparency,

    Offset = UDim2.fromOffset(0, 0),

    Spread = UDim2.fromOffset(
        THEME.Shadow.GlowSpread,
        THEME.Shadow.GlowSpread
    ),

    ShowBehindParent = true,
    Inset = false,

    Mode = Enum.ApplyShadowMode.Shape,
    ZIndex = -2,
}, Main)

-- Secondary depth shadow.
local DepthShadow = Create("UIShadow", {
    Enabled = true,

    Color = Color3.fromRGB(0, 0, 0),

    BlurRadius = UDim.new(
        0,
        THEME.Shadow.DepthBlur
    ),

    Transparency = THEME.Shadow.DepthTransparency,

    Offset = UDim2.fromOffset(0, 6),
    Spread = UDim2.fromOffset(2, 3),

    ShowBehindParent = true,
    Inset = false,

    Mode = Enum.ApplyShadowMode.Shape,
    ZIndex = -1,
}, Main)


--==============================================================
-- SECTION 07 - TOP BAR
--==============================================================

local TopBar = Create("Frame", {
    Name = "TopBar",

    Size = UDim2.new(1, 0, 0, 58),

    BackgroundColor3 = Color3.fromRGB(24, 22, 32),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, Main)

local Logo = Create("Frame", {
    Position = UDim2.fromOffset(17, 11),
    Size = UDim2.fromOffset(36, 36),

    BackgroundColor3 = THEME.Accent,
    BorderSizePixel = 0,
}, TopBar)

Corner(Logo, THEME.Radius.Logo)

local LogoText = Label(
    Logo,
    "S",
    22,
    Color3.new(1, 1, 1),
    true
)

LogoText.Size = UDim2.fromScale(1, 1)
LogoText.TextXAlignment = Enum.TextXAlignment.Center

local Title = Label(
    TopBar,
    "SILLY",
    16,
    THEME.Text,
    true
)

Title.Position = UDim2.fromOffset(64, 9)
Title.Size = UDim2.fromOffset(100, 20)

local Subtitle = Label(
    TopBar,
    "QUALITY OF LIFE SUITE",
    9,
    THEME.Muted
)

Subtitle.Position = UDim2.fromOffset(65, 29)
Subtitle.Size = UDim2.fromOffset(180, 15)

local Version = Label(
    TopBar,
    "v" .. CONFIG.Version,
    10,
    THEME.Muted
)

Version.AnchorPoint = Vector2.new(1, 0)
Version.Position = UDim2.new(1, -92, 0, 21)
Version.Size = UDim2.fromOffset(55, 16)

Version.TextXAlignment = Enum.TextXAlignment.Right

local MinimizeButton = Button(
    TopBar,
    "−",
    UDim2.fromOffset(30, 30)
)

MinimizeButton.Position = UDim2.new(1, -76, 0, 14)
MinimizeButton.TextSize = 20

local CloseButton = Button(
    TopBar,
    "×",
    UDim2.fromOffset(30, 30)
)

CloseButton.Position = UDim2.new(1, -38, 0, 14)
CloseButton.TextSize = 19


--==============================================================
-- SECTION 08 - MAIN LAYOUT & SIDEBAR
--==============================================================

local Body = Create("Frame", {
    Name = "Body",

    Position = UDim2.fromOffset(0, 58),

    Size = UDim2.new(1, 0, 1, -58),

    BackgroundTransparency = 1,
}, Main)

local Sidebar = Create("Frame", {
    Name = "Sidebar",

    Size = UDim2.new(0, 165, 1, 0),

    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, Body)

Padding(Sidebar, 12, 12, 18, 12)

Create("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Sidebar)

local WorkspaceLabel = Label(
    Sidebar,
    "WORKSPACE",
    9,
    THEME.Muted,
    true
)

WorkspaceLabel.Size = UDim2.new(1, 0, 0, 22)
WorkspaceLabel.LayoutOrder = 0

local Content = Create("Frame", {
    Name = "Content",

    Position = UDim2.fromOffset(165, 0),

    Size = UDim2.new(1, -165, 1, 0),

    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, Body)


--==============================================================
-- SECTION 09 - PAGE COMPONENTS
--==============================================================

local Pages = {}
local PageGroups = {}

local function CreatePage(name)
    -- CanvasGroup is the visual wrapper used for page-level fading/sliding.
    local group = Create("CanvasGroup", {
        Name = name .. "Group",

        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -12, 1, -12),

        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        ClipsDescendants = true,
        GroupTransparency = 0,
        Visible = false,
    }, Content)

    -- Keep the ScrollingFrame responsible for scrolling and page layout.
    local page = Create("ScrollingFrame", {
        Name = name,

        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromScale(1, 1),

        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        ScrollBarThickness = 3,
        ScrollBarImageColor3 = THEME.Accent,

        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,

        Visible = true,
    }, group)

    Padding(page, 22, 22, 22, 22)

    Create("UIListLayout", {
        Padding = UDim.new(0, 14),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)

    Pages[name] = page
    PageGroups[name] = group

    return page
end

local function PageHeader(parent, title, description)
    local container = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 55),
    }, parent)

    local heading = Label(
        container,
        title,
        23,
        THEME.Text,
        true
    )

    heading.Size = UDim2.new(1, 0, 0, 30)

    local sub = Label(
        container,
        description,
        11,
        THEME.Muted
    )

    sub.Position = UDim2.fromOffset(0, 30)
    sub.Size = UDim2.new(1, 0, 0, 19)

    return container
end

local function Section(parent, title)
    local section = Create("Frame", {
        BackgroundColor3 = THEME.Panel,

        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, parent)

    Corner(section, THEME.Radius.Panel)

    -- Thicker section border
    local outline = Stroke(section, THEME.Border)
    outline.Thickness = 2

    -- Violet underglow and depth shadow
    ApplyPanelShadow(section)

    Padding(section, 14, 14, 12, 12)

    Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, section)

    local heading = Label(
        section,
        title,
        13,
        THEME.Text,
        true
    )

    heading.Size = UDim2.new(1, 0, 0, 22)
    heading.LayoutOrder = 0

    return section
end

local function InfoCardPlain(parent, title, description)
    local card = Create("Frame", {
        BackgroundColor3 = THEME.Panel,

        Size = UDim2.new(1, 0, 0, 68),
    }, parent)

    Corner(card, THEME.Radius.Panel)
    Stroke(card, THEME.Border)

    Padding(card, 12, 12, 10, 10)

    local heading = Label(
        card,
        title,
        12,
        THEME.Text,
        true
    )

    heading.Size = UDim2.new(1, 0, 0, 20)

    local sub = Label(
        card,
        description,
        10,
        THEME.Muted
    )

    sub.Position = UDim2.fromOffset(0, 23)
    sub.Size = UDim2.new(1, 0, 0, 28)

    return card
end

local function InfoCard(parent, title, description)
    local card = Create("Frame", {
        BackgroundColor3 = THEME.Panel,

        Size = UDim2.new(1, 0, 0, 68),
    }, parent)

    Corner(card, THEME.Radius.Panel)
    Stroke(card, THEME.Border)
    ApplyPanelShadow(card)

    Padding(card, 12, 12, 10, 10)

    local heading = Label(
        card,
        title,
        12,
        THEME.Text,
        true
    )

    heading.Size = UDim2.new(1, 0, 0, 20)

    local sub = Label(
        card,
        description,
        10,
        THEME.Muted
    )

    sub.Position = UDim2.fromOffset(0, 23)
    sub.Size = UDim2.new(1, 0, 0, 28)

    return card
end

local function Toggle(parent, title, description, default, callback)
    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
    }, parent)

    local titleLabel = Label(
        row,
        title,
        12,
        THEME.Text,
        true
    )

    titleLabel.Size = UDim2.new(1, -65, 0, 20)

    local descLabel = Label(
        row,
        description,
        10,
        THEME.Muted
    )

    descLabel.Position = UDim2.fromOffset(0, 21)
    descLabel.Size = UDim2.new(1, -65, 0, 17)

    local switch = Create("TextButton", {
        AutoButtonColor = false,
        Text = "",

        Size = UDim2.fromOffset(38, 21),
        Position = UDim2.new(1, -42, 0.5, -10),

        BackgroundColor3 = default
            and THEME.Accent
            or THEME.PanelLight,
    }, row)

    Corner(switch, THEME.Radius.Toggle)

    local knob = Create("Frame", {
        Size = UDim2.fromOffset(15, 15),

        Position = default
            and UDim2.fromOffset(20, 3)
            or UDim2.fromOffset(3, 3),

        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, switch)

    Corner(knob, THEME.Radius.Toggle)

    local enabled = default == true

    local function Update(value)
        if Runtime.Unloaded then
            return
        end

        enabled = value
        Runtime.FeatureStates[title] = enabled

        Runtime:Tween(switch, THEME.Animation.Fast, {
            BackgroundColor3 = enabled
                and THEME.Accent
                or THEME.PanelLight,
        })

        Runtime:Tween(knob, THEME.Animation.Fast, {
            Position = enabled
                and UDim2.fromOffset(20, 3)
                or UDim2.fromOffset(3, 3),
        })

        if callback then
            callback(enabled)
        end
    end

    Runtime.FeatureStates[title] = enabled

    Runtime:Connect(switch.Activated, function()
        Update(not enabled)
    end)

    return {
        Set = Update,

        Get = function()
            return enabled
        end,
    }
end


--==============================================================
-- SECTION 10 - HOME PAGE
--==============================================================

local HomePage = CreatePage("Home")

PageHeader(
    HomePage,
    "Welcome to SILLY",
    "Your personal quality-of-life control centre."
)


local QuickSection = Section(HomePage, "Quick Controls")

Toggle(
    QuickSection,
    "Enhanced Lighting",
    "Local environment adjustments.",
    false
)

Toggle(
    QuickSection,
    "Reduce Particles",
    "Reduce excessive visual effects.",
    false
)

InfoCard(
    HomePage,
    "Build Information",
    "Version " .. CONFIG.Version
        .. " | Client-side interface foundation"
)


--==============================================================
-- SECTION 11 - VISUALS PAGE
--==============================================================

local VisualsPage = CreatePage("Visuals")

PageHeader(
    VisualsPage,
    "Visuals",
    "Customize your local game experience."
)

local EnvironmentSection = Section(
    VisualsPage,
    "Environment"
)

Toggle(
    EnvironmentSection,
    "Enhanced Lighting",
    "Adjust local lighting and atmosphere.",
    false
)

Toggle(
    EnvironmentSection,
    "Reduce Particles",
    "Reduce excessive particle effects.",
    false
)

Toggle(
    EnvironmentSection,
    "Disable Screen Effects",
    "Optional local visual effect reduction.",
    false
)

local EntitySection = Section(
    VisualsPage,
    "Entity Highlighting"
)

local MobESPConnection

local function SetMobESP(enabled)
    if game.GameId ~= 985731078 then
        return
    end

    local mobs = workspace:FindFirstChild("Mobs")
    if not mobs then
        warn("[SILLY] World Zero Mobs folder was not found.")
        return
    end

    local function addHighlight(mob)
        if not mob or not mob.Parent then
            return
        end

        local existing = mob:FindFirstChild("LarpZeroMobHighlight")
        if existing then
            return
        end

        local highlight = Instance.new("Highlight")
        highlight.Name = "LarpZeroMobHighlight"
        highlight.FillTransparency = 0
        highlight.Parent = mob
        Runtime:TrackInstance(highlight)
    end

    if enabled then
        for _, mob in ipairs(mobs:GetChildren()) do
            addHighlight(mob)
        end

        if MobESPConnection then
            MobESPConnection:Disconnect()
        end

        MobESPConnection = Runtime:Connect(mobs.ChildAdded, addHighlight)
    else
        if MobESPConnection then
            MobESPConnection:Disconnect()
            MobESPConnection = nil
        end

        for _, mob in ipairs(mobs:GetChildren()) do
            local highlight = mob:FindFirstChild("LarpZeroMobHighlight", true)
            if highlight then
                highlight:Destroy()
            end
        end
    end
end

Toggle(
    EntitySection,
    "Mob ESP",
    "Highlight current and newly spawned World Zero mobs.",
    false,
    SetMobESP
)



--==============================================================
-- SECTION 12 - INVENTORY PAGE
--==============================================================

local InventoryPage = CreatePage("Inventory")

PageHeader(
    InventoryPage,
    "Inventory",
    "Manage your item-related preferences."
)

local SellSection = Section(
    InventoryPage,
    "Auto Sell"
)

local WorldZeroId = 985731078
local AutoSellEnabled = false
local ProtectRareItems = true
local IncludePets = false
local IncludeCharms = false
local SellTowerEggs = false
local TowerEggs = {
    MoltenEgg = true,
    OceanEgg = true,
    SkyEgg = true,
    AlligatorEgg = true,
    FairyEgg = true,
    ArcaneEgg = true,
}
local AutoSellGeneration = 0
local InventoryBusy = setmetatable({}, {__mode = "k"})
local AutoHatchGeneration = 0
local AutoHatchInventoryGeneration = 0
local AutoHatchToggle
local InventoryEggHatchToggle
local UpgradeBusy = {}

local function IsWorldZero()
    return game.GameId == WorldZeroId
end

local function GetWorldZeroObjects()
    if not IsWorldZero() then
        error("This feature is only available in World Zero.")
    end

    local shared = ReplicatedStorage:WaitForChild("Shared", 10)
    if not shared then
        error("ReplicatedStorage.Shared was not found.")
    end

    local profileGui = PlayerGui:WaitForChild("Profile", 10)
    if not profileGui then
        error("PlayerGui.Profile was not found.")
    end

    local profileInventory = profileGui:WaitForChild("Inventory", 10)
    local itemsFolder = profileInventory and profileInventory:WaitForChild("Items", 10)

    if not itemsFolder then
        error("The player inventory items folder was not found.")
    end

    return {
        Shared = shared,
        Profile = profileGui,
        ProfileInventory = profileInventory,
        Items = itemsFolder,
        Remotes = ReplicatedStorage:WaitForChild("Remotes", 10),
    }
end

local function GameCall(callback, ...)
    local setter = setthreadidentity or setidentity
    local getter = getthreadidentity or getidentity
    local previous, changed

    if type(setter) == "function" and type(getter) == "function" then
        local ok, value = pcall(getter)
        if ok then
            previous = value
            changed = pcall(setter, 2)
        end
    end

    local results = table.pack(pcall(callback, ...))

    if changed then
        pcall(setter, previous)
    end

    return table.unpack(results, 1, results.n)
end

local InventoryPolicy = {}

function InventoryPolicy.Tier(value)
    local labels = {
        ["none"] = 0,
        ["0"] = 0,
        ["3"] = 3,
        ["3-5"] = 3,
        ["4"] = 4,
        ["4-5"] = 4,
        ["5"] = 5,
    }

    return labels[tostring(value)]
end

function InventoryPolicy.ShouldSell(item, config)
    if item.protected or item.equipped or item.stackable then
        return false
    end

    if item.towerEgg then
        return config.sellTowerEggs == true
    end

    if item.kind ~= "Weapon"
        and item.kind ~= "Armor"
        and item.kind ~= "Pet"
        and item.kind ~= "Charm" then
        return false
    end

    if item.kind == "Pet" and not config.includePets then
        return false
    end

    if item.kind == "Charm" and not config.includeCharms then
        return false
    end

    if type(item.rarity) ~= "number" or item.rarity == 7 then
        return false
    end

    local tier = InventoryPolicy.Tier(config.keepTier)
    if tier == nil then
        return false
    end

    if tier > 0 and item.rarity > tier then
        return false
    end

    if config.keepPerks then
        for name, value in pairs(item.perks or {}) do
            local selected = (config.selectedPerks or {})[name]
            if selected then
                local pet = item.kind == "Pet" or item.kind == "Charm"
                local threshold = pet and selected.PetPerkValue or selected.PerkValue
                local range = selected.Ranges and selected.Ranges[item.kind]

                if range then
                    threshold = range[selected.LowerMax and 1 or 2]
                end

                threshold = tonumber(threshold or selected.PerkValue)
                value = tonumber(value)

                if not threshold or not value then
                    return false
                end

                if selected.NegativeActive and value < 0 then
                    value = -value
                end

                value = math.floor(value * 100 + 0.5) / 100
                local offset = tonumber(config.offset) or 0

                if selected.LowerMax then
                    if value <= threshold + offset then
                        return false
                    end
                elseif value >= threshold - offset then
                    return false
                end
            end
        end
    end

    return true
end

local function SellItem(item, dropsModule)
    local done, ok, result = false, false, nil

    task.spawn(function()
        ok, result = GameCall(function()
            return dropsModule:SellItems(Player, {item})
        end)
        done = true
    end)

    local deadline = os.clock() + 8
    repeat
        task.wait(0.1)
    until done or Runtime.Unloaded or os.clock() >= deadline

    if not done or not ok then
        return false
    end

    return type(result) == "number" and result > 0
end

local function IsProtectedInventoryItem(item)
    if not item then
        return true
    end

    for _, key in ipairs({"Locked", "Favorited", "GiftWrap", "OnExpedition"}) do
        if item:FindFirstChild(key) or item:GetAttribute(key) == true then
            return true
        end
    end

    return false
end

local function GetItemRarity(item, itemData)
    local reference = itemData[item.Name]
    if not reference then
        return nil, nil
    end

    local rarity = reference.Rarity

    if reference.Type == "Pet" then
        local variant = item:FindFirstChild("Variant")
        local variantData = variant and reference.Variants and reference.Variants[variant.Value]
        rarity = variantData and variantData[4]
    end

    if reference.Type ~= "Weapon"
        and reference.Type ~= "Armor"
        and reference.Type ~= "Pet"
        and reference.Type ~= "Charm" then
        return nil, reference.Type
    end

    return type(rarity) == "number" and rarity or nil, reference.Type
end

local function SellInventoryItem(item, context, itemData, dropsModule)
    if not item or InventoryBusy[item] or item.Parent ~= context.Items then
        return false
    end

    InventoryBusy[item] = true

    local success, sold = pcall(function()
        if IsProtectedInventoryItem(item) or item:FindFirstChild("Count") then
            return false
        end

        local rarity, kind = GetItemRarity(item, itemData)

        local state = {
            kind = kind,
            rarity = rarity,
            perks = {},
            protected = IsProtectedInventoryItem(item),
            stackable = item:FindFirstChild("Count") ~= nil,
            equipped = false,
            towerEgg = TowerEggs[item.Name] == true,
        }

        local config = {
            keepTier = ProtectRareItems and 5 or 0,
            includePets = IncludePets,
            includeCharms = IncludeCharms,
            sellTowerEggs = SellTowerEggs,
            keepPerks = false,
            selectedPerks = {},
            offset = 0,
        }

        if not InventoryPolicy.ShouldSell(state, config) then
            return false
        end

        return SellItem(item, dropsModule)
    end)

    InventoryBusy[item] = nil

    if success and sold then
        print("[SILLY] Sold inventory item: " .. item.Name)
        return true
    end

    return false
end

local function ProcessInventoryItem(item, generation, context, itemData, dropsModule)
    task.delay(1, function()
        if Runtime.Unloaded
            or generation ~= AutoSellGeneration
            or not AutoSellEnabled
            or not context.Items
            or item.Parent ~= context.Items then
            return
        end

        SellInventoryItem(item, context, itemData, dropsModule)
    end)
end

local function StartAutoSell(enabled)
    AutoSellGeneration += 1
    local generation = AutoSellGeneration
    AutoSellEnabled = enabled

    if not enabled then
        return
    end

    if not IsWorldZero() then
        AutoSellEnabled = false
        warn("[SILLY] Auto Sell is only available in World Zero.")
        return
    end

    task.spawn(function()
        local ok, context = pcall(GetWorldZeroObjects)
        if not ok or Runtime.Unloaded or generation ~= AutoSellGeneration then
            warn("[SILLY] Auto Sell could not access the inventory.")
            return
        end

        local moduleOk, itemData, dropsModule = pcall(function()
            local itemsModule = require(context.Shared:WaitForChild("Items", 10))
            local drops = require(context.Shared:WaitForChild("Drops", 10))
            return itemsModule, drops
        end)

        if not moduleOk or not itemData or not dropsModule then
            warn("[SILLY] Auto Sell could not load the original inventory modules.")
            return
        end

        local watched = setmetatable({}, {__mode = "k"})
        local queued = setmetatable({}, {__mode = "k"})

        local function enqueue(item)
            if not item or queued[item] then
                return
            end

            watched[item] = true
            queued[item] = true

            task.delay(0.25, function()
                queued[item] = nil
                if generation == AutoSellGeneration
                    and AutoSellEnabled
                    and not Runtime.Unloaded
                    and item.Parent == context.Items then
                    ProcessInventoryItem(item, generation, context, itemData, dropsModule)
                end
            end)
        end

        Runtime:Connect(context.Items.ChildAdded, enqueue)
        Runtime:Connect(context.Items.DescendantAdded, function(child)
            local item = child
            while item and item.Parent ~= context.Items do
                item = item.Parent
            end
            if item then
                enqueue(item)
            end
        end)
    end)
end

local function UpgradeToMax(slotName)
    if UpgradeBusy[slotName] or not IsWorldZero() or Runtime.Unloaded then
        return
    end

    UpgradeBusy[slotName] = true

    task.spawn(function()
        local ok, err = pcall(function()
            local equips = ReplicatedStorage:WaitForChild("PlayerEquips", 10)
            local playerEquips = equips and equips:FindFirstChild(Player.Name)
            local slot = playerEquips and playerEquips:FindFirstChild(slotName)
            local item = slot and slot:FindFirstChildWhichIsA("Folder")
            if not item then
                return
            end

            local shared = ReplicatedStorage:WaitForChild("Shared", 10)
            local upgrades = require(shared:WaitForChild("ItemUpgrade", 10))
            local profiles = require(shared:WaitForChild("Profile", 10))
            local profileGui = PlayerGui:WaitForChild("Profile", 10)

            for _ = 1, 150 do
                if Runtime.Unloaded or item.Parent ~= slot then
                    break
                end

                if upgrades:GetUpgrade(item) >= upgrades:GetUpgradeLimit(item) then
                    break
                end

                local cost = upgrades:GetUpgradeCostForItem(item)
                if type(cost) ~= "number" or profiles:GetGold(profileGui) < cost then
                    break
                end

                upgrades:UpgradeItem(Player, item, false)
                task.wait(0.4)
            end

            print("[SILLY] " .. slotName .. " upgrade: "
                .. tostring(upgrades:GetUpgrade(item)) .. "/"
                .. tostring(upgrades:GetUpgradeLimit(item)))
        end)

        if not ok then
            warn("[SILLY] " .. slotName .. " upgrade failed: " .. tostring(err))
        end

        UpgradeBusy[slotName] = nil
    end)
end

local EggOptions = {
    StarEgg = {VisualName = "Star egg", CoinPrice = 2000, CurrencyType = "Gold"},
    JungleEgg = {VisualName = "Jungle egg", CoinPrice = 5000, CurrencyType = "Gold"},
    CrystalEgg = {VisualName = "Crystal egg", CoinPrice = 7500, CurrencyType = "Gold"},
    DesertEgg = {VisualName = "Pharaoh's egg", CoinPrice = 10000, CurrencyType = "Gold"},
    ChristmasEgg = {VisualName = "Holiday egg", CoinPrice = 400, CurrencyType = "Crystal"},
}

local SelectedEggKey = "StarEgg"
local HatchDelay = 0.5

local InventoryEggNames = {
    "StarEgg", "JungleEgg", "CrystalEgg", "ChristmasEgg", "DesertEgg",
    "MoltenEgg", "OceanEgg", "SkyEgg", "CatEgg", "CatEggHalloween",
    "AlligatorEgg", "FairyEgg", "AetherEgg", "CabbageEgg", "SkeletonEgg",
    "CupidEgg", "SlimeEgg", "TeddyEgg", "SantaEgg", "ArcaneEgg",
    "GhostEgg", "PenguinEgg", "RobloxEventEggHatchable", "GoldenEgg", "MiseryEgg",
    "BunnyEgg", "RheaEgg", "SuperCrystalEgg", "SuperDesertEgg", "SuperFairyEgg",
    "SuperStarEgg", "SuperMoltenEgg", "VoidEgg", "SuperArcaneEgg", "EasterPetEgg",
    "SuperSkyEgg", "SuperAlligatorEgg", "SuperOceanEgg", "SuperJungleEgg",
}

local InventoryEggSet = {}
for _, eggName in ipairs(InventoryEggNames) do
    InventoryEggSet[eggName] = true
end

local function BuySelectedEgg(context, eggKey)
    local egg = EggOptions[eggKey]
    if not egg then
        return false
    end

    local buyEgg = context.Remotes:FindFirstChild("Pets_BuyEgg")
    if not buyEgg then
        return false
    end

    if egg.CurrencyType == "Gold" then
        local currency = context.Profile:FindFirstChild("Currency")
        local gold = currency and currency:FindFirstChild("Gold")
        if not gold or tonumber(gold.Value) < egg.CoinPrice then
            return false
        end
    elseif egg.CurrencyType == "Crystal" then
        local getCrystals = context.Remotes:FindFirstChild("Crystals_GetCrystals")
        local crystals = getCrystals and getCrystals:InvokeServer()
        if type(crystals) ~= "number" or crystals < egg.CoinPrice then
            return false
        end
    end

    buyEgg:FireServer(eggKey, egg.CurrencyType)
    return true
end

local function RunAutoHatch(enabled)
    AutoHatchGeneration += 1
    local generation = AutoHatchGeneration

    if not enabled then
        return
    end

    if not IsWorldZero() then
        warn("[SILLY] Auto Hatch is only available in World Zero.")
        return
    end

    task.spawn(function()
        local ok, err = pcall(function()
            local context = GetWorldZeroObjects()
            local playerEquips = ReplicatedStorage:WaitForChild("PlayerEquips", 10)
            local petSlot = playerEquips:WaitForChild(Player.Name, 10):WaitForChild("Pet", 10)
            local inventoryModule = require(context.Shared:WaitForChild("Inventory", 10))
            local hatchRemote = context.Remotes:WaitForChild("Pets_Hatch", 10)

            while not Runtime.Unloaded and generation == AutoHatchGeneration do
                local currentPet = petSlot:FindFirstChildWhichIsA("Folder")
                if currentPet and currentPet.Name:find("Egg") then
                    task.wait(0.1)
                    continue
                end

                task.wait(HatchDelay)
                if Runtime.Unloaded or generation ~= AutoHatchGeneration then
                    break
                end

                if not BuySelectedEgg(context, SelectedEggKey) then
                    warn("[SILLY] Unable to buy selected egg. Check your balance and egg key.")
                    task.wait(3)
                    continue
                end

                local egg = context.Items:WaitForChild(SelectedEggKey, 5)
                if egg and not IsProtectedInventoryItem(egg) then
                    inventoryModule:EquipItemClient(egg, petSlot)
                    local deadline = os.clock() + 5
                    repeat
                        task.wait(0.1)
                    until petSlot:FindFirstChild(SelectedEggKey)
                        or Runtime.Unloaded
                        or generation ~= AutoHatchGeneration
                        or os.clock() >= deadline

                    if not Runtime.Unloaded
                        and generation == AutoHatchGeneration
                        and petSlot:FindFirstChild(SelectedEggKey) then
                        hatchRemote:FireServer()
                    end
                end

                task.wait()
            end
        end)

        if not ok then
            warn("[SILLY] Auto Hatch stopped: " .. tostring(err))
        end
    end)
end

local function RunInventoryEggHatch(enabled)
    AutoHatchInventoryGeneration += 1
    local generation = AutoHatchInventoryGeneration

    if not enabled then
        return
    end

    if not IsWorldZero() then
        warn("[SILLY] Inventory Egg Hatch is only available in World Zero.")
        return
    end

    task.spawn(function()
        local ok, err = pcall(function()
            local context = GetWorldZeroObjects()
            local playerEquips = ReplicatedStorage:WaitForChild("PlayerEquips", 10)
            local petSlot = playerEquips:WaitForChild(Player.Name, 10):WaitForChild("Pet", 10)
            local inventoryModule = require(context.Shared:WaitForChild("Inventory", 10))
            local hatchRemote = context.Remotes:WaitForChild("Pets_Hatch", 10)

            while not Runtime.Unloaded and generation == AutoHatchInventoryGeneration do
                local currentPet = petSlot:FindFirstChildWhichIsA("Folder")
                if currentPet and InventoryEggSet[currentPet.Name] then
                    task.wait(0.1)
                    continue
                end

                local hatched = false
                for _, item in ipairs(context.Items:GetChildren()) do
                    if Runtime.Unloaded or generation ~= AutoHatchInventoryGeneration then
                        break
                    end

                    if InventoryEggSet[item.Name]
                        and item.Parent == context.Items
                        and not IsProtectedInventoryItem(item) then
                        task.wait(HatchDelay)

                        if Runtime.Unloaded or generation ~= AutoHatchInventoryGeneration then
                            break
                        end

                        inventoryModule:EquipItemClient(item, petSlot)
                        local equippedEgg = petSlot:WaitForChild(item.Name, 5)
                        if equippedEgg then
                            task.wait(0.5)
                            if Runtime.Unloaded or generation ~= AutoHatchInventoryGeneration then
                                break
                            end
                            hatchRemote:FireServer()
                            task.wait(5)
                            hatched = true
                            break
                        end
                    end
                end

                if not hatched then
                    task.wait(5)
                end
            end
        end)

        if not ok then
            warn("[SILLY] Inventory Egg Hatch stopped: " .. tostring(err))
        end
    end)
end

Toggle(
    SellSection,
    "Enable Auto Sell",
    "Auto-sell eligible new weapons and armor using the old selling adapter.",
    false,
    StartAutoSell
)

Toggle(
    SellSection,
    "Protect Rare Items",
    "Keep rarity tiers above the old script's default sell threshold.",
    true,
    function(enabled)
        ProtectRareItems = enabled
    end
)

Toggle(
    SellSection,
    "Sell Pets",
    "Allow the old auto-sell policy to include pets.",
    false,
    function(enabled)
        IncludePets = enabled
    end
)

Toggle(
    SellSection,
    "Sell Charms",
    "Allow the old auto-sell policy to include charms.",
    false,
    function(enabled)
        IncludeCharms = enabled
    end
)

Toggle(
    SellSection,
    "Sell Tower Eggs",
    "Allow the old policy to sell eligible tower eggs.",
    false,
    function(enabled)
        SellTowerEggs = enabled
    end
)

local ManualSellButton = Button(
    InventoryPage,
    "Sell Eligible Inventory",
    UDim2.new(1, 0, 0, 38)
)

local UpgradeSection = Section(InventoryPage, "Gear Upgrades")

local UpgradePrimaryButton = Button(UpgradeSection, "Upgrade Primary to Max", UDim2.new(1, 0, 0, 36))
local UpgradeOffhandButton = Button(UpgradeSection, "Upgrade Offhand to Max", UDim2.new(1, 0, 0, 36))
local UpgradeArmorButton = Button(UpgradeSection, "Upgrade Armor to Max", UDim2.new(1, 0, 0, 36))

Runtime:Connect(UpgradePrimaryButton.Activated, function()
    UpgradeToMax("Primary")
end)
Runtime:Connect(UpgradeOffhandButton.Activated, function()
    UpgradeToMax("Offhand")
end)
Runtime:Connect(UpgradeArmorButton.Activated, function()
    UpgradeToMax("Armor")
end)

local ManualSellArmed = false

Runtime:Connect(ManualSellButton.Activated, function()
    if not ManualSellArmed then
        ManualSellArmed = true
        ManualSellButton.Text = "Confirm Sell Inventory"
        task.delay(2, function()
            if not Runtime.Unloaded and ManualSellArmed then
                ManualSellArmed = false
                ManualSellButton.Text = "Sell Eligible Inventory"
            end
        end)
        return
    end

    ManualSellArmed = false
    ManualSellButton.Text = "Sell Eligible Inventory"

    if not IsWorldZero() then
        warn("[SILLY] Manual inventory selling is only available in World Zero.")
        return
    end

    task.spawn(function()
        local ok, context = pcall(GetWorldZeroObjects)
        if not ok then
            warn("[SILLY] Could not access the inventory.")
            return
        end

        local moduleOk, itemData, dropsModule = pcall(function()
            return require(context.Shared:WaitForChild("Items", 10)),
                require(context.Shared:WaitForChild("Drops", 10))
        end)

        if not moduleOk then
            warn("[SILLY] Could not load inventory selling modules.")
            return
        end

        for _, item in ipairs(context.Items:GetChildren()) do
            if Runtime.Unloaded then
                break
            end
            SellInventoryItem(item, context, itemData, dropsModule)
            task.wait(0.1)
        end
    end)
end)

local EggSection = Section(InventoryPage, "Auto Egg Hatch")

local EggKeyInput = Create("TextBox", {
    Name = "EggKeyInput",
    ClearTextOnFocus = false,
    PlaceholderText = "Egg key: StarEgg, JungleEgg, CrystalEgg, DesertEgg, ChristmasEgg",
    Text = SelectedEggKey,
    TextSize = 10,
    TextColor3 = THEME.Text,
    PlaceholderColor3 = THEME.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundColor3 = THEME.PanelLight,
    Size = UDim2.new(1, 0, 0, 38),
}, EggSection)

Corner(EggKeyInput, THEME.Radius.Button)
Stroke(EggKeyInput, THEME.Border)
Padding(EggKeyInput, 10, 10, 0, 0)

local HatchDelayInput = Create("TextBox", {
    Name = "HatchDelayInput",
    ClearTextOnFocus = false,
    PlaceholderText = "Hatch delay in seconds (0 - 10)",
    Text = tostring(HatchDelay),
    TextSize = 11,
    TextColor3 = THEME.Text,
    PlaceholderColor3 = THEME.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundColor3 = THEME.PanelLight,
    Size = UDim2.new(1, 0, 0, 34),
}, EggSection)

Corner(HatchDelayInput, THEME.Radius.Button)
Stroke(HatchDelayInput, THEME.Border)
Padding(HatchDelayInput, 10, 10, 0, 0)

local EggKeyStatus = Label(EggSection, "Known eggs: StarEgg, JungleEgg, CrystalEgg, DesertEgg, ChristmasEgg.", 10, THEME.Muted)
EggKeyStatus.Size = UDim2.new(1, 0, 0, 28)

Runtime:Connect(EggKeyInput.FocusLost, function()
    local key = EggKeyInput.Text:match("^%s*(.-)%s*$")
    if EggOptions[key] then
        SelectedEggKey = key
        EggKeyStatus.Text = "Selected: " .. key .. " (" .. EggOptions[key].CurrencyType .. ")"
    else
        EggKeyStatus.Text = "Unknown egg key. Choose one of the five listed above."
    end
end)

Runtime:Connect(HatchDelayInput.FocusLost, function()
    local value = tonumber(HatchDelayInput.Text)
    if value then
        HatchDelay = math.clamp(value, 0, 10)
        HatchDelayInput.Text = tostring(HatchDelay)
    else
        HatchDelayInput.Text = tostring(HatchDelay)
    end
end)

AutoHatchToggle = Toggle(
    EggSection,
    "Auto Hatch Selected Egg",
    "Buy the selected egg, equip it, and hatch it using the original loop.",
    false,
    function(enabled)
        if enabled and InventoryEggHatchToggle then
            InventoryEggHatchToggle.Set(false)
        end
        RunAutoHatch(enabled)
    end
)

InventoryEggHatchToggle = Toggle(
    EggSection,
    "Hatch Eggs in Inventory",
    "Equip and hatch stored eggs without buying new ones.",
    false,
    function(enabled)
        if enabled and AutoHatchToggle then
            AutoHatchToggle.Set(false)
        end
        RunInventoryEggHatch(enabled)
    end
)

InfoCardPlain(
    InventoryPage,
    "Original Logic Port",
    "Selling, gear upgrades, and egg hatching use the World Zero modules and remotes referenced by the old SILLY script. Locked and protected items are skipped."
)


--==============================================================
-- SECTION 13 - ALERTS PAGE
--==============================================================

local AlertsPage = CreatePage("Alerts")

PageHeader(
    AlertsPage,
    "Notifications",
    "Configure the alerts displayed by SILLY."
)

local ItemAlerts = Section(
    AlertsPage,
    "Item Notifications"
)

Toggle(
    ItemAlerts,
    "New Item Acquired",
    "Notify when a new item is obtained.",
    true
)

Toggle(
    ItemAlerts,
    "Rare Drop Alerts",
    "Notify when a rare item is obtained.",
    true
)

InfoCard(
    AlertsPage,
    "Notification History",
    "Your recent item and drop notifications will appear here once implemented."
)


--==============================================================
-- SECTION 14 - SETTINGS PAGE
--==============================================================

local SettingsPage = CreatePage("Settings")

PageHeader(
    SettingsPage,
    "Settings",
    "Personalize your SILLY experience."
)

local InterfaceSection = Section(
    SettingsPage,
    "Interface"
)

Toggle(
    InterfaceSection,
    "Show Version",
    "Display the version in the title bar.",
    true,
    function(enabled)
        Version.Visible = enabled
    end
)

Toggle(
    InterfaceSection,
    "Animations",
    "Enable interface transitions.",
    true
)

local AboutSection = Section(
    SettingsPage,
    "About"
)

InfoCardPlain(
    AboutSection,
    "SILLY QoL Suite",
    "A custom client-side quality-of-life interface."
)

local UnloadButton = Button(
    SettingsPage,
    "Unload SILLY",
    UDim2.new(1, 0, 0, 38)
)

UnloadButton.BackgroundColor3 = Color3.fromRGB(65, 31, 42)
UnloadButton.TextColor3 = Color3.fromRGB(255, 160, 170)


--==============================================================
-- SECTION 15 - NAVIGATION
--==============================================================
local Navigation = {
    {Name = "Home", Symbol = "⌂"},
    {Name = "Visuals", Symbol = "◈"},
    {Name = "Inventory", Symbol = "▣"},
    {Name = "Alerts", Symbol = "◉"},
    {Name = "Settings", Symbol = "⚙"},
}

local NavButtons = {}
local CurrentPage = nil
local PageTransitioning = false
local PagePositions = {}

-- Store the original positions of the CanvasGroup wrappers.
for pageName, group in pairs(PageGroups) do
    PagePositions[pageName] = group.Position
end

local function SelectPage(name)
    if Runtime.Unloaded or PageTransitioning then
        return
    end

    local nextGroup = PageGroups[name]
    if not nextGroup then
        warn("[SILLY] Navigation error: Page not found - " .. tostring(name))
        return
    end

    if CurrentPage == name then
        return
    end

    local nextPosition = PagePositions[name]
    if not nextPosition then
        warn("[SILLY] Navigation error: Missing page position - " .. tostring(name))
        return
    end

    PageTransitioning = true

    local previousName = CurrentPage
    local previousGroup = previousName and PageGroups[previousName]

    -- Animate selected and unselected sidebar buttons.
    for pageName, button in pairs(NavButtons) do
        local selected = (pageName == name)

        Runtime:Tween(button, THEME.Animation.Normal, {
            BackgroundColor3 = selected
                and Color3.fromRGB(48, 38, 66)
                or THEME.Sidebar,

            TextColor3 = selected
                and THEME.AccentLight
                or THEME.Muted,
        })
    end

    -- Slide and fade the current page out.
    if previousGroup then
        local previousPosition = PagePositions[previousName]

        local outgoingTween = Runtime:Tween(
            previousGroup,
            THEME.Animation.Normal,
            {
                Position = previousPosition + UDim2.fromOffset(-12, 0),
                GroupTransparency = 1,
            }
        )

        if outgoingTween then
            outgoingTween.Completed:Wait()
        end

        if Runtime.Unloaded then
            return
        end

        previousGroup.Visible = false
        previousGroup.Position = previousPosition
        previousGroup.GroupTransparency = 0
    end

    if Runtime.Unloaded then
        return
    end

    -- Position the incoming page just to the right, then slide/fade it in.
    nextGroup.Position = nextPosition + UDim2.fromOffset(12, 0)
    nextGroup.GroupTransparency = 1
    nextGroup.Visible = true

    CurrentPage = name

    local incomingTween = Runtime:Tween(
        nextGroup,
        THEME.Animation.Normal,
        {
            Position = nextPosition,
            GroupTransparency = 0,
        }
    )

    if incomingTween then
        incomingTween.Completed:Wait()
    end

    if Runtime.Unloaded then
        return
    end

    -- Snap to exact final values to avoid accumulated position drift.
    nextGroup.Position = nextPosition
    nextGroup.GroupTransparency = 0

    PageTransitioning = false
end

-- Create navigation buttons.
for index, item in ipairs(Navigation) do
    local button = Create("TextButton", {
        Name = item.Name .. "Button",
        LayoutOrder = index,

        AutoButtonColor = false,

        Text = item.Symbol .. "    " .. item.Name,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,

        TextColor3 = THEME.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,

        BackgroundColor3 = THEME.Sidebar,
        Size = UDim2.new(1, 0, 0, 38),
    }, Sidebar)

    Corner(button, THEME.Radius.Button)
    Padding(button, 10, 5, 0, 0)

    NavButtons[item.Name] = button

    Runtime:Connect(button.Activated, function()
        SelectPage(item.Name)
    end)
end

-- Display the default page.
SelectPage("Home")

--==============================================================
-- SECTION 16 - WINDOW DRAGGING
--==============================================================

local dragging = false
local dragStart = nil
local startPosition = nil

Runtime:Connect(TopBar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true

        dragStart = input.Position
        startPosition = Main.Position
    end
end)

Runtime:Connect(UserInputService.InputChanged, function(input)
    if not dragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,

            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

Runtime:Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)


--==============================================================
-- SECTION 17 - MINIMIZE & RESTORE
--==============================================================

local minimized = false

Runtime:Connect(MinimizeButton.Activated, function()
    if Runtime.Unloaded then
        return
    end

    minimized = not minimized

    Body.Visible = not minimized

    Runtime:Tween(Main, THEME.Animation.Normal, {
        Size = minimized
            and UDim2.new(0, 760, 0, 58)
            or CONFIG.WindowSize,
    })
end)


--==============================================================
-- SECTION 18 - UNLOAD SYSTEM
--==============================================================

local ModalOverlay = Create("Frame", {
    Name = "UnloadConfirmation",

    Size = UDim2.fromScale(1, 1),

    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.4,

    Visible = false,
    ZIndex = 20,
}, Main)

local Modal = Create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),

    Position = UDim2.fromScale(0.5, 0.5),

    Size = UDim2.fromOffset(300, 155),

    BackgroundColor3 = THEME.Panel,
    ZIndex = 21,
}, ModalOverlay)

Corner(Modal, THEME.Radius.Modal)
Stroke(Modal, THEME.Border)

local ModalTitle = Label(
    Modal,
    "Unload SILLY?",
    17,
    THEME.Text,
    true
)

ModalTitle.Position = UDim2.fromOffset(16, 14)
ModalTitle.Size = UDim2.new(1, -32, 0, 26)
ModalTitle.ZIndex = 22

local ModalDescription = Label(
    Modal,
    "This will close the interface and clean up its runtime resources.",
    11,
    THEME.Muted
)

ModalDescription.Position = UDim2.fromOffset(16, 43)
ModalDescription.Size = UDim2.new(1, -32, 0, 40)
ModalDescription.ZIndex = 22

local CancelButton = Button(
    Modal,
    "Cancel",
    UDim2.fromOffset(125, 34)
)

CancelButton.Position = UDim2.fromOffset(16, 102)
CancelButton.ZIndex = 22

local ConfirmButton = Button(
    Modal,
    "Unload",
    UDim2.fromOffset(125, 34)
)

ConfirmButton.Position = UDim2.fromOffset(159, 102)
ConfirmButton.BackgroundColor3 = Color3.fromRGB(115, 47, 64)
ConfirmButton.ZIndex = 22

local function ShowUnloadConfirmation()
    if Runtime.Unloaded then
        return
    end

    ModalOverlay.Visible = true
end

Runtime:Connect(UnloadButton.Activated, ShowUnloadConfirmation)
Runtime:Connect(CloseButton.Activated, ShowUnloadConfirmation)

Runtime:Connect(CancelButton.Activated, function()
    ModalOverlay.Visible = false
end)

Runtime:Connect(ConfirmButton.Activated, function()
    Runtime:Unload()
end)


--==============================================================
-- SECTION 19 - INITIALIZATION
--==============================================================

print("================================")
print("[SILLY] Successfully initialized.")
print("[SILLY] Version: " .. CONFIG.Version)
print("[SILLY] Theme: Premium Violet")
print("[SILLY] Runtime cleanup: Enabled")
print("================================")
