--!strict
-- Cosmetic layer for functional placeholder creatures. No imported model/animation IDs.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Events = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigEvents"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local tracked: {[Model]: {Peak: Part?, Beam: Beam?, Glow: Highlight?, Sparkles: Sparkles?}} = {}
local state: any = nil
local correction = Instance.new("ColorCorrectionEffect")
correction.Name, correction.Parent = "ThrowASphereWeather", Lighting
local function observe(model: Instance)
    if not model:IsA("Model") or tracked[model] then return end
    local id = model:GetAttribute("CreatureId")
    local definition = id and Config.Creatures[id]
    if not definition then return end
    local root = model.PrimaryPart
    if not root then return end
    local item: any = {}
    local rarity = definition.Rarity
    if rarity == "Epica" then
        local sparkles = Instance.new("Sparkles")
        sparkles.Name, sparkles.SparkleColor, sparkles.Parent = "RaritySparkles", definition.BodyColor, root
        item.Sparkles = sparkles
    elseif rarity == "Mitica" or rarity == "Lendaria" or rarity == "Secreta" then
        local glow = Instance.new("Highlight")
        glow.Name, glow.Adornee = "RarityHighlight", model
        glow.FillTransparency, glow.OutlineTransparency, glow.OutlineColor = 0.9, 0.1, definition.BodyColor
        glow.Parent, item.Glow = model, glow
    end
    if rarity == "Lendaria" or rarity == "Secreta" then
        local peak = Instance.new("Part")
        peak.Name, peak.Anchored, peak.Transparency = "RarityPillarTip", true, 1
        peak.CanCollide, peak.CanTouch, peak.CanQuery, peak.Size = false, false, false, Vector3.new(0.1,0.1,0.1)
        peak.Position, peak.Parent = root.Position + Vector3.new(0, 42, 0), Workspace
        local lower, upper = Instance.new("Attachment"), Instance.new("Attachment")
        lower.Parent, upper.Parent = root, peak
        local beam = Instance.new("Beam")
        beam.Name, beam.Attachment0, beam.Attachment1 = "RarityPillar", lower, upper
        beam.Width0, beam.Width1, beam.FaceCamera, beam.LightEmission = 1.3, 0.2, true, 1
        beam.Color, beam.Transparency, beam.Parent = ColorSequence.new(definition.BodyColor), NumberSequence.new(0.45), root
        item.Peak, item.Beam = peak, beam
    end
    tracked[model] = item
end
local function observeWildFolder(folder: Instance)
    folder.ChildAdded:Connect(observe)
    for _, model in folder:GetChildren() do observe(model) end
end
local wildFolder = Workspace:FindFirstChild("CriaturasSelvagens")
if wildFolder then
    observeWildFolder(wildFolder)
else
    local connection: RBXScriptConnection
    connection = Workspace.ChildAdded:Connect(function(child)
        if child.Name ~= "CriaturasSelvagens" then return end
        connection:Disconnect()
        observeWildFolder(child)
    end)
end
local function setState(value: any)
    if typeof(value) ~= "table" then return end
    state = value
    local event = Events.Definitions[value.EventId]
    correction.TintColor = if event then event.Color:Lerp(Color3.new(1,1,1), 0.82) else Color3.new(1,1,1)
end
local worldUpdate = remotes:FindFirstChild("WorldStateUpdate")
if worldUpdate then (worldUpdate :: RemoteEvent).OnClientEvent:Connect(setState) end
(remotes:WaitForChild("StateUpdate") :: RemoteEvent).OnClientEvent:Connect(function(snapshot: any) if typeof(snapshot) == "table" and snapshot.Weather then setState(snapshot.Weather) end end)
local request = remotes:FindFirstChild("RequestWorldState")
if request then (request :: RemoteEvent):FireServer() end
task.spawn(function()
    while player.Parent do
        task.wait(0.2)
        local hue = (Workspace:GetServerTimeNow() * 0.12) % 1
        for model, item in tracked do
            if not model.Parent then if item.Peak then item.Peak:Destroy() end; tracked[model] = nil; continue end
            local root = model.PrimaryPart
            if item.Peak and root then item.Peak.Position = root.Position + Vector3.new(0, 42, 0) end
            if item.Beam and root then item.Beam.Enabled = root.LocalTransparencyModifier < 1 end
            if item.Glow and root then item.Glow.Enabled = root.LocalTransparencyModifier < 1 end
            if item.Sparkles and root then item.Sparkles.Enabled = root.LocalTransparencyModifier < 1 end
            if model:GetAttribute("Mutation") == "ArcoIris" then
                local color = Color3.fromHSV(hue, 0.8, 1)
                for _, descendant in model:GetDescendants() do if descendant:IsA("BasePart") and descendant.Name ~= "Eye" then descendant.Color = color end end
                if item.Glow then item.Glow.OutlineColor = color end
            end
        end
        -- Timers come from server timestamps; the client only renders their remaining time.
        if state then player:SetAttribute("EventSecondsRemaining", math.max(0, (state.EndsAt or 0) - Workspace:GetServerTimeNow())) end
    end
end)
