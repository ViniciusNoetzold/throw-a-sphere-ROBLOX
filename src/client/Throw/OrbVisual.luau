--!strict
local OrbVisual = {}

function OrbVisual.Create(color: Color3, diameter: number): (Model, BasePart)
    local model = Instance.new("Model")
    model.Name = "Orb"
    local function shape(name: string, kind: Enum.PartType, size: Vector3, frame: CFrame, tint: Color3, material: Enum.Material): Part
        local part = Instance.new("Part")
        part.Name, part.Shape, part.Size, part.CFrame = name, kind, size * diameter, frame
        part.Color, part.Material, part.Anchored = tint, material, true
        part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
        part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
        part.Parent = model
        return part
    end
    local pale = color:Lerp(Color3.fromRGB(247, 248, 255), .62)
    local rim = color:Lerp(Color3.fromRGB(32, 41, 73), .57)
    local core = shape("Shell", Enum.PartType.Ball, Vector3.one, CFrame.new(), pale, Enum.Material.SmoothPlastic)
    shape("MagneticRing", Enum.PartType.Cylinder, Vector3.new(.15, 1.06, 1.06),
        CFrame.Angles(0, 0, 1.02), rim, Enum.Material.SmoothPlastic)
    shape("LightBand", Enum.PartType.Cylinder, Vector3.new(.037, 1.075, 1.075),
        CFrame.Angles(0, 0, 1.02), color, Enum.Material.Neon)
    local lens = Vector3.new(0, .08, -.433) * diameter
    shape("CaptureLens", Enum.PartType.Ball, Vector3.new(.26, .26, .17), CFrame.new(lens), rim, Enum.Material.SmoothPlastic)
    shape("CoreGlow", Enum.PartType.Ball, Vector3.new(.14, .14, .11),
        CFrame.new(lens + Vector3.new(0, 0, -.063 * diameter)), pale, Enum.Material.Neon)
    model.PrimaryPart = core
    return model, core
end

return OrbVisual
