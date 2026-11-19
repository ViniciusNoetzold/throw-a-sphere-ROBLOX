--!strict
-- All effects are local and bounded. No reward decisions or external asset IDs live here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Config = require(ReplicatedStorage.Shared.Config)
local Reveals = require(ReplicatedStorage.Shared.ConfigReveal)
local Numbers = require(ReplicatedStorage.Shared.NumberFormatter)
local Director = {}

local function label(parent: Instance, text: string, y: number, height: number, size: number, color: Color3): TextLabel
    local item = Instance.new("TextLabel")
    item.Size, item.Position = UDim2.new(0.94, 0, 0, height), UDim2.fromScale(0.03, y)
    item.BackgroundTransparency, item.Text, item.TextScaled = 1, text, true
    item.Font, item.TextColor3, item.TextStrokeTransparency = Enum.Font.GothamBlack, color, 0.25
    local constraint = Instance.new("UITextSizeConstraint")
    constraint.MaxTextSize, constraint.MinTextSize, constraint.Parent = size, 10, item
    item.ZIndex, item.Parent = 8, parent
    return item
end
local function preview(id: string): Model
    local definition = Config.Creatures[id]
    local collection = ReplicatedStorage:FindFirstChild("CreatureModels")
    local existing = collection and collection:FindFirstChild(id)
    if existing and existing:IsA("Model") then
        local clone = existing:Clone()
        for _, p in clone:GetDescendants() do
            if p:IsA("LuaSourceContainer") then p:Destroy()
            elseif p:IsA("BasePart") then p.Anchored, p.CanCollide = true, false end
        end
        clone:PivotTo(CFrame.new())
        return clone
    end
    -- Original blockout, automatically replaced by an imported CreatureModels/<id> model.
    local model = Instance.new("Model")
    local function part(name: string, size: Vector3, position: Vector3, color: Color3): Part
        local p = Instance.new("Part")
        p.Name, p.Size, p.Position, p.Color = name, size, position, color
        p.Anchored, p.CanCollide, p.TopSurface, p.Parent = true, false, Enum.SurfaceType.Studs, model
        return p
    end
    model.PrimaryPart = part("Body", Vector3.new(3,2,2.5), Vector3.zero, definition.BodyColor)
    part("Head", Vector3.new(2,1.7,2), Vector3.new(0,1.8,-0.7), definition.BodyColor:Lerp(Color3.new(1,1,1),0.2))
    for _, side in {-1,1} do
        part("Eye", Vector3.new(0.2,0.3,0.1), Vector3.new(side*0.5,2,-1.75), Color3.fromRGB(20,25,40))
        part("Foot", Vector3.new(0.8,0.7,1.1), Vector3.new(side*1.1,-1.2,-0.6), definition.BodyColor)
        part("Ear", Vector3.new(0.6,1,0.7), Vector3.new(side*0.7,3,-0.5), definition.BodyColor)
    end
    return model
