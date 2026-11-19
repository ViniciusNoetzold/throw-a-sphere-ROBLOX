--!strict
-- Lightweight replaceable corridor art. Existing hub, sanctuaries and biome anchors stay intact.
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
    local charcoal = Color3.fromRGB(44, 56, 86)
    local cream = Color3.fromRGB(255, 247, 202)
    local yellow = Color3.fromRGB(255, 199, 52)
    local line = Rules.LinePosition
    local pad = part("YellowLaunchLine", Vector3.new(Rules.LineWidth, .4, Rules.LineDepth), line + Vector3.new(0, -1.75, 0), yellow)
    pad.TopSurface = Enum.SurfaceType.Smooth
    part("LaunchApron", Vector3.new(74, 1, 30), line + Vector3.new(0, -2.5, 12), charcoal)
    for _, side in {-1, 1} do
        part("StripeEdge", Vector3.new(Rules.LineWidth, .07, 1.1), pad.Position + Vector3.new(0, .22, side * (Rules.LineDepth / 2 - 1)), cream, true)
        part("ArchFoot", Vector3.new(6, 1, 7), line + Vector3.new(side * 33, -1.25, -6), charcoal)
        part("ArchTower", Vector3.new(4.5, 16, 4.5), line + Vector3.new(side * 33, 6, -6), Color3.fromRGB(252, 144, 64))
        part("ArchLight", Vector3.new(1.5, 11, .55), line + Vector3.new(side * 33, 6, -3.4), cream, true)
    end
    local arch = part("LaunchArch", Vector3.new(70, 3.3, 4.5), line + Vector3.new(0, 14.5, -6), charcoal)
    local sign = ctx.World.Label(arch, "PISTA DE ORBES", Vector3.new(0, .6, 2.5))
    local archLabel = sign.Parent :: BillboardGui
    archLabel.MaxDistance = 80
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
    for index, id in Layout.BiomeOrder do
        local palette = Layout.Biomes[id].Colors
        local origin = Rules.LaunchOrigin + Rules.Direction * ((index - 1) * Rules.ZoneLength)
        local colors = {
            Color3.fromRGB(118, 234, 142), Color3.fromRGB(95, 248, 215),
            Color3.fromRGB(255, 150, 64), Color3.fromRGB(159, 229, 255),
            Color3.fromRGB(255, 213, 108), Color3.fromRGB(194, 135, 255),
        }
        local accent = colors[index]
        local floorColor = palette[2]:Lerp(charcoal, .62)
        for segment = 0, 11 do
            local center = origin + Vector3.new(0, -2.5, -segment * 25 - 12.5)
            local tile = part("Runway_" .. id, Vector3.new(66, 1, 25), center, floorColor:Lerp(charcoal, (segment % 2) * .22))
            tile.TopSurface = Enum.SurfaceType.Smooth
            part("CenterDash", Vector3.new(.8, .05, 11), center + Vector3.new(0, .52, 0), accent, true)
        end
        for _, side in {-1, 1} do
            local wall = part("TunnelWall_" .. id, Vector3.new(3, 16, Rules.ZoneLength),
                origin + Vector3.new(side * 34, 5.5, -Rules.ZoneLength / 2), floorColor)
            wall.Material, wall.TopSurface = Enum.Material.SmoothPlastic, Enum.SurfaceType.Smooth
            part("WallInset", Vector3.new(.2, .55, Rules.ZoneLength),
                origin + Vector3.new(side * 32.45, 1.2, -Rules.ZoneLength / 2), accent, true)
            part("WallCap", Vector3.new(3.5, .6, Rules.ZoneLength),
                origin + Vector3.new(side * 34, 13.7, -Rules.ZoneLength / 2), accent)
            for segment = 1, 6 do
                part("WallPillar", Vector3.new(1.7, 15.8, 1.5),
                    origin + Vector3.new(side * 33, 5.55, -segment * Rules.ZoneLength / 6 + 1), charcoal)
            end
            for n = 1, 5 do
                local position = origin + Vector3.new(side * (40 + n % 2 * 3), 1, -n * 47)
                local base = part("SceneryBase", Vector3.new(11, 6, 15), position - Vector3.new(0, 3, 0), palette[2])
                base.CanCollide = false
                if index == 1 then
                    part("TreeTrunk", Vector3.new(2.4, 8, 2.4), position + Vector3.new(0, 3, 0), Color3.fromRGB(147, 95, 68), true).Material = Enum.Material.SmoothPlastic
                    local crown = part("TreeCrown", Vector3.new(11, 9, 11), position + Vector3.new(0, 9, 0), accent, true)
                    crown.Shape, crown.Material = Enum.PartType.Ball, Enum.Material.SmoothPlastic
                elseif index == 5 then
                    for step = 1, 3 do
                        local size = 11 - step * 2
                        part("RuinStep", Vector3.new(size, 2, size), position + Vector3.new(0, step * 2 - 1, 0), palette[1], true).Material = Enum.Material.Sandstone
                    end
                else
                    local shard = part("Crystal", Vector3.new(4, 9 + n % 3 * 3, 4), position + Vector3.new(0, 4, 0), accent, true)
                    shard.CFrame *= CFrame.Angles(math.rad(n * 11), math.rad(n * 32), side * .32)
                    part("CrystalGlow", Vector3.new(2, 6, 2), position + Vector3.new(side * 4, 2.8, -4), accent, true).Shape = Enum.PartType.Ball
                end
            end
        end
        if index > 1 then
            local gate = part("Gate_" .. id, Vector3.new(72, 2.6, 3), origin + Vector3.new(0, 13, -8), floorColor, true)
            gate.Material = Enum.Material.SmoothPlastic
            for _, side in {-1, 1} do
                part("GatePost", Vector3.new(3, 14, 3), origin + Vector3.new(34 * side, 5, -8), accent, true)
            end
            local caption = ctx.World.Label(gate, Config.Biomes[id].Name, Vector3.new(0, 1.2, 0))
            local gateLabel = caption.Parent :: BillboardGui
            gateLabel.MaxDistance = 95
        end
        task.wait()
    end
end
return World
