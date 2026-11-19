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
        if neon then p.Material = Enum.Material.Neon; p.CanCollide = false end
        p.Parent = folder
        return p
    end
    part("LaunchApron",Vector3.new(48,1,25),Rules.LinePosition+Vector3.new(0,-2.5,9),Color3.fromRGB(45,56,70))
    local pad = part("YellowLaunchLine",Vector3.new(44,0.3,2),Rules.LinePosition+Vector3.new(0,-1.7,0),Color3.fromRGB(255,215,35),true)
    ctx.World.Label(pad,"LINHA DE LANÇAMENTO\nPare a barra no centro verde",Vector3.new(0,6,0))
    local barrier=part("PlayerBarrier",Vector3.new(54,80,3),Rules.LaunchOrigin+Vector3.new(0,36,-2),Color3.new(1,1,1))
    barrier.Transparency,barrier.CanQuery=1,false
    -- Physical barrier plus server correction: the track is reserved for the orb.
    if not ctx.DisableLoops then task.spawn(function()
        while folder.Parent do
            task.wait(0.15)
            for _, player in Players:GetPlayers() do
                local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root and root:IsA("BasePart") then
                    local p=root.Position
                    if math.abs(p.X)<30 and p.Z<Rules.LaunchOrigin.Z-1 and p.Z>Rules.LaunchOrigin.Z-Rules.MaxDistance-30 then
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
        for segment = 0, 11 do
            for side = -1, 1, 2 do
                local position = origin + Vector3.new(side * 12, -2.5, -segment * 25 - 12.5)
                part("Runway_" .. id, Vector3.new(24, 1, 25), position, palette[(segment + (if side == 1 then 1 else 0)) % 2 + 1])
            end
        end
        for _, side in {-1, 1} do
            part("Wall_" .. id, Vector3.new(4, 10, 300), origin + Vector3.new(side * 27, 2, -150), palette[2])
            part("Rail_" .. id, Vector3.new(1, 0.5, 300), origin + Vector3.new(side * 27, 7.5, -150), palette[1]:Lerp(Color3.new(1,1,1), 0.5), true)
            for n = 1, 5 do
                local pillar = part("Landmark_" .. id, Vector3.new(5, 8 + index * 2, 5), origin + Vector3.new(side * 34, 3 + index, -n * 50), palette[1], index > 1)
                if index == 1 then part("TreeCrown", Vector3.new(13, 10, 13), pillar.Position + Vector3.new(0, 8, 0), Color3.fromRGB(60,175,55))
                else pillar.CFrame *= CFrame.Angles(0, 0, side * 0.2) end
            end
        end
        local banner = part("Gate_" .. id, Vector3.new(52, 2, 2), origin + Vector3.new(0, 16, -3), palette[1], true)
        ctx.World.Label(banner, Config.Biomes[id].Name .. "\n" .. ((index - 1) * 300) .. " STUDS", Vector3.new(0, 3, 0))
        local gateLabel=banner:FindFirstChild("Label")
        if gateLabel and gateLabel:IsA("BillboardGui") then gateLabel.MaxDistance=140 end
        task.wait()
    end
end
return World
