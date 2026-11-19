
--==============================================================
-- SILLY QoL SUITE
-- Version: 0.2.12
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
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Executor hook aliases retained from the original QoL implementation.
local HookFunction = hookfunc or hookfunction
local RestoreFunction = restorefunc or restorefunction
local IsHooked = ishooked or isfunctionhooked or is_hooked or is_function_hooked
local NewClosure = newcclosure

local CloneReference = cloneref or clonereference or function(instance)
    return instance
end

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")


--==============================================================
-- SECTION 02 - CONFIGURATION
--==============================================================

local CONFIG = {
    Name = "Yuri's Quality of Life Suite",
    Version = "0.2.12",

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
    RestoreEnhancedLighting = nil,
    RestoreGameplaySettings = nil,

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

    -- Restore gameplay hooks and stop background loops before cleanup.
    if self.RestoreGameplaySettings then
        pcall(self.RestoreGameplaySettings)
    end

    -- Restore locally modified lighting before destroying tracked instances.
    if self.RestoreEnhancedLighting then
        pcall(self.RestoreEnhancedLighting)
    end

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

    print("[Yuri's QoL Suite] Successfully unloaded.")
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
        TextSize = size or 15,
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
        TextSize = 14,

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
    "Y",
    22,
    Color3.new(1, 1, 1),
    true
)

LogoText.Size = UDim2.fromScale(1, 1)
LogoText.TextXAlignment = Enum.TextXAlignment.Center

local Title = Label(
    TopBar,
    "Yuri's",
    18,
    THEME.Text,
    true
)

Title.Position = UDim2.fromOffset(64, 9)
Title.Size = UDim2.fromOffset(100, 20)

local Subtitle = Label(
    TopBar,
    "QUALITY OF LIFE SUITE",
    10,
    THEME.Muted
)

Subtitle.Position = UDim2.fromOffset(65, 29)
Subtitle.Size = UDim2.fromOffset(180, 15)

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

-- Small restore button shown at the bottom-left while the main window is hidden.
local RestoreButton = Button(
    ScreenGui,
    "S",
    UDim2.fromOffset(44, 44)
)

RestoreButton.Name = "RestoreButton"
RestoreButton.AnchorPoint = Vector2.new(0, 1)
RestoreButton.Position = UDim2.new(0, 18, 1, -18)
RestoreButton.BackgroundColor3 = THEME.Accent
RestoreButton.TextColor3 = Color3.new(1, 1, 1)
RestoreButton.TextSize = 17
RestoreButton.Visible = false
Stroke(RestoreButton, THEME.AccentLight)

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
    10,
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
        Size = UDim2.new(1, 0, 0, description and 62 or 32),
    }, parent)

    local heading = Label(
        container,
        title,
        25,
        THEME.Text,
        true
    )

    heading.Size = UDim2.new(1, 0, 0, 32)

    if description then
        local sub = Label(
            container,
            description,
            12,
            THEME.Muted
        )

        sub.Position = UDim2.fromOffset(0, 33)
        sub.Size = UDim2.new(1, 0, 0, 22)
    end

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
        14,
        THEME.Text,
        true
    )

    heading.Size = UDim2.new(1, 0, 0, 24)
    heading.LayoutOrder = 0

    return section
end

local function InfoCardPlain(parent, title, description)
    local card = Create("Frame", {
        BackgroundColor3 = THEME.Panel,

        Size = UDim2.new(1, 0, 0, 76),
    }, parent)

    Corner(card, THEME.Radius.Panel)
    Stroke(card, THEME.Border)

    Padding(card, 12, 12, 10, 10)

    local heading = Label(
        card,
        title,
        14,
        THEME.Text,
        true
    )

    heading.Size = UDim2.new(1, 0, 0, 22)

    local sub = Label(
        card,
        description,
        12,
        THEME.Muted
    )

    sub.Position = UDim2.fromOffset(0, 26)
    sub.Size = UDim2.new(1, 0, 0, 32)

    return card
end

local function InfoCard(parent, title, description)
    local card = Create("Frame", {
        BackgroundColor3 = THEME.Panel,

        Size = UDim2.new(1, 0, 0, 76),
    }, parent)

    Corner(card, THEME.Radius.Panel)
    Stroke(card, THEME.Border)
    ApplyPanelShadow(card)

    Padding(card, 12, 12, 10, 10)

    local heading = Label(
        card,
        title,
        14,
        THEME.Text,
        true
    )

    heading.Size = UDim2.new(1, 0, 0, 22)

    local sub = Label(
        card,
        description,
        12,
        THEME.Muted
    )

    sub.Position = UDim2.fromOffset(0, 26)
    sub.Size = UDim2.new(1, 0, 0, 32)

    return card
end

local function Toggle(parent, title, description, default, callback)
    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 54),
    }, parent)

    local titleLabel = Label(
        row,
        title,
        14,
        THEME.Text,
        true
    )

    titleLabel.Size = UDim2.new(1, -65, 0, 22)

    local descLabel = Label(
        row,
        description,
        12,
        THEME.Muted
    )

    descLabel.Position = UDim2.fromOffset(0, 23)
    descLabel.Size = UDim2.new(1, -65, 0, 20)

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

    local function Update(value, suppressCallback)
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

        if callback and not suppressCallback then
            callback(enabled)
        end
    end

    Runtime.FeatureStates[title] = enabled

    Runtime:Connect(switch.Activated, function()
        Update(not enabled)
    end)

    return {
        Row = row,

        Set = function(value)
            Update(value, false)
        end,

        SetSilent = function(value)
            Update(value, true)
        end,

        Get = function()
            return enabled
        end,
    }
end


local function CollapsibleSection(parent, title)
    -- Use explicit height updates rather than nested AutomaticSize. This
    -- keeps all subsection headers visible inside scrolling containers.
    local container = Create("Frame", {
        BackgroundColor3 = THEME.PanelLight,
        Size = UDim2.new(1, 0, 0, 34),
        ClipsDescendants = true,
    }, parent)

    Corner(container, THEME.Radius.Button)
    Stroke(container, THEME.Border)

    local containerLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, container)

    local header = Create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Text = "",
        LayoutOrder = 0,
    }, container)

    local heading = Label(header, title, 13, THEME.Text, true)
    heading.Position = UDim2.fromOffset(12, 0)
    heading.Size = UDim2.new(1, -42, 1, 0)

    local arrow = Label(header, "›", 22, THEME.Muted, true)
    arrow.TextXAlignment = Enum.TextXAlignment.Center
    arrow.Position = UDim2.new(1, -34, 0, 0)
    arrow.Size = UDim2.fromOffset(22, 34)

    local content = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.fromOffset(10, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        LayoutOrder = 1,
    }, container)

    Padding(content, 2, 2, 0, 10)

    local contentLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, content)

    local function UpdateExpandedHeight()
        if content.Visible then
            container.Size = UDim2.new(
                1,
                0,
                0,
                34 + 6 + contentLayout.AbsoluteContentSize.Y
            )
        else
            container.Size = UDim2.new(1, 0, 0, 34)
        end
    end

    Runtime:Connect(contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"), UpdateExpandedHeight)

    Runtime:Connect(header.Activated, function()
        content.Visible = not content.Visible
        arrow.Text = content.Visible and "⌄" or "›"
        UpdateExpandedHeight()
    end)

    return content
end

local function Slider(parent, title, minimum, maximum, step, defaultValue, callback)
    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 52),
    }, parent)

    local titleLabel = Label(row, title, 12, THEME.Text, true)
    titleLabel.Position = UDim2.fromOffset(0, 0)
    titleLabel.Size = UDim2.new(1, -72, 0, 20)

    local valueLabel = Label(row, "", 11, THEME.Muted, true)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Position = UDim2.new(1, -68, 0, 0)
    valueLabel.Size = UDim2.fromOffset(68, 20)

    local track = Create("Frame", {
        BackgroundColor3 = THEME.Border,
        Position = UDim2.fromOffset(0, 31),
        Size = UDim2.new(1, -24, 0, 5),
    }, row)
    Corner(track, 5)

    local fill = Create("Frame", {
        BackgroundColor3 = THEME.Accent,
        Size = UDim2.new(0, 0, 1, 0),
    }, track)
    Corner(fill, 5)

    local knob = Create("Frame", {
        BackgroundColor3 = THEME.Text,
        Size = UDim2.fromOffset(13, 13),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
    }, track)
    Corner(knob, 7)

    local hitbox = Create("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Text = "",
        Position = UDim2.fromOffset(0, 22),
        Size = UDim2.new(1, -24, 0, 22),
    }, row)

    local current = defaultValue
    local dragging = false

    local function FormatValue(value)
        if step >= 1 then
            return tostring(math.floor(value + 0.5))
        end
        return string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")
    end

    local function SetValue(value, fireCallback)
        value = math.clamp(tonumber(value) or minimum, minimum, maximum)
        if step and step > 0 then
            value = minimum + math.floor(((value - minimum) / step) + 0.5) * step
            value = math.clamp(value, minimum, maximum)
        end
        current = value

        local alpha = maximum == minimum and 0 or (current - minimum) / (maximum - minimum)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = FormatValue(current)

        if fireCallback and callback then
            callback(current)
        end
    end

    local function SetFromPosition(x)
        local width = track.AbsoluteSize.X
        if width <= 0 then
            return
        end
        local alpha = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
        SetValue(minimum + (maximum - minimum) * alpha, true)
    end

    Runtime:Connect(hitbox.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            SetFromPosition(input.Position.X)
        end
    end)

    Runtime:Connect(UserInputService.InputChanged, function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            SetFromPosition(input.Position.X)
        end
    end)

    Runtime:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    SetValue(defaultValue, false)

    return {
        Set = function(value)
            SetValue(value, false)
        end,
        Get = function()
            return current
        end,
    }
