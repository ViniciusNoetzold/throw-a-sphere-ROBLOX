--!strict
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CreatureArt = require(script.Parent:WaitForChild("CreatureArt"))

type Walker = {
    Home: Vector3,
    Phase: number,
    Caption: TextLabel,
    Left: BasePart?,
    Right: BasePart?,
}
local walkers: {[Model]: Walker} = {}

local function observe(instance: Instance)
    if not instance:IsA("Model") then return end
    local home, phase = instance:GetAttribute("PenHome"), instance:GetAttribute("WalkPhase")
    local head = instance:FindFirstChild("Head")
    local board = head and head:FindFirstChild("Label")
    local caption = board and board:FindFirstChildWhichIsA("TextLabel")
    if typeof(home) ~= "Vector3" or typeof(phase) ~= "number" or not caption or not instance.PrimaryPart then return end
    local left, right = instance:FindFirstChild("LeftFoot"), instance:FindFirstChild("RightFoot")
    CreatureArt.ShowOn(instance, instance.Name, 1, 1)
    walkers[instance] = {
        Home = home,
        Phase = phase,
        Caption = caption,
        Left = if left and left:IsA("BasePart") then left else nil,
        Right = if right and right:IsA("BasePart") then right else nil,
    }
end

for _, model in CollectionService:GetTagged("SanctuaryWalker") do observe(model) end
CollectionService:GetInstanceAddedSignal("SanctuaryWalker"):Connect(function(model) task.defer(observe, model) end)
CollectionService:GetInstanceRemovedSignal("SanctuaryWalker"):Connect(function(model)
    if model:IsA("Model") then walkers[model] = nil end
end)

CreatureArt.Loaded:Connect(function(id: string)
    for model in walkers do
        if model.Name == id then CreatureArt.ShowOn(model, id, 1, 1) end
    end
end)

task.spawn(function()
    while script.Parent do
        task.wait(.6)
        for _, model in CollectionService:GetTagged("SanctuaryWalker") do
            if model:IsA("Model") and not walkers[model] then observe(model) end
        end
    end
end)

local elapsed = 0
RunService.RenderStepped:Connect(function(delta)
    elapsed += delta
    if elapsed < 1 / 30 then return end
    elapsed %= 1 / 30
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local time = Workspace:GetServerTimeNow()
    local eye = camera.CFrame.Position
    for model, walker in walkers do
        if not model.Parent or (eye - walker.Home).Magnitude > 95 then continue end
        local angle = time * .78 + walker.Phase
        local step = math.sin(time * 8 + walker.Phase)
        local position = walker.Home + Vector3.new(math.sin(angle) * 1.35, math.abs(step) * .09, math.cos(angle) * 1.65)
        local direction = Vector3.new(math.cos(angle) * 1.35, 0, -math.sin(angle) * 1.65)
        local pose = CFrame.lookAt(position, position + direction)
        model:PivotTo(pose)
        if walker.Left then walker.Left.CFrame = pose * CFrame.new(-.62, -.72 + math.max(0, step) * .22, -.45 + step * .22) end
        if walker.Right then walker.Right.CFrame = pose * CFrame.new(.62, -.72 + math.max(0, -step) * .22, -.45 - step * .22) end
        local pulse = (1 + math.sin(time * math.pi * 2 + walker.Phase)) * .5
        walker.Caption.TextColor3 = Color3.fromRGB(94, 215, 119):Lerp(Color3.fromRGB(185, 255, 126), pulse)
        walker.Caption.TextTransparency = .22 * (1 - pulse)
    end
end)
