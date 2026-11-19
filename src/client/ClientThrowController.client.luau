--!strict
-- Passo 1: mira local; acerto, estoque, sorte e captura pertencem ao servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local requestThrow = remotes:WaitForChild("RequestThrow") :: RemoteEvent
local throwResult = remotes:WaitForChild("ThrowResult") :: RemoteEvent
local stateUpdate = remotes:WaitForChild("StateUpdate") :: RemoteEvent

local maxRange = Config.GetMaxThrowRange(10, 1)
stateUpdate.OnClientEvent:Connect(function(state: any)
    if typeof(state) == "table" and typeof(state.MaxRange) == "number" then
        maxRange = state.MaxRange
    end
end)

local visuals = Instance.new("Folder")
visuals.Name = "ThrowASphere_ClientVisuals"
visuals.Parent = Workspace

local function makeVisual(name: string, size: Vector3): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Size = size
    part.Parent = visuals
    return part
end

local dots: {Part} = {}
for index = 1, 18 do
    local dot = makeVisual("Aim_" .. index, Vector3.new(0.35, 0.35, 0.35))
    dot.Shape = Enum.PartType.Ball
    dot.Transparency = 1
    table.insert(dots, dot)
end
local marker = makeVisual("AimTarget", Vector3.new(0.12, 2.5, 2.5))
marker.Shape = Enum.PartType.Cylinder
marker.Transparency = 1

local function hideAim()
    for _, dot in dots do
        dot.Transparency = 1
    end
    marker.Transparency = 1
end

local function bezier(startPos: Vector3, control: Vector3, finish: Vector3, alpha: number): Vector3
    local inverse = 1 - alpha
    return inverse * inverse * startPos + 2 * inverse * alpha * control + alpha * alpha * finish
end

local function controlPoint(startPos: Vector3, finish: Vector3): Vector3
    return (startPos + finish) / 2 + Vector3.new(0, math.clamp((finish - startPos).Magnitude * 0.35, 6, 40), 0)
end

local activeInput: InputObject? = nil
local inputMode = "Mouse"
local lastThrow = -math.huge

local function getRoot(): BasePart?
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

local function aimTarget(): (Vector3?, Model?, boolean)
    local camera = Workspace.CurrentCamera
    if not camera then return nil, nil, false end
    local ray: Ray
    if inputMode == "Gamepad" then
        ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    else
        local pointer = UserInputService:GetMouseLocation()
        if inputMode == "Touch" and activeInput then
            pointer = Vector2.new(activeInput.Position.X, activeInput.Position.Y)
        end
        -- ScreenPointToRay accounts for the Studio/Roblox top-bar inset.
        ray = camera:ScreenPointToRay(pointer.X, pointer.Y)
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excluded: {Instance} = {visuals}
    if player.Character then table.insert(excluded, player.Character :: Model) end
    params.FilterDescendantsInstances = excluded
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
    if not result then return nil, nil, false end
    local model = result.Instance:FindFirstAncestorOfClass("Model")
    local wildFolder = Workspace:FindFirstChild("CriaturasSelvagens")
    if model and wildFolder and model:IsDescendantOf(wildFolder) then
        return result.Position, model, result.Instance.Name == "Head"
    end
    return result.Position, nil, false
end

local function pointerOverControls(input: InputObject): boolean
    if input.KeyCode == Enum.KeyCode.ButtonR2 then return false end
    local position = UserInputService:GetMouseLocation()
    if input.UserInputType == Enum.UserInputType.Touch then
        position = Vector2.new(input.Position.X, input.Position.Y)
    end
    local playerGui = player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return false end
    for _, object in playerGui:GetGuiObjectsAtPosition(position.X, position.Y) do
        local current: Instance? = object
        while current and current ~= playerGui do
            if current:IsA("GuiButton") or (current:IsA("GuiObject") and current.Active) then
                return true
            end
            current = current.Parent
        end
    end
    return false
end

-- A modal consumes world input even when aiming with R2 or outside its panel.
local function modalOpen(): boolean
    local playerGui = player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return false end
    for _, screen in playerGui:GetChildren() do
        if screen:IsA("ScreenGui") and screen.Enabled and screen:GetAttribute("ModalOpen") == true then
            return true
        end
    end
    return false
end

RunService.RenderStepped:Connect(function()
    if not activeInput then return end
    if modalOpen() then activeInput = nil; hideAim(); return end
    local root = getRoot()
    local position, target, critical = aimTarget()
    if not root or not position then hideAim(); return end
    local targetPosition = if target and target.PrimaryPart then target.PrimaryPart.Position else position
    local inRange = (root.Position - targetPosition).Magnitude <= maxRange
    local color = if not inRange then Color3.fromRGB(255, 85, 85)
        elseif target and critical then Color3.fromRGB(255, 207, 76)
        elseif target then Color3.fromRGB(87, 235, 145)
        else Color3.fromRGB(109, 199, 255)
    local startPos = root.Position + Vector3.new(1.2, 1.8, 0)
    local control = controlPoint(startPos, position)
    for index, dot in dots do
        dot.Position = bezier(startPos, control, position, index / #dots)
        dot.Color = color
        dot.Transparency = 0.2
    end
    marker.Color = color
    marker.CFrame = CFrame.new(position + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.pi / 2)
    marker.Transparency = 0.35
end)

local function isThrowInput(input: InputObject): boolean
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
        or input.KeyCode == Enum.KeyCode.ButtonR2
end

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if processed or activeInput or not isThrowInput(input) or UserInputService:GetFocusedTextBox() then return end
    if modalOpen() then return end
    if pointerOverControls(input) then return end
    activeInput = input
    inputMode = if input.UserInputType == Enum.UserInputType.Touch then "Touch"
        elseif input.KeyCode == Enum.KeyCode.ButtonR2 then "Gamepad" else "Mouse"
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
    if input ~= activeInput then return end
    if modalOpen() or pointerOverControls(input) then
        activeInput = nil
        hideAim()
        return
    end
    -- Keep the originating touch available until its final ray has been calculated.
    local hitPos, target = aimTarget()
    activeInput = nil
    hideAim()
    local root = getRoot()
    if not root or not hitPos or not target or not target.PrimaryPart then return end
    if (root.Position - target.PrimaryPart.Position).Magnitude > maxRange then return end
    if os.clock() - lastThrow < Config.Constants.ThrowCooldownSeconds then return end
    lastThrow = os.clock()
    requestThrow:FireServer(target, hitPos)
end)