end

local function HexColorInput(parent, title, defaultColor, callback)
    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
    }, parent)

    local titleLabel = Label(row, title, 12, THEME.Text, true)
    titleLabel.Position = UDim2.fromOffset(0, 0)
    titleLabel.Size = UDim2.new(1, -112, 0, 20)

    local input = Create("TextBox", {
        BackgroundColor3 = THEME.Panel,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Text = "",
        TextColor3 = THEME.Text,
        TextSize = 12,
        PlaceholderText = "#RRGGBB",
        PlaceholderColor3 = THEME.Muted,
        Size = UDim2.fromOffset(92, 26),
        Position = UDim2.new(1, -104, 0, 0),
    }, row)
    Corner(input, THEME.Radius.Button)
    Stroke(input, THEME.Border)

    local preview = Create("Frame", {
        BackgroundColor3 = defaultColor,
        Position = UDim2.fromOffset(0, 27),
        Size = UDim2.new(1, 0, 0, 9),
    }, row)
    Corner(preview, 5)

    local current = defaultColor

    local function ToHex(color)
        if typeof(color) ~= "Color3" then
            return nil
        end

        return string.format(
            "#%02X%02X%02X",
            math.floor(color.R * 255 + 0.5),
            math.floor(color.G * 255 + 0.5),
            math.floor(color.B * 255 + 0.5)
        )
    end

    local function SetColor(color)
        -- A malformed or unexpected snapshot value must not break the
        -- entire Enhanced Lighting toggle or corrupt the current input.
        local hex = ToHex(color)
        if not hex then
            warn("[Yuri QoL] Ignored invalid color value in Enhanced Lighting control.")
            return false
        end

        current = color
        input.Text = hex
        preview.BackgroundColor3 = color
        return true
    end

    Runtime:Connect(input.FocusLost, function()
        local hex = input.Text:gsub("^%s+", ""):gsub("%s+$", "")
        hex = hex:gsub("^#", "")

        if #hex == 6 and hex:match("^%x%x%x%x%x%x$") then
            local red = tonumber(hex:sub(1, 2), 16)
            local green = tonumber(hex:sub(3, 4), 16)
            local blue = tonumber(hex:sub(5, 6), 16)
            current = Color3.fromRGB(red, green, blue)
            input.Text = ToHex(current) or "#FFFFFF"
            preview.BackgroundColor3 = current
            if callback then
                callback(current)
            end
        else
            input.Text = ToHex(current) or "#FFFFFF"
        end
    end)

    SetColor(defaultColor)

    return {
        Set = SetColor,
        Get = function()
            return current
        end,
    }
end


--==============================================================
-- SECTION 10 - HOME PAGE
--==============================================================

local HomePage = CreatePage("Home")

PageHeader(
    HomePage,
    "Welcome, " .. Player.DisplayName
)

local AboutSection = Section(HomePage, "About")

local AboutHeading = Label(
    AboutSection,
    "Yuri's Quality of Life Suite | Version " .. CONFIG.Version,
    16,
    THEME.Text,
    true
)
AboutHeading.Size = UDim2.new(1, 0, 0, 26)

local AboutDescription = Label(
    AboutSection,
    "Providing useful additions to make your experience prettier and smoother!",
    14,
    THEME.Muted
)
AboutDescription.Size = UDim2.new(1, 0, 0, 42)

local AboutAdditionsHeading = Label(
    AboutSection,
    "Additions include:",
    14,
    THEME.Text,
    true
)
AboutAdditionsHeading.Size = UDim2.new(1, 0, 0, 22)

local AboutAdditions = Label(
    AboutSection,
    "- Custom lighting adjustments\n- Improved visual clarity\n- Automatic inventory management\n- Hassle-free egg hatching and gear upgrading",
    14,
    THEME.Muted
)
AboutAdditions.Size = UDim2.new(1, 0, 0, 88)
AboutAdditions.TextYAlignment = Enum.TextYAlignment.Top

local WarningSection = Section(HomePage, "Warning")

local WarningText = Label(
    WarningSection,
    "- Use the suite at your own discretion.\n- Some features may stop working after game updates.\n- Automation features may perform actions without further confirmation.\n- Be careful when using Auto Sell. Items sold will not be recoverable.\n- Feature compatibility may vary between executors.",
    14,
    THEME.Muted
)
WarningText.Size = UDim2.new(1, 0, 0, 132)
WarningText.TextYAlignment = Enum.TextYAlignment.Top

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

-- Enhanced Lighting uses the game's native profile locks wherever supported.
-- Atmosphere profile tweens are filtered separately and intentionally remain
-- intercepted after the UI is disabled or the suite is unloaded.

local LightingSliderRanges = {
    Brightness = {Min = 0, Max = 10, Step = 0.1},
    ClockTime = {Min = 0, Max = 24, Step = 0.1},
    ExposureCompensation = {Min = -3, Max = 3, Step = 0.05},
    AtmosphereDensity = {Min = 0, Max = 1, Step = 0.01},
    BlurSize = {Min = 0, Max = 56, Step = 1},
    ColorCorrectionValue = {Min = -1, Max = 1, Step = 0.01},
    BloomSize = {Min = 0, Max = 56, Step = 1},
    BloomThreshold = {Min = 0, Max = 2, Step = 0.01},
}

local EnhancedLightingActive = false
local EnhancedLightingInitialized = false
local LightingSnapshot = {}
local EffectSnapshots = {}
local CreatedBloomEffects = {}
local EnhancedLightingControls = {}
local EnhancedLightingMenu
local ResetEnhancedLighting

local LightingLockId = "SILLY_QOL_EnhancedLighting"
local LightingModule
local BlurEffect
local ColorCorrectionEffect
local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

local function FindBloomEffects()
    local results = {}
    local seen = {}

    local function scan(root)
        if not root then
            return
        end
        for _, instance in ipairs(root:GetDescendants()) do
            if instance:IsA("BloomEffect") and not seen[instance] then
                seen[instance] = true
                table.insert(results, instance)
            end
        end
    end

    scan(Lighting)
    scan(workspace.CurrentCamera)
    return results
end

