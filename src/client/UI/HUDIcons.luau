--!strict
-- Native pictograms: no uploaded images, font glyphs, or texture dependencies.
local Icons = {}
local WHITE = Color3.fromRGB(255, 253, 231)
local INK = Color3.fromRGB(21, 18, 48)
local GOLD = Color3.fromRGB(255, 225, 91)

local function shape(parent: Instance, name: string, x: number, y: number, width: number, height: number, color: Color3, rounded: boolean?, rotation: number?): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Position = UDim2.fromScale(x, y)
    frame.Size = UDim2.fromScale(width, height)
    frame.BackgroundColor3 = color
    frame.BorderSizePixel = 0
    frame.Active = false
    frame.Rotation = rotation or 0
    frame.Parent = parent
    if rounded then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = frame
    end
    return frame
end

local function line(parent: Instance, name: string, x1: number, y1: number, x2: number, y2: number, width: number, color: Color3): Frame
    local dx, dy = x2 - x1, y2 - y1
    local frame = shape(parent, name, (x1 + x2) * 0.5, (y1 + y2) * 0.5, math.sqrt(dx * dx + dy * dy), width, color)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Rotation = math.deg(math.atan2(dy, dx))
    return frame
end

local function stroke(frame: Frame, color: Color3, thickness: number): UIStroke
    local outline = Instance.new("UIStroke")
    outline.Color = color
    outline.Thickness = thickness
    outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outline.Parent = frame
    return outline
end

local aliases = {
    bestiario = "book", loja = "shop", fusao = "fusion", diario = "gift", ranking = "trophy",
    criaturas = "paw", orbes = "orb", auto = "bolt", codigos = "ticket", forca = "bolt",
    fogo = "fire", agua = "water", planta = "leaf", raio = "bolt", gelo = "ice", terra = "earth", cosmico = "cosmic",
}