end
function Director.Play(parent: ScreenGui, data: any, alive: () -> boolean)
    local tier = Reveals[data.Rarity] or Reveals.Comum
    local reduced = parent:GetAttribute("ReducedMotion") == true
    local overlay = Instance.new("Frame")
    overlay.Name, overlay.Size, overlay.BackgroundColor3 = "RarityReveal", UDim2.fromScale(1,1), Color3.fromRGB(4,6,20)
    overlay.BackgroundTransparency, overlay.Active, overlay.ZIndex, overlay.Parent = 0.1, true, 4, parent
    if data.Preview then label(overlay,"PRÉVIA VISUAL • SEM RECOMPENSA",0,20,12,Color3.new(1,1,1)) end
    local bloom, blur, grade = Instance.new("BloomEffect"), Instance.new("BlurEffect"), Instance.new("ColorCorrectionEffect")
    bloom.Name, blur.Name, grade.Name = "DropRevealBloom", "DropRevealBlur", "DropRevealGrade"
    bloom.Intensity, bloom.Size, bloom.Threshold = 0.4, 30, 1
    blur.Size = if reduced then 0 else 7
    grade.TintColor = tier.Color:Lerp(Color3.new(1,1,1), 0.85)
    bloom.Parent, blur.Parent, grade.Parent = Lighting, Lighting, Lighting
    local viewport = Instance.new("ViewportFrame")
    viewport.Name, viewport.Size, viewport.Position = "CreatureReveal", UDim2.fromScale(0.74,0.64), UDim2.fromScale(0.13,0.15)
    viewport.BackgroundTransparency, viewport.ZIndex, viewport.Parent = 1, 7, overlay
    viewport.Ambient, viewport.LightColor, viewport.LightDirection = Color3.new(0.5,0.5,0.5), Color3.new(1,1,1), Vector3.new(-1,-1,-1)
    local world = Instance.new("WorldModel")
    world.Parent = viewport
    local camera = Instance.new("Camera")
    camera.FieldOfView, camera.Parent, viewport.CurrentCamera = 35, viewport, camera
    local creature = preview(data.CreatureId)
    creature.Parent = world
    local colors: {[BasePart]: Color3} = {}
    local transparencies: {[BasePart]: number} = {}
    for _, p in creature:GetDescendants() do if p:IsA("BasePart") then colors[p] = p.Color;transparencies[p]=p.Transparency;p.Color = Color3.new();p.Transparency=1 end end
    local bounds, size = creature:GetBoundingBox()
    local target = bounds.Position
    local radius = math.max(size.X,size.Y,size.Z) * 2.2
    local captureOrb=Instance.new("Part")
    captureOrb.Shape,captureOrb.Size,captureOrb.Anchored=Enum.PartType.Ball,Vector3.new(2,2,2),true
    captureOrb.Color,captureOrb.Material,captureOrb.Parent=data.OrbColor or tier.Color,Enum.Material.Neon,world
    local rays: {Frame} = {}
    for index = 1, (if reduced then 6 else tier.Rays) do
        local ray = Instance.new("Frame")
        ray.AnchorPoint, ray.Position, ray.Size = Vector2.new(0.5,0), UDim2.fromScale(0.5,0.5), UDim2.new(0,3 + tier.Rank,0.8,0)
        ray.Rotation, ray.BackgroundColor3, ray.BackgroundTransparency = index * 360 / tier.Rays, tier.Color, 0.8
        ray.BorderSizePixel, ray.ZIndex, ray.Parent = 0, 5, overlay
        local fade = Instance.new("UIGradient")
        fade.Rotation, fade.Transparency, fade.Parent = 90, NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.4,0.3),NumberSequenceKeypoint.new(1,1)}), ray
        table.insert(rays,ray)
    end
    local rings: {Frame} = {}
    for index = 1, tier.Rings do
        local ring = Instance.new("Frame")
        ring.AnchorPoint, ring.Position = Vector2.new(0.5,0.5), UDim2.fromScale(0.5,0.48)
        ring.Size, ring.BackgroundTransparency, ring.ZIndex, ring.Parent = UDim2.fromOffset(110+index*44,110+index*44), 1, 6, overlay
        local round, stroke = Instance.new("UICorner"), Instance.new("UIStroke")
        round.CornerRadius, round.Parent = UDim.new(1,0), ring
        stroke.Thickness, stroke.Color, stroke.Transparency, stroke.Parent = if index%2==0 then 1 else 3, tier.Color, 0.35, ring
        table.insert(rings,ring)
    end
    local title = label(overlay, "CONEXÃO COM A ORBE",0.06,50,40,tier.Color)
    local name = label(overlay,"? ? ?",0.73,60,52,Color3.new(1,1,1))
    local detail = label(overlay,"Três balançadas. Um encontro.",0.84,35,20,tier.Color)
    local bundle = data.Bundle or {data}
    local captures = 0
    for _, item in bundle do if item.Captured then captures += 1 end end
    local start = os.clock()
    local revealed = false
    local lastShake = 0
    local sounds: {Sound} = {}
    local function sound(asset: string, volume: number, pitch: number)
        local item = Instance.new("Sound")
        item.SoundId, item.Volume, item.PlaybackSpeed, item.Parent = asset, volume, pitch, SoundService
        table.insert(sounds, item); item:Play()
    end
    local ok, errorMessage = pcall(function()
        while alive() and os.clock() - start < 2.1 + tier.Duration do
            local elapsed = os.clock() - start
            local revealAt = 2.1 + tier.Suspense
            local after = math.max(0,elapsed-revealAt)
            local opened = elapsed >= revealAt
            if elapsed < 2.1 then
                local shake = math.min(3,math.floor(elapsed / 0.7)+1)
                if shake ~= lastShake then lastShake = shake; sound("rbxasset://sounds/volume_slider.ogg",0.12,0.8+shake*0.15) end
                title.Text = "BALANÇADA " .. shake .. " / 3"
                detail.Text = if shake <= (data.ShakesPassed or 0) then "ENERGIA ESTABILIZADA" else "SINAL INSTÁVEL..."
                captureOrb.CFrame=CFrame.new(target)*CFrame.Angles(0,0,if reduced then 0 else math.sin(elapsed/0.7*math.pi*2)*0.38)
            elseif not opened then
                captureOrb.Transparency=1
                for part,value in transparencies do part.Transparency=value end
                title.Text = if tier.Rank >= 5 then "UMA PRESENÇA EXTRAORDINÁRIA..." else "QUEM ESTÁ AÍ?"
                detail.Text = "REVELANDO O ENCONTRO"
            elseif not revealed then
                revealed = true
                sound("rbxasset://sounds/volume_slider.ogg",0.18,1.3+tier.Rank*0.1)
                if tier.Rank >= 4 then sound("rbxasset://sounds/impact_explosion_03.mp3",0.12,1.1) end
                for p,color in colors do p.Color = color end
                title.Text = string.upper(data.Rarity or "Comum") .. (if data.Captured then "!" else " • ENCONTRADA")
                name.Text = data.CreatureName or data.CreatureId
                detail.Text = if data.Captured then tostring(data.MutationName) .. " • " .. tostring(data.SizeName) .. " • $" .. Numbers.Format(data.IncomePerSec or 0) .. "/s"
                    else "ESCAPOU • +" .. Numbers.Format(data.XPGained or 0) .. " XP de consolação"
                if #bundle > 1 then detail.Text ..= "   |   " .. captures .. "/" .. #bundle .. " capturas" end
                local chance = data.SpawnChance or 1
                label(overlay,"ENCONTRO: 1 EM " .. Numbers.Format(math.max(1,math.floor(1/math.max(chance,1e-12)))),0.92,25,16,tier.Color)
            end
            local anticipation = if opened then math.max(0,1-after*3) else 0
            local rotation = if reduced then 0.15 else (if opened then math.min(after*0.6,1.8) else math.sin(elapsed*3)*0.15)
            local zoom = if opened then 1-0.18*anticipation else 1.15
            camera.CFrame = CFrame.lookAt(target + Vector3.new(math.sin(rotation)*radius*zoom, radius*0.17, -math.cos(rotation)*radius*zoom),target)
            creature:PivotTo(CFrame.new(0,if reduced then 0 else math.sin(elapsed*2)*0.1,0))
            bloom.Intensity = math.min(1.5,0.3+tier.Rank*0.1+anticipation*0.5)
            overlay.BackgroundColor3 = if tier.Rank == 7 then Color3.fromHSV((elapsed*0.04)%1,0.5,0.055) else Color3.fromRGB(4,6,20)
            for index, ray in rays do
                ray.Rotation = index*360/#rays + (if reduced then 0 else elapsed*(5+tier.Rank))
                ray.BackgroundTransparency = if opened then 0.76+math.sin(elapsed*2+index)*0.08 else 0.92
            end
            for index, ring in rings do
                ring.Rotation = (if index%2==0 then -1 else 1)*elapsed*(4+tier.Rank)
                local diameter = (110+index*44)*(1+anticipation*0.3)
                ring.Size = UDim2.fromOffset(diameter,diameter)
            end
            RunService.RenderStepped:Wait()
        end
    end)
    for _, item in sounds do item:Destroy() end
    bloom:Destroy(); blur:Destroy(); grade:Destroy(); overlay:Destroy()
    if not ok then warn("[RevealDirector]", errorMessage) end
end
return Director
