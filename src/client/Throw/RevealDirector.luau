--!strict
-- All effects are local and bounded. No reward decisions or external asset IDs live here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local Config = require(ReplicatedStorage.Shared.Config)
local Reveals = require(ReplicatedStorage.Shared.ConfigReveal)
local FlightRules = require(ReplicatedStorage.Shared.ConfigFlight)
local Numbers = require(ReplicatedStorage.Shared.NumberFormatter)
local CreatureArt = require(script.Parent.Parent:WaitForChild("CreatureArt"))
local OrbVisual = require(script.Parent:WaitForChild("OrbVisual"))
local Director = {}
type Actions = {Ready: () -> boolean, Submit: (string) -> ()}

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
local function preview(id: string, mutation: string?): Model
    local model = Instance.new("Model")
    local mesh = CreatureArt.Get(id, mutation)
    if mesh then
        mesh.CFrame = CFrame.new()
        mesh.Parent = model
        model.PrimaryPart = mesh
    end
    return model
end

function Director.Play(parent: ScreenGui, data: any, alive: () -> boolean, actions: Actions?)
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
    viewport.Name, viewport.Size, viewport.Position = "CreatureReveal", UDim2.fromScale(.74,.53), UDim2.fromScale(.13,.12)
    viewport.BackgroundTransparency, viewport.ZIndex, viewport.Parent = 1, 7, overlay
    viewport.Ambient, viewport.LightColor, viewport.LightDirection = Color3.new(0.5,0.5,0.5), Color3.new(1,1,1), Vector3.new(-1,-1,-1)
    local world = Instance.new("WorldModel")
    world.Parent = viewport
    local camera = Instance.new("Camera")
    camera.FieldOfView, camera.Parent, viewport.CurrentCamera = 35, viewport, camera
    local creature = preview(data.CreatureId, data.MutationName)
    for _, size in Config.Sizes do
        if size.Name == data.SizeName and creature.PrimaryPart then
            creature:ScaleTo(CreatureArt.Size(data.CreatureId, data.SizeName, size.Scale, data.MutationName))
            break
        end
    end
    creature.Parent = world
    local colors: {[BasePart]: Color3} = {}
    local transparencies: {[BasePart]: number} = {}
    for _, p in creature:GetDescendants() do if p:IsA("BasePart") then colors[p] = p.Color;transparencies[p]=p.Transparency;p.Color = Color3.new();p.Transparency=1 end end
    local bounds, size = CFrame.new(), Vector3.one * 2.1
    if creature.PrimaryPart then bounds, size = creature:GetBoundingBox() end
    local target = bounds.Position
    local originalScale = creature:GetScale()
    local radius = math.max(size.X,size.Y,size.Z) * 2.2
    local captureOrb = OrbVisual.Create(data.OrbColor or tier.Color, math.clamp(size.Magnitude * .45, 1.65, 2.5), data.OrbId)
    captureOrb.Parent = world
    local crown = captureOrb:FindFirstChild("Crown") :: BasePart?
    local prism = captureOrb:FindFirstChild("Prism") :: BasePart?
    local crownOffset = if crown then captureOrb:GetPivot():ToObjectSpace(crown.CFrame) else CFrame.identity
    local prismColor = if prism then prism.Color else tier.Color
    local intro = FlightRules.CaptureIntroSeconds
    local absorptionEnd = .95
    local function poseOrb(frame: CFrame, gap: number)
        captureOrb:PivotTo(frame)
        if crown then crown.CFrame = frame * crownOffset * CFrame.new(0, gap, 0) * CFrame.Angles(gap * .25, 0, 0) end
    end
    local burst: {Frame} = {}
    for i = 1, (if reduced then 0 else 5 + tier.Rank * 4) do
        local piece = Instance.new("Frame")
        piece.AnchorPoint = Vector2.new(.5, .5)
        piece.Position = UDim2.fromScale(.5, .46)
        piece.Size = UDim2.fromOffset(6 + (i % 4) * 2, 6 + (i % 4) * 2)
        piece.Rotation = 45
        piece.BorderSizePixel = 0
        piece.BackgroundColor3 = tier.Color:Lerp(Color3.new(1, 1, 1), (i % 3) * .22)
        piece.Visible = false
        piece.ZIndex = 7
        piece.Parent = overlay
        table.insert(burst, piece)
    end
    local pulse = Instance.new("Frame")
    pulse.AnchorPoint = Vector2.new(.5, .5)
    pulse.Position = UDim2.fromScale(.5, .46)
    pulse.BackgroundTransparency = 1
    pulse.ZIndex = 6
    pulse.Parent = overlay
    local pulseCorner = Instance.new("UICorner")
    pulseCorner.CornerRadius, pulseCorner.Parent = UDim.new(1, 0), pulse
    local pulseEdge = Instance.new("UIStroke")
    pulseEdge.Color, pulseEdge.Thickness, pulseEdge.Transparency, pulseEdge.Parent = tier.Color, 4, 1, pulse
    local rays: {Frame} = {}
    for index = 1, (if reduced then 6 else tier.Rays) do
        local ray = Instance.new("Frame")
        ray.AnchorPoint, ray.Position, ray.Size = Vector2.new(0.5,0.5), UDim2.fromScale(0.5,0.46), UDim2.new(0,3 + tier.Rank,0.38,0)
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
    local name = label(overlay,"? ? ?",.61,36,34,Color3.new(1,1,1))
    local detail = label(overlay,"",.71,24,18,tier.Color)
    local bundle = data.Bundle or {data}
    local captures = 0
    for _, item in bundle do if item.Captured then captures += 1 end end
    local start = os.clock()
    local revealed = false
    local revealedFullSize = false
    local lastShake = 0
    local passed = data.ShakesPassed or 0
    local attempted = math.min(3, passed + (if data.Captured then 0 else 1))
    local sounds: {Sound} = {}
    local function sound(asset: string, volume: number, pitch: number)
        local item = Instance.new("Sound")
        item.SoundId, item.Volume, item.PlaybackSpeed, item.Parent = asset, volume, pitch, SoundService
        table.insert(sounds, item); item:Play()
    end
    local ok, errorMessage = pcall(function()
        while alive() and os.clock() - start < intro + tier.Duration do
            local elapsed = os.clock() - start
            local revealAt = intro + tier.Suspense
            local after = math.max(0,elapsed-revealAt)
            local opened = elapsed >= revealAt
            if elapsed < absorptionEnd then
                local phase = math.clamp((elapsed - .18) / (absorptionEnd - .18), 0, 1)
                local suction = phase ^ 1.7
                local opening = if reduced then 0 else math.sin(phase * math.pi) * .55
                local drop = if reduced then 0 else 1.1 * math.max(0, 1 - elapsed / .26) ^ 2
                poseOrb(CFrame.new(target + Vector3.new(0, drop, 0)) * CFrame.Angles(0, -.23, 0), opening)
                if prism then prism.Color = prismColor:Lerp(Color3.new(1, 1, 1), (1 - suction) * phase) end
                if creature.PrimaryPart then
                    for part, value in transparencies do
                        part.Transparency = if elapsed < .18 then 1 else math.max(value, suction)
                    end
                    creature:ScaleTo(originalScale * math.max(.06, 1 - suction))
                    creature:PivotTo(CFrame.new(-.45 * (1 - suction), 1.05 * (1 - suction), .2))
                end
                title.Text = if elapsed < .18 then "A ORBE POUSOU" else "A ORBE ABSORVE A ENERGIA"
                pulse.Size = UDim2.fromOffset(65 + (1 - suction) * 170, 65 + (1 - suction) * 170)
                pulseEdge.Transparency = if phase == 0 then 1 else .25 + suction * .55
                for index, piece in burst do
                    local angle = index * 2.399963 + phase * 2
                    local radius = (1 - suction) * (.15 + index % 4 * .032)
                    piece.Position = UDim2.fromScale(.5 + math.cos(angle) * radius, .43 + math.sin(angle) * radius)
                    piece.Visible, piece.BackgroundTransparency = phase > 0, .14 + suction * .72
                end
            elseif elapsed < intro then
                for part in transparencies do part.Transparency = 1 end
                for _, piece in burst do piece.Visible = false end
                local beat = elapsed - absorptionEnd
                local shake = math.min(attempted, math.floor(beat / .66) + 1)
                local phase = math.clamp((beat - (shake - 1) * .66) / .66, 0, 1)
                local successful = shake <= passed
                if shake ~= lastShake then
                    lastShake = shake
                    sound("rbxasset://sounds/volume_slider.ogg", .18, if successful then .8 + shake * .18 else .58)
                end
                title.Text = "BALANÇADA " .. shake .. " / 3"
                detail.Text = if successful then "A ORBE RESISTIU" else "A CRIATURA ESTÁ SE SOLTANDO"
                local pulseColor = if successful then Color3.fromRGB(150, 255, 197) else Color3.fromRGB(255, 128, 142)
                local lift = if reduced then 0 else math.sin(phase * math.pi) * (if successful then .25 + shake * .16 else .5)
                local swing = if reduced then 0 else math.sin(phase * math.pi * 3) * (if successful then .25 + shake * .12 else .64) * (1 - phase)
                poseOrb(CFrame.new(target + Vector3.new(swing * .52, lift, 0)) * CFrame.Angles(swing * .33, -.23 + swing * .29, swing), 0)
                if prism then prism.Color = prismColor:Lerp(pulseColor, if phase < .34 then 1 - phase else .19) end
                pulseEdge.Color = pulseColor
                pulse.Size = UDim2.fromOffset(70 + phase * 155, 70 + phase * 155)
                pulseEdge.Transparency = .54 + .46 * phase
            elseif not opened then
                if captureOrb.Parent then captureOrb.Parent = nil end
                if not revealedFullSize then
                    revealedFullSize = true
                    if creature.PrimaryPart then creature:ScaleTo(originalScale) end
                    for part, value in transparencies do part.Transparency = value end
                end
                title.Text = if tier.Rank >= 5 then "UMA PRESENÇA EXTRAORDINÁRIA..." else "QUEM ESTÁ AÍ?"
                detail.Text = "REVELANDO O ENCONTRO"
            elseif not revealed then
                revealed = true
                sound("rbxasset://sounds/volume_slider.ogg",0.18,1.3+tier.Rank*0.1)
                if tier.Rank >= 4 then sound("rbxasset://sounds/impact_explosion_03.mp3",0.12,1.1) end
                for p,color in colors do p.Color = color end
                pulseEdge.Color = tier.Color:Lerp(Color3.new(1, 1, 1), .4)
                title.Text = string.upper(data.Rarity or "Comum") .. (if data.Captured then "!" else " • ENCONTRADA")
                name.Text = data.CreatureName or data.CreatureId
                local mutation = if data.MutationName == "ArcoIris" then "Shiny" else data.MutationName or "Normal"
                local sizeName = if data.SizeName == "Titanica" then "Titânica" else data.SizeName or "Normal"
                local variant = mutation .. " • " .. sizeName
                detail.Text = if data.Captured then variant .. " • $" .. Numbers.Format(data.IncomePerSec or 0) .. "/s"
                    else variant .. " • ESCAPOU • +" .. Numbers.Format(data.XPGained or 0) .. " XP"
                if #bundle > 1 then detail.Text ..= "   |   " .. captures .. "/" .. #bundle .. " capturas" end
                local stats = if data.Distance then Numbers.Format(data.Distance) .. " STUDS" else ""
                local chance = data.SpawnChance
                if type(chance) == "number" and chance > 0 and chance < 1 then
                    stats ..= (if stats == "" then "" else "   •   ") .. "VARIANTE 1 EM " .. Numbers.Format(math.ceil(1 / chance), 2)
                end
                label(overlay, stats, .78, 21, 14, tier.Color)
                if data.RareBoost then
                    title.Position, title.Size = UDim2.new(.03, 0, 0, 8), UDim2.new(.94, 0, 0, 35)
                    local bonus = label(overlay, "CHANCE DE RAROS ×" .. Numbers.Format(data.RareBoost, 2), 0, 18, 14, tier.Color)
                    bonus.Position = UDim2.new(.03, 0, 0, 44)
                    if data.NextBiome and data.NextMilestone then
                        local gate = data.NextMilestone
                        local nextBiome = label(overlay, Config.Biomes[data.NextBiome].Name .. "  ·  Desbloqueia no Nv. " .. gate.Level,
                            0, 18, 13, Color3.fromRGB(211, 222, 255))
                        nextBiome.Position = UDim2.new(.03, 0, 0, 63)
                    end
                end
            end
            local anticipation = if opened and not reduced then math.max(0, 1 - after * 3) else 0
            if opened then
                local sweep = math.clamp(after * 1.8, 0, 1)
                pulse.Size = UDim2.fromOffset(90 + sweep * (190 + tier.Rank * 42), 90 + sweep * (190 + tier.Rank * 42))
                pulseEdge.Transparency = if reduced then 1 else .32 + sweep * .68
                for index, piece in burst do
                    local rate = math.clamp(after * (1 + index % 5 * .13), 0, 1)
                    local angle = index * 2.399963
                    local distance = rate * (.18 + tier.Rank * .023 + index % 4 * .04)
                    piece.Position = UDim2.fromScale(.5 + math.cos(angle) * distance, .46 + math.sin(angle) * distance - rate * .07)
                    piece.Rotation = 45 + after * ((index % 3) - 1) * 120
                    piece.Visible = rate < 1
                    piece.BackgroundTransparency = .12 + rate * .88
                end
            end
            local rotation = if reduced then 0.15 else (if opened then math.min(after*0.6,1.8) else math.sin(elapsed*3)*0.15)
            local zoom = if opened then 1 - .18 * anticipation elseif elapsed >= intro then 1.24 else 1.06
            local height = if opened then .17 else .24
            camera.CFrame = CFrame.lookAt(target + Vector3.new(math.sin(rotation)*radius*zoom, radius*height, -math.cos(rotation)*radius*zoom),target)
            local lift = if reduced or not opened then 0 else math.sin(after * 3.1) * .10 + anticipation * .28
            local yaw = if reduced then 0 else math.sin(after * 2) * .13
            if elapsed >= absorptionEnd then creature:PivotTo(CFrame.new(0, lift, 0) * CFrame.Angles(0, yaw, 0)) end
            bloom.Intensity = math.min(1.5,0.3+tier.Rank*0.1+anticipation*0.5)
            overlay.BackgroundColor3 = if tier.Rank == 7 then Color3.fromHSV((elapsed*0.04)%1,0.5,0.055) else Color3.fromRGB(4,6,20)
            for index, ray in rays do
                local angle = index * math.pi * 2 / #rays + (if reduced then 0 else elapsed * (.08 + tier.Rank * .015))
                local radius = math.min(overlay.AbsoluteSize.X, overlay.AbsoluteSize.Y) * (0.17 + anticipation * .025)
                ray.Position = UDim2.new(.5, math.cos(angle) * radius, .46, math.sin(angle) * radius)
                ray.Rotation = math.deg(angle) + 90
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
    captureOrb:Destroy()
    for _, item in sounds do item:Destroy() end
    bloom:Destroy(); blur:Destroy(); grade:Destroy()
    if ok and actions and alive() then
        for _, item in burst do item:Destroy() end
        pulse:Destroy()
        local bar = Instance.new("Frame")
        bar.Name, bar.AnchorPoint, bar.Position = "ThrowOptions", Vector2.new(.5, 1), UDim2.new(.5, 0, 1, -10)
        bar.Size, bar.BackgroundTransparency, bar.Parent = UDim2.new(.94, 0, 0, 44), 1, overlay
        local limit = Instance.new("UISizeConstraint")
        limit.MaxSize, limit.Parent = Vector2.new(460, 44), bar
        local buttons: {TextButton} = {}
        local options = {
            {Id = "Retry", Caption = "JOGAR DE NOVO", Color = Color3.fromRGB(93, 231, 138)},
            {Id = "Base", Caption = "VOLTAR À BASE", Color = Color3.fromRGB(134, 196, 255)},
        }
        for index, option in options do
            local button = Instance.new("TextButton")
            button.Name, button.Text, button.Font = "Choose" .. option.Id, option.Caption, Enum.Font.GothamBlack
            button.Position, button.Size = UDim2.fromScale((index - 1) * .52, 0), UDim2.fromScale(.48, 1)
            button.BackgroundColor3, button.TextColor3 = option.Color, Color3.fromRGB(17, 29, 43)
            button.TextSize, button.ZIndex, button.Parent = 14, 9, bar
            local rounded = Instance.new("UICorner")
            rounded.CornerRadius, rounded.Parent = UDim.new(0, 10), button
            button.Activated:Connect(function() if actions.Ready() then actions.Submit(option.Id) end end)
            table.insert(buttons, button)
        end
        local wasEnabled = false
        while alive() do
            local enabled = actions.Ready()
            for _, button in buttons do
                button.Active, button.Selectable, button.AutoButtonColor = enabled, enabled, enabled
                button.BackgroundTransparency = if enabled then 0 else .35
            end
            if enabled and not wasEnabled and UserInputService:GetLastInputType().Name:match("^Gamepad") then
                GuiService.SelectedObject = buttons[1]
            end
            wasEnabled = enabled
            task.wait(.1)
        end
    end
    overlay:Destroy()
    if not ok then warn("[RevealDirector]", errorMessage) end
end
return Director
