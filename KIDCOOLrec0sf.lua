--[[
    NeonUI Exploit Edition
    Для Roblox executor (Synapse, Krnl, Delta, Wave и др.)
    - CoreGui (не удаляется при респавне, скрыт от PlayerGui)
    - protectgui / syn.protect_gui если доступно
    - getgenv() для глобального доступа
    - Перехват ошибок через getrawmetatable
    BY kidcool
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

-- ==================== БЕЗОПАСНОЕ ПОЛУЧЕНИЕ GUI-КОНТЕЙНЕРА ====================
local function getGuiParent()
    -- Пробуем CoreGui (лучший вариант для executor'а)
    local ok, result = pcall(function()
        return CoreGui
    end)
    if ok and result then return result end
    -- Fallback: PlayerGui
    return Player:WaitForChild("PlayerGui")
end

local GUIParent = getGuiParent()

-- ==================== ЗАЩИТА GUI (если доступна) ====================
local function protectGui(gui)
    -- Synapse / ScriptWare
    if syn and syn.protect_gui then
        pcall(function() syn.protect_gui(gui) end)
        return
    end
    -- Krnl / Fluxus / др.
    if protectgui then
        pcall(function() protectgui(gui) end)
        return
    end
    -- Electron
    if electron and electron.protect then
        pcall(function() electron.protect(gui) end)
        return
    end
    -- Если ничего нет — просто оставляем как есть
end

-- ==================== ТЕМА ====================
local Theme = {
    Bg = Color3.fromRGB(22, 22, 26),
    BgLight = Color3.fromRGB(32, 32, 38),
    BgHover = Color3.fromRGB(42, 42, 50),
    Accent = Color3.fromRGB(0, 200, 255),
    AccentDim = Color3.fromRGB(0, 120, 160),
    Text = Color3.fromRGB(240, 240, 245),
    TextDim = Color3.fromRGB(150, 150, 160),
    Danger = Color3.fromRGB(255, 80, 90),
    Success = Color3.fromRGB(80, 220, 120),
    Warning = Color3.fromRGB(255, 200, 80),
    Shadow = Color3.fromRGB(0, 0, 0)
}

local GLOW_ID = "rbxassetid://2704567431"

-- ==================== УТИЛИТЫ ====================
local function tween(obj, time, props, style, dir)
    local info = TweenInfo.new(
        time or 0.2,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function makeGlow(parent, size, pos, transparency, color)
    local g = Instance.new("ImageLabel")
    g.BackgroundTransparency = 1
    g.Image = GLOW_ID
    g.ImageColor3 = color or Theme.Accent
    g.ImageTransparency = transparency or 0.8
    g.ScaleType = Enum.ScaleType.Slice
    g.SliceCenter = Rect.new(20, 20, 80, 80)
    g.Size = size
    g.Position = pos
    g.ZIndex = 0
    g.Parent = parent
    return g
end

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

-- ==================== БИБЛИОТЕКА ====================
local NeonUI = {}
NeonUI.Theme = Theme
NeonUI.__index = NeonUI

-- ==================== СОЗДАНИЕ ОКНА ====================
function NeonUI.new(title, size)
    local self = setmetatable({}, NeonUI)
    self.Title = title or "NEON UI"
    self.Size = size or UDim2.new(0, 320, 0, 400)
    self.Tabs = {}
    self.Elements = {}
    self.IsOpen = true
    self.IsMinimized = false

    -- Удаляем старый
    local old = GUIParent:FindFirstChild("NeonUI")
    if old then old:Destroy() end

    -- ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "NeonUI"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.IgnoreGuiInset = true
    self.ScreenGui.DisplayOrder = 999
    self.ScreenGui.Parent = GUIParent

    -- Защита GUI (если executor поддерживает)
    protectGui(self.ScreenGui)

    -- Glow
    self.Glow1 = makeGlow(self.ScreenGui, UDim2.new(0, self.Size.X.Offset + 40, 0, self.Size.Y.Offset + 40),
        UDim2.new(0.5, -(self.Size.X.Offset + 40)/2, 0.5, -(self.Size.Y.Offset + 40)/2), 0.9)
    self.Glow2 = makeGlow(self.ScreenGui, UDim2.new(0, self.Size.X.Offset + 20, 0, self.Size.Y.Offset + 20),
        UDim2.new(0.5, -(self.Size.X.Offset + 20)/2, 0.5, -(self.Size.Y.Offset + 20)/2), 0.8)
    self.Glow3 = makeGlow(self.ScreenGui, UDim2.new(0, self.Size.X.Offset, 0, self.Size.Y.Offset),
        UDim2.new(0.5, -self.Size.X.Offset/2, 0.5, -self.Size.Y.Offset/2), 0.7)

    tween(self.Glow1, 2.5, {ImageTransparency = 0.95}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    tween(self.Glow2, 2.5, {ImageTransparency = 0.85}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    tween(self.Glow3, 2.5, {ImageTransparency = 0.75}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

    -- Основная панель
    self.Main = Instance.new("Frame")
    self.Main.Size = self.Size
    self.Main.Position = UDim2.new(0.5, -self.Size.X.Offset/2, 0.5, -self.Size.Y.Offset/2)
    self.Main.BackgroundColor3 = Theme.Bg
    self.Main.BorderSizePixel = 0
    self.Main.Active = true
    self.Main.ClipsDescendants = true
    self.Main.ZIndex = 1
    self.Main.Parent = self.ScreenGui
    makeCorner(self.Main, 14)

    -- Заголовок
    self.Header = Instance.new("Frame")
    self.Header.Size = UDim2.new(1, 0, 0, 44)
    self.Header.BackgroundTransparency = 1
    self.Header.ZIndex = 2
    self.Header.Parent = self.Main

    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Size = UDim2.new(1, -100, 1, 0)
    self.TitleLabel.Position = UDim2.new(0, 16, 0, 0)
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Text = self.Title
    self.TitleLabel.TextColor3 = Theme.Text
    self.TitleLabel.Font = Enum.Font.GothamBold
    self.TitleLabel.TextSize = 16
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.ZIndex = 3
    self.TitleLabel.Parent = self.Header

    -- Кнопка свернуть
    self.MinBtn = Instance.new("TextButton")
    self.MinBtn.Size = UDim2.new(0, 28, 0, 28)
    self.MinBtn.Position = UDim2.new(1, -72, 0.5, -14)
    self.MinBtn.BackgroundColor3 = Theme.BgLight
    self.MinBtn.Text = "−"
    self.MinBtn.TextColor3 = Theme.TextDim
    self.MinBtn.Font = Enum.Font.GothamBold
    self.MinBtn.TextSize = 16
    self.MinBtn.BorderSizePixel = 0
    self.MinBtn.ZIndex = 3
    self.MinBtn.AutoButtonColor = false
    self.MinBtn.Parent = self.Header
    makeCorner(self.MinBtn, 7)

    -- Кнопка закрыть
    self.CloseBtn = Instance.new("TextButton")
    self.CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    self.CloseBtn.Position = UDim2.new(1, -40, 0.5, -14)
    self.CloseBtn.BackgroundColor3 = Theme.BgLight
    self.CloseBtn.Text = "✕"
    self.CloseBtn.TextColor3 = Theme.TextDim
    self.CloseBtn.Font = Enum.Font.GothamBold
    self.CloseBtn.TextSize = 14
    self.CloseBtn.BorderSizePixel = 0
    self.CloseBtn.ZIndex = 3
    self.CloseBtn.AutoButtonColor = false
    self.CloseBtn.Parent = self.Header
    makeCorner(self.CloseBtn, 7)

    -- Разделитель
    self.Divider = Instance.new("Frame")
    self.Divider.Size = UDim2.new(1, -32, 0, 1)
    self.Divider.Position = UDim2.new(0, 16, 0, 46)
    self.Divider.BackgroundColor3 = Theme.BgLight
    self.Divider.BorderSizePixel = 0
    self.Divider.ZIndex = 2
    self.Divider.Parent = self.Main

    -- Контейнер вкладок
    self.TabBar = Instance.new("Frame")
    self.TabBar.Size = UDim2.new(1, -32, 0, 32)
    self.TabBar.Position = UDim2.new(0, 16, 0, 52)
    self.TabBar.BackgroundTransparency = 1
    self.TabBar.ZIndex = 2
    self.TabBar.Parent = self.Main

    self.TabLayout = Instance.new("UIListLayout")
    self.TabLayout.FillDirection = Enum.FillDirection.Horizontal
    self.TabLayout.Padding = UDim.new(0, 6)
    self.TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.TabLayout.Parent = self.TabBar

    -- Контейнер контента
    self.ContentContainer = Instance.new("Frame")
    self.ContentContainer.Size = UDim2.new(1, -32, 1, -96)
    self.ContentContainer.Position = UDim2.new(0, 16, 0, 90)
    self.ContentContainer.BackgroundTransparency = 1
    self.ContentContainer.ZIndex = 2
    self.ContentContainer.Parent = self.Main

    -- Перетаскивание
    self:_setupDrag()

    -- Кнопки
    self.MinBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end)
    self.CloseBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)

    -- Сохраняем в getgenv() для доступа из других скриптов
    if getgenv then
        getgenv().NeonUI = self
    end

    return self
end

-- ==================== ПЕРЕТАСКИВАНИЕ ====================
function NeonUI:_setupDrag()
    local dragging, dragInput, dragStart, startPos
    local self = self

    self.Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    self.Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            self.Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            self:_updateGlowPosition()
        end
    end)
end

function NeonUI:_updateGlowPosition()
    local pos = self.Main.Position
    self.Glow1.Position = pos - UDim2.new(0, 20, 0, 20)
    self.Glow2.Position = pos - UDim2.new(0, 10, 0, 10)
    self.Glow3.Position = pos
end

-- ==================== ВКЛАДКИ ====================
function NeonUI:CreateTab(name)
    local tab = {Name = name, Buttons = {}, Content = nil, Active = false}

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.BackgroundColor3 = Theme.BgLight
    btn.Text = name
    btn.TextColor3 = Theme.TextDim
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.ZIndex = 3
    btn.AutoButtonColor = false
    btn.Parent = self.TabBar
    makeCorner(btn, 6)

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = Theme.Accent
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Visible = false
    content.ZIndex = 3
    content.Parent = self.ContentContainer

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    tab.Button = btn
    tab.Content = content

    btn.MouseButton1Click:Connect(function()
        self:SelectTab(name)
    end)

    self.Tabs[name] = tab
    return tab
end

function NeonUI:SelectTab(name)
    for tabName, tab in pairs(self.Tabs) do
        local active = (tabName == name)
        tab.Content.Visible = active
        tween(tab.Button, 0.2, {
            BackgroundColor3 = active and Theme.Accent or Theme.BgLight,
            TextColor3 = active and Theme.Bg or Theme.TextDim
        })
    end
end

-- ==================== ЭЛЕМЕНТЫ ====================
function NeonUI:Toggle(tabName, text, default, callback)
    local tab = self.Tabs[tabName]
    if not tab then return end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Theme.BgLight
    btn.Text = "  " .. text
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.ZIndex = 3
    btn.AutoButtonColor = false
    btn.Parent = tab.Content
    makeCorner(btn, 6)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 20, 0, 20)
    indicator.Position = UDim2.new(1, -28, 0.5, -10)
    indicator.BackgroundColor3 = default and Theme.Accent or Theme.Bg
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 4
    indicator.Parent = btn
    makeCorner(indicator, 5)

    local state = default

    btn.MouseEnter:Connect(function()
        if not state then
            tween(btn, 0.2, {BackgroundColor3 = Theme.BgHover})
        end
    end)
    btn.MouseLeave:Connect(function()
        if not state then
            tween(btn, 0.2, {BackgroundColor3 = Theme.BgLight})
        end
    end)

    btn.MouseButton1Click:Connect(function()
        state = not state
        tween(btn, 0.2, {BackgroundColor3 = state and Theme.Accent or Theme.BgLight})
        tween(indicator, 0.2, {BackgroundColor3 = state and Theme.Bg or Theme.Bg})
        if callback then callback(state) end
    end)

    return btn
end

function NeonUI:Button(tabName, text, callback)
    local tab = self.Tabs[tabName]
    if not tab then return end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Theme.BgLight
    btn.Text = text
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.ZIndex = 3
    btn.AutoButtonColor = false
    btn.Parent = tab.Content
    makeCorner(btn, 6)

    btn.MouseEnter:Connect(function()
        tween(btn, 0.2, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Bg})
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.2, {BackgroundColor3 = Theme.BgLight, TextColor3 = Theme.Text})
    end)

    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)

    return btn