local function GetBloomTargets(createIfMissing)
    local targets = {}
    for effect in pairs(EffectSnapshots) do
        if effect:IsA("BloomEffect") and effect.Parent then
            table.insert(targets, effect)
        end
    end
    for _, effect in ipairs(CreatedBloomEffects) do
        if effect.Parent then
            table.insert(targets, effect)
        end
    end

    if #targets == 0 and createIfMissing then
        local effect = Instance.new("BloomEffect")
        effect.Name = "SILLY_EnhancedBloom"
        effect.Parent = Lighting
        table.insert(CreatedBloomEffects, effect)
        Runtime:TrackInstance(effect)
        table.insert(targets, effect)
    end

    return targets
end

local function CaptureEnhancedLightingDefaults()
    table.clear(LightingSnapshot)
    table.clear(EffectSnapshots)
    table.clear(CreatedBloomEffects)

    for _, property in ipairs({"Brightness", "ClockTime", "ExposureCompensation"}) do
        LightingSnapshot[property] = Lighting[property]
    end

    BlurEffect = Lighting:FindFirstChildOfClass("BlurEffect")
    ColorCorrectionEffect = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

    local function capture(instance, properties)
        if not instance then
            return
        end
        local snapshot = {}
        for _, property in ipairs(properties) do
            snapshot[property] = instance[property]
        end
        EffectSnapshots[instance] = snapshot
    end

    capture(BlurEffect, {"Enabled", "Size"})
    capture(ColorCorrectionEffect, {
        "Enabled", "Brightness", "Contrast", "Saturation", "TintColor"
    })
    capture(Atmosphere, {"Color", "Density"})

    local firstBloomSnapshot
    local bloomEnabled = false
    for _, effect in ipairs(FindBloomEffects()) do
        capture(effect, {"Enabled", "Size", "Threshold"})
        local snapshot = EffectSnapshots[effect]
        firstBloomSnapshot = firstBloomSnapshot or snapshot
        bloomEnabled = bloomEnabled or snapshot.Enabled
    end

    if EnhancedLightingControls.Bloom then
        EnhancedLightingControls.Bloom:SetSilent(bloomEnabled)
    end
    if firstBloomSnapshot and EnhancedLightingControls.BloomSize then
        EnhancedLightingControls.BloomSize:Set(firstBloomSnapshot.Size)
        EnhancedLightingControls.BloomThreshold:Set(firstBloomSnapshot.Threshold)
    end
end

local function InstallAtmosphereInterceptor()
    if not Atmosphere then
        warn("[Yuri's QoL Suite] Atmosphere was not found; its profile tween filter was not installed.")
        return false
    end

    if type(HookFunction) ~= "function" then
        warn("[Yuri's QoL Suite] Your executor does not expose hookfunction; Atmosphere interception is unavailable.")
        return false
    end

    local environment = getgenv and getgenv() or _G
    local state = environment.SILLY_QOL_ATMOSPHERE_HOOK_STATE

    if state and state.Installed then
        state.Instance = Atmosphere
        return true
    end

    local ok, result = pcall(function()
        local originalCreate
        local hook = NewClosure or function(callback) return callback end

        originalCreate = HookFunction(TweenService.Create, hook(function(self, instance, tweenInfo, properties)
            if state and instance == state.Instance and type(properties) == "table" then
                local goals = table.clone(properties)
                if goals.Color ~= nil then
                    goals.Color = state.Color
                end
                if goals.Density ~= nil then
                    goals.Density = state.Density
                end
                properties = goals
            end

            return originalCreate(self, instance, tweenInfo, properties)
        end))

        state = {
            Installed = true,
            Instance = Atmosphere,
            Color = Atmosphere.Color,
            Density = Atmosphere.Density,
            OriginalCreate = originalCreate,
        }
        environment.SILLY_QOL_ATMOSPHERE_HOOK_STATE = state
    end)

    if not ok then
        warn("[Yuri's QoL Suite] Could not install the Atmosphere tween filter: " .. tostring(result))
        return false
    end

    return true
end

local function SetAtmosphereTarget(color, density)
    local environment = getgenv and getgenv() or _G
    local state = environment.SILLY_QOL_ATMOSPHERE_HOOK_STATE
    if state then
        state.Instance = Atmosphere
        state.Color = color
        state.Density = density
    end

    if Atmosphere and Atmosphere.Parent then
        Atmosphere.Color = color
        Atmosphere.Density = density
    end
end

local function AcquireLightingLocks()
    if not LightingModule then
        local ok, result = pcall(function()
            return require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("Lighting"))
        end)
        if ok then
            LightingModule = result
        else
            warn("[Yuri's QoL Suite] Could not load the game's Lighting module: " .. tostring(result))
            return false
        end
    end

    local lockGroups = {
        Lighting = {"Brightness", "ClockTime", "ExposureCompensation"},
        Blur = {"Size"},
        ColorCorrection = {"Brightness", "Contrast", "Saturation", "TintColor"},
        Bloom = {"Size", "Threshold"},
    }

    for category, properties in pairs(lockGroups) do
        for _, property in ipairs(properties) do
            local ok, err = pcall(function()
                LightingModule:LockProfileProperty(
                    LightingLockId,
                    LightingLockId,
                    category,
                    property
                )
            end)
            if not ok then
                warn("[Yuri's QoL Suite] Could not lock " .. category .. "." .. property .. ": " .. tostring(err))
            end
        end
    end

    return true
end

local function ApplyBloomEnabled(enabled)
    if not EnhancedLightingActive then
        return
    end

    for _, effect in ipairs(GetBloomTargets(enabled)) do
        pcall(function()
            effect.Enabled = enabled
        end)
    end
end

local function ApplyBloomProperty(property, value)
    if not EnhancedLightingActive then
        return
    end

    local enabled = EnhancedLightingControls.Bloom
        and EnhancedLightingControls.Bloom:Get()
    for _, effect in ipairs(GetBloomTargets(enabled)) do
        pcall(function()
            effect[property] = value
        end)
    end
end

local function ApplyLightingValue(property, value)
    if EnhancedLightingActive then
        pcall(function()
            Lighting[property] = value
        end)
    end
end

local function ApplyEffectValue(instance, property, value)
    if EnhancedLightingActive and instance and instance.Parent then
        pcall(function()
            instance[property] = value
        end)
    end
end

local function RestoreEnhancedLightingDefaults()
    for property, value in pairs(LightingSnapshot) do
        pcall(function()
            Lighting[property] = value
        end)
    end

    local atmosphereSnapshot = Atmosphere and EffectSnapshots[Atmosphere]
    if atmosphereSnapshot then
        SetAtmosphereTarget(atmosphereSnapshot.Color, atmosphereSnapshot.Density)
    end

    for instance, properties in pairs(EffectSnapshots) do
        if instance.Parent then
            for property, value in pairs(properties) do
                pcall(function()
                    instance[property] = value
                end)
            end
        end
    end

    for _, effect in ipairs(CreatedBloomEffects) do
        pcall(function()
            effect:Destroy()
        end)
    end
    table.clear(CreatedBloomEffects)
end

local function SetEnhancedLighting(enabled)
    if enabled then
        if not EnhancedLightingInitialized then
            CaptureEnhancedLightingDefaults()
            if not AcquireLightingLocks() then
                if EnhancedLightingToggle then
                    EnhancedLightingToggle.SetSilent(false)
                end
                return
            end
            InstallAtmosphereInterceptor()
            EnhancedLightingInitialized = true
        end

        EnhancedLightingActive = true
        EnhancedLightingMenu.Visible = true

        ApplyLightingValue("Brightness", EnhancedLightingControls.Brightness:Get())
        ApplyLightingValue("ClockTime", EnhancedLightingControls.ClockTime:Get())
        ApplyLightingValue("ExposureCompensation", EnhancedLightingControls.ExposureCompensation:Get())
        ApplyEffectValue(BlurEffect, "Enabled", EnhancedLightingControls.Blur:Get())
        ApplyEffectValue(BlurEffect, "Size", EnhancedLightingControls.BlurSize:Get())
        ApplyEffectValue(ColorCorrectionEffect, "Enabled", EnhancedLightingControls.ColorCorrection:Get())
        ApplyEffectValue(ColorCorrectionEffect, "Brightness", EnhancedLightingControls.CorrectionBrightness:Get())
        ApplyEffectValue(ColorCorrectionEffect, "Contrast", EnhancedLightingControls.Contrast:Get())
        ApplyEffectValue(ColorCorrectionEffect, "Saturation", EnhancedLightingControls.Saturation:Get())
        ApplyEffectValue(ColorCorrectionEffect, "TintColor", EnhancedLightingControls.TintColor:Get())
        SetAtmosphereTarget(
            EnhancedLightingControls.AtmosphereColor:Get(),
            EnhancedLightingControls.AtmosphereDensity:Get()
        )
        ApplyBloomEnabled(EnhancedLightingControls.Bloom:Get())
        ApplyBloomProperty("Size", EnhancedLightingControls.BloomSize:Get())
        ApplyBloomProperty("Threshold", EnhancedLightingControls.BloomThreshold:Get())
    else
        EnhancedLightingActive = false
        if EnhancedLightingInitialized then
            RestoreEnhancedLightingDefaults()
        end
        if EnhancedLightingMenu then
            EnhancedLightingMenu.Visible = false
        end
    end
