--!strict
-- Grounded course geometry. Distance marks use the same zone lengths as flight resolution.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Rules = require(ReplicatedStorage.Shared.ConfigFlight)
local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.ConfigWorld)
local World = {}
function World.Init(ctx: any)
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "FlightCorridor", workspace
    local function part(name: string, size: Vector3, position: Vector3, color: Color3, neon: boolean?): Part
        local p = Instance.new("Part")
        p.Name, p.Size, p.Position, p.Color = name, size, position, color
        p.Anchored, p.TopSurface = true, Enum.SurfaceType.Studs
        if neon then
            p.Material = Enum.Material.Neon
            p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
        end
        p.Parent = folder
        return p
    end
    local charcoal = Color3.fromRGB(42, 49, 61)
    local cream = Color3.fromRGB(255, 247, 202)
    local yellow = Color3.fromRGB(255, 199, 52)
    local function sign(beam: Part, caption: string, ink: Color3)
        local plate = part("CourseSign", Vector3.new(28, 1.9, .32),
            beam.Position + Vector3.new(0, .32, beam.Size.Z / 2 + .16), charcoal)
        plate.CanCollide, plate.CanTouch, plate.CanQuery = false, false, false
        local panel = Instance.new("SurfaceGui")
        panel.Name, panel.Face, panel.LightInfluence = "CourseLettering", Enum.NormalId.Back, .12
        panel.CanvasSize, panel.Parent = Vector2.new(560, 52), plate
        local text = Instance.new("TextLabel")
        text.Size, text.BackgroundTransparency, text.Parent = UDim2.fromScale(1, 1), 1, panel
        text.Text, text.TextColor3, text.TextScaled = caption, ink, true
        text.Font = Enum.Font.GothamBlack
    end
    local line = Rules.LinePosition
    local stone = Color3.fromRGB(128, 135, 137)
    part("CorridorEarth", Vector3.new(164, 51, Rules.MaxDistance + 30),
        Rules.LaunchOrigin + Vector3.new(0, -29, 10 - (Rules.MaxDistance + 30) / 2), Color3.fromRGB(106, 75, 52))
    for step = 0, 7 do
        for _, side in {-1, 1} do
            part("LaunchPathTile", Vector3.new(14.8, .34, 14.8), Vector3.new(side * 7.5, -.01, -98 + step * 15),
                if (step + side) % 3 == 0 then stone:Lerp(charcoal, .24) else stone)
        end
    end
    local pad = part("YellowLaunchLine", Vector3.new(Rules.LineWidth, .4, Rules.LineDepth), line + Vector3.new(0, -1.75, 0), yellow)
    pad.TopSurface = Enum.SurfaceType.Studs
    part("LaunchApron", Vector3.new(74, 1, 30), line + Vector3.new(0, -2.5, 12), charcoal)
    for _, side in {-1, 1} do
        part("StripeEdge", Vector3.new(Rules.LineWidth, .07, 1.1), pad.Position + Vector3.new(0, .22, side * (Rules.LineDepth / 2 - 1)), cream, true)
        part("ArchFoot", Vector3.new(6, 1, 7), line + Vector3.new(side * 33, -1.25, -6), charcoal)
        part("ArchTower", Vector3.new(4.5, 16, 4.5), line + Vector3.new(side * 33, 6, -6), Color3.fromRGB(252, 144, 64))
        part("ArchLight", Vector3.new(1.5, 11, .55), line + Vector3.new(side * 33, 6, -3.4), cream, true)
    end
    local arch = part("LaunchArch", Vector3.new(70, 3.3, 4.5), line + Vector3.new(0, 14.5, -6), charcoal)
    part("ArchCornice", Vector3.new(74, .9, 5.8), arch.Position + Vector3.new(0, 1.85, 0), stone)
    part("ArchInlay", Vector3.new(38, .72, .24), arch.Position + Vector3.new(0, -1.15, 2.3), yellow, true)
    sign(arch, "PISTA DE ORBES", cream)
    for _, x in {-20, 0, 20} do
        for _, side in {-1, 1} do
            local arrow = part("LaunchChevron", Vector3.new(.65, .06, 4), pad.Position + Vector3.new(x + side * 1.25, .24, 4), charcoal, true)
            arrow.Material = Enum.Material.SmoothPlastic
            arrow.CFrame *= CFrame.Angles(0, math.rad(side * 48), 0)
        end
    end
    local barrier = part("PlayerBarrier", Vector3.new(68, 80, 3), Rules.LaunchOrigin + Vector3.new(0, 36, -2), Color3.new(1, 1, 1))
    barrier.Transparency, barrier.CanQuery = 1, false
    -- Physical barrier plus server correction: the track is reserved for the orb.
    if not ctx.DisableLoops then task.spawn(function()
        while folder.Parent do
            task.wait(0.15)
            for _, player in Players:GetPlayers() do
                local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root and root:IsA("BasePart") then
                    local p=root.Position
                    if p.Y >= -7 and math.abs(p.X)<36 and p.Z<Rules.LaunchOrigin.Z-1 and p.Z>Rules.LaunchOrigin.Z-Rules.MaxDistance-30 then
                        player.Character:PivotTo(CFrame.lookAt(Rules.LinePosition+Vector3.new(0,2,3),Rules.LinePosition+Vector3.new(0,2,-20)))
                        root.AssemblyLinearVelocity=Vector3.zero
                    end
                end
            end
        end
    end) end
    local accents = {
        Color3.fromRGB(156, 214, 88), Color3.fromRGB(111, 229, 200),
        Color3.fromRGB(250, 144, 70), Color3.fromRGB(165, 223, 250),
        Color3.fromRGB(232, 186, 104), Color3.fromRGB(178, 140, 239),
    }
    local white = Color3.fromRGB(243, 236, 211)
    for index, id in Layout.BiomeOrder do
        local biome = Layout.Biomes[id]
        local palette = biome.Colors
        local origin = Rules.LaunchOrigin + Rules.Direction * ((index - 1) * Rules.ZoneLength)
        local accent = accents[index]
        local masonry = charcoal:Lerp(accent, .24)
        local road = charcoal:Lerp(accent, .34)
        local segments = math.ceil(Rules.ZoneLength / Layout.TileSize)
        local step = Rules.ZoneLength / segments
        part("RoadFoundation_" .. id, Vector3.new(70, 1.8, Rules.ZoneLength),
            origin + Vector3.new(0, -3.02, -Rules.ZoneLength / 2), masonry)
        for segment = 0, segments - 1 do
            local center = origin + Vector3.new(0, -2.46, -(segment + .5) * step)
            for _, side in {-1, 1} do
                local tileColor = if (segment + side) % 3 == 0 then road:Lerp(white, .1) else road
                part("Runway_" .. id, Vector3.new(23.7, 1.1, step - .14), center + Vector3.new(side * 12, 0, 0), tileColor)
                part("ShoulderPaver", Vector3.new(8.2, .8, step - .2), center + Vector3.new(side * 28.2, .05, 0),
                    if (segment + side) % 3 == 1 then accent:Lerp(masonry, .32) else masonry)
                part("Kerb", Vector3.new(1.1, .22, step - .22), center + Vector3.new(side * 24.1, .57, 0),
                    if segment % 2 == 0 then accent else white)
                if segment % 2 == 0 then
                    part("TrackReflector", Vector3.new(.9, .09, 2.1), center + Vector3.new(side * 23, .59, 0), accent, true)
                end
            end
            local dash = part("CenterDash", Vector3.new(1.15, .05, 11), center + Vector3.new(0, .58, 0), white)
            dash.CanCollide, dash.CanTouch, dash.CanQuery = false, false, false
        end
        for _, side in {-1, 1} do
            local mid = origin + Vector3.new(side * 34.8, 0, -Rules.ZoneLength / 2)
            part("TunnelWall_" .. id, Vector3.new(4.4, 28, Rules.ZoneLength), mid + Vector3.new(0, 11, 0), masonry)
            part("WallBase", Vector3.new(5.1, 4, Rules.ZoneLength), mid + Vector3.new(0, 0, 0), charcoal)
            part("WallCornice", Vector3.new(6, 1.6, Rules.ZoneLength), mid + Vector3.new(0, 25, 0), road)
            part("WallRibbon", Vector3.new(.35, .65, Rules.ZoneLength), mid + Vector3.new(-side * 2.3, 5.4, 0), accent)
            for section = 1, 6 do
                local length = Rules.ZoneLength / 6
                local middle = origin + Vector3.new(0, 0, -(section - .5) * length)
                local wallTile = part("TunnelStudPanel", Vector3.new(.65, 17.4, length - 1.2),
                    middle + Vector3.new(side * 32.5, 14, 0), masonry:Lerp(accent, if section % 2 == 0 then .13 else .05))
                if side == 1 then wallTile.LeftSurface = Enum.SurfaceType.Studs else wallTile.RightSurface = Enum.SurfaceType.Studs end
                part("WallButtress", Vector3.new(3.7, 25, 3.2), middle + Vector3.new(side * 33, 11, length / 2 - 1.6), charcoal)
                local hill = 30 + (section * 7 + index * 3) % 13
                part("Hillside", Vector3.new(38, hill + 9, length),
                    middle + Vector3.new(side * 57.3, (hill - 9) / 2, 0), masonry:Lerp(palette[2], .35))
                part("HillsideCap", Vector3.new(38, 1.4, length), middle + Vector3.new(side * 57.3, hill + .2, 0),
                    accent:Lerp(masonry, .46))
            end
            for n = 1, 4 do
                local position = origin + Vector3.new(side * 28.6, -1.72, -n * Rules.ZoneLength / 5)
                part("LandmarkPedestal", Vector3.new(7, 1.15, 12), position, masonry)
                if index == 1 then
                    part("TreeTrunk", Vector3.new(1.7, 5.9, 1.7), position + Vector3.new(0, 3, 0), Color3.fromRGB(136, 90, 58))
                    for layer = 1, 3 do
                        local width = 7.7 - layer * 1.45
                        part("TreeLeaves", Vector3.new(width, 1.7, width), position + Vector3.new(0, 3.6 + layer * 1.5, 0),
                            accent:Lerp(palette[2], (4 - layer) * .23))
                    end
                    for _, offset in {-3, 3} do
                        part("FlowerBlock", Vector3.new(1.5, .8, 1.5), position + Vector3.new(side, .85, offset),
                            if offset < 0 then Color3.fromRGB(255, 197, 85) else Color3.fromRGB(240, 134, 159))
                    end
                elseif index == 2 then
                    local stem = part("MushroomStem", Vector3.new(2, 5.7, 2), position + Vector3.new(0, 3, 0), white)
                    stem.TopSurface = Enum.SurfaceType.Smooth
                    local cap = part("MushroomCap", Vector3.new(7, 2.8, 7), position + Vector3.new(0, 6.15, 0), accent)
                    cap.Shape = Enum.PartType.Ball
                    part("MushroomGlow", Vector3.new(2, .85, 2), position + Vector3.new(0, 7.35, 0), accent, true).Shape = Enum.PartType.Ball
                elseif index == 3 then
                    for layer = 1, 4 do
                        local width = 7 - layer * 1.25
                        part("BasaltStratum", Vector3.new(width, 1.65, width + 1), position + Vector3.new(0, layer * 1.55, 0),
                            if layer == 2 then road else charcoal)
                    end
                    part("EmberCore", Vector3.new(1.35, .6, 1.35), position + Vector3.new(0, 7.25, 0), accent, true)
                elseif index == 4 then
                    for blade = -1, 1 do
                        local shard = part("IceBlade", Vector3.new(1.8, 6.5 - math.abs(blade) * 2.6, 1.8),
                            position + Vector3.new(blade * 1.5, 3 - math.abs(blade), blade * 2.4), accent:Lerp(white, math.abs(blade) * .33))
                        shard.CFrame *= CFrame.Angles(0, math.rad(45), blade * .2)
                    end
                elseif index == 5 then
                    for _, offset in {-3, 3} do
                        part("RuinColumn", Vector3.new(2.1, 7.2, 2.1), position + Vector3.new(0, 3.8, offset), accent)
                    end
                    part("RuinLintel", Vector3.new(2.5, 1.2, 8.8), position + Vector3.new(0, 7.5, 0), accent:Lerp(white, .25))
                else
                    part("GeodeBase", Vector3.new(5, 3.8, 6), position + Vector3.new(0, 1.9, 0), charcoal)
                    for point = -1, 1 do
                        local crystal = part("CosmicGeode", Vector3.new(1.8, 4.5 - math.abs(point), 1.8),
                            position + Vector3.new(0, 3.1, point * 2.2), accent, true)
                        crystal.CFrame *= CFrame.Angles(point * .28, math.rad(45), side * .25)
                    end
                end
            end
        end
        if index > 1 then
            local gate = part("Gate_" .. id, Vector3.new(72, 3.2, 3.7), origin + Vector3.new(0, 23.8, 0), masonry, true)
            gate.Material = Enum.Material.SmoothPlastic
            for _, side in {-1, 1} do
                part("GatePost", Vector3.new(3, 24, 3.5), origin + Vector3.new(34 * side, 10, 0), accent, true)
                part("GateCapital", Vector3.new(5, 1.6, 5.4), origin + Vector3.new(34 * side, 22, 0), accent)
            end
            sign(gate, Config.Biomes[id].Name, white)
        end
        task.wait()
    end
    part("TrackBackstop", Vector3.new(74, 40, 9), Rules.LaunchOrigin + Rules.Direction * (Rules.MaxDistance + 5)
        + Vector3.new(0, 14, 0), charcoal)
end
return World