end

function NeonUI:Slider(tabName, text, min, max, default, callback)
    local tab = self.Tabs[tabName]
    if not tab then return end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 44)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 3
    frame.Parent = tab.Content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    label.Parent = frame

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.35, 0, 0, 18)
    valLabel.Position = UDim2.new(0.65, 0, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(default)
    valLabel.TextColor3 = Theme.Accent
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 12
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.ZIndex = 4
    valLabel.Parent = frame

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, 0, 0, 6)
    barBg.Position = UDim2.new(0, 0, 0, 26)
    barBg.BackgroundColor3 = Theme.BgLight
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 4
    barBg.Parent = frame
    makeCorner(barBg, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 5
    fill.Parent = barBg
    makeCorner(fill, 3)

    local dragging = false
    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
            local val = min + (max - min) * rel
            fill.Size = UDim2.new(rel, 0, 1, 0)
            valLabel.Text = string.format("%.2f", val)
            if callback then callback(val) end
        end
    end)

    return frame
end

function NeonUI:Label(tabName, text)
    local tab = self.Tabs[tabName]
    if not tab then return end

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.TextDim
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 3
    lbl.Parent = tab.Content

    return lbl
end

-- ==================== СВОРАЧИВАНИЕ ====================
function NeonUI:ToggleMinimize()
    self.IsMinimized = not self.IsMinimized

    if self.IsMinimized then
        tween(self.Main, 0.3, {
            Size = UDim2.new(0, self.Size.X.Offset, 0, 44)
        }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        self.TabBar.Visible = false
        self.ContentContainer.Visible = false
        self.MinBtn.Text = "+"
    else
        tween(self.Main, 0.3, {
            Size = self.Size
        }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        self.TabBar.Visible = true
        self.ContentContainer.Visible = true
        self.MinBtn.Text = "−"
    end

    self:_updateGlowPosition()
end

-- ==================== ЗАКРЫТИЕ ====================
function NeonUI:Close()
    if not self.IsOpen then return end
    self.IsOpen = false

    tween(self.Main, 0.3, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1
    }, Enum.EasingStyle.Back, Enum.EasingDirection.In)

    tween(self.Glow1, 0.3, {ImageTransparency = 1})
    tween(self.Glow2, 0.3, {ImageTransparency = 1})
    tween(self.Glow3, 0.3, {ImageTransparency = 1})

    task.wait(0.3)
    self.Main.Visible = false
    self.Glow1.Visible = false
    self.Glow2.Visible = false
    self.Glow3.Visible = false

    self:_createOpenButton()
end

function NeonUI:_createOpenButton()
    local openBtn = Instance.new("TextButton")
    openBtn.Size = UDim2.new(0, 56, 0, 56)
    openBtn.Position = UDim2.new(0, 20, 0.5, -28)
    openBtn.BackgroundColor3 = Theme.Bg
    openBtn.Text = "≡"
    openBtn.TextColor3 = Theme.Accent
    openBtn.Font = Enum.Font.GothamBold
    openBtn.TextSize = 24
    openBtn.BorderSizePixel = 0
    openBtn.ZIndex = 5
    openBtn.AutoButtonColor = false
    openBtn.Parent = self.ScreenGui
    makeCorner(openBtn, 28)

    local glow = makeGlow(openBtn, UDim2.new(1, 30, 1, 30), UDim2.new(0, -15, 0, -15), 0.7)

    tween(glow, 2, {
        ImageTransparency = 0.9,
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0, -20, 0, -20)
    }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

    openBtn.MouseButton1Click:Connect(function()
        openBtn:Destroy()
        self:Open()
    end)

    self.OpenButton = openBtn
end

function NeonUI:Open()
    if self.IsOpen then return end
    self.IsOpen = true

    self.Main.Visible = true
    self.Glow1.Visible = true
    self.Glow2.Visible = true
    self.Glow3.Visible = true

    self.Main.Size = UDim2.new(0, 0, 0, 0)
    self.Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    self.Main.BackgroundTransparency = 1

    self.Glow1.ImageTransparency = 1
    self.Glow2.ImageTransparency = 1
    self.Glow3.ImageTransparency = 1

    tween(self.Main, 0.4, {
        Size = self.Size,
        Position = UDim2.new(0.5, -self.Size.X.Offset/2, 0.5, -self.Size.Y.Offset/2),
        BackgroundTransparency = 0
    }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    tween(self.Glow1, 0.5, {ImageTransparency = 0.9})
    tween(self.Glow2, 0.5, {ImageTransparency = 0.8})
    tween(self.Glow3, 0.5, {ImageTransparency = 0.7})
end

-- ==================== DEBUG КОНСОЛЬ ====================
function NeonUI:CreateDebugConsole()
    local console = Instance.new("Frame")
    console.Size = UDim2.new(0, 420, 0, 220)
    console.Position = UDim2.new(0, 20, 0, 20)
    console.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    console.BorderSizePixel = 0
    console.Visible = false
    console.ZIndex = 10
    console.Active = true
    console.Parent = self.ScreenGui
    makeCorner(console, 10)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    header.BorderSizePixel = 0
    header.ZIndex = 11
    header.Parent = console
    makeCorner(header, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "DEBUG CONSOLE"
    title.TextColor3 = Theme.Accent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 12
    title.Parent = header

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 22, 0, 22)
    close.Position = UDim2.new(1, -28, 0.5, -11)
    close.BackgroundColor3 = Theme.Danger
    close.Text = "✕"
    close.TextColor3 = Color3.new(1,1,1)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 12
    close.BorderSizePixel = 0
    close.ZIndex = 12
    close.AutoButtonColor = false
    close.Parent = header
    makeCorner(close, 6)

    close.MouseButton1Click:Connect(function()
        console.Visible = false
    end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -40)
    scroll.Position = UDim2.new(0, 10, 0, 35)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Theme.Accent
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ZIndex = 11
    scroll.Parent = console

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local logCount = 0
    local function addLog(text, logType)
        logCount = logCount + 1
        local color = Theme.Text
        if logType == "error" then color = Theme.Danger
        elseif logType == "warn" then color = Theme.Warning
        elseif logType == "success" then color = Theme.Success
        end

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 20)
        lbl.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        lbl.BackgroundTransparency = 0.5
        lbl.Text = "  [" .. logType:upper() .. "] " .. text
        lbl.TextColor3 = color
        lbl.Font = Enum.Font.Code
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.BorderSizePixel = 0
        lbl.ZIndex = 12
        lbl.Parent = scroll
        makeCorner(lbl, 4)

        scroll.CanvasSize = UDim2.new(0, 0, 0, logCount * 24)
    end

    -- Перетаскивание
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = console.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            console.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function()
        dragging = false
    end)

    addLog("Debug console initialized", "success")
    addLog("Watching for errors...", "warn")

    -- Перехват ошибок через getrawmetatable (если доступно)
    if getrawmetatable and setreadonly then
        pcall(function()
            local mt = getrawmetatable(game)
            if not mt then return end
            local oldNamecall = mt.__namecall
            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method == "error" then
                    local args = {...}
                    addLog(tostring(args[1]), "error")
                elseif method == "warn" then
                    local args = {...}
                    addLog(tostring(args[1]), "warn")
                end
                return oldNamecall(self, ...)
            end)
            setreadonly(mt, true)
        end)
    end

    self.DebugConsole = console
    return console, addLog
end

-- ==================== ВОЗВРАТ ====================
return NeonUI