end

ResetEnhancedLighting = function()
    if not EnhancedLightingInitialized then
        return
    end

    RestoreEnhancedLightingDefaults()

    if Atmosphere then
        local snapshot = EffectSnapshots[Atmosphere]
        if snapshot then
            SetAtmosphereTarget(snapshot.Color, snapshot.Density)
        end
    end

    if EnhancedLightingControls.Brightness then
        EnhancedLightingControls.Brightness:Set(LightingSnapshot.Brightness)
        EnhancedLightingControls.ClockTime:Set(LightingSnapshot.ClockTime)
        EnhancedLightingControls.ExposureCompensation:Set(LightingSnapshot.ExposureCompensation)
    end
    if BlurEffect and EffectSnapshots[BlurEffect] then
        local snapshot = EffectSnapshots[BlurEffect]
        EnhancedLightingControls.Blur:Set(snapshot.Enabled)
        EnhancedLightingControls.BlurSize:Set(snapshot.Size)
    end
    if ColorCorrectionEffect and EffectSnapshots[ColorCorrectionEffect] then
        local snapshot = EffectSnapshots[ColorCorrectionEffect]
        EnhancedLightingControls.ColorCorrection:Set(snapshot.Enabled)
        EnhancedLightingControls.CorrectionBrightness:Set(snapshot.Brightness)
        EnhancedLightingControls.Contrast:Set(snapshot.Contrast)
        EnhancedLightingControls.Saturation:Set(snapshot.Saturation)
        EnhancedLightingControls.TintColor:Set(snapshot.TintColor)
    end
    if Atmosphere and EffectSnapshots[Atmosphere] then
        local snapshot = EffectSnapshots[Atmosphere]
        EnhancedLightingControls.AtmosphereColor:Set(snapshot.Color)
        EnhancedLightingControls.AtmosphereDensity:Set(snapshot.Density)
    end

    local bloom
    for instance, snapshot in pairs(EffectSnapshots) do
        if instance:IsA("BloomEffect") then
            bloom = snapshot
            break
        end
    end
    if bloom then
        EnhancedLightingControls.Bloom:SetSilent(bloom.Enabled)
        EnhancedLightingControls.BloomSize:Set(bloom.Size)
        EnhancedLightingControls.BloomThreshold:Set(bloom.Threshold)
    end
end

local EnhancedLightingToggle = Toggle(
    EnvironmentSection,
    "Enhanced Lighting",
    "Customize lighting and post-processing while blocking game profile changes.",
    false,
    SetEnhancedLighting
)
EnhancedLightingToggle.Row.LayoutOrder = 1

EnhancedLightingMenu = Create("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    Visible = false,
    LayoutOrder = 2,
}, EnvironmentSection)

Create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, EnhancedLightingMenu)

EnhancedLightingControls.Brightness = Slider(
    EnhancedLightingMenu, "Brightness", 0, 10, 0.1, 2,
    function(value) ApplyLightingValue("Brightness", value) end
)
EnhancedLightingControls.ClockTime = Slider(
    EnhancedLightingMenu, "Clock Time", 0, 24, 0.1, 14,
    function(value) ApplyLightingValue("ClockTime", value) end
)
EnhancedLightingControls.ExposureCompensation = Slider(
    EnhancedLightingMenu, "Exposure Compensation", -3, 3, 0.05, 0,
    function(value) ApplyLightingValue("ExposureCompensation", value) end
)

EnhancedLightingControls.AtmosphereColor = HexColorInput(
    EnhancedLightingMenu, "Atmosphere Color", Color3.fromRGB(199, 199, 199),
    function(value)
        if EnhancedLightingActive then
            local environment = getgenv and getgenv() or _G
            local state = environment.SILLY_QOL_ATMOSPHERE_HOOK_STATE
            if state then state.Color = value end
            if Atmosphere then Atmosphere.Color = value end
        end
    end
)
EnhancedLightingControls.AtmosphereDensity = Slider(
    EnhancedLightingMenu, "Atmosphere Density", 0, 1, 0.01, 0.3,
    function(value)
        if EnhancedLightingActive then
            local environment = getgenv and getgenv() or _G
            local state = environment.SILLY_QOL_ATMOSPHERE_HOOK_STATE
            if state then state.Density = value end
            if Atmosphere then Atmosphere.Density = value end
        end
    end
)

EnhancedLightingControls.Blur = Toggle(
    EnhancedLightingMenu, "Blur", "Toggle the local Blur effect.", false,
    function(value) ApplyEffectValue(BlurEffect, "Enabled", value) end
)
EnhancedLightingControls.BlurSize = Slider(
    EnhancedLightingMenu, "Blur Size", 0, 56, 1, 0,
    function(value) ApplyEffectValue(BlurEffect, "Size", value) end
)

EnhancedLightingControls.ColorCorrection = Toggle(
    EnhancedLightingMenu, "Color Correction", "Toggle local ColorCorrection.", false,
    function(value) ApplyEffectValue(ColorCorrectionEffect, "Enabled", value) end
)
EnhancedLightingControls.CorrectionBrightness = Slider(
    EnhancedLightingMenu, "Color Correction Brightness", -1, 1, 0.01, 0,
    function(value) ApplyEffectValue(ColorCorrectionEffect, "Brightness", value) end
)
EnhancedLightingControls.Contrast = Slider(
    EnhancedLightingMenu, "Color Correction Contrast", -1, 1, 0.01, 0,
    function(value) ApplyEffectValue(ColorCorrectionEffect, "Contrast", value) end
)
EnhancedLightingControls.Saturation = Slider(
    EnhancedLightingMenu, "Color Correction Saturation", -1, 1, 0.01, 0,
    function(value) ApplyEffectValue(ColorCorrectionEffect, "Saturation", value) end
)
EnhancedLightingControls.TintColor = HexColorInput(
    EnhancedLightingMenu, "Color Correction Tint", Color3.new(1, 1, 1),
    function(value) ApplyEffectValue(ColorCorrectionEffect, "TintColor", value) end
)

EnhancedLightingControls.Bloom = Toggle(
    EnhancedLightingMenu,
    "Bloom",
    "Toggle Bloom on all detected Bloom effects.",
    false,
    ApplyBloomEnabled
)
EnhancedLightingControls.BloomSize = Slider(
    EnhancedLightingMenu, "Bloom Size", 0, 56, 1, 24,
    function(value) ApplyBloomProperty("Size", value) end
)
EnhancedLightingControls.BloomThreshold = Slider(
    EnhancedLightingMenu, "Bloom Threshold", 0, 2, 0.01, 2,
    function(value) ApplyBloomProperty("Threshold", value) end
)

Runtime.RestoreEnhancedLighting = function()
    EnhancedLightingActive = false
    if EnhancedLightingInitialized then
        RestoreEnhancedLightingDefaults()
    end
    -- Intentionally retain the native profile locks and Atmosphere tween
    -- interceptor for the rest of this game session. Restarting the game
    -- restores the original game-owned update behavior.
end

local EntitySection = Section(
    VisualsPage,
    "Entity Highlighting"
)