function Icons.Draw(parent: GuiObject, iconId: string, color: Color3?): Frame
    local tint = color or Color3.fromRGB(90, 205, 255)
    local canvas = Instance.new("Frame")
    canvas.Name = "Icon_" .. iconId
    canvas.AnchorPoint = Vector2.new(0.5, 0.5)
    canvas.Position = UDim2.fromScale(0.5, 0.5)
    canvas.Size = UDim2.fromScale(0.98, 0.98)
    canvas.BackgroundTransparency = 1
    canvas.Active = false
    canvas.Parent = parent
    local aspect = Instance.new("UIAspectRatioConstraint")
    aspect.AspectRatio = 1
    aspect.AspectType = Enum.AspectType.FitWithinMaxSize
    aspect.Parent = canvas
    local rim = shape(canvas, "NeonRing", 0.025, 0.025, 0.95, 0.95, Color3.new(1, 1, 1), true)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, tint:Lerp(WHITE, 0.45)), ColorSequenceKeypoint.new(0.5, tint), ColorSequenceKeypoint.new(1, tint:Lerp(INK, 0.4))})
    gradient.Rotation = 65
    gradient.Parent = rim
    local inside = shape(canvas, "Recess", 0.115, 0.115, 0.77, 0.77, tint:Lerp(INK, 0.78), true)
    local ringGlint = shape(canvas, "RimGlint", 0.25, 0.045, 0.36, 0.035, WHITE, true)
    ringGlint.BackgroundTransparency = 0.28
    local art = shape(inside, "Artwork", 0.12, 0.1, 0.76, 0.8, WHITE)
    art.BackgroundTransparency = 1
    local id = string.lower(iconId)
    id = aliases[id] or id

    if id == "orb" then
        local orbit = shape(art, "OrbitalRing", 0.04, 0.32, 0.92, 0.34, WHITE, true, -30)
        orbit.BackgroundTransparency = 1
        stroke(orbit, tint:Lerp(WHITE, 0.65), 1.5)
        shape(art, "RunicCore", 0.30, 0.26, 0.42, 0.42, tint:Lerp(WHITE, 0.6), false, 45)
        shape(art, "CoreFacet", 0.42, 0.29, 0.17, 0.32, WHITE, false, 45)
        shape(art, "Satellite", 0.07, 0.60, 0.13, 0.13, GOLD, true)
        shape(art, "RuneGlint", 0.77, 0.16, 0.13, 0.13, WHITE, false, 45)
    elseif id == "bolt" then
        shape(art, "BoltTop", 0.41, 0.03, 0.23, 0.47, GOLD, false, 28)
        shape(art, "BoltBridge", 0.23, 0.4, 0.50, 0.16, GOLD, false, -8)
        shape(art, "BoltTail", 0.34, 0.48, 0.22, 0.49, WHITE, false, 28)
    elseif id == "book" then
        shape(art, "Cover", 0.09, 0.14, 0.82, 0.7, tint:Lerp(WHITE, 0.6), true)
        shape(art, "LeftPage", 0.16, 0.18, 0.31, 0.58, WHITE)
        shape(art, "RightPage", 0.53, 0.18, 0.31, 0.58, WHITE)
        line(art, "Spine", 0.5, 0.18, 0.5, 0.8, 0.05, INK)
        line(art, "TextLeft", 0.22, 0.4, 0.4, 0.4, 0.055, tint)
        line(art, "TextRight", 0.6, 0.4, 0.78, 0.4, 0.055, tint)
    elseif id == "shop" then
        local handle = shape(art, "Handle", 0.30, 0.06, 0.40, 0.40, WHITE, true)
        handle.BackgroundTransparency = 1
        stroke(handle, WHITE, 2)
        shape(art, "Bag", 0.14, 0.31, 0.72, 0.57, tint:Lerp(WHITE, 0.65), true)
        shape(art, "BagEmblem", 0.39, 0.45, 0.22, 0.22, GOLD, false, 45)
    elseif id == "fusion" then
        line(art, "LeftLink", 0.25, 0.25, 0.5, 0.72, 0.11, WHITE)
        line(art, "RightLink", 0.75, 0.25, 0.5, 0.72, 0.11, WHITE)
        shape(art, "First", 0.04, 0.06, 0.36, 0.36, GOLD, true)
        shape(art, "Second", 0.6, 0.06, 0.36, 0.36, WHITE, true)
        shape(art, "Merged", 0.29, 0.55, 0.42, 0.42, tint:Lerp(WHITE, 0.6), true)
    elseif id == "gift" then
        shape(art, "BowLeft", 0.17, 0.04, 0.32, 0.23, WHITE, true, 25)
        shape(art, "BowRight", 0.49, 0.04, 0.32, 0.23, WHITE, true, -25)
        shape(art, "Box", 0.15, 0.36, 0.70, 0.52, tint:Lerp(WHITE, 0.20))
        shape(art, "Lid", 0.08, 0.26, 0.84, 0.18, GOLD)
        shape(art, "Ribbon", 0.43, 0.26, 0.14, 0.62, WHITE)
    elseif id == "rebirth" then
        local cycle = shape(art, "Cycle", 0.16, 0.18, 0.68, 0.64, WHITE, true)
        cycle.BackgroundTransparency = 1
        stroke(cycle, WHITE, 2.5)
        line(art, "ArrowTopA", 0.51, 0.05, 0.72, 0.18, 0.1, GOLD)
        line(art, "ArrowTopB", 0.72, 0.18, 0.51, 0.30, 0.1, GOLD)
        line(art, "ArrowBottomA", 0.49, 0.7, 0.28, 0.82, 0.1, GOLD)
        line(art, "ArrowBottomB", 0.28, 0.82, 0.49, 0.95, 0.1, GOLD)
    elseif id == "trophy" or id == "crown" then
        shape(art, "CrownBase", 0.15, 0.55, 0.70, 0.26, GOLD)
        shape(art, "LeftPoint", 0.13, 0.24, 0.17, 0.48, GOLD, false, -13)
        shape(art, "MiddlePoint", 0.40, 0.08, 0.20, 0.58, WHITE)
        shape(art, "RightPoint", 0.70, 0.24, 0.17, 0.48, GOLD, false, 13)
        shape(art, "CrownJewel", 0.42, 0.60, 0.16, 0.16, tint, false, 45)
    elseif id == "paw" then
        shape(art, "Pad", 0.25, 0.46, 0.52, 0.42, WHITE, true)
        shape(art, "Toe1", 0.04, 0.26, 0.22, 0.27, GOLD, true, -20)
        shape(art, "Toe2", 0.25, 0.08, 0.22, 0.28, WHITE, true, -8)
        shape(art, "Toe3", 0.53, 0.08, 0.22, 0.28, WHITE, true, 8)
        shape(art, "Toe4", 0.75, 0.26, 0.22, 0.27, GOLD, true, 20)
    elseif id == "ticket" then
        shape(art, "Ticket", 0.10, 0.24, 0.80, 0.53, WHITE, true, -12)
        line(art, "Perforation", 0.65, 0.29, 0.65, 0.65, 0.035, tint)
        shape(art, "Stamp", 0.27, 0.35, 0.22, 0.22, GOLD, false, 33)
    elseif id == "lock" then
        local loop = shape(art, "LockLoop", 0.27, 0.04, 0.46, 0.54, WHITE, true)
        loop.BackgroundTransparency = 1
        stroke(loop, WHITE, 2.5)
        shape(art, "LockBody", 0.15, 0.40, 0.70, 0.48, GOLD, true)
        shape(art, "Keyhole", 0.44, 0.53, 0.13, 0.23, INK, true)
    elseif id == "fire" then
        shape(art, "OuterFlame", 0.27, 0.05, 0.50, 0.77, Color3.fromRGB(255, 145, 39), true, 18)
        shape(art, "LeftFlame", 0.12, 0.35, 0.45, 0.52, GOLD, true, -25)
        shape(art, "Core", 0.33, 0.43, 0.36, 0.48, WHITE, true, 10)
    elseif id == "water" then
        shape(art, "DropTip", 0.30, 0.08, 0.40, 0.40, WHITE, false, 45)
        shape(art, "Drop", 0.18, 0.29, 0.64, 0.60, WHITE, true)
        shape(art, "DropGlint", 0.32, 0.43, 0.13, 0.23, tint, true, 20)
    elseif id == "leaf" then
        shape(art, "Leaf", 0.20, 0.13, 0.59, 0.72, WHITE, true, 36)
        line(art, "Stem", 0.22, 0.87, 0.7, 0.24, 0.07, tint)
        line(art, "Vein", 0.45, 0.58, 0.36, 0.36, 0.05, tint)
    elseif id == "ice" then
        for _, angle in {0, 60, 120} do
            local radians = math.rad(angle)
            local dx, dy = math.cos(radians) * 0.4, math.sin(radians) * 0.4
            line(art, "IceCrystal", 0.5 - dx, 0.5 - dy, 0.5 + dx, 0.5 + dy, 0.1, WHITE)
        end
        shape(art, "IceCore", 0.36, 0.36, 0.28, 0.28, GOLD, false, 45)
    elseif id == "earth" then
        shape(art, "Gem", 0.21, 0.20, 0.59, 0.59, GOLD, false, 45)
        shape(art, "Facet", 0.36, 0.26, 0.28, 0.46, WHITE, false, 45)
    elseif id == "sword" then
        line(art, "Hilt", 0.20, 0.86, 0.45, 0.59, 0.16, GOLD)
        line(art, "Blade", 0.43, 0.60, 0.83, 0.13, 0.20, WHITE)
        line(art, "Guard", 0.24, 0.42, 0.65, 0.77, 0.12, GOLD)
    elseif id == "menu" then
        for _, y in {0.25, 0.5, 0.75} do
            line(art, "MenuBar", 0.12, y, 0.88, y, 0.13, WHITE)
        end
    else
        -- Cosmic / unknown: a clear orb-and-orbit motif, never a missing glyph.
        local orbit = shape(art, "Orbit", 0.04, 0.30, 0.92, 0.36, WHITE, true, -35)
        orbit.BackgroundTransparency = 1
        stroke(orbit, WHITE, 1.5)
        shape(art, "Planet", 0.29, 0.28, 0.44, 0.44, GOLD, true)
        shape(art, "Star", 0.73, 0.11, 0.15, 0.15, WHITE, false, 45)
    end
    return canvas
end

return Icons
