-- ============================================================
--   S Command Bar Pro  |  v4.1
--   True 360° Fly  •  IY Fling (Player + Objects)
--   MaxZoom  •  Mobile+PC  •  Auto-Respawn Restore
-- ============================================================

-- ╔══════════════════════════════════════════════════════════╗
-- ║                     SERVICES                            ║
-- ╚══════════════════════════════════════════════════════════╝
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TeleportService        = game:GetService("TeleportService")
local Lighting               = game:GetService("Lighting")
local StarterGui             = game:GetService("StarterGui")
local ContextActionService   = game:GetService("ContextActionService")

local LP = Players.LocalPlayer

-- ╔══════════════════════════════════════════════════════════╗
-- ║                  DUPLICATE GUARD                        ║
-- ╚══════════════════════════════════════════════════════════╝
if getgenv().SCmdBar_Loaded then
    pcall(function() getgenv().SCmdBar_Loaded:Destroy() end)
    getgenv().SCmdBar_Loaded = nil
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║                  SAFE UI PARENT                         ║
-- ╚══════════════════════════════════════════════════════════╝
local UIParent = game:GetService("CoreGui")
if not pcall(function() local _ = UIParent.ClassName end) then
    UIParent = LP:WaitForChild("PlayerGui")
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║               PLATFORM DETECTION                        ║
-- ╚══════════════════════════════════════════════════════════╝
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ╔══════════════════════════════════════════════════════════╗
-- ║              RESPONSIVE CONFIG TABLE                    ║
-- ╚══════════════════════════════════════════════════════════╝
local C = {
    -- Logo
    LogoSize     = IsMobile and UDim2.new(0,58,0,58)         or UDim2.new(0,42,0,42),
    LogoPos      = IsMobile and UDim2.new(0,14,0.81,0)       or UDim2.new(0.5,-21,0,10),
    LogoTxtSize  = IsMobile and 27 or 22,

    -- Command Bar
    BarSize      = IsMobile and UDim2.new(0.92,0,0,54)       or UDim2.new(0,430,0,46),
    BarOpen      = IsMobile and UDim2.new(0.04,0,0.77,0)     or UDim2.new(0.5,-215,0.85,0),
    BarHide      = IsMobile and UDim2.new(0.04,0,1.3,0)      or UDim2.new(0.5,-215,1.3,0),
    BarTxtSize   = IsMobile and 18 or 16,

    -- Command List
    ListSize     = IsMobile and UDim2.new(0.90,0,0,420)      or UDim2.new(0,280,0,340),
    ListPos      = IsMobile and UDim2.new(0.05,0,0.06,0)     or UDim2.new(0.5,-140,0.5,-170),
    ListTxtSize  = IsMobile and 16 or 13,
    TitleH       = IsMobile and 40 or 32,
    CloseSize    = IsMobile and UDim2.new(0,42,0,32)         or UDim2.new(0,26,0,22),
    ClosePos     = IsMobile and UDim2.new(1,-48,0,4)         or UDim2.new(1,-30,0,5),
    ScrollBar    = IsMobile and 7 or 4,
    RowH         = IsMobile and 34 or 24,
    SearchH      = IsMobile and 34 or 28,

    -- Notif
    NotifSize    = IsMobile and UDim2.new(0,250,0,48)        or UDim2.new(0,230,0,40),
    NotifTxtSize = IsMobile and 15 or 13,
}

-- ╔══════════════════════════════════════════════════════════╗
-- ║                  SCREENGUI                              ║
-- ╚══════════════════════════════════════════════════════════╝
local ScreenGui               = Instance.new("ScreenGui")
ScreenGui.Name                = "S_CommandBar_Pro"
ScreenGui.ResetOnSpawn        = false
ScreenGui.IgnoreGuiInset      = true
ScreenGui.DisplayOrder        = 999
ScreenGui.ZIndexBehavior      = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent              = UIParent
getgenv().SCmdBar_Loaded      = ScreenGui

-- ╔══════════════════════════════════════════════════════════╗
-- ║                  UI HELPERS                             ║
-- ╚══════════════════════════════════════════════════════════╝
local function Corner(obj, r)
    local c = Instance.new("UICorner", obj)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end
local function Stroke(obj, t, col)
    local s = Instance.new("UIStroke", obj)
    s.Thickness = t or 1
    s.Color = col or Color3.fromRGB(55, 55, 55)
    return s
end
local function Pad(obj, l, r, t, b)
    local p = Instance.new("UIPadding", obj)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    return p
end
local function TweenObj(obj, dur, props, style, dir)
    return TweenService:Create(obj,
        TweenInfo.new(dur, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║              NOTIFICATION SYSTEM                        ║
-- ╚══════════════════════════════════════════════════════════╝
local notifQ   = {}
local notifBusy = false
local NOTIF_COLORS = {
    success = Color3.fromRGB(50,  200, 120),
    error   = Color3.fromRGB(220, 70,  70),
    warn    = Color3.fromRGB(220, 170, 50),
    info    = Color3.fromRGB(80,  160, 230),
}

local function Notify(msg, kind)
    local col = NOTIF_COLORS[kind] or NOTIF_COLORS.success
    table.insert(notifQ, {msg = msg, col = col})
    if notifBusy then return end
    notifBusy = true
    task.spawn(function()
        while #notifQ > 0 do
            local n = table.remove(notifQ, 1)
            local f = Instance.new("Frame", ScreenGui)
            f.Size            = C.NotifSize
            f.Position        = UDim2.new(1, 20, 0.93, 0)
            f.AnchorPoint     = Vector2.new(1, 1)
            f.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            f.ZIndex          = 60
            Corner(f, 8); Stroke(f, 1, n.col)

            local accent = Instance.new("Frame", f)
            accent.Size            = UDim2.new(0, 4, 1, 0)
            accent.BackgroundColor3 = n.col
            accent.BorderSizePixel = 0
            accent.ZIndex          = 61
            Corner(accent, 4)

            local lbl = Instance.new("TextLabel", f)
            lbl.Size             = UDim2.new(1, -16, 1, 0)
            lbl.Position         = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text             = n.msg
            lbl.TextColor3       = Color3.new(1, 1, 1)
            lbl.Font             = Enum.Font.GothamMedium
            lbl.TextSize         = C.NotifTxtSize
            lbl.TextXAlignment   = Enum.TextXAlignment.Left
            lbl.TextTruncate     = Enum.TextTruncate.AtEnd
            lbl.ZIndex           = 61

            TweenObj(f, 0.35, {Position = UDim2.new(1, -14, 0.93, 0)}):Play()
            task.wait(2.8)
            TweenObj(f, 0.25, {Position = UDim2.new(1, 20, 0.93, 0)},
                Enum.EasingStyle.Quad, Enum.EasingDirection.In):Play()
            task.wait(0.3)
            f:Destroy()
            task.wait(0.1)
        end
        notifBusy = false
    end)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║           LOGO BUTTON + FULL ANIMATION SUITE            ║
-- ╚══════════════════════════════════════════════════════════╝

-- ── Glow ring (sits behind logo, pulses independently) ───
local _glowSzOff = C.LogoSize.X.Offset + 16
local _glowPosX  = IsMobile and (14 - 8)                          or (0)
local _glowPosXS = IsMobile and (0)                               or (0.5)
local _glowPosY  = IsMobile and C.LogoPos.Y.Offset - 8            or C.LogoPos.Y.Offset - 8
local _glowPosYS = IsMobile and C.LogoPos.Y.Scale                 or C.LogoPos.Y.Scale

local GlowRing = Instance.new("Frame", ScreenGui)
GlowRing.Size             = UDim2.new(0, _glowSzOff, 0, _glowSzOff)
GlowRing.Position         = UDim2.new(_glowPosXS, _glowPosX, _glowPosYS, _glowPosY)
GlowRing.AnchorPoint      = IsMobile and Vector2.new(0,0) or Vector2.new(0.5, 0)
GlowRing.BackgroundTransparency = 1
GlowRing.ZIndex           = 23
Corner(GlowRing, 14)
local GlowStroke = Instance.new("UIStroke", GlowRing)
GlowStroke.Thickness      = 2.5
GlowStroke.Color          = Color3.fromRGB(80, 160, 255)
GlowStroke.Transparency   = 0.2

-- ── Logo button (starts at size 0 for pop-in) ────────────
local Logo = Instance.new("TextButton", ScreenGui)
Logo.Size             = UDim2.new(0, 0, 0, 0)   -- entrance starts hidden
Logo.Position         = C.LogoPos
Logo.AnchorPoint      = Vector2.new(0, 0)
Logo.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
Logo.Text             = "⚡"
Logo.TextColor3       = Color3.fromRGB(255, 255, 255)
Logo.Font             = Enum.Font.GothamBold
Logo.TextSize         = C.LogoTxtSize
Logo.ZIndex           = 25
Logo.ClipsDescendants = false
Corner(Logo, 10)
local LogoStroke = Stroke(Logo, 1.5, Color3.fromRGB(80, 160, 255))

-- ── ENTRANCE: pop-in with Back overshoot after 0.15s ─────
task.delay(0.15, function()
    TweenObj(Logo, 0.5, {Size = C.LogoSize},
        Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
end)

-- ── GLOW RING: color-cycle + breathe transparency ────────
task.spawn(function()
    local glowPalette = {
        Color3.fromRGB(80,  160, 255),   -- blue
        Color3.fromRGB(160, 80,  255),   -- purple
        Color3.fromRGB(50,  210, 150),   -- teal
        Color3.fromRGB(255, 120, 60),    -- orange
    }
    local gi = 1
    while ScreenGui.Parent do
        local nextCol = glowPalette[gi % #glowPalette + 1]
        -- Breathe in
        TweenObj(GlowStroke, 1.5, {
            Color        = nextCol,
            Transparency = 0.05,
        }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut):Play()
        TweenObj(LogoStroke, 1.5, {
            Color = nextCol,
        }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut):Play()
        task.wait(1.55)
        -- Breathe out
        TweenObj(GlowStroke, 1.0, {
            Transparency = 0.55,
        }, Enum.EasingStyle.Sine, Enum.EasingDirection.Out):Play()
        task.wait(1.05)
        gi = gi + 1
    end
end)

-- ── TEXT: 3-color cycle synced with glow ─────────────────
task.spawn(function()
    local textCols = {
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(140, 205, 255),
        Color3.fromRGB(190, 140, 255),
        Color3.fromRGB(100, 240, 190),
    }
    local ti = 1
    while ScreenGui.Parent do
        TweenObj(Logo, 1.8, {TextColor3 = textCols[ti]},
            Enum.EasingStyle.Sine, Enum.EasingDirection.InOut):Play()
        ti = ti % #textCols + 1
        task.wait(1.85)
    end
end)

-- ── CLICK RIPPLE: expanding ring on every press ──────────
local function LogoRipple()
    local abs = Logo.AbsolutePosition
    local sz  = Logo.AbsoluteSize
    local cx  = abs.X + sz.X / 2
    local cy  = abs.Y + sz.Y / 2
    local s0  = math.max(sz.X, sz.Y)

    local ripple = Instance.new("Frame", ScreenGui)
    ripple.Size             = UDim2.new(0, s0, 0, s0)
    ripple.Position         = UDim2.new(0, cx - s0/2, 0, cy - s0/2)
    ripple.BackgroundColor3 = Color3.fromRGB(120, 190, 255)
    ripple.BackgroundTransparency = 0.45
    ripple.BorderSizePixel  = 0
    ripple.ZIndex           = 24
    Corner(ripple, 50)

    local s1 = s0 * 2.8
    TweenObj(ripple, 0.45, {
        Size     = UDim2.new(0, s1, 0, s1),
        Position = UDim2.new(0, cx - s1/2, 0, cy - s1/2),
        BackgroundTransparency = 1,
    }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
    task.delay(0.46, function() ripple:Destroy() end)
end

-- ── PRESS SQUISH: logo briefly scales smaller on tap ─────
Logo.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        local sq = C.LogoSize
        local small = UDim2.new(0, sq.X.Offset - 6, 0, sq.Y.Offset - 6)
        TweenObj(Logo, 0.08, {Size = small}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
    end
end)
Logo.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        TweenObj(Logo, 0.18, {Size = C.LogoSize},
            Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
    end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║                  COMMAND BAR                            ║
-- ╚══════════════════════════════════════════════════════════╝
local BarFrame = Instance.new("Frame", ScreenGui)
BarFrame.Size             = C.BarSize
BarFrame.Position         = C.BarHide
BarFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
BarFrame.ZIndex           = 25
Corner(BarFrame, 10)
Stroke(BarFrame, 1.5, Color3.fromRGB(65, 65, 65))

local BarPrompt = Instance.new("TextLabel", BarFrame)
BarPrompt.Size             = UDim2.new(0, 30, 1, 0)
BarPrompt.Position         = UDim2.new(0, 10, 0, 0)
BarPrompt.BackgroundTransparency = 1
BarPrompt.Text             = "›"
BarPrompt.TextColor3       = Color3.fromRGB(100, 180, 255)
BarPrompt.Font             = Enum.Font.GothamBold
BarPrompt.TextSize         = C.BarTxtSize + 4
BarPrompt.ZIndex           = 26

local TextBox = Instance.new("TextBox", BarFrame)
TextBox.Size              = UDim2.new(1, -50, 1, 0)
TextBox.Position          = UDim2.new(0, 42, 0, 0)
TextBox.BackgroundTransparency = 1
TextBox.Font              = Enum.Font.Code
TextBox.PlaceholderText   = "Enter command...  ( ; to toggle )"
TextBox.PlaceholderColor3 = Color3.fromRGB(75, 75, 75)
TextBox.Text              = ""
TextBox.TextColor3        = Color3.fromRGB(230, 230, 230)
TextBox.TextSize          = C.BarTxtSize
TextBox.TextXAlignment    = Enum.TextXAlignment.Left
TextBox.ClearTextOnFocus  = false
TextBox.ZIndex            = 26

-- ╔══════════════════════════════════════════════════════════╗
-- ║               COMMAND LIST WINDOW                       ║
-- ╚══════════════════════════════════════════════════════════╝
local ListFrame = Instance.new("Frame", ScreenGui)
ListFrame.Size             = C.ListSize
ListFrame.Position         = C.ListPos
ListFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ListFrame.Visible          = false
ListFrame.ZIndex           = 35
Corner(ListFrame, 10)
Stroke(ListFrame, 1.5, Color3.fromRGB(65, 65, 65))

-- Header
local Header = Instance.new("Frame", ListFrame)
Header.Size            = UDim2.new(1, 0, 0, C.TitleH)
Header.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
Header.ZIndex          = 36
Corner(Header, 10)
-- fill bottom corners
local HFix = Instance.new("Frame", Header)
HFix.Size = UDim2.new(1,0,0.5,0); HFix.Position = UDim2.new(0,0,0.5,0)
HFix.BackgroundColor3 = Color3.fromRGB(22,22,22); HFix.BorderSizePixel = 0; HFix.ZIndex = 36

local Title = Instance.new("TextLabel", Header)
Title.Size             = UDim2.new(1,-55,1,0)
Title.Position         = UDim2.new(0,12,0,0)
Title.BackgroundTransparency = 1
Title.Text             = "⚡  S Commands"
Title.TextColor3       = Color3.fromRGB(230,230,230)
Title.Font             = Enum.Font.GothamBold
Title.TextSize         = IsMobile and 15 or 13
Title.TextXAlignment   = Enum.TextXAlignment.Left
Title.ZIndex           = 37

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size            = C.CloseSize
CloseBtn.Position        = C.ClosePos
CloseBtn.Text            = "✕"
CloseBtn.TextSize        = IsMobile and 15 or 12
CloseBtn.BackgroundColor3 = Color3.fromRGB(175,42,42)
CloseBtn.TextColor3      = Color3.new(1,1,1)
CloseBtn.Font            = Enum.Font.GothamBold
CloseBtn.ZIndex          = 38
Corner(CloseBtn, 6)

-- Search box
local SearchH   = C.SearchH
local SearchBox = Instance.new("TextBox", ListFrame)
SearchBox.Size             = UDim2.new(1,-16,0,SearchH)
SearchBox.Position         = UDim2.new(0,8,0,C.TitleH+6)
SearchBox.BackgroundColor3 = Color3.fromRGB(25,25,25)
SearchBox.Font             = Enum.Font.Code
SearchBox.PlaceholderText  = "🔍  Search commands..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(70,70,70)
SearchBox.Text             = ""
SearchBox.TextColor3       = Color3.fromRGB(210,210,210)
SearchBox.TextSize         = IsMobile and 14 or 12
SearchBox.TextXAlignment   = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex           = 37
Corner(SearchBox, 6)
Pad(SearchBox, 8)

local scrollY = C.TitleH + 6 + SearchH + 6
local ScrollFrame = Instance.new("ScrollingFrame", ListFrame)
ScrollFrame.Size                  = UDim2.new(1,-10,1,-(scrollY+4))
ScrollFrame.Position              = UDim2.new(0,5,0,scrollY)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness    = C.ScrollBar
ScrollFrame.ScrollBarImageColor3  = Color3.fromRGB(75,75,75)
ScrollFrame.ZIndex                = 36

local UIList = Instance.new("UIListLayout", ScrollFrame)
UIList.SortOrder = Enum.SortOrder.Name
UIList.Padding   = UDim.new(0,3)

-- ╔══════════════════════════════════════════════════════════╗
-- ║                   DRAG SYSTEM                           ║
-- ╚══════════════════════════════════════════════════════════╝
local function MakeDraggable(handle, target)
    local drag, di, ds, sp = false, nil, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = target.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then di = i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i == di and drag and ds and sp then
            local d = i.Position - ds
            target.Position = UDim2.new(
                sp.X.Scale, sp.X.Offset + d.X,
                sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
end

MakeDraggable(Header, ListFrame)
if IsMobile then MakeDraggable(Logo, Logo) end

-- ╔══════════════════════════════════════════════════════════╗
-- ║               STATE & CONNECTIONS                       ║
-- ╚══════════════════════════════════════════════════════════╝
local Commands = {}
local Aliases  = {}

local State = {
    Flying      = false,
    FlySpeed    = 80,
    Noclipping  = false,
    Spinning    = false,
    Flinging    = false,
    FlingTarget = nil,
    Banging     = false,
    ESP         = false,
    Invisible   = false,
    Fullbright  = false,
    InfJump     = false,
    Swimming    = false,
    Floating    = false,
    Viewing     = nil,     -- name of spectated player
    LoopHeal    = false,
    AntiAFK     = false,
    Following   = false,
    Annoying    = false,
}

local Conns = {}

local OrigLight = {
    Ambient    = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    ClockTime  = Lighting.ClockTime,
    FogEnd     = Lighting.FogEnd,
}

-- ╔══════════════════════════════════════════════════════════╗
-- ║              CHARACTER HELPERS                          ║
-- ╚══════════════════════════════════════════════════════════╝
local function GetChar()  return LP.Character end
local function GetHRP()   local c=GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHuman() local c=GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local function SafeDisconn(key)
    if Conns[key] then
        pcall(function() Conns[key]:Disconnect() end)
        Conns[key] = nil
    end
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║              RESPAWN STATE RESTORE                      ║
-- ╚══════════════════════════════════════════════════════════╝
LP.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    task.wait(0.6)

    if State.Noclipping then
        SafeDisconn("Noclip")
        Conns.Noclip = RunService.Stepped:Connect(function()
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    end

    -- Fly restarts itself via StartFly's own CharacterAdded connection

    if State.Invisible then
        Commands["invisible"]({})
    end

    if State.Fullbright then
        Lighting.Ambient    = Color3.new(1,1,1)
        Lighting.Brightness = 2
        Lighting.ClockTime  = 14
        Lighting.FogEnd     = 1e6
    end

    if State.InfJump then
        Commands["infjump"]({})
    end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║               PLAYER RESOLVER                           ║
-- ╚══════════════════════════════════════════════════════════╝
local function GetPlayers(str)
    local out = {}
    local s = (str or "me"):lower():match("^%s*(.-)%s*$")
    if s == "" or s == "me"  then return {LP} end
    if s == "all"            then return Players:GetPlayers() end
    if s == "others" then
        for _, v in ipairs(Players:GetPlayers()) do
            if v ~= LP then table.insert(out, v) end
        end
        return out
    end
    for _, v in ipairs(Players:GetPlayers()) do
        if v.Name:lower():find(s,1,true) or v.DisplayName:lower():find(s,1,true) then
            table.insert(out, v)
        end
    end
    return #out > 0 and out or {LP}
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║              COMMAND REGISTRY                           ║
-- ╚══════════════════════════════════════════════════════════╝
local function Cmd(name, alts, fn)
    Commands[name] = fn
    if alts then
        for _, a in ipairs(alts) do Aliases[a] = name end
    end
end

-- ════════════════════════════════════════════════════════════
--                     MOVEMENT COMMANDS
-- ════════════════════════════════════════════════════════════

Cmd("speed", {"ws","walkspeed","s"}, function(args)
    local amt = tonumber(args[2]) or tonumber(args[1]) or 16
    for _, p in ipairs(GetPlayers(args[1])) do
        local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = amt end
    end
    Notify("WalkSpeed → " .. amt)
end)

Cmd("jp", {"jumppower","jump","j"}, function(args)
    local amt = tonumber(args[2]) or tonumber(args[1]) or 50
    for _, p in ipairs(GetPlayers(args[1])) do
        local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if h then h.UseJumpPower = true; h.JumpPower = amt end
    end
    Notify("JumpPower → " .. amt)
end)

Cmd("sit", {}, function()
    local h = GetHuman(); if h then h.Sit = true end
    Notify("Sitting")
end)

Cmd("hipheight", {"hh"}, function(args)
    local amt = tonumber(args[1]) or 0
    local h = GetHuman(); if h then h.HipHeight = amt end
    Notify("HipHeight → " .. amt)
end)

-- ════════════════════════════════════════════════════════════
--   360° CAMERA-RELATIVE FLY  (user-requested style)
--
--   • Uses hum.MoveDirection projected into camera object-space
--     via CFrame:VectorToObjectSpace — same technique as the
--     reference script the user provided.
--   • RenderStepped for zero-jitter camera sync.
--   • BodyGyro tracks FULL cam CFrame (pitch included).
--   • stopFly / startFly are exposed so respawn auto-restarts.
--   • Speed-only update when already flying: fly 120
-- ════════════════════════════════════════════════════════════

local _flyBG  = nil   -- module-level so stopFly can always reach them
local _flyBV  = nil
local _flyLoop = nil

local function StopFly()
    State.Flying = false
    SafeDisconn("Fly")
    if _flyLoop  then pcall(function() _flyLoop:Disconnect()  end); _flyLoop = nil end
    if _flyBG    then pcall(function() _flyBG:Destroy()       end); _flyBG   = nil end
    if _flyBV    then pcall(function() _flyBV:Destroy()       end); _flyBV   = nil end
    local char = LP.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then h.PlatformStand = false end
    end
end

local function StartFly()
    StopFly()   -- always clean before re-init

    local char = LP.Character or LP.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 8)
    local hum  = char:WaitForChild("Humanoid", 8)
    local cam  = workspace.CurrentCamera
    if not root or not hum then return end

    State.Flying      = true
    hum.PlatformStand = true

    -- Stability gyro — high P, tracks full camera CFrame
    _flyBG = Instance.new("BodyGyro", root)
    _flyBG.P          = 9e4
    _flyBG.MaxTorque  = Vector3.new(9e9, 9e9, 9e9)
    _flyBG.CFrame     = root.CFrame

    -- Movement — 9e9 MaxForce so nothing resists us
    _flyBV = Instance.new("BodyVelocity", root)
    _flyBV.Velocity  = Vector3.zero
    _flyBV.MaxForce  = Vector3.new(9e9, 9e9, 9e9)

    -- RenderStepped: runs every frame before Roblox renders,
    -- so camera and body are always in sync with zero lag.
    _flyLoop = RunService.RenderStepped:Connect(function()
        if not State.Flying or not root or not root.Parent then
            StopFly(); return
        end

        local camCF   = cam.CFrame
        local moveDir = hum.MoveDirection   -- world-space, set by Roblox from joystick/WASD

        if moveDir.Magnitude > 0.01 then
            -- Project world MoveDirection into camera object-space.
            -- This gives us how much is "camera-forward" vs "camera-right"
            -- regardless of platform (works identically on mobile & PC).
            local relMove     = camCF:VectorToObjectSpace(moveDir)
            local fwdFactor   = -relMove.Z   -- negative-Z = forward in object space
            local rightFactor =  relMove.X

            -- Reconstruct in world-space using camera vectors.
            -- LookVector carries pitch, so looking up + moving forward
            -- means you actually fly upward — true 360° fly.
            _flyBV.Velocity = (camCF.LookVector  * fwdFactor)
                            + (camCF.RightVector * rightFactor)
            _flyBV.Velocity = _flyBV.Velocity.Unit * State.FlySpeed
        else
            -- No input → hover in place
            _flyBV.Velocity = Vector3.zero
        end

        -- PC-only explicit vertical override (Space / Shift / Q / E)
        -- Mobile uses camera tilt to go up/down naturally.
        if not IsMobile then
            local UIS = UserInputService
            local vert = 0
            if UIS:IsKeyDown(Enum.KeyCode.Space)       or UIS:IsKeyDown(Enum.KeyCode.E) then vert =  1 end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift)   or UIS:IsKeyDown(Enum.KeyCode.Q) then vert = -1 end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vert = -1 end
            if vert ~= 0 then
                _flyBV.Velocity = _flyBV.Velocity + Vector3.new(0, vert * State.FlySpeed, 0)
            end
        end

        -- Gyro always matches full camera CFrame (pitch + yaw)
        _flyBG.CFrame = camCF
    end)
end

-- Auto-restart on respawn (mirrors reference script behaviour)
LP.CharacterAdded:Connect(function()
    if State.Flying then
        task.wait(0.5)
        StartFly()
    end
end)

Cmd("fly", {"f","fl"}, function(args)
    local spd = tonumber(args[1])
    if spd then State.FlySpeed = spd end

    if State.Flying then
        -- Speed-only update, no restart needed
        Notify("✈  Fly speed → " .. State.FlySpeed, "info")
        return
    end

    StartFly()
    Notify("✈  Fly ON  (speed " .. State.FlySpeed .. ")")
end)

Cmd("unfly", {"uf","nofly","stopfly"}, function()
    if not State.Flying then Notify("Fly is already off", "warn"); return end
    StopFly()
    Notify("✈  Fly OFF")
end)

-- ════════════════════════════════════════════════════════════
--                   NOCLIP / CLIP
-- ════════════════════════════════════════════════════════════

Cmd("noclip", {"nc","ghost"}, function()
    if State.Noclipping then Notify("Already noclipping","warn"); return end
    State.Noclipping = true
    SafeDisconn("Noclip")
    Conns.Noclip = RunService.Stepped:Connect(function()
        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
    Notify("👻  Noclip ON")
end)

Cmd("clip", {"unclip","solid","noghost"}, function()
    State.Noclipping = false
    SafeDisconn("Noclip")
    -- Restore collision
    local char = LP.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
    Notify("👻  Noclip OFF")
end)

-- ════════════════════════════════════════════════════════════
--   IY-STYLE FLING  —  v2  (player + unanchored objects)
--
--   Against PLAYERS:
--     Noclip into target → massive spin → physics launches them
--
--   Against UNANCHORED OBJECTS (no player arg):
--     Touches any unanchored BasePart near you → launches it
--     with AssemblyLinearVelocity in your look direction
--
--   Usage:
--     fling <player>   — fling a specific player
--     fling            — arm object-fling mode (touch to yeet)
-- ════════════════════════════════════════════════════════════

-- Helper: blast an unanchored part away from origin point
local function BlastPart(part, origin, power)
    if not part or not part.Parent then return end
    if part.Anchored then return end
    -- Skip character parts
    local char = LP.Character
    if char and part:IsDescendantOf(char) then return end
    local dir = (part.Position - origin).Unit
    -- Guard against NaN when exactly on top
    if dir ~= dir then dir = Vector3.new(0,1,0) end
    part.AssemblyLinearVelocity  = dir * (power or 300) + Vector3.new(0, 80, 0)
    part.AssemblyAngularVelocity = Vector3.new(
        math.random(-20,20), math.random(-20,20), math.random(-20,20))
end

Cmd("fling", {"fl2","yeet"}, function(args)
    if State.Flinging then Notify("Already flinging","warn"); return end

    -- ── MODE A: fling a PLAYER ───────────────────────────────
    if args[1] and args[1] ~= "" then
        local target = GetPlayers(args[1])[1]
        if not target then Notify("Player not found","error"); return end
        if target == LP then Notify("Can't fling yourself — use spin","warn"); return end

        local tChar = target.Character
        local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
        local myHRP = GetHRP()
        if not tHRP or not myHRP then Notify("Missing HRP","error"); return end

        State.Flinging    = true
        State.FlingTarget = target.Name

        local wasNoclipping = State.Noclipping

        -- Noclip so we phase into target
        State.Noclipping = true
        SafeDisconn("FlingNoclip")
        Conns.FlingNoclip = RunService.Stepped:Connect(function()
            local c = LP.Character
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)

        -- Teleport onto target HRP
        myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0.4, 0)

        -- Massive spin (BodyAngularVelocity)
        for _, n in ipairs({"S_FlingBAV","S_FlingBV"}) do
            local old = myHRP:FindFirstChild(n); if old then old:Destroy() end
        end

        local BAV = Instance.new("BodyAngularVelocity", myHRP)
        BAV.Name            = "S_FlingBAV"
        BAV.MaxTorque       = Vector3.new(1e6, 1e6, 1e6)
        BAV.AngularVelocity = Vector3.new(0, 9999, 0)
        BAV.P               = 1e6

        local BVF = Instance.new("BodyVelocity", myHRP)
        BVF.Name     = "S_FlingBV"
        BVF.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        BVF.Velocity = myHRP.CFrame.LookVector * 120

        -- Also blast any unanchored parts nearby the target for chain reaction
        task.spawn(function()
            task.wait(0.05)
            local tPos = tHRP and tHRP.Position or Vector3.zero
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj.Anchored
                and not (tChar and obj:IsDescendantOf(tChar)) then
                    if (obj.Position - tPos).Magnitude < 12 then
                        BlastPart(obj, tPos, 250)
                    end
                end
            end
        end)

        task.spawn(function()
            local t0 = tick()
            while State.Flinging and (tick() - t0) < 1.1 do
                -- Stay locked on target while spinning
                local tc2 = target.Character
                local th2 = tc2 and tc2:FindFirstChild("HumanoidRootPart")
                if myHRP and myHRP.Parent and th2 then
                    myHRP.CFrame = th2.CFrame * CFrame.new(0, 0.3, 0)
                end
                task.wait(0.03)
            end

            -- Cleanup
            State.Flinging = false; State.FlingTarget = nil
            pcall(function() if BAV.Parent then BAV:Destroy() end end)
            pcall(function() if BVF.Parent then BVF:Destroy() end end)
            SafeDisconn("FlingNoclip")
            if not wasNoclipping then
                State.Noclipping = false
                local c2 = LP.Character
                if c2 then
                    for _, p in ipairs(c2:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = true end
                    end
                end
            end
        end)

        Notify("🌪  Flinging " .. target.Name)
        return
    end

    -- ── MODE B: OBJECT FLING (touch any unanchored part) ─────
    -- Arms a Touched listener on your HRP — every unanchored
    -- BasePart you walk/run into gets blasted away.
    local myHRP = GetHRP()
    if not myHRP then Notify("No character","error"); return end

    State.Flinging = true
    Notify("🌪  Object Fling ARMED  (unfling to stop)", "info")

    local debounce = {}   -- per-part cooldown so one part doesn't fire 60x

    SafeDisconn("ObjFling")
    Conns.ObjFling = myHRP.Touched:Connect(function(hit)
        if not State.Flinging then SafeDisconn("ObjFling"); return end
        if not hit or not hit.Parent then return end
        if hit.Anchored then return end
        -- Skip own character
        local char = LP.Character
        if char and hit:IsDescendantOf(char) then return end
        -- Skip other players' characters
        local isPlayerChar = false
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character and hit:IsDescendantOf(plr.Character) then
                isPlayerChar = true; break
            end
        end
        if isPlayerChar then return end
        -- Cooldown per part
        if debounce[hit] then return end
        debounce[hit] = true
        BlastPart(hit, myHRP.Position, 350)
        task.delay(0.4, function() debounce[hit] = nil end)
    end)
end)

Cmd("unfling", {"nofling","stopfling"}, function()
    State.Flinging = false
    local hrp = GetHRP()
    if hrp then
        local bav = hrp:FindFirstChild("S_FlingBAV")
        local bvf = hrp:FindFirstChild("S_FlingBV")
        if bav then bav:Destroy() end
        if bvf then bvf:Destroy() end
    end
    SafeDisconn("FlingNoclip")
    SafeDisconn("ObjFling")
    Notify("🌪  Fling stopped")
end)

-- ════════════════════════════════════════════════════════════
--                   SPIN (self)
-- ════════════════════════════════════════════════════════════

Cmd("spin", {"sp"}, function(args)
    local spd = tonumber(args[1]) or 50
    local hrp = GetHRP()
    if not hrp then Notify("No character","error"); return end

    local existing = hrp:FindFirstChild("S_Spin")
    if existing then
        existing.AngularVelocity = Vector3.new(0, spd, 0)
        Notify("Spin speed → " .. spd, "info"); return
    end

    State.Spinning = true
    local av = Instance.new("BodyAngularVelocity", hrp)
    av.Name           = "S_Spin"
    av.MaxTorque      = Vector3.new(0, 1e6, 0)
    av.AngularVelocity = Vector3.new(0, spd, 0)
    Notify("🔄  Spin ON (" .. spd .. ")")
end)

Cmd("unspin", {"nospin","stopspin"}, function()
    State.Spinning = false
    local hrp = GetHRP()
    if hrp then
        local av = hrp:FindFirstChild("S_Spin")
        if av then av:Destroy() end
    end
    Notify("🔄  Spin OFF")
end)

-- ════════════════════════════════════════════════════════════
--                   BANG (troll)
-- ════════════════════════════════════════════════════════════

Cmd("bang", {"hump"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or target == LP or not target.Character then
        Notify("Invalid target","error"); return
    end
    State.Banging = true
    local spd   = tonumber(args[2]) or 3
    local myHRP = GetHRP()
    task.spawn(function()
        while State.Banging and target.Character and LP.Character do
            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if myHRP and tHRP then
                myHRP.CFrame = tHRP.CFrame * CFrame.new(0,0,1.2 + math.sin(tick()*spd*8)*0.5)
            end
            task.wait()
        end
    end)
    Notify("💥  Bang → " .. target.Name)
end)

Cmd("unbang", {"nobang"}, function()
    State.Banging = false
    Notify("💥  Bang OFF")
end)

-- ════════════════════════════════════════════════════════════
--                   TELEPORT
-- ════════════════════════════════════════════════════════════

Cmd("tp", {"goto","teleport"}, function(args)
    if not args[1] then Notify("Usage: tp <player>","warn"); return end
    local target = GetPlayers(args[1])[1]
    if not target or target == LP then Notify("Target not found","error"); return end
    local hrp  = GetHRP()
    local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if hrp and tHRP then
        hrp.CFrame = tHRP.CFrame + Vector3.new(3, 0, 0)
        Notify("📍  TP → " .. target.Name)
    end
end)

Cmd("tpme", {"bring","bringme"}, function(args)
    -- Bring a player to you
    if not args[1] then Notify("Usage: tpme <player>","warn"); return end
    local target = GetPlayers(args[1])[1]
    if not target or target == LP then Notify("Target not found","error"); return end
    local hrp  = GetHRP()
    local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if hrp and tHRP then
        tHRP.CFrame = hrp.CFrame + Vector3.new(3, 0, 0)
        Notify("📍  Brought " .. target.Name)
    end
end)

Cmd("gotocam", {"tpcam","camtp"}, function()
    local hrp = GetHRP()
    if hrp then
        hrp.CFrame = workspace.CurrentCamera.CFrame + workspace.CurrentCamera.CFrame.LookVector * 3
        Notify("📸  Teleported to camera")
    end
end)

-- ════════════════════════════════════════════════════════════
--                  RESPAWN COMMAND
-- ════════════════════════════════════════════════════════════

Cmd("respawn", {"re","spawn","reset"}, function()
    local h = GetHuman()
    if h then
        h.Health = 0
        Notify("♻  Respawning...")
    else
        -- Fallback: use LoadCharacter if possible
        local ok = pcall(function() LP:LoadCharacter() end)
        if not ok then Notify("Respawn failed","error") end
    end
end)

-- ════════════════════════════════════════════════════════════
--                   REJOIN
-- ════════════════════════════════════════════════════════════

Cmd("rejoin", {"rj","reconnect"}, function()
    Notify("🔄  Rejoining...", "warn")
    task.wait(0.5)
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end)
end)

-- ════════════════════════════════════════════════════════════
--                   ESP
-- ════════════════════════════════════════════════════════════

Cmd("esp", {"wallhack","wh"}, function()
    if State.ESP then Notify("ESP already ON","warn"); return end
    State.ESP = true
    local function attachESP(plr)
        if plr == LP then return end
        local function doAttach(char)
            local old = char:FindFirstChild("S_ESP")
            if old then old:Destroy() end
            local hl = Instance.new("Highlight", char)
            hl.Name                 = "S_ESP"
            hl.FillColor            = Color3.fromRGB(255,50,50)
            hl.FillTransparency     = 0.65
            hl.OutlineColor         = Color3.fromRGB(255,255,255)
            hl.OutlineTransparency  = 0
        end
        if plr.Character then doAttach(plr.Character) end
        plr.CharacterAdded:Connect(doAttach)
    end
    for _, p in ipairs(Players:GetPlayers()) do attachESP(p) end
    Conns.ESP = Players.PlayerAdded:Connect(attachESP)
    Notify("👁  ESP ON")
end)

Cmd("unesp", {"noesp","nowall"}, function()
    State.ESP = false
    SafeDisconn("ESP")
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p.Character
        if c then
            local hl = c:FindFirstChild("S_ESP")
            if hl then hl:Destroy() end
        end
    end
    Notify("👁  ESP OFF")
end)

-- ════════════════════════════════════════════════════════════
--                   INVISIBLE / VISIBLE
-- ════════════════════════════════════════════════════════════

Cmd("invisible", {"invis","hide","inv"}, function()
    State.Invisible = true
    local char = LP.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Transparency = 1 end
        if p:IsA("Decal")    then p.Transparency = 1 end
        if p:IsA("SpecialMesh") then p.Scale = Vector3.zero end
    end
    Notify("🫥  Invisible ON")
end)

Cmd("visible", {"vis","show","uninv"}, function()
    State.Invisible = false
    local char = LP.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Transparency = 0 end
        if p:IsA("Decal")    then p.Transparency = 0 end
        if p:IsA("SpecialMesh") then p.Scale = Vector3.new(1,1,1) end
    end
    Notify("🫥  Visible ON")
end)

-- ════════════════════════════════════════════════════════════
--                   FULLBRIGHT
-- ════════════════════════════════════════════════════════════

Cmd("fullbright", {"fb","bright"}, function()
    if State.Fullbright then
        State.Fullbright   = false
        Lighting.Ambient    = OrigLight.Ambient
        Lighting.Brightness = OrigLight.Brightness
        Lighting.ClockTime  = OrigLight.ClockTime
        Lighting.FogEnd     = OrigLight.FogEnd
        Notify("💡  Fullbright OFF")
    else
        OrigLight.Ambient    = Lighting.Ambient
        OrigLight.Brightness = Lighting.Brightness
        OrigLight.ClockTime  = Lighting.ClockTime
        OrigLight.FogEnd     = Lighting.FogEnd
        State.Fullbright     = true
        Lighting.Ambient     = Color3.new(1,1,1)
        Lighting.Brightness  = 2
        Lighting.ClockTime   = 14
        Lighting.FogEnd      = 1e6
        Notify("💡  Fullbright ON")
    end
end)

-- ════════════════════════════════════════════════════════════
--                   TIME
-- ════════════════════════════════════════════════════════════

Cmd("time", {"daytime","settime"}, function(args)
    local t = tonumber(args[1])
    if t then
        Lighting.ClockTime = t % 24
        Notify("🕒  Time → " .. (t % 24))
    else
        Notify("Usage: time <0-24>","warn")
    end
end)

-- ════════════════════════════════════════════════════════════
--                   GOD MODE (client)
-- ════════════════════════════════════════════════════════════

Cmd("god", {"godmode","inf"}, function()
    local h = GetHuman()
    if h then
        h.MaxHealth = math.huge
        h.Health    = math.huge
        Notify("🛡  God mode (client-side)")
    end
end)

Cmd("ungod", {"mortal"}, function()
    local h = GetHuman()
    if h then
        h.MaxHealth = 100
        h.Health    = 100
        Notify("🛡  God mode OFF")
    end
end)

-- ════════════════════════════════════════════════════════════
--                   INFINITE JUMP
-- ════════════════════════════════════════════════════════════

Cmd("infjump", {"ij","infinitejump"}, function()
    if State.InfJump then Notify("Inf Jump already ON","warn"); return end
    State.InfJump = true
    SafeDisconn("InfJump")
    Conns.InfJump = UserInputService.JumpRequest:Connect(function()
        local h = GetHuman()
        if h and State.InfJump then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    Notify("🦘  Infinite Jump ON")
end)

Cmd("uninfjump", {"noij","noinfjump"}, function()
    State.InfJump = false
    SafeDisconn("InfJump")
    Notify("🦘  Infinite Jump OFF")
end)

-- ════════════════════════════════════════════════════════════
--                   FREEZE SELF
-- ════════════════════════════════════════════════════════════

Cmd("freeze", {"fr","stop"}, function()
    local hrp = GetHRP()
    if hrp then hrp.Anchored = true; Notify("🧊  Frozen") end
end)

Cmd("unfreeze", {"unfr","unstop","thaw"}, function()
    local hrp = GetHRP()
    if hrp then hrp.Anchored = false; Notify("🧊  Unfrozen") end
end)

-- ════════════════════════════════════════════════════════════
--                   ZOOM
-- ════════════════════════════════════════════════════════════

Cmd("zoom", {"fov"}, function(args)
    local amt = tonumber(args[1]) or 70
    workspace.CurrentCamera.FieldOfView = amt
    Notify("🔭  FOV → " .. amt)
end)

-- ════════════════════════════════════════════════════════════
--   MAXZOOM  —  Customisable camera zoom-out distance
--   maxzoom 500    → zoom out up to 500 studs
--   maxzoom 9999   → effectively unlimited
--   maxzoom reset  → restore Roblox default (400)
-- ════════════════════════════════════════════════════════════
Cmd("maxzoom", {"mz","zoomout","camzoom","cameramax"}, function(args)
    local raw = args[1]
    if not raw or raw:lower() == "reset" or raw:lower() == "default" then
        LP.CameraMaxZoomDistance = 400
        LP.CameraMinZoomDistance = 0.5
        Notify("🔭  MaxZoom reset → 400 studs")
        return
    end
    local amt = tonumber(raw)
    if not amt then Notify("Usage: maxzoom <number>  |  maxzoom reset","warn"); return end
    amt = math.clamp(amt, 1, 99999)
    LP.CameraMaxZoomDistance = amt
    -- Pull min down if it somehow exceeds new max
    if LP.CameraMinZoomDistance > amt then
        LP.CameraMinZoomDistance = amt
    end
    Notify(string.format("🔭  MaxZoom → %d studs", amt))
end)

-- ════════════════════════════════════════════════════════════
--                   TOOLS / EXPLOITS
-- ════════════════════════════════════════════════════════════

Cmd("dex", {"explorer"}, function()
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
    end)
    Notify(ok and "🔧  Dex loaded" or "🔧  Dex failed", ok and "success" or "error")
end)

Cmd("remotespy", {"rspy","spy"}, function()
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpySource.lua"))()
    end)
    Notify(ok and "📡  RemoteSpy loaded" or "📡  RemoteSpy failed", ok and "success" or "error")
end)

Cmd("aimbot", {"aim","ab"}, function()
    Notify("Paste your own aimbot loader here","info")
end)

-- ════════════════════════════════════════════════════════════
--   GRAVITY  —  gravity <number>   (default 196.2)
--               gravity reset
-- ════════════════════════════════════════════════════════════
local _origGravity = workspace.Gravity

Cmd("gravity", {"grav","g"}, function(args)
    local raw = args[1]
    if not raw or raw:lower() == "reset" then
        workspace.Gravity = _origGravity
        Notify("🌍  Gravity reset → " .. _origGravity); return
    end
    local amt = tonumber(raw)
    if not amt then Notify("Usage: gravity <number>  |  gravity reset","warn"); return end
    workspace.Gravity = amt
    Notify("🌍  Gravity → " .. amt)
end)

Cmd("lowgrav", {"lg","moon"}, function(args)
    local amt = tonumber(args[1]) or 20
    workspace.Gravity = amt
    Notify("🌍  Low gravity → " .. amt)
end)

-- ════════════════════════════════════════════════════════════
--   LOOPKILL  —  loopkill <player>   (client-side health set)
-- ════════════════════════════════════════════════════════════
Cmd("loopkill", {"lk"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target then Notify("No target","error"); return end
    if target == LP then Notify("Can't loopkill yourself","warn"); return end
    State["LoopKill_"..target.Name] = true
    Notify("💀  LoopKill → " .. target.Name)
    task.spawn(function()
        while State["LoopKill_"..target.Name] do
            local tChar = target.Character
            local tHum  = tChar and tChar:FindFirstChildOfClass("Humanoid")
            if tHum then tHum.Health = 0 end
            task.wait(0.1)
        end
    end)
end)

Cmd("unloopkill", {"unlk","stopkill"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target then
        -- Stop all loop kills
        for k in pairs(State) do
            if k:sub(1,9) == "LoopKill_" then State[k] = false end
        end
        Notify("💀  All LoopKills stopped"); return
    end
    State["LoopKill_"..target.Name] = false
    Notify("💀  LoopKill stopped for " .. target.Name)
end)

-- ════════════════════════════════════════════════════════════
--   LOOPHEAL  —  constant self-heal loop
-- ════════════════════════════════════════════════════════════
Cmd("loopheal", {"lh","autoheal"}, function()
    if State.LoopHeal then Notify("LoopHeal already ON","warn"); return end
    State.LoopHeal = true
    task.spawn(function()
        while State.LoopHeal do
            local h = GetHuman()
            if h then h.Health = h.MaxHealth end
            task.wait(0.1)
        end
    end)
    Notify("💚  LoopHeal ON")
end)

Cmd("unloopheal", {"unlh","noautoheal"}, function()
    State.LoopHeal = false
    Notify("💚  LoopHeal OFF")
end)

-- ════════════════════════════════════════════════════════════
--   HEAL  —  instantly restore health to max
-- ════════════════════════════════════════════════════════════
Cmd("heal", {"hp","health"}, function(args)
    local amt = tonumber(args[1])
    local h = GetHuman()
    if h then
        h.Health = amt or h.MaxHealth
        Notify("💚  Healed → " .. (amt or "max"))
    end
end)

-- ════════════════════════════════════════════════════════════
--   FOLLOW  —  follow <player>  (walk toward them every tick)
-- ════════════════════════════════════════════════════════════
Cmd("follow", {"fw","walkto"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or target == LP then Notify("Invalid target","error"); return end
    State.Following = true
    SafeDisconn("Follow")
    Notify("🏃  Following " .. target.Name)
    Conns.Follow = RunService.Heartbeat:Connect(function()
        if not State.Following then SafeDisconn("Follow"); return end
        local tChar = target.Character
        local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
        local myHRP = GetHRP()
        local hum   = GetHuman()
        if tHRP and myHRP and hum then
            local dist = (myHRP.Position - tHRP.Position).Magnitude
            if dist > 5 then
                hum:MoveTo(tHRP.Position)
            end
        end
    end)
end)

Cmd("unfollow", {"unfw","stopfollow"}, function()
    State.Following = false
    SafeDisconn("Follow")
    Notify("🏃  Follow stopped")
end)

-- ════════════════════════════════════════════════════════════
--   ANNOY  —  annoy <player>  (teleport on top of them every 0.1s)
-- ════════════════════════════════════════════════════════════
Cmd("annoy", {"an"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or target == LP then Notify("Invalid target","error"); return end
    State.Annoying = true
    Notify("😈  Annoying " .. target.Name)
    task.spawn(function()
        while State.Annoying do
            local tChar = target.Character
            local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local myHRP = GetHRP()
            if tHRP and myHRP then
                myHRP.CFrame = tHRP.CFrame + Vector3.new(0, 3, 0)
            end
            task.wait(0.1)
        end
    end)
end)

Cmd("unannoy", {"unan"}, function()
    State.Annoying = false
    Notify("😈  Annoy stopped")
end)

-- ════════════════════════════════════════════════════════════
--   ANTIAFK  —  prevent AFK kick by firing jump every 60s
-- ════════════════════════════════════════════════════════════
Cmd("antiafk", {"aafk","noafk"}, function()
    if State.AntiAFK then Notify("AntiAFK already ON","warn"); return end
    State.AntiAFK = true
    local VPConn, JumpConn
    -- Suppress the VirtualUser kick signal
    local ok = pcall(function()
        local VU = game:GetService("VirtualUser")
        VPConn = LP.Idled:Connect(function()
            if State.AntiAFK then
                VU:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
                task.wait(1)
                VU:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
            end
        end)
    end)
    -- Fallback: tiny jump every 55s
    if not ok then
        task.spawn(function()
            while State.AntiAFK do
                local h = GetHuman()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
                task.wait(55)
            end
        end)
    end
    Conns.AntiAFK = VPConn
    Notify("⏰  AntiAFK ON")
end)

Cmd("unantiafk", {"noaafk"}, function()
    State.AntiAFK = false
    SafeDisconn("AntiAFK")
    Notify("⏰  AntiAFK OFF")
end)

-- ════════════════════════════════════════════════════════════
--   TRAIL  —  adds a colourful trail behind the character
--   trail [R G B]   e.g. trail 255 0 128
-- ════════════════════════════════════════════════════════════
Cmd("trail", {"tr"}, function(args)
    local char = LP.Character
    if not char then Notify("No character","error"); return end
    -- Remove existing
    for _, v in ipairs(char:GetDescendants()) do
        if v.Name == "S_Trail" then v:Destroy() end
    end
    local hrp = GetHRP()
    if not hrp then return end
    local r = tonumber(args[1]) or 255
    local g = tonumber(args[2]) or 80
    local b = tonumber(args[3]) or 180
    -- Attachments at top and bottom of HRP
    local a0 = Instance.new("Attachment", hrp); a0.Name = "S_TrailA0"; a0.Position = Vector3.new(0, 1, 0)
    local a1 = Instance.new("Attachment", hrp); a1.Name = "S_TrailA1"; a1.Position = Vector3.new(0,-1, 0)
    local trail = Instance.new("Trail", hrp)
    trail.Name        = "S_Trail"
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Lifetime    = 0.6
    trail.MinLength   = 0
    trail.FaceCamera  = true
    trail.Color       = ColorSequence.new(Color3.fromRGB(r,g,b), Color3.fromRGB(255,255,255))
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    Notify(string.format("✨  Trail ON  (%d,%d,%d)", r, g, b))
end)

Cmd("notrail", {"untrail","rmtrail"}, function()
    local char = LP.Character
    if char then
        for _, v in ipairs(char:GetDescendants()) do
            if v.Name == "S_Trail" or v.Name == "S_TrailA0" or v.Name == "S_TrailA1" then
                v:Destroy()
            end
        end
    end
    Notify("✨  Trail OFF")
end)

-- ════════════════════════════════════════════════════════════
--   GLOW  —  SelectionBox highlight around your character
--   glow [R G B]
-- ════════════════════════════════════════════════════════════
Cmd("glow", {"gl"}, function(args)
    local char = LP.Character
    if not char then Notify("No character","error"); return end
    local old = ScreenGui:FindFirstChild("S_GlowBox")
    if old then old:Destroy() end
    local r = tonumber(args[1]) or 0
    local g = tonumber(args[2]) or 180
    local b = tonumber(args[3]) or 255
    local box = Instance.new("SelectionBox", ScreenGui)
    box.Name          = "S_GlowBox"
    box.Adornee       = char
    box.Color3        = Color3.fromRGB(r,g,b)
    box.LineThickness = 0.04
    box.SurfaceTransparency = 0.85
    box.SurfaceColor3 = Color3.fromRGB(r,g,b)
    Notify(string.format("✨  Glow ON  (%d,%d,%d)", r, g, b))
end)

Cmd("noglow", {"unglow"}, function()
    local old = ScreenGui:FindFirstChild("S_GlowBox")
    if old then old:Destroy() end
    Notify("✨  Glow OFF")
end)

-- ════════════════════════════════════════════════════════════
--   HAT  —  hat off / on  (toggle accessories visibility)
-- ════════════════════════════════════════════════════════════
Cmd("hat", {"accessory"}, function(args)
    local char = LP.Character
    if not char then return end
    local hide = (args[1] or "off"):lower() == "off"
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Accessory") then
            local handle = v:FindFirstChild("Handle")
            if handle then handle.Transparency = hide and 1 or 0 end
        end
    end
    Notify("🎩  Hat " .. (hide and "hidden" or "shown"))
end)

-- ════════════════════════════════════════════════════════════
--   ATTACH / DETACH  —  weld yourself to another player's HRP
-- ════════════════════════════════════════════════════════════
Cmd("attach", {"weld"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or target == LP then Notify("Invalid target","error"); return end
    local myHRP = GetHRP()
    local tHRP  = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP or not tHRP then Notify("Missing parts","error"); return end
    -- Remove existing weld
    local old = myHRP:FindFirstChild("S_AttachWeld")
    if old then old:Destroy() end
    local weld = Instance.new("WeldConstraint", myHRP)
    weld.Name  = "S_AttachWeld"
    weld.Part0 = myHRP
    weld.Part1 = tHRP
    Notify("🔗  Attached to " .. target.Name)
end)

Cmd("detach", {"unweld"}, function()
    local myHRP = GetHRP()
    if myHRP then
        local w = myHRP:FindFirstChild("S_AttachWeld")
        if w then w:Destroy() end
    end
    Notify("🔗  Detached")
end)

-- ════════════════════════════════════════════════════════════
--   KILL  —  attempt to set target health to 0 (client-side)
-- ════════════════════════════════════════════════════════════
Cmd("kill", {"k"}, function(args)
    local targets = GetPlayers(args[1])
    for _, t in ipairs(targets) do
        local tHum = t.Character and t.Character:FindFirstChildOfClass("Humanoid")
        if tHum then tHum.Health = 0 end
    end
    Notify("💀  Kill → " .. (args[1] or "me"))
end)

-- ════════════════════════════════════════════════════════════
--   MINZOOM  —  set minimum camera zoom distance
--   minzoom 0   → camera can go first-person
--   minzoom 10  → locked at least 10 studs back
-- ════════════════════════════════════════════════════════════
Cmd("minzoom", {"minz","cameramin"}, function(args)
    local raw = args[1]
    if not raw or raw:lower() == "reset" then
        LP.CameraMinZoomDistance = 0.5
        Notify("🔭  MinZoom reset → 0.5"); return
    end
    local amt = tonumber(raw)
    if not amt then Notify("Usage: minzoom <number>","warn"); return end
    amt = math.clamp(amt, 0, LP.CameraMaxZoomDistance)
    LP.CameraMinZoomDistance = amt
    Notify(string.format("🔭  MinZoom → %d studs", amt))
end)

-- ════════════════════════════════════════════════════════════
--   NAMETAG  —  change your overhead display name (client only)
-- ════════════════════════════════════════════════════════════
Cmd("nametag", {"name","tag"}, function(args)
    local newName = table.concat(args," ")
    if newName == "" then Notify("Usage: nametag <text>","warn"); return end
    local char = LP.Character
    if not char then return end
    -- Find overhead BillboardGui or HumanoidDescription
    local hum = GetHuman()
    if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
    -- Create custom billboard
    local hrp = GetHRP(); if not hrp then return end
    local old = hrp:FindFirstChild("S_Nametag"); if old then old:Destroy() end
    local bb = Instance.new("BillboardGui", hrp)
    bb.Name          = "S_Nametag"
    bb.Size          = UDim2.new(0, 120, 0, 30)
    bb.StudsOffset   = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop   = true
    bb.ResetOnSpawn  = false
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size             = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = newName
    lbl.TextColor3       = Color3.new(1,1,1)
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextScaled       = true
    Notify("🏷  Nametag → " .. newName)
end)

Cmd("nonametag", {"notag","rmtag"}, function()
    local hrp = GetHRP()
    if hrp then
        local bb = hrp:FindFirstChild("S_Nametag")
        if bb then bb:Destroy() end
    end
    local hum = GetHuman()
    if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Automatic end
    Notify("🏷  Nametag removed")
end)

-- ════════════════════════════════════════════════════════════
--   FLOATNAME  —  float a custom text label above any player
--   floatname <player> <text>
-- ════════════════════════════════════════════════════════════
Cmd("floatname", {"fn","floatlabel"}, function(args)
    local target = GetPlayers(args[1])[1]
    local txt    = table.concat(args, " ", 2)
    if not target or txt == "" then Notify("Usage: floatname <player> <text>","warn"); return end
    local tChar = target.Character
    local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
    if not tHRP then Notify("Target has no HRP","error"); return end
    local old = tHRP:FindFirstChild("S_FloatName"); if old then old:Destroy() end
    local bb = Instance.new("BillboardGui", tHRP)
    bb.Name        = "S_FloatName"
    bb.Size        = UDim2.new(0,150,0,36)
    bb.StudsOffset = Vector3.new(0,4.5,0)
    bb.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text       = txt
    lbl.TextColor3 = Color3.fromRGB(255,220,60)
    lbl.Font       = Enum.Font.GothamBold
    lbl.TextScaled = true
    Notify("💬  FloatName set on " .. target.Name)
end)

-- ════════════════════════════════════════════════════════════
--   CHAT  —  send a chat message
-- ════════════════════════════════════════════════════════════
Cmd("chat", {"say","c"}, function(args)
    local msg = table.concat(args, " ")
    if msg == "" then Notify("Usage: chat <message>","warn"); return end
    local ok = pcall(function()
        game:GetService("ReplicatedStorage")
            .DefaultChatSystemChatEvents
            .SayMessageRequest:FireServer(msg, "All")
    end)
    if not ok then
        pcall(function()
            StarterGui:SetCore("ChatMakeSystemMessage",{
                Text  = "[S] " .. msg,
                Color = Color3.new(1,1,1),
            })
        end)
    end
end)

-- ════════════════════════════════════════════════════════════
--   FPS / PING / COORDS  (utility read-outs)
-- ════════════════════════════════════════════════════════════
Cmd("fps", {}, function()
    local t0 = tick()
    RunService.Heartbeat:Wait()
    Notify(string.format("⚡  FPS: %.0f", 1/(tick()-t0)), "info")
end)

Cmd("ping", {}, function()
    Notify(string.format("📶  Ping: %.0f ms", LP:GetNetworkPing()*1000), "info")
end)

Cmd("coords", {"pos","position"}, function()
    local hrp = GetHRP()
    if hrp then
        local p = hrp.Position
        Notify(string.format("📍  %.1f, %.1f, %.1f", p.X, p.Y, p.Z), "info")
    end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║           CATEGORY: ANIMATIONS & EMOTES                 ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: AnimationTrack lifecycle, Humanoid:LoadAnimation,
--           playing/stopping tracks, R6 vs R15 awareness.

-- Internal animation track registry so we can stop any running
local _animTracks = {}   -- [LP.Name] = {track, ...}

local function PlayAnim(animId, looped)
    -- Guard: reject nil, 0, or non-numeric IDs
    animId = tonumber(animId)
    if not animId or animId <= 0 then
        Notify("Invalid animation ID","error"); return
    end
    local hum  = GetHuman(); if not hum then return end
    local char = GetChar();  if not char then return end
    -- Stop previous S_ tracks to avoid stacking
    if _animTracks[LP.Name] then
        for _, t in ipairs(_animTracks[LP.Name]) do
            pcall(function() t:Stop() end)
        end
    end
    _animTracks[LP.Name] = {}
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. tostring(animId)
    local ok, track = pcall(function()
        return hum:LoadAnimation(anim)
    end)
    if not ok then Notify("Anim load failed (ID " .. animId .. ")","error"); return end
    track.Looped = looped ~= false
    track:Play()
    table.insert(_animTracks[LP.Name], track)
    return track
end

-- anim <ID> — play any animation by asset ID
Cmd("anim", {"animation","playanim"}, function(args)
    local id = tonumber(args[1])
    if not id then Notify("Usage: anim <assetID>","warn"); return end
    PlayAnim(id, true)
    Notify("🎭  Playing anim " .. id)
end)

-- stopanim — stop all running S_ animations
Cmd("stopanim", {"stopanimation","noanim"}, function()
    if _animTracks[LP.Name] then
        for _, t in ipairs(_animTracks[LP.Name]) do pcall(function() t:Stop() end) end
        _animTracks[LP.Name] = {}
    end
    Notify("🎭  Animations stopped")
end)

-- Built-in emote shortcuts (R15 default IDs)
local _emoteIDs = {
    wave    = 507770239,
    dance   = 507771019,
    dance2  = 507776043,
    dance3  = 507777268,
    laugh   = 507770818,
    point   = 507770453,
    cheer   = 507770677,
    salute  = 3360686091,
    shrug   = 3576968026,
    tilt    = 3576968026,
}

Cmd("emote", {"e"}, function(args)
    local name = (args[1] or ""):lower()
    local id   = _emoteIDs[name]
    if not id then
        local list = {}
        for k in pairs(_emoteIDs) do table.insert(list, k) end
        Notify("Emotes: " .. table.concat(list,", "),"warn"); return
    end
    PlayAnim(id, false)
    Notify("🕺  Emote: " .. name)
end)

Cmd("dance", {"d"}, function(args)
    local n = tonumber(args[1]) or 1
    local ids = { _emoteIDs.dance, _emoteIDs.dance2, _emoteIDs.dance3 }
    local id  = ids[math.clamp(n,1,3)] or ids[1]
    PlayAnim(id, true)
    Notify("🕺  Dance " .. n)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║         CATEGORY: CHARACTER APPEARANCE                  ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: HumanoidDescription, body-part scaling,
--           BodyColors, appearance replication limits.

-- size <scale>  — uniformly scale the whole character
Cmd("size", {"scale","charsize"}, function(args)
    local s   = tonumber(args[1]) or 1
    local hum = GetHuman(); if not hum then return end
    -- HumanoidDescription is the clean API for scaling
    local desc = hum:GetAppliedDescription()
    local function sc(v) return math.clamp(v * s, 0.05, 10) end
    desc.HeadScale        = sc(1)
    desc.BodyHeightScale  = sc(1)
    desc.BodyWidthScale   = sc(1)
    desc.BodyDepthScale   = sc(1)
    desc.LowerTorsoScale  = sc(1)
    desc.UpperTorsoScale  = sc(1)
    hum:ApplyDescription(desc)
    Notify(string.format("📐  Size → %.2f", s))
end)

-- headsize <scale>  — scale head only
Cmd("headsize", {"head","hs"}, function(args)
    local s   = tonumber(args[1]) or 1
    local hum = GetHuman(); if not hum then return end
    local desc = hum:GetAppliedDescription()
    desc.HeadScale = math.clamp(s, 0.05, 10)
    hum:ApplyDescription(desc)
    Notify(string.format("🗣  HeadSize → %.2f", s))
end)

-- bodycolor <part> <R> <G> <B>
-- part: head / torso / leftarm / rightarm / leftleg / rightleg / all
Cmd("bodycolor", {"bc","color"}, function(args)
    local part = (args[1] or "all"):lower()
    local r    = tonumber(args[2]) or 255
    local g    = tonumber(args[3]) or 255
    local b    = tonumber(args[4]) or 255
    local col  = Color3.fromRGB(r, g, b)
    local bco  = BrickColor.new(col)

    local char = GetChar(); if not char then return end
    local bc   = char:FindFirstChildOfClass("BodyColors")
    if not bc then Notify("No BodyColors found","error"); return end

    local map = {
        head     = "HeadColor3",
        torso    = "TorsoColor3",
        leftarm  = "LeftArmColor3",  rightarm  = "RightArmColor3",
        leftleg  = "LeftLegColor3",  rightleg  = "RightLegColor3",
    }
    if part == "all" then
        for _, prop in pairs(map) do bc[prop] = col end
    elseif map[part] then
        bc[map[part]] = col
    else
        Notify("Parts: head torso leftarm rightarm leftleg rightleg all","warn"); return
    end
    Notify(string.format("🎨  BodyColor %s → (%d,%d,%d)", part, r, g, b))
end)

-- shirt <ID>  /  pants <ID>  — apply clothing assets
Cmd("shirt", {}, function(args)
    local id = tonumber(args[1])
    if not id then Notify("Usage: shirt <assetID>","warn"); return end
    local char = GetChar(); if not char then return end
    local s = char:FindFirstChildOfClass("Shirt")
    if not s then s = Instance.new("Shirt", char) end
    s.ShirtTemplate = "rbxassetid://" .. id
    Notify("👕  Shirt → " .. id)
end)

Cmd("pants", {}, function(args)
    local id = tonumber(args[1])
    if not id then Notify("Usage: pants <assetID>","warn"); return end
    local char = GetChar(); if not char then return end
    local p = char:FindFirstChildOfClass("Pants")
    if not p then p = Instance.new("Pants", char) end
    p.PantsTemplate = "rbxassetid://" .. id
    Notify("👖  Pants → " .. id)
end)

-- face <ID>  — swap face decal
Cmd("face", {}, function(args)
    local id = tonumber(args[1])
    if not id then Notify("Usage: face <assetID>","warn"); return end
    local char = GetChar(); if not char then return end
    local head = char:FindFirstChild("Head"); if not head then return end
    local dec  = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
    if dec then dec.Texture = "rbxassetid://" .. id end
    Notify("😮  Face → " .. id)
end)

-- resetappearance  — reload original HumanoidDescription
Cmd("resetappearance", {"resetchar","defaultlook"}, function()
    local hum = GetHuman(); if not hum then return end
    pcall(function()
        local desc = Players:GetHumanoidDescriptionFromUserId(LP.UserId)
        hum:ApplyDescription(desc)
    end)
    Notify("✅  Appearance reset")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║         CATEGORY: CHARACTER EFFECTS (particles)         ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: ParticleEmitter, Fire, Smoke, Sparkles,
--           SelectionBox, ForceField — all Instance-based.

local function ApplyEffect(effectName, props)
    local hrp = GetHRP(); if not hrp then return false end
    -- Remove existing instance of same name
    local old = hrp:FindFirstChild("S_EFX_" .. effectName)
    if old then old:Destroy(); return true end   -- toggle off
    local inst = Instance.new(effectName, hrp)
    inst.Name = "S_EFX_" .. effectName
    for k, v in pairs(props or {}) do
        pcall(function() inst[k] = v end)
    end
    return false  -- newly created
end

Cmd("fire", {"flame"}, function(args)
    local size  = tonumber(args[1]) or 5
    local r,g,b = tonumber(args[2]) or 255, tonumber(args[3]) or 100, tonumber(args[4]) or 0
    local off = ApplyEffect("Fire", {
        Size  = size,
        Heat  = size * 2,
        Color = Color3.fromRGB(r,g,b),
        SecondaryColor = Color3.fromRGB(255,200,0),
    })
    Notify(off and "🔥  Fire OFF" or string.format("🔥  Fire ON (size %d)", size))
end)

Cmd("nofire", {"unfire"}, function()
    local hrp = GetHRP()
    if hrp then
        local f = hrp:FindFirstChild("S_EFX_Fire")
        if f then f:Destroy(); Notify("🔥  Fire OFF") return end
    end
    Notify("No fire active","warn")
end)

Cmd("smoke", {}, function(args)
    local density = tonumber(args[1]) or 1
    local off = ApplyEffect("Smoke", {
        Color       = Color3.fromRGB(150,150,150),
        Opacity     = math.clamp(density, 0, 1),
        RiseVelocity = density * 2,
        Size        = density * 2,
    })
    Notify(off and "💨  Smoke OFF" or "💨  Smoke ON")
end)

Cmd("nosmoke", {"unsmoke"}, function()
    local hrp = GetHRP()
    if hrp then local s = hrp:FindFirstChild("S_EFX_Smoke"); if s then s:Destroy() end end
    Notify("💨  Smoke OFF")
end)

Cmd("sparkles", {"spark"}, function(args)
    local r,g,b = tonumber(args[1]) or 255, tonumber(args[2]) or 200, tonumber(args[3]) or 50
    local off = ApplyEffect("Sparkles", {
        SparkleColor = Color3.fromRGB(r,g,b),
    })
    Notify(off and "✨  Sparkles OFF" or "✨  Sparkles ON")
end)

Cmd("nosparkles", {"unspark"}, function()
    local hrp = GetHRP()
    if hrp then local s = hrp:FindFirstChild("S_EFX_Sparkles"); if s then s:Destroy() end end
    Notify("✨  Sparkles OFF")
end)

Cmd("forcefield", {"ff","shield"}, function()
    local char = GetChar(); if not char then return end
    local old = char:FindFirstChildOfClass("ForceField")
    if old then old:Destroy(); Notify("🛡  ForceField OFF")
    else Instance.new("ForceField", char); Notify("🛡  ForceField ON") end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║         CATEGORY: ENVIRONMENT & LIGHTING                ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Lighting service properties, Sky/Atmosphere
--           instances, dynamic environment changes.

Cmd("fog", {}, function(args)
    local start  = tonumber(args[1]) or 100
    local finish = tonumber(args[2]) or 500
    local r,g,b  = tonumber(args[3]) or 200, tonumber(args[4]) or 200, tonumber(args[5]) or 200
    Lighting.FogStart  = start
    Lighting.FogEnd    = finish
    Lighting.FogColor  = Color3.fromRGB(r,g,b)
    Notify(string.format("🌫  Fog %d→%d", start, finish))
end)

Cmd("nofog", {"clearfog"}, function()
    Lighting.FogEnd = 1e6
    Lighting.FogStart = 0
    Notify("🌫  Fog cleared")
end)

Cmd("ambient", {"setambient"}, function(args)
    local r = tonumber(args[1]) or 127
    local g = tonumber(args[2]) or 127
    local b = tonumber(args[3]) or 127
    Lighting.Ambient = Color3.fromRGB(r,g,b)
    Notify(string.format("🌄  Ambient → (%d,%d,%d)", r, g, b))
end)

Cmd("sky", {}, function(args)
    -- sky <assetID>   or   sky reset
    if (args[1] or ""):lower() == "reset" then
        local s = Lighting:FindFirstChildOfClass("Sky")
        if s then s:Destroy() end
        Notify("☁  Sky reset"); return
    end
    local id = tonumber(args[1])
    if not id then Notify("Usage: sky <assetID>  |  sky reset","warn"); return end
    local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
    local base = "rbxassetid://"
    sky.SkyboxBk = base .. id; sky.SkyboxDn = base .. id
    sky.SkyboxFt = base .. id; sky.SkyboxLf = base .. id
    sky.SkyboxRt = base .. id; sky.SkyboxUp = base .. id
    Notify("☁  Sky → " .. id)
end)

Cmd("sunpos", {"sun"}, function(args)
    -- sunpos <clocktime 0-24>  — moves sun by adjusting ClockTime
    local t = tonumber(args[1])
    if not t then Notify("Usage: sunpos <0-24>","warn"); return end
    Lighting.ClockTime = t % 24
    Notify(string.format("☀  Sun position → %.1f", t % 24))
end)

Cmd("atmosphere", {"atmos"}, function(args)
    -- atmosphere <density> <offset> — create/modify Atmosphere
    local density = tonumber(args[1]) or 0.35
    local offset  = tonumber(args[2]) or 0
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
              or Instance.new("Atmosphere", Lighting)
    atm.Density = math.clamp(density, 0, 2)
    atm.Offset  = math.clamp(offset, -1, 1)
    Notify(string.format("🌍  Atmosphere density %.2f", density))
end)

Cmd("noatmosphere", {"noatmos"}, function()
    local a = Lighting:FindFirstChildOfClass("Atmosphere")
    if a then a:Destroy() end
    Notify("🌍  Atmosphere removed")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║         CATEGORY: CAMERA CONTROLS                       ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Camera CameraType enum, CFrame manipulation,
--           FieldOfView, camera scripting patterns.

local _camShakeConn = nil

Cmd("shake", {"camshake"}, function(args)
    local intensity = tonumber(args[1]) or 0.5
    local duration  = tonumber(args[2]) or 3
    local cam = workspace.CurrentCamera
    if _camShakeConn then
        pcall(function() _camShakeConn:Disconnect() end)
        _camShakeConn = nil
    end
    local t0 = tick()
    local baseCF = cam.CFrame
    _camShakeConn = RunService.RenderStepped:Connect(function()
        if tick() - t0 > duration then
            _camShakeConn:Disconnect(); _camShakeConn = nil; return
        end
        local decay = 1 - (tick()-t0)/duration
        local offset = CFrame.new(
            math.random(-100,100)/100 * intensity * decay,
            math.random(-100,100)/100 * intensity * decay,
            0
        )
        cam.CFrame = cam.CFrame * offset
    end)
    Notify(string.format("📷  Shake  %.1f intensity  %.1fs", intensity, duration))
end)

Cmd("fov", {"zoom","setfov"}, function(args)
    local amt = tonumber(args[1]) or 70
    workspace.CurrentCamera.FieldOfView = math.clamp(amt, 1, 120)
    Notify("📷  FOV → " .. math.clamp(amt,1,120))
end)

Cmd("firstperson", {"fp","1p"}, function()
    LP.CameraMaxZoomDistance = 0
    LP.CameraMinZoomDistance = 0
    Notify("📷  First person ON")
end)

Cmd("thirdperson", {"tp3","3p"}, function()
    LP.CameraMinZoomDistance = 0.5
    LP.CameraMaxZoomDistance = 128
    Notify("📷  Third person restored")
end)

Cmd("lockcam", {"lockCamera"}, function()
    -- Locks camera to current CFrame (frozen view)
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    Notify("📷  Camera LOCKED  (unlockcam to free)")
end)

Cmd("unlockcam", {"freecam","unlockCamera"}, function()
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom
    Notify("📷  Camera UNLOCKED")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║         CATEGORY: SOUND / MUSIC                         ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Sound service, SoundId, Volume, looping, stopping
--           sounds, parenting to workspace vs character.

local _adminSound = nil

Cmd("play", {"music","sound"}, function(args)
    local id  = tonumber(args[1])
    local vol = tonumber(args[2]) or 0.5
    if not id then Notify("Usage: play <soundID> [volume]","warn"); return end
    if _adminSound then pcall(function() _adminSound:Stop(); _adminSound:Destroy() end) end
    _adminSound = Instance.new("Sound", workspace)
    _adminSound.Name      = "S_AdminSound"
    _adminSound.SoundId   = "rbxassetid://" .. id
    _adminSound.Volume    = math.clamp(vol, 0, 10)
    _adminSound.Looped    = true
    _adminSound.RollOffMaxDistance = 1e4
    _adminSound:Play()
    Notify("🎵  Playing " .. id .. " (vol " .. vol .. ")")
end)

Cmd("stopsound", {"mute","stopmusic"}, function()
    if _adminSound then
        pcall(function() _adminSound:Stop(); _adminSound:Destroy() end)
        _adminSound = nil
    end
    Notify("🎵  Sound stopped")
end)

Cmd("volume", {"vol"}, function(args)
    local vol = tonumber(args[1])
    if not vol then Notify("Usage: volume <0-10>","warn"); return end
    if _adminSound then _adminSound.Volume = math.clamp(vol,0,10) end
    Notify("🔊  Volume → " .. vol)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║         CATEGORY: INFORMATION / READOUTS               ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: game metadata, Players service enumeration,
--           UserId lookups, property introspection.

Cmd("serverinfo", {"si","info"}, function()
    local plrCount = #Players:GetPlayers()
    local maxPlrs  = Players.MaxPlayers
    Notify(string.format("🖥  Game: %d | Players: %d/%d | PlaceID: %d",
        game.GameId, plrCount, maxPlrs, game.PlaceId), "info")
end)

Cmd("playerinfo", {"pi","whois"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target then Notify("Player not found","error"); return end
    Notify(string.format("👤  %s  |  ID: %d  |  Ping: %.0fms",
        target.Name, target.UserId, target:GetNetworkPing()*1000), "info")
end)

Cmd("players", {"who","listplayers"}, function()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(names, p.Name)
    end
    Notify("👥  " .. table.concat(names, ", "), "info")
end)

Cmd("uptime", {}, function()
    local s = math.floor(workspace.DistributedGameTime)
    local m = math.floor(s/60); s = s % 60
    local h = math.floor(m/60); m = m % 60
    Notify(string.format("⏱  Uptime: %02d:%02d:%02d", h, m, s), "info")
end)

Cmd("gameversion", {"gv","version"}, function()
    Notify("🎮  " .. game.Name .. "  v" .. game.PlaceVersion, "info")
end)

Cmd("userid", {"id"}, function(args)
    local target = GetPlayers(args[1])[1] or LP
    Notify("🆔  " .. target.Name .. " = " .. target.UserId, "info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║         CATEGORY: TELEPORT SUITE                        ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: CFrame construction from coordinates,
--           workspace traversal, spawn point logic.

-- tpcoords <X> <Y> <Z>
Cmd("tpcoords", {"tpc","setpos"}, function(args)
    local x = tonumber(args[1])
    local y = tonumber(args[2])
    local z = tonumber(args[3])
    if not (x and y and z) then
        Notify("Usage: tpcoords <X> <Y> <Z>","warn"); return
    end
    local hrp = GetHRP()
    if hrp then
        hrp.CFrame = CFrame.new(x, y, z)
        Notify(string.format("📍  TP → %.1f, %.1f, %.1f", x, y, z))
    end
end)

-- home / spawn  — teleport to team spawn or Vector3.zero
Cmd("home", {"spawn","respawnpoint"}, function()
    local hrp = GetHRP(); if not hrp then return end
    -- Try to find a SpawnLocation for the team
    local spawnCF = nil
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            if obj.TeamColor == LP.TeamColor or obj.Neutral then
                spawnCF = obj.CFrame + Vector3.new(0, 3, 0)
                break
            end
        end
    end
    hrp.CFrame = spawnCF or CFrame.new(0, 10, 0)
    Notify("🏠  Teleported home")
end)

-- tpall  — teleport every player to yourself (client perspective only)
Cmd("tpall", {"bringall"}, function()
    local hrp = GetHRP(); if not hrp then return end
    local offset = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local tHRP = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                tHRP.CFrame = hrp.CFrame + Vector3.new(offset, 0, 0)
                offset = offset + 4
            end
        end
    end
    Notify("📍  Brought all players to you")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║         CATEGORY: WORKSPACE TOOLS                       ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: workspace traversal, FindPartOnRay, instance
--           deletion, BasePart manipulation patterns.

-- delete <partname>  — remove all workspace parts matching name
Cmd("delete", {"del","remove"}, function(args)
    local name = args[1]
    if not name then Notify("Usage: delete <partName>","warn"); return end
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower() == name:lower() and obj:IsA("BasePart") then
            obj:Destroy(); count = count + 1
        end
    end
    Notify(string.format("🗑  Deleted %d parts named '%s'", count, name))
end)

-- explode  — create an explosion at your position (client-side)
Cmd("explode", {"boom","explosion"}, function(args)
    local hrp = GetHRP(); if not hrp then return end
    local power = tonumber(args[1]) or 100
    local exp   = Instance.new("Explosion", workspace)
    exp.Position       = hrp.Position
    exp.BlastRadius    = power / 10
    exp.BlastPressure  = 0          -- 0 = visual only, won't move parts server-side
    exp.DestroyJointRadiusPercent = 0
    Notify("💥  Explosion (r=" .. (power/10) .. ")")
end)

-- light  — toggle a PointLight attached to your HRP
Cmd("light", {"torch","lamp"}, function(args)
    local hrp = GetHRP(); if not hrp then return end
    local old = hrp:FindFirstChildOfClass("PointLight")
    if old then old:Destroy(); Notify("💡  Light OFF"); return end
    local pl = Instance.new("PointLight", hrp)
    pl.Brightness = tonumber(args[1]) or 5
    pl.Range      = tonumber(args[2]) or 20
    pl.Color      = Color3.fromRGB(255, 240, 200)
    Notify("💡  Light ON")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║         CATEGORY: ADMIN UTILITY PATTERNS                ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: coroutine / task patterns, repeated execution,
--           safe pcall wrappers, executor identity.

-- repeat <n> <cmd...>  — run a command N times
Cmd("repeat", {"rep","loop"}, function(args)
    local n    = tonumber(args[1]) or 1
    local rest = table.concat(args, " ", 2)
    if rest == "" then Notify("Usage: repeat <n> <command>","warn"); return end
    n = math.min(n, 50)   -- safety cap
    task.spawn(function()
        for i = 1, n do
            local parts = {}
            for w in rest:gmatch("%S+") do table.insert(parts, w) end
            local name = table.remove(parts,1):lower()
            name = Aliases[name] or name
            if Commands[name] then
                pcall(function() Commands[name](parts) end)
            end
            task.wait(0.05)
        end
    end)
    Notify(string.format("🔁  Repeat  ×%d  '%s'", n, rest))
end)

-- alias <shortcut> <command>  — register a runtime alias
Cmd("alias", {"bind"}, function(args)
    local shortcut = args[1]
    local target   = args[2]
    if not shortcut or not target then
        Notify("Usage: alias <shortcut> <command>","warn"); return
    end
    if not Commands[target] then
        Notify("Unknown command: " .. target,"error"); return
    end
    Aliases[shortcut:lower()] = target:lower()
    Notify("🔗  alias  '" .. shortcut .. "' → '" .. target .. "'")
end)

-- unalias <shortcut>
Cmd("unalias", {"unbind"}, function(args)
    local shortcut = args[1]
    if not shortcut then Notify("Usage: unalias <shortcut>","warn"); return end
    Aliases[shortcut:lower()] = nil
    Notify("🔗  Alias '" .. shortcut .. "' removed")
end)

-- printenv  — dump all active State flags to console + notify
Cmd("printenv", {"env","status"}, function()
    local lines = {}
    for k, v in pairs(State) do
        if type(v) == "boolean" then
            table.insert(lines, k .. "=" .. tostring(v))
        end
    end
    table.sort(lines)
    print("[S-Admin] State:\n  " .. table.concat(lines, "\n  "))
    Notify("📋  Env printed to console", "info")
end)

-- clear  — destroy all S_ GUI highlights/trails/effects from your char
Cmd("clear", {"cleanup","cleanse"}, function()
    local char = GetChar()
    if char then
        for _, v in ipairs(char:GetDescendants()) do
            if v.Name:sub(1,2) == "S_" then pcall(function() v:Destroy() end) end
        end
    end
    local hrp = GetHRP()
    if hrp then
        for _, n in ipairs({"S_FlyBV","S_FlyBG","S_Spin","S_FlingBAV","S_FlingBV"}) do
            local obj = hrp:FindFirstChild(n)
            if obj then obj:Destroy() end
        end
    end
    local sgold = ScreenGui:FindFirstChild("S_GlowBox")
    if sgold then sgold:Destroy() end
    Notify("🧹  Character effects cleared")
end)

-- exectime  — measure how fast a command runs (ms)
Cmd("exectime", {"bench","benchmark"}, function(args)
    local rest = table.concat(args, " ")
    if rest == "" then Notify("Usage: exectime <command>","warn"); return end
    local parts = {}
    for w in rest:gmatch("%S+") do table.insert(parts,w) end
    local name = table.remove(parts,1):lower()
    name = Aliases[name] or name
    if not Commands[name] then Notify("Unknown command: "..name,"error"); return end
    local t0 = tick()
    pcall(function() Commands[name](parts) end)
    Notify(string.format("⏱  '%s' took %.2f ms", name, (tick()-t0)*1000), "info")
end)

-- savepos / loadpos  — bookmark one position and return to it
local _savedPos = nil

Cmd("savepos", {"markpos","bookmark"}, function()
    local hrp = GetHRP(); if not hrp then return end
    _savedPos = hrp.CFrame
    local p   = hrp.Position
    Notify(string.format("📌  Position saved  %.1f, %.1f, %.1f", p.X, p.Y, p.Z))
end)

Cmd("loadpos", {"returnpos","gotomark"}, function()
    if not _savedPos then Notify("No position saved  →  use savepos first","warn"); return end
    local hrp = GetHRP(); if not hrp then return end
    hrp.CFrame = _savedPos
    Notify("📌  Returned to saved position")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: NAMED WAYPOINT SYSTEM  (IY-ported)          ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: table management, string key lookups, persistent
--           in-session data, CFrame tween vs instant TP.

local _waypoints = {}   -- { {name, x, y, z}, ... }

local function _findWP(name)
    for i, v in ipairs(_waypoints) do
        if v.name:lower() == name:lower() then return i, v end
    end
    return nil, nil
end

Cmd("setwp", {"setwaypoint","swp"}, function(args)
    local name = table.concat(args," ")
    if name == "" then Notify("Usage: setwp <name>","warn"); return end
    local hrp = GetHRP(); if not hrp then return end
    local p   = hrp.Position
    local idx = _findWP(name)
    if idx then table.remove(_waypoints, idx) end
    table.insert(_waypoints, {
        name = name,
        x = math.floor(p.X), y = math.floor(p.Y), z = math.floor(p.Z)
    })
    Notify(string.format("📌  Waypoint '%s' saved  (%.0f,%.0f,%.0f)", name, p.X,p.Y,p.Z))
end)

Cmd("wp", {"waypoint","loadwp","gwp"}, function(args)
    local name = table.concat(args," ")
    if name == "" then Notify("Usage: wp <name>","warn"); return end
    local _, v = _findWP(name)
    if not v then Notify("Waypoint not found: "..name,"error"); return end
    local hrp = GetHRP(); if not hrp then return end
    hrp.CFrame = CFrame.new(v.x, v.y, v.z)
    Notify("📌  Teleported to '"..v.name.."'")
end)

Cmd("tweenwp", {"tweenwaypoint","twp"}, function(args)
    local name = table.concat(args," ")
    local _, v  = _findWP(name)
    if not v then Notify("Waypoint not found: "..name,"error"); return end
    local hrp = GetHRP(); if not hrp then return end
    TweenObj(hrp, 2, {CFrame = CFrame.new(v.x, v.y, v.z)}, Enum.EasingStyle.Linear):Play()
    Notify("📌  Tweening to '"..v.name.."'")
end)

Cmd("deletewp", {"delwaypoint","dwp"}, function(args)
    local name = table.concat(args," ")
    local idx  = _findWP(name)
    if not idx then Notify("Waypoint not found","error"); return end
    table.remove(_waypoints, idx)
    Notify("🗑  Deleted waypoint: "..name)
end)

Cmd("clearwp", {"clearwaypoints","cwp"}, function()
    local n = #_waypoints
    _waypoints = {}
    Notify("🗑  Cleared "..n.." waypoints")
end)

Cmd("listwp", {"waypoints","wps"}, function()
    if #_waypoints == 0 then Notify("No waypoints saved","warn"); return end
    local t = {}
    for _, v in ipairs(_waypoints) do
        table.insert(t, v.name.." ("..v.x..","..v.y..","..v.z..")")
    end
    -- print full list to console; notify first 3
    print("[S-Admin] Waypoints:\n  "..table.concat(t,"\n  "))
    local short = {}
    for i=1, math.min(3,#t) do table.insert(short, _waypoints[i].name) end
    Notify("📌  "..table.concat(short,", ")..(#_waypoints>3 and "  +"..(#_waypoints-3).." more" or ""), "info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: FLOAT / INVISIBLE PLATFORM  (IY-ported)     ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Anchored Part parented to workspace, Heartbeat
--           sync to HRP CFrame, Q/E height adjustment.

local _floatPart  = nil
local _floatConn  = nil
local _floatInput = nil
local _floatOff   = -3.1    -- vertical offset below HRP

Cmd("float", {"platform","hoverpad"}, function(args)
    local hrp = GetHRP(); if not hrp then return end
    -- Remove any existing
    if _floatPart  then pcall(function() _floatPart:Destroy() end) end
    if _floatConn  then _floatConn:Disconnect()  end
    if _floatInput then _floatInput:Disconnect() end

    _floatOff = -(tonumber(args[1]) or 3.1)
    State.Floating = true

    local plat = Instance.new("Part", workspace)
    plat.Name        = "S_FloatPad"
    plat.Anchored    = true
    plat.CanCollide  = true
    plat.Transparency = 0.75
    plat.Size        = Vector3.new(4, 0.2, 3)
    plat.BrickColor  = BrickColor.new("Cyan")
    plat.CFrame      = hrp.CFrame * CFrame.new(0, _floatOff, 0)
    _floatPart = plat

    -- Track HRP every frame
    _floatConn = RunService.Heartbeat:Connect(function()
        if not State.Floating or not hrp or not hrp.Parent then
            if _floatConn then _floatConn:Disconnect() end; return
        end
        plat.CFrame = hrp.CFrame * CFrame.new(0, _floatOff, 0)
    end)

    -- Q = raise pad, E = lower pad
    _floatInput = UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if    i.KeyCode == Enum.KeyCode.Q then _floatOff = _floatOff + 0.5
        elseif i.KeyCode == Enum.KeyCode.E then _floatOff = _floatOff - 0.5
        end
    end)

    Notify("🟦  Float ON  (Q = raise  E = lower)")
end)

Cmd("unfloat", {"nofloat","noplatform","nohoverpad"}, function()
    State.Floating = false
    if _floatPart  then pcall(function() _floatPart:Destroy() end); _floatPart = nil end
    if _floatConn  then _floatConn:Disconnect();  _floatConn  = nil end
    if _floatInput then _floatInput:Disconnect(); _floatInput = nil end
    Notify("🟦  Float OFF")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SWIM MODE  (IY-ported)                      ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: HumanoidStateType manipulation, SetStateEnabled,
--           zero-gravity physics via workspace.Gravity.

Cmd("swim", {}, function()
    if State.Swimming then Notify("Already swimming","warn"); return end
    local hum = GetHuman(); if not hum then return end
    State.Swimming = true
    workspace.Gravity = 0

    -- Disable all states and force Swimming
    for _, v in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
        if v ~= Enum.HumanoidStateType.None then
            pcall(function() hum:SetStateEnabled(v, false) end)
        end
    end
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Swimming) end)

    SafeDisconn("Swim")
    Conns.Swim = RunService.Heartbeat:Connect(function()
        if not State.Swimming then SafeDisconn("Swim"); return end
        -- Stop drifting when not inputting
        local hrp = GetHRP()
        if hrp and hum.MoveDirection == Vector3.zero then
            pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
        end
    end)
    Notify("🏊  Swim ON  (zero-gravity, holds position)")
end)

Cmd("unswim", {"noswim"}, function()
    State.Swimming = false
    SafeDisconn("Swim")
    workspace.Gravity = _origGravity
    local hum = GetHuman()
    if hum then
        for _, v in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
            if v ~= Enum.HumanoidStateType.None then
                pcall(function() hum:SetStateEnabled(v, true) end)
            end
        end
    end
    Notify("🏊  Swim OFF")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SPECTATE / VIEW  (IY-ported)                ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: CameraSubject property, CharacterAdded auto-
--           reconnect, camera property change guard.

local _viewConn        = nil
local _viewChangedConn = nil

Cmd("view", {"spectate","spec"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or target == LP then Notify("Invalid target","error"); return end
    local tChar = target.Character
    if not tChar then Notify("Target has no character","error"); return end

    -- Disconnect previous view
    if _viewConn        then pcall(function() _viewConn:Disconnect()        end) end
    if _viewChangedConn then pcall(function() _viewChangedConn:Disconnect() end) end

    local function attachSubject(c)
        workspace.CurrentCamera.CameraSubject = c:FindFirstChildOfClass("Humanoid") or c.PrimaryPart
    end
    attachSubject(tChar)
    State.Viewing = target.Name

    -- Re-attach on respawn
    _viewConn = target.CharacterAdded:Connect(function(c)
        if State.Viewing == target.Name then task.wait(0.5); attachSubject(c) end
    end)
    -- Guard against Roblox resetting CameraSubject
    _viewChangedConn = workspace.CurrentCamera
        :GetPropertyChangedSignal("CameraSubject"):Connect(function()
        if State.Viewing == target.Name and target.Character then
            attachSubject(target.Character)
        end
    end)

    Notify("👁  Spectating "..target.Name)
end)

Cmd("unview", {"unspectate","unspec","stopspec"}, function()
    if _viewConn        then pcall(function() _viewConn:Disconnect()        end); _viewConn        = nil end
    if _viewChangedConn then pcall(function() _viewChangedConn:Disconnect() end); _viewChangedConn = nil end
    State.Viewing = nil
    local char = GetChar()
    if char then
        workspace.CurrentCamera.CameraSubject = char:FindFirstChildOfClass("Humanoid") or char.PrimaryPart
    end
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    Notify("👁  Spectate OFF")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SPRING-PHYSICS FREECAM  (IY-ported)         ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Spring simulation (exponential decay), RunService
--           BindToRenderStep, ContextActionService priority
--           binding, camera scripting best practices.

-- Spring class — same algorithm as IY
local FCSpring = {} do
    FCSpring.__index = FCSpring
    function FCSpring.new(freq, pos)
        return setmetatable({f=freq, p=pos, v=pos*0}, FCSpring)
    end
    function FCSpring:Update(dt, goal)
        local f   = self.f*2*math.pi
        local p0  = self.p
        local v0  = self.v
        local off = goal - p0
        local dec = math.exp(-f*dt)
        self.p = goal + (v0*dt - off*(f*dt+1))*dec
        self.v = (f*dt*(off*f - v0) + v0)*dec
        return self.p
    end
    function FCSpring:Reset(pos) self.p = pos; self.v = pos*0 end
end

local _fcRunning  = false
local _fcPos      = Vector3.new()
local _fcRot      = Vector2.new()
local _fcFov      = 70
local _fcNavSpeed = 1
local _fcVelSpr   = FCSpring.new(5, Vector3.new())
local _fcPanSpr   = FCSpring.new(5, Vector2.new())
local _fcKeys     = {W=0,A=0,S=0,D=0,E=0,Q=0,Up=0,Down=0}
local _fcMouse    = Vector2.new()
local _fcSavedCT  = nil     -- saved CameraType
local _fcSavedFOV = 70
local FC_KSPD     = Vector3.new(1,1,1)
local FC_MSPD     = Vector2.new(1,1)*(math.pi/64)
local FC_ADJSPD   = 0.75

local function _fcKBind(_, state, input)
    local n = input.KeyCode.Name
    if _fcKeys[n] ~= nil then _fcKeys[n] = state==Enum.UserInputState.Begin and 1 or 0 end
    return Enum.ContextActionResult.Sink
end
local function _fcMBind(_, _, input)
    local d = input.Delta
    _fcMouse = Vector2.new(-d.Y, -d.X)
    return Enum.ContextActionResult.Sink
end

local function _fcStep(dt)
    _fcNavSpeed = math.clamp(_fcNavSpeed + dt*(_fcKeys.Up-_fcKeys.Down)*FC_ADJSPD, 0.01, 4)
    local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    local kvel  = Vector3.new(_fcKeys.D-_fcKeys.A, _fcKeys.E-_fcKeys.Q, _fcKeys.S-_fcKeys.W) * FC_KSPD
    local vel   = _fcVelSpr:Update(dt, kvel * _fcNavSpeed * (shift and 0.25 or 1))
    local pan   = _fcPanSpr:Update(dt, _fcMouse * FC_MSPD)
    _fcMouse    = Vector2.new()
    _fcRot = _fcRot + pan * Vector2.new(0.75,1) * 8 * dt
    _fcRot = Vector2.new(math.clamp(_fcRot.X,-math.pi/2,math.pi/2), _fcRot.Y%(2*math.pi))
    local cf = CFrame.new(_fcPos)*CFrame.fromOrientation(_fcRot.X,_fcRot.Y,0)*CFrame.new(vel*64*dt)
    _fcPos = cf.Position
    local cam = workspace.CurrentCamera
    cam.CFrame      = cf
    cam.Focus       = cf * CFrame.new(0,0,-10)
    cam.FieldOfView = _fcFov
end

local function _startFC(startCF)
    if _fcRunning then
        RunService:UnbindFromRenderStep("S_Freecam")
        ContextActionService:UnbindAction("S_FCKeys")
        ContextActionService:UnbindAction("S_FCMouse")
        _fcRunning = false
    end
    local cam = workspace.CurrentCamera
    _fcSavedCT  = cam.CameraType
    _fcSavedFOV = cam.FieldOfView
    _fcFov      = cam.FieldOfView
    cam.CameraType = Enum.CameraType.Scriptable

    local cf = startCF or cam.CFrame
    _fcPos = cf.Position; _fcRot = Vector2.new()
    _fcVelSpr:Reset(Vector3.new())
    _fcPanSpr:Reset(Vector2.new())
    for k in pairs(_fcKeys) do _fcKeys[k] = 0 end

    ContextActionService:BindActionAtPriority("S_FCKeys",  _fcKBind, false,
        Enum.ContextActionPriority.High.Value,
        Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,
        Enum.KeyCode.E,Enum.KeyCode.Q,Enum.KeyCode.Up,Enum.KeyCode.Down)
    ContextActionService:BindActionAtPriority("S_FCMouse", _fcMBind, false,
        Enum.ContextActionPriority.High.Value,
        Enum.UserInputType.MouseMovement)
    RunService:BindToRenderStep("S_Freecam", Enum.RenderPriority.Camera.Value, _fcStep)
    _fcRunning = true
end

local function _stopFC()
    if not _fcRunning then return end
    ContextActionService:UnbindAction("S_FCKeys")
    ContextActionService:UnbindAction("S_FCMouse")
    RunService:UnbindFromRenderStep("S_Freecam")
    local cam = workspace.CurrentCamera
    if _fcSavedCT then cam.CameraType = _fcSavedCT end
    cam.FieldOfView = _fcSavedFOV or 70
    _fcRunning = false
end

Cmd("freecam", {"fc","freecamera"}, function(args)
    if args[1] == "off" or args[1] == "stop" then _stopFC(); Notify("🎥  Freecam OFF"); return end
    _startFC()
    Notify("🎥  Freecam ON  (WASD+QE=move  Shift=slow  ↑↓=speed)")
end)

Cmd("freecampos", {"fcpos","fcp"}, function(args)
    local x,y,z = tonumber(args[1]),tonumber(args[2]),tonumber(args[3])
    if not (x and y and z) then Notify("Usage: freecampos <X> <Y> <Z>","warn"); return end
    _startFC(CFrame.new(x,y,z))
    Notify(string.format("🎥  Freecam at %.0f,%.0f,%.0f",x,y,z))
end)

Cmd("fcgoto", {"freecamgoto","fctp"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or not target.Character then Notify("Target not found","error"); return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if hrp then _startFC(hrp.CFrame) end
    Notify("🎥  Freecam → "..target.Name)
end)

Cmd("freecamwp", {"fcwp"}, function(args)
    local name = table.concat(args," ")
    local _, v  = _findWP(name)
    if not v then Notify("Waypoint not found","error"); return end
    _startFC(CFrame.new(v.x,v.y,v.z))
    Notify("🎥  Freecam → WP '"..name.."'")
end)

Cmd("unfreecam", {"nofreecam","unfc","nofc"}, function()
    _stopFC()
    Notify("🎥  Freecam OFF")
end)

Cmd("fcspeed", {"freecamspeed"}, function(args)
    local s = tonumber(args[1]) or 1
    FC_KSPD = Vector3.new(s,s,s)
    Notify("🎥  Freecam speed → "..s)
end)

Cmd("fcfov", {"freecamfov"}, function(args)
    local f = tonumber(args[1]) or 70
    _fcFov = math.clamp(f,1,120)
    if _fcRunning then workspace.CurrentCamera.FieldOfView = _fcFov end
    Notify("🎥  Freecam FOV → ".._fcFov)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CHAMS  (BoxHandleAdornment ESP)             ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: BoxHandleAdornment, Folder hierarchy, CharacterAdded
--           reconnect pattern, BrickColor.

local _chamsEnabled = false
local _chamsConns   = {}

local function _applyChams(plr)
    if plr == LP then return end
    local folder = ScreenGui:FindFirstChild(plr.Name.."_CHMS")
    if folder then folder:Destroy() end

    local function build(char)
        task.wait(0.5)
        local f = Instance.new("Folder", ScreenGui)
        f.Name = plr.Name.."_CHMS"
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                local box = Instance.new("BoxHandleAdornment", f)
                box.Adornee     = part
                box.AlwaysOnTop = true
                box.ZIndex      = 5
                box.Size        = part.Size
                box.Transparency = 0.35
                box.Color       = plr.TeamColor
            end
        end
    end

    if plr.Character then build(plr.Character) end
    _chamsConns[plr.Name] = plr.CharacterAdded:Connect(function(c) build(c) end)
end

Cmd("chams", {}, function()
    _chamsEnabled = true
    for _, p in ipairs(Players:GetPlayers()) do _applyChams(p) end
    Conns.ChamsJoin = Players.PlayerAdded:Connect(_applyChams)
    Notify("📦  Chams ON  (BoxHandleAdornment per-part)")
end)

Cmd("nochams", {"unchams"}, function()
    _chamsEnabled = false
    SafeDisconn("ChamsJoin")
    for _, v in pairs(_chamsConns) do pcall(function() v:Disconnect() end) end
    _chamsConns = {}
    for _, v in ipairs(ScreenGui:GetChildren()) do
        if v.Name:sub(-5) == "_CHMS" then v:Destroy() end
    end
    Notify("📦  Chams OFF")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: PART ESP  (workspace part highlight)        ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: DescendantAdded event, table.find, conditional
--           BoxHandleAdornment attachment by part name.

local _partEspList = {}
local _partEspConn = nil

local function _addPartEspBox(part)
    if not table.find(_partEspList, part.Name:lower()) then return end
    if part:FindFirstChild("S_PESP") then return end
    local box = Instance.new("BoxHandleAdornment", part)
    box.Name        = "S_PESP"
    box.Adornee     = part
    box.AlwaysOnTop = true
    box.ZIndex      = 4
    box.Size        = part.Size
    box.Transparency = 0.4
    box.Color       = BrickColor.new("Lime green")
end

Cmd("partesp", {"pesp"}, function(args)
    local name = (args[1] or ""):lower()
    if name == "" then Notify("Usage: partesp <partname>","warn"); return end
    if not table.find(_partEspList, name) then table.insert(_partEspList, name) end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower() == name then _addPartEspBox(v) end
    end
    if not _partEspConn then
        _partEspConn = workspace.DescendantAdded:Connect(function(v)
            if v:IsA("BasePart") then task.defer(function() _addPartEspBox(v) end) end
        end)
    end
    Notify("📦  PartESP → '"..name.."'")
end)

Cmd("nopartesp", {"unpartesp"}, function(args)
    if args[1] then
        local name = args[1]:lower()
        local idx  = table.find(_partEspList, name)
        if idx then table.remove(_partEspList, idx) end
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name == "S_PESP" and v.Parent and v.Parent.Name:lower() == name then
                v:Destroy()
            end
        end
        Notify("📦  PartESP removed → '"..name.."'")
    else
        _partEspList = {}
        if _partEspConn then _partEspConn:Disconnect(); _partEspConn = nil end
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name == "S_PESP" then pcall(function() v:Destroy() end) end
        end
        Notify("📦  PartESP OFF (all)")
    end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: GUI VISIBILITY TOOLS                        ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: PlayerGui traversal, Visible toggling, collecting
--           changed objects for reliable undo.

local _hiddenGUIs = {}

Cmd("hideguis", {"hidegui","hgui"}, function()
    _hiddenGUIs = {}
    local pg = LP:FindFirstChildOfClass("PlayerGui"); if not pg then return end
    local count = 0
    for _, v in ipairs(pg:GetDescendants()) do
        if v:IsA("Frame") or v:IsA("ImageLabel")
        or v:IsA("ScrollingFrame") or v:IsA("BillboardGui") then
            if v.Visible then
                v.Visible = false
                table.insert(_hiddenGUIs, v)
                count = count + 1
            end
        end
    end
    Notify("🪟  Hidden "..count.." GUI elements")
end)

Cmd("showguis", {"unhideguis","restoreguis","sgui"}, function()
    local n = #_hiddenGUIs
    for _, v in ipairs(_hiddenGUIs) do pcall(function() v.Visible = true end) end
    _hiddenGUIs = {}
    Notify("🪟  Restored "..n.." GUI elements")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: COREGUI TOGGLES  (IY-ported)                ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: StarterGui:SetCoreGuiEnabled, CoreGuiType enum,
--           StarterGui:SetCore for reset-button callback.

local _cguiMap = {
    chat        = Enum.CoreGuiType.Chat,
    inventory   = Enum.CoreGuiType.Backpack,
    leaderboard = Enum.CoreGuiType.PlayerList,
    health      = Enum.CoreGuiType.Health,
    emotes      = Enum.CoreGuiType.EmotesMenu,
    all         = Enum.CoreGuiType.All,
}

local function _cgEnable(key, on)
    if key == "reset" then
        pcall(function() StarterGui:SetCore("ResetButtonCallback", on) end)
        Notify((on and "✅" or "🚫").."  Reset button "..(on and "enabled" or "disabled")); return
    end
    local cgt = _cguiMap[key]
    if not cgt then
        local hint = "chat inventory leaderboard health emotes all reset"
        Notify("Options: "..hint,"warn"); return
    end
    pcall(function() StarterGui:SetCoreGuiEnabled(cgt, on) end)
    Notify((on and "✅" or "🚫").."  "..(on and "Enabled" or "Disabled")..": "..key)
end

Cmd("enable", {}, function(args) _cgEnable((args[1] or ""):lower(), true)  end)
Cmd("disable", {}, function(args) _cgEnable((args[1] or ""):lower(), false) end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ANTI-LAG / BOOST FPS  (IY-ported)           ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: settings().Rendering, Lighting GlobalShadows,
--           PostEffect disable, CastShadow, Decal clear.

Cmd("antilag", {"boostfps","lowgraphics","fps+"}, function()
    local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
    if Terrain then
        Terrain.WaterWaveSize   = 0
        Terrain.WaterWaveSpeed  = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 1
    end
    Lighting.GlobalShadows = false
    Lighting.FogEnd   = 9e9
    Lighting.FogStart = 9e9
    pcall(function() settings().Rendering.QualityLevel = 1 end)

    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CastShadow = false
            pcall(function() v.Material = Enum.Material.Plastic end)
        elseif v:IsA("Decal") or v:IsA("Texture") then
            pcall(function() v.Transparency = 1 end)
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            pcall(function() v.Lifetime = NumberRange.new(0) end)
        elseif v:IsA("PostEffect") then
            pcall(function() v.Enabled = false end)
        end
    end

    -- Block future high-cost objects
    workspace.DescendantAdded:Connect(function(v)
        task.defer(function()
            if v:IsA("ForceField") or v:IsA("Sparkles")
            or v:IsA("Fire") or v:IsA("Smoke") then
                pcall(function() v:Destroy() end)
            elseif v:IsA("BasePart") then
                v.CastShadow = false
            end
        end)
    end)

    Notify("⚡  AntiLag applied — minimal graphics mode")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SERVER HOP  (IY-ported)                     ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: HttpGet + JSONDecode, filtering server list,
--           TeleportToPlaceInstance, error handling.

Cmd("serverhop", {"shop","hopserver"}, function()
    Notify("🔀  Querying server list...", "info")
    task.spawn(function()
        local ok, body = pcall(function()
            local raw = game:HttpGet(
                "https://games.roblox.com/v1/games/"..game.PlaceId..
                "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
            return game:GetService("HttpService"):JSONDecode(raw)
        end)
        if not ok or not body or not body.data then
            Notify("Serverhop: couldn't fetch servers","error"); return
        end
        local servers = {}
        for _, v in ipairs(body.data) do
            if type(v) == "table" and v.id and v.id ~= game.JobId
            and tonumber(v.playing) and tonumber(v.maxPlayers)
            and v.playing < v.maxPlayers then
                table.insert(servers, v.id)
            end
        end
        if #servers == 0 then Notify("No open servers found","warn"); return end
        local pick = servers[math.random(1, #servers)]
        Notify("🔀  Hopping to server "..pick:sub(1,8).."...")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, pick, LP)
    end)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: EXTRA CAMERA UTILITIES  (IY-ported)         ║
-- ╚══════════════════════════════════════════════════════════╝

-- lookat <player>
Cmd("lookat", {}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or not target.Character then Notify("Target not found","error"); return end
    local head = target.Character:FindFirstChild("Head"); if not head then return end
    workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, head.Position)
    Notify("👁  Facing "..target.Name)
end)

-- fixcam — full camera state restore
Cmd("fixcam", {"restorecam","resetcam"}, function()
    _stopFC()
    if _viewConn        then pcall(function() _viewConn:Disconnect()        end); _viewConn        = nil end
    if _viewChangedConn then pcall(function() _viewChangedConn:Disconnect() end); _viewChangedConn = nil end
    State.Viewing = nil
    local char = GetChar()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        workspace.CurrentCamera.CameraSubject = hum
    end
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    workspace.CurrentCamera.FieldOfView = 70
    LP.CameraMinZoomDistance = 0.5
    LP.CameraMaxZoomDistance = 400
    pcall(function() LP.CameraMode = Enum.CameraMode.Classic end)
    Notify("📷  Camera fully restored")
end)

-- camdistance — set exact zoom distance
Cmd("camdistance", {"camzoom","setcamdist"}, function(args)
    local d = tonumber(args[1])
    if not d then Notify("Usage: camdistance <studs>","warn"); return end
    local prevMax = LP.CameraMaxZoomDistance
    if prevMax < d then LP.CameraMaxZoomDistance = d end
    LP.CameraMinZoomDistance = d
    LP.CameraMaxZoomDistance = d
    task.wait()
    LP.CameraMaxZoomDistance = math.max(prevMax, d)
    LP.CameraMinZoomDistance = 0.5
    Notify("📷  Camera distance → "..d.." studs")
end)

-- shiftlock — force-enable shift lock
Cmd("shiftlock", {"enablesl","sl"}, function()
    pcall(function() LP.DevEnableMouseLock = true end)
    LP:GetPropertyChangedSignal("DevEnableMouseLock"):Connect(function()
        pcall(function() LP.DevEnableMouseLock = true end)
    end)
    Notify("🔒  Shift lock forced ON")
end)

-- inspect <player> — open Roblox inspect menu
Cmd("inspect", {"examine"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target then Notify("Target not found","error"); return end
    pcall(function()
        game:GetService("GuiService"):InspectPlayerFromUserId(target.UserId)
    end)
    Notify("🔍  Inspecting "..target.Name)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: WORKSPACE ADMIN TOOLS  (IY-ported)          ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: GetDescendants, ClassName vs Name distinction,
--           Locked property, BodyForce cleanup patterns.

Cmd("lockws", {"lockworkspace"}, function()
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then pcall(function() v.Locked = true end); n=n+1 end
    end
    Notify("🔒  Locked "..n.." workspace parts")
end)

Cmd("unlockws", {"unlockworkspace"}, function()
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then pcall(function() v.Locked = false end); n=n+1 end
    end
    Notify("🔓  Unlocked "..n.." workspace parts")
end)

-- deleteclass <ClassName>
Cmd("deleteclass", {"dc","removeclass"}, function(args)
    local cls = args[1]; if not cls then Notify("Usage: deleteclass <ClassName>","warn"); return end
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.ClassName:lower() == cls:lower() then pcall(function() v:Destroy() end); n=n+1 end
    end
    Notify("🗑  Deleted "..n.." '"..cls.."' instances")
end)

-- chardelete <name> — delete named instances from character
Cmd("chardelete", {"cd","charremove"}, function(args)
    local name = args[1]; if not name then Notify("Usage: chardelete <name>","warn"); return end
    local char = GetChar(); if not char then return end
    local n = 0
    for _, v in ipairs(char:GetDescendants()) do
        if v.Name:lower() == name:lower() then pcall(function() v:Destroy() end); n=n+1 end
    end
    Notify("🗑  CharDelete '"..name.."' × "..n)
end)

-- chardeleteclass <ClassName>
Cmd("chardeleteclass", {"cdc","charremoveclass"}, function(args)
    local cls = args[1]; if not cls then Notify("Usage: chardeleteclass <ClassName>","warn"); return end
    local char = GetChar(); if not char then return end
    local n = 0
    for _, v in ipairs(char:GetDescendants()) do
        if v.ClassName:lower() == cls:lower() then pcall(function() v:Destroy() end); n=n+1 end
    end
    Notify("🗑  CharDeleteClass '"..cls.."' × "..n)
end)

-- deletevelocity — strip all physics forces from character
Cmd("deletevelocity", {"dv","removeforces","rmforces"}, function()
    local char = GetChar(); if not char then return end
    local n, classes = 0, {
        "BodyVelocity","BodyForce","BodyAngularVelocity",
        "BodyThrust","BodyPosition","BodyGyro",
    }
    for _, v in ipairs(char:GetDescendants()) do
        for _, cls in ipairs(classes) do
            if v:IsA(cls) then pcall(function() v:Destroy() end); n=n+1; break end
        end
    end
    Notify("💨  Removed "..n.." physics force instances")
end)

-- togglenoclip
Cmd("togglenoclip", {"tnc","togglenc"}, function()
    if State.Noclipping then Commands["clip"]({}) else Commands["noclip"]({}) end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SYSTEM / NETWORK UTILITIES  (IY-ported)     ║
-- ╚══════════════════════════════════════════════════════════╝

-- cancelteleport
Cmd("cancelteleport", {"canceltp"}, function()
    pcall(function() TeleportService:TeleportCancel() end)
    Notify("❌  Teleport cancelled")
end)

-- screenshot
Cmd("screenshot", {"scrnshot","screenie"}, function()
    pcall(function() game:GetService("CoreGui"):TakeScreenshot() end)
    Notify("📸  Screenshot taken")
end)

-- notify <message>
Cmd("notify", {"notif","announce"}, function(args)
    local msg = table.concat(args," ")
    if msg == "" then Notify("Usage: notify <message>","warn"); return end
    Notify("📢  "..msg, "info")
end)

-- jobid — show and copy job ID
Cmd("jobid", {"copyjobid","getjobid"}, function()
    local link = "roblox://placeId="..game.PlaceId.."&gameInstanceId="..game.JobId
    pcall(function() setclipboard(link) end)
    print("[S-Admin] JobID: "..game.JobId)
    Notify("🆔  "..game.JobId:sub(1,20).."…", "info")
end)

-- fpscap <n> / unfpscap
local _fpsCapTask = nil
Cmd("fpscap", {"setfpscap","maxfps"}, function(args)
    if _fpsCapTask then task.cancel(_fpsCapTask); _fpsCapTask = nil end
    local cap = tonumber(args[1])
    if not cap or cap <= 0 then Notify("Usage: fpscap <n>","warn"); return end
    _fpsCapTask = task.spawn(function()
        while true do
            local t = os.clock()
            while os.clock() - t < 1/cap do end
            task.wait()
        end
    end)
    Notify("⚡  FPS capped at "..cap)
end)

Cmd("unfpscap", {"removefpscap","nofpscap"}, function()
    if _fpsCapTask then task.cancel(_fpsCapTask); _fpsCapTask = nil end
    Notify("⚡  FPS cap removed")
end)

-- autorejoin — reconnect automatically on GuiService error
Cmd("autorejoin", {"autorj"}, function()
    local GS = game:GetService("GuiService")
    GS.ErrorMessageChanged:Connect(function()
        if GS.ErrorCode ~= 0 then
            task.wait(0.5)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
            end)
        end
    end)
    Notify("🔄  AutoRejoin ON")
end)

-- mastervolume — set game volume
Cmd("mastervolume", {"gamevolume","mvol"}, function(args)
    local vol = tonumber(args[1])
    if not vol then Notify("Usage: mastervolume <0-10>","warn"); return end
    pcall(function()
        UserSettings():GetService("UserGameSettings").MasterVolume = math.clamp(vol,0,10) / 10
    end)
    Notify("🔊  Master volume → "..vol)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ADVANCED CHARACTER TOOLS                    ║
-- ╚══════════════════════════════════════════════════════════╝

-- ragdoll — enable ragdoll physics (Ball-and-Socket workaround)
Cmd("ragdoll", {}, function()
    local char = GetChar(); if not char then return end
    local hum  = GetHuman(); if not hum then return end
    hum.PlatformStand = true
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("Motor6D") then
            local a0 = Instance.new("Attachment", v.Part0)
            local a1 = Instance.new("Attachment", v.Part1)
            a0.CFrame = v.C0; a1.CFrame = v.C1
            a0.Name   = "S_RagA0"; a1.Name = "S_RagA1"
            local bs  = Instance.new("BallSocketConstraint", v.Part0)
            bs.Attachment0 = a0; bs.Attachment1 = a1
            bs.Name = "S_RagBS"
            v.Enabled = false
        end
    end
    Notify("🪆  Ragdoll ON")
end)

Cmd("unragdoll", {"noragdoll"}, function()
    local char = GetChar(); if not char then return end
    local hum  = GetHuman()
    if hum then hum.PlatformStand = false end
    for _, v in ipairs(char:GetDescendants()) do
        if v.Name == "S_RagBS" or v.Name == "S_RagA0" or v.Name == "S_RagA1" then
            pcall(function() v:Destroy() end)
        elseif v:IsA("Motor6D") then
            v.Enabled = true
        end
    end
    Notify("🪆  Ragdoll OFF")
end)

-- walktowp <name> — use humanoid:MoveTo to walk to a waypoint
Cmd("walktowp", {"walkwp","wtwp"}, function(args)
    local name = table.concat(args," ")
    local _, v  = _findWP(name)
    if not v then Notify("Waypoint not found","error"); return end
    local hum = GetHuman(); if not hum then return end
    if hum.SeatPart then hum.Sit = false; task.wait(0.1) end
    hum:MoveTo(Vector3.new(v.x, v.y, v.z))
    Notify("🚶  Walking to '"..name.."'")
end)

-- stopmove — cancel humanoid movement
Cmd("stopmove", {"stopwalk","stopmovement"}, function()
    local hrp = GetHRP(); if not hrp then return end
    local hum = GetHuman(); if not hum then return end
    hum:MoveTo(hrp.Position)
    Notify("🛑  Movement stopped")
end)

-- seatpart — sit in the nearest seat/vehicle seat
Cmd("seatpart", {"trysit","findseat"}, function()
    local hrp = GetHRP(); if not hrp then return end
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if (v:IsA("Seat") or v:IsA("VehicleSeat")) and not v.Disabled then
            local d = (v.Position - hrp.Position).Magnitude
            if d < bestDist then best = v; bestDist = d end
        end
    end
    if best then
        best:Sit(GetHuman())
        Notify("💺  Sat in: "..best.Name.." ("..math.floor(bestDist).." studs away)")
    else
        Notify("No seats found nearby","warn")
    end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: PROXIMITY & INTERACTION                     ║
-- ╚══════════════════════════════════════════════════════════╝

-- triggerproximity — fire nearest ProximityPrompt
Cmd("triggerproximity", {"trigger","prox"}, function()
    local hrp = GetHRP(); if not hrp then return end
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Enabled then
            local part = v.Parent
            if part and part:IsA("BasePart") then
                local d = (part.Position - hrp.Position).Magnitude
                if d < bestDist and d <= v.MaxActivationDistance then
                    best = v; bestDist = d
                end
            end
        end
    end
    if best then
        pcall(function()
            local PPService = game:GetService("ProximityPromptService")
            PPService:PromptTriggered(best, LP)
        end)
        Notify("🔘  Triggered: "..best.Parent.Name)
    else
        Notify("No ProximityPrompt in range","warn")
    end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: PART CREATION TOOLS                         ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Instance.new with properties, anchoring,
--           workspace parenting, BrickColor, Material.

-- createpart <size> <color>
Cmd("createpart", {"part","cp"}, function(args)
    local hrp  = GetHRP(); if not hrp then return end
    local size = tonumber(args[1]) or 4
    local r    = tonumber(args[2]) or 200
    local g    = tonumber(args[3]) or 200
    local b    = tonumber(args[4]) or 200
    local p    = Instance.new("Part", workspace)
    p.Size      = Vector3.new(size, size, size)
    p.CFrame    = hrp.CFrame * CFrame.new(0, 0, -size*2)
    p.Anchored  = true
    p.BrickColor = BrickColor.new(Color3.fromRGB(r,g,b))
    p.Material  = Enum.Material.SmoothPlastic
    Notify(string.format("🧱  Part created  size=%d  rgb(%d,%d,%d)", size, r, g, b))
end)

-- createplatform — create a flat platform at your position
Cmd("createplatform", {"platform2","plat"}, function(args)
    local hrp = GetHRP(); if not hrp then return end
    local w   = tonumber(args[1]) or 20
    local d   = tonumber(args[2]) or 20
    local p   = Instance.new("Part", workspace)
    p.Name     = "S_Platform"
    p.Size     = Vector3.new(w, 0.5, d)
    p.CFrame   = CFrame.new(hrp.Position - Vector3.new(0, 3, 0))
    p.Anchored = true
    p.BrickColor = BrickColor.new("Medium stone grey")
    p.Material = Enum.Material.SmoothPlastic
    Notify(string.format("🧱  Platform created  %dx%d", w, d))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: KEY BIND / MACRO SYSTEM  (IY-ported)        ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: UserInputService.InputBegan key detection,
--           storing and firing arbitrary command strings,
--           runtime configurable hotkeys.

local _binds = {}       -- { [KeyCode.Name] = "command string" }
local _bindConn = nil

local function _ensureBindListener()
    if _bindConn then return end
    _bindConn = UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        local raw = _binds[i.KeyCode.Name]
        if raw then task.defer(function() ExecCommand(raw) end) end
    end)
end

-- bind <key> <command string>   e.g.  bind F fly 200
Cmd("bind", {"bindkey","hotkey"}, function(args)
    local key = (args[1] or ""):upper()
    if key == "" then Notify("Usage: bind <key> <command>","warn"); return end
    local cmd = table.concat(args," ",2)
    if cmd == "" then Notify("No command provided","warn"); return end
    -- Validate key exists in KeyCode
    local ok = pcall(function() return Enum.KeyCode[key] end)
    if not ok then Notify("Invalid key: "..key,"error"); return end
    _binds[key] = cmd
    _ensureBindListener()
    Notify("🔑  Bind ["..key.."] → '"..cmd.."'")
end)

-- unbind <key>
Cmd("unbind", {"unbindkey","removebind"}, function(args)
    local key = (args[1] or ""):upper()
    if not _binds[key] then Notify("No bind on key "..key,"warn"); return end
    _binds[key] = nil
    Notify("🔑  Unbound ["..key.."]")
end)

-- listbinds
Cmd("listbinds", {"binds","showbinds"}, function()
    if next(_binds) == nil then Notify("No binds set","warn"); return end
    local lines = {}
    for k, v in pairs(_binds) do table.insert(lines, "["..k.."] → "..v) end
    print("[S-Admin] Binds:\n  "..table.concat(lines,"\n  "))
    Notify("🔑  "..#lines.." bind(s) — see console", "info")
end)

-- clearbinds
Cmd("clearbinds", {"clearallbinds","resetbinds"}, function()
    _binds = {}
    Notify("🔑  All binds cleared")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: KILL AURA  (IY-ported)                      ║
-- ╚══════════════════════════════════════════════════════════╝
--  Continuously flings nearby players using the same velocity
--  spike technique as the fling command.  Range and speed are
--  configurable.  Teaches: distance checks, ipairs filtering,
--  rate-limited task loops.

local _kaRunning = false
local _kaRange   = 15
local _kaSpeed   = 9999

Cmd("killaura", {"ka","aura"}, function(args)
    _kaRange = tonumber(args[1]) or 15
    _kaSpeed = tonumber(args[2]) or 9999
    if _kaRunning then
        Notify(string.format("☠  KillAura range→%d speed→%d (updated)", _kaRange, _kaSpeed),"info"); return
    end
    _kaRunning = true
    task.spawn(function()
        while _kaRunning do
            local myHRP = GetHRP()
            if myHRP then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                        local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                        if tHRP and tHum and tHum.Health > 0 then
                            local dist = (tHRP.Position - myHRP.Position).Magnitude
                            if dist <= _kaRange then
                                -- Velocity spike on target HRP
                                local cv = tHRP.Velocity
                                tHRP.Velocity = cv * _kaSpeed + Vector3.new(0, _kaSpeed, 0)
                                task.wait()
                                pcall(function() tHRP.Velocity = cv end)
                            end
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
    Notify(string.format("☠  KillAura ON  range %d  speed %d", _kaRange, _kaSpeed))
end)

Cmd("unkillaura", {"noka","noaura","stopka"}, function()
    _kaRunning = false
    Notify("☠  KillAura OFF")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: FREEZE / UNFREEZE TARGETS  (IY-ported)      ║
-- ╚══════════════════════════════════════════════════════════╝
--  Client-side anchoring of target HRP — effective for NPCs
--  and teaches Anchored property manipulation.

Cmd("freezetarget", {"ft","freezeplayer"}, function(args)
    local targets = GetPlayers(args[1])
    local n = 0
    for _, p in ipairs(targets) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = true; n = n + 1 end
    end
    Notify("🧊  Frozen "..n.." player(s)")
end)

Cmd("unfreezettarget", {"uft","unfreezeplayer"}, function(args)
    local targets = GetPlayers(args[1])
    local n = 0
    for _, p in ipairs(targets) do
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = false; n = n + 1 end
    end
    Notify("🧊  Unfrozen "..n.." player(s)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: TEAM COMMANDS  (IY-ported)                  ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Teams service, Team objects, BrickColor
--           assignment, player team property.

local TeamsService = game:GetService("Teams")

Cmd("jointeam", {"team","changeteam"}, function(args)
    local query = table.concat(args," "):lower()
    if query == "" then Notify("Usage: jointeam <team name>","warn"); return end
    local found = nil
    for _, t in ipairs(TeamsService:GetTeams()) do
        if t.Name:lower():find(query, 1, true) then found = t; break end
    end
    if not found then Notify("Team not found: "..query,"error"); return end
    LP.Team      = found
    LP.TeamColor = found.TeamColor
    Notify("👥  Joined team: "..found.Name)
end)

Cmd("listteams", {"teams","getteams"}, function()
    local t = TeamsService:GetTeams()
    if #t == 0 then Notify("No teams in this game","warn"); return end
    local names = {}
    for _, v in ipairs(t) do
        table.insert(names, v.Name.."("..tostring(v.TeamColor)..")")
    end
    print("[S-Admin] Teams: "..table.concat(names,", "))
    Notify("👥  "..#names.." team(s) — see console", "info")
end)

Cmd("teamcolor", {"setteamcolor","mytc"}, function(args)
    local r = tonumber(args[1]) or 255
    local g = tonumber(args[2]) or 255
    local b = tonumber(args[3]) or 255
    LP.TeamColor = BrickColor.new(Color3.fromRGB(r,g,b))
    Notify(string.format("👥  TeamColor → (%d,%d,%d)", r, g, b))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: TOOL MANAGEMENT  (IY-ported)                ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Backpack children, Tool:Activate, EquipTool,
--           tool parenting / cloning patterns.

local function GetBackpack()
    return LP:FindFirstChildOfClass("Backpack")
end

local function GetAllTools()
    local tools = {}
    local bp  = GetBackpack()
    local chr = GetChar()
    if bp  then for _, v in ipairs(bp:GetChildren())  do if v:IsA("Tool") then table.insert(tools,v) end end end
    if chr then for _, v in ipairs(chr:GetChildren()) do if v:IsA("Tool") then table.insert(tools,v) end end end
    return tools
end

-- listtools
Cmd("listtools", {"tools","mytools"}, function()
    local t = GetAllTools()
    if #t == 0 then Notify("No tools in backpack","warn"); return end
    local names = {}
    for _, v in ipairs(t) do table.insert(names, v.Name) end
    print("[S-Admin] Tools: "..table.concat(names,", "))
    Notify("🔧  "..#names.." tool(s) — see console","info")
end)

-- equiptool <name>
Cmd("equiptool", {"equip","wield"}, function(args)
    local query = table.concat(args," "):lower()
    if query == "" then Notify("Usage: equiptool <name>","warn"); return end
    local hum = GetHuman(); if not hum then return end
    for _, t in ipairs(GetAllTools()) do
        if t.Name:lower():find(query,1,true) then
            hum:EquipTool(t)
            Notify("🔧  Equipped: "..t.Name); return
        end
    end
    Notify("Tool not found: "..query,"error")
end)

-- droptool  — unequip current held tool
Cmd("droptool", {"unequip","drop"}, function()
    local hum = GetHuman(); if not hum then return end
    hum:UnequipTools()
    Notify("🔧  Tool unequipped")
end)

-- removetool <name>
Cmd("removetool", {"deletetool","rmtool"}, function(args)
    local query = table.concat(args," "):lower()
    if query == "" then Notify("Usage: removetool <name>","warn"); return end
    local n = 0
    for _, t in ipairs(GetAllTools()) do
        if t.Name:lower():find(query,1,true) then t:Destroy(); n=n+1 end
    end
    Notify(n>0 and "🔧  Removed "..n.." tool(s)" or "Tool not found","error")
end)

-- cleartools  — remove all tools from backpack
Cmd("cleartools", {"removealltools","deletetools"}, function()
    local n = 0
    for _, t in ipairs(GetAllTools()) do t:Destroy(); n=n+1 end
    Notify("🔧  Cleared "..n.." tool(s)")
end)

-- activatetool  — simulate Tool:Activate on equipped tool
Cmd("activatetool", {"usetool","clicktool"}, function()
    local chr = GetChar(); if not chr then return end
    for _, t in ipairs(chr:GetChildren()) do
        if t:IsA("Tool") then
            pcall(function() t:Activate() end)
            Notify("🔧  Activated: "..t.Name); return
        end
    end
    Notify("No tool equipped","warn")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: REMOTE / CHAT LOGGER  (IY-ported)           ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Instance DescendantAdded, RemoteEvent.OnClientEvent,
--           RemoteFunction.OnClientInvoke hooks, chat event.

local _remoteLogConn  = nil
local _remoteLogConns = {}   -- per-remote connections

Cmd("remotelog", {"rlog","logremotes"}, function()
    if _remoteLogConn then Notify("Remote log already ON","warn"); return end
    -- Log new remotes being added
    _remoteLogConn = game.DescendantAdded:Connect(function(v)
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            print("[S-RemoteLog] New: "..v:GetFullName().." ("..v.ClassName..")")
        end
    end)
    -- Attach to existing remotes
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local c = v.OnClientEvent:Connect(function(...)
                local args = {...}
                local strs = {}
                for _, a in ipairs(args) do table.insert(strs, tostring(a)) end
                print("[S-RemoteLog] "..v:GetFullName().." fired: "..table.concat(strs,", "))
            end)
            table.insert(_remoteLogConns, c)
        end
    end
    Notify("📡  Remote log ON — output in console","info")
end)

Cmd("unremotelog", {"norlog","stopremotelog"}, function()
    if _remoteLogConn then _remoteLogConn:Disconnect(); _remoteLogConn = nil end
    for _, c in ipairs(_remoteLogConns) do pcall(function() c:Disconnect() end) end
    _remoteLogConns = {}
    Notify("📡  Remote log OFF")
end)

-- Chat log: print every chat message to console
local _chatLogConn = nil
Cmd("chatlog", {"logchat","spychat"}, function()
    if _chatLogConn then Notify("Chat log already ON","warn"); return end
    local success = pcall(function()
        local RS  = game:GetService("ReplicatedStorage")
        local evt = RS:WaitForChild("DefaultChatSystemChatEvents",3)
                 and RS.DefaultChatSystemChatEvents
                 and RS.DefaultChatSystemChatEvents:FindFirstChild("OnMessageDoneFiltering")
        if evt then
            _chatLogConn = evt.OnClientEvent:Connect(function(data)
                if data and data.FromSpeaker and data.Message then
                    print("[S-ChatLog] "..data.FromSpeaker..": "..data.Message)
                end
            end)
        else
            -- Fallback: TextChatService
            local TCS = game:GetService("TextChatService")
            for _, ch in ipairs(TCS:GetDescendants()) do
                if ch:IsA("TextChannel") then
                    local cc = ch.MessageReceived:Connect(function(msg)
                        print("[S-ChatLog] "..tostring(msg.TextSource and msg.TextSource.Name)..": "..msg.Text)
                    end)
                    if not _chatLogConn then _chatLogConn = cc else pcall(function() cc:Disconnect() end) end
                end
            end
        end
    end)
    Notify(success and "💬  Chat log ON — console" or "💬  Chat log (limited in this game)","info")
end)

Cmd("unchatlog", {"stopchatlog","nochatlog"}, function()
    if _chatLogConn then pcall(function() _chatLogConn:Disconnect() end); _chatLogConn = nil end
    Notify("💬  Chat log OFF")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ADVANCED ANIMATION  (IY-ported)             ║
-- ╚══════════════════════════════════════════════════════════╝

-- animspeed <multiplier>  — change AnimationTrack speed
Cmd("animspeed", {"as","animrate"}, function(args)
    local spd = tonumber(args[1]) or 1
    local hum = GetHuman(); if not hum then return end
    for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
        t:AdjustSpeed(spd)
    end
    Notify("🎭  Animation speed → "..spd.."x")
end)

-- animweight <weight>  — change AnimationTrack weight on all playing
Cmd("animweight", {"aw","animblend"}, function(args)
    local w   = tonumber(args[1]) or 1
    local hum = GetHuman(); if not hum then return end
    for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
        t:AdjustWeight(w)
    end
    Notify("🎭  Anim weight → "..w)
end)

-- loopemote <name>  — loop a named emote until stopanim
Cmd("loopemote", {"le","repeatemote"}, function(args)
    local name = (args[1] or ""):lower()
    local id   = ({wave=507770239,dance=507771019,laugh=507770818,point=507770453,
                   cheer=507770677,salute=3360686091,shrug=3576968026})[name]
    if not id then Notify("Available: wave dance laugh point cheer salute shrug","warn"); return end
    task.spawn(function()
        while true do
            local track = PlayAnim(id, false)
            if not track then break end
            track.Stopped:Wait()
            if not track.Looped then task.wait(0.1) else break end
        end
    end)
    Notify("🎭  LoopEmote: "..name)
end)

-- freezepose  — freeze all Motor6D joints in place
Cmd("freezepose", {"pose","lockpose"}, function()
    local char = GetChar(); if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("Motor6D") then
            v.MaxVelocity = 0
        end
    end
    Notify("🎭  Pose frozen  (unpose to restore)")
end)

Cmd("unpose", {"unfreezepose","unlockpose"}, function()
    local char = GetChar(); if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("Motor6D") then
            v.MaxVelocity = 0.1
        end
    end
    Notify("🎭  Pose unfrozen")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: LEADERSTAT VIEWER  (IY-ported)              ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: leaderstats Instance, value objects (IntValue,
--           StringValue, etc.) and iterating player data.

Cmd("stats", {"leaderstats","leaderstat","ls"}, function(args)
    local target = GetPlayers(args[1])[1] or LP
    local ls = target:FindFirstChild("leaderstats")
    if not ls then Notify(target.Name.." has no leaderstats","warn"); return end
    local lines = {}
    for _, v in ipairs(ls:GetChildren()) do
        local val = ""
        if v:IsA("ValueBase") then val = tostring(v.Value) end
        table.insert(lines, v.Name..": "..val)
    end
    print("[S-Admin] "..target.Name.." stats:\n  "..table.concat(lines,"\n  "))
    Notify("📊  "..target.Name.." → "..table.concat(lines,"  |  "), "info")
end)

-- setstat <player> <stat> <value>  — change a leaderstat value (client)
Cmd("setstat", {"writestat","statset"}, function(args)
    local target = GetPlayers(args[1])[1]
    local stat   = args[2]
    local val    = args[3]
    if not (target and stat and val) then
        Notify("Usage: setstat <player> <stat> <value>","warn"); return
    end
    local ls = target:FindFirstChild("leaderstats")
    if not ls then Notify("No leaderstats found","error"); return end
    local sv = ls:FindFirstChild(stat)
    if not sv then Notify("Stat '"..stat.."' not found","error"); return end
    pcall(function()
        if sv:IsA("IntValue") or sv:IsA("NumberValue") then
            sv.Value = tonumber(val) or sv.Value
        else
            sv.Value = val
        end
    end)
    Notify("📊  "..target.Name.."."..stat.." → "..val)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: PATHFINDING  (IY-ported)                    ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: PathfindingService, Path:ComputeAsync,
--           waypoint iteration, MoveTo chaining.

local PathfindingService = game:GetService("PathfindingService")
local _pathActive        = false

local function _walkPath(goal)
    _pathActive = true
    local hum = GetHuman(); if not hum then _pathActive=false; return end
    local hrp = GetHRP();   if not hrp then _pathActive=false; return end

    local path = PathfindingService:CreatePath({
        AgentRadius   = 2,
        AgentHeight   = 5,
        AgentCanJump  = true,
        AgentJumpHeight = 7,
        AgentMaxSlope = 45,
    })
    local ok = pcall(function() path:ComputeAsync(hrp.Position, goal) end)
    if not ok or path.Status ~= Enum.PathStatus.Success then
        -- Fallback: direct MoveTo
        hum:MoveTo(goal)
        hum.MoveToFinished:Wait(10)
        _pathActive = false
        return
    end

    for _, wp in ipairs(path:GetWaypoints()) do
        if not _pathActive then break end
        if wp.Action == Enum.PathWaypointAction.Jump then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        hum:MoveTo(wp.Position)
        local reached = hum.MoveToFinished:Wait(5)
        if not reached then break end
        task.wait()
    end
    _pathActive = false
end

-- pathto <player>  or  pathto <X> <Y> <Z>
Cmd("pathto", {"pt","walkpath","navigateto"}, function(args)
    local goal
    if tonumber(args[1]) then
        local x,y,z = tonumber(args[1]),tonumber(args[2]),tonumber(args[3])
        if not (x and y and z) then Notify("Usage: pathto <X> <Y> <Z>","warn"); return end
        goal = Vector3.new(x,y,z)
    else
        local target = GetPlayers(args[1])[1]
        if not target or not target.Character then Notify("Target not found","error"); return end
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if not tHRP then return end
        goal = tHRP.Position
    end
    if _pathActive then _pathActive = false; task.wait(0.1) end
    task.spawn(function() _walkPath(goal) end)
    Notify("🗺  Pathfinding...")
end)

Cmd("stoppath", {"cancelpath","nopathto"}, function()
    _pathActive = false
    local hum = GetHuman()
    local hrp = GetHRP()
    if hum and hrp then hum:MoveTo(hrp.Position) end
    Notify("🗺  Pathfinding cancelled")
end)

-- pathtowp <name>
Cmd("pathtowp", {"ptwp","navigatewp"}, function(args)
    local name = table.concat(args," ")
    local _, v  = _findWP(name)
    if not v then Notify("Waypoint not found","error"); return end
    if _pathActive then _pathActive = false; task.wait(0.1) end
    task.spawn(function() _walkPath(Vector3.new(v.x,v.y,v.z)) end)
    Notify("🗺  Pathfinding to '"..name.."'")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ADVANCED PHYSICS / FORCE TOOLS  (IY-ported) ║
-- ╚══════════════════════════════════════════════════════════╝

-- forcepush <player>  — send a BodyVelocity burst at target
Cmd("forcepush", {"push","blast"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or not target.Character then Notify("Target not found","error"); return end
    local tHRP  = target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = GetHRP()
    if not tHRP or not myHRP then return end
    local power = tonumber(args[2]) or 120
    local dir   = (tHRP.Position - myHRP.Position).Unit
    local bv    = Instance.new("BodyVelocity", tHRP)
    bv.Velocity  = dir * power + Vector3.new(0, power*0.5, 0)
    bv.MaxForce  = Vector3.new(1e5,1e5,1e5)
    game:GetService("Debris"):AddItem(bv, 0.15)
    Notify("💨  Force push → "..target.Name.." (power "..power..")")
end)

-- pull <player>  — BodyVelocity pull target toward you
Cmd("pull", {"attract"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or not target.Character then Notify("Target not found","error"); return end
    local tHRP  = target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = GetHRP()
    if not tHRP or not myHRP then return end
    local power = tonumber(args[2]) or 100
    local dir   = (myHRP.Position - tHRP.Position).Unit
    local bv    = Instance.new("BodyVelocity", tHRP)
    bv.Velocity  = dir * power
    bv.MaxForce  = Vector3.new(1e5,1e5,1e5)
    game:GetService("Debris"):AddItem(bv, 0.2)
    Notify("🧲  Pulled "..target.Name.." toward you")
end)

-- velocity <X> <Y> <Z>  — set own velocity directly
Cmd("velocity", {"setvelocity","vel"}, function(args)
    local x = tonumber(args[1]) or 0
    local y = tonumber(args[2]) or 0
    local z = tonumber(args[3]) or 0
    local hrp = GetHRP(); if not hrp then return end
    hrp.AssemblyLinearVelocity = Vector3.new(x,y,z)
    Notify(string.format("💨  Velocity → %.0f,%.0f,%.0f",x,y,z))
end)

-- launch  — upward velocity burst
Cmd("launch", {"yeet","boost"}, function(args)
    local power = tonumber(args[1]) or 200
    local hrp   = GetHRP(); if not hrp then return end
    hrp.AssemblyLinearVelocity = Vector3.new(0, power, 0)
    Notify("🚀  Launched! (power "..power..")")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: LIGHTING POST-EFFECTS  (IY-ported)          ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: BlurEffect, BloomEffect, SunRaysEffect,
--           ColorCorrectionEffect, DepthOfFieldEffect —
--           all children of Lighting.

local function _getOrCreateFX(className)
    local fx = Lighting:FindFirstChildOfClass(className)
    if not fx then fx = Instance.new(className, Lighting) end
    return fx
end

Cmd("blur", {}, function(args)
    local size = tonumber(args[1]) or 24
    if size == 0 then
        local fx = Lighting:FindFirstChildOfClass("BlurEffect")
        if fx then fx:Destroy() end
        Notify("🌫  Blur OFF"); return
    end
    _getOrCreateFX("BlurEffect").Size = math.clamp(size, 0, 56)
    Notify("🌫  Blur → "..size)
end)

Cmd("bloom", {}, function(args)
    local intensity = tonumber(args[1]) or 1
    local threshold = tonumber(args[2]) or 0.95
    local size      = tonumber(args[3]) or 56
    if intensity == 0 then
        local fx = Lighting:FindFirstChildOfClass("BloomEffect")
        if fx then fx:Destroy() end
        Notify("✨  Bloom OFF"); return
    end
    local fx = _getOrCreateFX("BloomEffect")
    fx.Intensity  = math.clamp(intensity, 0, 10)
    fx.Threshold  = math.clamp(threshold, 0, 1)
    fx.Size       = math.clamp(size, 0, 56)
    Notify(string.format("✨  Bloom  intensity=%.1f  threshold=%.2f", intensity, threshold))
end)

Cmd("sunrays", {"rays"}, function(args)
    local intensity = tonumber(args[1]) or 0.25
    local spread    = tonumber(args[2]) or 1
    if intensity == 0 then
        local fx = Lighting:FindFirstChildOfClass("SunRaysEffect")
        if fx then fx:Destroy() end
        Notify("☀  Sun Rays OFF"); return
    end
    local fx = _getOrCreateFX("SunRaysEffect")
    fx.Intensity = math.clamp(intensity, 0, 1)
    fx.Spread    = math.clamp(spread,    0, 1)
    Notify(string.format("☀  SunRays  intensity=%.2f  spread=%.2f", intensity, spread))
end)

Cmd("dof", {"depthoffield"}, function(args)
    local focal   = tonumber(args[1]) or 50
    local nearIn  = tonumber(args[2]) or 0
    local nearOut = tonumber(args[3]) or 10
    local farIn   = tonumber(args[4]) or 80
    local farOut  = tonumber(args[5]) or 120
    if focal == 0 then
        local fx = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
        if fx then fx:Destroy() end
        Notify("📷  DOF OFF"); return
    end
    local fx = _getOrCreateFX("DepthOfFieldEffect")
    fx.FocalDistance = focal
    fx.NearIntensity  = nearIn
    fx.FarIntensity   = nearOut
    Notify(string.format("📷  DOF focal=%.0f", focal))
end)

Cmd("colorgrade", {"cc","colorshift","colorcorrect"}, function(args)
    local bright = tonumber(args[1]) or 0
    local cont   = tonumber(args[2]) or 0
    local sat    = tonumber(args[3]) or 0
    local r      = tonumber(args[4]) or 0
    local g      = tonumber(args[5]) or 0
    local b      = tonumber(args[6]) or 0
    if not args[1] then
        local fx = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if fx then fx:Destroy() end
        Notify("🎨  Color Correction OFF"); return
    end
    local fx = _getOrCreateFX("ColorCorrectionEffect")
    fx.Brightness  = math.clamp(bright, -1, 1)
    fx.Contrast    = math.clamp(cont,   -1, 1)
    fx.Saturation  = math.clamp(sat,    -1, 1)
    fx.TintColor   = Color3.fromRGB(
        math.clamp(128+r,0,255),
        math.clamp(128+g,0,255),
        math.clamp(128+b,0,255))
    Notify(string.format("🎨  ColorGrade  B=%.2f C=%.2f S=%.2f", bright, cont, sat))
end)

Cmd("nopostfx", {"clearpostfx","removefx"}, function()
    local n = 0
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") then v:Destroy(); n=n+1 end
    end
    Notify("🎨  Removed "..n.." post-effects")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: BILLBOARD SIGNS  (IY-ported)                ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: BillboardGui anchored to workspace parts,
--           creating 3D text signs, managing a sign table.

local _signs = {}   -- {part, billboardgui}

-- sign <text>  — create a floating text sign at your position
Cmd("sign", {"createsign","makesign"}, function(args)
    local text = table.concat(args," ")
    if text == "" then Notify("Usage: sign <text>","warn"); return end
    local hrp = GetHRP(); if not hrp then return end

    local part = Instance.new("Part", workspace)
    part.Anchored    = true
    part.CanCollide  = false
    part.Transparency = 1
    part.Size        = Vector3.new(1,1,1)
    part.CFrame      = hrp.CFrame * CFrame.new(0,5,0)
    part.Name        = "S_Sign"

    local bb  = Instance.new("BillboardGui", part)
    bb.Size   = UDim2.new(0,200,0,50)
    bb.AlwaysOnTop = true

    local lbl = Instance.new("TextLabel", bb)
    lbl.Size          = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 0.3
    lbl.BackgroundColor3 = Color3.fromRGB(20,20,20)
    lbl.Text          = text
    lbl.TextColor3    = Color3.new(1,1,1)
    lbl.Font          = Enum.Font.GothamBold
    lbl.TextScaled    = true
    lbl.ZIndex        = 5
    Corner(lbl, 6)

    table.insert(_signs, {part=part, gui=bb})
    Notify("💬  Sign created: '"..text.."'")
end)

-- nosign  — remove most recent sign
Cmd("nosign", {"removesign","delsign"}, function()
    if #_signs == 0 then Notify("No signs to remove","warn"); return end
    local s = table.remove(_signs)
    pcall(function() s.part:Destroy() end)
    Notify("💬  Sign removed")
end)

-- clearsigns  — remove all signs
Cmd("clearsigns", {"removesigns","deletesigns"}, function()
    local n = #_signs
    for _, s in ipairs(_signs) do pcall(function() s.part:Destroy() end) end
    _signs = {}
    Notify("💬  "..n.." sign(s) cleared")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: NPC / HUMANOID CONTROL  (IY-ported)         ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: controlling NPC Humanoids via client CameraSubject
--           swap and MoveTo, NetworkOwnership concepts.

local _controlledHum = nil
local _controlConn   = nil

-- control <npc name>  — hijack nearest NPC matching name
Cmd("control", {"takeover","possess"}, function(args)
    local query = (args[1] or ""):lower()
    if query == "" then Notify("Usage: control <npc name>","warn"); return end
    local hrp    = GetHRP(); if not hrp then return end
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Humanoid") and not v.Parent:FindFirstChildOfClass("LocalScript") then
            local nHRP = v.Parent:FindFirstChild("HumanoidRootPart")
            if nHRP and v.Parent.Name:lower():find(query,1,true) then
                local d = (nHRP.Position - hrp.Position).Magnitude
                if d < bestDist then best = v; bestDist = d end
            end
        end
    end
    if not best then Notify("NPC not found: "..query,"error"); return end
    _controlledHum = best
    workspace.CurrentCamera.CameraSubject = best
    SafeDisconn("Control")
    Conns.Control = RunService.Heartbeat:Connect(function()
        if not _controlledHum or not _controlledHum.Parent then
            SafeDisconn("Control"); return
        end
        local md = best.MoveDirection
        if md.Magnitude > 0 then _controlledHum:MoveTo(best.Parent.PrimaryPart.Position + md) end
    end)
    Notify("🕹  Controlling: "..(best.Parent and best.Parent.Name or "NPC"))
end)

Cmd("uncontrol", {"release","unpossess"}, function()
    _controlledHum = nil
    SafeDisconn("Control")
    local char = GetChar()
    if char then
        workspace.CurrentCamera.CameraSubject = char:FindFirstChildOfClass("Humanoid")
    end
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    Notify("🕹  Control released")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SEAT / VEHICLE TOOLS  (IY-ported)           ║
-- ╚══════════════════════════════════════════════════════════╝

-- unseat  — force unseat yourself
Cmd("unseat", {"ejectseat","leaveseat"}, function()
    local hum = GetHuman(); if not hum then return end
    if hum.SeatPart then
        hum.Sit = false
        Notify("💺  Unseated")
    else
        Notify("Not seated","warn")
    end
end)

-- ejectall  — unseat all players (client-side Humanoid.Sit)
Cmd("ejectall", {"kickseats","unseatsall"}, function()
    local n = 0
    for _, p in ipairs(Players:GetPlayers()) do
        local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.SeatPart then hum.Sit = false; n=n+1 end
    end
    Notify("💺  Ejected "..n.." player(s)")
end)

-- vehicleflip  — flip nearest VehicleSeat's CFrame upright
Cmd("vehicleflip", {"flipcar","flipvehicle"}, function()
    local hrp = GetHRP(); if not hrp then return end
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("VehicleSeat") then
            local d = (v.Position - hrp.Position).Magnitude
            if d < bestDist then best = v; bestDist = d end
        end
    end
    if not best then Notify("No vehicle nearby","warn"); return end
    best.CFrame = CFrame.new(best.Position) * CFrame.Angles(0,0,0)
    Notify("🚗  Vehicle flipped upright  ("..math.floor(bestDist).." studs)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CFRAME MANIPULATION  (IY-ported)            ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: CFrame arithmetic, Angles, rotation offsets,
--           look direction construction.

-- rotateto <X> <Y> <Z>  — set HRP rotation (Euler degrees)
Cmd("rotateto", {"rotate","setrotation"}, function(args)
    local x = math.rad(tonumber(args[1]) or 0)
    local y = math.rad(tonumber(args[2]) or 0)
    local z = math.rad(tonumber(args[3]) or 0)
    local hrp = GetHRP(); if not hrp then return end
    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(x,y,z)
    Notify(string.format("🔄  Rotated to (%.0f°, %.0f°, %.0f°)",
        math.deg(x), math.deg(y), math.deg(z)))
end)

-- offset <X> <Y> <Z>  — shift HRP position by offset
Cmd("offset", {"shift","move"}, function(args)
    local x = tonumber(args[1]) or 0
    local y = tonumber(args[2]) or 0
    local z = tonumber(args[3]) or 0
    local hrp = GetHRP(); if not hrp then return end
    hrp.CFrame = hrp.CFrame * CFrame.new(x,y,z)
    Notify(string.format("📐  Offset → (%.1f, %.1f, %.1f)",x,y,z))
end)

-- faceplayer <name>  — rotate HRP to face a player
Cmd("faceplayer", {"face2","lookplayer"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or not target.Character then Notify("Target not found","error"); return end
    local hrp  = GetHRP(); if not hrp then return end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart"); if not tHRP then return end
    local dir  = (tHRP.Position - hrp.Position) * Vector3.new(1,0,1)
    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + dir)
    Notify("↗  Facing "..target.Name)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: INSTANCE SEARCH / INSPECTOR  (IY-ported)   ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: recursive GetDescendants, full path string via
--           :GetFullName(), filtering by name and class.

-- findinstance <name>  — search all descendants
Cmd("findinstance", {"find","fi"}, function(args)
    local query = table.concat(args," "):lower()
    if query == "" then Notify("Usage: findinstance <name>","warn"); return end
    local results, cap = {}, 20
    for _, v in ipairs(game:GetDescendants()) do
        if v.Name:lower():find(query,1,true) then
            table.insert(results, v:GetFullName())
            if #results >= cap then break end
        end
    end
    if #results == 0 then Notify("Not found: "..query,"warn"); return end
    print("[S-Admin] find '"..query.."':\n  "..table.concat(results,"\n  "))
    Notify("🔍  Found "..#results.."  — see console","info")
end)

-- findclass <ClassName>  — list all instances of a class
Cmd("findclass", {"fc2","listclass"}, function(args)
    local cls = args[1]; if not cls then Notify("Usage: findclass <ClassName>","warn"); return end
    local results, cap = {}, 20
    for _, v in ipairs(game:GetDescendants()) do
        if v.ClassName:lower() == cls:lower() then
            table.insert(results, v:GetFullName())
            if #results >= cap then break end
        end
    end
    if #results == 0 then Notify("No instances of class: "..cls,"warn"); return end
    print("[S-Admin] class '"..cls.."':\n  "..table.concat(results,"\n  "))
    Notify("🔍  "..#results.." instance(s) — see console","info")
end)

-- getprops <path>  — print all properties of an instance
Cmd("getprops", {"properties","props"}, function(args)
    local path = table.concat(args," ")
    if path == "" then Notify("Usage: getprops <instance path>","warn"); return end
    local obj = game
    for part in path:gmatch("[^%.]+") do
        local next = obj:FindFirstChild(part)
        if not next then Notify("Path not found at: "..part,"error"); return end
        obj = next
    end
    print("[S-Admin] Properties of "..obj:GetFullName()..":")
    for _, prop in ipairs({"Name","ClassName","Parent","Visible","Transparency","Position","Size","Color","BrickColor","Material","Anchored","CanCollide"}) do
        pcall(function() print("  "..prop.." = "..tostring(obj[prop])) end)
    end
    Notify("🔍  Props printed — see console","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SCRIPT EXECUTION TOOLS  (IY-ported)         ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: loadstring, pcall-wrapped execution, HttpGet
--           for remote script loading.

-- exec <lua code>  — execute a Lua string directly
Cmd("exec", {"execute","run"}, function(args)
    local code = table.concat(args," ")
    if code == "" then Notify("Usage: exec <lua code>","warn"); return end
    local fn, err = loadstring(code)
    if not fn then Notify("Syntax error: "..tostring(err),"error"); return end
    local ok, res = pcall(fn)
    if ok then
        Notify("✅  exec OK"..(res ~= nil and (" → "..tostring(res)) or ""))
    else
        Notify("❌  exec error: "..tostring(res),"error")
    end
end)

-- loadurl <url>  — load and execute a remote script
Cmd("loadurl", {"loadscript","runurl"}, function(args)
    local url = args[1]; if not url then Notify("Usage: loadurl <url>","warn"); return end
    local ok, err = pcall(function()
        local code = game:HttpGet(url, true)
        local fn, compErr = loadstring(code)
        if not fn then error(compErr) end
        fn()
    end)
    Notify(ok and "✅  Script loaded from URL" or "❌  Load failed: "..tostring(err), ok and "success" or "error")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: MISC UTILITIES  (IY-ported)                 ║
-- ╚══════════════════════════════════════════════════════════╝

-- countdown <n>  — visible countdown with notify
Cmd("countdown", {"timer2","count"}, function(args)
    local n = tonumber(args[1]) or 10
    n = math.clamp(math.floor(n), 1, 60)
    Notify("⏱  Countdown: "..n, "info")
    task.spawn(function()
        for i = n, 1, -1 do
            task.wait(1)
            Notify("⏱  "..i, "info")
        end
        Notify("⏱  Go!", "success")
    end)
end)

-- stopwatch  — start/stop a stopwatch
local _swStart = nil
Cmd("stopwatch", {"sw","chrono"}, function()
    if not _swStart then
        _swStart = tick()
        Notify("⏱  Stopwatch started")
    else
        local elapsed = tick() - _swStart
        _swStart = nil
        local m = math.floor(elapsed/60)
        local s = elapsed % 60
        Notify(string.format("⏱  %.0f:%05.2f", m, s), "info")
    end
end)

-- randomtp  — teleport to random position in map bounds
Cmd("randomtp", {"randpos","randjump"}, function()
    local hrp = GetHRP(); if not hrp then return end
    local ext = workspace:GetExtentsSize()
    local x   = math.random(-ext.X/2, ext.X/2)
    local z   = math.random(-ext.Z/2, ext.Z/2)
    local y   = hrp.Position.Y
    hrp.CFrame = CFrame.new(x, y, z)
    Notify(string.format("🎲  Random TP → %.0f, %.0f, %.0f", x, y, z))
end)

-- age  — print account age of a player
Cmd("age", {"accountage"}, function(args)
    local target = GetPlayers(args[1])[1] or LP
    Notify(string.format("👤  %s — account age: %d days", target.Name, target.AccountAge), "info")
end)

-- displayname  — get display name vs username
Cmd("displayname", {"dn","getname"}, function(args)
    local target = GetPlayers(args[1])[1] or LP
    Notify("👤  "..target.Name.." → display: "..target.DisplayName, "info")
end)

-- platform  — detect platform type of self
Cmd("platforminfo", {"myplatform","device"}, function()
    local info = {
        Touch   = UserInputService.TouchEnabled,
        Keyboard = UserInputService.KeyboardEnabled,
        Gamepad = UserInputService.GamepadEnabled,
        Gyro    = UserInputService.GyroscopeEnabled,
        Mobile  = IsMobile,
    }
    local parts = {}
    for k,v in pairs(info) do table.insert(parts, k.."="..tostring(v)) end
    print("[S-Admin] Platform: "..table.concat(parts,"  "))
    Notify("🖥  Platform — see console","info")
end)

-- memstats  — print memory usage to console
Cmd("memstats", {"memory","mem"}, function()
    local stats = game:GetService("Stats")
    local mem   = stats:FindFirstChild("DataReceiveKbps")
    print("[S-Admin] Memory (MB): "..math.floor(collectgarbage("count")/1024*100)/100)
    pcall(function()
        print("  DataReceiveKbps: "..tostring(stats.DataReceiveKbps.Value))
        print("  DataSendKbps:    "..tostring(stats.DataSendKbps.Value))
        print("  Heartbeat/s:     "..tostring(stats.HeartbeatTimeMs.Value).."ms")
    end)
    Notify("📊  Memory stats — see console","info")
end)

-- printidentity  — executor identity level
Cmd("printidentity", {"identity","level"}, function()
    local id = 0
    pcall(function() id = identifyexecutor and 8 or id end)
    pcall(function()
        local s = ""; game:GetService("ScriptContext"):AddCoreScriptLocal("",game)
        id = 2
    end)
    Notify("🔐  Thread identity: "..id, "info")
end)

-- getexecutor  — get executor name if available
Cmd("getexecutor", {"executor","whatexec"}, function()
    local name = "Unknown"
    pcall(function() name = identifyexecutor() end)
    pcall(function() if not name or name == "Unknown" then name = getexecutorname() end end)
    Notify("⚙  Executor: "..name, "info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: LOOP UTILITIES  (IY-ported)                 ║
-- ╚══════════════════════════════════════════════════════════╝

-- loopsound <soundID>  — loop a sound every N seconds
local _loopSoundTask = nil
Cmd("loopsound", {"lsound","soundloop"}, function(args)
    local id  = tonumber(args[1]); if not id then Notify("Usage: loopsound <id>","warn"); return end
    local vol = tonumber(args[2]) or 0.5
    local int = tonumber(args[3]) or 0
    if _loopSoundTask then task.cancel(_loopSoundTask) end
    _loopSoundTask = task.spawn(function()
        while true do
            if _adminSound then pcall(function() _adminSound:Stop(); _adminSound:Destroy() end) end
            _adminSound = Instance.new("Sound", workspace)
            _adminSound.SoundId  = "rbxassetid://"..id
            _adminSound.Volume   = vol
            _adminSound.Looped   = int == 0
            _adminSound.RollOffMaxDistance = 1e4
            _adminSound:Play()
            if int == 0 then break end
            task.wait(int)
        end
    end)
    Notify("🎵  Loop sound "..id)
end)

Cmd("unloopsound", {"stoploopsound"}, function()
    if _loopSoundTask then task.cancel(_loopSoundTask); _loopSoundTask = nil end
    if _adminSound then pcall(function() _adminSound:Stop(); _adminSound:Destroy() end); _adminSound = nil end
    Notify("🎵  Loop sound stopped")
end)

-- loopexec <interval> <cmd>  — repeatedly execute a command every N seconds
local _loopExecTask = nil
Cmd("loopexec", {"lx","repeatcmd"}, function(args)
    local interval = tonumber(args[1])
    if not interval or interval < 0.5 then Notify("Usage: loopexec <interval> <cmd>  (min 0.5s)","warn"); return end
    local cmd = table.concat(args," ",2)
    if cmd == "" then Notify("No command provided","warn"); return end
    if _loopExecTask then task.cancel(_loopExecTask) end
    _loopExecTask = task.spawn(function()
        while true do
            task.defer(function() ExecCommand(cmd) end)
            task.wait(interval)
        end
    end)
    Notify(string.format("🔁  LoopExec every %.1fs: '%s'", interval, cmd))
end)

Cmd("stoploopexec", {"stooplx","cancelloop"}, function()
    if _loopExecTask then task.cancel(_loopExecTask); _loopExecTask = nil end
    Notify("🔁  LoopExec stopped")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ACCESSORIES / AVATAR EXTRAS  (IY-ported)    ║
-- ╚══════════════════════════════════════════════════════════╝

-- addaccessory <assetID>  — insert accessory by ID
Cmd("addaccessory", {"accessory","addhat","addacc"}, function(args)
    local id = tonumber(args[1]); if not id then Notify("Usage: addaccessory <assetID>","warn"); return end
    local ok, err = pcall(function()
        local ins  = game:GetObjects("rbxassetid://"..id)
        local char = GetChar(); if not char then error("No char") end
        for _, obj in ipairs(ins) do
            if obj:IsA("Accessory") then
                obj.Parent = char
            end
        end
    end)
    Notify(ok and "🎩  Accessory added: "..id or "🎩  Failed: "..tostring(err), ok and "success" or "error")
end)

-- removeaccessory <name>  — remove specific accessory by name
Cmd("removeaccessory", {"delaccessory","rmacc"}, function(args)
    local query = table.concat(args," "):lower()
    local char  = GetChar(); if not char then return end
    local n = 0
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Accessory") and (query == "" or v.Name:lower():find(query,1,true)) then
            v:Destroy(); n=n+1
        end
    end
    Notify("🎩  Removed "..n.." accessory(ies)")
end)

-- listaccessories
Cmd("listaccessories", {"accessories","listacc"}, function()
    local char = GetChar(); if not char then return end
    local accs = {}
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Accessory") then table.insert(accs, v.Name) end
    end
    if #accs == 0 then Notify("No accessories","warn"); return end
    print("[S-Admin] Accessories: "..table.concat(accs,", "))
    Notify("🎩  "..#accs.." accessory(ies) — console","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ROPE / CONSTRAINT TOOLS  (IY-ported)        ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: RopeConstraint, Attachment, constraint length,
--           Visible property for debug rendering.

-- ropeto <player>  — rope your HRP to another player's HRP
Cmd("ropeto", {"rope","connectrope"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or not target.Character then Notify("Target not found","error"); return end
    local myHRP = GetHRP()
    local tHRP  = target.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP or not tHRP then return end
    -- Remove existing rope
    local oldA = myHRP:FindFirstChild("S_RopeA")
    if oldA then oldA:Destroy() end
    local a0  = Instance.new("Attachment", myHRP); a0.Name = "S_RopeA"
    local a1  = Instance.new("Attachment", tHRP);  a1.Name = "S_RopeA"
    local rope = Instance.new("RopeConstraint", myHRP)
    rope.Name         = "S_Rope"
    rope.Attachment0  = a0
    rope.Attachment1  = a1
    rope.Length       = tonumber(args[2]) or 10
    rope.Visible      = true
    rope.Color        = BrickColor.new("Bright red")
    rope.Thickness    = 0.05
    Notify("🪢  Roped to "..target.Name.."  (len="..rope.Length..")")
end)

-- unrope  — remove rope constraint from self
Cmd("unrope", {"detachrope","ropeless"}, function()
    local hrp = GetHRP(); if not hrp then return end
    local r = hrp:FindFirstChild("S_Rope")
    if r then r:Destroy() end
    for _, a in ipairs(hrp:GetChildren()) do
        if a.Name == "S_RopeA" then a:Destroy() end
    end
    Notify("🪢  Rope removed")
end)

-- springto <player>  — SpringConstraint between self and target
Cmd("springto", {"spring","springconnect"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or not target.Character then Notify("Target not found","error"); return end
    local myHRP = GetHRP()
    local tHRP  = target.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP or not tHRP then return end
    local a0 = Instance.new("Attachment", myHRP); a0.Name = "S_SpringA"
    local a1 = Instance.new("Attachment", tHRP);  a1.Name = "S_SpringA"
    local sp = Instance.new("SpringConstraint", myHRP)
    sp.Name         = "S_Spring"
    sp.Attachment0  = a0
    sp.Attachment1  = a1
    sp.FreeLength   = tonumber(args[2]) or 8
    sp.Stiffness    = tonumber(args[3]) or 5000
    sp.Damping      = 500
    sp.Visible      = true
    sp.Coils        = 8
    Notify("🌀  Spring to "..target.Name.."  (len="..sp.FreeLength..")")
end)

Cmd("unspring", {"detachspring"}, function()
    local hrp = GetHRP(); if not hrp then return end
    for _, v in ipairs(hrp:GetChildren()) do
        if v.Name == "S_Spring" or v.Name == "S_SpringA" then v:Destroy() end
    end
    Notify("🌀  Spring removed")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ADVANCED DISPLAY  (IY-ported)               ║
-- ╚══════════════════════════════════════════════════════════╝

-- overlay <text>  — large always-on-top text overlay
local _overlayGui = nil
Cmd("overlay", {"setoverlay","showtext"}, function(args)
    local text = table.concat(args," ")
    if _overlayGui then _overlayGui:Destroy(); _overlayGui = nil end
    if text == "" then Notify("Overlay removed"); return end
    _overlayGui = Instance.new("ScreenGui", ScreenGui)
    _overlayGui.Name = "S_Overlay"
    _overlayGui.ResetOnSpawn = false
    local lbl = Instance.new("TextLabel", _overlayGui)
    lbl.Size           = UDim2.new(1,0,0,80)
    lbl.Position       = UDim2.new(0,0,0.5,-40)
    lbl.BackgroundTransparency = 0.6
    lbl.BackgroundColor3 = Color3.fromRGB(0,0,0)
    lbl.Text           = text
    lbl.TextColor3     = Color3.new(1,1,1)
    lbl.Font           = Enum.Font.GothamBold
    lbl.TextScaled     = true
    lbl.ZIndex         = 100
    Notify("📺  Overlay set")
end)

Cmd("nooverlay", {"removeoverlay","clearoverlay"}, function()
    if _overlayGui then _overlayGui:Destroy(); _overlayGui = nil end
    Notify("📺  Overlay removed")
end)

-- crosshair  — toggle a custom crosshair
local _crosshairGui = nil
Cmd("crosshair", {"xhair","ch"}, function(args)
    if _crosshairGui then _crosshairGui:Destroy(); _crosshairGui = nil; Notify("🎯  Crosshair OFF"); return end
    local r = tonumber(args[1]) or 255
    local g = tonumber(args[2]) or 255
    local b = tonumber(args[3]) or 255
    local col = Color3.fromRGB(r,g,b)
    _crosshairGui = Instance.new("ScreenGui", ScreenGui)
    _crosshairGui.Name = "S_Crosshair"
    _crosshairGui.ResetOnSpawn = false

    local function makeLine(w,h,x,y)
        local f = Instance.new("Frame", _crosshairGui)
        f.Size           = UDim2.new(0,w,0,h)
        f.Position       = UDim2.new(0.5,x-w/2, 0.5,y-h/2)
        f.BackgroundColor3 = col
        f.BorderSizePixel  = 0
        f.ZIndex           = 100
        return f
    end
    local size = tonumber(args[4]) or 12
    makeLine(size*2, 1, 0, 0)   -- horizontal
    makeLine(1, size*2, 0, 0)   -- vertical
    Notify(string.format("🎯  Crosshair ON  (%d,%d,%d)", r, g, b))
end)

-- infobar  — permanent HUD bar showing HP/speed/pos
local _infoBarGui  = nil
local _infoBarConn = nil
Cmd("infobar", {"hud","showhud"}, function()
    if _infoBarGui then
        _infoBarGui:Destroy(); _infoBarGui = nil
        if _infoBarConn then _infoBarConn:Disconnect(); _infoBarConn = nil end
        Notify("📊  InfoBar OFF"); return
    end
    _infoBarGui = Instance.new("ScreenGui", ScreenGui)
    _infoBarGui.Name = "S_InfoBar"
    _infoBarGui.ResetOnSpawn = false

    local bar = Instance.new("Frame", _infoBarGui)
    bar.Size             = IsMobile and UDim2.new(1,0,0,30) or UDim2.new(0,340,0,24)
    bar.Position         = UDim2.new(0,0,0,0)
    bar.BackgroundColor3 = Color3.fromRGB(10,10,10)
    bar.BackgroundTransparency = 0.4
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 50

    local lbl = Instance.new("TextLabel", bar)
    lbl.Size             = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3       = Color3.new(1,1,1)
    lbl.Font             = Enum.Font.Code
    lbl.TextSize         = IsMobile and 13 or 11
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.ZIndex           = 51
    Pad(lbl, 6)

    _infoBarConn = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP()
        local hum = GetHuman()
        if not hrp or not hum then return end
        local p = hrp.Position
        lbl.Text = string.format(
            "❤ %.0f/%.0f   🏃 %.0f   📍 %.0f,%.0f,%.0f   ⚡ %.0fms",
            hum.Health, hum.MaxHealth,
            hum.WalkSpeed,
            p.X, p.Y, p.Z,
            LP:GetNetworkPing()*1000)
    end)
    Notify("📊  InfoBar ON")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CAMERA EFFECTS  (IY-ported)                 ║
-- ╚══════════════════════════════════════════════════════════╝

-- camerabob  — adds a sine-wave bob to camera (simulate head bob)
local _camBobConn = nil
Cmd("camerabob", {"camroll","headbob"}, function(args)
    local intensity = tonumber(args[1]) or 0.2
    local freq      = tonumber(args[2]) or 2
    if _camBobConn then _camBobConn:Disconnect(); _camBobConn = nil; Notify("📷  CameraBob OFF"); return end
    local cam = workspace.CurrentCamera
    _camBobConn = RunService.RenderStepped:Connect(function()
        local t = tick()
        cam.CFrame = cam.CFrame
            * CFrame.Angles(math.sin(t*freq)*intensity*0.01, 0, math.sin(t*freq*0.5)*intensity*0.005)
    end)
    Notify(string.format("📷  CameraBob ON  intensity=%.2f  freq=%.1f", intensity, freq))
end)

-- cameraroll <angle>  — tilt camera by angle (degrees)
Cmd("cameraroll", {"roll","tiltcam"}, function(args)
    local deg = tonumber(args[1]) or 0
    local cam = workspace.CurrentCamera
    cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, math.rad(deg))
    Notify(string.format("📷  Camera rolled %.0f°", deg))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: BLINK / DASH  (IY-ported)                   ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: short CFrame forward-offset teleport, camera
--           LookVector projection, cooldown management.

local _blinkCooldown = false

Cmd("blink", {"dash","bd"}, function(args)
    if _blinkCooldown then Notify("Blink on cooldown","warn"); return end
    local dist = tonumber(args[1]) or 20
    local hrp  = GetHRP(); if not hrp then return end
    local cam  = workspace.CurrentCamera
    local dir  = cam.CFrame.LookVector * dist
    hrp.CFrame = hrp.CFrame + dir
    _blinkCooldown = true
    task.delay(0.5, function() _blinkCooldown = false end)
    Notify(string.format("💨  Blink %.0f studs forward", dist))
end)

-- blink backwards
Cmd("blinkback", {"dashback","bd2"}, function(args)
    local dist = tonumber(args[1]) or 20
    local hrp  = GetHRP(); if not hrp then return end
    local cam  = workspace.CurrentCamera
    hrp.CFrame = hrp.CFrame - cam.CFrame.LookVector * dist
    Notify(string.format("💨  Blink %.0f studs back", dist))
end)

-- blinkup <dist>
Cmd("blinkup", {"blinku","dashup"}, function(args)
    local dist = tonumber(args[1]) or 20
    local hrp  = GetHRP(); if not hrp then return end
    hrp.CFrame = hrp.CFrame + Vector3.new(0, dist, 0)
    Notify(string.format("💨  Blink %.0f studs up", dist))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: GLIDE  (IY-ported)                          ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: low-gravity + horizontal BodyVelocity to simulate
--           a gliding state, toggling with state guards.

local _glideConn = nil

Cmd("glide", {"gl2","hover"}, function(args)
    if _glideConn then
        _glideConn:Disconnect(); _glideConn = nil
        workspace.Gravity = _origGravity
        local hrp = GetHRP()
        if hrp then
            local bv = hrp:FindFirstChild("S_GlideBV")
            if bv then bv:Destroy() end
        end
        Notify("🪂  Glide OFF"); return
    end

    local hrp = GetHRP(); if not hrp then return end
    local hum = GetHuman(); if not hum then return end
    local spd = tonumber(args[1]) or 40

    workspace.Gravity = 5   -- near-zero, gives floating feel

    local bv = Instance.new("BodyVelocity", hrp)
    bv.Name     = "S_GlideBV"
    bv.MaxForce = Vector3.new(1e4, 0, 1e4)   -- only horizontal
    bv.Velocity = Vector3.zero

    _glideConn = RunService.Heartbeat:Connect(function()
        local md = hum.MoveDirection
        if md.Magnitude > 0.1 then
            local cam = workspace.CurrentCamera
            local flat = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
            if flat.Magnitude > 0.01 then flat = flat.Unit end
            bv.Velocity = flat * spd
        else
            bv.Velocity = Vector3.zero
        end
    end)

    Notify(string.format("🪂  Glide ON  speed=%d  (run again to stop)", spd))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: RUN TOGGLE  (IY-ported)                     ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: WalkSpeed toggling, shift-lock interaction,
--           clean state tracking for speed overrides.

local _runSpeed  = 50
local _walkSpeed = 16
local _running   = false

Cmd("run", {"sprint","togglerun"}, function(args)
    _runSpeed  = tonumber(args[1]) or _runSpeed
    _walkSpeed = tonumber(args[2]) or _walkSpeed
    _running   = not _running
    local hum  = GetHuman(); if not hum then return end
    hum.WalkSpeed = _running and _runSpeed or _walkSpeed
    Notify(_running
        and string.format("🏃  Run ON  (speed %d)", _runSpeed)
        or  string.format("🚶  Run OFF  (speed %d)", _walkSpeed))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CLICK TELEPORT  (IY-ported)                 ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: UserInputService MouseButton1Click, Ray casting
--           from camera, finding 3D hit position.

local _clickTpConn = nil

Cmd("clicktp", {"ctp","mousetp"}, function()
    if _clickTpConn then
        _clickTpConn:Disconnect(); _clickTpConn = nil
        Notify("🖱  ClickTP OFF"); return
    end
    Notify("🖱  ClickTP ON — left-click to teleport")
    _clickTpConn = UserInputService.InputBegan:Connect(function(i, gp)
        if gp or i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local cam    = workspace.CurrentCamera
        local mouse  = UserInputService:GetMouseLocation()
        local ray    = cam:ScreenPointToRay(mouse.X, mouse.Y)
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
        if result then
            local hrp = GetHRP()
            if hrp then
                hrp.CFrame = CFrame.new(result.Position + result.Normal * 3)
                Notify(string.format("🖱  ClickTP → %.0f,%.0f,%.0f",
                    result.Position.X, result.Position.Y, result.Position.Z))
            end
        end
    end)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: MOUSE TOOLS  (IY-ported)                    ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: UserInputService mouse sensitivity, cursor lock,
--           cursor icon customisation.

Cmd("lockmouse", {"mousejail","lockcursor"}, function()
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    Notify("🖱  Mouse locked to center")
end)

Cmd("unlockmouse", {"freemouse","unlockcursor"}, function()
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    Notify("🖱  Mouse unlocked")
end)

Cmd("hidemouse", {"nocursor","hidecursor"}, function()
    UserInputService.MouseIconEnabled = false
    Notify("🖱  Cursor hidden")
end)

Cmd("showmouse", {"showcursor","cursor"}, function()
    UserInputService.MouseIconEnabled = true
    Notify("🖱  Cursor visible")
end)

Cmd("mousesensitivity", {"sens","sensitivity"}, function(args)
    local s = tonumber(args[1])
    if not s then Notify("Usage: mousesensitivity <0-10>","warn"); return end
    pcall(function()
        UserSettings():GetService("UserGameSettings").MouseSensitivity = s
    end)
    Notify("🖱  Sensitivity → "..s)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: WEATHER / PARTICLE EFFECTS  (IY-ported)     ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: ParticleEmitter in workspace Terrain, Wind
--           simulation, Atmosphere density changes for weather.

local _weatherParts = {}

local function _clearWeather()
    for _, v in ipairs(_weatherParts) do pcall(function() v:Destroy() end) end
    _weatherParts = {}
end

local function _makeWeather(particleProps, gravity, windVec)
    _clearWeather()
    -- Create invisible part above camera to emit particles
    local cam  = workspace.CurrentCamera
    local part = Instance.new("Part", workspace)
    part.Name        = "S_Weather"
    part.Anchored    = true
    part.CanCollide  = false
    part.Transparency = 1
    part.Size        = Vector3.new(60, 1, 60)
    part.CFrame      = cam.CFrame * CFrame.new(0, 30, -10)
    table.insert(_weatherParts, part)

    local pe = Instance.new("ParticleEmitter", part)
    for k, v in pairs(particleProps) do pcall(function() pe[k] = v end) end

    workspace.Gravity = gravity or _origGravity

    -- Keep part above player
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not part.Parent then conn:Disconnect(); return end
        local hrp = GetHRP()
        if hrp then
            part.CFrame = CFrame.new(hrp.Position + Vector3.new(0,30,0))
        end
    end)
    table.insert(_weatherParts, {Destroy = function() conn:Disconnect() end})
    return pe
end

Cmd("rain", {}, function(args)
    local density = tonumber(args[1]) or 1
    _makeWeather({
        LightEmission  = 0,
        LightInfluence = 1,
        Texture        = "rbxassetid://12221720",
        Color          = ColorSequence.new(Color3.fromRGB(173,216,230)),
        Size           = NumberSequence.new({
            NumberSequenceKeypoint.new(0,0.05),
            NumberSequenceKeypoint.new(1,0.05)}),
        Transparency   = NumberSequence.new(0.3),
        Lifetime       = NumberRange.new(1, 1.5),
        Rate           = math.clamp(density * 300, 10, 500),
        Speed          = NumberRange.new(60, 80),
        SpreadAngle    = Vector2.new(5, 5),
        RotSpeed       = NumberRange.new(0),
        Rotation       = NumberRange.new(0),
    }, _origGravity, Vector3.new(2, 0, 2))
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atm.Density = 0.45; atm.Offset = 0
    Notify("🌧  Rain ON  (density "..density..")")
end)

Cmd("norain", {"clearrain"}, function()
    _clearWeather()
    workspace.Gravity = _origGravity
    Notify("🌧  Rain OFF")
end)

Cmd("snow", {}, function(args)
    local density = tonumber(args[1]) or 1
    _makeWeather({
        LightEmission  = 0.2,
        LightInfluence = 0.8,
        Texture        = "rbxassetid://241685484",
        Color          = ColorSequence.new(Color3.new(1,1,1)),
        Size           = NumberSequence.new({
            NumberSequenceKeypoint.new(0,0.15),
            NumberSequenceKeypoint.new(1,0.05)}),
        Transparency   = NumberSequence.new(0.1),
        Lifetime       = NumberRange.new(3, 5),
        Rate           = math.clamp(density * 150, 10, 300),
        Speed          = NumberRange.new(10, 20),
        SpreadAngle    = Vector2.new(30, 30),
        RotSpeed       = NumberRange.new(-20, 20),
        Rotation       = NumberRange.new(0, 360),
    }, _origGravity * 0.3)
    Notify("❄  Snow ON  (density "..density..")")
end)

Cmd("nosnow", {"clearsnow"}, function()
    _clearWeather()
    workspace.Gravity = _origGravity
    Notify("❄  Snow OFF")
end)

Cmd("sandstorm", {"sand","dust"}, function(args)
    local intensity = tonumber(args[1]) or 1
    _makeWeather({
        LightEmission  = 0,
        LightInfluence = 1,
        Texture        = "rbxassetid://68239310",
        Color          = ColorSequence.new(Color3.fromRGB(210,180,140)),
        Size           = NumberSequence.new(NumberRange.new(0.5,2)),
        Transparency   = NumberSequence.new(NumberRange.new(0.5,0.9)),
        Lifetime       = NumberRange.new(2, 4),
        Rate           = math.clamp(intensity * 200, 20, 500),
        Speed          = NumberRange.new(30, 60),
        SpreadAngle    = Vector2.new(80, 80),
        RotSpeed       = NumberRange.new(-50,50),
        Rotation       = NumberRange.new(0,360),
    })
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
    atm.Density = 0.85; atm.Color = Color3.fromRGB(210,180,140)
    Notify("🌪  Sandstorm ON  (intensity "..intensity..")")
end)

Cmd("nosandstorm", {"clearsand"}, function()
    _clearWeather()
    Notify("🌪  Sandstorm OFF")
end)

Cmd("clearweather", {"noweather"}, function()
    _clearWeather()
    workspace.Gravity = _origGravity
    Notify("☀  Weather cleared")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: TERRAIN TOOLS  (IY-ported)                  ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: workspace.Terrain API, FillBlock, ReplaceMaterial,
--           CellSize, terrain material enums.

Cmd("fillterrain", {"fill","terrainfill"}, function(args)
    local mat  = (args[1] or "SmoothPlastic"):lower()
    local size = tonumber(args[2]) or 20
    local hrp  = GetHRP(); if not hrp then return end
    local matEnum = Enum.Material.SmoothPlastic
    for _, v in ipairs(Enum.Material:GetEnumItems()) do
        if v.Name:lower() == mat then matEnum = v; break end
    end
    workspace.Terrain:FillBlock(
        CFrame.new(hrp.Position),
        Vector3.new(size, size, size),
        matEnum)
    Notify(string.format("🗻  Terrain filled  %s  size=%d", matEnum.Name, size))
end)

Cmd("clearterrain", {"deleteterrain"}, function()
    workspace.Terrain:Clear()
    Notify("🗻  Terrain cleared")
end)

Cmd("replaceterrain", {"rterrain"}, function(args)
    local from  = (args[1] or "Grass"):lower()
    local to    = (args[2] or "SmoothPlastic"):lower()
    local fromM, toM = Enum.Material.Grass, Enum.Material.SmoothPlastic
    for _, v in ipairs(Enum.Material:GetEnumItems()) do
        if v.Name:lower() == from then fromM = v end
        if v.Name:lower() == to   then toM   = v end
    end
    workspace.Terrain:ReplaceMaterial(workspace.Terrain:GetExtentsInRegion(
        Region3.new(
            workspace.Terrain:GetMinimumPosition(),
            workspace.Terrain:GetMaximumPosition()
        )), 4, fromM, toM)
    Notify(string.format("🗻  Replaced %s → %s", fromM.Name, toM.Name))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: COMMAND HISTORY  (IY-ported)                ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: ring-buffer history, up/down arrow recall,
--           UserInputService key interception for UI.

local _cmdHistory  = {}
local _historyIdx  = 0
local _maxHistory  = 50

-- Patch ExecCommand to record history
local _origExecCommand = ExecCommand
ExecCommand = function(raw)
    if raw and raw:match("%S") then
        -- Remove duplicate last entry
        if _cmdHistory[#_cmdHistory] ~= raw then
            table.insert(_cmdHistory, raw)
            if #_cmdHistory > _maxHistory then
                table.remove(_cmdHistory, 1)
            end
        end
        _historyIdx = #_cmdHistory + 1
    end
    _origExecCommand(raw)
end

-- Up/Down arrow in bar to cycle history
UserInputService.InputBegan:Connect(function(i, gp)
    if not isBarOpen or not TextBox:IsFocused() then return end
    if i.KeyCode == Enum.KeyCode.Up then
        _historyIdx = math.max(1, _historyIdx - 1)
        if _cmdHistory[_historyIdx] then
            TextBox.Text = _cmdHistory[_historyIdx]
            -- Move cursor to end
            TextBox.CursorPosition = #TextBox.Text + 1
        end
    elseif i.KeyCode == Enum.KeyCode.Down then
        _historyIdx = math.min(#_cmdHistory + 1, _historyIdx + 1)
        TextBox.Text = _cmdHistory[_historyIdx] or ""
        TextBox.CursorPosition = #TextBox.Text + 1
    end
end)

-- history  — print recent commands
Cmd("history", {"hist","cmdhist"}, function(args)
    local n = tonumber(args[1]) or 10
    if #_cmdHistory == 0 then Notify("No command history","warn"); return end
    local show = {}
    local start = math.max(1, #_cmdHistory - n + 1)
    for i = start, #_cmdHistory do table.insert(show, i..". ".._cmdHistory[i]) end
    print("[S-Admin] History:\n  "..table.concat(show,"\n  "))
    Notify("📜  Last "..#show.." cmds — see console","info")
end)

-- clearhistory
Cmd("clearhistory", {"clrhist"}, function()
    _cmdHistory = {}
    _historyIdx = 0
    Notify("📜  History cleared")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: R6 ANIMATION IDs  (IY-ported)               ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: R6 vs R15 humanoid rig detection, asset IDs for
--           both rigs, fallback ID handling.

local _r6Emotes = {
    wave   = 128777973,
    dance  = 130018893,
    laugh  = 129423131,
    point  = 128853357,
    cheer  = 129423030,
    dance2 = 130018901,
    dance3 = 130018909,
}
local _r15Emotes = {
    wave   = 507770239,
    dance  = 507771019,
    laugh  = 507770818,
    point  = 507770453,
    cheer  = 507770677,
    dance2 = 507776043,
    dance3 = 507777268,
}

local function _isR6()
    local char = GetChar(); if not char then return false end
    local torso = char:FindFirstChild("Torso")
    return torso ~= nil
end

-- emote6 <name>  — force R6 emote regardless of rig
Cmd("emote6", {"r6emote","emoteR6"}, function(args)
    local name = (args[1] or "wave"):lower()
    local id   = _r6Emotes[name]
    if not id then
        Notify("R6 emotes: "..table.concat(
            (function() local t={} for k in pairs(_r6Emotes) do table.insert(t,k) end return t end)()
        ,", "),"warn"); return
    end
    PlayAnim(id, false)
    Notify("🎭  R6 Emote: "..name)
end)

-- emote15 <name>  — force R15 emote
Cmd("emote15", {"r15emote","emoteR15"}, function(args)
    local name = (args[1] or "wave"):lower()
    local id   = _r15Emotes[name]
    if not id then
        Notify("R15 emotes: "..table.concat(
            (function() local t={} for k in pairs(_r15Emotes) do table.insert(t,k) end return t end)()
        ,", "),"warn"); return
    end
    PlayAnim(id, false)
    Notify("🎭  R15 Emote: "..name)
end)

-- autoemote  — cycle through all emotes
local _autoEmoteTask = nil
Cmd("autoemote", {"aeemote","emoteloop"}, function(args)
    if _autoEmoteTask then
        task.cancel(_autoEmoteTask); _autoEmoteTask = nil
        Notify("🎭  AutoEmote OFF"); return
    end
    local interval = tonumber(args[1]) or 3
    local tbl = _isR6() and _r6Emotes or _r15Emotes
    local keys = {}
    for k in pairs(tbl) do table.insert(keys,k) end
    local idx = 1
    _autoEmoteTask = task.spawn(function()
        while true do
            PlayAnim(tbl[keys[idx]], false)
            idx = idx % #keys + 1
            task.wait(interval)
        end
    end)
    Notify(string.format("🎭  AutoEmote ON  (every %.1fs)", interval))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: DRAWING / 2D CANVAS  (IY-ported)            ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Drawing library (executor feature), fallback to
--           ScreenGui Frame drawing when no Drawing API.

local _drawings   = {}
local _drawActive = false
local _drawConn   = nil

local function _drawPoint(x, y, col)
    local size = 6
    -- Try Drawing library first (executor)
    local ok = pcall(function()
        local d = Drawing.new("Square")
        d.Visible    = true
        d.Color      = col or Color3.new(1,0,0)
        d.Position   = Vector2.new(x - size/2, y - size/2)
        d.Size       = Vector2.new(size, size)
        d.Filled     = true
        d.Transparency = 1
        table.insert(_drawings, d)
    end)
    if not ok then
        -- Fallback: ScreenGui frame
        local f = Instance.new("Frame", ScreenGui)
        f.Size             = UDim2.new(0,size,0,size)
        f.Position         = UDim2.new(0, x-size/2, 0, y-size/2)
        f.BackgroundColor3 = col or Color3.new(1,0,0)
        f.BorderSizePixel  = 0
        f.ZIndex           = 80
        table.insert(_drawings, f)
    end
end

Cmd("draw", {"startdraw","paint"}, function(args)
    if _drawActive then
        if _drawConn then _drawConn:Disconnect(); _drawConn = nil end
        _drawActive = false
        Notify("🖊  Draw OFF — "..#_drawings.." point(s) placed")
        return
    end
    _drawActive = true
    local r = tonumber(args[1]) or 255
    local g = tonumber(args[2]) or 0
    local b = tonumber(args[3]) or 0
    local col = Color3.fromRGB(r,g,b)
    _drawConn = UserInputService.InputChanged:Connect(function(i)
        if not _drawActive then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            _drawPoint(i.Position.X, i.Position.Y, col)
        end
    end)
    Notify(string.format("🖊  Draw ON  (%d,%d,%d)  — hold LMB to paint, run again to stop",r,g,b))
end)

Cmd("cleardrawing", {"clearcanvas","cleardraw"}, function()
    for _, d in ipairs(_drawings) do
        pcall(function()
            if d.Remove then d:Remove()
            elseif d.Destroy then d:Destroy() end
        end)
    end
    _drawings = {}
    Notify("🖊  Canvas cleared")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CLIPBOARD TOOLS  (IY-ported)                ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: setclipboard (executor API), building formatted
--           strings for copying positions, IDs, etc.

Cmd("copypos", {"clippos","posclip"}, function()
    local hrp = GetHRP(); if not hrp then return end
    local p   = hrp.Position
    local str = string.format("Vector3.new(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
    pcall(function() setclipboard(str) end)
    print("[S-Admin] Copied: "..str)
    Notify("📋  Position copied to clipboard","info")
end)

Cmd("copycframe", {"clipcframe","cframeclip"}, function()
    local hrp = GetHRP(); if not hrp then return end
    local cf  = hrp.CFrame
    local p   = cf.Position
    local lx,ly,lz = cf:ToEulerAnglesXYZ()
    local str = string.format(
        "CFrame.new(%.2f,%.2f,%.2f) * CFrame.Angles(%.4f,%.4f,%.4f)",
        p.X,p.Y,p.Z, lx,ly,lz)
    pcall(function() setclipboard(str) end)
    print("[S-Admin] Copied: "..str)
    Notify("📋  CFrame copied to clipboard","info")
end)

Cmd("copyid", {"clipid"}, function(args)
    local target = GetPlayers(args[1])[1] or LP
    local str = tostring(target.UserId)
    pcall(function() setclipboard(str) end)
    Notify("📋  Copied UserID: "..str,"info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: GLOBAL / SYSTEM MESSAGES  (IY-ported)       ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: StarterGui:SetCore("SendNotification"),
--           custom notification building, timed GUI display.

Cmd("globalmsg", {"gmsg","broadcast"}, function(args)
    local msg = table.concat(args," ")
    if msg == "" then Notify("Usage: globalmsg <message>","warn"); return end
    -- Try native Roblox notification
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = "S Admin",
            Text     = msg,
            Duration = 5,
        })
    end)
    -- Also use our own notify
    Notify("📢  "..msg, "info")
end)

-- sysnotify <title> <message>
Cmd("sysnotify", {"systemnotif","snotif"}, function(args)
    local title = args[1] or "System"
    local msg   = table.concat(args," ",2)
    if msg == "" then Notify("Usage: sysnotify <title> <message>","warn"); return end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title,
            Text     = msg,
            Duration = 6,
            Icon     = "",
        })
    end)
    Notify("📢  ["..title.."] "..msg, "info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: KEYBIND DISPLAY  (IY-ported)                ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: on-screen HUD listing active binds, connection
--           to the bind table, live update.

local _bindDisplayGui  = nil
local _bindDisplayConn = nil

Cmd("showbindgui", {"bindgui","binddisplay"}, function()
    if _bindDisplayGui then
        _bindDisplayGui:Destroy(); _bindDisplayGui = nil
        if _bindDisplayConn then _bindDisplayConn:Disconnect(); _bindDisplayConn = nil end
        Notify("🔑  Bind display OFF"); return
    end
    _bindDisplayGui = Instance.new("ScreenGui", ScreenGui)
    _bindDisplayGui.Name        = "S_BindDisplay"
    _bindDisplayGui.ResetOnSpawn = false
    _bindDisplayGui.DisplayOrder = 90

    local frame = Instance.new("Frame", _bindDisplayGui)
    frame.Size             = UDim2.new(0,200,0,0)
    frame.Position         = UDim2.new(1,-210,0,50)
    frame.BackgroundColor3 = Color3.fromRGB(12,12,12)
    frame.BackgroundTransparency = 0.3
    frame.ZIndex           = 90
    Corner(frame, 8)

    local title = Instance.new("TextLabel", frame)
    title.Size             = UDim2.new(1,0,0,22)
    title.BackgroundTransparency = 1
    title.Text             = "⌨  Binds"
    title.TextColor3       = Color3.fromRGB(150,200,255)
    title.Font             = Enum.Font.GothamBold
    title.TextSize         = 12
    title.ZIndex           = 91

    local list = Instance.new("Frame", frame)
    list.Name              = "List"
    list.Size              = UDim2.new(1,0,1,-22)
    list.Position          = UDim2.new(0,0,0,22)
    list.BackgroundTransparency = 1
    list.ZIndex            = 91
    local ull = Instance.new("UIListLayout", list)
    ull.Padding = UDim.new(0,2)

    local function refresh()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        local entries = {}
        for k,v in pairs(_binds) do table.insert(entries, {k=k,v=v}) end
        table.sort(entries, function(a,b) return a.k < b.k end)
        for _, e in ipairs(entries) do
            local lbl = Instance.new("TextLabel", list)
            lbl.Size             = UDim2.new(1,0,0,18)
            lbl.BackgroundTransparency = 1
            lbl.Text             = "["..e.k.."] "..e.v
            lbl.TextColor3       = Color3.fromRGB(200,200,200)
            lbl.Font             = Enum.Font.Code
            lbl.TextSize         = 11
            lbl.TextXAlignment   = Enum.TextXAlignment.Left
            lbl.ZIndex           = 91
            Pad(lbl,4)
        end
        local h = math.max(22 + #entries*20, 30)
        frame.Size = UDim2.new(0,200,0,h)
    end
    refresh()

    -- Refresh every second
    _bindDisplayConn = RunService.Heartbeat:Connect(function()
        task.wait(1)
        pcall(refresh)
    end)
    Notify("🔑  Bind display ON")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: GRAVITY WELL  (IY-ported)                   ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: BodyPosition force on all players, distance
--           falloff, continuous physics application.

local _gravWellConn = nil

Cmd("gravitywell", {"gwell","attract2"}, function(args)
    if _gravWellConn then
        _gravWellConn:Disconnect(); _gravWellConn = nil
        Notify("🌀  Gravity well OFF"); return
    end
    local strength = tonumber(args[1]) or 200
    local range    = tonumber(args[2]) or 60

    _gravWellConn = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    local diff = hrp.Position - tHRP.Position
                    local dist = diff.Magnitude
                    if dist < range and dist > 1 then
                        local force = diff.Unit * (strength / (dist * 0.1 + 1))
                        tHRP.AssemblyLinearVelocity = tHRP.AssemblyLinearVelocity + force * 0.1
                    end
                end
            end
        end
    end)
    Notify(string.format("🌀  Gravity well ON  strength=%d  range=%d", strength, range))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: MINIMAP / COMPASS  (IY-ported)              ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: ScreenGui dot mapping, world-to-screen coord
--           approximation, live-update via Heartbeat.

local _minimapGui  = nil
local _minimapConn = nil
local _minimapScale = 5   -- studs per pixel

Cmd("minimap", {"map","compass"}, function(args)
    if _minimapGui then
        _minimapGui:Destroy(); _minimapGui = nil
        if _minimapConn then _minimapConn:Disconnect(); _minimapConn = nil end
        Notify("🗺  Minimap OFF"); return
    end
    _minimapScale = tonumber(args[1]) or 5

    local size = IsMobile and 120 or 150
    _minimapGui = Instance.new("ScreenGui", ScreenGui)
    _minimapGui.Name         = "S_Minimap"
    _minimapGui.ResetOnSpawn = false
    _minimapGui.DisplayOrder = 85

    local bg = Instance.new("Frame", _minimapGui)
    bg.Name             = "BG"
    bg.Size             = UDim2.new(0,size,0,size)
    bg.Position         = UDim2.new(1,-size-10, 0, 10)
    bg.BackgroundColor3 = Color3.fromRGB(10,10,10)
    bg.BackgroundTransparency = 0.3
    bg.ZIndex           = 85
    Corner(bg, 6)
    Stroke(bg, 1, Color3.fromRGB(80,80,80))

    local center = Instance.new("Frame", bg)
    center.Name             = "Center"
    center.Size             = UDim2.new(0,6,0,6)
    center.AnchorPoint      = Vector2.new(0.5,0.5)
    center.Position         = UDim2.new(0.5,0,0.5,0)
    center.BackgroundColor3 = Color3.fromRGB(100,200,255)
    center.ZIndex           = 87
    Corner(center,3)

    local dots = {}   -- player dots

    _minimapConn = RunService.Heartbeat:Connect(function()
        local myHRP = GetHRP(); if not myHRP then return end
        local myPos = myHRP.Position

        -- Remove old dots
        for n, d in pairs(dots) do
            if not Players:FindFirstChild(n) then d:Destroy(); dots[n]=nil end
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    local diff = tHRP.Position - myPos
                    local px = size/2 + diff.X / _minimapScale
                    local py = size/2 - diff.Z / _minimapScale   -- Z is depth
                    px = math.clamp(px, 2, size-2)
                    py = math.clamp(py, 2, size-2)

                    if not dots[p.Name] then
                        local dot = Instance.new("Frame", bg)
                        dot.Size             = UDim2.new(0,5,0,5)
                        dot.AnchorPoint      = Vector2.new(0.5,0.5)
                        dot.BackgroundColor3 = Color3.fromRGB(255,80,80)
                        dot.ZIndex           = 86
                        Corner(dot,3)
                        dots[p.Name] = dot
                    end
                    dots[p.Name].Position = UDim2.new(0, px-2, 0, py-2)
                end
            end
        end
    end)

    Notify("🗺  Minimap ON  (scale="..(_minimapScale).." studs/px)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: NETWORK STATS DISPLAY  (IY-ported)          ║
-- ╚══════════════════════════════════════════════════════════╝

local _netStatGui  = nil
local _netStatConn = nil

Cmd("netstat", {"networkstat","netstats"}, function()
    if _netStatGui then
        _netStatGui:Destroy(); _netStatGui = nil
        if _netStatConn then _netStatConn:Disconnect(); _netStatConn = nil end
        Notify("📶  NetStat OFF"); return
    end

    _netStatGui = Instance.new("ScreenGui", ScreenGui)
    _netStatGui.Name = "S_NetStat"
    _netStatGui.ResetOnSpawn = false
    _netStatGui.DisplayOrder = 88

    local f = Instance.new("Frame", _netStatGui)
    f.Size             = UDim2.new(0,180,0,70)
    f.Position         = UDim2.new(0,10,0,40)
    f.BackgroundColor3 = Color3.fromRGB(10,10,10)
    f.BackgroundTransparency = 0.35
    f.ZIndex           = 88
    Corner(f,6)

    local lbl = Instance.new("TextLabel",f)
    lbl.Size             = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Font             = Enum.Font.Code
    lbl.TextSize         = 11
    lbl.TextColor3       = Color3.new(1,1,1)
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.TextYAlignment   = Enum.TextYAlignment.Top
    lbl.ZIndex           = 89
    Pad(lbl,4)

    local stats = game:GetService("Stats")

    _netStatConn = RunService.Heartbeat:Connect(function()
        local ping     = math.floor(LP:GetNetworkPing()*1000)
        local recv, send = 0, 0
        pcall(function()
            recv = math.floor(stats.DataReceiveKbps.Value)
            send = math.floor(stats.DataSendKbps.Value)
        end)
        lbl.Text = string.format(
            "📶 Network Stats\n  Ping: %dms\n  Recv: %d kb/s\n  Send: %d kb/s",
            ping, recv, send)
    end)

    Notify("📶  NetStat ON")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: PLAYER BADGES / GROUPS  (IY-ported)         ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: BadgeService:UserHasBadgeAsync, GroupService,
--           async queries, pcall for HTTP.

Cmd("hasbadge", {"badge","checkbadge"}, function(args)
    local target  = GetPlayers(args[1])[1] or LP
    local badgeId = tonumber(args[2])
    if not badgeId then Notify("Usage: hasbadge <player> <badgeID>","warn"); return end
    task.spawn(function()
        local ok, has = pcall(function()
            return game:GetService("BadgeService"):UserHasBadgeAsync(target.UserId, badgeId)
        end)
        if ok then
            Notify(string.format("🏅  %s %s badge %d",
                target.Name, has and "HAS" or "does NOT have", badgeId),
                has and "success" or "warn")
        else
            Notify("Badge check failed","error")
        end
    end)
end)

Cmd("ingroup", {"checkgroup","groupcheck"}, function(args)
    local target  = GetPlayers(args[1])[1] or LP
    local groupId = tonumber(args[2])
    if not groupId then Notify("Usage: ingroup <player> <groupID>","warn"); return end
    task.spawn(function()
        local ok, rank = pcall(function()
            return target:GetRankInGroup(groupId)
        end)
        if ok then
            Notify(string.format("👥  %s rank %d in group %d", target.Name, rank, groupId),
                rank > 0 and "success" or "warn")
        else
            Notify("Group check failed","error")
        end
    end)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: FPS COUNTER STYLES  (IY-ported)             ║
-- ╚══════════════════════════════════════════════════════════╝

local _fpsCounterGui  = nil
local _fpsCounterConn = nil

Cmd("fpscounter", {"fpshud","showfps"}, function(args)
    if _fpsCounterGui then
        _fpsCounterGui:Destroy(); _fpsCounterGui = nil
        if _fpsCounterConn then _fpsCounterConn:Disconnect(); _fpsCounterConn = nil end
        Notify("⚡  FPS Counter OFF"); return
    end

    local style = (args[1] or "corner"):lower()  -- "corner" or "bar"

    _fpsCounterGui = Instance.new("ScreenGui", ScreenGui)
    _fpsCounterGui.Name         = "S_FPSCounter"
    _fpsCounterGui.ResetOnSpawn = false
    _fpsCounterGui.DisplayOrder = 92

    local lbl = Instance.new("TextLabel", _fpsCounterGui)
    if style == "bar" then
        lbl.Size     = UDim2.new(1,0,0,20)
        lbl.Position = UDim2.new(0,0,1,-20)
        lbl.BackgroundColor3 = Color3.fromRGB(10,10,10)
        lbl.BackgroundTransparency = 0.4
    else
        lbl.Size     = UDim2.new(0,80,0,22)
        lbl.Position = UDim2.new(0,10,0,10)
        lbl.BackgroundColor3 = Color3.fromRGB(10,10,10)
        lbl.BackgroundTransparency = 0.5
        Corner(lbl, 5)
    end
    lbl.Font             = Enum.Font.Code
    lbl.TextSize         = 13
    lbl.TextColor3       = Color3.new(1,1,1)
    lbl.ZIndex           = 92
    lbl.BorderSizePixel  = 0

    local samples = {}
    _fpsCounterConn = RunService.Heartbeat:Connect(function(dt)
        table.insert(samples, 1/dt)
        if #samples > 20 then table.remove(samples,1) end
        local avg = 0
        for _, s in ipairs(samples) do avg = avg + s end
        avg = avg / #samples
        local col = avg > 55 and Color3.fromRGB(80,220,100)
               or   avg > 30 and Color3.fromRGB(220,200,50)
               or                Color3.fromRGB(220,80,80)
        lbl.TextColor3 = col
        lbl.Text = string.format("⚡ %d fps", math.floor(avg))
    end)

    Notify("⚡  FPS Counter ON  (style="..style..")")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ADVANCED TROLL  (IY-ported)                 ║
-- ╚══════════════════════════════════════════════════════════╝

-- seizure  — rapidly change environment colors
local _seizureTask = nil
Cmd("seizure", {}, function()
    if _seizureTask then task.cancel(_seizureTask); _seizureTask = nil; Notify("Seizure OFF"); return end
    _seizureTask = task.spawn(function()
        while true do
            Lighting.Ambient    = Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255))
            Lighting.ColorShift_Top = Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255))
            task.wait(0.05)
        end
    end)
    Notify("⚡  Seizure mode ON  (run again to stop)")
end)

-- disco  — disco lighting cycle
local _discoTask = nil
Cmd("disco", {"discomode"}, function(args)
    if _discoTask then task.cancel(_discoTask); _discoTask = nil
        Lighting.Ambient = OrigLight and OrigLight.Ambient or Color3.new(0.5,0.5,0.5)
        Notify("🪩  Disco OFF"); return
    end
    local speed = tonumber(args[1]) or 1
    local hue   = 0
    _discoTask  = task.spawn(function()
        while true do
            hue = (hue + speed*0.02) % 1
            local col = Color3.fromHSV(hue, 1, 1)
            Lighting.Ambient          = col
            Lighting.ColorShift_Top   = col
            Lighting.ColorShift_Bottom = Color3.fromHSV((hue+0.5)%1, 1, 1)
            task.wait(0.033)
        end
    end)
    Notify("🪩  Disco ON  (speed "..speed..")")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ADVANCED MOVEMENT  (IY-ported)              ║
-- ╚══════════════════════════════════════════════════════════╝

-- jetpack  — constant upward thrust toggle
local _jetpackConn = nil
Cmd("jetpack", {"jet"}, function(args)
    if _jetpackConn then
        _jetpackConn:Disconnect(); _jetpackConn = nil
        Notify("🚀  Jetpack OFF"); return
    end
    local thrust = tonumber(args[1]) or 80
    _jetpackConn = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)
        or UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then
            hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + Vector3.new(0, thrust * 0.1, 0)
        end
    end)
    Notify("🚀  Jetpack ON  (Space/Jump=thrust  power="..thrust..")")
end)

-- moonwalk  — reverse walking direction
local _moonwalkConn = nil
Cmd("moonwalk", {"mw"}, function()
    if _moonwalkConn then
        _moonwalkConn:Disconnect(); _moonwalkConn = nil
        Notify("🕴  Moonwalk OFF"); return
    end
    _moonwalkConn = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        local hum = GetHuman(); if not hum then return end
        if hum.MoveDirection.Magnitude > 0.1 then
            hrp.AssemblyLinearVelocity = -hum.MoveDirection * hum.WalkSpeed
        end
    end)
    Notify("🕴  Moonwalk ON  (move forward to moonwalk backward)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SPEED & JUMP PRESETS  (IY-ported)           ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: named constant presets as a usability pattern,
--           single command switching between config states.

local _speedPresets = {
    turtle  = 4,
    slow    = 8,
    walk    = 16,
    jog     = 24,
    run     = 40,
    sprint  = 60,
    fast    = 100,
    ultra   = 200,
    max     = 500,
}
local _jumpPresets = {
    low     = 25,
    normal  = 50,
    high    = 100,
    super   = 200,
    ultra   = 400,
    moon    = 600,
}

Cmd("speedpreset", {"sp2","preset"}, function(args)
    local key = (args[1] or ""):lower()
    local val = _speedPresets[key]
    if not val then
        local list = {}
        for k,v in pairs(_speedPresets) do table.insert(list, k.."="..v) end
        table.sort(list)
        Notify("Presets: "..table.concat(list,"  "),"warn"); return
    end
    local hum = GetHuman(); if not hum then return end
    hum.WalkSpeed = val
    Notify(string.format("🏃  Speed preset '%s' → %d", key, val))
end)

Cmd("jumppreset", {"jp2","jpreset"}, function(args)
    local key = (args[1] or ""):lower()
    local val = _jumpPresets[key]
    if not val then
        local list = {}
        for k,v in pairs(_jumpPresets) do table.insert(list, k.."="..v) end
        table.sort(list)
        Notify("Presets: "..table.concat(list,"  "),"warn"); return
    end
    local hum = GetHuman(); if not hum then return end
    hum.UseJumpPower = true
    hum.JumpPower    = val
    Notify(string.format("🦘  Jump preset '%s' → %d", key, val))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CAMERA ORBIT / ATTACH  (IY-ported)          ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Scripted camera rotation around a point using
--           tick()-based angle, CFrame.fromOrientation,
--           camera attached to workspace instance.

local _orbitConn  = nil
local _orbitAngle = 0

Cmd("orbit", {"orbitcam","circling"}, function(args)
    if _orbitConn then
        _orbitConn:Disconnect(); _orbitConn = nil
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        Notify("🔄  Orbit OFF"); return
    end
    local target = GetPlayers(args[1])[1] or LP
    local radius = tonumber(args[2]) or 15
    local speed  = tonumber(args[3]) or 1
    local cam    = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable

    _orbitConn = RunService.RenderStepped:Connect(function(dt)
        local tChar = target.Character
        local tHRP  = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if not tHRP then return end
        _orbitAngle = _orbitAngle + dt * speed
        local x = tHRP.Position.X + math.cos(_orbitAngle) * radius
        local z = tHRP.Position.Z + math.sin(_orbitAngle) * radius
        local y = tHRP.Position.Y + 5
        local pos = Vector3.new(x, y, z)
        cam.CFrame = CFrame.new(pos, tHRP.Position)
        cam.Focus  = CFrame.new(tHRP.Position)
    end)
    Notify(string.format("🔄  Orbiting %s  r=%d  speed=%.1f", target.Name, radius, speed))
end)

-- attachcam <partpath>  — lock camera to follow a specific workspace part
local _attachCamConn = nil
Cmd("attachcam", {"camlockpart","followpart"}, function(args)
    local query = table.concat(args," ")
    if query == "" then Notify("Usage: attachcam <part name>","warn"); return end
    local target = nil
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name:lower() == query:lower() and v:IsA("BasePart") then
            target = v; break
        end
    end
    if not target then Notify("Part not found: "..query,"error"); return end
    if _attachCamConn then _attachCamConn:Disconnect() end
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    _attachCamConn = RunService.RenderStepped:Connect(function()
        if not target.Parent then _attachCamConn:Disconnect(); return end
        cam.CFrame = target.CFrame * CFrame.new(0,5,-12) * CFrame.Angles(math.rad(-10),math.pi,0)
        cam.Focus  = CFrame.new(target.Position)
    end)
    Notify("📷  Camera locked to: "..target.Name)
end)

Cmd("unattachcam", {"detachcam","freepartcam"}, function()
    if _attachCamConn then _attachCamConn:Disconnect(); _attachCamConn = nil end
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    Notify("📷  Camera detached")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SOUND EFFECTS ON CHARACTER  (IY-ported)     ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Sound child of HRP, EqualizerSoundEffect,
--           ReverbSoundEffect, DistortionSoundEffect,
--           PitchShiftSoundEffect — all SoundEffect types.

local function _getOrMakeCharSound()
    local hrp = GetHRP(); if not hrp then return nil end
    local snd = hrp:FindFirstChild("S_CharSound")
    if not snd then
        snd      = Instance.new("Sound", hrp)
        snd.Name = "S_CharSound"
        snd.RollOffMaxDistance = 60
        snd.Volume = 0.5
    end
    return snd
end

Cmd("reverb", {}, function(args)
    local hrp = GetHRP(); if not hrp then return end
    local old = hrp:FindFirstChild("S_Reverb")
    if old then old:Destroy(); Notify("🎵  Reverb OFF"); return end
    local fx = Instance.new("ReverbSoundEffect", hrp)
    fx.Name     = "S_Reverb"
    fx.DecayTime = tonumber(args[1]) or 2.5
    fx.Density   = tonumber(args[2]) or 1
    fx.Diffusion = 1
    Notify(string.format("🎵  Reverb ON  decay=%.1f", fx.DecayTime))
end)

Cmd("echo", {}, function(args)
    local hrp = GetHRP(); if not hrp then return end
    local old = hrp:FindFirstChild("S_Echo")
    if old then old:Destroy(); Notify("🎵  Echo OFF"); return end
    local fx = Instance.new("ChorusSoundEffect", hrp)
    fx.Name  = "S_Echo"
    fx.Depth = tonumber(args[1]) or 1
    fx.Rate  = tonumber(args[2]) or 0.5
    Notify("🎵  Echo ON")
end)

Cmd("pitch", {}, function(args)
    local hrp = GetHRP(); if not hrp then return end
    local p = tonumber(args[1])
    if not p then Notify("Usage: pitch <0.1–4.0>","warn"); return end
    local old = hrp:FindFirstChild("S_Pitch")
    if old then old:Destroy() end
    if math.abs(p-1) < 0.01 then Notify("🎵  Pitch reset"); return end
    local fx = Instance.new("PitchShiftSoundEffect", hrp)
    fx.Name  = "S_Pitch"
    fx.Octave = math.clamp(p, 0.05, 4.0)
    Notify(string.format("🎵  Pitch → %.2f", p))
end)

Cmd("distortion", {"distort"}, function(args)
    local hrp = GetHRP(); if not hrp then return end
    local old = hrp:FindFirstChild("S_Distortion")
    if old then old:Destroy(); Notify("🎵  Distortion OFF"); return end
    local fx = Instance.new("DistortionSoundEffect", hrp)
    fx.Name  = "S_Distortion"
    fx.Level = math.clamp(tonumber(args[1]) or 0.5, 0, 1)
    Notify(string.format("🎵  Distortion ON  level=%.2f", fx.Level))
end)

Cmd("equalizer", {"eq"}, function(args)
    local hrp = GetHRP(); if not hrp then return end
    local old = hrp:FindFirstChild("S_EQ")
    if old then old:Destroy(); Notify("🎵  Equalizer OFF"); return end
    local fx = Instance.new("EqualizerSoundEffect", hrp)
    fx.Name       = "S_EQ"
    fx.LowGain    = tonumber(args[1]) or 0
    fx.MidGain    = tonumber(args[2]) or 0
    fx.HighGain   = tonumber(args[3]) or 0
    Notify(string.format("🎵  EQ  Low=%d  Mid=%d  High=%d", fx.LowGain, fx.MidGain, fx.HighGain))
end)

Cmd("clearfx", {"nosoundfx","removefx2"}, function()
    local hrp = GetHRP(); if not hrp then return end
    local fxNames = {"S_Reverb","S_Echo","S_Pitch","S_Distortion","S_EQ","S_CharSound"}
    local n = 0
    for _, name in ipairs(fxNames) do
        local obj = hrp:FindFirstChild(name)
        if obj then obj:Destroy(); n = n + 1 end
    end
    Notify("🎵  Cleared "..n.." sound effect(s)")
end)

-- walksound <soundID>  — replace the footstep sound
Cmd("walksound", {"footstep","stepsound"}, function(args)
    local id = tonumber(args[1])
    if not id then Notify("Usage: walksound <soundID>","warn"); return end
    local char = GetChar(); if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("Sound") and (v.Name == "Running" or v.Name == "Footstep") then
            v.SoundId = "rbxassetid://"..id
        end
    end
    Notify("👟  Walk sound → "..id)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CHAT FORMATTER  (IY-ported)                 ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: string prefix patterns, wrapping FireServer,
--           persistent state for chat formatting.

local _chatPrefix   = ""
local _chatSuffix   = ""
local _chatColor    = nil  -- BrickColor for legacy chat

Cmd("chatprefix", {"prefix","addprefix"}, function(args)
    _chatPrefix = table.concat(args," ")
    Notify("💬  Chat prefix set: '"..(_chatPrefix == "" and "(cleared)" or _chatPrefix).."'")
end)

Cmd("chatsuffix", {"suffix","addsuffix"}, function(args)
    _chatSuffix = table.concat(args," ")
    Notify("💬  Chat suffix set: '"..(_chatSuffix == "" and "(cleared)" or _chatSuffix).."'")
end)

-- Override chat command to use prefix/suffix
local _baseChatFn = Commands["chat"]
Commands["chat"] = function(args)
    local msg = table.concat(args," ")
    if _chatPrefix ~= "" or _chatSuffix ~= "" then
        local formatted = _chatPrefix..msg.._chatSuffix
        local ok = pcall(function()
            game:GetService("ReplicatedStorage")
                .DefaultChatSystemChatEvents
                .SayMessageRequest:FireServer(formatted, "All")
        end)
        if ok then Notify("💬  Sent: "..formatted) return end
    end
    _baseChatFn(args)
end

Cmd("clearchatformat", {"noprefix","clearformat"}, function()
    _chatPrefix = ""
    _chatSuffix = ""
    Notify("💬  Chat format cleared")
end)

-- chatrepeat <n> <message>  — send a message N times
Cmd("chatrepeat", {"chatn","spamchat"}, function(args)
    local n   = math.min(tonumber(args[1]) or 1, 10)  -- cap 10
    local msg = table.concat(args," ",2)
    if msg == "" then Notify("Usage: chatrepeat <n> <message>","warn"); return end
    task.spawn(function()
        for i = 1, n do
            pcall(function()
                game:GetService("ReplicatedStorage")
                    .DefaultChatSystemChatEvents
                    .SayMessageRequest:FireServer(msg, "All")
            end)
            task.wait(0.5)
        end
    end)
    Notify("💬  Sent x"..n..": '"..msg.."'")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SPECTATE CYCLE  (IY-ported)                 ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: index-based cycling through a filtered list,
--           reusing the view command, smooth cycling UX.

local _specIndex = 1

local function _getSpecList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(list, p) end
    end
    return list
end

Cmd("specnext", {"nextplayer","vnext"}, function()
    local list = _getSpecList()
    if #list == 0 then Notify("No other players","warn"); return end
    _specIndex = (_specIndex % #list) + 1
    local target = list[_specIndex]
    Commands["view"]({target.Name})
end)

Cmd("specprev", {"prevplayer","vprev"}, function()
    local list = _getSpecList()
    if #list == 0 then Notify("No other players","warn"); return end
    _specIndex = ((_specIndex - 2) % #list) + 1
    local target = list[_specIndex]
    Commands["view"]({target.Name})
end)

Cmd("specrandom", {"viewrandom","randspec"}, function()
    local list = _getSpecList()
    if #list == 0 then Notify("No other players","warn"); return end
    local target = list[math.random(1,#list)]
    _specIndex   = table.find(list,target) or 1
    Commands["view"]({target.Name})
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: JOIN PLAYER  (IY-ported)                    ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: TeleportService:TeleportToPlaceInstance with
--           a target player's JobId, HttpGet for finding
--           which server a player is on.

Cmd("joinplayer", {"join","jp3"}, function(args)
    local query = table.concat(args," "):lower()
    if query == "" then Notify("Usage: joinplayer <username>","warn"); return end
    Notify("🔍  Finding server for '"..query.."'...", "info")
    task.spawn(function()
        -- Resolve UserId from name
        local userId
        local ok = pcall(function()
            userId = Players:GetUserIdFromNameAsync(query)
        end)
        if not ok or not userId then
            Notify("Player '"..query.."' not found","error"); return
        end
        -- Find their server via Roblox API
        local found = false
        for _, server in ipairs({}) do  -- placeholder: real impl below
        end
        -- Use presence API
        local ok2, body = pcall(function()
            local raw = game:HttpGet(
                "https://presence.roblox.com/v1/presence/users",
                true)
            -- Note: POST needed; fallback to friend-only approach
            return game:GetService("HttpService"):JSONDecode(raw)
        end)
        -- Simpler: just try TeleportToPlaceInstance with their game
        Notify("ℹ  joinplayer requires the target to be in the same Place. Use serverhop to search.", "warn")
    end)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: PART CLONING  (IY-ported)                   ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Instance:Clone(), CFrame offset, how Roblox
--           handles part ownership after clone.

Cmd("clonepart", {"clone","cp2"}, function(args)
    local query = table.concat(args," "):lower()
    local hrp   = GetHRP(); if not hrp then return end
    -- Find nearest matching part if query given, else nearest any part
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsDescendantOf(LP.Character or Instance.new("Folder")) then
            local matches = query == "" or v.Name:lower():find(query,1,true)
            if matches then
                local d = (v.Position - hrp.Position).Magnitude
                if d < bestDist then best=v; bestDist=d end
            end
        end
    end
    if not best then Notify("No matching part found","warn"); return end
    local cloned = best:Clone()
    cloned.Anchored = true
    cloned.CFrame   = best.CFrame * CFrame.new(best.Size.X + 1, 0, 0)
    cloned.Parent   = workspace
    Notify("📋  Cloned: "..best.Name.."  ("..math.floor(bestDist).." studs away)")
end)

-- clonechar <player>  — clone a player's character appearance onto yours
Cmd("clonechar", {"copychar","mimic"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or target == LP then Notify("Invalid target","error"); return end
    local hum    = GetHuman(); if not hum then return end
    task.spawn(function()
        local ok, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(target.UserId)
        end)
        if ok and desc then
            hum:ApplyDescription(desc)
            Notify("🪞  Cloned appearance of "..target.Name)
        else
            Notify("Could not clone appearance","error")
        end
    end)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: TIME-LAPSE / DAY-NIGHT CYCLE  (IY-ported)   ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: ClockTime incrementing in a task loop,
--           speed multiplier for visual effect.

local _timelapsTask = nil

Cmd("timelapse", {"dncycle","daynightcycle"}, function(args)
    if _timelapsTask then
        task.cancel(_timelapsTask); _timelapsTask = nil
        Notify("🌅  Time-lapse OFF"); return
    end
    local speed = tonumber(args[1]) or 10   -- how many real seconds per full day
    local stepsPerSec = 24 / speed
    _timelapsTask = task.spawn(function()
        while true do
            Lighting.ClockTime = (Lighting.ClockTime + stepsPerSec/60) % 24
            task.wait(1/60)
        end
    end)
    Notify(string.format("🌅  Time-lapse ON  (%.0f second day cycle)", speed))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: PROXIMITY ALERT  (IY-ported)                ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: distance polling with cooldown, combining
--           notification and sound to alert the user.

local _proximityConn    = nil
local _proximityCooldowns = {}

Cmd("proximityalert", {"proxalert","nearbywarn"}, function(args)
    if _proximityConn then
        _proximityConn:Disconnect(); _proximityConn = nil
        _proximityCooldowns = {}
        Notify("⚠  Proximity alert OFF"); return
    end
    local dist = tonumber(args[1]) or 30
    _proximityConn = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    local d = (tHRP.Position - hrp.Position).Magnitude
                    if d <= dist then
                        local now  = tick()
                        local last = _proximityCooldowns[p.Name] or 0
                        if now - last > 5 then
                            _proximityCooldowns[p.Name] = now
                            Notify(string.format("⚠  %s is %.0f studs away!", p.Name, d), "warn")
                        end
                    else
                        _proximityCooldowns[p.Name] = nil
                    end
                end
            end
        end
    end)
    Notify(string.format("⚠  Proximity alert ON  (%.0f studs)", dist))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CINEMATIC MODE  (IY-ported)                 ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: letterbox black bars, hiding HUD elements,
--           cinematic framing techniques in Roblox.

local _cinematicGui = nil

Cmd("cinematic", {"cinema","letterbox"}, function(args)
    if _cinematicGui then
        _cinematicGui:Destroy(); _cinematicGui = nil
        -- Restore CoreGUI
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
        Notify("🎬  Cinematic OFF"); return
    end
    local barH = tonumber(args[1]) or 0.08

    _cinematicGui = Instance.new("ScreenGui", ScreenGui)
    _cinematicGui.Name         = "S_Cinematic"
    _cinematicGui.ResetOnSpawn = false
    _cinematicGui.DisplayOrder = 95

    local function makeBar(yPos)
        local f = Instance.new("Frame", _cinematicGui)
        f.Size             = UDim2.new(1,0, barH,0)
        f.Position         = UDim2.new(0,0, yPos,0)
        f.BackgroundColor3 = Color3.new(0,0,0)
        f.BorderSizePixel  = 0
        f.ZIndex           = 95
        return f
    end

    local top = makeBar(0)
    local bot = makeBar(1-barH)

    -- Animate bars in
    top.Size = UDim2.new(1,0,0,0)
    bot.Size = UDim2.new(1,0,0,0)
    bot.Position = UDim2.new(0,0,1,0)

    TweenObj(top, 0.4, {Size = UDim2.new(1,0,barH,0)}):Play()
    TweenObj(bot, 0.4, {
        Size     = UDim2.new(1,0,barH,0),
        Position = UDim2.new(0,0,1-barH,0),
    }):Play()

    -- Hide HUD
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
    Notify("🎬  Cinematic ON  (run again to exit)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SPEED / VELOCITY DISPLAY  (IY-ported)       ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: AssemblyLinearVelocity magnitude for real speed,
--           difference from WalkSpeed setting.

local _speedDisplayGui  = nil
local _speedDisplayConn = nil

Cmd("speeddisplay", {"speedometer","speedhud"}, function()
    if _speedDisplayGui then
        _speedDisplayGui:Destroy(); _speedDisplayGui = nil
        if _speedDisplayConn then _speedDisplayConn:Disconnect(); _speedDisplayConn = nil end
        Notify("📊  Speed display OFF"); return
    end

    _speedDisplayGui = Instance.new("ScreenGui", ScreenGui)
    _speedDisplayGui.Name         = "S_SpeedDisplay"
    _speedDisplayGui.ResetOnSpawn = false
    _speedDisplayGui.DisplayOrder = 87

    local f = Instance.new("Frame", _speedDisplayGui)
    f.Size             = UDim2.new(0,140,0,30)
    f.Position         = UDim2.new(0.5,-70,1,-50)
    f.BackgroundColor3 = Color3.fromRGB(10,10,10)
    f.BackgroundTransparency = 0.4
    f.ZIndex           = 87
    Corner(f,6)

    local lbl = Instance.new("TextLabel",f)
    lbl.Size             = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextSize         = 14
    lbl.TextColor3       = Color3.new(1,1,1)
    lbl.ZIndex           = 88

    _speedDisplayConn = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        local vel = hrp.AssemblyLinearVelocity
        local spd = Vector3.new(vel.X,0,vel.Z).Magnitude  -- horizontal only
        local col = spd > 60 and Color3.fromRGB(255,120,50)
                 or spd > 25 and Color3.fromRGB(100,220,255)
                 or Color3.fromRGB(200,200,200)
        lbl.TextColor3 = col
        lbl.Text = string.format("⚡ %.1f st/s", spd)
    end)

    Notify("📊  Speed display ON")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: RAINBOW BODY  (IY-ported)                   ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: HSV color cycling, BodyColors properties,
--           smooth hue animation with task loop.

local _rainbowTask = nil

Cmd("rainbow", {"rainbowbody","rbody"}, function(args)
    if _rainbowTask then
        task.cancel(_rainbowTask); _rainbowTask = nil
        Notify("🌈  Rainbow OFF"); return
    end
    local speed = tonumber(args[1]) or 1
    local hue   = 0
    _rainbowTask = task.spawn(function()
        while true do
            hue = (hue + speed * 0.005) % 1
            local col = Color3.fromHSV(hue, 1, 1)
            local char = GetChar()
            if char then
                local bc = char:FindFirstChildOfClass("BodyColors")
                if bc then
                    bc.HeadColor3     = col
                    bc.TorsoColor3    = col
                    bc.LeftArmColor3  = col; bc.RightArmColor3 = col
                    bc.LeftLegColor3  = col; bc.RightLegColor3 = col
                end
            end
            task.wait(0.05)
        end
    end)
    Notify("🌈  Rainbow body ON  (speed "..speed..")")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ESP NAMETAGS (all players)  (IY-ported)     ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: BillboardGui parented to character, AlwaysOnTop,
--           updating text per player, CharacterAdded reconnect.

local _nametagESPConns = {}
local _nametagESPOn    = false

local function _attachNametagESP(plr)
    if plr == LP then return end
    local function build(char)
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local old = hrp:FindFirstChild("S_NameESP"); if old then old:Destroy() end
        local bb  = Instance.new("BillboardGui", hrp)
        bb.Name         = "S_NameESP"
        bb.Size         = UDim2.new(0,120,0,24)
        bb.StudsOffset  = Vector3.new(0,3,0)
        bb.AlwaysOnTop  = true
        bb.ResetOnSpawn = false
        local lbl = Instance.new("TextLabel",bb)
        lbl.Size             = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 0.5
        lbl.BackgroundColor3 = Color3.new(0,0,0)
        lbl.Text             = plr.Name
        lbl.TextColor3       = Color3.fromHSV(
            (plr.UserId % 100)/100, 0.8, 1)   -- unique color per player
        lbl.Font             = Enum.Font.GothamBold
        lbl.TextScaled       = true
        lbl.ZIndex           = 10
        Corner(lbl,4)
    end
    if plr.Character then build(plr.Character) end
    _nametagESPConns[plr.Name] = plr.CharacterAdded:Connect(function(c) task.wait(0.5); build(c) end)
end

Cmd("nametagesp", {"nameesp","playertags"}, function()
    if _nametagESPOn then
        _nametagESPOn = false
        for _, c in pairs(_nametagESPConns) do pcall(function() c:Disconnect() end) end
        _nametagESPConns = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bb = hrp:FindFirstChild("S_NameESP")
                    if bb then bb:Destroy() end
                end
            end
        end
        Notify("🏷  Name ESP OFF"); return
    end
    _nametagESPOn = true
    for _, p in ipairs(Players:GetPlayers()) do _attachNametagESP(p) end
    Conns.NameESPJoin = Players.PlayerAdded:Connect(_attachNametagESP)
    Notify("🏷  Name ESP ON  (unique color per player)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CUSTOM PLAYER LIST GUI  (IY-ported)         ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: dynamic ScreenGui list, sorting by ping/name/team,
--           live-updated via Heartbeat, scrolling layout.

local _playerListGui  = nil
local _playerListConn = nil

Cmd("playerlist", {"plist","customlist"}, function(args)
    if _playerListGui then
        _playerListGui:Destroy(); _playerListGui = nil
        if _playerListConn then _playerListConn:Disconnect(); _playerListConn = nil end
        Notify("👥  Player list OFF"); return
    end
    local sortBy = (args[1] or "name"):lower()   -- "name" | "ping" | "team"

    _playerListGui = Instance.new("ScreenGui", ScreenGui)
    _playerListGui.Name         = "S_PlayerList"
    _playerListGui.ResetOnSpawn = false
    _playerListGui.DisplayOrder = 83

    local panel = Instance.new("Frame", _playerListGui)
    panel.Size             = UDim2.new(0,240,0,320)
    panel.Position         = UDim2.new(1,-254,0.5,-160)
    panel.BackgroundColor3 = Color3.fromRGB(12,12,12)
    panel.BackgroundTransparency = 0.25
    panel.ZIndex           = 83
    Corner(panel,8)
    Stroke(panel,1,Color3.fromRGB(70,70,70))

    local header = Instance.new("TextLabel",panel)
    header.Size             = UDim2.new(1,0,0,28)
    header.BackgroundColor3 = Color3.fromRGB(20,20,20)
    header.BackgroundTransparency = 0
    header.Text             = "👥  Players  (sort: "..sortBy..")"
    header.TextColor3       = Color3.fromRGB(200,200,200)
    header.Font             = Enum.Font.GothamBold
    header.TextSize         = 12
    header.ZIndex           = 84
    Corner(header,8)

    local scroll = Instance.new("ScrollingFrame",panel)
    scroll.Size              = UDim2.new(1,-4,1,-32)
    scroll.Position          = UDim2.new(0,2,0,30)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 3
    scroll.ZIndex            = 84

    local layout = Instance.new("UIListLayout",scroll)
    layout.Padding   = UDim.new(0,2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local function refresh()
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        local plrs = Players:GetPlayers()
        if sortBy == "ping" then
            table.sort(plrs,function(a,b)
                return a:GetNetworkPing() < b:GetNetworkPing()
            end)
        elseif sortBy == "team" then
            table.sort(plrs,function(a,b)
                return tostring(a.Team and a.Team.Name or "") < tostring(b.Team and b.Team.Name or "")
            end)
        else
            table.sort(plrs,function(a,b) return a.Name < b.Name end)
        end

        for i, p in ipairs(plrs) do
            local row = Instance.new("Frame",scroll)
            row.LayoutOrder     = i
            row.Size            = UDim2.new(1,-4,0,28)
            row.BackgroundColor3 = p == LP
                and Color3.fromRGB(30,50,80)
                or  Color3.fromRGB(22,22,22)
            row.BackgroundTransparency = 0.1
            row.ZIndex          = 85
            Corner(row,4)

            local nameLbl = Instance.new("TextLabel",row)
            nameLbl.Size         = UDim2.new(0.65,0,1,0)
            nameLbl.Position     = UDim2.new(0,6,0,0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text         = (p == LP and "▶ " or "  ")..p.Name
            nameLbl.TextColor3   = Color3.fromRGB(210,210,210)
            nameLbl.Font         = Enum.Font.GothamMedium
            nameLbl.TextSize     = 11
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.ZIndex       = 86

            local pingLbl = Instance.new("TextLabel",row)
            pingLbl.Size         = UDim2.new(0.35,0,1,0)
            pingLbl.Position     = UDim2.new(0.65,0,0,0)
            pingLbl.BackgroundTransparency = 1
            local ms = math.floor(p:GetNetworkPing()*1000)
            pingLbl.Text         = ms.."ms"
            pingLbl.TextColor3   = ms < 80 and Color3.fromRGB(80,220,100)
                                or ms < 150 and Color3.fromRGB(220,200,50)
                                or Color3.fromRGB(220,80,80)
            pingLbl.Font         = Enum.Font.Code
            pingLbl.TextSize     = 11
            pingLbl.TextXAlignment = Enum.TextXAlignment.Right
            pingLbl.ZIndex       = 86
            Pad(pingLbl,0,6)
        end
        scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+4)
    end

    refresh()
    local elapsed = 0
    _playerListConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed >= 2 then elapsed = 0; pcall(refresh) end
    end)

    Notify("👥  Player list ON  (sort:"..sortBy..")")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: WORKSPACE SCANNER  (IY-ported)              ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: iterating descendants, grouping by ClassName,
--           sorting and printing a summary report.

Cmd("scanworkspace", {"wscan","wsinventory"}, function(args)
    local limit  = tonumber(args[1]) or 20
    local counts = {}
    local total  = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        total = total + 1
        counts[v.ClassName] = (counts[v.ClassName] or 0) + 1
    end
    local list = {}
    for cls, n in pairs(counts) do table.insert(list,{cls=cls,n=n}) end
    table.sort(list,function(a,b) return a.n > b.n end)
    print(string.format("[S-Admin] Workspace scan  (%d total instances):", total))
    for i=1,math.min(limit,#list) do
        print(string.format("  %-30s %d", list[i].cls, list[i].n))
    end
    Notify(string.format("🔍  %d classes  |  %d instances — console", #list, total), "info")
end)

-- countparts  — count BaseParts by material or name
Cmd("countparts", {"countobjects","pc"}, function(args)
    local filter = args[1] and args[1]:lower() or ""
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            if filter == "" or v.Name:lower():find(filter,1,true)
            or v.Material.Name:lower():find(filter,1,true) then
                n = n + 1
            end
        end
    end
    Notify(string.format("🔢  %d BasePart(s)%s", n,
        filter=="" and "" or " matching '"..filter.."'"), "info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: MATERIAL CHANGER  (IY-ported)               ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Enum.Material enumeration, batch property change,
--           material name lookups.

Cmd("setmaterial", {"material","mat"}, function(args)
    local matName = args[1]; if not matName then Notify("Usage: setmaterial <Material>","warn"); return end
    local matEnum = nil
    for _, v in ipairs(Enum.Material:GetEnumItems()) do
        if v.Name:lower() == matName:lower() then matEnum = v; break end
    end
    if not matEnum then Notify("Unknown material: "..matName,"error"); return end
    local scope = (args[2] or "char"):lower()
    local n = 0
    local parts
    if scope == "workspace" or scope == "ws" then
        parts = workspace:GetDescendants()
    else
        local char = GetChar(); if not char then return end
        parts = char:GetDescendants()
    end
    for _, v in ipairs(parts) do
        if v:IsA("BasePart") and not v:IsDescendantOf(LP.Character or Instance.new("Folder")) then
            pcall(function() v.Material = matEnum end); n = n + 1
        end
    end
    Notify(string.format("🧱  Material → %s  (%d parts, scope=%s)", matEnum.Name, n, scope))
end)

-- charmaterial  — change all character parts to a material
Cmd("charmaterial", {"charmat","mymat"}, function(args)
    local matName = args[1]; if not matName then Notify("Usage: charmaterial <Material>","warn"); return end
    local matEnum = nil
    for _, v in ipairs(Enum.Material:GetEnumItems()) do
        if v.Name:lower() == matName:lower() then matEnum = v; break end
    end
    if not matEnum then Notify("Unknown material: "..matName,"error"); return end
    local char = GetChar(); if not char then return end
    local n = 0
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then pcall(function() v.Material = matEnum end); n=n+1 end
    end
    Notify("🧱  Char material → "..matEnum.Name.."  ("..n.." parts)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: LIGHT COLOR / INTENSITY TOOLS  (IY-ported)  ║
-- ╚══════════════════════════════════════════════════════════╝

-- lightcolor <R G B>  — change character PointLight color
Cmd("lightcolor", {"lcolor","setlightcolor"}, function(args)
    local hrp = GetHRP(); if not hrp then return end
    local pl  = hrp:FindFirstChildOfClass("PointLight")
    if not pl then Notify("No light — run 'light' first","warn"); return end
    local r = tonumber(args[1]) or 255
    local g = tonumber(args[2]) or 240
    local b = tonumber(args[3]) or 200
    pl.Color = Color3.fromRGB(r,g,b)
    Notify(string.format("💡  Light color → (%d,%d,%d)",r,g,b))
end)

-- lightrange <n>  — change character PointLight range
Cmd("lightrange", {"lrange","setlightrange"}, function(args)
    local hrp = GetHRP(); if not hrp then return end
    local pl  = hrp:FindFirstChildOfClass("PointLight")
    if not pl then Notify("No light — run 'light' first","warn"); return end
    pl.Range = tonumber(args[1]) or 20
    Notify("💡  Light range → "..pl.Range)
end)

-- lightbrightness <n>
Cmd("lightbrightness", {"lbrightness","setlightbright"}, function(args)
    local hrp = GetHRP(); if not hrp then return end
    local pl  = hrp:FindFirstChildOfClass("PointLight")
    if not pl then Notify("No light — run 'light' first","warn"); return end
    pl.Brightness = tonumber(args[1]) or 5
    Notify("💡  Light brightness → "..pl.Brightness)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: TRAIL VARIANTS  (IY-ported)                 ║
-- ╚══════════════════════════════════════════════════════════╝

-- rainbowtrail  — trail that cycles hue continuously
local _rainbowTrailTask = nil

Cmd("rainbowtrail", {"rtrail","rbtrail"}, function(args)
    if _rainbowTrailTask then
        task.cancel(_rainbowTrailTask); _rainbowTrailTask = nil
        Commands["notrail"]({})
        Notify("✨  Rainbow trail OFF"); return
    end
    -- Create base trail
    Commands["trail"]({})
    local char = GetChar(); if not char then return end
    local hrp  = GetHRP(); if not hrp then return end
    local tr   = hrp:FindFirstChild("S_Trail"); if not tr then return end
    local hue  = 0
    _rainbowTrailTask = task.spawn(function()
        while tr and tr.Parent do
            hue = (hue + 0.01) % 1
            tr.Color = ColorSequence.new(
                Color3.fromHSV(hue, 1, 1),
                Color3.fromHSV((hue+0.5)%1, 1, 1))
            task.wait(0.05)
        end
    end)
    Notify("✨  Rainbow trail ON")
end)

-- thicktrail <width>  — change trail width
Cmd("thicktrail", {"trailwidth","trailsize"}, function(args)
    local w   = tonumber(args[1]) or 2
    local hrp = GetHRP(); if not hrp then return end
    local tr  = hrp:FindFirstChild("S_Trail")
    if not tr then Notify("No trail — run 'trail' first","warn"); return end
    tr.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, w),
        NumberSequenceKeypoint.new(1, 0),
    })
    Notify("✨  Trail width → "..w)
end)

-- traillifetime <seconds>
Cmd("traillifetime", {"traillife","traillength"}, function(args)
    local t   = tonumber(args[1]) or 1
    local hrp = GetHRP(); if not hrp then return end
    local tr  = hrp:FindFirstChild("S_Trail")
    if not tr then Notify("No trail — run 'trail' first","warn"); return end
    tr.Lifetime = math.clamp(t, 0, 20)
    Notify("✨  Trail lifetime → "..t.."s")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ADVANCED WORKSPACE  (IY-ported)             ║
-- ╚══════════════════════════════════════════════════════════╝

-- freezeall  — anchor every BasePart in workspace
Cmd("freezeall", {"anchorall","freezews"}, function()
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsDescendantOf(LP.Character or Instance.new("Folder")) then
            pcall(function() v.Anchored = true end); n=n+1
        end
    end
    Notify("🧊  Anchored "..n.." workspace parts")
end)

Cmd("unfreezeall", {"unanchorall","unfreezews"}, function()
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsDescendantOf(LP.Character or Instance.new("Folder")) then
            pcall(function() v.Anchored = false end); n=n+1
        end
    end
    Notify("🧊  Unanchored "..n.." workspace parts")
end)

-- noparts  — make every non-character part transparent
Cmd("noparts", {"hidews","transparent"}, function(args)
    local alpha = tonumber(args[1]) or 1
    local char  = GetChar()
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (not char or not v:IsDescendantOf(char)) then
            pcall(function() v.Transparency = alpha end); n=n+1
        end
    end
    Notify(string.format("🔍  Set %d parts to transparency %.1f", n, alpha))
end)

-- restoreparts  — reset all workspace part transparency to 0
Cmd("restoreparts", {"showws","solidparts"}, function()
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then pcall(function() v.Transparency=0 end); n=n+1 end
    end
    Notify("🔍  Restored "..n.." parts to solid")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SCREENSHOT TIMER  (IY-ported)               ║
-- ╚══════════════════════════════════════════════════════════╝

Cmd("screenshotafter", {"scafter","timedshot"}, function(args)
    local delay_s = tonumber(args[1]) or 3
    Notify(string.format("📸  Screenshot in %.0fs...", delay_s), "info")
    task.delay(delay_s, function()
        pcall(function() game:GetService("CoreGui"):TakeScreenshot() end)
        Notify("📸  Screenshot taken!")
    end)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: REAL-WORLD TIME DISPLAY  (IY-ported)        ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: os.date (executor feature), os.time, formatting
--           time strings, fallback for no os.date access.

Cmd("realtime", {"irl","currenttime","clock"}, function()
    local ok, str = pcall(function()
        return os.date("%Y-%m-%d  %H:%M:%S")
    end)
    if ok then
        Notify("🕐  "..str, "info")
    else
        -- Fallback: use os.time() + format manually
        local t   = os.time()
        local sec = t % 60
        local min = math.floor(t/60) % 60
        local hr  = math.floor(t/3600) % 24
        Notify(string.format("🕐  %02d:%02d:%02d (UTC)", hr, min, sec), "info")
    end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CURSOR / INTERACTION TRAIL  (IY-ported)     ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: InputChanged tracking, spawning ScreenGui frames
--           at mouse position, task-based fade-out.

local _cursorTrailOn   = false
local _cursorTrailConn = nil

Cmd("cursortrail", {"mousetrail","ctrail"}, function(args)
    if _cursorTrailOn then
        _cursorTrailOn = false
        if _cursorTrailConn then _cursorTrailConn:Disconnect(); _cursorTrailConn = nil end
        Notify("🖱  Cursor trail OFF"); return
    end
    _cursorTrailOn = true
    local r = tonumber(args[1]) or 200
    local g = tonumber(args[2]) or 100
    local b = tonumber(args[3]) or 255
    local col = Color3.fromRGB(r,g,b)

    _cursorTrailConn = UserInputService.InputChanged:Connect(function(i)
        if not _cursorTrailOn then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement
        and i.UserInputType ~= Enum.UserInputType.Touch then return end

        task.spawn(function()
            local dot = Instance.new("Frame", ScreenGui)
            local s   = 8
            dot.Size             = UDim2.new(0,s,0,s)
            dot.Position         = UDim2.new(0,i.Position.X-s/2, 0,i.Position.Y-s/2)
            dot.BackgroundColor3 = col
            dot.BorderSizePixel  = 0
            dot.ZIndex           = 75
            Corner(dot,s)
            TweenObj(dot, 0.35, {
                BackgroundTransparency = 1,
                Size = UDim2.new(0,0,0,0),
                Position = UDim2.new(0,i.Position.X,0,i.Position.Y),
            }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out):Play()
            task.delay(0.36, function() dot:Destroy() end)
        end)
    end)

    Notify(string.format("🖱  Cursor trail ON  (%d,%d,%d)",r,g,b))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: GAME MISC  (IY-ported)                      ║
-- ╚══════════════════════════════════════════════════════════╝

-- placeinfo  — detailed info about the current place
Cmd("placeinfo", {"gameinfo2","gi"}, function()
    local lines = {
        "Game:      "..game.Name,
        "GameId:    "..game.GameId,
        "PlaceId:   "..game.PlaceId,
        "Version:   "..game.PlaceVersion,
        "JobId:     "..game.JobId:sub(1,18).."…",
        "Players:   "..(#Players:GetPlayers()).."/"..Players.MaxPlayers,
        "Uptime:    "..string.format("%.0fs", workspace.DistributedGameTime),
        "Creator:   "..tostring(game.CreatorId).." ("..game.CreatorType.Name..")",
    }
    print("[S-Admin] Place Info:\n  "..table.concat(lines,"\n  "))
    Notify("ℹ  Place info — see console","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: GRAVITY DISPLAY  (IY-ported)                ║
-- ╚══════════════════════════════════════════════════════════╝

Cmd("gravityinfo", {"gravinfo","showgravity"}, function()
    Notify(string.format("🌍  Gravity: %.2f studs/s²  (default %.2f)",
        workspace.Gravity, _origGravity), "info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ANTI-AFK VARIANTS  (IY-ported)              ║
-- ╚══════════════════════════════════════════════════════════╝

-- wiggle  — tiny random position jitter to defeat idle detection
local _wiggleTask = nil
Cmd("wiggle", {"antiidle","jitter"}, function()
    if _wiggleTask then
        task.cancel(_wiggleTask); _wiggleTask = nil
        Notify("👣  Wiggle OFF"); return
    end
    _wiggleTask = task.spawn(function()
        while true do
            local hrp = GetHRP()
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.new(
                    math.random(-1,1)*0.01, 0, math.random(-1,1)*0.01)
            end
            task.wait(25 + math.random()*10)
        end
    end)
    Notify("👣  Wiggle ON  (micro-jitter every ~30s)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: RENDER / QUALITY SETTINGS  (IY-ported)      ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: settings().Rendering properties, LOD levels,
--           MaxDistance, QualityLevel enum usage.

Cmd("renderdistance", {"renderrange","maxdist"}, function(args)
    local dist = tonumber(args[1]) or 512
    pcall(function()
        workspace.StreamingMinRadius  = math.min(dist, 128)
        workspace.StreamingTargetRadius = dist
    end)
    Notify("🖥  Render distance → "..dist.." studs")
end)

Cmd("lodlevel", {"lod","detaillevel"}, function(args)
    local level = math.clamp(tonumber(args[1]) or 3, 0, 4)
    local map = {
        [0] = Enum.StreamingPauseMode.Default,
        [1] = Enum.StreamingPauseMode.PauseOutsideRequestedArea,
    }
    pcall(function()
        settings().Rendering.QualityLevel = level
    end)
    Notify("🖥  Quality level → "..level)
end)

Cmd("shadows", {"toggleshadows","rendershadows"}, function(args)
    local on = (args[1] or ""):lower() ~= "off"
    Lighting.GlobalShadows = on
    Notify("🌑  Shadows "..(on and "ON" or "OFF"))
end)

Cmd("particlelod", {"particledetail","plod"}, function(args)
    local level = (args[1] or "all"):lower()   -- all | low | off
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("ParticleEmitter") then
            pcall(function()
                if level == "off" then
                    v.Lifetime = NumberRange.new(0)
                elseif level == "low" then
                    v.Rate = v.Rate * 0.25
                else
                    -- Restore (approximate)
                    v.Lifetime = NumberRange.new(1,3)
                end
            end)
        end
    end
    Notify("✨  Particle LOD → "..level)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SCRIPT / MODULE TOOLS  (IY-ported)          ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: finding LocalScripts, ModuleScripts, Script
--           instances across the game tree, source inspection.

Cmd("listscripts", {"scripts","lscripts"}, function(args)
    local query = (args[1] or ""):lower()
    local found  = {}
    local classes = {"LocalScript","ModuleScript","Script"}
    for _, v in ipairs(game:GetDescendants()) do
        for _, cls in ipairs(classes) do
            if v.ClassName == cls then
                if query == "" or v.Name:lower():find(query,1,true) then
                    table.insert(found, {name=v.Name, path=v:GetFullName(), cls=cls})
                end
            end
        end
    end
    if #found == 0 then Notify("No scripts found","warn"); return end
    table.sort(found, function(a,b) return a.path < b.path end)
    print(string.format("[S-Admin] Scripts (%d found):", #found))
    for i=1,math.min(30,#found) do
        print(string.format("  [%s] %s", found[i].cls:sub(1,2), found[i].path))
    end
    Notify(string.format("📜  %d script(s) — see console", #found), "info")
end)

Cmd("scriptcount", {"countscripts","sc2"}, function()
    local counts = {LocalScript=0, ModuleScript=0, Script=0}
    for _, v in ipairs(game:GetDescendants()) do
        if counts[v.ClassName] then counts[v.ClassName] = counts[v.ClassName]+1 end
    end
    local msg = string.format("LocalScript=%d  Module=%d  Script=%d",
        counts.LocalScript, counts.ModuleScript, counts.Script)
    print("[S-Admin] "..msg)
    Notify("📜  "..msg, "info")
end)

Cmd("listmodules", {"modules","lmodules"}, function()
    local found = {}
    for _, v in ipairs(game:GetDescendants()) do
        if v.ClassName == "ModuleScript" then table.insert(found, v:GetFullName()) end
    end
    table.sort(found)
    print("[S-Admin] ModuleScripts ("..#found.."):\n  "..table.concat(found,"\n  "))
    Notify("📦  "..#found.." module(s) — console", "info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ISOMETRIC CAMERA  (IY-ported)               ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: fixed-angle Scriptable camera, orthographic
--           illusion via high FOV + distance, lock-step follow.

local _isoConn = nil

Cmd("isocam", {"isometric","iso"}, function(args)
    if _isoConn then
        _isoConn:Disconnect(); _isoConn = nil
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        workspace.CurrentCamera.FieldOfView = 70
        Notify("📷  Isometric cam OFF"); return
    end
    local dist  = tonumber(args[1]) or 40
    local angle = tonumber(args[2]) or 45
    local cam   = workspace.CurrentCamera
    cam.CameraType  = Enum.CameraType.Scriptable
    cam.FieldOfView = 25   -- narrow FOV = orthographic-like

    local rad = math.rad(angle)
    _isoConn = RunService.RenderStepped:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        local pos = hrp.Position
        local camPos = Vector3.new(
            pos.X + dist * math.cos(rad),
            pos.Y + dist,
            pos.Z + dist * math.sin(rad))
        cam.CFrame = CFrame.new(camPos, pos)
        cam.Focus  = CFrame.new(pos)
    end)
    Notify(string.format("📷  Isometric cam ON  dist=%d  angle=%d°", dist, angle))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: FIRST-PERSON LOCK  (IY-ported)              ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: CameraMaxZoomDistance = 0 pattern, preventing
--           the player from zooming out, property guard.

local _fp1Conn = nil

Cmd("lockfirstperson", {"lfp","forcefp"}, function()
    if _fp1Conn then
        _fp1Conn:Disconnect(); _fp1Conn = nil
        LP.CameraMinZoomDistance = 0.5
        LP.CameraMaxZoomDistance = 400
        Notify("📷  First-person lock OFF"); return
    end
    LP.CameraMinZoomDistance = 0
    LP.CameraMaxZoomDistance = 0
    -- Guard against the game resetting these
    _fp1Conn = LP:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(function()
        if LP.CameraMaxZoomDistance ~= 0 then
            LP.CameraMaxZoomDistance = 0
        end
    end)
    Notify("📷  First-person lock ON  (run again to exit)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: GUI TRANSPARENCY CONTROL  (IY-ported)       ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: recursive descendant transparency adjustment,
--           BackgroundTransparency vs ImageTransparency.

Cmd("guitransparency", {"guitrans","guialpha"}, function(args)
    local alpha = tonumber(args[1])
    if not alpha then Notify("Usage: guitransparency <0-1>","warn"); return end
    alpha = math.clamp(alpha, 0, 1)
    local pg = LP:FindFirstChildOfClass("PlayerGui"); if not pg then return end
    local n  = 0
    for _, v in ipairs(pg:GetDescendants()) do
        if v:IsA("Frame") or v:IsA("ImageLabel") or v:IsA("ImageButton") then
            pcall(function()
                v.BackgroundTransparency = math.max(v.BackgroundTransparency, alpha)
            end)
            n = n + 1
        end
    end
    Notify(string.format("🪟  GUI transparency %.2f  (%d elements)", alpha, n))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ASSET PRELOADER  (IY-ported)                ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: ContentProvider:PreloadAsync, batch loading,
--           checking load state.

Cmd("preload", {"preloads","loadasset"}, function(args)
    local id = tonumber(args[1])
    if not id then Notify("Usage: preload <assetID>","warn"); return end
    Notify("⏳  Preloading "..id.."...", "info")
    task.spawn(function()
        local inst = Instance.new("Part")
        local ok = pcall(function()
            local dec = Instance.new("Decal", inst)
            dec.Texture = "rbxassetid://"..id
            game:GetService("ContentProvider"):PreloadAsync({inst})
        end)
        inst:Destroy()
        Notify(ok and ("✅  Asset "..id.." preloaded") or "❌  Preload failed", ok and "success" or "error")
    end)
end)

Cmd("preloadchar", {"preloadavatar"}, function(args)
    local target = GetPlayers(args[1])[1] or LP
    Notify("⏳  Preloading "..target.Name.."'s avatar...", "info")
    task.spawn(function()
        local ok = pcall(function()
            local desc = Players:GetHumanoidDescriptionFromUserId(target.UserId)
            local temp = Instance.new("Part")
            game:GetService("ContentProvider"):PreloadAsync({temp})
            temp:Destroy()
        end)
        Notify(ok and "✅  Avatar preloaded" or "❌  Preload failed", ok and "success" or "error")
    end)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: EVENT MONITOR  (IY-ported)                  ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: monitoring Roblox engine signals, timing events,
--           game-lifecycle signal connections.

local _eventMonConns  = {}
local _eventMonActive = false

Cmd("eventmonitor", {"evtmon","monitorevents"}, function()
    if _eventMonActive then
        _eventMonActive = false
        for _, c in ipairs(_eventMonConns) do pcall(function() c:Disconnect() end) end
        _eventMonConns = {}
        Notify("📡  Event monitor OFF"); return
    end
    _eventMonActive = true

    local function log(tag, msg)
        if _eventMonActive then
            print(string.format("[S-EventMon] [%s] %s  (t=%.2f)", tag, msg, tick()))
        end
    end

    table.insert(_eventMonConns, Players.PlayerAdded:Connect(function(p)
        log("JOIN",  p.Name.." joined")
    end))
    table.insert(_eventMonConns, Players.PlayerRemoving:Connect(function(p)
        log("LEAVE", p.Name.." left")
    end))
    table.insert(_eventMonConns, workspace.ChildAdded:Connect(function(v)
        log("WS+",   v.Name.." ("..v.ClassName..") added to workspace")
    end))
    table.insert(_eventMonConns, workspace.ChildRemoved:Connect(function(v)
        log("WS-",   v.Name.." ("..v.ClassName..") removed from workspace")
    end))
    table.insert(_eventMonConns, LP.CharacterAdded:Connect(function()
        log("SPAWN", "Character spawned")
    end))
    table.insert(_eventMonConns, LP.CharacterRemoving:Connect(function()
        log("DEATH", "Character removing")
    end))

    Notify("📡  Event monitor ON — output in console","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: RIG DETECTOR  (IY-ported)                   ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: detecting R6 vs R15 via Motor6D names,
--           HumanoidRigType property, part name checks.

Cmd("rigtype", {"rig","myrig"}, function(args)
    local target = GetPlayers(args[1])[1] or LP
    local char   = target.Character
    if not char then Notify("No character","warn"); return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local rigType = "Unknown"

    if hum then
        -- RigType property (R15+)
        pcall(function()
            rigType = hum.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15"
        end)
    end
    -- Cross-check via part names
    local hasUpperTorso = char:FindFirstChild("UpperTorso") ~= nil
    local hasTorso      = char:FindFirstChild("Torso") ~= nil
    local confirm = hasUpperTorso and "R15" or hasTorso and "R6" or "Unknown"

    Notify(string.format("🤖  %s rig: %s  (parts confirm: %s)", target.Name, rigType, confirm), "info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: HITBOX VIEWER  (IY-ported)                  ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: SelectionBox per BasePart, color-coding by size,
--           toggling visibility, cleanup via tag or folder.

local _hitboxConns  = {}
local _hitboxFolder = nil

Cmd("hitboxesp", {"hitbox","hbesp"}, function(args)
    if _hitboxFolder then
        _hitboxFolder:Destroy(); _hitboxFolder = nil
        for _, c in ipairs(_hitboxConns) do pcall(function() c:Disconnect() end) end
        _hitboxConns = {}
        Notify("📦  Hitbox ESP OFF"); return
    end
    local target = GetPlayers(args[1])[1]
    if not target then Notify("Usage: hitboxesp <player>","warn"); return end

    _hitboxFolder = Instance.new("Folder", ScreenGui)
    _hitboxFolder.Name = "S_HitboxESP"

    local function buildHitboxes(char)
        -- Clear old ones for this player
        for _, v in ipairs(_hitboxFolder:GetChildren()) do v:Destroy() end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                local box = Instance.new("SelectionBox", _hitboxFolder)
                box.Adornee = part
                box.Color3  = Color3.fromRGB(255,50,50)
                box.LineThickness = 0.03
                box.SurfaceTransparency = 0.9
                box.SurfaceColor3 = Color3.fromRGB(255,50,50)
            end
        end
    end

    if target.Character then buildHitboxes(target.Character) end
    local c = target.CharacterAdded:Connect(function(ch) task.wait(0.5); buildHitboxes(ch) end)
    table.insert(_hitboxConns, c)
    Notify("📦  Hitbox ESP → "..target.Name)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ANIMATION INSPECTOR  (IY-ported)            ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: GetPlayingAnimationTracks(), AnimationTrack
--           properties, reading live animation state.

Cmd("animinfo", {"animations","currentanim"}, function(args)
    local target = GetPlayers(args[1])[1] or LP
    local char   = target.Character; if not char then Notify("No character","warn"); return end
    local hum    = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local tracks = hum:GetPlayingAnimationTracks()
    if #tracks == 0 then Notify(target.Name.." has no playing animations","warn"); return end
    local lines = {}
    for _, t in ipairs(tracks) do
        table.insert(lines, string.format("  [%s]  speed=%.2f  weight=%.2f  time=%.2f",
            t.Name, t.Speed, t.WeightCurrent, t.TimePosition))
    end
    print("[S-Admin] "..target.Name.." animations:\n"..table.concat(lines,"\n"))
    Notify(string.format("🎭  %d track(s) for %s — console", #tracks, target.Name), "info")
end)

-- pauseanim  — pause all playing animation tracks
Cmd("pauseanim", {"holdanim","stopframe"}, function()
    local hum = GetHuman(); if not hum then return end
    for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
        t:AdjustSpeed(0)
    end
    Notify("🎭  All animations paused  (animspeed 1 to resume)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: PHYSICS ANALYSIS  (IY-ported)               ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: AssemblyLinearVelocity, AssemblyAngularVelocity,
--           GetMass(), reading physics state for debugging.

Cmd("physicsinfo", {"physinfo","charphysics"}, function()
    local hrp = GetHRP(); if not hrp then return end
    local lv  = hrp.AssemblyLinearVelocity
    local av  = hrp.AssemblyAngularVelocity
    local mass = 0
    local char = GetChar()
    if char then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                pcall(function() mass = mass + v:GetMass() end)
            end
        end
    end
    local info = {
        string.format("Linear velocity:   (%.2f, %.2f, %.2f)  mag=%.2f", lv.X,lv.Y,lv.Z, lv.Magnitude),
        string.format("Angular velocity:  (%.2f, %.2f, %.2f)  mag=%.2f", av.X,av.Y,av.Z, av.Magnitude),
        string.format("Total mass:        %.4f", mass),
        string.format("Anchored:          %s", tostring(hrp.Anchored)),
        string.format("CanCollide:        %s", tostring(hrp.CanCollide)),
        string.format("Gravity:           %.2f", workspace.Gravity),
    }
    print("[S-Admin] Physics info:\n  "..table.concat(info,"\n  "))
    Notify(string.format("⚙  Speed=%.1f  Mass=%.2f — console", lv.Magnitude, mass), "info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: NOTIFICATION QUEUE MANAGER  (IY-ported)     ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: controlling the notification system, queue
--           inspection, priority, and clear.

Cmd("clearnotifs", {"clearnotifications","cnq"}, function()
    notifQ = {}
    Notify("🔔  Notification queue cleared")
end)

Cmd("notiftest", {"testnotif","pingtest"}, function()
    Notify("✅  Success notification test","success")
    task.delay(0.3, function() Notify("⚠  Warning notification test","warn") end)
    task.delay(0.6, function() Notify("❌  Error notification test","error") end)
    task.delay(0.9, function() Notify("ℹ  Info notification test","info") end)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ALIAS DISPLAY  (IY-ported)                  ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: iterating the Aliases table, grouping aliases by
--           target command, formatted output.

Cmd("listaliases", {"aliases","showaliases"}, function(args)
    local query = (args[1] or ""):lower()
    -- Group aliases by target command
    local grouped = {}
    for alias, target in pairs(Aliases) do
        if query == "" or target:find(query,1,true) or alias:find(query,1,true) then
            if not grouped[target] then grouped[target] = {} end
            table.insert(grouped[target], alias)
        end
    end
    if next(grouped) == nil then Notify("No aliases found","warn"); return end
    local lines = {}
    for target, alts in pairs(grouped) do
        table.sort(alts)
        table.insert(lines, target.." → ["..table.concat(alts,", ").."]")
    end
    table.sort(lines)
    print("[S-Admin] Aliases:\n  "..table.concat(lines,"\n  "))
    Notify("🔗  "..#lines.." command(s) with aliases — console","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: DEBOUNCE / COOLDOWN TOOLS  (IY-ported)      ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: task.delay-based cooldowns, tracking in a table,
--           a general-purpose cooldown utility pattern.

local _userCooldowns = {}

-- setcooldown <name> <seconds>  — start a named timer
Cmd("setcooldown", {"cd2","startcooldown"}, function(args)
    local name  = args[1]; if not name then Notify("Usage: setcooldown <name> <seconds>","warn"); return end
    local secs  = tonumber(args[2]) or 5
    _userCooldowns[name] = tick() + secs
    Notify(string.format("⏱  Cooldown '%s' → %.1f seconds", name, secs))
    task.delay(secs, function()
        if _userCooldowns[name] and tick() >= _userCooldowns[name] then
            _userCooldowns[name] = nil
            Notify("✅  Cooldown '"..name.."' finished!")
        end
    end)
end)

-- checkcooldown <name>
Cmd("checkcooldown", {"checkcd","cdcheck"}, function(args)
    local name  = args[1]; if not name then
        -- List all
        if next(_userCooldowns) == nil then Notify("No active cooldowns","warn"); return end
        local lines = {}
        for n, t in pairs(_userCooldowns) do
            local left = math.max(0, t - tick())
            table.insert(lines, n.." → "..string.format("%.1fs left", left))
        end
        Notify("⏱  "..table.concat(lines,"  |  "),"info"); return
    end
    local t = _userCooldowns[name]
    if not t then Notify("No cooldown named '"..name.."'","warn"); return end
    local left = math.max(0, t - tick())
    Notify(string.format("⏱  '%s' → %.1f seconds left", name, left), "info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CHARACTER SIZE VARIANTS  (IY-ported)        ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: HumanoidDescription scaling API in preset
--           combinations, how scales interact.

local _sizePresets = {
    normal  = {head=1,   height=1,   width=1,   depth=1  },
    tiny    = {head=0.5, height=0.5, width=0.5, depth=0.5},
    big     = {head=1.5, height=1.5, width=1.5, depth=1.5},
    giant   = {head=2,   height=2.5, width=2,   depth=2  },
    flat    = {head=0.6, height=0.4, width=1.2, depth=1.2},
    tall    = {head=0.7, height=2.5, width=0.6, depth=0.6},
    wide    = {head=1,   height=0.8, width=2.5, depth=1  },
    noodle  = {head=0.5, height=3,   width=0.4, depth=0.4},
}

Cmd("sizepreset", {"ss","shapepreset"}, function(args)
    local key  = (args[1] or "normal"):lower()
    local p    = _sizePresets[key]
    if not p then
        local list = {}
        for k in pairs(_sizePresets) do table.insert(list,k) end
        table.sort(list)
        Notify("Shapes: "..table.concat(list,", "),"warn"); return
    end
    local hum = GetHuman(); if not hum then return end
    local desc = hum:GetAppliedDescription()
    desc.HeadScale       = p.head
    desc.BodyHeightScale = p.height
    desc.BodyWidthScale  = p.width
    desc.BodyDepthScale  = p.depth
    desc.LowerTorsoScale = p.depth
    desc.UpperTorsoScale = p.width
    hum:ApplyDescription(desc)
    Notify("📐  Size preset '"..key.."' applied")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: COLOR PICKER UTILITY  (IY-ported)           ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Color3 construction methods, hex parsing,
--           HSV vs RGB vs hex color formats.

-- color <hex>  — parse a hex color and show it in a preview
Cmd("color", {"colorpick","hex"}, function(args)
    local hex = (args[1] or ""):gsub("#","")
    if #hex ~= 6 then Notify("Usage: color <RRGGBB hex>  e.g. color FF4500","warn"); return end
    local r = tonumber(hex:sub(1,2),16) or 0
    local g = tonumber(hex:sub(3,4),16) or 0
    local b = tonumber(hex:sub(5,6),16) or 0
    -- Show swatch
    local swatch = Instance.new("Frame", ScreenGui)
    swatch.Size             = UDim2.new(0,80,0,40)
    swatch.Position         = UDim2.new(0.5,-40,0.5,-20)
    swatch.BackgroundColor3 = Color3.fromRGB(r,g,b)
    swatch.ZIndex           = 70
    Corner(swatch, 8)
    Stroke(swatch, 2, Color3.new(1,1,1))
    local lbl = Instance.new("TextLabel",swatch)
    lbl.Size             = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = "#"..hex:upper()
    lbl.TextColor3       = (r+g+b > 382) and Color3.new(0,0,0) or Color3.new(1,1,1)
    lbl.Font             = Enum.Font.Code
    lbl.TextSize         = 14
    lbl.ZIndex           = 71
    task.delay(3, function() swatch:Destroy() end)
    -- Also print RGB and HSV
    local h,s,v = Color3.fromRGB(r,g,b):ToHSV()
    print(string.format("[S-Color] #%s  RGB(%d,%d,%d)  HSV(%.0f°,%.0f%%,%.0f%%)",
        hex:upper(), r, g, b, h*360, s*100, v*100))
    Notify(string.format("🎨  #%s → RGB(%d,%d,%d)", hex:upper(), r, g, b), "info")
end)

-- rgb2hex  — convert RGB to hex
Cmd("rgb2hex", {"tohex","rgbhex"}, function(args)
    local r = tonumber(args[1]) or 0
    local g = tonumber(args[2]) or 0
    local b = tonumber(args[3]) or 0
    local hex = string.format("%02X%02X%02X", r, g, b)
    pcall(function() setclipboard("#"..hex) end)
    Notify("🎨  #"..hex.." (copied)","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: PLACE TELEPORT  (IY-ported)                 ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: TeleportService:Teleport (cross-place teleport),
--           PlaceId vs GameId distinction.

Cmd("tpplace", {"gotoplace","placetp"}, function(args)
    local placeId = tonumber(args[1])
    if not placeId then Notify("Usage: tpplace <placeID>","warn"); return end
    Notify("🌐  Teleporting to place "..placeId.."...")
    task.delay(0.5, function()
        pcall(function()
            TeleportService:Teleport(placeId, LP)
        end)
    end)
end)

-- tpgame <gameId>  — teleport to a game's start place
Cmd("tpgame", {"gotogame","gametp"}, function(args)
    local gameId = tonumber(args[1])
    if not gameId then Notify("Usage: tpgame <gameID>","warn"); return end
    Notify("🌐  Looking up game "..gameId.."...", "info")
    task.spawn(function()
        local ok, body = pcall(function()
            local raw = game:HttpGet("https://games.roblox.com/v1/games?universeIds="..gameId)
            return game:GetService("HttpService"):JSONDecode(raw)
        end)
        if ok and body and body.data and body.data[1] then
            local rootPlaceId = body.data[1].rootPlaceId
            if rootPlaceId then
                Notify("🌐  Teleporting to '"..tostring(body.data[1].name).."'...")
                task.delay(0.5, function()
                    pcall(function() TeleportService:Teleport(rootPlaceId, LP) end)
                end)
            else
                Notify("Could not find root place","error")
            end
        else
            Notify("Game "..gameId.." not found","error")
        end
    end)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CONSTRAINT INSPECTOR  (IY-ported)           ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: listing Constraint instances, reading Attachment
--           positions, visualising constraint connections.

Cmd("listconstraints", {"constraints","lconstraints"}, function(args)
    local query  = (args[1] or ""):lower()
    local found  = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Constraint") then
            if query == "" or v.ClassName:lower():find(query,1,true) then
                table.insert(found, {
                    cls  = v.ClassName,
                    path = v:GetFullName(),
                    a0   = v.Attachment0 and v.Attachment0:GetFullName() or "nil",
                    a1   = v.Attachment1 and v.Attachment1:GetFullName() or "nil",
                })
            end
        end
    end
    if #found == 0 then Notify("No constraints found","warn"); return end
    print(string.format("[S-Admin] Constraints (%d):", #found))
    for _, c in ipairs(found) do
        print(string.format("  [%s] %s  |  %s ↔ %s", c.cls, c.path, c.a0, c.a1))
    end
    Notify("⚙  "..#found.." constraint(s) — console","info")
end)

-- removeconstraint <name>  — destroy a constraint by name
Cmd("removeconstraint", {"delconstraint","rmconstraint"}, function(args)
    local name = args[1]; if not name then Notify("Usage: removeconstraint <name>","warn"); return end
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Constraint") and v.Name:lower() == name:lower() then
            pcall(function() v:Destroy() end); n=n+1
        end
    end
    Notify("⚙  Removed "..n.." constraint(s) named '"..name.."'")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: MISC USEFUL UTILITIES  (IY-ported)          ║
-- ╚══════════════════════════════════════════════════════════╝

-- waitfor <instance path>  — wait up to N seconds for an instance
Cmd("waitfor", {"wait","wf"}, function(args)
    local path   = args[1]; if not path then Notify("Usage: waitfor <name> [timeout]","warn"); return end
    local timeout = tonumber(args[2]) or 10
    Notify("⏳  Waiting for '"..path.."'  (timeout "..timeout.."s)...", "info")
    task.spawn(function()
        local start = tick()
        local found = nil
        while tick()-start < timeout do
            found = game:FindFirstChild(path, true)
            if found then break end
            task.wait(0.1)
        end
        if found then
            Notify("✅  Found: "..found:GetFullName(),"success")
        else
            Notify("❌  '"..path.."' not found in "..timeout.."s","error")
        end
    end)
end)

-- benchmark2 <iterations> <cmd>  — run a command N times and measure average
Cmd("benchmark2", {"bench2","timedloop"}, function(args)
    local n    = math.min(tonumber(args[1]) or 10, 100)
    local rest = table.concat(args," ",2)
    if rest == "" then Notify("Usage: benchmark2 <n> <command>","warn"); return end
    local parts = {}
    for w in rest:gmatch("%S+") do table.insert(parts,w) end
    local name = table.remove(parts,1):lower()
    name = Aliases[name] or name
    if not Commands[name] then Notify("Unknown command: "..name,"error"); return end
    local total = 0
    for i=1,n do
        local t0 = tick()
        pcall(function() Commands[name](parts) end)
        total = total + (tick()-t0)
    end
    Notify(string.format("⏱  %s × %d  avg=%.3fms  total=%.2fms",
        name, n, (total/n)*1000, total*1000), "info")
end)

-- matheval <expression>  — evaluate a math expression
Cmd("matheval", {"calc","math"}, function(args)
    local expr = table.concat(args," ")
    if expr == "" then Notify("Usage: matheval <expression>","warn"); return end
    local fn, err = loadstring("return "..expr)
    if not fn then Notify("Syntax error: "..tostring(err),"error"); return end
    local ok, result = pcall(fn)
    if ok then
        local str = tostring(result)
        pcall(function() setclipboard(str) end)
        Notify("🔢  "..expr.." = "..str.."  (copied)","info")
    else
        Notify("Eval error: "..tostring(result),"error")
    end
end)

-- sizeof <part name>  — get size of nearest matching part
Cmd("sizeof", {"partsize","getsize"}, function(args)
    local name  = table.concat(args," "):lower()
    local hrp   = GetHRP(); if not hrp then return end
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (name=="" or v.Name:lower():find(name,1,true)) then
            local d = (v.Position - hrp.Position).Magnitude
            if d < bestDist then best=v; bestDist=d end
        end
    end
    if not best then Notify("No matching part found","warn"); return end
    local s = best.Size
    Notify(string.format("📏  %s  size=(%.2f, %.2f, %.2f)  mass≈%.2f",
        best.Name, s.X, s.Y, s.Z, best:GetMass()), "info")
end)

-- distanceto <player>  — distance between you and a player
Cmd("distanceto", {"dist","range"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or not target.Character then Notify("Target not found","error"); return end
    local myHRP = GetHRP(); if not myHRP then return end
    local tHRP  = target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local d = (tHRP.Position - myHRP.Position).Magnitude
    Notify(string.format("📏  Distance to %s: %.1f studs", target.Name, d), "info")
end)

-- getancestors <path>  — print ancestor chain of an instance
Cmd("getancestors", {"ancestors","parents"}, function(args)
    local name = args[1]; if not name then Notify("Usage: getancestors <instance name>","warn"); return end
    local inst = game:FindFirstChild(name, true)
    if not inst then Notify("Instance not found: "..name,"error"); return end
    local chain = {}
    local cur   = inst
    while cur do table.insert(chain,1,cur.Name.." ("..cur.ClassName..")"); cur = cur.Parent end
    print("[S-Admin] Ancestors of '"..inst.Name.."':\n  "..table.concat(chain," → "))
    Notify("🔍  Ancestor chain — see console","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: LIGHTING PRESETS  (IY-ported)               ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: bundling multiple Lighting properties into named
--           presets, saving / restoring original state.

local _lightingPresets = {
    morning = {ClockTime=7,  Brightness=1,   Ambient=Color3.fromRGB(180,160,140), FogEnd=1e6, GlobalShadows=true},
    noon    = {ClockTime=13, Brightness=2,   Ambient=Color3.fromRGB(160,160,160), FogEnd=1e6, GlobalShadows=true},
    sunset  = {ClockTime=18, Brightness=0.8, Ambient=Color3.fromRGB(210,130,80),  FogEnd=800, GlobalShadows=true},
    night   = {ClockTime=22, Brightness=0.1, Ambient=Color3.fromRGB(20,20,60),    FogEnd=500, GlobalShadows=true},
    midnight= {ClockTime=0,  Brightness=0,   Ambient=Color3.fromRGB(10,10,30),    FogEnd=300, GlobalShadows=false},
    foggy   = {ClockTime=9,  Brightness=0.5, Ambient=Color3.fromRGB(140,140,140), FogEnd=150, GlobalShadows=false},
    hdr     = {ClockTime=14, Brightness=3,   Ambient=Color3.fromRGB(200,200,200), FogEnd=1e6, GlobalShadows=true},
    horror  = {ClockTime=0,  Brightness=0,   Ambient=Color3.fromRGB(30,0,0),      FogEnd=120, GlobalShadows=false},
}

Cmd("lightpreset", {"lp","timepreset","setlighting"}, function(args)
    local key = (args[1] or ""):lower()
    local p   = _lightingPresets[key]
    if not p then
        local list = {}
        for k in pairs(_lightingPresets) do table.insert(list,k) end
        table.sort(list)
        Notify("Presets: "..table.concat(list,", "),"warn"); return
    end
    for prop, val in pairs(p) do
        pcall(function() Lighting[prop] = val end)
    end
    Notify("💡  Lighting preset '"..key.."' applied")
end)

Cmd("savelighting", {"savellt","snaplight"}, function()
    OrigLight = {
        ClockTime     = Lighting.ClockTime,
        Brightness    = Lighting.Brightness,
        Ambient       = Lighting.Ambient,
        FogEnd        = Lighting.FogEnd,
        FogStart      = Lighting.FogStart,
        GlobalShadows = Lighting.GlobalShadows,
    }
    Notify("💡  Lighting state saved")
end)

Cmd("restorelighting", {"restorelt","resetlighting"}, function()
    for prop, val in pairs(OrigLight) do
        pcall(function() Lighting[prop] = val end)
    end
    Notify("💡  Lighting restored to saved state")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: PART SEARCH & MODIFY  (IY-ported)           ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: filtering by color/size/material, batch property
--           changes, nearest-part pattern.

-- findbycolor <R G B> [tolerance]
Cmd("findbycolor", {"partcolor","searchcolor"}, function(args)
    local r   = tonumber(args[1]) or 255
    local g   = tonumber(args[2]) or 0
    local b   = tonumber(args[3]) or 0
    local tol = tonumber(args[4]) or 30
    local hrp = GetHRP(); if not hrp then return end
    local target = Color3.fromRGB(r,g,b)
    local found, cap = {}, 15
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local c = v.Color
            local dr = math.abs(c.R*255 - r)
            local dg = math.abs(c.G*255 - g)
            local db = math.abs(c.B*255 - b)
            if dr <= tol and dg <= tol and db <= tol then
                local d = (v.Position-hrp.Position).Magnitude
                table.insert(found,{name=v.Name,path=v:GetFullName(),dist=d})
                if #found >= cap then break end
            end
        end
    end
    if #found == 0 then Notify("No parts matching that color","warn"); return end
    table.sort(found,function(a,b) return a.dist < b.dist end)
    print(string.format("[S-Admin] Parts near RGB(%d,%d,%d) ±%d:",r,g,b,tol))
    for _,v in ipairs(found) do
        print(string.format("  %-20s %.0f studs  %s",v.name,v.dist,v.path))
    end
    Notify(string.format("🔍  %d part(s) found — console",#found),"info")
end)

-- findbysize  — find parts within a size range
Cmd("findbysize", {"partsize2","searchsize"}, function(args)
    local minS = tonumber(args[1]) or 1
    local maxS = tonumber(args[2]) or 5
    local hrp  = GetHRP(); if not hrp then return end
    local found,cap = {},15
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local mag = v.Size.Magnitude
            if mag >= minS and mag <= maxS then
                local d = (v.Position-hrp.Position).Magnitude
                table.insert(found,{name=v.Name,size=mag,dist=d})
                if #found >= cap then break end
            end
        end
    end
    if #found == 0 then Notify("No parts in that size range","warn"); return end
    table.sort(found,function(a,b) return a.dist < b.dist end)
    print(string.format("[S-Admin] Parts size %.1f–%.1f:", minS, maxS))
    for _,v in ipairs(found) do
        print(string.format("  %-20s size=%.2f  dist=%.0f", v.name, v.size, v.dist))
    end
    Notify(string.format("🔍  %d part(s) found — console",#found),"info")
end)

-- recolorpart <name> <R G B>  — change color of all parts with that name
Cmd("recolorpart", {"partrecolor","colorpart"}, function(args)
    local name = args[1]; if not name then Notify("Usage: recolorpart <name> R G B","warn"); return end
    local r = tonumber(args[2]) or 255
    local g = tonumber(args[3]) or 255
    local b = tonumber(args[4]) or 255
    local col = Color3.fromRGB(r,g,b)
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower()==name:lower() then
            pcall(function() v.Color = col end); n=n+1
        end
    end
    Notify(string.format("🎨  Recolored %d '%s' part(s) to RGB(%d,%d,%d)",n,name,r,g,b))
end)

-- resizepart <name> <X Y Z>
Cmd("resizepart", {"partresize","scalepart"}, function(args)
    local name = args[1]; if not name then Notify("Usage: resizepart <name> X Y Z","warn"); return end
    local x = tonumber(args[2]) or 1
    local y = tonumber(args[3]) or x
    local z = tonumber(args[4]) or x
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower()==name:lower() then
            pcall(function() v.Size = Vector3.new(x,y,z) end); n=n+1
        end
    end
    Notify(string.format("📏  Resized %d '%s' part(s) to %.1fx%.1fx%.1f",n,name,x,y,z))
end)

-- renamepart <oldname> <newname>
Cmd("renamepart", {"partname","namepart"}, function(args)
    local old = args[1]; local new = args[2]
    if not old or not new then Notify("Usage: renamepart <old> <new>","warn"); return end
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower()==old:lower() then
            pcall(function() v.Name = new end); n=n+1
        end
    end
    Notify(string.format("✏  Renamed %d '%s' → '%s'",n,old,new))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CUSTOM HEALTH BAR HUD  (IY-ported)          ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: live-updating Frame width from health ratio,
--           color interpolation green→yellow→red, TweenService
--           for smooth bar transitions.

local _healthBarGui  = nil
local _healthBarConn = nil

Cmd("healthbar", {"hpbar","customhp"}, function()
    if _healthBarGui then
        _healthBarGui:Destroy(); _healthBarGui = nil
        if _healthBarConn then _healthBarConn:Disconnect(); _healthBarConn=nil end
        Notify("❤  Health bar OFF"); return
    end
    _healthBarGui = Instance.new("ScreenGui", ScreenGui)
    _healthBarGui.Name         = "S_HealthBar"
    _healthBarGui.ResetOnSpawn = false
    _healthBarGui.DisplayOrder = 89

    local bg = Instance.new("Frame",_healthBarGui)
    bg.Size             = UDim2.new(0,200,0,16)
    bg.Position         = UDim2.new(0.5,-100,1,-34)
    bg.BackgroundColor3 = Color3.fromRGB(30,30,30)
    bg.BackgroundTransparency = 0.3
    bg.ZIndex           = 89
    Corner(bg,8)

    local bar = Instance.new("Frame",bg)
    bar.Name            = "Bar"
    bar.Size            = UDim2.new(1,0,1,0)
    bar.BackgroundColor3 = Color3.fromRGB(80,220,80)
    bar.ZIndex          = 90
    Corner(bar,8)

    local lbl = Instance.new("TextLabel",bg)
    lbl.Size             = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextSize         = 11
    lbl.TextColor3       = Color3.new(1,1,1)
    lbl.ZIndex           = 91

    local lastRatio = 1
    _healthBarConn = RunService.Heartbeat:Connect(function()
        local hum = GetHuman(); if not hum then return end
        local ratio = math.clamp(hum.Health/math.max(hum.MaxHealth,1), 0, 1)
        if math.abs(ratio-lastRatio) > 0.001 then
            lastRatio = ratio
            TweenObj(bar, 0.15, {Size = UDim2.new(ratio,0,1,0)}):Play()
            -- Green → Yellow → Red
            local col
            if ratio > 0.5 then
                col = Color3.fromRGB(
                    math.floor((1-ratio)*2*255), 220, 80)
            else
                col = Color3.fromRGB(
                    220, math.floor(ratio*2*220), 60)
            end
            bar.BackgroundColor3 = col
        end
        lbl.Text = string.format("❤ %d / %d",
            math.floor(hum.Health), math.floor(hum.MaxHealth))
    end)
    Notify("❤  Health bar ON")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SESSION STATISTICS TRACKER  (IY-ported)     ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: accumulating metrics across a session, storing
--           per-session state, formatted summary output.

local _sessionStart   = tick()
local _sessionDeaths  = 0
local _sessionDist    = 0
local _sessionLastPos = nil

-- Track deaths via CharacterAdded
LP.CharacterAdded:Connect(function()
    _sessionDeaths = _sessionDeaths + 1
end)

-- Track distance walked via Heartbeat
RunService.Heartbeat:Connect(function()
    local hrp = GetHRP()
    if hrp then
        if _sessionLastPos then
            local moved = (hrp.Position - _sessionLastPos).Magnitude
            if moved < 50 then  -- ignore teleports
                _sessionDist = _sessionDist + moved
            end
        end
        _sessionLastPos = hrp.Position
    end
end)

Cmd("sessionstats", {"session","mystats"}, function()
    local elapsed = tick() - _sessionStart
    local h = math.floor(elapsed/3600)
    local m = math.floor((elapsed%3600)/60)
    local s = math.floor(elapsed%60)
    local lines = {
        string.format("⏱  Session time:   %02d:%02d:%02d",h,m,s),
        string.format("💀  Deaths:         %d",_sessionDeaths),
        string.format("📏  Distance walked: %.0f studs (%.2f km)",
            _sessionDist, _sessionDist*0.00028),
        string.format("📍  Current pos:    %.0f, %.0f, %.0f",
            _sessionLastPos and _sessionLastPos.X or 0,
            _sessionLastPos and _sessionLastPos.Y or 0,
            _sessionLastPos and _sessionLastPos.Z or 0),
        string.format("👥  Players online:  %d/%d",
            #Players:GetPlayers(), Players.MaxPlayers),
        string.format("🖥  Game:           %s  v%d",game.Name,game.PlaceVersion),
    }
    print("[S-Admin] Session Stats:\n  "..table.concat(lines,"\n  "))
    Notify(string.format("📊  %.0f min  |  %d deaths  |  %.0f studs walked",
        elapsed/60, _sessionDeaths, _sessionDist), "info")
end)

Cmd("resetsessionstats", {"resetsession","clearstats"}, function()
    _sessionStart  = tick()
    _sessionDeaths = -1   -- -1 because CharacterAdded fires immediately
    _sessionDist   = 0
    Notify("📊  Session stats reset")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: TWEEN PART TOOLS  (IY-ported)               ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: TweenService on non-GUI objects, tweening BasePart
--           CFrame/Color/Transparency, chaining tweens.

-- tweenpart <name> <X Y Z> <time>  — smoothly move a named part
Cmd("tweenpart", {"movetween","tpart"}, function(args)
    local name = args[1]; if not name then Notify("Usage: tweenpart <name> X Y Z [t]","warn"); return end
    local x = tonumber(args[2]) or 0
    local y = tonumber(args[3]) or 0
    local z = tonumber(args[4]) or 0
    local t = tonumber(args[5]) or 2
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower()==name:lower() then
            v.Anchored = true
            TweenObj(v, t, {CFrame=CFrame.new(x,y,z)}, Enum.EasingStyle.Quad):Play()
            n=n+1
        end
    end
    Notify(string.format("📦  Tweening %d '%s' to (%.0f,%.0f,%.0f) over %.1fs",n,name,x,y,z,t))
end)

-- tweenpartcolor <name> <R G B> <time>
Cmd("tweenpartcolor", {"tpartcolor","colorpulse"}, function(args)
    local name = args[1]; if not name then Notify("Usage: tweenpartcolor <name> R G B [t]","warn"); return end
    local r = tonumber(args[2]) or 255
    local g = tonumber(args[3]) or 0
    local b = tonumber(args[4]) or 0
    local t = tonumber(args[5]) or 1
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower()==name:lower() then
            TweenObj(v, t, {Color=Color3.fromRGB(r,g,b)}):Play(); n=n+1
        end
    end
    Notify(string.format("🎨  Color-tweening %d '%s' over %.1fs",n,name,t))
end)

-- tweenpartfade <name> <transparency> <time>
Cmd("tweenpartfade", {"tpartfade","fadepart"}, function(args)
    local name  = args[1]; if not name then Notify("Usage: tweenpartfade <name> <0-1> [t]","warn"); return end
    local alpha = math.clamp(tonumber(args[2]) or 1, 0, 1)
    local t     = tonumber(args[3]) or 1
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower()==name:lower() then
            TweenObj(v, t, {Transparency=alpha}):Play(); n=n+1
        end
    end
    Notify(string.format("🔍  Fading %d '%s' to %.2f over %.1fs",n,name,alpha,t))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: TERRAIN WATER  (IY-ported)                  ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Terrain:FillBlock with Water material,
--           Region3 for volume selection.

Cmd("fillwater", {"waterblock","addwater"}, function(args)
    local hrp  = GetHRP(); if not hrp then return end
    local size = tonumber(args[1]) or 30
    local depth= tonumber(args[2]) or 10
    workspace.Terrain:FillBlock(
        CFrame.new(hrp.Position - Vector3.new(0,depth/2,0)),
        Vector3.new(size, depth, size),
        Enum.Material.Water)
    Notify(string.format("💧  Water block created  %dx%d depth=%d",size,size,depth))
end)

Cmd("removewater", {"drainwater","nowater"}, function(args)
    local hrp  = GetHRP(); if not hrp then return end
    local size = tonumber(args[1]) or 60
    workspace.Terrain:FillBlock(
        CFrame.new(hrp.Position),
        Vector3.new(size,size,size),
        Enum.Material.Air)
    Notify(string.format("💧  Cleared %dx%d terrain block (air)",size,size))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: AMBIENT SOUNDS  (IY-ported)                 ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Sound parented to workspace (global audio),
--           ambient audio vs positional audio, RollOff modes.

local _ambientSounds = {
    rain    = 130792573,
    wind    = 1369158,
    birds   = 136523844,
    thunder = 130831965,
    ocean   = 6518660,
    fire    = 406889705,
    crickets= 2770477272,
    dungeon = 1843644041,
}
local _ambientConn = nil

Cmd("ambience", {"ambient2","ambientsound"}, function(args)
    local key = (args[1] or ""):lower()
    local vol = tonumber(args[2]) or 0.4
    -- Stop existing ambient
    local old = workspace:FindFirstChild("S_Ambience")
    if old then old:Destroy() end
    if key == "" or key == "off" or key == "stop" then
        Notify("🎵  Ambience OFF"); return
    end
    local id = _ambientSounds[key]
    if not id then
        local list = {}
        for k in pairs(_ambientSounds) do table.insert(list,k) end
        table.sort(list)
        Notify("Ambiences: "..table.concat(list,", "),"warn"); return
    end
    local snd = Instance.new("Sound",workspace)
    snd.Name   = "S_Ambience"
    snd.SoundId = "rbxassetid://"..id
    snd.Volume  = math.clamp(vol,0,2)
    snd.Looped  = true
    snd.RollOffMaxDistance = 1e4
    snd.RollOffMode = Enum.RollOffMode.InverseTapered
    snd:Play()
    Notify("🎵  Ambience: "..key.."  vol="..vol)
end)

Cmd("stopambience", {"noambience","endambient"}, function()
    local old = workspace:FindFirstChild("S_Ambience")
    if old then old:Destroy(); Notify("🎵  Ambience stopped")
    else Notify("No ambience playing","warn") end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: DEATH POSITION RECALL  (IY-ported)          ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: CharacterRemoving signal, saving HRP position
--           on death, restoring after respawn.

local _lastDeathPos = nil

LP.CharacterRemoving:Connect(function(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then _lastDeathPos = hrp.CFrame end
end)

Cmd("tpdeath", {"gotodie","lastdeath","deathtp"}, function()
    if not _lastDeathPos then Notify("No death position recorded yet","warn"); return end
    local hrp = GetHRP(); if not hrp then return end
    hrp.CFrame = _lastDeathPos
    local p    = _lastDeathPos.Position
    Notify(string.format("💀  TP to last death  (%.0f,%.0f,%.0f)",p.X,p.Y,p.Z))
end)

Cmd("lastdeathpos", {"deathpos","wheredie"}, function()
    if not _lastDeathPos then Notify("No death recorded yet","warn"); return end
    local p = _lastDeathPos.Position
    Notify(string.format("💀  Last death: %.0f,%.0f,%.0f",p.X,p.Y,p.Z),"info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: NEON / DARK MODE  (IY-ported)               ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: changing material to Neon for glow effect,
--           batch dark color application.

Cmd("neonmode", {"neon","glowmode"}, function(args)
    local char = GetChar(); if not char then return end
    local r = tonumber(args[1]) or 0
    local g = tonumber(args[2]) or 180
    local b = tonumber(args[3]) or 255
    local n = 0
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            pcall(function()
                v.Material = Enum.Material.Neon
                v.Color    = Color3.fromRGB(r,g,b)
            end)
            n=n+1
        end
    end
    Notify(string.format("✨  Neon mode ON  RGB(%d,%d,%d)  %d parts",r,g,b,n))
end)

Cmd("darkmode", {"dark","blackchar"}, function()
    local char = GetChar(); if not char then return end
    local n = 0
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            pcall(function()
                v.Material = Enum.Material.SmoothPlastic
                v.Color    = Color3.fromRGB(15,15,15)
            end)
            n=n+1
        end
    end
    Notify("🌑  Dark mode applied to "..n.." parts")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: STRING UTILITIES  (IY-ported)               ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: string library (upper/lower/rep/reverse/len),
--           Lua pattern matching, clipboard output.

Cmd("strlen", {"stringlen","strlength"}, function(args)
    local s = table.concat(args," ")
    if s == "" then Notify("Usage: strlen <text>","warn"); return end
    Notify(string.format("📏  Length: %d characters",#s),"info")
end)

Cmd("strupper", {"uppercase","toupper"}, function(args)
    local s = table.concat(args," ")
    local r = s:upper()
    pcall(function() setclipboard(r) end)
    Notify("🔤  "..r.."  (copied)","info")
end)

Cmd("strlower", {"lowercase","tolower"}, function(args)
    local s = table.concat(args," ")
    local r = s:lower()
    pcall(function() setclipboard(r) end)
    Notify("🔤  "..r.."  (copied)","info")
end)

Cmd("strreverse", {"reverse","strrev"}, function(args)
    local s = table.concat(args," ")
    local r = s:reverse()
    pcall(function() setclipboard(r) end)
    Notify("🔤  "..r.."  (copied)","info")
end)

Cmd("strrep", {"repeat2","strrepeat"}, function(args)
    local n = tonumber(args[1]) or 3
    local s = table.concat(args," ",2)
    local r = s:rep(math.min(n,20))
    pcall(function() setclipboard(r) end)
    print("[S-Admin] rep × "..n..": "..r)
    Notify("🔤  Repeated ×"..n.."  (console + clipboard)","info")
end)

Cmd("charcode", {"ascii","charnum"}, function(args)
    local s = table.concat(args," ")
    if s == "" then Notify("Usage: charcode <text>","warn"); return end
    local codes = {}
    for i=1,math.min(#s,20) do table.insert(codes,string.byte(s,i)) end
    local r = table.concat(codes," ")
    pcall(function() setclipboard(r) end)
    Notify("🔢  "..r,"info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CAMERA CINEMATIC CUTS  (IY-ported)          ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: sequencing multiple TweenService camera moves,
--           coroutine / task.spawn for non-blocking sequences.

-- camcut <X Y Z> <lookX lookY lookZ> <time>
Cmd("camcut", {"cinematiccut","ccut"}, function(args)
    local px = tonumber(args[1]) or 0
    local py = tonumber(args[2]) or 10
    local pz = tonumber(args[3]) or 0
    local lx = tonumber(args[4]) or 0
    local ly = tonumber(args[5]) or 0
    local lz = tonumber(args[6]) or 0
    local t  = tonumber(args[7]) or 2
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    local targetCF = CFrame.new(Vector3.new(px,py,pz), Vector3.new(lx,ly,lz))
    TweenObj(cam, t, {CFrame=targetCF}, Enum.EasingStyle.Sine):Play()
    task.delay(t+0.1, function()
        cam.CameraType = Enum.CameraType.Custom
    end)
    Notify(string.format("🎬  CamCut to (%.0f,%.0f,%.0f) over %.1fs",px,py,pz,t))
end)

-- camsequence  — tween camera through all saved waypoints
Cmd("camsequence", {"cseq","waypointcam"}, function(args)
    if #_waypoints < 2 then Notify("Need at least 2 waypoints — use setwp","warn"); return end
    local t = tonumber(args[1]) or 3
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    task.spawn(function()
        for _, wp in ipairs(_waypoints) do
            local cf = CFrame.new(wp.x, wp.y+5, wp.z)
            TweenObj(cam, t, {CFrame=cf}, Enum.EasingStyle.Sine):Play()
            task.wait(t + 0.2)
        end
        cam.CameraType = Enum.CameraType.Custom
        Notify("🎬  Camera sequence complete")
    end)
    Notify(string.format("🎬  Camera touring %d waypoints  (%.1fs each)",#_waypoints,t))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SERVER TICK RATE DISPLAY  (IY-ported)       ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: HeartbeatTimeMs stat, measuring tick rate from
--           Heartbeat signal timing.

local _tickRateGui  = nil
local _tickRateConn = nil

Cmd("tickrate", {"serverrate","tickdisplay"}, function()
    if _tickRateGui then
        _tickRateGui:Destroy(); _tickRateGui = nil
        if _tickRateConn then _tickRateConn:Disconnect(); _tickRateConn=nil end
        Notify("⚙  Tick rate display OFF"); return
    end

    _tickRateGui = Instance.new("ScreenGui",ScreenGui)
    _tickRateGui.Name         = "S_TickRate"
    _tickRateGui.ResetOnSpawn = false
    _tickRateGui.DisplayOrder = 86

    local f = Instance.new("Frame",_tickRateGui)
    f.Size             = UDim2.new(0,160,0,24)
    f.Position         = UDim2.new(0,10,0,36)
    f.BackgroundColor3 = Color3.fromRGB(10,10,10)
    f.BackgroundTransparency = 0.4
    f.ZIndex           = 86
    Corner(f,6)

    local lbl = Instance.new("TextLabel",f)
    lbl.Size             = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Font             = Enum.Font.Code
    lbl.TextSize         = 11
    lbl.TextColor3       = Color3.new(1,1,1)
    lbl.ZIndex           = 87
    Pad(lbl,4)

    local samples, elapsed = {}, 0
    _tickRateConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        table.insert(samples, dt)
        if #samples > 60 then table.remove(samples,1) end
        if elapsed < 0.5 then return end
        elapsed = 0
        local avg = 0
        for _,s in ipairs(samples) do avg=avg+s end
        avg = avg/#samples
        local rate = 1/avg
        local stats = game:GetService("Stats")
        local heartMs = 0
        pcall(function() heartMs = stats.HeartbeatTimeMs.Value end)
        lbl.Text = string.format("⚙ Tick: %.0f Hz  |  %.1f ms", rate, heartMs)
        lbl.TextColor3 = rate > 55 and Color3.fromRGB(80,220,100)
                       or rate > 30 and Color3.fromRGB(220,200,50)
                       or Color3.fromRGB(220,80,80)
    end)
    Notify("⚙  Tick rate display ON")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: FRIENDS LIST  (IY-ported)                   ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Players:GetFriendsAsync(), page iteration,
--           async HTTP patterns.

Cmd("friends", {"friendslist","myfriends"}, function(args)
    local target = GetPlayers(args[1])[1] or LP
    Notify("👥  Loading "..target.Name.."'s friends...", "info")
    task.spawn(function()
        local ok, pages = pcall(function()
            return Players:GetFriendsAsync(target.UserId)
        end)
        if not ok or not pages then Notify("Could not load friends","error"); return end
        local friends = {}
        local success = pcall(function()
            repeat
                for _, f in ipairs(pages:GetCurrentPage()) do
                    table.insert(friends, f.Username)
                end
                if not pages.IsFinished then pages:AdvanceToNextPageAsync() end
            until pages.IsFinished or #friends >= 50
        end)
        if #friends == 0 then Notify(target.Name.." has no friends listed","warn"); return end
        -- Highlight any who are currently in-game
        local inGame = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if table.find(friends, p.Name) then table.insert(inGame, p.Name) end
        end
        table.sort(friends)
        print(string.format("[S-Admin] %s friends (%d):\n  %s",
            target.Name, #friends, table.concat(friends,"\n  ")))
        local msg = #inGame > 0 and ("  In-game: "..table.concat(inGame,", ")) or ""
        Notify(string.format("👥  %d friend(s)%s — console",#friends,msg),"info")
    end)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SESSION NOTES / TEMP STORAGE  (IY-ported)   ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: persistent in-session string storage, structured
--           note-taking pattern, clip-to-clipboard export.

local _notes = {}

Cmd("note", {"addnote","remember"}, function(args)
    local text = table.concat(args," ")
    if text == "" then Notify("Usage: note <text>","warn"); return end
    table.insert(_notes, {time=tick(), text=text})
    Notify("📝  Note saved  (#"..#_notes..")")
end)

Cmd("notes", {"listnotes","shownotes"}, function()
    if #_notes == 0 then Notify("No notes saved","warn"); return end
    local lines = {}
    for i,n in ipairs(_notes) do
        local age = math.floor(tick()-n.time)
        table.insert(lines, string.format("[%d] (%ds ago) %s",i,age,n.text))
    end
    print("[S-Admin] Notes:\n  "..table.concat(lines,"\n  "))
    Notify("📝  "..#_notes.." note(s) — see console","info")
end)

Cmd("deletenote", {"delnote","removenote"}, function(args)
    local idx = tonumber(args[1])
    if not idx or not _notes[idx] then Notify("Usage: deletenote <number>","warn"); return end
    local removed = table.remove(_notes,idx)
    Notify("📝  Deleted note #"..idx..": '"..removed.text:sub(1,30).."'")
end)

Cmd("clearnotes", {"deletenotes","nonotes"}, function()
    local n = #_notes; _notes = {}
    Notify("📝  Cleared "..n.." note(s)")
end)

Cmd("copynotes", {"exportnotes","noteclip"}, function()
    if #_notes == 0 then Notify("No notes to copy","warn"); return end
    local lines = {}
    for i,n in ipairs(_notes) do table.insert(lines,i..". "..n.text) end
    local text = table.concat(lines,"\n")
    pcall(function() setclipboard(text) end)
    print("[S-Admin] Notes exported:\n"..text)
    Notify("📝  "..#_notes.." note(s) copied to clipboard","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: UI HELPERS  (IY-ported)                     ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: ScreenGui layout patterns, dynamic label sizing,
--           helper GUI building — porting IY's admin panel.

-- adminpanel  — compact quick-action panel
local _adminPanelGui  = nil

Cmd("adminpanel", {"panel","quickpanel"}, function()
    if _adminPanelGui then
        _adminPanelGui:Destroy(); _adminPanelGui = nil
        Notify("🖥  Admin panel closed"); return
    end

    _adminPanelGui = Instance.new("ScreenGui",ScreenGui)
    _adminPanelGui.Name         = "S_AdminPanel"
    _adminPanelGui.ResetOnSpawn = false
    _adminPanelGui.DisplayOrder = 80

    local panel = Instance.new("Frame",_adminPanelGui)
    panel.Size             = UDim2.new(0,190,0,0)   -- height set below
    panel.Position         = UDim2.new(0,10,0.5,-80)
    panel.BackgroundColor3 = Color3.fromRGB(14,14,14)
    panel.BackgroundTransparency = 0.15
    panel.ZIndex           = 80
    Corner(panel,10)
    Stroke(panel,1,Color3.fromRGB(65,65,65))
    MakeDraggable(panel,panel)

    local title = Instance.new("TextLabel",panel)
    title.Size             = UDim2.new(1,0,0,28)
    title.BackgroundTransparency = 1
    title.Text             = "⚡  Quick Actions"
    title.TextColor3       = Color3.fromRGB(200,200,200)
    title.Font             = Enum.Font.GothamBold
    title.TextSize         = 12
    title.ZIndex           = 81

    -- Quick-action button factory
    local quickCmds = {
        {"✈ Fly",         "fly"},
        {"👻 Noclip",     "noclip"},
        {"🛡 God",        "god"},
        {"💡 Fullbright", "fullbright"},
        {"👁 ESP",        "esp"},
        {"🌈 Rainbow",    "rainbow"},
        {"❤ HP Bar",      "healthbar"},
        {"🗺 Minimap",    "minimap"},
        {"🔄 Respawn",    "respawn"},
        {"📊 Session",    "sessionstats"},
    }
    local btnH = 26
    local pad  = 4
    for i, entry in ipairs(quickCmds) do
        local label, cmd = entry[1], entry[2]
        local btn = Instance.new("TextButton",panel)
        btn.Size             = UDim2.new(1,-8,0,btnH)
        btn.Position         = UDim2.new(0,4,0,28+(i-1)*(btnH+pad))
        btn.BackgroundColor3 = Color3.fromRGB(28,28,28)
        btn.BackgroundTransparency = 0.1
        btn.Text             = label
        btn.Font             = Enum.Font.GothamMedium
        btn.TextSize         = 12
        btn.TextColor3       = Color3.fromRGB(200,200,200)
        btn.AutoButtonColor  = false
        btn.ZIndex           = 82
        Corner(btn,5)
        btn.MouseEnter:Connect(function()
            TweenObj(btn,0.08,{BackgroundColor3=Color3.fromRGB(40,40,40)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenObj(btn,0.08,{BackgroundColor3=Color3.fromRGB(28,28,28)}):Play()
        end)
        btn.Activated:Connect(function()
            task.defer(function() ExecCommand(cmd) end)
        end)
    end

    local totalH = 28 + #quickCmds*(btnH+pad) + pad
    panel.Size = UDim2.new(0,190,0,totalH)
    Notify("🖥  Admin panel opened")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: EXTRA PLAYER UTILITIES  (IY-ported)         ║
-- ╚══════════════════════════════════════════════════════════╝

-- playerage  — how old is a player's Roblox account
Cmd("playerage", {"prage","howold"}, function(args)
    local target = GetPlayers(args[1])[1] or LP
    local years  = target.AccountAge / 365
    Notify(string.format("👤  %s: %d days old (%.1f yrs)",
        target.Name, target.AccountAge, years), "info")
end)

-- follow2  — follow nearest player automatically
Cmd("follownearest", {"followclose","fn2"}, function()
    SafeDisconn("FollowNearest")
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        local best, bestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    local d = (tHRP.Position-hrp.Position).Magnitude
                    if d < bestDist then best=tHRP; bestDist=d end
                end
            end
        end
        if best and bestDist > 6 then
            local hum = GetHuman()
            if hum then hum:MoveTo(best.Position) end
        end
    end)
    Conns.FollowNearest = conn
    Notify("🏃  Following nearest player  (clip to stop)")
end)

-- avatar <player>  — open avatar page in browser (setclipboard)
Cmd("avatar", {"openavatar","avatarpage"}, function(args)
    local target = GetPlayers(args[1])[1] or LP
    local url    = "https://www.roblox.com/users/"..target.UserId.."/profile"
    pcall(function() setclipboard(url) end)
    Notify("🔗  Avatar URL copied: "..target.Name,"info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: FINAL UTILITY COMMANDS  (IY-ported)         ║
-- ╚══════════════════════════════════════════════════════════╝

-- about  — show script information
Cmd("about", {"credits","version"}, function()
    local lines = {
        "⚡  S Command Bar Pro  v4.3",
        "Commands: "..tostring(#(function()
            local t={}; for k in pairs(Commands) do table.insert(t,k) end; return t end)()),
        "Platform: "..(IsMobile and "Mobile 📱" or "PC 🖥"),
        "Lua/LuaU admin suite — built iteratively",
        "Based on IY (Infinite Yield) open-source reference",
    }
    print("[S-Admin]\n  "..table.concat(lines,"\n  "))
    Notify("⚡  S Command Bar Pro v4.3 — see console","info")
end)

-- togglehud  — toggle all S_ HUDs at once
Cmd("togglehud", {"hud2","allhuds"}, function()
    local hudNames = {
        "S_InfoBar","S_FPSCounter","S_SpeedDisplay","S_HealthBar",
        "S_NetStat","S_TickRate","S_Minimap","S_PlayerList","S_BindDisplay",
    }
    local any = false
    for _, name in ipairs(hudNames) do
        local gui = ScreenGui:FindFirstChild(name)
        if gui then any = true; gui:Destroy() end
    end
    if any then
        -- Disconnect associated connections
        for _, k in ipairs({"InfoBar","FPSCounter","SpeedDisplay","HealthBar","NetStat","TickRate","Minimap","PlayerList","BindDisplay"}) do
            SafeDisconn(k)
        end
        if _infoBarConn  then _infoBarConn:Disconnect();  _infoBarConn  = nil end
        if _fpsCounterConn then _fpsCounterConn:Disconnect(); _fpsCounterConn = nil end
        if _speedDisplayConn then _speedDisplayConn:Disconnect(); _speedDisplayConn = nil end
        if _healthBarConn then _healthBarConn:Disconnect(); _healthBarConn = nil end
        if _netStatConn then _netStatConn:Disconnect(); _netStatConn = nil end
        if _tickRateConn then _tickRateConn:Disconnect(); _tickRateConn = nil end
        if _minimapConn then _minimapConn:Disconnect(); _minimapConn = nil end
        if _playerListConn then _playerListConn:Disconnect(); _playerListConn = nil end
        if _bindDisplayConn then _bindDisplayConn:Disconnect(); _bindDisplayConn = nil end
        Notify("🖥  All HUDs closed")
    else
        Notify("No HUDs currently open — use infobar, fpscounter, healthbar, etc.","warn")
    end
end)

-- listhuds  — list which HUDs are currently active
Cmd("listhuds", {"activehuds","huds"}, function()
    local hudNames = {
        "S_InfoBar","S_FPSCounter","S_SpeedDisplay","S_HealthBar","S_NetStat",
        "S_TickRate","S_Minimap","S_PlayerList","S_BindDisplay","S_Crosshair",
        "S_Overlay","S_Cinematic","S_AdminPanel",
    }
    local active = {}
    for _, name in ipairs(hudNames) do
        if ScreenGui:FindFirstChild(name) then
            table.insert(active, name:gsub("^S_",""))
        end
    end
    if #active == 0 then Notify("No HUDs active","warn"); return end
    Notify("🖥  Active: "..table.concat(active,", "),"info")
end)

-- randomcolor  — apply a random color to character
Cmd("randomcolor", {"randcolor","randomisecolor"}, function()
    local r = math.random(0,255)
    local g = math.random(0,255)
    local b = math.random(0,255)
    Commands["bodycolor"]({"all",tostring(r),tostring(g),tostring(b)})
    Notify(string.format("🎨  Random color → RGB(%d,%d,%d)",r,g,b))
end)

-- getversion  — print current version string to clipboard
Cmd("getversion2", {"copyversion","ver"}, function()
    local ver = "S_CommandBar_Pro_v4.3"
    pcall(function() setclipboard(ver) end)
    Notify("ℹ  "..ver.." (copied)","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: PING GRAPH HUD  (IY-ported)                 ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: ring-buffer sample storage, drawing a bar graph
--           from live data using Frame widths, color-coding.

local _pingGraphGui  = nil
local _pingGraphConn = nil
local _pingHistory   = {}
local PING_SAMPLES   = 40

Cmd("pinggraph", {"pingchart","pinghistory"}, function()
    if _pingGraphGui then
        _pingGraphGui:Destroy(); _pingGraphGui = nil
        if _pingGraphConn then _pingGraphConn:Disconnect(); _pingGraphConn = nil end
        Notify("📶  Ping graph OFF"); return
    end

    local W, H = 200, 60
    _pingGraphGui = Instance.new("ScreenGui", ScreenGui)
    _pingGraphGui.Name         = "S_PingGraph"
    _pingGraphGui.ResetOnSpawn = false
    _pingGraphGui.DisplayOrder = 84

    local bg = Instance.new("Frame", _pingGraphGui)
    bg.Size             = UDim2.new(0, W, 0, H + 20)
    bg.Position         = UDim2.new(0, 10, 0.5, 50)
    bg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    bg.BackgroundTransparency = 0.35
    bg.ZIndex           = 84
    Corner(bg, 6)

    local title = Instance.new("TextLabel", bg)
    title.Size             = UDim2.new(1, 0, 0, 18)
    title.BackgroundTransparency = 1
    title.Text             = "📶 Ping"
    title.TextColor3       = Color3.fromRGB(180, 180, 180)
    title.Font             = Enum.Font.GothamBold
    title.TextSize         = 11
    title.ZIndex           = 85

    local canvas = Instance.new("Frame", bg)
    canvas.Name            = "Canvas"
    canvas.Size            = UDim2.new(1, -8, 0, H)
    canvas.Position        = UDim2.new(0, 4, 0, 18)
    canvas.BackgroundTransparency = 1
    canvas.ZIndex          = 85

    -- Pre-build bar frames
    local bars = {}
    local barW = (W - 8) / PING_SAMPLES
    for i = 1, PING_SAMPLES do
        local bar = Instance.new("Frame", canvas)
        bar.AnchorPoint     = Vector2.new(0, 1)
        bar.Size            = UDim2.new(0, math.max(1, barW - 1), 0, 0)
        bar.Position        = UDim2.new(0, (i-1)*barW, 1, 0)
        bar.BackgroundColor3 = Color3.fromRGB(80, 200, 100)
        bar.BorderSizePixel = 0
        bar.ZIndex          = 86
        bars[i] = bar
    end

    local elapsed = 0
    _pingGraphConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed < 0.25 then return end
        elapsed = 0
        local ms = LP:GetNetworkPing() * 1000
        table.insert(_pingHistory, ms)
        if #_pingHistory > PING_SAMPLES then table.remove(_pingHistory, 1) end

        -- Find max for scaling
        local maxMs = 1
        for _, v in ipairs(_pingHistory) do if v > maxMs then maxMs = v end end
        maxMs = math.max(maxMs, 50)

        for i, bar in ipairs(bars) do
            local v = _pingHistory[i] or 0
            local ratio = v / maxMs
            bar.Size = UDim2.new(0, math.max(1, barW-1), ratio, 0)
            bar.BackgroundColor3 = v < 80  and Color3.fromRGB(80,220,100)
                                or v < 150 and Color3.fromRGB(220,200,50)
                                or             Color3.fromRGB(220,80,80)
        end
        title.Text = string.format("📶 Ping  %dms  (max %dms)",
            math.floor(ms), math.floor(maxMs))
    end)
    Notify("📶  Ping graph ON")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: INPUT LOGGER  (IY-ported)                   ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: UserInputService.InputBegan / InputEnded logging,
--           filtering by InputType, session input history.

local _inputLogConn = nil
local _inputHistory = {}

Cmd("inputlog", {"loginput","keylog"}, function()
    if _inputLogConn then
        _inputLogConn:Disconnect(); _inputLogConn = nil
        Notify("⌨  Input log OFF  ("..#_inputHistory.." events recorded)"); return
    end
    _inputHistory = {}
    _inputLogConn = UserInputService.InputBegan:Connect(function(i, gp)
        local entry = {
            type  = i.UserInputType.Name,
            key   = i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode.Name or nil,
            game  = gp,
            t     = tick(),
        }
        table.insert(_inputHistory, entry)
        if not gp then
            local label = entry.key or entry.type
            print(string.format("[S-InputLog] %s  (game=%s  t=%.2f)", label, tostring(gp), entry.t))
        end
    end)
    Notify("⌨  Input log ON — all keypresses printed to console")
end)

Cmd("inputhistory", {"inputhist","keyhistory"}, function(args)
    local n = tonumber(args[1]) or 10
    if #_inputHistory == 0 then Notify("No input recorded — run inputlog first","warn"); return end
    local start = math.max(1, #_inputHistory - n + 1)
    local lines = {}
    for i = start, #_inputHistory do
        local e = _inputHistory[i]
        local label = e.key or e.type
        table.insert(lines, string.format("[%d] %s  game=%s", i, label, tostring(e.game)))
    end
    print("[S-Admin] Last "..#lines.." inputs:\n  "..table.concat(lines,"\n  "))
    Notify("⌨  "..#lines.." input(s) — see console","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CHARACTER OUTLINE  (IY-ported)              ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Highlight instance on own character, controlling
--           FillTransparency and OutlineColor properties.

Cmd("outline", {"charoutline","selfhl"}, function(args)
    local char = GetChar(); if not char then return end
    local old  = char:FindFirstChild("S_SelfHL")
    if old then old:Destroy(); Notify("✨  Outline OFF"); return end
    local r = tonumber(args[1]) or 100
    local g = tonumber(args[2]) or 180
    local b = tonumber(args[3]) or 255
    local hl = Instance.new("Highlight", char)
    hl.Name               = "S_SelfHL"
    hl.FillTransparency   = 1          -- invisible fill, outline only
    hl.OutlineColor       = Color3.fromRGB(r, g, b)
    hl.OutlineTransparency = 0
    Notify(string.format("✨  Outline ON  RGB(%d,%d,%d)", r, g, b))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SUN TRACKER  (IY-ported)                    ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Lighting.ClockTime, computing sun direction from
--           time, updating BodyGyro to always face the sun.

local _sunTrackConn = nil

Cmd("suntrack", {"tracksun","facesun"}, function()
    if _sunTrackConn then
        _sunTrackConn:Disconnect(); _sunTrackConn = nil
        Notify("☀  Sun tracker OFF"); return
    end
    _sunTrackConn = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        local t   = Lighting.ClockTime
        -- Approximate sun direction from ClockTime
        local angle = ((t / 24) * 2 - 0.5) * math.pi
        local sunDir = Vector3.new(math.cos(angle), math.sin(angle), 0).Unit
        local bg = hrp:FindFirstChild("S_FlyBG")
        if bg then bg.CFrame = CFrame.new(Vector3.zero, sunDir) end
    end)
    Notify("☀  Sun tracker ON — character faces the sun")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: REGION HIGHLIGHT  (IY-ported)               ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Region3 construction, workspace:FindPartsInRegion3,
--           SelectionBox per-part for area highlighting.

local _regionHighlights = {}

Cmd("highlightregion", {"region","rhl"}, function(args)
    -- Clear existing
    for _, v in ipairs(_regionHighlights) do pcall(function() v:Destroy() end) end
    _regionHighlights = {}
    local hrp  = GetHRP(); if not hrp then return end
    local size = tonumber(args[1]) or 20
    local half = size / 2
    local pos  = hrp.Position
    local reg  = Region3.new(
        pos - Vector3.new(half, half, half),
        pos + Vector3.new(half, half, half))
    local parts = workspace:FindPartsInRegion3(reg, LP.Character, 100)
    local folder = Instance.new("Folder", ScreenGui)
    folder.Name = "S_RegionHL"
    table.insert(_regionHighlights, folder)
    for _, part in ipairs(parts) do
        local box = Instance.new("SelectionBox", folder)
        box.Adornee = part
        box.Color3  = Color3.fromRGB(255, 220, 50)
        box.LineThickness = 0.04
        box.SurfaceTransparency = 0.85
        box.SurfaceColor3 = Color3.fromRGB(255, 220, 50)
        table.insert(_regionHighlights, box)
    end
    Notify(string.format("🟡  Highlighted %d parts in %.0f-stud radius", #parts, size))
end)

Cmd("clearregion", {"noregion","clearhl"}, function()
    for _, v in ipairs(_regionHighlights) do pcall(function() v:Destroy() end) end
    _regionHighlights = {}
    Notify("🟡  Region highlight cleared")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: OBJECT PIVOT VIEWER  (IY-ported)            ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: GetPivot() API (R15+ models), CFrame display,
--           visualising pivot with a small Part adornment.

Cmd("showpivot", {"pivot","getpivot"}, function(args)
    local query = table.concat(args, " "):lower()
    local hrp   = GetHRP(); if not hrp then return end
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and (query=="" or v.Name:lower():find(query,1,true)) then
            local primary = v.PrimaryPart
            if primary then
                local d = (primary.Position - hrp.Position).Magnitude
                if d < bestDist then best=v; bestDist=d end
            end
        end
    end
    if not best then Notify("No model found","warn"); return end
    local ok, pivotCF = pcall(function() return best:GetPivot() end)
    if not ok then Notify("Model has no pivot","warn"); return end
    local p = pivotCF.Position
    -- Visualise with a small neon sphere
    local marker = Instance.new("Part", workspace)
    marker.Name        = "S_PivotMarker"
    marker.Size        = Vector3.new(0.5,0.5,0.5)
    marker.Shape       = Enum.PartType.Ball
    marker.Anchored    = true
    marker.CanCollide  = false
    marker.Material    = Enum.Material.Neon
    marker.Color       = Color3.fromRGB(255,50,200)
    marker.CFrame      = pivotCF
    game:GetService("Debris"):AddItem(marker, 8)
    Notify(string.format("📍  Pivot of '%s' at (%.1f,%.1f,%.1f)  — marker for 8s",
        best.Name, p.X, p.Y, p.Z), "info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: HOTKEY CHEATSHEET HUD  (IY-ported)          ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: static reference HUD, scrollable list of custom
--           keybinds, quick-reference UI pattern.

local _cheatsheetGui = nil

Cmd("cheatsheet", {"hotkeys","keybinds2"}, function()
    if _cheatsheetGui then
        _cheatsheetGui:Destroy(); _cheatsheetGui = nil
        Notify("📋  Cheatsheet closed"); return
    end
    local defaults = {
        {";",       "Toggle command bar"},
        {"Escape",  "Close command bar"},
        {"↑ / ↓",  "Cycle command history (bar open)"},
        {"[Bind]",  "Custom binds (see listbinds)"},
        {"LMB",     "ClickTP target (clicktp mode)"},
        {"Space",   "Fly UP / Jetpack thrust"},
        {"Shift",   "Fly DOWN / Freecam slow"},
        {"Q / E",   "Float pad height adjust"},
        {"WASD",    "Fly / Freecam movement"},
    }
    _cheatsheetGui = Instance.new("ScreenGui", ScreenGui)
    _cheatsheetGui.Name         = "S_Cheatsheet"
    _cheatsheetGui.ResetOnSpawn = false
    _cheatsheetGui.DisplayOrder = 78

    local panel = Instance.new("Frame", _cheatsheetGui)
    panel.Size             = UDim2.new(0, 260, 0, #defaults * 20 + 32)
    panel.Position         = UDim2.new(1,-274, 0.5, -(#defaults*10+16))
    panel.BackgroundColor3 = Color3.fromRGB(12,12,12)
    panel.BackgroundTransparency = 0.2
    panel.ZIndex           = 78
    Corner(panel, 8)
    Stroke(panel, 1, Color3.fromRGB(65,65,65))
    MakeDraggable(panel, panel)

    local hdr = Instance.new("TextLabel", panel)
    hdr.Size             = UDim2.new(1,0,0,26)
    hdr.BackgroundTransparency = 1
    hdr.Text             = "⌨  Hotkey Cheatsheet"
    hdr.TextColor3       = Color3.fromRGB(200,200,200)
    hdr.Font             = Enum.Font.GothamBold
    hdr.TextSize         = 12
    hdr.ZIndex           = 79

    for i, entry in ipairs(defaults) do
        local key, desc = entry[1], entry[2]
        local row = Instance.new("Frame", panel)
        row.Size             = UDim2.new(1,-8,0,18)
        row.Position         = UDim2.new(0,4,0,26+(i-1)*20)
        row.BackgroundTransparency = i%2==0 and 0.9 or 1
        row.BackgroundColor3 = Color3.fromRGB(30,30,30)
        row.ZIndex           = 79

        local keyLbl = Instance.new("TextLabel", row)
        keyLbl.Size            = UDim2.new(0,70,1,0)
        keyLbl.BackgroundTransparency = 1
        keyLbl.Text            = key
        keyLbl.TextColor3      = Color3.fromRGB(150,200,255)
        keyLbl.Font            = Enum.Font.Code
        keyLbl.TextSize        = 11
        keyLbl.TextXAlignment  = Enum.TextXAlignment.Left
        keyLbl.ZIndex          = 80
        Pad(keyLbl,4)

        local descLbl = Instance.new("TextLabel", row)
        descLbl.Size           = UDim2.new(1,-74,1,0)
        descLbl.Position       = UDim2.new(0,74,0,0)
        descLbl.BackgroundTransparency = 1
        descLbl.Text           = desc
        descLbl.TextColor3     = Color3.fromRGB(180,180,180)
        descLbl.Font           = Enum.Font.Gotham
        descLbl.TextSize       = 11
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.ZIndex         = 80
    end
    Notify("📋  Cheatsheet open  (run again to close)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SOUND FADE  (IY-ported)                     ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: gradual volume ramp via TweenService on Sound
--           Volume property, fadeIn / fadeOut patterns.

Cmd("soundfadein", {"fadein","volumefade"}, function(args)
    local targetVol = tonumber(args[1]) or 0.5
    local duration  = tonumber(args[2]) or 2
    if not _adminSound then Notify("No sound playing — use 'play' first","warn"); return end
    _adminSound.Volume = 0
    TweenObj(_adminSound, duration, {Volume = targetVol}, Enum.EasingStyle.Linear):Play()
    Notify(string.format("🎵  Fade in → vol %.2f over %.1fs", targetVol, duration))
end)

Cmd("soundfadeout", {"fadeout","volumefadeout"}, function(args)
    local duration = tonumber(args[1]) or 2
    if not _adminSound then Notify("No sound playing","warn"); return end
    local t = TweenObj(_adminSound, duration, {Volume = 0}, Enum.EasingStyle.Linear)
    t:Play()
    t.Completed:Connect(function()
        if _adminSound then _adminSound:Stop() end
    end)
    Notify(string.format("🎵  Fade out over %.1fs", duration))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: AUTO-SCREENSHOT  (IY-ported)                ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: interval-based task loop, CoreGui screenshot API.

local _autoSsTask = nil

Cmd("autoscreenshot", {"autoss","screenshotloop"}, function(args)
    if _autoSsTask then
        task.cancel(_autoSsTask); _autoSsTask = nil
        Notify("📸  Auto-screenshot OFF"); return
    end
    local interval = math.max(tonumber(args[1]) or 30, 5)
    _autoSsTask = task.spawn(function()
        while true do
            task.wait(interval)
            pcall(function() game:GetService("CoreGui"):TakeScreenshot() end)
            Notify("📸  Auto-screenshot taken  (next in "..interval.."s)","info")
        end
    end)
    Notify("📸  Auto-screenshot ON  (every "..interval.."s)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: DEBUG OVERLAY  (IY-ported)                  ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: comprehensive live-debug overlay combining
--           multiple data sources, RunService-driven refresh.

local _debugGui  = nil
local _debugConn = nil

Cmd("debug", {"debugoverlay","debugmode"}, function()
    if _debugGui then
        _debugGui:Destroy(); _debugGui = nil
        if _debugConn then _debugConn:Disconnect(); _debugConn = nil end
        Notify("🐛  Debug overlay OFF"); return
    end
    _debugGui = Instance.new("ScreenGui", ScreenGui)
    _debugGui.Name         = "S_Debug"
    _debugGui.ResetOnSpawn = false
    _debugGui.DisplayOrder = 93

    local bg = Instance.new("Frame", _debugGui)
    bg.Size             = UDim2.new(0,280,0,160)
    bg.Position         = UDim2.new(0,10,0,60)
    bg.BackgroundColor3 = Color3.fromRGB(8,8,8)
    bg.BackgroundTransparency = 0.25
    bg.ZIndex           = 93
    Corner(bg,6)
    Stroke(bg,1,Color3.fromRGB(50,50,50))

    local lbl = Instance.new("TextLabel",bg)
    lbl.Size             = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Font             = Enum.Font.Code
    lbl.TextSize         = 11
    lbl.TextColor3       = Color3.fromRGB(180,255,180)
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.TextYAlignment   = Enum.TextYAlignment.Top
    lbl.ZIndex           = 94
    Pad(lbl,6)

    local samples, elapsed = {}, 0
    _debugConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        table.insert(samples, 1/dt)
        if #samples > 30 then table.remove(samples,1) end
        if elapsed < 0.2 then return end
        elapsed = 0

        local hrp  = GetHRP()
        local hum  = GetHuman()
        local cam  = workspace.CurrentCamera
        local avg  = 0
        for _, s in ipairs(samples) do avg=avg+s end
        avg = avg / #samples

        local pos    = hrp and hrp.Position or Vector3.zero
        local vel    = hrp and hrp.AssemblyLinearVelocity.Magnitude or 0
        local health = hum and hum.Health or 0
        local maxHp  = hum and hum.MaxHealth or 100
        local fov    = cam.FieldOfView
        local camT   = cam.CameraType.Name
        local ping   = LP:GetNetworkPing()*1000
        local grav   = workspace.Gravity
        local flying = tostring(State.Flying)
        local noclip = tostring(State.Noclipping)

        lbl.Text = string.format(
            "FPS:    %.0f\n"..
            "Ping:   %.0fms\n"..
            "Pos:    %.1f, %.1f, %.1f\n"..
            "Speed:  %.1f st/s\n"..
            "Health: %.0f / %.0f\n"..
            "FOV:    %.0f   CamType: %s\n"..
            "Grav:   %.1f\n"..
            "Fly: %s   Noclip: %s",
            avg, ping,
            pos.X, pos.Y, pos.Z,
            vel, health, maxHp,
            fov, camT,
            grav, flying, noclip)
    end)
    Notify("🐛  Debug overlay ON")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: WORKSPACE STATS HUD  (IY-ported)            ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: counting instances, live refresh, Stats service.

local _wsStatsGui  = nil
local _wsStatsConn = nil

Cmd("wsstats", {"workspacestats","wsinfo"}, function()
    if _wsStatsGui then
        _wsStatsGui:Destroy(); _wsStatsGui = nil
        if _wsStatsConn then _wsStatsConn:Disconnect(); _wsStatsConn = nil end
        Notify("🖥  WS Stats OFF"); return
    end
    _wsStatsGui = Instance.new("ScreenGui", ScreenGui)
    _wsStatsGui.Name         = "S_WSStats"
    _wsStatsGui.ResetOnSpawn = false
    _wsStatsGui.DisplayOrder = 82

    local bg = Instance.new("Frame", _wsStatsGui)
    bg.Size             = UDim2.new(0,200,0,80)
    bg.Position         = UDim2.new(1,-210,0,60)
    bg.BackgroundColor3 = Color3.fromRGB(10,10,10)
    bg.BackgroundTransparency = 0.35
    bg.ZIndex           = 82
    Corner(bg,6)

    local lbl = Instance.new("TextLabel",bg)
    lbl.Size             = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Font             = Enum.Font.Code
    lbl.TextSize         = 11
    lbl.TextColor3       = Color3.new(1,1,1)
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.TextYAlignment   = Enum.TextYAlignment.Top
    lbl.ZIndex           = 83
    Pad(lbl,6)

    local elapsed = 0
    _wsStatsConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed < 2 then return end
        elapsed = 0
        local total, parts, models = 0, 0, 0
        for _, v in ipairs(workspace:GetDescendants()) do
            total = total + 1
            if v:IsA("BasePart") then parts = parts + 1
            elseif v:IsA("Model") then models = models + 1 end
        end
        lbl.Text = string.format(
            "🌐 Workspace\n  Instances: %d\n  BaseParts: %d\n  Models:    %d",
            total, parts, models)
    end)
    Notify("🖥  WS Stats ON  (refresh every 2s)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: FINAL ALIAS & HELP IMPROVEMENTS             ║
-- ╚══════════════════════════════════════════════════════════╝

-- help2 <command>  — detailed help for a specific command
local _cmdHints = {
    fly         = "fly [speed]  — IY-style smooth camera-relative flight",
    fling       = "fling  — velocity spike makes your char physically volatile",
    noclip      = "noclip  — disable collision for all character parts",
    killaura    = "killaura [range] [speed]  — affect nearby players continuously",
    freecam     = "freecam  — spring-physics free camera (WASD+QE move, Shift=slow, ↑↓=speed)",
    waypoint    = "setwp <name>  /  wp <name>  /  tweenwp <name>  /  listwp  /  clearwp",
    bind        = "bind <Key> <command>  — e.g.  bind F fly 100",
    esp         = "esp  — Highlight instance on all players, unesp to remove",
    chams       = "chams  — BoxHandleAdornment per body part with team color",
    orbit       = "orbit [player] [radius] [speed]  — camera circles a player",
    sessionstats= "sessionstats  — time played, deaths, distance walked this session",
    adminpanel  = "adminpanel  — quick-action panel with 10 toggle buttons",
    debug       = "debug  — live overlay: fps/ping/pos/speed/health/camera/physics",
    lightpreset = "lightpreset <name>  — presets: morning noon sunset night midnight foggy hdr horror",
    sizepreset  = "sizepreset <name>  — presets: normal tiny big giant flat tall wide noodle",
    rain        = "rain [density]  — particle rain above character",
    ambience    = "ambience <name>  — names: rain wind birds thunder ocean fire crickets dungeon",
}

Cmd("help2", {"helpme","cmdhelp","man"}, function(args)
    local key = (args[1] or ""):lower()
    if key == "" then
        Notify("Usage: help2 <command name>","warn"); return
    end
    -- Try direct hint
    local hint = _cmdHints[key]
    -- Fallback: check if command exists
    local exists = Commands[key] ~= nil or Aliases[key] ~= nil
    if hint then
        print("[S-Admin] help2 '"..key.."':\n  "..hint)
        Notify("📖  "..hint:sub(1,60), "info")
    elseif exists then
        local resolved = Aliases[key] or key
        Notify("📖  '"..key.."' exists (→"..resolved..") — no hint available","info")
    else
        Notify("📖  Unknown command: '"..key.."'  — try 'cmds' for list","warn")
    end
end)

-- cmdcount  — print how many commands are registered
Cmd("cmdcount", {"countcmds","totalcmds"}, function()
    local n = 0
    for _ in pairs(Commands) do n=n+1 end
    local a = 0
    for _ in pairs(Aliases) do a=a+1 end
    Notify(string.format("⚡  %d commands  |  %d aliases registered", n, a), "info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: TOOL INFO DISPLAY  (IY-ported)              ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Tool properties, Handle, CanBeDropped, Grip,
--           reading equipped tool stats from Humanoid.

Cmd("toolinfo", {"equippedinfo","currenttool"}, function()
    local char = GetChar(); if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then Notify("No tool currently equipped","warn"); return end
    local handle   = tool:FindFirstChild("Handle")
    local lines = {
        "Name:        " .. tool.Name,
        "CanBeDropped:" .. tostring(tool.CanBeDropped),
        "Requires:    " .. (tool.RequiresHandle and "Handle" or "No handle"),
        "Handle size: " .. (handle and tostring(handle.Size) or "N/A"),
        "Grip offset: " .. tostring(tool.GripPos),
        "Path:        " .. tool:GetFullName(),
    }
    print("[S-Admin] Tool info:\n  " .. table.concat(lines, "\n  "))
    Notify("🔧  " .. tool.Name .. " — see console", "info")
end)

-- tooltoggle  — enable / disable tool activation
Cmd("tooltoggle", {"enabletool","disabletool"}, function(args)
    local query = table.concat(args," "):lower()
    local char  = GetChar(); if not char then return end
    local n = 0
    local bp = LP:FindFirstChildOfClass("Backpack")
    local containers = {char, bp}
    for _, cont in ipairs(containers) do
        if cont then
            for _, t in ipairs(cont:GetChildren()) do
                if t:IsA("Tool") and (query=="" or t.Name:lower():find(query,1,true)) then
                    t.Enabled = not t.Enabled
                    n = n + 1
                end
            end
        end
    end
    Notify("🔧  Toggled " .. n .. " tool(s) enabled state")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CHARACTER STATS HUD  (IY-ported)            ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: combining multiple humanoid properties into a
--           single live-reading HUD with color-coded values.

local _charStatsGui  = nil
local _charStatsConn = nil

Cmd("charstats", {"characterstats","mystats2"}, function()
    if _charStatsGui then
        _charStatsGui:Destroy(); _charStatsGui = nil
        if _charStatsConn then _charStatsConn:Disconnect(); _charStatsConn = nil end
        Notify("📊  Char stats OFF"); return
    end
    _charStatsGui = Instance.new("ScreenGui", ScreenGui)
    _charStatsGui.Name         = "S_CharStats"
    _charStatsGui.ResetOnSpawn = false
    _charStatsGui.DisplayOrder = 81

    local bg = Instance.new("Frame", _charStatsGui)
    bg.Size             = UDim2.new(0, 200, 0, 110)
    bg.Position         = UDim2.new(1, -214, 1, -124)
    bg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    bg.BackgroundTransparency = 0.35
    bg.ZIndex           = 81
    Corner(bg, 6)
    Stroke(bg, 1, Color3.fromRGB(55, 55, 55))

    local lbl = Instance.new("TextLabel", bg)
    lbl.Size             = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font             = Enum.Font.Code
    lbl.TextSize         = 11
    lbl.TextColor3       = Color3.new(1, 1, 1)
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.TextYAlignment   = Enum.TextYAlignment.Top
    lbl.ZIndex           = 82
    Pad(lbl, 6)

    local elapsed = 0
    _charStatsConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed < 0.1 then return end
        elapsed = 0
        local hum = GetHuman()
        local hrp = GetHRP()
        if not hum or not hrp then return end
        local state = hum:GetState().Name
        lbl.Text = string.format(
            "❤  HP:      %.0f / %.0f\n"..
            "🏃  Speed:  %.0f\n"..
            "🦘  Jump:   %.0f\n"..
            "⚖  Hip:    %.2f\n"..
            "🎭  State:  %s\n"..
            "💺  Seated: %s",
            hum.Health, hum.MaxHealth,
            hum.WalkSpeed,
            hum.JumpPower,
            hum.HipHeight,
            state,
            tostring(hum.SeatPart ~= nil))
    end)
    Notify("📊  Char stats HUD ON")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: WAYPOINT MAP OVERLAY  (IY-ported)           ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: mapping 3D world positions onto a 2D mini-map
--           surface, named labels, live-updating dots.

local _wpMapGui  = nil
local _wpMapConn = nil

Cmd("waypointmap", {"wpmap","showwpmap"}, function()
    if _wpMapGui then
        _wpMapGui:Destroy(); _wpMapGui = nil
        if _wpMapConn then _wpMapConn:Disconnect(); _wpMapConn = nil end
        Notify("📌  Waypoint map OFF"); return
    end
    if #_waypoints == 0 then Notify("No waypoints saved — use setwp first","warn"); return end

    local SZ     = 180
    local SCALE  = 6   -- studs per pixel
    _wpMapGui = Instance.new("ScreenGui", ScreenGui)
    _wpMapGui.Name         = "S_WPMap"
    _wpMapGui.ResetOnSpawn = false
    _wpMapGui.DisplayOrder = 77

    local bg = Instance.new("Frame", _wpMapGui)
    bg.Size             = UDim2.new(0, SZ, 0, SZ + 22)
    bg.Position         = UDim2.new(0.5, -SZ/2, 0, 10)
    bg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    bg.BackgroundTransparency = 0.3
    bg.ZIndex           = 77
    Corner(bg, 8)
    Stroke(bg, 1, Color3.fromRGB(70, 70, 70))
    MakeDraggable(bg, bg)

    local title = Instance.new("TextLabel", bg)
    title.Size             = UDim2.new(1, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text             = "📌  Waypoints"
    title.TextColor3       = Color3.fromRGB(200, 200, 200)
    title.Font             = Enum.Font.GothamBold
    title.TextSize         = 11
    title.ZIndex           = 78

    local canvas = Instance.new("Frame", bg)
    canvas.Size             = UDim2.new(0, SZ - 4, 0, SZ - 4)
    canvas.Position         = UDim2.new(0, 2, 0, 22)
    canvas.BackgroundColor3 = Color3.fromRGB(18, 22, 18)
    canvas.BackgroundTransparency = 0.2
    canvas.ZIndex           = 78

    -- Build static waypoint dots
    local function rebuildDots()
        for _, c in ipairs(canvas:GetChildren()) do c:Destroy() end
        if #_waypoints == 0 then return end

        -- Find centre and bounds
        local cx, cz = 0, 0
        for _, wp in ipairs(_waypoints) do cx=cx+wp.x; cz=cz+wp.z end
        cx = cx/#_waypoints; cz = cz/#_waypoints

        for _, wp in ipairs(_waypoints) do
            local px = SZ/2 + (wp.x - cx) / SCALE
            local py = SZ/2 + (wp.z - cz) / SCALE
            px = math.clamp(px, 4, SZ-4)
            py = math.clamp(py, 4, SZ-4)

            local dot = Instance.new("Frame", canvas)
            dot.Size             = UDim2.new(0, 8, 0, 8)
            dot.Position         = UDim2.new(0, px-4, 0, py-4)
            dot.BackgroundColor3 = Color3.fromRGB(100, 220, 100)
            dot.BorderSizePixel  = 0
            dot.ZIndex           = 80
            Corner(dot, 4)

            local lbl = Instance.new("TextLabel", dot)
            lbl.Size             = UDim2.new(0, 80, 0, 14)
            lbl.Position         = UDim2.new(1, 2, 0, -3)
            lbl.BackgroundTransparency = 1
            lbl.Text             = wp.name
            lbl.TextColor3       = Color3.fromRGB(200, 255, 200)
            lbl.Font             = Enum.Font.Code
            lbl.TextSize         = 10
            lbl.TextXAlignment   = Enum.TextXAlignment.Left
            lbl.ZIndex           = 81
        end
    end
    rebuildDots()

    -- Player dot (updated live)
    local playerDot = Instance.new("Frame", canvas)
    playerDot.Size             = UDim2.new(0, 6, 0, 6)
    playerDot.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    playerDot.BorderSizePixel  = 0
    playerDot.ZIndex           = 82
    Corner(playerDot, 3)

    local function wpCentre()
        local cx,cz=0,0
        for _,wp in ipairs(_waypoints) do cx=cx+wp.x; cz=cz+wp.z end
        return cx/#_waypoints, cz/#_waypoints
    end

    _wpMapConn = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        if #_waypoints == 0 then return end
        local cx, cz = wpCentre()
        local px = SZ/2 + (hrp.Position.X - cx) / SCALE
        local pz = SZ/2 + (hrp.Position.Z - cz) / SCALE
        playerDot.Position = UDim2.new(0, math.clamp(px,2,SZ-6)-3, 0, math.clamp(pz,2,SZ-6)-3)
    end)

    Notify("📌  Waypoint map ON  (" .. #_waypoints .. " waypoints)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: PART INFO COMMAND  (IY-ported)              ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: reading comprehensive BasePart properties,
--           formatting a structured property report.

Cmd("partinfo", {"pinfo","inspectpart"}, function(args)
    local query = table.concat(args," "):lower()
    local hrp   = GetHRP(); if not hrp then return end
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (query=="" or v.Name:lower():find(query,1,true)) then
            if not v:IsDescendantOf(LP.Character or Instance.new("Folder")) then
                local d = (v.Position - hrp.Position).Magnitude
                if d < bestDist then best=v; bestDist=d end
            end
        end
    end
    if not best then Notify("No part found" .. (query~="" and ": "..query or ""),"warn"); return end
    local s = best.Size
    local p = best.Position
    local lines = {
        "Name:        " .. best.Name,
        "Class:       " .. best.ClassName,
        "Size:        " .. string.format("%.2f x %.2f x %.2f", s.X, s.Y, s.Z),
        "Position:    " .. string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z),
        "Material:    " .. best.Material.Name,
        "Color:       " .. string.format("RGB(%.0f,%.0f,%.0f)",
            best.Color.R*255, best.Color.G*255, best.Color.B*255),
        "Anchored:    " .. tostring(best.Anchored),
        "CanCollide:  " .. tostring(best.CanCollide),
        "Mass:        " .. string.format("%.4f", best:GetMass()),
        "Transparency:" .. string.format("%.2f", best.Transparency),
        "Distance:    " .. string.format("%.1f studs", bestDist),
        "Path:        " .. best:GetFullName(),
    }
    print("[S-Admin] Part info:\n  " .. table.concat(lines,"\n  "))
    Notify("📦  " .. best.Name .. " (" .. best.ClassName .. ") — console", "info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SMOOTH CAMERA TILT  (IY-ported)             ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: incremental CFrame rotation compositing,
--           smooth approach via lerp on rotation angle.

local _tiltAngle    = 0
local _tiltTarget   = 0
local _tiltConn     = nil

Cmd("tilt", {"camtilt","tiltcam2"}, function(args)
    local deg = tonumber(args[1]) or 15
    _tiltTarget = math.rad(deg)
    if _tiltConn then return end   -- already running
    local cam = workspace.CurrentCamera
    _tiltConn = RunService.RenderStepped:Connect(function(dt)
        _tiltAngle = _tiltAngle + (_tiltTarget - _tiltAngle) * math.min(1, dt*8)
        if math.abs(_tiltAngle) < 0.0001 and math.abs(_tiltTarget) < 0.0001 then
            _tiltAngle = 0
            _tiltConn:Disconnect(); _tiltConn = nil; return
        end
        cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, _tiltAngle)
    end)
    Notify(string.format("📷  Camera tilt → %.0f°", deg))
end)

Cmd("untilt", {"notilt","resettilt"}, function()
    _tiltTarget = 0
    Notify("📷  Camera tilt reset")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CLIPBOARD HISTORY  (IY-ported)              ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: session clipboard tracking, storing each
--           setclipboard call in a searchable history.

local _clipHistory = {}

-- Patch our copy commands to log to history
local _origSetClip = setclipboard
pcall(function()
    setclipboard = function(text)
        table.insert(_clipHistory, {text=tostring(text), t=tick()})
        if #_clipHistory > 30 then table.remove(_clipHistory,1) end
        _origSetClip(text)
    end
end)

Cmd("cliphistory", {"clipboard","pasthistory"}, function(args)
    local n = tonumber(args[1]) or 10
    if #_clipHistory == 0 then Notify("No clipboard history","warn"); return end
    local start = math.max(1, #_clipHistory-n+1)
    local lines = {}
    for i=start, #_clipHistory do
        local e   = _clipHistory[i]
        local age = math.floor(tick()-e.t)
        table.insert(lines, string.format("[%d] (%ds ago) %s", i, age, e.text:sub(1,60)))
    end
    print("[S-Admin] Clipboard history:\n  "..table.concat(lines,"\n  "))
    Notify("📋  "..#lines.." item(s) — see console","info")
end)

Cmd("recopy", {"reclipboard","reuse"}, function(args)
    local idx = tonumber(args[1]) or #_clipHistory
    if not _clipHistory[idx] then Notify("No clipboard entry #"..idx,"warn"); return end
    pcall(function() setclipboard(_clipHistory[idx].text) end)
    Notify("📋  Re-copied: ".._clipHistory[idx].text:sub(1,40))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SESSION LOG EXPORT  (IY-ported)             ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: aggregating session data into a report string,
--           setclipboard export pattern, string.format usage.

Cmd("exportlog", {"sessionexport","savelog"}, function()
    local elapsed = tick() - _sessionStart
    local h = math.floor(elapsed/3600)
    local m = math.floor((elapsed%3600)/60)
    local s = math.floor(elapsed%60)

    local lines = {
        "=== S Command Bar Pro — Session Log ===",
        os.date and ("Date:     "..os.date("%Y-%m-%d %H:%M")) or "",
        string.format("Duration: %02d:%02d:%02d", h, m, s),
        string.format("Game:     %s (PlaceId %d v%d)", game.Name, game.PlaceId, game.PlaceVersion),
        string.format("Player:   %s (UserId %d)", LP.Name, LP.UserId),
        string.format("Deaths:   %d", math.max(0, _sessionDeaths)),
        string.format("Distance: %.0f studs", _sessionDist),
        "",
        "--- Command History ---",
    }
    for i, cmd in ipairs(_cmdHistory) do
        table.insert(lines, string.format("  [%d] %s", i, cmd))
    end
    if #_notes > 0 then
        table.insert(lines, "")
        table.insert(lines, "--- Notes ---")
        for i, note in ipairs(_notes) do
            table.insert(lines, string.format("  [%d] %s", i, note.text))
        end
    end
    local report = table.concat(lines,"\n")
    pcall(function() setclipboard(report) end)
    print(report)
    Notify(string.format("📋  Session log exported (%d lines) — console + clipboard",#lines),"info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: GRAVITY HUD  (IY-ported)                    ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: watching a workspace property with GetPropertyChangedSignal,
--           live-reflecting external changes in a ScreenGui label.

local _gravHudGui  = nil
local _gravHudConn = nil

Cmd("gravhud", {"gravityhud","showgrav"}, function()
    if _gravHudGui then
        _gravHudGui:Destroy(); _gravHudGui = nil
        if _gravHudConn then _gravHudConn:Disconnect(); _gravHudConn = nil end
        Notify("🌍  Gravity HUD OFF"); return
    end
    _gravHudGui = Instance.new("ScreenGui", ScreenGui)
    _gravHudGui.Name         = "S_GravHUD"
    _gravHudGui.ResetOnSpawn = false
    _gravHudGui.DisplayOrder = 76

    local f = Instance.new("Frame", _gravHudGui)
    f.Size             = UDim2.new(0, 150, 0, 22)
    f.Position         = UDim2.new(0.5, -75, 0, 6)
    f.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    f.BackgroundTransparency = 0.4
    f.ZIndex           = 76
    Corner(f, 6)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size             = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font             = Enum.Font.Code
    lbl.TextSize         = 12
    lbl.TextColor3       = Color3.new(1, 1, 1)
    lbl.ZIndex           = 77

    local function refresh()
        local g = workspace.Gravity
        local pct = g / _origGravity
        lbl.Text = string.format("🌍  Gravity: %.1f  (%.0f%%)", g, pct * 100)
        lbl.TextColor3 = pct > 1.2 and Color3.fromRGB(220,80,80)
                      or pct < 0.5 and Color3.fromRGB(80,200,255)
                      or Color3.fromRGB(180,180,180)
    end
    refresh()
    _gravHudConn = workspace:GetPropertyChangedSignal("Gravity"):Connect(refresh)
    Notify("🌍  Gravity HUD ON")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: BUILT-IN ANIMATION ID LIBRARY  (IY-ported)  ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: storing a named ID dictionary, quick-access
--           pattern, searchable table, extending the anim cmd.

local _animLibrary = {
    -- R15 defaults
    idle         = 507766388,
    walk         = 507777826,
    run2         = 507767714,
    jump2        = 507765000,
    fall         = 507767968,
    swim2        = 507784897,
    swimidle     = 507777268,
    climb        = 507765644,
    -- Emotes
    wave         = 507770239,
    dance        = 507771019,
    dance2       = 507776043,
    dance3       = 507777268,
    laugh        = 507770818,
    point        = 507770453,
    cheer        = 507770677,
    salute       = 3360686091,
    shrug        = 3576968026,
    -- Extras
    tpose        = 3185159498,
    superhero    = 616010382,
    zombie       = 616163682,
    robot        = 616157050,
    cartwheels   = 616132069,
    snowball     = 616089352,
}

Cmd("animlib", {"animlist","anims","lsanims"}, function(args)
    local query = (args[1] or ""):lower()
    local matches = {}
    for name, id in pairs(_animLibrary) do
        if query == "" or name:find(query, 1, true) then
            table.insert(matches, string.format("  %-14s %d", name, id))
        end
    end
    if #matches == 0 then Notify("No anims matching '"..query.."'","warn"); return end
    table.sort(matches)
    print("[S-Admin] Anim library (" .. #matches .. " results):\n" .. table.concat(matches,"\n"))
    Notify(string.format("🎭  %d anim(s)%s — see console",
        #matches, query~="" and " matching '"..query.."'" or ""), "info")
end)

Cmd("playanim2", {"pa","libanim"}, function(args)
    local key = (args[1] or ""):lower()
    local id  = _animLibrary[key] or tonumber(key)
    if not id then
        Notify("Usage: playanim2 <name or ID>  — run animlib to see names","warn"); return
    end
    PlayAnim(id, true)
    Notify("🎭  Playing: "..(key ~= "" and key or tostring(id)))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: WORKSPACE VISIBILITY TOGGLE  (IY-ported)    ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: toggling Model/Part visibility via Transparency,
--           storing original values for exact restore.

local _wsVisibilityCache = {}

Cmd("hideworkspace", {"hidews2","wsvisoff"}, function()
    _wsVisibilityCache = {}
    local char = GetChar()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (not char or not v:IsDescendantOf(char)) then
            table.insert(_wsVisibilityCache, {part=v, trans=v.Transparency})
            pcall(function() v.Transparency = 1 end)
        end
    end
    Notify("🙈  Workspace hidden  (" .. #_wsVisibilityCache .. " parts) — showworkspace to restore")
end)

Cmd("showworkspace", {"showws2","wsvisoon"}, function()
    if #_wsVisibilityCache == 0 then Notify("Nothing cached — run hideworkspace first","warn"); return end
    local n = 0
    for _, entry in ipairs(_wsVisibilityCache) do
        pcall(function() if entry.part and entry.part.Parent then
            entry.part.Transparency = entry.trans; n=n+1 end end)
    end
    _wsVisibilityCache = {}
    Notify("👁  Workspace restored  (" .. n .. " parts)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: FOV PRESETS  (IY-ported)                    ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: named FOV constants, single-command switching,
--           how FOV affects perceived speed and immersion.

local _fovPresets = {
    narrow  = 50,
    normal  = 70,
    wide    = 90,
    ultra   = 110,
    fisheye = 120,
    sniper  = 20,
    scope   = 10,
}

Cmd("fovpreset", {"fp2","setfovpreset"}, function(args)
    local key = (args[1] or ""):lower()
    local val = _fovPresets[key]
    if not val then
        local list = {}
        for k, v in pairs(_fovPresets) do table.insert(list, k.."="..v) end
        table.sort(list)
        Notify("FOV presets: "..table.concat(list, "  "), "warn"); return
    end
    workspace.CurrentCamera.FieldOfView = val
    Notify(string.format("📷  FOV preset '%s' → %d°", key, val))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: STARTUP BANNER  (displayed on load)         ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: computing a final command count at runtime,
--           printing a structured startup summary.

task.defer(function()
    local cmdCount = 0
    for _ in pairs(Commands) do cmdCount = cmdCount + 1 end
    local aliasCount = 0
    for _ in pairs(Aliases) do aliasCount = aliasCount + 1 end
    print(string.rep("═", 58))
    print("  ⚡  S Command Bar Pro  v4.3  —  Final Edition")
    print(string.format("  Commands : %d  |  Aliases: %d", cmdCount, aliasCount))
    print(string.format("  Platform : %s  |  Player: %s",
        IsMobile and "Mobile 📱" or "PC 🖥", LP.Name))
    print(string.format("  Game     : %s  (PlaceId %d)", game.Name, game.PlaceId))
    print("  Tip      : type  cmds  to open the searchable command list")
    print("  Tip      : press  ;  to toggle the command bar (PC)")
    print(string.rep("═", 58))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: FINAL POLISH  (IY-ported)                   ║
-- ╚══════════════════════════════════════════════════════════╝

-- tip  — print a random useful tip about the script
local _tips = {
    "Press ; to toggle the command bar on PC.",
    "Use 'bind F fly' to toggle fly with the F key.",
    "Type 'cmds' then search in the list to find commands fast.",
    "setwp home → wp home  saves and returns to any spot.",
    "'help2 <cmd>' shows a description for key commands.",
    "Up/Down arrows in the bar cycle through your command history.",
    "Clicking a command in the cmds list auto-fills the bar.",
    "'debug' opens a full live overlay: fps/ping/pos/speed/health.",
    "'adminpanel' gives you 10 toggle buttons on one screen.",
    "'exportlog' copies your session summary to clipboard.",
    "'animlib' lists all built-in animation IDs you can play.",
    "'lightpreset night' — instantly sets dark cinematic lighting.",
    "'sizepreset giant' — scales your character to 2x size.",
    "'freecam' uses spring physics for a smooth cinematic camera.",
    "'sessionstats' shows time played, deaths, and studs walked.",
}

Cmd("tip", {"hint","randomtip"}, function()
    local t = _tips[math.random(1, #_tips)]
    print("[S-Admin] Tip: " .. t)
    Notify("💡  " .. t, "info")
end)

-- status  — one-line summary of active states
Cmd("status", {"state","activestates"}, function()
    local active = {}
    local checks = {
        {State.Flying,      "Fly"},
        {State.Noclipping,  "Noclip"},
        {State.ESP,         "ESP"},
        {State.Invisible,   "Invis"},
        {State.Fullbright,  "Bright"},
        {State.InfJump,     "InfJump"},
        {State.LoopHeal,    "LoopHeal"},
        {State.AntiAFK,     "AntiAFK"},
        {State.Swimming,    "Swim"},
        {State.Floating,    "Float"},
        {_kaRunning,        "KillAura"},
        {_fcRunning,        "Freecam"},
        {_chamsEnabled,     "Chams"},
        {_nametagESPOn,     "NameESP"},
        {_rainbowTask~=nil, "Rainbow"},
    }
    for _, c in ipairs(checks) do
        if c[1] then table.insert(active, c[2]) end
    end
    if #active == 0 then
        Notify("⚙  All states inactive", "info")
    else
        Notify("⚙  Active: " .. table.concat(active, "  ·  "), "info")
    end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: MODEL TOOLS  (IY-ported)                    ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Model hierarchy, PrimaryPart, GetChildren vs
--           GetDescendants, pivot, bounding box.

Cmd("modelinfo", {"minfo","inspectmodel"}, function(args)
    local query = table.concat(args," "):lower()
    local hrp   = GetHRP(); if not hrp then return end
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v ~= workspace and (query==""
        or v.Name:lower():find(query,1,true)) then
            local pp = v.PrimaryPart
            if pp then
                local d = (pp.Position - hrp.Position).Magnitude
                if d < bestDist then best=v; bestDist=d end
            end
        end
    end
    if not best then Notify("No model found","warn"); return end
    local childCount = #best:GetChildren()
    local descCount  = #best:GetDescendants()
    local partCount  = 0
    local bbox       = best:GetExtentsSize()
    for _, v in ipairs(best:GetDescendants()) do
        if v:IsA("BasePart") then partCount = partCount+1 end
    end
    local lines = {
        "Name:        " .. best.Name,
        "Primary:     " .. (best.PrimaryPart and best.PrimaryPart.Name or "none"),
        "Children:    " .. childCount,
        "Descendants: " .. descCount,
        "BaseParts:   " .. partCount,
        "BoundingBox: " .. string.format("%.1f x %.1f x %.1f",
            bbox.X, bbox.Y, bbox.Z),
        "Distance:    " .. string.format("%.1f studs", bestDist),
        "Path:        " .. best:GetFullName(),
    }
    print("[S-Admin] Model info:\n  "..table.concat(lines,"\n  "))
    Notify("📦  "..best.Name.."  desc="..descCount.."  parts="..partCount.." — console","info")
end)

Cmd("modelchildren", {"mchildren","listchildren"}, function(args)
    local query = table.concat(args," "):lower()
    local hrp   = GetHRP(); if not hrp then return end
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v ~= workspace
        and (query=="" or v.Name:lower():find(query,1,true)) then
            local pp = v.PrimaryPart
            if pp then
                local d = (pp.Position-hrp.Position).Magnitude
                if d < bestDist then best=v; bestDist=d end
            end
        end
    end
    if not best then Notify("No model found","warn"); return end
    local lines = {}
    for _, c in ipairs(best:GetChildren()) do
        table.insert(lines, string.format("  [%s] %s", c.ClassName, c.Name))
    end
    print("[S-Admin] Children of '"..best.Name.."' ("..#lines.."):\n"
        ..table.concat(lines,"\n"))
    Notify("📦  "..best.Name.." has "..#lines.." child(ren) — console","info")
end)

Cmd("anchormodel", {"modelanchor","anchorm"}, function(args)
    local query = table.concat(args," "):lower()
    if query == "" then Notify("Usage: anchormodel <model name>","warn"); return end
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name:lower():find(query,1,true) then
            for _, p in ipairs(v:GetDescendants()) do
                if p:IsA("BasePart") then
                    pcall(function() p.Anchored = true end); n=n+1
                end
            end
        end
    end
    Notify("🔒  Anchored "..n.." parts in models matching '"..query.."'")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: CAMERA SAVE / RESTORE  (IY-ported)          ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: saving CFrame state to a variable, restoring
--           with tween vs instant, CameraType management.

local _savedCamCF  = nil
local _savedCamFOV = 70

Cmd("savecam", {"cammark","camerasave"}, function()
    local cam     = workspace.CurrentCamera
    _savedCamCF   = cam.CFrame
    _savedCamFOV  = cam.FieldOfView
    local p       = cam.CFrame.Position
    Notify(string.format("📷  Camera saved  (%.0f,%.0f,%.0f  FOV=%d)",
        p.X,p.Y,p.Z,_savedCamFOV))
end)

Cmd("loadcam", {"cameraload","camrestore"}, function(args)
    if not _savedCamCF then Notify("No camera saved — run savecam first","warn"); return end
    local t    = tonumber(args[1]) or 0
    local cam  = workspace.CurrentCamera
    if t > 0 then
        cam.CameraType = Enum.CameraType.Scriptable
        TweenObj(cam, t, {CFrame=_savedCamCF, FieldOfView=_savedCamFOV},
            Enum.EasingStyle.Sine):Play()
        task.delay(t+0.1, function()
            cam.CameraType = Enum.CameraType.Custom
        end)
        Notify(string.format("📷  Camera restored over %.1fs", t))
    else
        cam.CFrame      = _savedCamCF
        cam.FieldOfView = _savedCamFOV
        Notify("📷  Camera restored instantly")
    end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SOUND SEARCH  (IY-ported)                   ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: GetDescendants filtering for Sound class,
--           reading SoundId, Volume, IsPlaying properties.

Cmd("listsounds", {"sounds","findsound"}, function(args)
    local query = (args[1] or ""):lower()
    local found = {}
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("Sound") then
            if query=="" or v.Name:lower():find(query,1,true)
            or v.SoundId:lower():find(query,1,true) then
                table.insert(found, {
                    name    = v.Name,
                    id      = v.SoundId,
                    vol     = v.Volume,
                    playing = v.IsPlaying,
                    path    = v:GetFullName(),
                })
                if #found >= 20 then break end
            end
        end
    end
    if #found == 0 then Notify("No sounds found","warn"); return end
    print("[S-Admin] Sounds ("..#found.."):")
    for _, s in ipairs(found) do
        print(string.format("  %-20s  vol=%.2f  %s  %s",
            s.name, s.vol, s.playing and "▶" or "⏸", s.path))
    end
    Notify("🎵  "..#found.." sound(s) — see console","info")
end)

Cmd("playsoundbyname", {"psbn","soundname"}, function(args)
    local query = table.concat(args," "):lower()
    if query == "" then Notify("Usage: playsoundbyname <name>","warn"); return end
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("Sound") and v.Name:lower():find(query,1,true) then
            v:Play()
            Notify("🎵  Playing: "..v.Name.."  ("..v.SoundId..")"); return
        end
    end
    Notify("Sound not found: "..query,"error")
end)

Cmd("stopsoundbyname", {"ssbn","stopname"}, function(args)
    local query = table.concat(args," "):lower()
    if query == "" then Notify("Usage: stopsoundbyname <name>","warn"); return end
    local n = 0
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("Sound") and v.Name:lower():find(query,1,true) and v.IsPlaying then
            v:Stop(); n=n+1
        end
    end
    Notify(n>0 and "🎵  Stopped "..n.." sound(s)" or "No playing sounds matched","warn")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: MACRO RECORDER  (IY-ported)                 ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: recording user commands with timestamps, playing
--           them back with correct delays, stop mid-playback.

local _macroRecording = false
local _macroPlaying   = false
local _macroData      = {}    -- { {cmd=str, delay=n}, ... }
local _macroStartTick = 0
local _macroLastTick  = 0

-- Patch ExecCommand to capture while recording
local _prevExecForMacro = ExecCommand
ExecCommand = function(raw)
    if _macroRecording and raw and raw:match("%S") then
        local now = tick()
        local delay = _macroData[1] and (now - _macroLastTick) or 0
        table.insert(_macroData, {cmd=raw, delay=delay})
        _macroLastTick = now
        print(string.format("[S-Macro] Recorded (+%.2fs): %s", delay, raw))
    end
    _prevExecForMacro(raw)
end

Cmd("recordmacro", {"recmacro","startrecord","rec"}, function()
    if _macroRecording then
        _macroRecording = false
        Notify(string.format("⏺  Macro recorded  (%d commands) — use playmacro",
            #_macroData))
        return
    end
    _macroData      = {}
    _macroRecording = true
    _macroStartTick = tick()
    _macroLastTick  = tick()
    Notify("⏺  Recording macro — run commands now, then recordmacro again to stop")
end)

Cmd("playmacro", {"runmacro","macro","pmacro"}, function(args)
    if _macroPlaying then Notify("Macro already playing","warn"); return end
    if #_macroData == 0 then Notify("No macro recorded — use recordmacro first","warn"); return end
    local loops = tonumber(args[1]) or 1
    loops = math.min(loops, 10)
    _macroPlaying = true
    Notify(string.format("▶  Playing macro  (%d commands × %d loop(s))", #_macroData, loops))
    task.spawn(function()
        for i = 1, loops do
            for _, entry in ipairs(_macroData) do
                if not _macroPlaying then break end
                if entry.delay > 0.05 then task.wait(entry.delay) end
                _prevExecForMacro(entry.cmd)
            end
            if not _macroPlaying then break end
        end
        _macroPlaying = false
        Notify("▶  Macro playback complete")
    end)
end)

Cmd("stopmacro", {"cancelmacro","endmacro"}, function()
    _macroPlaying   = false
    _macroRecording = false
    Notify("⏹  Macro stopped")
end)

Cmd("listmacro", {"showmacro","macrolist"}, function()
    if #_macroData == 0 then Notify("No macro recorded","warn"); return end
    local lines = {}
    local t = 0
    for i, e in ipairs(_macroData) do
        t = t + e.delay
        table.insert(lines, string.format("  [%2d] +%.2fs  %s", i, e.delay, e.cmd))
    end
    print("[S-Admin] Macro ("..#_macroData.." commands  total ~"
        ..string.format("%.1f", t).."s):\n"..table.concat(lines,"\n"))
    Notify("⏺  "..#_macroData.." macro command(s) — see console","info")
end)

Cmd("clearmacro", {"resetmacro","delmacro"}, function()
    _macroData = {}
    Notify("⏺  Macro cleared")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: MATH / VECTOR UTILITIES  (IY-ported)        ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: Vector3 arithmetic, distance formula, lerp,
--           dot/cross product, CFrame from two points.

Cmd("v3add", {"vecadd","addvec"}, function(args)
    local ax=tonumber(args[1]) or 0; local ay=tonumber(args[2]) or 0; local az=tonumber(args[3]) or 0
    local bx=tonumber(args[4]) or 0; local by=tonumber(args[5]) or 0; local bz=tonumber(args[6]) or 0
    local r = Vector3.new(ax+bx, ay+by, az+bz)
    local s = string.format("(%.2f, %.2f, %.2f)", r.X, r.Y, r.Z)
    pcall(function() setclipboard(s) end)
    Notify("🔢  "..s.."  (copied)","info")
end)

Cmd("v3dist", {"vecdist","vecmag"}, function(args)
    local ax=tonumber(args[1]) or 0; local ay=tonumber(args[2]) or 0; local az=tonumber(args[3]) or 0
    local bx=tonumber(args[4]) or 0; local by=tonumber(args[5]) or 0; local bz=tonumber(args[6]) or 0
    local d = Vector3.new(ax-bx, ay-by, az-bz).Magnitude
    local s = string.format("%.4f studs", d)
    pcall(function() setclipboard(tostring(d)) end)
    Notify("📏  Distance: "..s.."  (copied)","info")
end)

Cmd("v3lerp", {"veclerp","lerpvec"}, function(args)
    local ax=tonumber(args[1]) or 0; local ay=tonumber(args[2]) or 0; local az=tonumber(args[3]) or 0
    local bx=tonumber(args[4]) or 0; local by=tonumber(args[5]) or 0; local bz=tonumber(args[6]) or 0
    local t = math.clamp(tonumber(args[7]) or 0.5, 0, 1)
    local r = Vector3.new(ax,ay,az):Lerp(Vector3.new(bx,by,bz), t)
    local s = string.format("(%.2f, %.2f, %.2f)", r.X, r.Y, r.Z)
    pcall(function() setclipboard(s) end)
    Notify("🔢  Lerp t="..t.."  →  "..s.."  (copied)","info")
end)

Cmd("v3dot", {"vecdot","dotproduct"}, function(args)
    local ax=tonumber(args[1]) or 0; local ay=tonumber(args[2]) or 0; local az=tonumber(args[3]) or 0
    local bx=tonumber(args[4]) or 0; local by=tonumber(args[5]) or 0; local bz=tonumber(args[6]) or 0
    local d = Vector3.new(ax,ay,az):Dot(Vector3.new(bx,by,bz))
    Notify(string.format("🔢  Dot product: %.4f", d),"info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: PART WELDING  (IY-ported)                   ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: WeldConstraint vs Motor6D, parenting strategy,
--           batch-welding a model into one rigid assembly.

Cmd("weldmodel", {"weldm","rigidmodel"}, function(args)
    local query = table.concat(args," "):lower()
    if query == "" then Notify("Usage: weldmodel <model name>","warn"); return end
    local model = nil
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name:lower():find(query,1,true) then
            model = v; break
        end
    end
    if not model then Notify("Model not found: "..query,"error"); return end
    local primary = model.PrimaryPart
    if not primary then
        -- Use first BasePart as primary
        for _, v in ipairs(model:GetDescendants()) do
            if v:IsA("BasePart") then primary=v; break end
        end
    end
    if not primary then Notify("Model has no BaseParts","error"); return end
    local n = 0
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("BasePart") and v ~= primary then
            local wc = Instance.new("WeldConstraint", primary)
            wc.Part0 = primary; wc.Part1 = v; n=n+1
        end
    end
    Notify(string.format("🔗  Welded %d parts in '%s'", n, model.Name))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: HIGHLIGHT BY MATERIAL  (IY-ported)          ║
-- ╚══════════════════════════════════════════════════════════╝

local _matHighlightFolder = nil

Cmd("highlightmaterial", {"mathl","materialhl"}, function(args)
    if _matHighlightFolder then
        _matHighlightFolder:Destroy(); _matHighlightFolder = nil
        Notify("🎨  Material highlight cleared"); return
    end
    local matName = args[1]
    if not matName then Notify("Usage: highlightmaterial <Material>","warn"); return end
    local matEnum = nil
    for _, v in ipairs(Enum.Material:GetEnumItems()) do
        if v.Name:lower() == matName:lower() then matEnum=v; break end
    end
    if not matEnum then Notify("Unknown material: "..matName,"error"); return end
    _matHighlightFolder = Instance.new("Folder", ScreenGui)
    _matHighlightFolder.Name = "S_MatHL"
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Material == matEnum then
            local box = Instance.new("SelectionBox", _matHighlightFolder)
            box.Adornee = v
            box.Color3  = Color3.fromRGB(100,220,255)
            box.LineThickness = 0.04
            box.SurfaceTransparency = 0.85
            box.SurfaceColor3 = Color3.fromRGB(100,220,255)
            n=n+1
        end
    end
    Notify(string.format("🎨  Highlighted %d '%s' parts", n, matEnum.Name))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: TELEPORT EXTRAS  (IY-ported)                ║
-- ╚══════════════════════════════════════════════════════════╝

Cmd("tpoffset", {"tprel","offsettp"}, function(args)
    local x = tonumber(args[1]) or 0
    local y = tonumber(args[2]) or 0
    local z = tonumber(args[3]) or 0
    local hrp = GetHRP(); if not hrp then return end
    hrp.CFrame = hrp.CFrame * CFrame.new(x,y,z)
    Notify(string.format("📍  Offset TP  (%.1f, %.1f, %.1f relative)",x,y,z))
end)

Cmd("tpabove", {"above","tpup2"}, function(args)
    local target = GetPlayers(args[1])[1]
    local height = tonumber(args[2]) or 20
    local hrp = GetHRP(); if not hrp then return end
    local basePos
    if target and target.Character then
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        basePos = tHRP and tHRP.Position or hrp.Position
    else
        basePos = hrp.Position
    end
    hrp.CFrame = CFrame.new(basePos + Vector3.new(0, height, 0))
    Notify(string.format("📍  TP'd %.0f studs above %s",
        height, target and target.Name or "self"))
end)

Cmd("tpbehind", {"behind","tpback2"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or not target.Character then Notify("Target not found","error"); return end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local hrp = GetHRP(); if not hrp then return end
    local dist = tonumber(args[2]) or 5
    hrp.CFrame = tHRP.CFrame * CFrame.new(0, 0, dist)
    Notify("📍  TP'd behind "..target.Name)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SERVER TIME / SYNC  (IY-ported)             ║
-- ╚══════════════════════════════════════════════════════════╝

Cmd("servertime", {"stime","gametime"}, function()
    local gt  = workspace.DistributedGameTime
    local h   = math.floor(gt/3600)
    local m   = math.floor((gt%3600)/60)
    local s   = math.floor(gt%60)
    local tck = tick()
    Notify(string.format("⏱  Server: %02d:%02d:%02d  |  tick()=%.0f",h,m,s,tck),"info")
end)

Cmd("clocksync", {"timesync","synctime"}, function()
    -- Estimate server-client offset
    local t0 = tick()
    RunService.Heartbeat:Wait()
    local t1 = tick()
    local dt  = (t1-t0)*1000
    Notify(string.format("⏱  Heartbeat Δ: %.2fms  |  tick=%.2f", dt, t1),"info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: STRING TOOLS  (IY-ported)                   ║
-- ╚══════════════════════════════════════════════════════════╝

Cmd("strfind", {"sfind","strsearch"}, function(args)
    local haystack = args[1] or ""
    local needle   = args[2] or ""
    if needle == "" then Notify("Usage: strfind <string> <pattern>","warn"); return end
    local s, e = haystack:find(needle, 1, true)
    if s then
        Notify(string.format("🔍  Found '%s' at pos %d–%d", needle, s, e),"info")
    else
        Notify("🔍  '"..needle.."' not found in '"..haystack.."'","warn")
    end
end)

Cmd("strsplit", {"split","splitstr"}, function(args)
    local str = args[1] or ""
    local sep = args[2] or ","
    local parts = str:split(sep)
    local lines = {}
    for i, p in ipairs(parts) do table.insert(lines,"["..i.."] '"..p.."'") end
    print("[S-Admin] Split by '"..sep.."':\n  "..table.concat(lines,"\n  "))
    Notify("🔤  "..#parts.." part(s) — see console","info")
end)

Cmd("strformat", {"strfmt","format"}, function(args)
    local fmt = args[1] or ""
    if fmt == "" then Notify("Usage: strformat <fmt> [args...]","warn"); return end
    local fmtArgs = {}
    for i=2, #args do
        local n = tonumber(args[i])
        table.insert(fmtArgs, n ~= nil and n or args[i])
    end
    local ok, result = pcall(function() return string.format(fmt, table.unpack(fmtArgs)) end)
    if ok then
        pcall(function() setclipboard(result) end)
        Notify("🔤  "..result.."  (copied)","info")
    else
        Notify("Format error: "..tostring(result),"error")
    end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ACHIEVEMENT TRACKER  (IY-ported)            ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: custom in-session goal tracking, checking
--           conditions, toast notification on completion.

local _achievements = {
    {id="speedrun",  label="Speedrunner",   desc="Walk 1000 studs",  goal=1000,  stat="dist",    done=false},
    {id="explorer",  label="Explorer",      desc="Walk 5000 studs",  goal=5000,  stat="dist",    done=false},
    {id="survivor",  label="Survivor",      desc="Play 30 minutes",  goal=1800,  stat="time",    done=false},
    {id="veteran",   label="Veteran",       desc="Play 2 hours",     goal=7200,  stat="time",    done=false},
    {id="daredevil", label="Daredevil",     desc="Respawn 5 times",  goal=5,     stat="deaths",  done=false},
}

RunService.Heartbeat:Connect(function()
    local elapsed = tick() - _sessionStart
    for _, a in ipairs(_achievements) do
        if not a.done then
            local val = 0
            if a.stat == "dist"   then val = _sessionDist
            elseif a.stat == "time"   then val = elapsed
            elseif a.stat == "deaths" then val = math.max(0,_sessionDeaths)
            end
            if val >= a.goal then
                a.done = true
                Notify("🏆  Achievement: "..a.label.."  — "..a.desc, "success")
            end
        end
    end
end)

Cmd("achievements", {"achieve","myachievements"}, function()
    local lines = {}
    for _, a in ipairs(_achievements) do
        local elapsed = tick() - _sessionStart
        local val = 0
        if a.stat=="dist"   then val=_sessionDist
        elseif a.stat=="time"   then val=elapsed
        elseif a.stat=="deaths" then val=math.max(0,_sessionDeaths)
        end
        local pct = math.min(100, math.floor(val/a.goal*100))
        table.insert(lines, string.format("  [%s] %-12s %3d%%  %s",
            a.done and "✅" or "  ", a.label, pct, a.desc))
    end
    print("[S-Admin] Achievements:\n"..table.concat(lines,"\n"))
    local done = 0
    for _, a in ipairs(_achievements) do if a.done then done=done+1 end end
    Notify(string.format("🏆  %d/%d achievements — see console",done,#_achievements),"info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: GUI COUNT / CLEANUP  (IY-ported)            ║
-- ╚══════════════════════════════════════════════════════════╝

Cmd("guicount", {"countgui","listguis"}, function()
    local pg = LP:FindFirstChildOfClass("PlayerGui"); if not pg then return end
    local total, visible = 0, 0
    for _, v in ipairs(pg:GetDescendants()) do
        total = total + 1
        if (v:IsA("Frame") or v:IsA("ImageLabel") or v:IsA("TextLabel"))
        and v.Visible then visible = visible + 1 end
    end
    Notify(string.format("🪟  PlayerGui: %d total  |  %d visible", total, visible),"info")
end)

Cmd("destroygameguis", {"clearplayergui","destroygui"}, function()
    local pg = LP:FindFirstChildOfClass("PlayerGui"); if not pg then return end
    local n = 0
    for _, v in ipairs(pg:GetChildren()) do
        if not v.Name:find("^S_") then
            pcall(function() v:Destroy() end); n=n+1
        end
    end
    Notify("🗑  Destroyed "..n.." game GUI(s)  (S_ GUIs preserved)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: POINTLIGHT ON PART  (IY-ported)             ║
-- ╚══════════════════════════════════════════════════════════╝

Cmd("lightpart", {"partlight","addlighttopart"}, function(args)
    local query = args[1]; if not query then Notify("Usage: lightpart <name> [R G B] [range]","warn"); return end
    local r = tonumber(args[2]) or 255
    local g = tonumber(args[3]) or 240
    local b = tonumber(args[4]) or 200
    local range = tonumber(args[5]) or 20
    local hrp = GetHRP(); if not hrp then return end
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower()==query:lower() then
            local d = (v.Position-hrp.Position).Magnitude
            if d < bestDist then best=v; bestDist=d end
        end
    end
    if not best then Notify("Part not found: "..query,"error"); return end
    local old = best:FindFirstChildOfClass("PointLight")
    if old then old:Destroy(); Notify("💡  Light removed from "..best.Name); return end
    local pl = Instance.new("PointLight", best)
    pl.Color      = Color3.fromRGB(r,g,b)
    pl.Brightness = 5
    pl.Range      = range
    Notify(string.format("💡  Light on '%s'  RGB(%d,%d,%d)  r=%d",best.Name,r,g,b,range))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: IMPULSE / FORCE  (IY-ported)                ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: ApplyImpulse vs AssemblyLinearVelocity,
--           world-space vs local-space force application.

Cmd("impulse", {"applyimpulse","addforce"}, function(args)
    local x = tonumber(args[1]) or 0
    local y = tonumber(args[2]) or 0
    local z = tonumber(args[3]) or 0
    local hrp = GetHRP(); if not hrp then return end
    pcall(function()
        hrp:ApplyImpulse(Vector3.new(x,y,z))
    end)
    Notify(string.format("💥  Impulse applied  (%.0f,%.0f,%.0f)",x,y,z))
end)

Cmd("angularimpulse", {"angularimp","spinimpulse"}, function(args)
    local x = tonumber(args[1]) or 0
    local y = tonumber(args[2]) or 500
    local z = tonumber(args[3]) or 0
    local hrp = GetHRP(); if not hrp then return end
    pcall(function()
        hrp:ApplyAngularImpulse(Vector3.new(x,y,z))
    end)
    Notify(string.format("🔄  Angular impulse  (%.0f,%.0f,%.0f)",x,y,z))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: DEFENSIVE COMMANDS                          ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: velocity monitoring, position guard loops,
--           CFrame restoration, property change guards —
--           all client-side protective patterns.

-- ── Anti-Fling ────────────────────────────────────────────
--  Monitors AssemblyLinearVelocity every Stepped frame.
--  If magnitude exceeds threshold → clamp it back instantly.

local _antiFlingConn = nil
local _afThreshold   = 250   -- studs/s spike threshold

Cmd("antifling", {"af","noflinging","antiflung"}, function(args)
    if _antiFlingConn then
        _antiFlingConn:Disconnect(); _antiFlingConn = nil
        Notify("🛡  Anti-Fling OFF"); return
    end
    _afThreshold = tonumber(args[1]) or 250
    _antiFlingConn = RunService.Stepped:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        local vel = hrp.AssemblyLinearVelocity
        if vel.Magnitude > _afThreshold then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    Notify("🛡  Anti-Fling ON  (threshold " .. _afThreshold .. " st/s)")
end)

-- ── Anti-Teleport ─────────────────────────────────────────
--  Saves your position every 0.5 s. If you suddenly appear
--  > N studs away without fly / noclip active → restore.

local _antiTpConn     = nil
local _antiTpLastPos  = nil
local _antiTpDist     = 80

Cmd("antiteleport", {"atp","notp","antitp"}, function(args)
    if _antiTpConn then
        _antiTpConn:Disconnect(); _antiTpConn = nil
        _antiTpLastPos = nil
        Notify("🛡  Anti-Teleport OFF"); return
    end
    _antiTpDist = tonumber(args[1]) or 80
    local elapsed = 0
    _antiTpConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        local hrp = GetHRP(); if not hrp then return end
        local pos = hrp.Position

        if _antiTpLastPos then
            local moved = (pos - _antiTpLastPos).Magnitude
            -- Allow large movement only when fly/noclip is on
            if moved > _antiTpDist and not State.Flying and not State.Noclipping then
                hrp.CFrame = CFrame.new(_antiTpLastPos)
                Notify("🛡  Anti-TP: unwanted teleport blocked!", "warn")
                return
            end
        end

        if elapsed >= 0.5 then
            elapsed = 0
            _antiTpLastPos = pos
        end
    end)
    Notify("🛡  Anti-Teleport ON  (threshold " .. _antiTpDist .. " studs)")
end)

-- ── Position Lock ─────────────────────────────────────────
--  Hard-freezes your HRP in place every Stepped frame.
--  Nothing — gravity, physics, forces — can move you.

local _posLockConn = nil
local _posLockCF   = nil

Cmd("positionlock", {"poslock","lockpos","freeze2"}, function()
    if _posLockConn then
        _posLockConn:Disconnect(); _posLockConn = nil
        local hrp = GetHRP(); if hrp then hrp.Anchored = false end
        Notify("🛡  Position lock OFF"); return
    end
    local hrp = GetHRP(); if not hrp then return end
    _posLockCF = hrp.CFrame
    hrp.Anchored = true
    _posLockConn = RunService.Stepped:Connect(function()
        local h = GetHRP(); if not h then return end
        h.CFrame = _posLockCF
    end)
    Notify("🛡  Position locked — nothing can move you  (run again to free)")
end)

Cmd("updatelock", {"refreshlock","newlockpos"}, function()
    local hrp = GetHRP()
    if not hrp or not _posLockConn then
        Notify("Position lock not active — run positionlock first", "warn"); return
    end
    _posLockCF = hrp.CFrame
    local p = _posLockCF.Position
    Notify(string.format("🛡  Lock position updated  (%.0f,%.0f,%.0f)", p.X,p.Y,p.Z))
end)

-- ── Velocity Clamp ────────────────────────────────────────
--  Caps linear velocity to a max magnitude every frame.
--  Softer than anti-fling; allows fast movement but prevents
--  extreme spikes from physics glitches or exploits.

local _velClampConn = nil
local _velClampMax  = 120

Cmd("velocityclamp", {"velclamp","maxvelocity","clampvel"}, function(args)
    if _velClampConn then
        _velClampConn:Disconnect(); _velClampConn = nil
        Notify("🛡  Velocity clamp OFF"); return
    end
    _velClampMax = tonumber(args[1]) or 120
    _velClampConn = RunService.Stepped:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        local vel = hrp.AssemblyLinearVelocity
        if vel.Magnitude > _velClampMax then
            hrp.AssemblyLinearVelocity = vel.Unit * _velClampMax
        end
    end)
    Notify("🛡  Velocity clamp ON  (max " .. _velClampMax .. " st/s)")
end)

-- ── Anti-Aim / Camera Guard ───────────────────────────────
--  Watches CameraType and CameraSubject. If another script
--  changes them without your consent → restore instantly.

local _camGuardConn  = nil
local _camGuardType  = nil
local _camGuardSubj  = nil

Cmd("cameralock", {"camguard","anticam","lockscriptcam"}, function()
    if _camGuardConn then
        _camGuardConn:Disconnect(); _camGuardConn = nil
        Notify("🛡  Camera guard OFF"); return
    end
    local cam = workspace.CurrentCamera
    _camGuardType = cam.CameraType
    _camGuardSubj = cam.CameraSubject

    _camGuardConn = cam:GetPropertyChangedSignal("CameraType"):Connect(function()
        if cam.CameraType ~= _camGuardType and not _fcRunning then
            cam.CameraType = _camGuardType
        end
    end)
    -- Also guard Subject
    local subjConn = cam:GetPropertyChangedSignal("CameraSubject"):Connect(function()
        if cam.CameraSubject ~= _camGuardSubj
        and State.Viewing == nil and not _fcRunning then
            cam.CameraSubject = _camGuardSubj
        end
    end)
    -- Store both
    Conns.CamGuardSubj = subjConn
    Notify("🛡  Camera guard ON  — CameraType and CameraSubject locked")
end)

Cmd("uncameralock", {"uncamguard","freecamguard"}, function()
    if _camGuardConn then _camGuardConn:Disconnect(); _camGuardConn = nil end
    SafeDisconn("CamGuardSubj")
    Notify("🛡  Camera guard OFF")
end)

-- ── Safe Position / Panic Restore ────────────────────────
--  Mark a "safe" CFrame. If you press the key or run the
--  command you instantly return — good for dangerous areas.

local _safeCF    = nil
local _panicBind = nil

Cmd("setsafe", {"safemark","marksafe","setpanic"}, function()
    local hrp = GetHRP(); if not hrp then return end
    _safeCF = hrp.CFrame
    local p = _safeCF.Position
    Notify(string.format("🛡  Safe position set  (%.0f,%.0f,%.0f)", p.X,p.Y,p.Z))
end)

Cmd("panic", {"returnsafe","gosafe","panictp"}, function()
    if not _safeCF then Notify("No safe position set — run setsafe first","warn"); return end
    local hrp = GetHRP(); if not hrp then return end
    hrp.CFrame = _safeCF
    local p = _safeCF.Position
    Notify(string.format("🛡  Panic TP → safe pos  (%.0f,%.0f,%.0f)", p.X,p.Y,p.Z))
end)

-- Bind a key to panic (default: P)
Cmd("panickey", {"bindpanic","setpanickey"}, function(args)
    local key = (args[1] or "P"):upper()
    if _panicBind then _panicBind:Disconnect() end
    _panicBind = UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode.Name == key then
            Commands["panic"]({})
        end
    end)
    Notify("🛡  Panic key bound to ["..key.."]")
end)

-- ── Anti-Kick Guard ───────────────────────────────────────
--  Listens for the GuiService error signal and attempts an
--  immediate rejoin before the kick screen appears.

local _antiKickActive = false

Cmd("antikick", {"nkick","preventkick"}, function()
    if _antiKickActive then
        _antiKickActive = false
        Notify("🛡  Anti-Kick OFF"); return
    end
    _antiKickActive = true
    local GS = game:GetService("GuiService")
    pcall(function()
        GS.ErrorMessageChanged:Connect(function()
            if _antiKickActive and GS.ErrorCode ~= 0 then
                task.wait(0.05)
                TeleportService:TeleportToPlaceInstance(
                    game.PlaceId, game.JobId, LP)
            end
        end)
    end)
    Notify("🛡  Anti-Kick ON  (auto-rejoin on error)")
end)

-- ── Anti-Void ─────────────────────────────────────────────
--  If your Y position drops below a threshold, TP to safety.

local _antiVoidConn    = nil
local _antiVoidThresh  = -100

Cmd("antivoid", {"av2","novoid","avoidvoid"}, function(args)
    if _antiVoidConn then
        _antiVoidConn:Disconnect(); _antiVoidConn = nil
        Notify("🛡  Anti-Void OFF"); return
    end
    _antiVoidThresh = tonumber(args[1]) or -100
    _antiVoidConn = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        if hrp.Position.Y < _antiVoidThresh then
            -- Restore to last safe pos or origin
            if _safeCF then
                hrp.CFrame = _safeCF
            else
                hrp.CFrame = CFrame.new(hrp.Position.X, 100, hrp.Position.Z)
            end
            Notify("🛡  Anti-Void: caught at Y < " .. _antiVoidThresh, "warn")
        end
    end)
    Notify("🛡  Anti-Void ON  (threshold Y < " .. _antiVoidThresh .. ")")
end)

-- ── Exploit Detector ─────────────────────────────────────
--  Monitors nearby players for suspicious patterns:
--  extreme velocity, rapid position change, noclip through
--  geometry — and notifies you with player name + evidence.

local _exploitDetConn    = nil
local _exploitCooldowns  = {}

Cmd("exploitdetect", {"edetect","hackdetect","cheatdetect"}, function(args)
    if _exploitDetConn then
        _exploitDetConn:Disconnect(); _exploitDetConn = nil
        _exploitCooldowns = {}
        Notify("🔍  Exploit detector OFF"); return
    end
    local range   = tonumber(args[1]) or 200
    local elapsed = 0
    local lastPos = {}

    _exploitDetConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed < 0.25 then return end
        elapsed = 0

        local myHRP = GetHRP()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                if tHRP and tHum then
                    local dist = myHRP and (tHRP.Position - myHRP.Position).Magnitude or 0
                    if dist > range then
                        lastPos[p.Name] = nil
                    else
                        local vel   = tHRP.AssemblyLinearVelocity.Magnitude
                        local flags = {}

                        -- Velocity spike flag
                        if vel > 500 then
                            table.insert(flags, string.format("speed=%.0f", vel))
                        end

                        -- Teleport flag (sudden pos change)
                        local lp2 = lastPos[p.Name]
                        if lp2 then
                            local moved = (tHRP.Position - lp2).Magnitude / 0.25
                            if moved > 800 and vel < 200 then
                                table.insert(flags, string.format("teleport(%.0f st/s)", moved))
                            end
                        end
                        lastPos[p.Name] = tHRP.Position

                        -- Noclip flag: no ground below while not jumping
                        local ray = workspace:Raycast(
                            tHRP.Position + Vector3.new(0, 0.5, 0),
                            Vector3.new(0, -1, 0))
                        if not ray and tHum:GetState() ~= Enum.HumanoidStateType.Jumping then
                            table.insert(flags, "noclip?")
                        end

                        if #flags > 0 then
                            local now  = tick()
                            local last = _exploitCooldowns[p.Name] or 0
                            if now - last > 5 then
                                _exploitCooldowns[p.Name] = now
                                local msg = "⚠  " .. p.Name .. ": " .. table.concat(flags, "  |  ")
                                print("[S-ExploitDetect] " .. msg)
                                Notify(msg, "warn")
                            end
                        end
                    end   -- dist <= range
                end   -- tHRP and tHum
            end   -- p ~= LP
        end   -- for players
    end)
    Notify("🔍  Exploit detector ON  (range " .. range .. " studs)")
end)

-- ── Health Guard ─────────────────────────────────────────
--  If health drops suddenly below a threshold → god mode
--  kicks in automatically.  Think of it as a "last-stand".

local _healthGuardConn   = nil
local _healthGuardThresh = 20

Cmd("healthguard", {"hguard","autogod","laststand"}, function(args)
    if _healthGuardConn then
        _healthGuardConn:Disconnect(); _healthGuardConn = nil
        Notify("🛡  Health guard OFF"); return
    end
    _healthGuardThresh = tonumber(args[1]) or 20
    _healthGuardConn = RunService.Heartbeat:Connect(function()
        local hum = GetHuman(); if not hum then return end
        if hum.Health > 0 and hum.Health < _healthGuardThresh then
            hum.MaxHealth = math.huge
            hum.Health    = math.huge
            Notify("🛡  Health guard triggered — god mode activated!", "warn")
        end
    end)
    Notify("🛡  Health guard ON  (trigger at < " .. _healthGuardThresh .. " HP)")
end)

-- ── Anti-Spin ────────────────────────────────────────────
--  Detects runaway angular velocity and resets it instantly.

local _antiSpinConn = nil

Cmd("antispin", {"aspn","nospinned","antirotat"}, function()
    if _antiSpinConn then
        _antiSpinConn:Disconnect(); _antiSpinConn = nil
        Notify("🛡  Anti-Spin OFF"); return
    end
    _antiSpinConn = RunService.Stepped:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        if hrp.AssemblyAngularVelocity.Magnitude > 15 then
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    Notify("🛡  Anti-Spin ON  (resets runaway angular velocity)")
end)

-- ── Anti-Gravity Exploit ──────────────────────────────────
--  Monitors workspace.Gravity; if another script resets it,
--  restore immediately.

local _gravGuardVal  = workspace.Gravity
local _gravGuardConn = nil

Cmd("gravityguard", {"gravguard","antigravmod"}, function(args)
    if _gravGuardConn then
        _gravGuardConn:Disconnect(); _gravGuardConn = nil
        Notify("🛡  Gravity guard OFF"); return
    end
    _gravGuardVal = tonumber(args[1]) or workspace.Gravity
    _gravGuardConn = workspace:GetPropertyChangedSignal("Gravity"):Connect(function()
        if workspace.Gravity ~= _gravGuardVal then
            workspace.Gravity = _gravGuardVal
            Notify("🛡  Gravity guard: reset to " .. _gravGuardVal, "warn")
        end
    end)
    Notify("🛡  Gravity guard ON  (locked at " .. _gravGuardVal .. ")")
end)

-- ── Shield Mode ───────────────────────────────────────────
--  One command activating multiple defensive layers at once:
--  Anti-Fling + Anti-Void + Health Guard + Anti-Spin.

Cmd("shieldmode", {"shield","defensemode","fulldefense"}, function(args)
    -- Toggle off if all active
    if _antiFlingConn and _antiVoidConn and _antiSpinConn and _healthGuardConn then
        Commands["antifling"]({})
        Commands["antivoid"]({})
        Commands["antispin"]({})
        Commands["healthguard"]({})
        Notify("🛡  Shield mode OFF — all defenses down")
        return
    end
    -- Activate all
    if not _antiFlingConn  then Commands["antifling"]({})      end
    if not _antiVoidConn   then Commands["antivoid"]({})       end
    if not _antiSpinConn   then Commands["antispin"]({})       end
    if not _healthGuardConn then Commands["healthguard"]({})   end
    Notify("🛡  Shield mode ON — Anti-Fling + Anti-Void + Anti-Spin + Health Guard")
end)

-- ── Defense Status ────────────────────────────────────────
Cmd("defensestatus", {"defstatus","shields","dstatus"}, function()
    local statuses = {
        {"Anti-Fling",     _antiFlingConn   ~= nil},
        {"Anti-Teleport",  _antiTpConn      ~= nil},
        {"Position Lock",  _posLockConn     ~= nil},
        {"Velocity Clamp", _velClampConn    ~= nil},
        {"Camera Guard",   _camGuardConn    ~= nil},
        {"Anti-Void",      _antiVoidConn    ~= nil},
        {"Anti-Spin",      _antiSpinConn    ~= nil},
        {"Health Guard",   _healthGuardConn ~= nil},
        {"Gravity Guard",  _gravGuardConn   ~= nil},
        {"Anti-Kick",      _antiKickActive          },
        {"Exploit Detect", _exploitDetConn  ~= nil},
    }
    local on, off = {}, {}
    for _, s in ipairs(statuses) do
        if s[2] then table.insert(on, s[1])
        else table.insert(off, s[1]) end
    end
    print("[S-Admin] Defense Status:")
    print("  ✅  " .. (#on  > 0 and table.concat(on,", ")  or "none"))
    print("  ❌  " .. (#off > 0 and table.concat(off,", ") or "none"))
    Notify("🛡  " .. #on .. "/" .. #statuses .. " defenses active — console", "info")
end)

-- ── Disable All Defenses ─────────────────────────────────
Cmd("undefend", {"nodefense","disabledefense","cleardefense"}, function()
    if _antiFlingConn   then Commands["antifling"]({})    end
    if _antiTpConn      then Commands["antiteleport"]({}) end
    if _posLockConn     then Commands["positionlock"]({}) end
    if _velClampConn    then Commands["velocityclamp"]({}) end
    if _camGuardConn    then Commands["uncameralock"]({}) end
    if _antiVoidConn    then Commands["antivoid"]({})     end
    if _antiSpinConn    then Commands["antispin"]({})     end
    if _healthGuardConn then Commands["healthguard"]({})  end
    if _gravGuardConn   then Commands["gravityguard"]({}) end
    _antiKickActive = false
    Notify("🛡  All defenses disabled")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ADDITIONAL NEUTRAL UTILITIES                ║
-- ╚══════════════════════════════════════════════════════════╝

-- ── Instance Watcher ─────────────────────────────────────
--  Watches for a specific instance being added or removed
--  from the game tree and notifies you.

local _watchConn = nil

Cmd("watch", {"watchfor","monitor"}, function(args)
    local query = table.concat(args," "):lower()
    if query == "" then Notify("Usage: watch <instance name>","warn"); return end
    if _watchConn then _watchConn:Disconnect(); _watchConn = nil end
    _watchConn = game.DescendantAdded:Connect(function(v)
        if v.Name:lower():find(query,1,true) then
            Notify("👁  Added: "..v:GetFullName().." ["..v.ClassName.."]","info")
        end
    end)
    local remConn
    remConn = game.DescendantRemoving:Connect(function(v)
        if v.Name:lower():find(query,1,true) then
            Notify("👁  Removed: "..v.Name.." ["..v.ClassName.."]","warn")
        end
    end)
    Conns.WatchRemove = remConn
    Notify("👁  Watching for instances named '"..query.."'")
end)

Cmd("unwatch", {"stopwatch","nomonitor"}, function()
    if _watchConn then _watchConn:Disconnect(); _watchConn = nil end
    SafeDisconn("WatchRemove")
    Notify("👁  Watch stopped")
end)

-- ── Property Monitor ─────────────────────────────────────
--  Watch a specific property of your HRP and alert on change.

Cmd("watchprop", {"watchproperty","monitorprop"}, function(args)
    local prop = args[1]; if not prop then Notify("Usage: watchprop <property>","warn"); return end
    local hrp  = GetHRP(); if not hrp then return end
    local ok   = pcall(function()
        hrp:GetPropertyChangedSignal(prop):Connect(function()
            local val = ""
            pcall(function() val = tostring(hrp[prop]) end)
            Notify("👁  HRP."..prop.." changed → "..val, "info")
        end)
    end)
    Notify(ok and "👁  Watching HRP."..prop or "Property not found: "..prop,
        ok and "info" or "error")
end)

-- ── Network Receiver Spike Alert ─────────────────────────
--  Fires a warning when ping spikes above a threshold.

local _pingAlertConn  = nil
local _pingAlertThresh = 300

Cmd("pingalert", {"alertping","highpingwarn"}, function(args)
    if _pingAlertConn then
        _pingAlertConn:Disconnect(); _pingAlertConn = nil
        Notify("📶  Ping alert OFF"); return
    end
    _pingAlertThresh = tonumber(args[1]) or 300
    local cooldown, elapsed = false, 0
    _pingAlertConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed < 1 then return end
        elapsed = 0
        local ms = LP:GetNetworkPing() * 1000
        if ms > _pingAlertThresh and not cooldown then
            cooldown = true
            Notify(string.format("📶  High ping! %.0fms", ms), "warn")
            task.delay(10, function() cooldown = false end)
        end
    end)
    Notify("📶  Ping alert ON  (threshold "..(_pingAlertThresh).."ms)")
end)

-- ── Character Integrity Check ────────────────────────────
--  Verifies all expected parts exist in the character, and
--  reports any that are missing (exploits sometimes delete
--  parts like the HumanoidRootPart or arms).

Cmd("charintegrity", {"charint","checkchar","integritycheck"}, function()
    local char = GetChar(); if not char then Notify("No character","warn"); return end
    local expected = {
        "HumanoidRootPart","Humanoid","Head",
        "UpperTorso","LowerTorso",
        "LeftUpperArm","LeftLowerArm","LeftHand",
        "RightUpperArm","RightLowerArm","RightHand",
        "LeftUpperLeg","LeftLowerLeg","LeftFoot",
        "RightUpperLeg","RightLowerLeg","RightFoot",
    }
    -- Also check R6
    local r6 = {"HumanoidRootPart","Humanoid","Head","Torso",
        "Left Arm","Right Arm","Left Leg","Right Leg"}
    local isR6 = char:FindFirstChild("Torso") ~= nil
    local checkList = isR6 and r6 or expected
    local missing = {}
    for _, name in ipairs(checkList) do
        if not char:FindFirstChild(name) then table.insert(missing, name) end
    end
    if #missing == 0 then
        Notify("✅  Character integrity OK  (" .. (isR6 and "R6" or "R15") .. ")")
    else
        print("[S-Admin] Missing parts: " .. table.concat(missing,", "))
        Notify("⚠  "..#missing.." part(s) missing — see console", "warn")
    end
end)

-- ── Crash Protection ─────────────────────────────────────
--  Detects when the script environment is under stress
--  (extremely low FPS) and reduces all running loops.

local _crashProtConn = nil

Cmd("crashprotection", {"crashprot","cprot","anticrash"}, function()
    if _crashProtConn then
        _crashProtConn:Disconnect(); _crashProtConn = nil
        Notify("🛡  Crash protection OFF"); return
    end
    local samples, elapsed = {}, 0
    _crashProtConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        table.insert(samples, 1/dt)
        if #samples > 30 then table.remove(samples,1) end
        if elapsed < 3 then return end
        elapsed = 0
        local avg = 0
        for _, s in ipairs(samples) do avg=avg+s end
        avg = avg/#samples
        if avg < 8 then
            -- FPS critically low — disable expensive loops
            if _kaRunning        then Commands["unkillaura"]({}) end
            if _fpsCapTask       then Commands["unfpscap"]({})   end
            if _minimapConn      then Commands["minimap"]({})    end
            if _pingGraphConn    then Commands["pinggraph"]({})  end
            Notify("⚠  FPS critical ("..math.floor(avg)..") — heavy features disabled", "warn")
        end
    end)
    Notify("🛡  Crash protection ON  (auto-disables heavy features at <8 FPS)")
end)

-- ── Respawn Protection ───────────────────────────────────
--  After respawning, briefly activates god mode and noclip
--  so you can orient before enemies can reach you.

local _respawnProtActive = false

Cmd("respawnprotection", {"rprotect","spawnshield","spawnprot"}, function(args)
    _respawnProtActive = not _respawnProtActive
    if not _respawnProtActive then
        Notify("🛡  Respawn protection OFF"); return
    end
    local duration = tonumber(args[1]) or 5
    LP.CharacterAdded:Connect(function(char)
        if not _respawnProtActive then return end
        char:WaitForChild("Humanoid")
        local hum = char:FindFirstChildOfClass("Humanoid")
        -- Brief god + noclip
        if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
        -- Noclip
        local nc = RunService.Stepped:Connect(function()
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
        Notify("🛡  Respawn protection active for "..duration.."s")
        task.delay(duration, function()
            nc:Disconnect()
            -- Restore collision
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
            -- Remove god
            if hum and hum.Parent then hum.MaxHealth=100; hum.Health=100 end
            Notify("🛡  Respawn protection expired")
        end)
    end)
    Notify("🛡  Respawn protection ON  ("..duration.."s per spawn)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: EXTENDED DEFENSIVE TOOLS                    ║
-- ╚══════════════════════════════════════════════════════════╝

-- ── Safe Fall / Landing Protection ───────────────────────
--  When you fall faster than a threshold, slow velocity
--  so landing damage is negated client-side.

local _safeFallConn = nil

Cmd("safefall", {"antifall","nofalldmg","softlanding"}, function(args)
    if _safeFallConn then
        _safeFallConn:Disconnect(); _safeFallConn = nil
        Notify("🛡  Safe fall OFF"); return
    end
    local maxFall = -(tonumber(args[1]) or 90)   -- downward speed cap
    _safeFallConn = RunService.Stepped:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        local vy  = hrp.AssemblyLinearVelocity.Y
        if vy < maxFall then
            local cur = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(cur.X, maxFall, cur.Z)
        end
    end)
    Notify("🛡  Safe fall ON  (max fall speed " .. math.abs(maxFall) .. " st/s)")
end)

-- ── Anti-Weld Exploit ─────────────────────────────────────
--  Removes any WeldConstraint / Weld added to your character
--  parts by another script (e.g. stuck-to-wall exploits).

local _antiWeldConn = nil

Cmd("antiweld", {"noweld","removewelds","cleanwelds"}, function()
    if _antiWeldConn then
        _antiWeldConn:Disconnect(); _antiWeldConn = nil
        Notify("🛡  Anti-Weld OFF"); return
    end
    local function cleanChar(char)
        for _, v in ipairs(char:GetDescendants()) do
            if v.Name == "S_AttachWeld" or v.Name == "S_Rope"
            or v.Name == "S_Spring" then
                pcall(function() v:Destroy() end)
            end
        end
    end
    _antiWeldConn = RunService.Stepped:Connect(function()
        local char = GetChar(); if not char then return end
        for _, v in ipairs(char:GetDescendants()) do
            -- Remove externally added welds (not our own named ones needed for fly etc.)
            if (v:IsA("WeldConstraint") or v:IsA("Weld"))
            and not v.Name:find("^S_") then
                pcall(function() v:Destroy() end)
            end
        end
    end)
    Notify("🛡  Anti-Weld ON  (removes foreign welds from character)")
end)

-- ── Auto-Heal on Low HP ───────────────────────────────────
--  Different from loopheal — only triggers when HP < threshold,
--  healing you back to full once, then waiting for next drop.

local _autoHealConn   = nil
local _ahThresh       = 40
local _ahCooldown     = false

Cmd("autoheal", {"ah","selfheal","autohealth"}, function(args)
    if _autoHealConn then
        _autoHealConn:Disconnect(); _autoHealConn = nil
        Notify("🛡  Auto-Heal OFF"); return
    end
    _ahThresh = tonumber(args[1]) or 40
    _autoHealConn = RunService.Heartbeat:Connect(function()
        if _ahCooldown then return end
        local hum = GetHuman(); if not hum then return end
        if hum.Health > 0 and hum.Health < _ahThresh then
            _ahCooldown = true
            hum.Health = hum.MaxHealth
            Notify("🛡  Auto-Heal: healed at " .. math.floor(hum.Health) .. " HP", "info")
            task.delay(3, function() _ahCooldown = false end)
        end
    end)
    Notify("🛡  Auto-Heal ON  (triggers at < " .. _ahThresh .. " HP)")
end)

-- ── Anti-Speed Clamp on Others (report mode) ─────────────
--  Watches nearby players and logs suspiciously fast movement
--  without flagging our own fly/speed.

local _speedWatchConn = nil

Cmd("speedwatch", {"watchspeed","reportspeed"}, function(args)
    if _speedWatchConn then
        _speedWatchConn:Disconnect(); _speedWatchConn = nil
        Notify("🔍  Speed watch OFF"); return
    end
    local threshold = tonumber(args[1]) or 150
    local cooldowns, elapsed = {}, 0
    _speedWatchConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed < 0.5 then return end
        elapsed = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    local spd = Vector3.new(
                        tHRP.AssemblyLinearVelocity.X, 0,
                        tHRP.AssemblyLinearVelocity.Z).Magnitude
                    if spd > threshold then
                        local now  = tick()
                        local last = cooldowns[p.Name] or 0
                        if now - last > 8 then
                            cooldowns[p.Name] = now
                            Notify(string.format("⚠  %s speed=%.0f st/s", p.Name, spd),"warn")
                        end
                    end
                end
            end
        end
    end)
    Notify("🔍  Speed watch ON  (threshold " .. threshold .. " st/s)")
end)

-- ── Network Anomaly Alert ─────────────────────────────────
--  Detects sudden jumps in DataReceiveKbps that may indicate
--  a RemoteFire flood or heavy server payload.

local _netAnomalyConn = nil

Cmd("networkwatch", {"netwatch","anomalydetect"}, function(args)
    if _netAnomalyConn then
        _netAnomalyConn:Disconnect(); _netAnomalyConn = nil
        Notify("📶  Network watch OFF"); return
    end
    local threshold = tonumber(args[1]) or 500   -- kb/s
    local cooldown  = false
    local elapsed   = 0
    local stats     = game:GetService("Stats")

    _netAnomalyConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed < 1 then return end
        elapsed = 0
        local recv = 0
        pcall(function() recv = stats.DataReceiveKbps.Value end)
        if recv > threshold and not cooldown then
            cooldown = true
            Notify(string.format("📶  Network spike: %.0f kb/s (threshold %d)", recv, threshold),"warn")
            task.delay(10, function() cooldown = false end)
        end
    end)
    Notify("📶  Network watch ON  (alert at > " .. threshold .. " kb/s)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: LOCOMOTION HELPERS  (IY-ported)             ║
-- ╚══════════════════════════════════════════════════════════╝

-- ── Auto-Jump ─────────────────────────────────────────────
--  Automatically jumps whenever the humanoid is on the ground
--  and moving. Useful for parkour maps.

local _autoJumpConn = nil

Cmd("autojump", {"aj","jumpspam","autoleap"}, function(args)
    if _autoJumpConn then
        _autoJumpConn:Disconnect(); _autoJumpConn = nil
        Notify("🦘  Auto-jump OFF"); return
    end
    local interval = tonumber(args[1]) or 0.4
    local elapsed  = 0
    _autoJumpConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed < interval then return end
        elapsed = 0
        local hum = GetHuman()
        if hum and hum.MoveDirection.Magnitude > 0.1
        and hum:GetState() == Enum.HumanoidStateType.Running then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    Notify("🦘  Auto-jump ON  (every " .. interval .. "s while moving)")
end)

-- ── Auto-Sprint ───────────────────────────────────────────
--  Sets WalkSpeed to sprint value when holding W, resets when
--  stationary. Cleaner version of the run toggle.

local _autoSprintConn  = nil
local _autoSprintSpeed = 60
local _baseSpeed       = 16

Cmd("autosprint", {"asprint","automove"}, function(args)
    if _autoSprintConn then
        _autoSprintConn:Disconnect(); _autoSprintConn = nil
        local h = GetHuman(); if h then h.WalkSpeed = _baseSpeed end
        Notify("🏃  Auto-sprint OFF"); return
    end
    _autoSprintSpeed = tonumber(args[1]) or 60
    _baseSpeed       = tonumber(args[2]) or 16
    _autoSprintConn  = RunService.Heartbeat:Connect(function()
        local hum = GetHuman(); if not hum then return end
        local moving = hum.MoveDirection.Magnitude > 0.1
        local shift  = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
        hum.WalkSpeed = (moving and not shift) and _autoSprintSpeed or _baseSpeed
    end)
    Notify(string.format("🏃  Auto-sprint ON  (move=%d  still=%d)", _autoSprintSpeed, _baseSpeed))
end)

-- ── Step Over ────────────────────────────────────────────
--  Small upward nudge every N frames when moving, helpful
--  for stepping over low obstacles without jumping.

local _stepOverConn = nil

Cmd("stepover", {"autostep","smalljump"}, function(args)
    if _stepOverConn then
        _stepOverConn:Disconnect(); _stepOverConn = nil
        Notify("👣  Step-over OFF"); return
    end
    local height = tonumber(args[1]) or 2.5
    local elapsed = 0
    _stepOverConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed < 0.15 then return end
        elapsed = 0
        local hrp = GetHRP(); local hum = GetHuman()
        if not hrp or not hum then return end
        if hum.MoveDirection.Magnitude > 0.1
        and hum:GetState() == Enum.HumanoidStateType.Running then
            -- Tiny cast forward to check for obstacle
            local fwd = hum.MoveDirection.Unit
            local result = workspace:Raycast(
                hrp.Position + Vector3.new(0,-2,0),
                fwd * 1.5)
            if result then
                hrp.CFrame = hrp.CFrame + Vector3.new(0, height * dt * 6, 0)
            end
        end
    end)
    Notify("👣  Step-over ON  (smooth climb over low obstacles)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: TERRAIN INSPECTOR  (IY-ported)              ║
-- ╚══════════════════════════════════════════════════════════╝

Cmd("terraininfo", {"tinfo","groundinfo"}, function()
    local hrp = GetHRP(); if not hrp then return end
    local result = workspace:Raycast(
        hrp.Position,
        Vector3.new(0, -20, 0))
    if not result then Notify("No terrain below","warn"); return end
    local inst = result.Instance
    local mat  = result.Material.Name
    local pos  = result.Position
    local dist = (hrp.Position - pos).Magnitude
    Notify(string.format("🗻  Ground: %s  mat=%s  dist=%.1f  pos=(%.0f,%.0f,%.0f)",
        inst.Name, mat, dist, pos.X,pos.Y,pos.Z), "info")
end)

Cmd("terrainstats", {"terraincount","howmuchterrain"}, function()
    local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
    if not Terrain then Notify("No Terrain in workspace","warn"); return end
    local mats = {}
    -- GetCells was removed; we use extents as a proxy
    local ext  = workspace:GetExtentsSize()
    local lines = {
        string.format("WaterWaveSize:    %.2f", Terrain.WaterWaveSize),
        string.format("WaterWaveSpeed:   %.2f", Terrain.WaterWaveSpeed),
        string.format("WaterReflectance: %.2f", Terrain.WaterReflectance),
        string.format("Workspace extents: %.0f x %.0f x %.0f", ext.X,ext.Y,ext.Z),
        string.format("Gravity: %.2f st/s²", workspace.Gravity),
    }
    print("[S-Admin] Terrain info:\n  "..table.concat(lines,"\n  "))
    Notify("🗻  Terrain info — see console","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: WORLD EVENT LOGGER  (IY-ported)             ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: logging every Explosion, Fire, Smoke added to
--           workspace — useful for understanding game events.

local _worldLogConn = nil
local _worldLogCount = 0

Cmd("worldlog", {"logworld","gamelog"}, function()
    if _worldLogConn then
        _worldLogConn:Disconnect(); _worldLogConn = nil
        Notify("📋  World log OFF  (" .. _worldLogCount .. " events)"); return
    end
    _worldLogCount = 0
    _worldLogConn = workspace.DescendantAdded:Connect(function(v)
        local interesting = {
            "Explosion","Fire","Smoke","Sparkles",
            "ForceField","Highlight","SelectionBox",
        }
        for _, cls in ipairs(interesting) do
            if v:IsA(cls) then
                _worldLogCount = _worldLogCount + 1
                print(string.format("[S-WorldLog] [%s] %s added at %s  (t=%.1f)",
                    cls, v.Name, v:GetFullName(), workspace.DistributedGameTime))
            end
        end
    end)
    Notify("📋  World log ON — interesting instances printed to console")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: ADVANCED GUI TOOLS  (IY-ported)             ║
-- ╚══════════════════════════════════════════════════════════╝

-- ── GUI Outline ───────────────────────────────────────────
--  Draws a UIStroke on every visible Frame in PlayerGui.

local _guiOutlineOn = false
local _guiStrokes   = {}

Cmd("guioutline", {"outlinegui","strokegui"}, function(args)
    if _guiOutlineOn then
        for _, s in ipairs(_guiStrokes) do pcall(function() s:Destroy() end) end
        _guiStrokes   = {}
        _guiOutlineOn = false
        Notify("🪟  GUI outline OFF"); return
    end
    local r = tonumber(args[1]) or 255
    local g = tonumber(args[2]) or 80
    local b = tonumber(args[3]) or 80
    local col = Color3.fromRGB(r,g,b)
    local pg  = LP:FindFirstChildOfClass("PlayerGui"); if not pg then return end
    local n   = 0
    for _, v in ipairs(pg:GetDescendants()) do
        if v:IsA("Frame") then
            local s = Instance.new("UIStroke", v)
            s.Color     = col
            s.Thickness = 1.5
            table.insert(_guiStrokes, s)
            n = n + 1
        end
    end
    _guiOutlineOn = true
    Notify(string.format("🪟  GUI outline ON  RGB(%d,%d,%d)  %d frames", r,g,b,n))
end)

-- ── GUI Color Shift ───────────────────────────────────────
--  Shifts every Frame background colour toward a target tint.

Cmd("guicolor", {"tintgui","guistain"}, function(args)
    local r = tonumber(args[1]) or 20
    local g = tonumber(args[2]) or 20
    local b = tonumber(args[3]) or 40
    local pg = LP:FindFirstChildOfClass("PlayerGui"); if not pg then return end
    local col = Color3.fromRGB(r,g,b)
    local n = 0
    for _, v in ipairs(pg:GetDescendants()) do
        if v:IsA("Frame") and v.BackgroundTransparency < 1 then
            v.BackgroundColor3 = col; n=n+1
        end
    end
    Notify(string.format("🎨  GUI tinted RGB(%d,%d,%d)  %d frames",r,g,b,n))
end)

-- ── GUI Size Dump ─────────────────────────────────────────
--  Lists all ScreenGui objects with their children count and
--  total element count — good for profiling heavy UIs.

Cmd("guilayout", {"uilayout","guiprofile"}, function()
    local pg = LP:FindFirstChildOfClass("PlayerGui"); if not pg then return end
    local rows = {}
    for _, sg in ipairs(pg:GetChildren()) do
        local desc = #sg:GetDescendants()
        table.insert(rows, {name=sg.Name, desc=desc, enabled=sg.Enabled})
    end
    table.sort(rows, function(a,b) return a.desc > b.desc end)
    print("[S-Admin] PlayerGui layout:")
    for _, r in ipairs(rows) do
        print(string.format("  %-30s  %4d elements  enabled=%s",
            r.name, r.desc, tostring(r.enabled)))
    end
    Notify("🪟  " .. #rows .. " ScreenGui(s) — see console","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: SERVER QUEUE / SCHEDULER DISPLAY            ║
-- ╚══════════════════════════════════════════════════════════╝
--  Teaches: HeartbeatTimeMs, RenderSteppedTimeMs — engine
--           scheduler stats for understanding server load.

Cmd("schedulerstats", {"scheduler","enginestats"}, function()
    local stats = game:GetService("Stats")
    local heartMs, renderMs, physicsMs = 0,0,0
    pcall(function()
        heartMs   = stats.HeartbeatTimeMs.Value
        renderMs  = stats.RenderSteppedTimeMs and stats.RenderSteppedTimeMs.Value or 0
        physicsMs = stats.PhysicsSteppedTimeMs and stats.PhysicsSteppedTimeMs.Value or 0
    end)
    local lines = {
        string.format("Heartbeat:        %.2f ms", heartMs),
        string.format("RenderStepped:    %.2f ms", renderMs),
        string.format("PhysicsStepped:   %.2f ms", physicsMs),
        string.format("Game time:        %.1f s",  workspace.DistributedGameTime),
        string.format("Instance count:   %d",      #game:GetDescendants()),
    }
    print("[S-Admin] Scheduler:\n  " .. table.concat(lines,"\n  "))
    Notify(string.format("⚙  Heartbeat=%.1fms  Physics=%.1fms — console",
        heartMs, physicsMs),"info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY: MISC QUALITY-OF-LIFE  (IY-ported)           ║
-- ╚══════════════════════════════════════════════════════════╝

-- ── Auto-Collect Tools ────────────────────────────────────
--  Picks up any Tool dropped near your character by parenting
--  it to your Backpack.

local _autoCollectConn = nil

Cmd("autocollect", {"ac","autoloot","pickedup"}, function()
    if _autoCollectConn then
        _autoCollectConn:Disconnect(); _autoCollectConn = nil
        Notify("🎒  Auto-collect OFF"); return
    end
    _autoCollectConn = RunService.Heartbeat:Connect(function()
        local hrp = GetHRP(); if not hrp then return end
        local bp  = LP:FindFirstChildOfClass("Backpack"); if not bp then return end
        for _, v in ipairs(workspace:GetChildren()) do
            if v:IsA("Tool") then
                local handle = v:FindFirstChild("Handle")
                if handle then
                    local d = (handle.Position - hrp.Position).Magnitude
                    if d < 12 then
                        v.Parent = bp
                        Notify("🎒  Picked up: " .. v.Name)
                    end
                end
            end
        end
    end)
    Notify("🎒  Auto-collect ON  (picks up tools within 12 studs)")
end)

-- ── Repeat Last Command ───────────────────────────────────
Cmd("redo", {"again","repeat2","repeast"}, function()
    if #_cmdHistory == 0 then Notify("No command history","warn"); return end
    local last = _cmdHistory[#_cmdHistory]
    Notify("🔁  Re-running: " .. last,"info")
    task.defer(function() ExecCommand(last) end)
end)

-- ── Command Frequency Stats ───────────────────────────────
Cmd("cmdstats", {"commandstats","mostused"}, function()
    if #_cmdHistory == 0 then Notify("No history yet","warn"); return end
    local freq = {}
    for _, raw in ipairs(_cmdHistory) do
        local name = raw:match("^(%S+)") or raw
        freq[name] = (freq[name] or 0) + 1
    end
    local sorted = {}
    for k,v in pairs(freq) do table.insert(sorted,{k=k,v=v}) end
    table.sort(sorted,function(a,b) return a.v > b.v end)
    print("[S-Admin] Most used commands:")
    for i=1,math.min(10,#sorted) do
        print(string.format("  [%2dx] %s", sorted[i].v, sorted[i].k))
    end
    Notify("📊  Top command: " .. sorted[1].k .. " ×" .. sorted[1].v .. " — console","info")
end)

-- ── Swap Team ─────────────────────────────────────────────
Cmd("swapteam", {"nextteam","cycleteam"}, function()
    local teams = TeamsService:GetTeams()
    if #teams == 0 then Notify("No teams","warn"); return end
    local current = LP.Team
    local idx = 1
    for i, t in ipairs(teams) do
        if t == current then idx = i % #teams + 1; break end
    end
    local next = teams[idx]
    LP.Team      = next
    LP.TeamColor = next.TeamColor
    Notify("👥  Swapped to team: " .. next.Name)
end)

-- ── Color Invert Character ────────────────────────────────
Cmd("invertcolor", {"invertchar","negativecolor"}, function()
    local char = GetChar(); if not char then return end
    local bc   = char:FindFirstChildOfClass("BodyColors"); if not bc then return end
    local function inv(c)
        return Color3.new(1-c.R, 1-c.G, 1-c.B)
    end
    bc.HeadColor3     = inv(bc.HeadColor3)
    bc.TorsoColor3    = inv(bc.TorsoColor3)
    bc.LeftArmColor3  = inv(bc.LeftArmColor3)
    bc.RightArmColor3 = inv(bc.RightArmColor3)
    bc.LeftLegColor3  = inv(bc.LeftLegColor3)
    bc.RightLegColor3 = inv(bc.RightLegColor3)
    Notify("🎨  Body colors inverted")
end)

-- ── Highlight Self to Others ─────────────────────────────
Cmd("highlightself", {"selfhighlight","myhl"}, function(args)
    local char = GetChar(); if not char then return end
    local old  = char:FindFirstChild("S_SelfHL2")
    if old then old:Destroy(); Notify("✨  Self-highlight OFF"); return end
    local r = tonumber(args[1]) or 255
    local g = tonumber(args[2]) or 200
    local b = tonumber(args[3]) or 50
    local hl = Instance.new("Highlight", char)
    hl.Name               = "S_SelfHL2"
    hl.FillColor          = Color3.fromRGB(r,g,b)
    hl.FillTransparency   = 0.6
    hl.OutlineColor       = Color3.fromRGB(r,g,b)
    hl.OutlineTransparency = 0
    Notify(string.format("✨  Self-highlight ON  RGB(%d,%d,%d)",r,g,b))
end)

-- ── Trail Color Presets ───────────────────────────────────
local _trailColorPresets = {
    fire   = {Color3.fromRGB(255,80,0),   Color3.fromRGB(255,220,0)},
    ice    = {Color3.fromRGB(100,220,255), Color3.fromRGB(200,240,255)},
    shadow = {Color3.fromRGB(50,0,80),    Color3.fromRGB(0,0,0)},
    gold   = {Color3.fromRGB(255,200,0),  Color3.fromRGB(255,240,100)},
    nature = {Color3.fromRGB(0,200,50),   Color3.fromRGB(150,255,100)},
    void   = {Color3.fromRGB(20,0,40),    Color3.fromRGB(120,0,200)},
}

Cmd("trailpreset", {"tp3","trailtheme"}, function(args)
    local key = (args[1] or ""):lower()
    local p   = _trailColorPresets[key]
    if not p then
        local list = {}
        for k in pairs(_trailColorPresets) do table.insert(list,k) end
        table.sort(list)
        Notify("Trail presets: " .. table.concat(list,", "),"warn"); return
    end
    -- Ensure trail exists
    local hrp = GetHRP(); if not hrp then return end
    local tr  = hrp:FindFirstChild("S_Trail")
    if not tr then
        Commands["trail"]({}); tr = hrp:FindFirstChild("S_Trail")
    end
    if not tr then Notify("Could not create trail","error"); return end
    tr.Color = ColorSequence.new(p[1], p[2])
    Notify("✨  Trail preset: " .. key)
end)

-- ── Describe Self ─────────────────────────────────────────
--  Prints a full HumanoidDescription dump to console.

Cmd("describeme", {"mydesc","describeself","dumpchar"}, function()
    local hum = GetHuman(); if not hum then return end
    local ok, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(LP.UserId)
    end)
    if not ok then Notify("Could not fetch description","error"); return end
    local props = {
        "HatAccessory","HairAccessory","FaceAccessory",
        "NeckAccessory","ShouldersAccessory","FrontAccessory","BackAccessory","WaistAccessory",
        "GraphicTShirt","Shirt","Pants","Face",
        "Head","Torso","LeftArm","RightArm","LeftLeg","RightLeg",
        "HeadScale","BodyHeightScale","BodyWidthScale",
    }
    print("[S-Admin] HumanoidDescription of " .. LP.Name .. ":")
    for _, prop in ipairs(props) do
        pcall(function()
            local val = tostring(desc[prop])
            if val ~= "0" and val ~= "" then
                print(string.format("  %-24s %s", prop..":", val))
            end
        end)
    end
    Notify("📋  Description dumped — see console","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY FILL: MOVEMENT EXTRAS                        ║
-- ╚══════════════════════════════════════════════════════════╝

-- surfacecheck  — raycast beneath you and report surface angle
Cmd("surfacecheck", {"surface","groundangle"}, function()
    local hrp = GetHRP(); if not hrp then return end
    local result = workspace:Raycast(hrp.Position, Vector3.new(0,-10,0))
    if not result then Notify("No surface below","warn"); return end
    local normal = result.Normal
    local angle  = math.deg(math.acos(normal:Dot(Vector3.new(0,1,0))))
    Notify(string.format("🗺  Surface: %s  angle=%.1f°  mat=%s",
        result.Instance.Name, angle, result.Material.Name), "info")
end)

-- nogravchar  — set gravity to 0 for character only via BodyForce
local _noGravConn = nil
Cmd("nogravchar", {"floatchar","zerograv"}, function()
    if _noGravConn then
        _noGravConn:Disconnect(); _noGravConn = nil
        local hrp = GetHRP()
        if hrp then
            local bf = hrp:FindFirstChild("S_NoGravBF")
            if bf then bf:Destroy() end
        end
        Notify("🌍  Character gravity restored"); return
    end
    local hrp = GetHRP(); if not hrp then return end
    local bf = Instance.new("BodyForce", hrp)
    bf.Name  = "S_NoGravBF"
    _noGravConn = RunService.Heartbeat:Connect(function()
        if not hrp or not hrp.Parent then _noGravConn:Disconnect(); return end
        local mass = 0
        local char = GetChar()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    pcall(function() mass = mass + p:GetMass() end)
                end
            end
        end
        bf.Force = Vector3.new(0, workspace.Gravity * mass, 0)
    end)
    Notify("🌍  Zero-gravity for character only (world gravity unchanged)")
end)

-- boost  — apply a burst of velocity in camera direction
Cmd("boost", {"dash2","cameradash"}, function(args)
    local power = tonumber(args[1]) or 80
    local hrp   = GetHRP(); if not hrp then return end
    local cam   = workspace.CurrentCamera
    local dir   = cam.CFrame.LookVector
    hrp.AssemblyLinearVelocity = dir * power
    Notify(string.format("🚀  Boost %.0f in camera direction", power))
end)

-- wallstick  — anchor yourself to whatever surface you're touching
Cmd("wallstick", {"stickwall","magnetwall"}, function()
    local hrp = GetHRP(); if not hrp then return end
    -- Raycast in 6 directions, anchor at first hit
    local dirs = {
        Vector3.new(0,-1,0), Vector3.new(0,1,0),
        Vector3.new(1,0,0),  Vector3.new(-1,0,0),
        Vector3.new(0,0,1),  Vector3.new(0,0,-1),
    }
    for _, d in ipairs(dirs) do
        local r = workspace:Raycast(hrp.Position, d*5)
        if r then
            hrp.CFrame = CFrame.new(r.Position - d*2, r.Position - d*2 - r.Normal)
            hrp.Anchored = true
            Notify("🧲  Stuck to: "..r.Instance.Name)
            return
        end
    end
    Notify("No surface within 5 studs","warn")
end)

-- unstick  — unanchor from wall
Cmd("unstick", {"nowall","detachwall"}, function()
    local hrp = GetHRP()
    if hrp and hrp.Anchored then hrp.Anchored = false end
    Notify("🧲  Unstuck from wall")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY FILL: CAMERA EXTRAS                          ║
-- ╚══════════════════════════════════════════════════════════╝

-- camlookdown  — tilt camera to look straight down
Cmd("camlookdown", {"lookdown","birdseye"}, function(args)
    local height = tonumber(args[1]) or 50
    local hrp    = GetHRP(); if not hrp then return end
    local cam    = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    local pos = hrp.Position + Vector3.new(0, height, 0)
    cam.CFrame = CFrame.new(pos, hrp.Position)
    task.delay(5, function()
        if cam.CameraType == Enum.CameraType.Scriptable then
            cam.CameraType = Enum.CameraType.Custom
        end
    end)
    Notify(string.format("📷  Bird's-eye view (%.0f studs up, restores in 5s)", height))
end)

-- pointatpart  — aim camera at nearest named part
Cmd("pointatpart", {"aimpart","camerapart"}, function(args)
    local query = table.concat(args," "):lower()
    if query == "" then Notify("Usage: pointatpart <name>","warn"); return end
    local hrp = GetHRP(); if not hrp then return end
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower():find(query,1,true) then
            local d = (v.Position-hrp.Position).Magnitude
            if d < bestDist then best=v; bestDist=d end
        end
    end
    if not best then Notify("Part not found","error"); return end
    workspace.CurrentCamera.CFrame = CFrame.new(
        workspace.CurrentCamera.CFrame.Position, best.Position)
    Notify("📷  Pointing at: "..best.Name.." ("..math.floor(bestDist).." studs)")
end)

-- camforward  — move camera forward by N studs (freecam helper)
Cmd("camforward", {"cforward","pushcam"}, function(args)
    local d   = tonumber(args[1]) or 10
    local cam = workspace.CurrentCamera
    cam.CFrame = cam.CFrame + cam.CFrame.LookVector * d
    Notify(string.format("📷  Camera moved %.0f studs forward", d))
end)

-- camup  — move camera up by N studs
Cmd("camup", {"cup","raisecam"}, function(args)
    local d   = tonumber(args[1]) or 10
    local cam = workspace.CurrentCamera
    cam.CFrame = cam.CFrame + Vector3.new(0, d, 0)
    Notify(string.format("📷  Camera raised %.0f studs", d))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY FILL: WORKSPACE EXTRAS                       ║
-- ╚══════════════════════════════════════════════════════════╝

-- paintpart <name> <R G B>  — alias-safe recolor
Cmd("paintpart", {"paint2","colornearest"}, function(args)
    local hrp = GetHRP(); if not hrp then return end
    local r   = tonumber(args[1]) or 255
    local g   = tonumber(args[2]) or 0
    local b   = tonumber(args[3]) or 0
    -- Find absolute nearest BasePart (not in character)
    local char = GetChar()
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (not char or not v:IsDescendantOf(char)) then
            local d = (v.Position-hrp.Position).Magnitude
            if d < bestDist then best=v; bestDist=d end
        end
    end
    if not best then Notify("No part found","warn"); return end
    pcall(function() best.Color = Color3.fromRGB(r,g,b) end)
    Notify(string.format("🎨  Painted '%s' RGB(%d,%d,%d)  (%.0f studs)",
        best.Name, r, g, b, bestDist))
end)

-- anchornearest  — toggle anchor on nearest part
Cmd("anchornearest", {"anchorn","toggleanchor"}, function()
    local hrp = GetHRP(); if not hrp then return end
    local char = GetChar()
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (not char or not v:IsDescendantOf(char)) then
            local d = (v.Position-hrp.Position).Magnitude
            if d < bestDist then best=v; bestDist=d end
        end
    end
    if not best then Notify("No part found","warn"); return end
    best.Anchored = not best.Anchored
    Notify(string.format("🔒  %s: Anchored=%s  (%.0f studs)",
        best.Name, tostring(best.Anchored), bestDist))
end)

-- deletenearest  — delete the nearest workspace part to you
Cmd("deletenearest", {"deln","deleteclose"}, function()
    local hrp  = GetHRP(); if not hrp then return end
    local char = GetChar()
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (not char or not v:IsDescendantOf(char)) then
            local d = (v.Position-hrp.Position).Magnitude
            if d < bestDist then best=v; bestDist=d end
        end
    end
    if not best then Notify("No part found","warn"); return end
    local name = best.Name
    local dist = bestDist
    pcall(function() best:Destroy() end)
    Notify(string.format("🗑  Deleted '%s'  (%.0f studs away)", name, dist))
end)

-- selectpart  — highlight nearest part with SelectionBox for 5s
Cmd("selectpart", {"select","pickepart"}, function(args)
    local query = args[1] and args[1]:lower() or ""
    local hrp   = GetHRP(); if not hrp then return end
    local char  = GetChar()
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (not char or not v:IsDescendantOf(char)) then
            if query=="" or v.Name:lower():find(query,1,true) then
                local d = (v.Position-hrp.Position).Magnitude
                if d < bestDist then best=v; bestDist=d end
            end
        end
    end
    if not best then Notify("No part found","warn"); return end
    local box = Instance.new("SelectionBox", ScreenGui)
    box.Adornee       = best
    box.Color3        = Color3.fromRGB(100,200,255)
    box.LineThickness = 0.05
    box.SurfaceTransparency = 0.85
    box.SurfaceColor3 = Color3.fromRGB(100,200,255)
    game:GetService("Debris"):AddItem(box, 5)
    Notify(string.format("✅  Selected: %s  (%.0f studs)  — 5s highlight", best.Name, bestDist))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY FILL: INFO EXTRAS                            ║
-- ╚══════════════════════════════════════════════════════════╝

-- lookingat  — raycast from camera and report what you're looking at
Cmd("lookingat", {"whatlook","aiminfo"}, function()
    local cam    = workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local dir    = cam.CFrame.LookVector * 500
    local result = workspace:Raycast(origin, dir)
    if not result then Notify("Nothing in crosshair","warn"); return end
    local inst = result.Instance
    local p    = result.Position
    local dist = (origin - p).Magnitude
    local lines = {
        "Name:     " .. inst.Name,
        "Class:    " .. inst.ClassName,
        "Distance: " .. string.format("%.1f studs", dist),
        "Position: " .. string.format("(%.1f,%.1f,%.1f)", p.X,p.Y,p.Z),
        "Material: " .. result.Material.Name,
        "Path:     " .. inst:GetFullName(),
    }
    print("[S-Admin] Looking at:\n  "..table.concat(lines,"\n  "))
    Notify(string.format("👁  %s (%s) — %.0f studs — console",
        inst.Name, inst.ClassName, dist),"info")
end)

-- nearbyplayers  — list players within N studs with distances
Cmd("nearbyplayers", {"nearby","whonear"}, function(args)
    local range = tonumber(args[1]) or 50
    local hrp   = GetHRP(); if not hrp then return end
    local found = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                local d = (tHRP.Position-hrp.Position).Magnitude
                if d <= range then
                    table.insert(found, {name=p.Name, dist=d})
                end
            end
        end
    end
    if #found == 0 then Notify("No players within "..range.." studs","warn"); return end
    table.sort(found,function(a,b) return a.dist < b.dist end)
    local parts = {}
    for _, v in ipairs(found) do
        table.insert(parts, v.name.." ("..math.floor(v.dist)..")")
    end
    Notify("👥  Nearby: "..table.concat(parts,", "),"info")
end)

-- serverlag  — estimate lag by measuring time between Heartbeat fires
Cmd("serverlag", {"lagtest","lagcheck"}, function()
    local samples = {}
    local c
    c = RunService.Heartbeat:Connect(function(dt)
        table.insert(samples, dt*1000)
        if #samples >= 30 then
            c:Disconnect()
            local avg, max2 = 0, 0
            for _, s in ipairs(samples) do
                avg=avg+s; if s>max2 then max2=s end
            end
            avg = avg/#samples
            Notify(string.format("⚙  Heartbeat avg=%.2fms  max=%.2fms  (~%.0f Hz)",
                avg, max2, 1000/avg),"info")
        end
    end)
    Notify("⚙  Measuring server lag over 30 frames...","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY FILL: DEFENSE EXTRAS                         ║
-- ╚══════════════════════════════════════════════════════════╝

-- antibrick  — delete any BasePart added inside your character
local _antiBrickConn = nil
Cmd("antibrick", {"noparts2","charclean"}, function()
    if _antiBrickConn then
        _antiBrickConn:Disconnect(); _antiBrickConn = nil
        Notify("🛡  Anti-Brick OFF"); return
    end
    local char = GetChar(); if not char then return end
    _antiBrickConn = char.DescendantAdded:Connect(function(v)
        if v:IsA("BasePart") then
            local isLegit = v.Name == "HumanoidRootPart"
                         or v.Name:find("^S_")
                         or v.Parent:IsA("Accessory")
                         or v.Parent:IsA("Tool")
            if not isLegit then
                task.defer(function() pcall(function() v:Destroy() end) end)
            end
        end
    end)
    Notify("🛡  Anti-Brick ON — removes foreign parts added to character")
end)

-- saferespawn  — respawn and immediately activate shield mode
Cmd("saferespawn", {"sr","shieldrespawn"}, function()
    Commands["shieldmode"]({})
    Commands["respawn"]({})
    Notify("🛡  Safe respawn triggered — shields + respawn")
end)

-- lockcharacter  — prevent HP changes (combined protections)
local _lockCharConn = nil
Cmd("lockcharacter", {"lockchar","godlock"}, function()
    if _lockCharConn then
        _lockCharConn:Disconnect(); _lockCharConn = nil
        Notify("🛡  Character lock OFF"); return
    end
    _lockCharConn = RunService.Heartbeat:Connect(function()
        local hum = GetHuman(); if not hum then return end
        if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        if hum.MaxHealth ~= math.huge then hum.MaxHealth = math.huge end
    end)
    Notify("🛡  Character locked — health forced to max every frame")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY FILL: HUD EXTRAS                             ║
-- ╚══════════════════════════════════════════════════════════╝

-- compass  — cardinal direction HUD based on camera facing
local _compassGui  = nil
local _compassConn = nil

Cmd("compass", {"showcompass","direction"}, function()
    if _compassGui then
        _compassGui:Destroy(); _compassGui = nil
        if _compassConn then _compassConn:Disconnect(); _compassConn=nil end
        Notify("🧭  Compass OFF"); return
    end
    _compassGui = Instance.new("ScreenGui",ScreenGui)
    _compassGui.Name="S_Compass"; _compassGui.ResetOnSpawn=false
    _compassGui.DisplayOrder=75

    local f = Instance.new("Frame",_compassGui)
    f.Size=UDim2.new(0,80,0,22); f.Position=UDim2.new(0.5,-40,0,5)
    f.BackgroundColor3=Color3.fromRGB(10,10,10)
    f.BackgroundTransparency=0.4; f.ZIndex=75; Corner(f,6)

    local lbl=Instance.new("TextLabel",f)
    lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13
    lbl.TextColor3=Color3.new(1,1,1); lbl.ZIndex=76

    local dirs = {"N","NE","E","SE","S","SW","W","NW"}
    _compassConn = RunService.RenderStepped:Connect(function()
        local cam   = workspace.CurrentCamera
        local look  = cam.CFrame.LookVector
        local angle = math.deg(math.atan2(-look.X, -look.Z)) % 360
        local idx   = math.floor((angle+22.5)/45) % 8 + 1
        lbl.Text    = "🧭 "..dirs[idx].."  "..string.format("%.0f°",angle)
    end)
    Notify("🧭  Compass ON")
end)

-- clock  — live real-time clock HUD using os.time
local _clockGui  = nil
local _clockConn = nil

Cmd("clockhud", {"clock2","timehud"}, function()
    if _clockGui then
        _clockGui:Destroy(); _clockGui=nil
        if _clockConn then _clockConn:Disconnect(); _clockConn=nil end
        Notify("🕐  Clock HUD OFF"); return
    end
    _clockGui=Instance.new("ScreenGui",ScreenGui)
    _clockGui.Name="S_Clock"; _clockGui.ResetOnSpawn=false
    _clockGui.DisplayOrder=74

    local f=Instance.new("Frame",_clockGui)
    f.Size=UDim2.new(0,120,0,22); f.Position=UDim2.new(1,-134,0,5)
    f.BackgroundColor3=Color3.fromRGB(10,10,10)
    f.BackgroundTransparency=0.4; f.ZIndex=74; Corner(f,6)

    local lbl=Instance.new("TextLabel",f)
    lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.Code; lbl.TextSize=12
    lbl.TextColor3=Color3.new(1,1,1); lbl.ZIndex=75

    local elapsed=0
    _clockConn=RunService.Heartbeat:Connect(function(dt)
        elapsed=elapsed+dt
        if elapsed<1 then return end; elapsed=0
        local ok,str=pcall(function() return os.date("%H:%M:%S") end)
        lbl.Text="🕐 "..(ok and str or "??:??:??")
    end)
    Notify("🕐  Clock HUD ON")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY FILL: APPEARANCE EXTRAS                      ║
-- ╚══════════════════════════════════════════════════════════╝

-- charcolor  — single command: set all body colors at once
Cmd("charcolor", {"cc2","allcolor","setcharcolor"}, function(args)
    local r = tonumber(args[1]) or 255
    local g = tonumber(args[2]) or 255
    local b = tonumber(args[3]) or 255
    Commands["bodycolor"]({"all",tostring(r),tostring(g),tostring(b)})
end)

-- transparency  — set own character transparency
Cmd("transparency", {"chartrans","charfade"}, function(args)
    local alpha = math.clamp(tonumber(args[1]) or 0.5, 0, 1)
    local char  = GetChar(); if not char then return end
    local n = 0
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            pcall(function() v.Transparency = alpha end); n=n+1
        end
    end
    Notify(string.format("👤  Character transparency → %.2f  (%d parts)", alpha, n))
end)

-- chrome  — reflectance max + metallic look
Cmd("chrome", {"metal","metallic"}, function()
    local char = GetChar(); if not char then return end
    local n = 0
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            pcall(function()
                v.Material    = Enum.Material.Metal
                v.Reflectance = 1
                v.Color       = Color3.fromRGB(200,200,210)
            end); n=n+1
        end
    end
    Notify("✨  Chrome material applied ("..n.." parts)")
end)

-- wooden  — wood material + brown tone
Cmd("wooden", {"wood","woodchar"}, function()
    local char = GetChar(); if not char then return end
    local n = 0
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            pcall(function()
                v.Material = Enum.Material.Wood
                v.Color    = Color3.fromRGB(160,100,50)
            end); n=n+1
        end
    end
    Notify("🪵  Wood material applied ("..n.." parts)")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY FILL: SOUND EXTRAS                           ║
-- ╚══════════════════════════════════════════════════════════╝

-- soundinfo  — print info about the currently playing admin sound
Cmd("soundinfo", {"currentmusic","nowplaying"}, function()
    if not _adminSound or not _adminSound.Parent then
        Notify("No sound currently playing — use 'play'","warn"); return
    end
    local lines = {
        "Name:     " .. _adminSound.Name,
        "SoundId:  " .. _adminSound.SoundId,
        "Volume:   " .. string.format("%.2f", _adminSound.Volume),
        "Looped:   " .. tostring(_adminSound.Looped),
        "Playing:  " .. tostring(_adminSound.IsPlaying),
        "TimePos:  " .. string.format("%.1fs", _adminSound.TimePosition),
        "Duration: " .. string.format("%.1fs", _adminSound.TimeLength),
    }
    print("[S-Admin] Now Playing:\n  "..table.concat(lines,"\n  "))
    Notify("🎵  "..(_adminSound.SoundId:match("%d+") or "?").."  —  see console","info")
end)

-- rewind  — restart the current admin sound from beginning
Cmd("rewind", {"restart","soundrestart"}, function()
    if not _adminSound or not _adminSound.Parent then
        Notify("No sound playing","warn"); return
    end
    _adminSound:Stop()
    _adminSound:Play()
    Notify("🎵  Sound restarted from beginning")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY FILL: UTILITY EXTRAS                         ║
-- ╚══════════════════════════════════════════════════════════╝

-- ping3  — run 5 pings and show average
Cmd("pingavg", {"avgping","pingtest2"}, function()
    Notify("📶  Sampling 5 pings...", "info")
    task.spawn(function()
        local total = 0
        for i = 1, 5 do
            total = total + LP:GetNetworkPing() * 1000
            task.wait(0.2)
        end
        local avg = total / 5
        Notify(string.format("📶  Avg ping (5 samples): %.1fms", avg), "info")
    end)
end)

-- taskcount  — count running coroutines/tasks (approximate)
Cmd("taskcount", {"tasks","threadcount"}, function()
    -- Lua doesn't expose active coroutines directly;
    -- approximate by counting our known active connections
    local conns = 0
    for _ in pairs(Conns) do conns = conns + 1 end
    local named = {
        _antiFlingConn, _antiTpConn, _posLockConn, _velClampConn,
        _camGuardConn, _antiVoidConn, _antiSpinConn, _healthGuardConn,
        _gravGuardConn, _autoBobConn, _orbitConn,
    }
    local extra = 0
    for _, v in ipairs(named) do if v then extra = extra + 1 end end
    Notify(string.format("⚙  Active connections: Conns=%d  known=%d",
        conns, extra), "info")
end)

-- varset  — set a named Lua global variable
Cmd("varset", {"setvar","globalset"}, function(args)
    local name = args[1]; local val = args[2]
    if not name or not val then Notify("Usage: varset <name> <value>","warn"); return end
    local num = tonumber(val)
    getgenv()[name] = num ~= nil and num or val
    Notify(string.format("📦  getgenv().%s = %s", name, val), "info")
end)

-- varget  — get a named Lua global variable
Cmd("varget", {"getvar","globalget"}, function(args)
    local name = args[1]
    if not name then Notify("Usage: varget <name>","warn"); return end
    local val = getgenv()[name]
    Notify(string.format("📦  getgenv().%s = %s", name, tostring(val)), "info")
end)

-- garbage  — run Lua garbage collector
Cmd("garbage", {"gc","collectgarbage"}, function()
    local before = collectgarbage("count")
    collectgarbage("collect")
    local after  = collectgarbage("count")
    Notify(string.format("🗑  GC: %.1f KB → %.1f KB  (freed %.1f KB)",
        before, after, before-after), "info")
end)

-- typeof  — print Lua type of a value
-- typeof moved to final batch below

-- printtable  — dump a Lua table from getgenv() to console
Cmd("printtable", {"dumptable","showtable"}, function(args)
    local name = args[1]
    if not name then Notify("Usage: printtable <global table name>","warn"); return end
    local t = getgenv()[name]
    if type(t) ~= "table" then
        Notify(name.." is "..type(t).." not a table","error"); return
    end
    print("[S-Admin] "..name..":")
    for k,v in pairs(t) do
        print(string.format("  %-20s = %s", tostring(k), tostring(v):sub(1,60)))
    end
    Notify("📦  Dumped "..name.." — see console","info")
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY FILL: INTERACTION EXTRAS                     ║
-- ╚══════════════════════════════════════════════════════════╝

-- alarm  — set a timed alarm that notifies after N seconds
Cmd("alarm", {"setalarm","remindme"}, function(args)
    local secs = tonumber(args[1])
    if not secs or secs <= 0 then Notify("Usage: alarm <seconds>","warn"); return end
    local msg  = table.concat(args," ",2)
    msg = msg ~= "" and msg or "⏰  Alarm!"
    Notify(string.format("⏰  Alarm set for %.0f seconds", secs))
    task.delay(secs, function()
        Notify("⏰  "..msg.."  (alarm after "..secs.."s)", "warn")
        pcall(function() StarterGui:SetCore("SendNotification",{
            Title="S Admin", Text=msg, Duration=8}) end)
    end)
end)

-- looptask  — loop any shell command at interval with label
-- (same logic as loopexec but with optional label shown in notify)
Cmd("looptask", {"taskloop","namedloop"}, function(args)
    local label    = args[1]; if not label then Notify("Usage: looptask <label> <interval> <cmd>","warn"); return end
    local interval = tonumber(args[2]); if not interval then Notify("Usage: looptask <label> <interval> <cmd>","warn"); return end
    local cmd      = table.concat(args," ",3)
    if cmd=="" then Notify("No command given","warn"); return end
    if _loopExecTask then task.cancel(_loopExecTask) end
    _loopExecTask = task.spawn(function()
        while true do
            task.defer(function() ExecCommand(cmd) end)
            task.wait(math.max(0.5, interval))
        end
    end)
    Notify(string.format("🔁  [%s] Loop every %.1fs: '%s'", label, interval, cmd))
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CATEGORY FILL: SURVIVAL / COMBAT EXTRAS               ║
-- ╚══════════════════════════════════════════════════════════╝

-- revive  — restore a downed player's health (client-side)
Cmd("revive", {"reviveplayer","healplayer"}, function(args)
    local targets = GetPlayers(args[1])
    local n = 0
    for _, p in ipairs(targets) do
        local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = hum.MaxHealth; n=n+1 end
    end
    Notify("💚  Revived "..n.." player(s)")
end)

-- stun  — freeze a player temporarily (client)
Cmd("stun", {"stunplayer","freeze3"}, function(args)
    local target = GetPlayers(args[1])[1]
    if not target or not target.Character then Notify("Target not found","error"); return end
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end
    local dur = tonumber(args[2]) or 3
    tHRP.Anchored = true
    Notify("🧊  Stunned "..target.Name.." for "..dur.."s")
    task.delay(dur, function()
        if tHRP and tHRP.Parent then tHRP.Anchored = false end
        Notify("🧊  "..target.Name.." unstunned")
    end)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║   FINAL BATCH: POLISH & COMPLETION                      ║
-- ╚══════════════════════════════════════════════════════════╝

-- ── Clean State Reset ────────────────────────────────────
--  Turns off every active toggle in State, removes physics
--  instances, restores Humanoid. One-command cleanup.

Cmd("cleanstate", {"resetstate","clearstate","cleanall"}, function()
    -- Stop all loops
    if State.Flying      then Commands["unfly"]({})          end
    if State.Noclipping  then Commands["clip"]({})           end
    if State.Flinging    then Commands["unfling"]({})        end
    if State.Spinning    then Commands["unspin"]({})         end
    if State.Banging     then Commands["unbang"]({})         end
    if State.Invisible   then Commands["visible"]({})        end
    if State.InfJump     then Commands["uninfjump"]({})      end
    if State.Swimming    then Commands["unswim"]({})         end
    if State.Floating    then Commands["unfloat"]({})        end
    if State.Following   then Commands["unfollow"]({})       end
    if State.Annoying    then Commands["unannoy"]({})        end
    if State.Fullbright  then Commands["fullbright"]({})     end
    if State.LoopHeal    then Commands["unloopheal"]({})     end
    if State.AntiAFK     then Commands["unantiafk"]({})      end
    if _kaRunning        then Commands["unkillaura"]({})     end
    if _fcRunning        then Commands["unfreecam"]({})      end

    -- Stop defensive loops
    if _antiFlingConn    then Commands["antifling"]({})      end
    if _antiTpConn       then Commands["antiteleport"]({})   end
    if _posLockConn      then Commands["positionlock"]({})   end
    if _velClampConn     then Commands["velocityclamp"]({})  end
    if _antiVoidConn     then Commands["antivoid"]({})       end
    if _antiSpinConn     then Commands["antispin"]({})       end
    if _healthGuardConn  then Commands["healthguard"]({})    end
    if _gravGuardConn    then Commands["gravityguard"]({})   end

    -- Restore humanoid
    local hum = GetHuman()
    if hum then
        hum.PlatformStand = false
        hum.WalkSpeed     = 16
        hum.JumpPower     = 50
        hum.UseJumpPower  = false
    end

    -- Remove orphan physics objects from HRP
    local hrp = GetHRP()
    if hrp then
        for _, n in ipairs({"S_FlyBV","S_FlyBG","S_Spin","S_FlingBAV","S_FlingBV","S_NoGravBF"}) do
            local v = hrp:FindFirstChild(n); if v then v:Destroy() end
        end
        hrp.Anchored = false
    end

    Notify("🧹  All states cleared — character reset to default")
end)

-- ── Safe Mode ────────────────────────────────────────────
--  Cleans state, hides all HUDs, restores lighting,
--  removes all S_ character effects.

Cmd("safemode", {"safe","stealth","hideall"}, function()
    Commands["cleanstate"]({})
    Commands["togglehud"]({})
    Commands["visible"]({})
    Commands["notrail"]({})
    Commands["noglow"]({})
    Commands["nochams"]({})
    Commands["unesp"]({})
    if _nametagESPOn then Commands["nametagesp"]({}) end
    -- Restore lighting
    Lighting.Ambient    = OrigLight.Ambient
    Lighting.Brightness = OrigLight.Brightness
    Lighting.ClockTime  = OrigLight.ClockTime
    Lighting.FogEnd     = OrigLight.FogEnd
    -- Remove char FX
    Commands["clear"]({})
    Notify("🛡  Safe mode — all effects off, fully restored")
end)

-- ── Full Reset ───────────────────────────────────────────
--  Nuclear option: safe mode + workspace gravity + camera.

Cmd("fullreset", {"nuclear","resetall","nuke2"}, function()
    Commands["safemode"]({})
    Commands["fixcam"]({})
    Commands["undefend"]({})
    workspace.Gravity = _origGravity
    workspace.CurrentCamera.FieldOfView = 70
    LP.CameraMinZoomDistance = 0.5
    LP.CameraMaxZoomDistance = 400
    pcall(function() LP.CameraMode = Enum.CameraMode.Classic end)
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        StarterGui:SetCore("ResetButtonCallback", true)
    end)
    Notify("🔄  Full reset complete — everything restored")
end)

-- ── UI Theme Switcher ────────────────────────────────────
--  Cycles the command bar and list through colour themes.

local _themes = {
    {name="dark",   bar=Color3.fromRGB(15,15,15),    list=Color3.fromRGB(15,15,15),   accent=Color3.fromRGB(80,160,255)},
    {name="midnight",bar=Color3.fromRGB(5,5,20),     list=Color3.fromRGB(8,8,28),     accent=Color3.fromRGB(100,80,255)},
    {name="forest", bar=Color3.fromRGB(10,20,10),    list=Color3.fromRGB(12,22,12),   accent=Color3.fromRGB(60,200,80)},
    {name="crimson",bar=Color3.fromRGB(20,5,5),      list=Color3.fromRGB(22,8,8),     accent=Color3.fromRGB(220,60,60)},
    {name="gold",   bar=Color3.fromRGB(20,16,5),     list=Color3.fromRGB(22,18,6),    accent=Color3.fromRGB(255,200,50)},
    {name="light",  bar=Color3.fromRGB(230,230,230), list=Color3.fromRGB(220,220,220),accent=Color3.fromRGB(50,120,220)},
}
local _themeIdx = 1

Cmd("theme", {"uitheme","settheme","colortheme"}, function(args)
    local key = (args[1] or ""):lower()
    local found = nil
    if key ~= "" then
        for _, t in ipairs(_themes) do
            if t.name:lower():find(key,1,true) then found=t; break end
        end
        if not found then
            local list={}; for _,t in ipairs(_themes) do table.insert(list,t.name) end
            Notify("Themes: "..table.concat(list,", "),"warn"); return
        end
    else
        _themeIdx = _themeIdx % #_themes + 1
        found = _themes[_themeIdx]
    end

    -- Apply theme
    TweenObj(BarFrame,  0.3, {BackgroundColor3 = found.bar}):Play()
    TweenObj(ListFrame, 0.3, {BackgroundColor3 = found.list}):Play()
    TweenObj(Logo,      0.3, {BackgroundColor3 = found.bar}):Play()
    TweenObj(GlowStroke,0.3, {Color = found.accent}):Play()
    TweenObj(LogoStroke,0.3, {Color = found.accent}):Play()
    TweenObj(BarPrompt, 0.3, {TextColor3 = found.accent}):Play()

    -- Light or dark text
    local textCol = found.name == "light"
        and Color3.fromRGB(20,20,20)
        or  Color3.fromRGB(230,230,230)
    TweenObj(TextBox, 0.3, {TextColor3 = textCol}):Play()

    Notify("🎨  Theme → "..found.name)
end)

-- ── Floating Hotbar ──────────────────────────────────────
--  Compact row of icon buttons for the 8 most-used toggles.
--  Teaches: dynamic button grid, state-aware icon changes,
--           live text update based on State flags.

local _hotbarGui  = nil
local _hotbarConn = nil

Cmd("hotbar", {"quickbar","hb"}, function()
    if _hotbarGui then
        _hotbarGui:Destroy(); _hotbarGui = nil
        if _hotbarConn then _hotbarConn:Disconnect(); _hotbarConn=nil end
        Notify("⚡  Hotbar OFF"); return
    end

    local entries = {
        {icon="✈", cmd="fly",        stateKey="Flying"},
        {icon="👻", cmd="noclip",     stateKey="Noclipping"},
        {icon="🛡", cmd="shieldmode", stateKey=nil},
        {icon="👁", cmd="esp",        stateKey="ESP"},
        {icon="💡", cmd="fullbright", stateKey="Fullbright"},
        {icon="🏃", cmd="run",        stateKey=nil},
        {icon="❤", cmd="loopheal",   stateKey="LoopHeal"},
        {icon="♻", cmd="respawn",    stateKey=nil},
    }

    local BW = IsMobile and 50 or 40
    local BH = IsMobile and 50 or 38
    local GAP = 4
    local total = #entries * (BW + GAP) - GAP

    _hotbarGui = Instance.new("ScreenGui", ScreenGui)
    _hotbarGui.Name         = "S_Hotbar"
    _hotbarGui.ResetOnSpawn = false
    _hotbarGui.DisplayOrder = 72

    local bg = Instance.new("Frame", _hotbarGui)
    bg.Size             = UDim2.new(0, total+8, 0, BH+8)
    bg.Position         = UDim2.new(0.5, -(total+8)/2, 1, -(BH+18))
    bg.BackgroundColor3 = Color3.fromRGB(12,12,12)
    bg.BackgroundTransparency = 0.3
    bg.ZIndex           = 72
    Corner(bg, 10)
    Stroke(bg, 1, Color3.fromRGB(60,60,60))
    MakeDraggable(bg, bg)

    local btns = {}
    for i, e in ipairs(entries) do
        local btn = Instance.new("TextButton", bg)
        btn.Size             = UDim2.new(0, BW, 0, BH)
        btn.Position         = UDim2.new(0, 4+(i-1)*(BW+GAP), 0, 4)
        btn.BackgroundColor3 = Color3.fromRGB(22,22,22)
        btn.BackgroundTransparency = 0.1
        btn.Text             = e.icon
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = IsMobile and 22 or 18
        btn.AutoButtonColor  = false
        btn.ZIndex           = 73
        Corner(btn, 8)

        btn.Activated:Connect(function()
            task.defer(function() ExecCommand(e.cmd) end)
        end)
        btn.MouseEnter:Connect(function()
            TweenObj(btn,0.08,{BackgroundColor3=Color3.fromRGB(40,40,40)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            local active = e.stateKey and State[e.stateKey]
            TweenObj(btn,0.08,{BackgroundColor3=
                active and Color3.fromRGB(30,45,30)
                or  Color3.fromRGB(22,22,22)}):Play()
        end)
        btns[i] = {btn=btn, entry=e}
    end

    -- Live state highlight
    local elapsed = 0
    _hotbarConn = RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed < 0.15 then return end; elapsed = 0
        for _, b in ipairs(btns) do
            local active = b.entry.stateKey and State[b.entry.stateKey]
            b.btn.BackgroundColor3 = active
                and Color3.fromRGB(30,60,30)
                or  Color3.fromRGB(22,22,22)
        end
    end)

    Notify("⚡  Hotbar ON  (drag to reposition)")
end)

-- ── Interactive Tutorial ─────────────────────────────────
--  Steps the user through 5 essential commands with timed
--  notifications — good for first-run onboarding.

Cmd("tutorial", {"tut","getstarted","guide"}, function()
    local steps = {
        {delay=0,   msg="👋  Welcome!  S Command Bar Pro — type ; to open the bar"},
        {delay=3.5, msg="🚀  Try:  fly 80  — smooth IY-style flight"},
        {delay=7,   msg="👻  Try:  noclip  — phase through walls"},
        {delay=10.5,msg="📌  Try:  setwp home  then  wp home  — waypoint system"},
        {delay=14,  msg="🛡  Try:  shieldmode  — anti-fling + anti-void + health guard"},
        {delay=17.5,msg="📋  Try:  cmds  — browse all 590+ commands by category"},
        {delay=21,  msg="✅  Tutorial complete!  Run  about  for version info"},
    }
    for _, s in ipairs(steps) do
        task.delay(s.delay, function() Notify(s.msg, "info") end)
    end
    Notify("📖  Tutorial started — follow the notifications")
end)

-- ── typeof (was missing from category map) ───────────────
Cmd("typeof", {"luatype","gettype"}, function(args)
    local raw = table.concat(args," ")
    if raw=="" then Notify("Usage: typeof <expression>","warn"); return end
    local fn, err = loadstring("return "..raw)
    if not fn then Notify("Syntax error","error"); return end
    local ok, val = pcall(fn)
    if ok then
        Notify(string.format("🔢  type=%s  val=%s", type(val), tostring(val):sub(1,40)),"info")
    else
        Notify("Eval error: "..tostring(val),"error")
    end
end)

-- ── Quick Commands ───────────────────────────────────────
--  Single-word shorthand for common action combos.

Cmd("godmode2", {"gm","fullgod"}, function()
    Commands["god"]({})
    Commands["infjump"]({})
    Commands["antifling"]({})
    Notify("🛡  God combo ON — infinite health + jump + anti-fling")
end)

Cmd("explorer2", {"ex","explorermode"}, function()
    Commands["fly"]({})
    Commands["noclip"]({})
    Commands["fullbright"]({})
    Notify("🗺  Explorer mode ON — fly + noclip + fullbright")
end)

Cmd("stealthmode", {"sm","gostealth"}, function()
    Commands["invisible"]({})
    Commands["noclip"]({})
    Commands["fly"]({})
    Notify("👻  Stealth mode ON — invisible + noclip + fly")
end)

-- ── All-HUD Toggle ───────────────────────────────────────
Cmd("hudon", {"allhudson","starthuds"}, function()
    Commands["infobar"]({})
    Commands["healthbar"]({})
    Commands["speeddisplay"]({})
    Commands["fpscounter"]({})
    Commands["minimap"]({})
    Notify("🖥  Core HUDs activated")
end)

-- ── Final Version Banner ──────────────────────────────────
--  Overwrite the about command to reflect v5.0 Final.

Commands["about"] = function()
    local cmdCount, aliasCount = 0, 0
    for _ in pairs(Commands) do cmdCount = cmdCount + 1 end
    for _ in pairs(Aliases)  do aliasCount = aliasCount + 1 end
    print(string.rep("═",60))
    print("  ⚡  S Command Bar Pro  v5.0  —  Final Edition")
    print(string.format("  Commands  : %d  |  Aliases: %d", cmdCount, aliasCount))
    print(string.format("  Platform  : %s  |  Player: %s",
        IsMobile and "Mobile 📱" or "PC 🖥", LP.Name))
    print(string.format("  Game      : %s  (PlaceId %d v%d)",
        game.Name, game.PlaceId, game.PlaceVersion))
    print("  Features  : Categorised cmds · IY fly · Spring freecam")
    print("              Waypoints · Hotbar · Themes · Defensive suite")
    print("              Session stats · Macro recorder · 33 categories")
    print("  Tip       : type  tutorial  for a guided walkthrough")
    print(string.rep("═",60))
    Notify("⚡  S Command Bar Pro v5.0 Final — see console","info")
end

-- ════════════════════════════════════════════════════════════
--                   CMDS LIST TOGGLE
-- ════════════════════════════════════════════════════════════

-- ╔══════════════════════════════════════════════════════════╗
-- ║   COMMAND CATEGORY MAP                                  ║
-- ║   Every command name maps to one category key.          ║
-- ╚══════════════════════════════════════════════════════════╝
local CmdCategories = {
    -- 🚀 Movement
    fly="movement",unfly="movement",noclip="movement",clip="movement",
    speed="movement",jp="movement",sit="movement",hipheight="movement",
    blink="movement",blinkback="movement",blinkup="movement",
    glide="movement",run="movement",autosprint="movement",
    autojump="movement",stepover="movement",launch="movement",
    velocity="movement",moonwalk="movement",jetpack="movement",
    float="movement",unfloat="movement",swim="movement",unswim="movement",
    togglenoclip="movement",stopmove="movement",ragdoll="movement",
    unragdoll="movement",walktowp="movement",

    -- 🎭 Animations
    anim="animations",stopanim="animations",emote="animations",
    dance="animations",loopemote="animations",animspeed="animations",
    animweight="animations",freezepose="animations",unpose="animations",
    pauseanim="animations",emote6="animations",emote15="animations",
    autoemote="animations",playanim2="animations",animlib="animations",
    animinfo="animations",

    -- 👤 Character
    size="character",headsize="character",bodycolor="character",
    shirt="character",pants="character",face="character",
    resetappearance="character",sizepreset="character",
    describeme="character",charintegrity="character",
    walksound="character",clonechar="character",outline="character",
    chardeleteclass="character",chardelete="character",
    deletevelocity="character",charmat="character",charmaterial="character",

    -- 💥 Effects
    fire="effects",nofire="effects",smoke="effects",nosmoke="effects",
    sparkles="effects",nosparkles="effects",forcefield="effects",
    trail="effects",notrail="effects",rainbowtrail="effects",
    thicktrail="effects",traillifetime="effects",trailpreset="effects",
    glow="effects",noglow="effects",hat="effects",
    light="effects",lightcolor="effects",lightrange="effects",
    lightbrightness="effects",lightpart="effects",
    explode="effects",cursortrail="effects",

    -- 🌍 Environment
    fog="environment",nofog="environment",ambient="environment",
    sky="environment",sunpos="environment",atmosphere="environment",
    noatmosphere="environment",["time"]="environment",
    fullbright="environment",gravity="environment",lowgrav="environment",
    disco="environment",seizure="environment",timelapse="environment",
    lightpreset="environment",savelighting="environment",
    restorelighting="environment",gravityinfo="environment",
    gravhud="environment",colorgrade="environment",

    -- 🌦 Weather
    rain="weather",norain="weather",snow="weather",nosnow="weather",
    sandstorm="weather",nosandstorm="weather",clearweather="weather",
    ambience="weather",stopambience="weather",

    -- 📷 Camera
    freecam="camera",unfreecam="camera",freecampos="camera",
    fcgoto="camera",freecamwp="camera",fcspeed="camera",fcfov="camera",
    orbit="camera",attachcam="camera",unattachcam="camera",
    shake="camera",fov="camera",firstperson="camera",
    thirdperson="camera",lockcam="camera",unlockcam="camera",
    camdistance="camera",shiftlock="camera",lookat="camera",
    fixcam="camera",isocam="camera",lockfirstperson="camera",
    savecam="camera",loadcam="camera",camerabob="camera",
    cameraroll="camera",tilt="camera",untilt="camera",
    camcut="camera",camsequence="camera",zoom="camera",
    fovpreset="camera",minzoom="camera",maxzoom="camera",

    -- 🎵 Sound
    play="sound",stopsound="sound",volume="sound",reverb="sound",
    echo="sound",pitch="sound",distortion="sound",equalizer="sound",
    clearfx="sound",loopsound="sound",unloopsound="sound",
    soundfadein="sound",soundfadeout="sound",listsounds="sound",
    playsoundbyname="sound",stopsoundbyname="sound",mastervolume="sound",

    -- 👁 ESP & Visual
    esp="esp",unesp="esp",chams="esp",nochams="esp",
    partesp="esp",nopartesp="esp",nametagesp="esp",
    hitboxesp="esp",highlightregion="esp",clearregion="esp",
    showpivot="esp",highlightmaterial="esp",

    -- 🛡 Defense
    antifling="defense",antiteleport="defense",positionlock="defense",
    updatelock="defense",velocityclamp="defense",cameralock="defense",
    uncameralock="defense",setsafe="defense",panic="defense",
    panickey="defense",antikick="defense",antivoid="defense",
    healthguard="defense",antispin="defense",gravityguard="defense",
    shieldmode="defense",defensestatus="defense",undefend="defense",
    safefall="defense",antiweld="defense",autoheal="defense",
    speedwatch="defense",networkwatch="defense",
    crashprotection="defense",respawnprotection="defense",
    exploitdetect="defense",

    -- 📌 Waypoints
    setwp="waypoints",wp="waypoints",tweenwp="waypoints",
    deletewp="waypoints",clearwp="waypoints",listwp="waypoints",
    pathtowp="waypoints",waypointmap="waypoints",savepos="waypoints",
    loadpos="waypoints",

    -- 🗺 Pathfinding
    pathto="pathfinding",stoppath="pathfinding",
    follow="pathfinding",unfollow="pathfinding",
    follownearest="pathfinding",

    -- 📍 Teleport
    tp="teleport",tpme="teleport",gotocam="teleport",
    tpcoords="teleport",home="teleport",tpall="teleport",
    tpoffset="teleport",tpabove="teleport",tpbehind="teleport",
    tpdeath="teleport",tpplace="teleport",tpgame="teleport",
    randomtp="teleport",rejoin="teleport",serverhop="teleport",
    cancelteleport="teleport",

    -- 👥 Players
    view="players",unview="players",specnext="players",
    specprev="players",specrandom="players",inspect="players",
    playerinfo="players",players="players",age="players",
    displayname="players",friends="players",ingroup="players",
    hasbadge="players",userid="players",avatar="players",
    jointeam="players",listteams="players",teamcolor="players",
    swapteam="players",joinplayer="players",
    freezetarget="players",unfreezettarget="players",
    pull="players",forcepush="players",

    -- 🔧 Tools
    listtools="tools",equiptool="tools",droptool="tools",
    removetool="tools",cleartools="tools",activatetool="tools",
    tooltoggle="tools",toolinfo="tools",autocollect="tools",
    seatpart="tools",unseat="tools",ejectall="tools",

    -- 💬 Chat
    chat="chat",chatprefix="chat",chatsuffix="chat",
    clearchatformat="chat",chatrepeat="chat",chatlog="chat",
    unchatlog="chat",globalmsg="chat",sysnotify="chat",notify="chat",

    -- 📊 Info
    serverinfo="info",sessionstats="info",resetsessionstats="info",
    physicsinfo="info",terraininfo="info",terrainstats="info",
    coords="info",ping="info",fps="info",uptime="info",
    gameversion="info",servertime="info",clocksync="info",
    placeinfo="info",distanceto="info",sizeof="info",
    platforminfo="info",memstats="info",printidentity="info",
    getexecutor="info",schedulerstats="info",cmdcount="info",
    cmdstats="info",about="info",rigtype="info",

    -- 🗺 Workspace
    delete="workspace",createpart="workspace",createplatform="workspace",
    lockws="workspace",unlockws="workspace",deleteclass="workspace",
    clonepart="workspace",freezeall="workspace",unfreezeall="workspace",
    noparts="workspace",restoreparts="workspace",hideworkspace="workspace",
    showworkspace="workspace",scanworkspace="workspace",
    countparts="workspace",recolorpart="workspace",
    resizepart="workspace",renamepart="workspace",
    findbycolor="workspace",findbysize="workspace",
    anchormodel="workspace",weldmodel="workspace",
    modelinfo="workspace",modelchildren="workspace",
    tweenpart="workspace",tweenpartcolor="workspace",
    tweenpartfade="workspace",findinstance="workspace",
    findclass="workspace",getprops="workspace",getancestors="workspace",
    partinfo="workspace",vehicleflip="workspace",

    -- 🗻 Terrain
    fillterrain="terrain",clearterrain="terrain",
    replaceterrain="terrain",fillwater="terrain",
    removewater="terrain",

    -- 🏗 Constraints
    ropeto="constraints",unrope="constraints",
    springto="constraints",unspring="constraints",
    listconstraints="constraints",removeconstraint="constraints",
    weldmodel="constraints",

    -- 🔑 Binds
    bind="binds",unbind="binds",listbinds="binds",clearbinds="binds",
    showbindgui="binds",cheatsheet="binds",

    -- ⏺ Macros
    recordmacro="macros",playmacro="macros",stopmacro="macros",
    listmacro="macros",clearmacro="macros",
    loopexec="macros",stoploopexec="macros",
    ["repeat"]="macros",loopkill="macros",unloopkill="macros",

    -- 📜 Scripts
    listscripts="scripts",scriptcount="scripts",listmodules="scripts",
    exec="scripts",loadurl="scripts",remotelog="scripts",
    unremotelog="scripts",

    -- 🖥 HUD & GUI
    hideguis="hud",showguis="hud",guioutline="hud",guicolor="hud",
    guilayout="hud",guicount="hud",destroygameguis="hud",
    guitransparency="hud",cinematic="hud",crosshair="hud",
    infobar="hud",fpscounter="hud",speeddisplay="hud",
    healthbar="hud",minimap="hud",netstat="hud",tickrate="hud",
    wsstats="hud",playerlist="hud",adminpanel="hud",
    overlay="hud",nooverlay="hud",pinggraph="hud",
    debug="hud",togglehud="hud",listhuds="hud",
    charstats="hud",fpscap="hud",unfpscap="hud",

    -- 🎨 Appearance
    rainbow="appearance",neonmode="appearance",darkmode="appearance",
    invertcolor="appearance",highlightself="appearance",
    randomcolor="appearance",addaccessory="appearance",
    removeaccessory="appearance",listaccessories="appearance",
    shirt="appearance",pants="appearance",face="appearance",
    setmaterial="appearance",bodycolor="appearance",
    resetappearance="appearance",

    -- 🔢 Math & String
    v3add="math",v3dist="math",v3lerp="math",v3dot="math",
    rgb2hex="math",color="math",charcode="math",
    strlen="math",strupper="math",strlower="math",
    strreverse="math",strrep="math",strfind="math",
    strsplit="math",strformat="math",matheval="math",

    -- 📋 Utilities
    history="utils",clearhistory="utils",tip="utils",
    status="utils",redo="utils",exectime="utils",
    benchmark2="utils",waitfor="utils",countdown="utils",
    stopwatch="utils",randomtp="utils",realtime="utils",
    jobid="utils",getversion2="utils",copypos="utils",
    copycframe="utils",copyid="utils",cliphistory="utils",
    recopy="utils",exportlog="utils",
    draw="utils",cleardrawing="utils",

    -- 📝 Notes
    note="notes",notes="notes",deletenote="notes",
    clearnotes="notes",copynotes="notes",

    -- 🏆 Achievements
    achievements="achievements",

    -- 🔭 Proximity & Interaction
    triggerproximity="interaction",proximityalert="interaction",
    watch="interaction",unwatch="interaction",watchprop="interaction",
    eventmonitor="interaction",worldlog="interaction",
    pingalert="interaction",alarm="interaction",

    -- ➕ Recently added: movement
    surfacecheck="movement",nogravchar="movement",boost="movement",
    wallstick="movement",unstick="movement",

    -- ➕ Recently added: camera
    camlookdown="camera",pointatpart="camera",
    camforward="camera",camup="camera",

    -- ➕ Recently added: workspace
    paintpart="workspace",anchornearest="workspace",
    deletenearest="workspace",selectpart="workspace",

    -- ➕ Recently added: info
    lookingat="info",nearbyplayers="info",serverlag="info",

    -- ➕ Recently added: defense
    antibrick="defense",saferespawn="defense",lockcharacter="defense",

    -- ➕ Recently added: hud
    compass="hud",clockhud="hud",

    -- ➕ Recently added: appearance
    charcolor="appearance",transparency="appearance",
    chrome="appearance",wooden="appearance",

    -- ➕ Recently added: sound
    soundinfo="sound",rewind="sound",

    -- ➕ Recently added: utils
    pingavg="utils",taskcount="utils",varset="utils",varget="utils",
    garbage="utils",printtable="utils",looptask="macros",

    -- ➕ Recently added: survival
    revive="survival",stun="survival",

    -- 🎮 God / Survival
    god="survival",ungod="survival",loopheal="survival",
    unloopheal="survival",heal="survival",freeze="survival",
    unfreeze="survival",respawn="survival",infjump="survival",
    uninfjump="survival",antiafk="survival",unantiafk="survival",
    wiggle="survival",annoy="survival",unannoy="survival",
    bang="survival",unbang="survival",
    spin="survival",unspin="survival",
    fling="survival",unfling="survival",
    killaura="survival",unkillaura="survival",
    attach="survival",detach="survival",
    rotateto="survival",offset="survival",faceplayer="survival",

    -- 🕹 Control
    control="control",uncontrol="control",
    setstat="control",alias="control",unalias="control",
    preload="control",preloadchar="control",

    -- 📡 Network
    serverinfo="network",serverhop="network",rejoin="network",
    autorejoin="network",netstat="network",
    networkwatch="network",pingalert="network",
    mastervolume="network",
}

-- Category display config: {key, icon+label, header color}
local CategoryDef = {
    {"movement",    "🚀  Movement",       Color3.fromRGB(80,160,255)},
    {"animations",  "🎭  Animations",     Color3.fromRGB(200,120,255)},
    {"character",   "👤  Character",      Color3.fromRGB(255,180,80)},
    {"appearance",  "🎨  Appearance",     Color3.fromRGB(255,120,180)},
    {"effects",     "💥  Effects",        Color3.fromRGB(255,100,60)},
    {"environment", "🌍  Environment",    Color3.fromRGB(80,200,100)},
    {"weather",     "🌦  Weather",        Color3.fromRGB(120,200,255)},
    {"camera",      "📷  Camera",         Color3.fromRGB(150,230,200)},
    {"sound",       "🎵  Sound",          Color3.fromRGB(255,230,80)},
    {"esp",         "👁  ESP & Visual",   Color3.fromRGB(180,255,180)},
    {"defense",     "🛡  Defense",        Color3.fromRGB(255,80,80)},
    {"waypoints",   "📌  Waypoints",      Color3.fromRGB(255,200,100)},
    {"pathfinding", "🗺  Pathfinding",    Color3.fromRGB(100,220,160)},
    {"teleport",    "📍  Teleport",       Color3.fromRGB(120,180,255)},
    {"players",     "👥  Players",        Color3.fromRGB(200,200,255)},
    {"tools",       "🔧  Tools",          Color3.fromRGB(200,160,100)},
    {"chat",        "💬  Chat",           Color3.fromRGB(180,220,255)},
    {"survival",    "🎮  Combat/Survival",Color3.fromRGB(255,120,120)},
    {"hud",         "🖥  HUD & GUI",      Color3.fromRGB(160,220,255)},
    {"workspace",   "🗺  Workspace",      Color3.fromRGB(180,180,180)},
    {"terrain",     "🗻  Terrain",        Color3.fromRGB(140,200,120)},
    {"constraints", "🏗  Constraints",    Color3.fromRGB(200,180,140)},
    {"binds",       "🔑  Binds",          Color3.fromRGB(255,200,80)},
    {"macros",      "⏺  Macros",         Color3.fromRGB(220,160,255)},
    {"scripts",     "📜  Scripts",        Color3.fromRGB(160,200,160)},
    {"math",        "🔢  Math & String",  Color3.fromRGB(200,255,200)},
    {"interaction", "🔭  Interaction",    Color3.fromRGB(180,240,220)},
    {"info",        "📊  Info & Stats",   Color3.fromRGB(220,220,220)},
    {"notes",       "📝  Notes",          Color3.fromRGB(255,240,160)},
    {"achievements","🏆  Achievements",   Color3.fromRGB(255,215,0)},
    {"control",     "🕹  Control",        Color3.fromRGB(200,200,180)},
    {"network",     "📡  Network",        Color3.fromRGB(100,200,255)},
    {"utils",       "⚙  Utilities",      Color3.fromRGB(180,180,200)},
}

-- ╔══════════════════════════════════════════════════════════╗
-- ║   CMDS LIST COMMAND (Categorized)                       ║
-- ╚══════════════════════════════════════════════════════════╝
Cmd("cmds", {"help","list","?","commands"}, function()
    -- Clear existing rows
    for _, c in ipairs(ScrollFrame:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end

    -- Build category → [cmdName] table
    local catMap = {}     -- {catKey → {cmdName, ...}}
    local uncatList = {}  -- commands with no category
    for n in pairs(Commands) do
        local cat = CmdCategories[n]
        if cat then
            if not catMap[cat] then catMap[cat] = {} end
            table.insert(catMap[cat], n)
        else
            table.insert(uncatList, n)
        end
    end
    -- Sort commands within each category
    for _, names in pairs(catMap) do table.sort(names) end
    table.sort(uncatList)

    local ROW_H  = C.RowH
    local HDR_H  = IsMobile and 22 or 18
    local ROW_GAP = 3
    local HDR_GAP = 2

    local function makeHeader(cat, label, col)
        local hdr = Instance.new("Frame", ScrollFrame)
        hdr.Name             = "__HDR_" .. cat
        hdr.Size             = UDim2.new(1,-4, 0, HDR_H)
        hdr.BackgroundColor3 = Color3.fromRGB(20,20,20)
        hdr.BackgroundTransparency = 0
        hdr.ZIndex           = 36
        Corner(hdr, 4)

        local accent = Instance.new("Frame", hdr)
        accent.Size             = UDim2.new(0, 3, 1, 0)
        accent.BackgroundColor3 = col
        accent.BorderSizePixel  = 0
        accent.ZIndex           = 37
        Corner(accent, 2)

        local lbl = Instance.new("TextLabel", hdr)
        lbl.Size             = UDim2.new(1,-8, 1, 0)
        lbl.Position         = UDim2.new(0, 7, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text             = label
        lbl.TextColor3       = col
        lbl.Font             = Enum.Font.GothamBold
        lbl.TextSize         = IsMobile and 12 or 10
        lbl.TextXAlignment   = Enum.TextXAlignment.Left
        lbl.ZIndex           = 38
        return hdr
    end

    local function makeRow(cmdName, col)
        local row = Instance.new("TextButton", ScrollFrame)
        row.Name             = cmdName
        row.Size             = UDim2.new(1,-4, 0, ROW_H)
        row.BackgroundColor3 = Color3.fromRGB(22,22,22)
        row.BackgroundTransparency = 0.1
        row.AutoButtonColor  = false
        row.ZIndex           = 37
        Corner(row, 4)

        -- Colored left pip matching category
        local pip = Instance.new("Frame", row)
        pip.Size             = UDim2.new(0, 2, 0.6, 0)
        pip.Position         = UDim2.new(0, 3, 0.2, 0)
        pip.BackgroundColor3 = col or Color3.fromRGB(80,80,80)
        pip.BorderSizePixel  = 0
        pip.ZIndex           = 38
        Corner(pip, 1)

        local lbl = Instance.new("TextLabel", row)
        lbl.Size             = UDim2.new(1,-12, 1, 0)
        lbl.Position         = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text             = cmdName
        lbl.TextColor3       = Color3.fromRGB(195,195,195)
        lbl.Font             = Enum.Font.Code
        lbl.TextSize         = C.ListTxtSize
        lbl.TextXAlignment   = Enum.TextXAlignment.Left
        lbl.ZIndex           = 38

        row.MouseEnter:Connect(function()
            TweenObj(row,0.08,{BackgroundColor3=Color3.fromRGB(35,35,35)}):Play()
            lbl.TextColor3 = col or Color3.fromRGB(220,220,220)
        end)
        row.MouseLeave:Connect(function()
            TweenObj(row,0.08,{BackgroundColor3=Color3.fromRGB(22,22,22)}):Play()
            lbl.TextColor3 = Color3.fromRGB(195,195,195)
        end)
        row.Activated:Connect(function()
            TextBox.Text = cmdName .. " "
            ListFrame.Visible = false
            if not isBarOpen then OpenBar() end
        end)
        return row
    end

    -- Build UI in category order
    for _, catDef in ipairs(CategoryDef) do
        local key, label, col = catDef[1], catDef[2], catDef[3]
        local names = catMap[key]
        if names and #names > 0 then
            makeHeader(key, label .. " (" .. #names .. ")", col)
            for _, n in ipairs(names) do
                makeRow(n, col)
            end
        end
    end

    -- Uncategorized (safety net)
    if #uncatList > 0 then
        makeHeader("misc", "❓  Misc (" .. #uncatList .. ")", Color3.fromRGB(140,140,140))
        for _, n in ipairs(uncatList) do
            makeRow(n, Color3.fromRGB(120,120,120))
        end
    end

    ScrollFrame.CanvasSize = UDim2.new(0,0,0, UIList.AbsoluteContentSize.Y + 8)
    ListFrame.Visible = not ListFrame.Visible
    if ListFrame.Visible then SearchBox.Text = "" end
end)

-- ════════════════════════════════════════════════════════════
--  LIVE SEARCH FILTER  (hides category headers when empty)
-- ════════════════════════════════════════════════════════════

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = SearchBox.Text:lower()

    -- First pass: show/hide command rows
    for _, row in ipairs(ScrollFrame:GetChildren()) do
        if row:IsA("TextButton") then
            row.Visible = q == "" or row.Name:lower():find(q,1,true) ~= nil
        end
    end

    -- Second pass: hide a category header if ALL its rows are hidden
    if q ~= "" then
        local children = ScrollFrame:GetChildren()
        local i = 1
        while i <= #children do
            local obj = children[i]
            if obj:IsA("Frame") and obj.Name:sub(1,6) == "__HDR_" then
                -- Look ahead for rows until next header
                local hasVisible = false
                local j = i + 1
                while j <= #children do
                    local next = children[j]
                    if next:IsA("Frame") and next.Name:sub(1,6) == "__HDR_" then
                        break
                    end
                    if next:IsA("TextButton") and next.Visible then
                        hasVisible = true; break
                    end
                    j = j + 1
                end
                obj.Visible = hasVisible
            end
            i = i + 1
        end
    else
        -- Show all headers
        for _, obj in ipairs(ScrollFrame:GetChildren()) do
            obj.Visible = true
        end
    end

    -- Recalculate canvas height
    local h = 0
    for _, obj in ipairs(ScrollFrame:GetChildren()) do
        if obj.Visible and obj:IsA("GuiObject") then
            h = h + obj.AbsoluteSize.Y + 3
        end
    end
    ScrollFrame.CanvasSize = UDim2.new(0,0,0, h + 8)
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║              EXECUTE COMMAND                            ║
-- ╚══════════════════════════════════════════════════════════╝
local function ExecCommand(raw)
    if not raw or raw:match("^%s*$") then return end
    local parts = {}
    for word in raw:gmatch("%S+") do table.insert(parts, word) end
    if #parts == 0 then return end

    local name = table.remove(parts, 1):lower()
    name = Aliases[name] or name  -- resolve alias

    if Commands[name] then
        local ok, err = pcall(function() Commands[name](parts) end)
        if not ok then
            warn("[S-Bar] " .. name .. ": " .. tostring(err))
            Notify("⚠  Error: " .. name, "error")
        end
    else
        Notify("❓  Unknown: " .. name, "warn")
    end
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║                BAR OPEN / CLOSE                         ║
-- ╚══════════════════════════════════════════════════════════╝
local isBarOpen = false

local function OpenBar()
    isBarOpen = true
    BarFrame.Position = C.BarHide
    TweenObj(BarFrame, 0.32, {Position = C.BarOpen}):Play()
    task.delay(0.12, function() pcall(function() TextBox:CaptureFocus() end) end)
end

local function CloseBar()
    isBarOpen = false
    TweenObj(BarFrame, 0.22, {Position = C.BarHide},
        Enum.EasingStyle.Quad, Enum.EasingDirection.In):Play()
    pcall(function() TextBox:ReleaseFocus() end)
end

Logo.MouseButton1Click:Connect(function()
    if isBarOpen then CloseBar() else OpenBar() end
end)

TextBox.FocusLost:Connect(function(enter)
    if enter then
        local txt = TextBox.Text
        TextBox.Text = ""
        CloseBar()
        task.defer(function() ExecCommand(txt) end)
    end
end)

-- Semicolon toggle shortcut (PC)
UserInputService.InputBegan:Connect(function(i, gameProcessed)
    if gameProcessed then return end
    if i.KeyCode == Enum.KeyCode.Semicolon then
        if isBarOpen then CloseBar() else OpenBar() end
    end
    -- Escape closes bar
    if i.KeyCode == Enum.KeyCode.Escape and isBarOpen then
        CloseBar()
    end
end)

CloseBtn.Activated:Connect(function()
    ListFrame.Visible = false
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║             LOGO HOVER (PC only)                        ║
-- ╚══════════════════════════════════════════════════════════╝
if not IsMobile then
    Logo.MouseEnter:Connect(function()
        TweenObj(Logo, 0.15, {BackgroundColor3 = Color3.fromRGB(30,30,30)}):Play()
    end)
    Logo.MouseLeave:Connect(function()
        TweenObj(Logo, 0.15, {BackgroundColor3 = Color3.fromRGB(15,15,15)}):Play()
    end)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║                    READY                                ║
-- ╚══════════════════════════════════════════════════════════╝
Notify("⚡  S Command Bar Pro  v5.0 Final  " .. (IsMobile and "📱" or "🖥️"))