local MobESPConnection
local MobESPActive = false
local MobESPFillColor = Color3.fromRGB(128, 128, 128)
local MobESPOutlineColor = Color3.fromRGB(0, 0, 0)
local MobESPOutlineOnly = false
local MobESPMenu

local function UpdateMobESPColors()
    local mobs = workspace:FindFirstChild("Mobs")
    if not mobs then
        return
    end

    for _, mob in ipairs(mobs:GetChildren()) do
        local highlight = mob:FindFirstChild("LarpZeroMobHighlight")
        if highlight and highlight:IsA("Highlight") then
            highlight.FillTransparency = MobESPOutlineOnly and 1 or 0
            highlight.FillColor = MobESPFillColor
            highlight.OutlineColor = MobESPOutlineColor
        end
    end
end

local function SetMobESP(enabled)
    MobESPActive = enabled
    MobESPMenu.Visible = enabled

    if game.GameId ~= 985731078 then
        if enabled then
            warn("[Yuri's QoL Suite] Mob ESP is only available in World Zero.")
        end
        return
    end

    local mobs = workspace:FindFirstChild("Mobs")
    if not mobs then
        if enabled then
            warn("[Yuri's QoL Suite] World Zero Mobs folder was not found.")
        end
        return
    end

    local function addHighlight(mob)
        if not mob or not mob.Parent then
            return
        end

        local existing = mob:FindFirstChild("LarpZeroMobHighlight")
        if existing and existing:IsA("Highlight") then
            existing.FillTransparency = MobESPOutlineOnly and 1 or 0
            existing.FillColor = MobESPFillColor
            existing.OutlineColor = MobESPOutlineColor
            return
        end

        local highlight = Instance.new("Highlight")
        highlight.Name = "LarpZeroMobHighlight"
        highlight.FillTransparency = MobESPOutlineOnly and 1 or 0
        highlight.FillColor = MobESPFillColor
        highlight.OutlineColor = MobESPOutlineColor
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

local MobESPToggle = Toggle(
    EntitySection,
    "Mob ESP",
    "Highlight current and newly spawned World Zero mobs.",
    false,
    SetMobESP
)
MobESPToggle.Row.LayoutOrder = 1

MobESPMenu = Create("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    Visible = false,
    LayoutOrder = 2,
}, EntitySection)

Create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, MobESPMenu)

Toggle(
    MobESPMenu,
    "Outline Only",
    "Hide the fill and keep the mob outline visible.",
    false,
    function(enabled)
        MobESPOutlineOnly = enabled
        if MobESPActive then
            UpdateMobESPColors()
        end
    end
)

HexColorInput(
    MobESPMenu,
    "Fill Color",
    MobESPFillColor,
    function(color)
        MobESPFillColor = color
        if MobESPActive then
            UpdateMobESPColors()
        end
    end
)

HexColorInput(
    MobESPMenu,
    "Outline Color",
    MobESPOutlineColor,
    function(color)
        MobESPOutlineColor = color
        if MobESPActive then
            UpdateMobESPColors()
        end
    end
)


--==============================================================
-- SECTION 12 - GEAR UPGRADES PAGE
--==============================================================

local GearUpgradesPage = CreatePage("Gear Upgrades")

PageHeader(
    GearUpgradesPage,
    "Auto Gear Upgrades",
    "Upgrade your equipped gear to its maximum level."
)


--==============================================================
-- SECTION 13 - EGG HATCHING PAGE
--==============================================================

local EggHatchingPage = CreatePage("Egg Hatching")

PageHeader(
    EggHatchingPage,
    "Auto Egg Hatching",
    "Automatically buy and hatch eggs or hatch eggs from your inventory."
)



--==============================================================
-- SECTION 14 - INVENTORY PAGE
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
local AutoSellConnections = {}
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

    local selectedPerks = config.keepPerks and (config.selectedPerks or {}) or {}
    local hasSelectedPerks = next(selectedPerks) ~= nil

    if not hasSelectedPerks then
        local tier = InventoryPolicy.Tier(config.keepTier)
        if tier == nil then
            return false
        end

        -- Failsafe: with no selected perks, keep tier 5 and above.
        if item.rarity >= tier then
            return false
        end
    else
        -- With perk filters active, tier 5+ items are also evaluated by perks.
        for name, value in pairs(item.perks or {}) do
            local selected = selectedPerks[name]
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


local SavePerkTable = {
    ["Gold Hoarder"] = { PerkValue = 0.2, PetPerkValue = 0.2, PerkName = "GoldDrop" },
    ["Lucky Looter"] = { PerkValue = 0.1, PetPerkValue = 0.1, PerkName = "PetFoodDrop" },
    ["Energized"] = { PerkValue = 0.15, PetPerkValue = 0.15, PerkName = "UltCharge" },
    ["HP UP"] = { PerkValue = 0.12, PetPerkValue = 0.07, PerkName = "BonusHP" },
    ["Attack Up"] = { PerkValue = 0.08, PetPerkValue = 0.05, PerkName = "BonusAttack" },
    ["Agility"] = { PerkValue = 0.1, PetPerkValue = 0.1, PerkName = "BonusWalkspeed" },
    ["Burn Resistance"] = { PerkValue = 0.9, PetPerkValue = 0.9, PerkName = "ResistBurn" },
    ["Poison Resistance"] = { PerkValue = 0.9, PetPerkValue = 0.9, PerkName = "ResistPoison" },
    ["Frost Resistance"] = { PerkValue = 0.9, PetPerkValue = 0.9, PerkName = "ResistFrost" },
    ["Knockdown Resistance"] = { PerkValue = 0.9, PetPerkValue = 0.9, PerkName = "ResistKockdown" },
    ["Untouchable"] = { PerkValue = 0.2, PerkName = "DodgeChance" },
    ["Rough Skin"] = { PerkValue = 0.1, PerkName = "RoughSkin" },
    ["Damage Reduction"] = { PerkValue = 0.08, PerkName = "DamageReduction" },
    ["Life Drain"] = { PerkValue = 0.06, PerkName = "LifeDrain" },
    ["Burn Chance"] = { PerkValue = 0.15, PerkName = "BurnChance" },
    ["Frost Chance"] = { PerkValue = 0.15, PerkName = "FrostChance" },
    ["Poison Chance"] = { PerkValue = 0.15, PerkName = "PoisonChance" },
    ["Crit Stack"] = { PerkValue = 0.15, PerkName = "CritStack" },
    ["Poisonous Thorns"] = { PerkValue = 0.6, PerkName = "PoisonThorns" },
    ["Elemental Resistance"] = { PerkValue = 0.4, PetPerkValue = 0.15, PerkName = "Elemental" },
    ["Ferocious"] = { PerkValue = 0.4, PetPerkValue = 0.15, PerkName = "Ferocious" },
    ["Vampiric"] = { PerkValue = 0.15, PetPerkValue = 0.05, PerkName = "Vampiric" },
    ["Boss Bane"] = { PerkValue = 0.3, PetPerkValue = 0.1, PerkName = "TestTier5" },
    ["Mob Slayer"] = { PerkValue = 0.3, PetPerkValue = 0.1, PerkName = "MobBoss" },
    ["Elite Assassin"] = { PerkValue = 0.3, PetPerkValue = 0.1, PerkName = "EliteBoss" },
    ["Opening Strike"] = { PerkValue = 0.25, PerkName = "OpeningStrike" },
    ["Self Destruct"] = { PerkValue = 0.5, PerkName = "Destruction" },
    ["Fortress"] = { PerkValue = 0.4, PerkName = "Fortress" },
    ["Glass"] = { PerkValue = 1, PerkName = "Glass" },
    ["Master Thief"] = { PerkValue = 0.35, PerkName = "MasterThief" },
    ["Oblivion"] = { PerkValue = 0.05, PetPerkValue = 0.05, PerkName = "Oblivion" },
    ["Reckless"] = { PerkValue = 0.25, PetPerkValue = 0.25, PerkName = "Reckless" },
    ["Comeback"] = { PerkValue = 0.3, PerkName = "Comeback" },
    ["Relentless"] = { PerkValue = 0.15, PerkName = "Relentless" },
    ["Duelist"] = { PerkValue = 0.3, PerkName = "Duelist" },
    ["Unstoppable"] = { PerkValue = 0.15, PerkName = "Unstoppable" },
    ["Survivor"] = { PerkValue = 0.2, PerkName = "Survivor" },
    ["Executioner"] = { PerkValue = 0.5, PetPerkValue = 0.5, PerkName = "Executioner" },
    ["Adrenaline"] = { PerkValue = 0.3, PerkName = "Adrenaline" },
    ["Cooldown Reduction"] = { PerkValue = 0.1, PerkName = "CooldownReduction" },
    ["Attack Speed"] = { PerkValue = 0.15, PerkName = "AttackSpeed" },
    ["Water Bubble"] = { PerkValue = 0.4, PerkName = "WaterBubble", LowerMax = true },
    ["Blessing"] = { PerkValue = 0.3, PerkName = "Blessing" },
    ["Deaths Door"] = { PerkValue = 0.5, PerkName = "DeathsDoor" },
    ["Protector"] = { PerkValue = 0.1, PerkName = "Protector" }
}

