--!strict
-- Small, asset-free UI primitives shared by the HUD and its collection panels.
local TweenService = game:GetService("TweenService")

local Widgets = {}
Widgets.Colors = {
    Ink = Color3.fromRGB(20, 17, 40),
    Panel = Color3.fromRGB(34, 28, 65),
    Card = Color3.fromRGB(53, 44, 88),
    White = Color3.fromRGB(255, 252, 245),
    Muted = Color3.fromRGB(193, 190, 221),
    Gold = Color3.fromRGB(255, 212, 63),
    Green = Color3.fromRGB(97, 243, 151),
    Blue = Color3.fromRGB(74, 193, 255),
    Pink = Color3.fromRGB(255, 102, 175),
    Purple = Color3.fromRGB(175, 119, 255),
    Orange = Color3.fromRGB(255, 158, 65),
}

function Widgets.Round(parent: Instance, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

function Widgets.Outline(parent: Instance, thickness: number, color: Color3?): UIStroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Widgets.Colors.Ink
    stroke.Thickness = thickness
    stroke.ApplyStrokeMode = if parent:IsA("TextLabel") then Enum.ApplyStrokeMode.Contextual else Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    stroke.Parent = parent
    return stroke
end

function Widgets.Gradient(parent: Instance, color: Color3, bottom: Color3?)
    local gradient = parent:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
    gradient.Name = "SurfaceGradient"
    local hue, saturation, value = color:ToHSV()
    local low = bottom
    if not low then
        if value < 0.4 then low = color:Lerp(Color3.new(0, 0, 0), 0.25)
        else
            local offset = if hue < 0.16 then -0.055 elseif hue < 0.55 then 0.07 elseif hue < 0.78 then 0.035 else -0.10
            low = Color3.fromHSV((hue + offset) % 1, math.min(1, saturation + 0.16), value * 0.85)
        end
    end
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color:Lerp(Color3.new(1, 1, 1), if value < 0.4 then 0.10 else 0.30)),
        ColorSequenceKeypoint.new(0.42, color),
        ColorSequenceKeypoint.new(1, low),
    })
    gradient.Rotation = 90
    gradient.Parent = parent
    if parent:IsA("GuiObject") then parent.BackgroundColor3 = Color3.new(1, 1, 1) end
    return gradient
end

-- A small fixed stud field evokes Roblox brick surfaces without image assets or
-- per-frame work. Callers choose density; the hard cap keeps mobile GUI cost bounded.
function Widgets.Pattern(parent: GuiObject, color: Color3?, columns: number?, rows: number?): Frame
    local pattern = Instance.new("Frame")
    pattern.Name = "StudPattern"
    pattern.Size = UDim2.fromScale(1, 1)
    pattern.BackgroundTransparency = 1
    pattern.ClipsDescendants = true
    pattern.Parent = parent
    Widgets.Round(pattern, 10)
    local countX = math.clamp(math.floor(columns or 8), 1, 12)
    local countY = math.clamp(math.floor(rows or 1), 1, 2)
    local tint = color or Color3.new(1, 1, 1)
    for row = 1, countY do
        for column = 1, countX do
            local stud = Instance.new("Frame")
            stud.Name = "Stud"
            stud.AnchorPoint = Vector2.new(0.5, 0.5)
            stud.Position = UDim2.fromScale((column - 0.5) / countX, (row - 0.5) / countY)
            stud.Size = UDim2.fromOffset(7, 7)
            stud.BorderSizePixel = 0
            stud.BackgroundColor3 = tint
            stud.BackgroundTransparency = 0.91
            stud.Parent = pattern
            local stroke = Widgets.Outline(stud, 1, tint:Lerp(Widgets.Colors.Ink, 0.55))
            stroke.Transparency = 0.75
        end
    end
    return pattern
end