local function cancelAim()
    activeInput = nil
    hideAim()
end
UserInputService.WindowFocusReleased:Connect(cancelAim)
player.CharacterRemoving:Connect(cancelAim)

local function animateThrow(data: any)
    if typeof(data) ~= "table" or typeof(data.StartPos) ~= "Vector3" or typeof(data.HitPos) ~= "Vector3" then return end
    local orb = makeVisual("CaptureOrb", Vector3.new(1.2, 1.2, 1.2))
    local animationStarted = os.clock()
    orb.Shape = Enum.PartType.Ball
    orb.Color = if typeof(data.OrbColor) == "Color3" then data.OrbColor else Color3.fromRGB(109, 199, 255)
    orb.Position = data.StartPos
    Debris:AddItem(orb, 5)
    local attachment0 = Instance.new("Attachment")
    attachment0.Position = Vector3.new(0, 0.35, 0)
    attachment0.Parent = orb
    local attachment1 = Instance.new("Attachment")
    attachment1.Position = Vector3.new(0, -0.35, 0)
    attachment1.Parent = orb
    local trail = Instance.new("Trail")
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Color = ColorSequence.new(orb.Color)
    trail.Lifetime = 0.25
    trail.Parent = orb

    local hiddenParts: {[BasePart]: number} = {}
    local hiddenLabels: {[BillboardGui]: boolean} = {}
    local function restoreCreature()
        for part, original in hiddenParts do
            if part.Parent then part.LocalTransparencyModifier = original end
        end
        for label, original in hiddenLabels do
            if label.Parent then label.Enabled = original end
        end
    end
    local ok, failure = pcall(function()
        local startPos: Vector3 = data.StartPos
        local finish: Vector3 = data.HitPos
        local control = controlPoint(startPos, finish)
        local duration = math.clamp((finish - startPos).Magnitude / 140, 0.32, 0.75)
        local elapsed = 0
        while elapsed < duration and orb.Parent do
            elapsed += RunService.Heartbeat:Wait()
            local alpha = math.min(1, elapsed / duration)
            orb.CFrame = CFrame.new(bezier(startPos, control, finish, alpha)) * CFrame.Angles(alpha * 8, 0, alpha * 4)
        end
        local target = data.TargetModel
        if typeof(target) == "Instance" and target:IsA("Model") and target.Parent then
            for _, descendant in target:GetDescendants() do
                if descendant:IsA("BasePart") then
                    hiddenParts[descendant] = descendant.LocalTransparencyModifier
                    descendant.LocalTransparencyModifier = 1
                elseif descendant:IsA("BillboardGui") then
                    hiddenLabels[descendant] = descendant.Enabled
                    descendant.Enabled = false
                end
            end
        end
        local rest = CFrame.new(finish + Vector3.new(0, 0.7, 0))
        orb.CFrame = rest
        trail.Enabled = false
        local passed = if typeof(data.ShakesPassed) == "number" then math.clamp(data.ShakesPassed, 0, 3) else 0
        local shakes = if data.Captured then 3 else math.min(3, passed + 1)
        for _ = 1, shakes do
            task.wait(0.22)
            for _, angle in {28, -28, 0} do
                if not orb.Parent then return end
                local tween = TweenService:Create(orb, TweenInfo.new(0.11, Enum.EasingStyle.Quad), {
                    CFrame = rest * CFrame.Angles(0, 0, math.rad(angle)),
                })
                tween:Play()
                tween.Completed:Wait()
            end
        end
        if data.Captured then
            orb.Color = Color3.fromRGB(255, 213, 74)
            local tween = TweenService:Create(orb, TweenInfo.new(0.45), {Size = Vector3.new(2.2, 2.2, 2.2), Transparency = 1})
            tween:Play()
            tween.Completed:Wait()
        else
            restoreCreature()
            orb.Color = Color3.fromRGB(150, 160, 180)
            task.wait(0.3)
        end
    end)
    if ok and data.Captured then
        -- Keep the captured model hidden until the server removes it after its lock.
        -- A delayed fallback also restores models if a server-side despawn is interrupted.
        task.delay(math.max(0, 4.6 - (os.clock() - animationStarted)), restoreCreature)
    else
        restoreCreature()
    end
    orb:Destroy()
    if not ok then warn("[ThrowASphere] Falha no efeito de captura: " .. tostring(failure)) end
end

throwResult.OnClientEvent:Connect(function(data: any)
    task.spawn(animateThrow, data)
end)