local InventoryPerks = {}
function InventoryPerks.Refresh(saved, native)
    local known = {}
    local byLabel = {}
    local function normalize(value)
        return tostring(value):lower():gsub("[^%w]", "")
    end
    for id, data in pairs(native) do
        if type(data) == "table" and data.DisplayName then
            byLabel[normalize(data.DisplayName)] = id
        end
    end
    local function configure(row, data)
        row.LowerMax = data.LowerIsBetter == true
        row.NegativeActive = data.NegativeActive == true
        row.Ranges = {
            Weapon = data.WeaponStatRange or data.StatRange,
            Armor = data.ArmorStatRange or data.StatRange,
            Pet = data.PetStatRange or data.StatRange,
            Charm = data.PetStatRange or data.StatRange,
        }
        local range = data.StatRange
        if range then
            row.PerkValue = range[row.LowerMax and 1 or 2]
        end
        local petRange = data.PetStatRange or range
        if petRange then
            row.PetPerkValue = petRange[row.LowerMax and 1 or 2]
        end
    end
    for label, row in pairs(saved) do
        if not native[row.PerkName] and byLabel[normalize(label)] then
            row.PerkName = byLabel[normalize(label)]
        end
        known[row.PerkName] = true
        if native[row.PerkName] then
            configure(row, native[row.PerkName])
        end
    end
    for id, data in pairs(native) do
        if not known[id] and type(data) == "table"
            and type(data.DisplayName) == "string" and data.StatRange then
            local label = data.DisplayName
            if saved[label] then
                label = label .. " (" .. id .. ")"
            end
            local row = {PerkName = id}
            configure(row, data)
            saved[label] = row
        end
    end
end

local SelectedPerks = {}
local KeepSelectedPerks = true
local PerkOffset = 0

local perkModuleOk, nativePerks = GameCall(function()
    return require(ReplicatedStorage.WorldModules.GearPerks)
end)
if perkModuleOk and type(nativePerks) == "table" then
    InventoryPerks.Refresh(SavePerkTable, nativePerks)
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

local function GetExpectedPerkCount(rarity, kind)
    if kind == "Charm" then
        return rarity == 5 and 1 or 0
    end
    return ({[3] = 1, [4] = 2, [5] = 3})[rarity] or 0
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
        if type(rarity) ~= "number" or not kind then
            return false
        end

        local expectedPerks = GetExpectedPerkCount(rarity, kind)
        local perks = {}

        if KeepSelectedPerks and expectedPerks > 0 then
            local deadline = os.clock() + 8
            repeat
                local complete = true
                for index = 1, expectedPerks do
                    local perk = item:FindFirstChild("Perk" .. index)
                    if not perk or perk.Value == "" or not perk:FindFirstChild("PerkValue") then
                        complete = false
                        break
                    end
                end
                if complete then
                    break
                end
                if Runtime.Unloaded or item.Parent ~= context.Items or os.clock() >= deadline then
                    return false
                end
                task.wait(0.1)
            until false
        end

        for _, child in ipairs(item:GetChildren()) do
            if child.Name:match("^Perk%d+$") then
                local value = child:FindFirstChild("PerkValue")
                if not value or child.Value == "" then
                    return false
                end
                local selected = SelectedPerks[child.Value]
                local roll = tonumber(value.Value)
                if not roll then
                    return false
                end
                if selected and selected.NegativeActive and roll < 0 then
                    roll = -roll
                end
                local previous = perks[child.Value]
                if previous ~= nil then
                    roll = selected and selected.LowerMax and math.min(previous, roll)
                        or math.max(previous, roll)
                end
                perks[child.Value] = roll
            end
        end

        local state = {
            kind = kind,
            rarity = rarity,
            perks = perks,
            protected = IsProtectedInventoryItem(item),
            stackable = item:FindFirstChild("Count") ~= nil,
            equipped = false,
            towerEgg = TowerEggs[item.Name] == true,
        }

        local config = {
            keepTier = 5,
            includePets = IncludePets,
            includeCharms = IncludeCharms,
            sellTowerEggs = SellTowerEggs,
            keepPerks = KeepSelectedPerks,
            selectedPerks = SelectedPerks,
            offset = PerkOffset / 100,
        }

        if not InventoryPolicy.ShouldSell(state, config) then
            return false
        end

        if Runtime.Unloaded or item.Parent ~= context.Items or IsProtectedInventoryItem(item) then
            return false
        end

        return SellItem(item, dropsModule)
    end)

    InventoryBusy[item] = nil

    if success and sold then
        print("[Yuri's QoL Suite] Sold inventory item: " .. item.Name)
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

    for _, connection in ipairs(AutoSellConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(AutoSellConnections)

    if not enabled then
        return
    end

    if not IsWorldZero() then
        AutoSellEnabled = false
        warn("[Yuri's QoL Suite] Auto Sell is only available in World Zero.")
        return
    end

    task.spawn(function()
        local ok, context = pcall(GetWorldZeroObjects)
        if not ok or Runtime.Unloaded or generation ~= AutoSellGeneration then
            warn("[Yuri's QoL Suite] Auto Sell could not access the inventory.")
            return
        end

        local moduleOk, itemData, dropsModule = pcall(function()
            local itemsModule = require(context.Shared:WaitForChild("Items", 10))
            local drops = require(context.Shared:WaitForChild("Drops", 10))
            return itemsModule, drops
        end)

        if not moduleOk or not itemData or not dropsModule then
            warn("[Yuri's QoL Suite] Auto Sell could not load the original inventory modules.")
            return
        end

        if Runtime.Unloaded or generation ~= AutoSellGeneration or not AutoSellEnabled then
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

        table.insert(AutoSellConnections, Runtime:Connect(context.Items.ChildAdded, enqueue))
        table.insert(AutoSellConnections, Runtime:Connect(context.Items.DescendantAdded, function(child)
            local item = child
            while item and item.Parent ~= context.Items do
                item = item.Parent
            end
            if item then
                enqueue(item)
            end
        end))
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

            print("[Yuri's QoL Suite] " .. slotName .. " upgrade: "
                .. tostring(upgrades:GetUpgrade(item)) .. "/"
                .. tostring(upgrades:GetUpgradeLimit(item)))
        end)

        if not ok then
            warn("[Yuri's QoL Suite] " .. slotName .. " upgrade failed: " .. tostring(err))
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
        warn("[Yuri's QoL Suite] Auto Hatch is only available in World Zero.")
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
                    warn("[Yuri's QoL Suite] Unable to buy selected egg. Check your balance and egg key.")
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
            warn("[Yuri's QoL Suite] Auto Hatch stopped: " .. tostring(err))
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
        warn("[Yuri's QoL Suite] Inventory Egg Hatch is only available in World Zero.")
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
            warn("[Yuri's QoL Suite] Inventory Egg Hatch stopped: " .. tostring(err))
        end
    end)
end

Toggle(
    SellSection,
    "Enable Auto Sell",
    "Auto-sell eligible new items below tier 5 using your perk and item-type protections.",
    false,
    StartAutoSell
)

