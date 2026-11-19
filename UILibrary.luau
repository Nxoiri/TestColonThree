
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
-- 11. Quick Access Page
-- 12. Visuals Page
-- 13. Inventory Page
-- 14. Alerts Page
-- 15. Settings Page
-- 16. Navigation
-- 17. Window Dragging
-- 18. Minimize & Restore
-- 19. Unload System
-- 20. Initialization
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
    Version = "0.2.0",

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

-- Reuse the native World Zero menu lifecycle from the original SILLY script.
-- The menu module is loaded lazily so the rest of the interface can initialize
-- even when the game UI is not available yet.
local QuickMenuController = (function()
    local QuickMenuGui

    local function GetMenu(name)
        if game.GameId ~= 985731078 then
            error("Native menu access is only available in World Zero.")
        end

        if not QuickMenuGui then
            local client = ReplicatedStorage:WaitForChild("Client", 5)
            if not client then
                error("World Zero Client folder was not found.")
            end

            client = CloneReference(client)

            local guiModule = client:WaitForChild("Gui", 5)
            if not guiModule then
                error("World Zero Client.Gui module was not found.")
            end

            QuickMenuGui = require(CloneReference(guiModule))
        end

        return QuickMenuGui:Get(name)
    end

    local active, pending, running, closed
    local controller = {}

    local function release()
        local previous = active
        active = nil

        if previous then
            previous:Close()
        end
    end

    function controller.Request(name)
        if closed or Runtime.Unloaded then
            return false
        end

        pending = name

        if running then
            return true
        end

        running = true

        local ok = pcall(function()
            while pending and not closed and not Runtime.Unloaded do
                local target = pending
                pending = nil

                if active then
                    release()
                    task.wait(0.3)
                end

                if closed or Runtime.Unloaded then
                    break
                end

                if pending then
                    target = pending
                    pending = nil
                end

                local menu = GetMenu(target)
                active = menu

                if target == "PetExpeditions" then
                    menu:Open(true)
                else
                    menu:Open()
                end
            end
        end)

        running = false

        if not ok then
            pending = nil
            pcall(release)
        end

        return ok
    end

    function controller.Close()
        closed = true
        pending = nil
        pcall(release)
    end

    return controller
end)()

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

    if QuickMenuController then
        pcall(function()
            QuickMenuController.Close()
        end)
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
-- SECTION 11 - QUICK ACCESS PAGE
--==============================================================

local QuickAccessPage = CreatePage("Quick Access")

PageHeader(
    QuickAccessPage,
    "Quick Access",
    "Open native World Zero menus without replacing their built-in UI."
)

local NativeMenuSection = Section(
    QuickAccessPage,
    "Native Menu"
)

local MenuKeyInput = Create("TextBox", {
    Name = "NativeMenuKeyInput",
    ClearTextOnFocus = false,
    PlaceholderText = "Enter exact menu key (for example: PetExpeditions)",
    Text = "",
    TextSize = 11,
    TextColor3 = THEME.Text,
    PlaceholderColor3 = THEME.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundColor3 = THEME.PanelLight,
    Size = UDim2.new(1, 0, 0, 38),
}, NativeMenuSection)

Corner(MenuKeyInput, THEME.Radius.Button)
Stroke(MenuKeyInput, THEME.Border)
Padding(MenuKeyInput, 10, 10, 0, 0)
MenuKeyInput.LayoutOrder = 1

local OpenNativeMenuButton = Button(
    NativeMenuSection,
    "Open Menu",
    UDim2.new(1, 0, 0, 38)
)
OpenNativeMenuButton.LayoutOrder = 2

local QuickMenuStatus = Label(
    NativeMenuSection,
    "Ready. Menu keys are case-sensitive.",
    10,
    THEME.Muted
)
QuickMenuStatus.Size = UDim2.new(1, 0, 0, 28)
QuickMenuStatus.LayoutOrder = 3

local VerifiedMenuSection = Section(
    QuickAccessPage,
    "Verified Shortcut"
)

local PetExpeditionsButton = Button(
    VerifiedMenuSection,
    "Pet Expeditions",
    UDim2.new(1, 0, 0, 38)
)

local function RequestNativeMenu(menuName)
    if Runtime.Unloaded then
        return
    end

    if type(menuName) ~= "string" or menuName:match("^%s*$") then
        QuickMenuStatus.Text = "Enter a menu key first."
        QuickMenuStatus.TextColor3 = THEME.Accent
        return
    end

    if game.GameId ~= 985731078 then
        QuickMenuStatus.Text = "Native menus are only available in World Zero."
        QuickMenuStatus.TextColor3 = THEME.Accent
        return
    end

    QuickMenuStatus.Text = "Requesting: " .. menuName
    QuickMenuStatus.TextColor3 = THEME.Muted

    task.spawn(function()
        local ok, accepted = pcall(function()
            return QuickMenuController.Request(menuName)
        end)

        if Runtime.Unloaded then
            return
        end

        if not ok or not accepted then
            QuickMenuStatus.Text = "Menu unavailable: " .. menuName
            QuickMenuStatus.TextColor3 = THEME.Accent
        else
            QuickMenuStatus.Text = "Request accepted: " .. menuName
            QuickMenuStatus.TextColor3 = THEME.AccentLight
        end
    end)
end

Runtime:Connect(OpenNativeMenuButton.Activated, function()
    local menuName = MenuKeyInput.Text:match("^%s*(.-)%s*$")
    RequestNativeMenu(menuName)
end)

Runtime:Connect(MenuKeyInput.FocusLost, function(enterPressed)
    if enterPressed then
        local menuName = MenuKeyInput.Text:match("^%s*(.-)%s*$")
        RequestNativeMenu(menuName)
    end
end)

Runtime:Connect(PetExpeditionsButton.Activated, function()
    RequestNativeMenu("PetExpeditions")
end)

InfoCardPlain(
    QuickAccessPage,
    "Menu Key Testing",
    "The original controller confirms PetExpeditions as a native menu key. Test other exact keys here before they are added as permanent shortcuts."
)


--==============================================================
-- SECTION 12 - VISUALS PAGE
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

Toggle(
    EntitySection,
    "Mob ESP",
    "Highlight supported mobs and NPCs.",
    false
)


--==============================================================
-- SECTION 13 - INVENTORY PAGE
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

Toggle(
    SellSection,
    "Enable Auto Sell",
    "Automatically handle eligible unwanted items.",
    false
)

Toggle(
    SellSection,
    "Protect Rare Items",
    "Keep items marked as rare.",
    true
)

Toggle(
    SellSection,
    "Protect Selected Items",
    "Respect your configured item exclusions.",
    true
)

InfoCard(
    InventoryPage,
    "Inventory Integration",
    "Item detection and selling logic will be connected after inspecting your existing implementation."
)


--==============================================================
-- SECTION 14 - ALERTS PAGE
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
-- SECTION 15 - SETTINGS PAGE
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
-- SECTION 16 - NAVIGATION
--==============================================================
local Navigation = {
    {Name = "Home", Symbol = "⌂"},
    {Name = "Quick Access", Symbol = "↗"},
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
-- SECTION 17 - WINDOW DRAGGING
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
-- SECTION 18 - MINIMIZE & RESTORE
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
-- SECTION 19 - UNLOAD SYSTEM
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
-- SECTION 20 - INITIALIZATION
--==============================================================

print("================================")
print("[SILLY] Successfully initialized.")
print("[SILLY] Version: " .. CONFIG.Version)
print("[SILLY] Theme: Premium Violet")
print("[SILLY] Runtime cleanup: Enabled")
print("================================")
