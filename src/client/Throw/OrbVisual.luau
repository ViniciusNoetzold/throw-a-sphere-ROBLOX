--!strict
local OrbVisual = {}

type Style = {Fittings: number, Metal: Color3, Shell: Color3, Halo: boolean?}
local steel = Color3.fromRGB(179, 209, 224)
local pearl = Color3.fromRGB(240, 243, 245)
local baseStyle: Style = {Fittings = 2, Metal = steel, Shell = pearl}
local styles: {[string]: Style} = {
    Esmeralda = {Fittings = 4, Metal = Color3.fromRGB(167, 230, 178), Shell = pearl},
    Rubi = {Fittings = 4, Metal = Color3.fromRGB(255, 185, 123), Shell = Color3.fromRGB(255, 217, 205)},
    Safira = {Fittings = 6, Metal = Color3.fromRGB(147, 225, 255), Shell = Color3.fromRGB(233, 247, 255)},
    Runica = {Fittings = 6, Metal = Color3.fromRGB(239, 192, 72), Shell = Color3.fromRGB(78, 67, 42)},
    Hextech = {Fittings = 8, Metal = Color3.fromRGB(100, 195, 215), Shell = Color3.fromRGB(44, 82, 101), Halo = true},
    Cosmica = {Fittings = 6, Metal = Color3.fromRGB(188, 143, 246), Shell = Color3.fromRGB(68, 47, 107), Halo = true},
    Mestre = {Fittings = 8, Metal = Color3.fromRGB(252, 215, 104), Shell = Color3.fromRGB(103, 49, 106), Halo = true},
    Prismatica = {Fittings = 8, Metal = Color3.fromRGB(239, 212, 255), Shell = pearl, Halo = true},
}

function OrbVisual.Create(color: Color3, diameter: number, orbId: string?): (Model, BasePart)
    local model = Instance.new("Model")
    model.Name = "Orb"
    local style = if orbId then styles[orbId] or baseStyle else baseStyle
    local function shape(name: string, kind: Enum.PartType, size: Vector3, frame: CFrame, tint: Color3, material: Enum.Material): Part
        local part = Instance.new("Part")
        part.Name, part.Shape, part.Size, part.CFrame = name, kind, size * diameter, frame
        part.Color, part.Material, part.Anchored = tint, material, true
        part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
        part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
        part.Parent = model
        return part
    end
    local ink = color:Lerp(Color3.fromRGB(22, 29, 46), .77)
    local bright = color:Lerp(pearl, .32)
    local vertical = CFrame.Angles(0, 0, math.pi / 2)
    local core = shape("CeramicShell", Enum.PartType.Ball, Vector3.one, CFrame.new(), style.Shell:Lerp(color, .21), Enum.Material.SmoothPlastic)
    shape("Crown", Enum.PartType.Ball, Vector3.new(.95, .77, .95), CFrame.new(0, .16 * diameter, 0), color, Enum.Material.SmoothPlastic)
    shape("Collar", Enum.PartType.Cylinder, Vector3.new(.16, 1.055, 1.055), vertical, ink, Enum.Material.SmoothPlastic)
    for _, side in {-1, 1} do
        shape("MetalRim", Enum.PartType.Cylinder, Vector3.new(.026, 1.073, 1.073),
            CFrame.new(0, side * .073 * diameter, 0) * vertical, style.Metal, Enum.Material.Metal)
    end
    for index = 1, style.Fittings do
        local angle = (index - .5) * math.pi * 2 / style.Fittings
        local radial = Vector3.new(math.sin(angle), 0, math.cos(angle))
        local point = (radial * .51 + Vector3.new(0, .035, 0)) * diameter
        local seat = CFrame.lookAt(point, point + radial)
        shape("ShellClamp", Enum.PartType.Block, Vector3.new(.105, .23, .085), seat, style.Metal, Enum.Material.Metal)
        if style.Halo then
            shape("CoreVent", Enum.PartType.Block, Vector3.new(.061, .095, .038),
                seat * CFrame.new(0, -.013 * diameter, -.05 * diameter), bright, Enum.Material.Neon)
        end
    end
    local lens = CFrame.new(0, .026 * diameter, -.525 * diameter) * CFrame.Angles(0, math.pi / 2, 0)
    shape("LensHousing", Enum.PartType.Cylinder, Vector3.new(.11, .36, .36), lens, ink, Enum.Material.Metal)
    shape("LensTrim", Enum.PartType.Cylinder, Vector3.new(.047, .27, .27),
        lens * CFrame.new(.065 * diameter, 0, 0), style.Metal, Enum.Material.Metal)
    shape("Prism", Enum.PartType.Block, Vector3.new(.053, .171, .171),
        lens * CFrame.new(.093 * diameter, 0, 0) * CFrame.Angles(math.pi / 4, 0, 0), bright, Enum.Material.Neon)
    model.PrimaryPart = core
    return model, core
end

return OrbVisual