local PerkSection
PerkSection = Section(InventoryPage, "Perks to Keep")
PerkSection.Visible = KeepSelectedPerks

Toggle(
    SellSection,
    "Keep Selected Perks",
    "Protect items that have a selected perk at or above its quality threshold.",
    true,
    function(enabled)
        KeepSelectedPerks = enabled
        if PerkSection then
            PerkSection.Visible = enabled
        end
    end
)

local OffsetRow = Create("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 42),
}, PerkSection)

Label(OffsetRow, "Perk Offset (%)", 12, THEME.Text, true).Size = UDim2.new(1, -110, 1, 0)

local OffsetInput = Create("TextBox", {
    BackgroundColor3 = THEME.PanelLight,
    TextColor3 = THEME.Text,
    PlaceholderColor3 = THEME.Muted,
    Text = "0",
    PlaceholderText = "0-5",
    ClearTextOnFocus = false,
    TextSize = 14,
    Font = Enum.Font.Gotham,
    Size = UDim2.fromOffset(72, 28),
    Position = UDim2.new(1, -76, 0.5, -14),
}, OffsetRow)
Corner(OffsetInput, THEME.Radius.Button)
Stroke(OffsetInput, THEME.Border)

Runtime:Connect(OffsetInput.FocusLost, function()
    local value = tonumber(OffsetInput.Text)
    if not value then
        value = 0
    end
    value = math.clamp(math.floor(value + 0.5), 0, 5)
    PerkOffset = value
    OffsetInput.Text = tostring(value)
end)

local PerkNames = {}
for name in pairs(SavePerkTable) do
    table.insert(PerkNames, name)
end
table.sort(PerkNames)

for _, perkName in ipairs(PerkNames) do
    local perkData = SavePerkTable[perkName]
    Toggle(
        PerkSection,
        perkName,
        "Keep this perk at its selected quality or better.",
        false,
        function(enabled)
            if enabled then
                SelectedPerks[perkData.PerkName] = perkData
            else
                SelectedPerks[perkData.PerkName] = nil
            end
        end
    )
end

Toggle(
    SellSection,
    "Sell Pets",
    "Allow eligible pets below tier 5 to be sold unless a selected perk protects them.",
    false,
    function(enabled)
        IncludePets = enabled
    end
)