local function bevel(parent: GuiObject, radius: number, glossy: boolean)
    local inset = Instance.new("Frame")
    inset.Name = "InsetBevel"
    inset.Position = UDim2.fromOffset(3, 3)
    inset.Size = UDim2.new(1, -6, 1, -6)
    inset.BackgroundTransparency = 1
    inset.Parent = parent
    Widgets.Round(inset, math.max(3, radius - 2))
    local edge = Widgets.Outline(inset, 1.2, Color3.new(1, 1, 1))
    edge.Transparency = if glossy then 0.46 else 0.82
    if glossy then
        local shine = Instance.new("Frame")
        shine.Name = "GlossHighlight"
        shine.Position = UDim2.fromOffset(5, 4)
        shine.Size = UDim2.new(1, -10, 0.4, -1)
        shine.BackgroundColor3 = Color3.new(1, 1, 1)
        shine.BackgroundTransparency = 0.83
        shine.BorderSizePixel = 0
        shine.Parent = parent
        Widgets.Round(shine, radius - 3)
        local glint = Instance.new("Frame")
        glint.Name = "TopGlint"
        glint.Position = UDim2.new(0.2, 0, 0, 3)
        glint.Size = UDim2.new(0.6, 0, 0, 2)
        glint.BackgroundColor3 = Color3.new(1, 1, 1)
        glint.BackgroundTransparency = 0.35
        glint.BorderSizePixel = 0
        glint.Parent = parent
    end
    local shade = Instance.new("Frame")
    shade.Name = "BottomBevel"
    shade.AnchorPoint = Vector2.new(0, 1)
    shade.Position = UDim2.new(0, 5, 1, -3)
    shade.Size = UDim2.new(1, -10, 0, if glossy then 4 else 2)
    shade.BackgroundColor3 = Widgets.Colors.Ink
    shade.BackgroundTransparency = if glossy then 0.55 else 0.7
    shade.BorderSizePixel = 0
    shade.Parent = parent
end

function Widgets.Frame(parent: Instance, name: string, position: UDim2, size: UDim2, color: Color3?): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Position = position
    frame.Size = size
    frame.BackgroundColor3 = color or Widgets.Colors.Panel
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Widgets.Round(frame, 14)
    Widgets.Outline(frame, 3)
    Widgets.Gradient(frame, color or Widgets.Colors.Panel)
    bevel(frame, 14, false)
    return frame
end

function Widgets.Label(parent: Instance, name: string, value: string, position: UDim2, size: UDim2, fontSize: number, color: Color3?, body: boolean?): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Position = position
    label.Size = size
    label.Font = if body then Enum.Font.GothamBold else Enum.Font.FredokaOne
    label.Text = value
    label.TextSize = fontSize
    label.TextColor3 = color or Widgets.Colors.White
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    Widgets.Outline(label, if body then 1.5 else 2.5)
    return label
end

function Widgets.Button(parent: Instance, name: string, value: string, position: UDim2, size: UDim2, color: Color3, fontSize: number?): TextButton
    local button = Instance.new("TextButton")
    button.Name = name
    button.Position = position
    button.Size = size
    button.BackgroundColor3 = Color3.new(1, 1, 1)
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Selectable = true
    button.Parent = parent
    Widgets.Round(button, 12)
    Widgets.Outline(button, 3)
    Widgets.Gradient(button, color)
    bevel(button, 12, true)
    local label = Widgets.Label(button, "Caption", value, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), fontSize or 15)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextWrapped = true
    local scale = Instance.new("UIScale")
    scale.Name = "InteractionScale"
    scale.Parent = button
    local activeTween: Tween? = nil
    local function animate(amount: number)
        if activeTween then activeTween:Cancel() end
        activeTween = TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Scale = amount})
        activeTween:Play()
    end
    button.MouseEnter:Connect(function() animate(1.04) end)
    button.MouseLeave:Connect(function() animate(1) end)
    button.SelectionGained:Connect(function() animate(1.04) end)
    button.SelectionLost:Connect(function() animate(1) end)
    button.MouseButton1Down:Connect(function() animate(0.94) end)
    button.MouseButton1Up:Connect(function() animate(1) end)
    return button
end

function Widgets.List(parent: Instance, name: string, position: UDim2, size: UDim2): ScrollingFrame
    local list = Instance.new("ScrollingFrame")
    list.Name = name
    list.Position = position
    list.Size = size
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 5
    list.ScrollBarImageColor3 = Widgets.Colors.Purple
    list.CanvasSize = UDim2.new()
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.ScrollingDirection = Enum.ScrollingDirection.Y
    list.Active = true
    list.Parent = parent
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 9)
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = list
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = list
    return list
end

return Widgets