Toggle(
    SellSection,
    "Sell Charms",
    "Allow eligible charms below tier 5 to be sold unless a selected perk protects them.",
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

local UpgradeSection = Section(GearUpgradesPage, "Gear Upgrades")

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
        warn("[Yuri's QoL Suite] Manual inventory selling is only available in World Zero.")
        return
    end

    task.spawn(function()
        local ok, context = pcall(GetWorldZeroObjects)
        if not ok then
            warn("[Yuri's QoL Suite] Could not access the inventory.")
            return
        end

        local moduleOk, itemData, dropsModule = pcall(function()
            return require(context.Shared:WaitForChild("Items", 10)),
                require(context.Shared:WaitForChild("Drops", 10))
        end)

        if not moduleOk then
            warn("[Yuri's QoL Suite] Could not load inventory selling modules.")
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

local EggSection = Section(EggHatchingPage, "Egg Hatching")

local EggKeyInput = Create("TextBox", {
    Name = "EggKeyInput",
    ClearTextOnFocus = false,
    PlaceholderText = "Egg key: StarEgg, JungleEgg, CrystalEgg, DesertEgg, ChristmasEgg",
    Text = SelectedEggKey,
    TextSize = 13,
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
    TextSize = 13,
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

--==============================================================
-- SECTION 14 - GAMEPLAY PAGE
--==============================================================

local GameplayPage = CreatePage("Gameplay")

PageHeader(
    GameplayPage,
    "Gameplay",
    "Optional gameplay helpers for World Zero."
)

local WarningLabel = Label(
    GameplayPage,
    "Before you use these, make sure you're not in a party!",
    13,
    Color3.fromRGB(255, 190, 105),
    true
)
WarningLabel.Size = UDim2.new(1, -4, 0, 38)

local KnockdownSection = Section(GameplayPage, "Knockdown")
local ClassBuffSection = Section(GameplayPage, "Class Buffs")

local KnockdownEnabled = false
local KnockdownFunction = nil
local DisableKnockdownToggle
local AutoBuffEnabled = false
local AutoBuffToggle
local BuffKeyCode = Enum.KeyCode.B
local BuffKeybindLabel = Label(
    ClassBuffSection,
    "Buff Keybind: B (change in Settings)",
    13,
    THEME.Muted
)
BuffKeybindLabel.Size = UDim2.new(1, -4, 0, 28)

local DungeonPlaceIds = {
    ["107701891477606"] = true, ["83712338696299"] = true,
    ["2978696440"] = true, ["4310476380"] = true,
    ["4310464656"] = true, ["4310478830"] = true,
    ["3383444582"] = true, ["3885726701"] = true,
    ["3994953548"] = true, ["4050468028"] = true,
    ["3165900886"] = true, ["4465988196"] = true,
    ["4465989351"] = true, ["4465989998"] = true,
    ["4646473427"] = true, ["4646475342"] = true,
    ["4646475570"] = true, ["6386112652"] = true,
    ["11466514043"] = true, ["6510862058"] = true,
    ["11533444995"] = true, ["6847034886"] = true,
    ["11644048314"] = true, ["9944263348"] = true,
    ["10014664329"] = true, ["10651527284"] = true,
    ["10727165164"] = true, ["14914700740"] = true,
    ["14914855930"] = true, ["128961185668563"] = true,
    ["93889085342251"] = true, ["102111805987017"] = true,
    ["81373988789544"] = true, ["109614960834199"] = true,
    ["138178936582742"] = true, ["110769392907898"] = true,
    ["75540798045662"] = true, ["18567068844"] = true,
    ["5862277651"] = true, ["4526768588"] = true,
    ["5703353651"] = true, ["6075085184"] = true,
    ["7071564842"] = true, ["10089970465"] = true,
    ["10795158121"] = true, ["15121292578"] = true,
    ["14400549310"] = true, ["13988110964"] = true,
}

local function IsInDungeon()
    return game.GameId == WorldZeroId
        and DungeonPlaceIds[tostring(game.PlaceId)] == true
end

local function SetDisableKnockdown(enabled)
    if enabled == KnockdownEnabled then
        return
    end

    if enabled then
        if not IsInDungeon() then
            warn("[Yuri's QoL Suite] Disable Knockdown is only available inside a dungeon.")
            if DisableKnockdownToggle then DisableKnockdownToggle.SetSilent(false) end
            return
        end
        if type(HookFunction) ~= "function"
            or type(RestoreFunction) ~= "function"
            or type(NewClosure) ~= "function"
            or type(IsHooked) ~= "function" then
            warn("[Yuri's QoL Suite] Your executor does not support the required hook functions.")
            if DisableKnockdownToggle then DisableKnockdownToggle.SetSilent(false) end
            return
        end

        local success, result = pcall(function()
            local playerScripts = Player:WaitForChild("PlayerScripts", 10)
            local playerModule = playerScripts and playerScripts:WaitForChild("PlayerModule", 10)
            if not playerModule then
                error("PlayerModule was not found.")
            end
            GameCall(function()
                return require(playerModule)
            end)

            local client = ReplicatedStorage:WaitForChild("Client", 10)
            local actionsModule = client and client:WaitForChild("Actions", 10)
            if not actionsModule then
                error("Client.Actions was not found.")
            end
            local requireSucceeded, actions = GameCall(function()
                return require(actionsModule)
            end)
            if not requireSucceeded then
                error("Could not require Client.Actions: " .. tostring(actions))
            end
            if type(actions) ~= "table" or type(actions.Knockdown) ~= "function" then
                error("Client.Actions.Knockdown was not found.")
            end
            KnockdownFunction = actions.Knockdown
            HookFunction(KnockdownFunction, NewClosure(function()
                return
            end))
        end)

        if not success then
            KnockdownFunction = nil
            warn("[Yuri's QoL Suite] Could not enable Disable Knockdown: " .. tostring(result))
            if DisableKnockdownToggle then DisableKnockdownToggle.SetSilent(false) end
            return
        end
        KnockdownEnabled = true
    else
        if KnockdownFunction then
            pcall(function()
                if IsHooked(KnockdownFunction) then
                    RestoreFunction(KnockdownFunction)
                end
            end)
        end
        KnockdownFunction = nil
        KnockdownEnabled = false
    end
end

local BuffRemoteNames = {
    "Skillset_DualWielder_AttackBuff",
    "Skillset_Guardian_AggroDraw",
}

local function ApplyClassBuffs()
    if not IsInDungeon() then
        return
    end
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then
        return
    end
    for _, remoteName in ipairs(BuffRemoteNames) do
        local remote = remotesFolder:FindFirstChild(remoteName)
        if remote and remote:IsA("RemoteEvent") then
            pcall(function()
                remote:FireServer()
            end)
        end
    end
end

local function SetAutoBuff(enabled)
    AutoBuffEnabled = enabled
    if not enabled then
        return
    end
    if not IsInDungeon() then
        AutoBuffEnabled = false
        warn("[Yuri's QoL Suite] Class Buffs are only available inside a dungeon.")
        if AutoBuffToggle then AutoBuffToggle.SetSilent(false) end
        return
    end
    task.spawn(function()
        while AutoBuffEnabled and not Runtime.Unloaded do
            local character = Player.Character
            local health = character and character:FindFirstChild("HealthProperties")
            health = health and health:FindFirstChild("Health")
            if health and health.Value > 0 then
                ApplyClassBuffs()
            end
            task.wait(1)
        end
    end)
end

DisableKnockdownToggle = Toggle(
    KnockdownSection,
    "Disable Knockdown",
    "Prevents your character from entering the knockdown state.",
    false,
    SetDisableKnockdown
)

AutoBuffToggle = Toggle(
    ClassBuffSection,
    "Auto Buff",
    "Automatically applies both general class buffs once per second while alive.",
    false,
    SetAutoBuff
)

Runtime.RestoreGameplaySettings = function()
    AutoBuffEnabled = false
    if KnockdownEnabled and KnockdownFunction then
        pcall(function()
            if IsHooked and IsHooked(KnockdownFunction) then
                RestoreFunction(KnockdownFunction)
            end
        end)
    end
    KnockdownEnabled = false
    KnockdownFunction = nil
end


--==============================================================
-- SECTION 15 - ALERTS PAGE
--==============================================================

local AlertsPage = CreatePage("Alerts")

PageHeader(
    AlertsPage,
    "Notifications",
    "Configure the alerts displayed by Yuri's Quality of Life Suite."
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
-- SECTION 16 - SETTINGS PAGE
--==============================================================

local SettingsPage = CreatePage("Settings")

PageHeader(
    SettingsPage,
    "Settings",
    "Personalize your experience."
)

local InterfaceSection = Section(
    SettingsPage,
    "Interface"
)

local ToggleKeyCode = Enum.KeyCode.J
local WaitingForKeybind = false
local WaitingForBuffKeybind = false

local KeybindButton = Button(
    InterfaceSection,
    "Toggle UI Key: J",
    UDim2.new(1, 0, 0, 34)
)

Runtime:Connect(KeybindButton.Activated, function()
    if Runtime.Unloaded then
        return
    end

    WaitingForBuffKeybind = false
    WaitingForKeybind = true
    KeybindButton.Text = "Press a key..."
end)

local GameplayKeybindSection = Section(SettingsPage, "Gameplay")
local BuffKeybindButton = Button(
    GameplayKeybindSection,
    "Class Buff Key: B",
    UDim2.new(1, 0, 0, 34)
)

Runtime:Connect(BuffKeybindButton.Activated, function()
    if Runtime.Unloaded then
        return
    end

    WaitingForKeybind = false
    WaitingForBuffKeybind = true
    BuffKeybindButton.Text = "Press a key..."
end)


local ResetLightingButton = Button(
    SettingsPage,
    "Reset Enhanced Lighting",
    UDim2.new(1, 0, 0, 38)
)

Runtime:Connect(ResetLightingButton.Activated, function()
    if ResetEnhancedLighting then
        ResetEnhancedLighting()
    end
end)


local UnloadButton = Button(
    SettingsPage,
    "Unload Suite",
    UDim2.new(1, 0, 0, 38)
)

UnloadButton.BackgroundColor3 = Color3.fromRGB(65, 31, 42)
UnloadButton.TextColor3 = Color3.fromRGB(255, 160, 170)


--==============================================================
-- SECTION 17 - NAVIGATION
--==============================================================
local Navigation = {
    {Name = "Home", Symbol = "・"},
    {Name = "Visuals", Symbol = "・"},
    {Name = "Gameplay", Symbol = "・"},
    {Name = "Inventory", Symbol = "・"},
    {Name = "Egg Hatching", Symbol = "・"},
    {Name = "Gear Upgrades", Symbol = "・"},
    {Name = "Alerts", Symbol = "・"},
    {Name = "Settings", Symbol = "・"},
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
        warn("[Yuri's QoL Suite] Navigation error: Page not found - " .. tostring(name))
        return
    end

    if CurrentPage == name then
        return
    end

    local nextPosition = PagePositions[name]
    if not nextPosition then
        warn("[Yuri's QoL Suite] Navigation error: Missing page position - " .. tostring(name))
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
        TextSize = 14,
        Font = Enum.Font.GothamMedium,

        TextColor3 = THEME.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,

        BackgroundColor3 = THEME.Sidebar,
        Size = UDim2.new(1, 0, 0, 40),
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
-- SECTION 18 - WINDOW DRAGGING
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

local function SetMinimized(value)
    if Runtime.Unloaded or minimized == value then
        return
    end

    minimized = value

    if minimized then
        Main.Visible = false
        RestoreButton.Visible = true
    else
        -- Always restore the main window in the center of the screen.
        Main.Position = UDim2.fromScale(0.5, 0.5)
        Main.Size = CONFIG.WindowSize
        Main.Visible = true
        RestoreButton.Visible = false
    end
end

Runtime:Connect(MinimizeButton.Activated, function()
    SetMinimized(true)
end)

Runtime:Connect(RestoreButton.Activated, function()
    SetMinimized(false)
end)

Runtime:Connect(UserInputService.InputBegan, function(input, gameProcessed)
    if Runtime.Unloaded then
        return
    end

    if WaitingForKeybind or WaitingForBuffKeybind then
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        if WaitingForKeybind then
            if input.KeyCode == Enum.KeyCode.Escape then
                WaitingForKeybind = false
                KeybindButton.Text = "Toggle UI Key: " .. ToggleKeyCode.Name
                return
            end
            ToggleKeyCode = input.KeyCode
            WaitingForKeybind = false
            KeybindButton.Text = "Toggle UI Key: " .. ToggleKeyCode.Name
            return
        end

        if input.KeyCode == Enum.KeyCode.Escape then
            WaitingForBuffKeybind = false
            BuffKeybindButton.Text = "Class Buff Key: " .. BuffKeyCode.Name
            return
        end
        BuffKeyCode = input.KeyCode
        WaitingForBuffKeybind = false
        BuffKeybindButton.Text = "Class Buff Key: " .. BuffKeyCode.Name
        BuffKeybindLabel.Text = "Buff Keybind: " .. BuffKeyCode.Name .. " (change in Settings)"
        return
    end

    if gameProcessed or UserInputService:GetFocusedTextBox() then
        return
    end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == BuffKeyCode then
            ApplyClassBuffs()
            return
        end
        if input.KeyCode == ToggleKeyCode then
            SetMinimized(not minimized)
        end
    end
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
    "Unload Yuri's Quality of Life Suite?",
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
print("[Yuri's QoL Suite] Successfully initialized.")
print("[Yuri's QoL Suite] Version: " .. CONFIG.Version)
print("[Yuri's QoL Suite] Theme: Premium Violet")
print("[Yuri's QoL Suite] Runtime cleanup: Enabled")
print("================================")
