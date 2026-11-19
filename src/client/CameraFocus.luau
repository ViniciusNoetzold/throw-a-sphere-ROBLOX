--!strict
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ACTION = "ThrowASphereGameplayFocus"
local CameraFocus = {}
local owner: string? = nil
local original: {Camera: Camera, Type: Enum.CameraType, Subject: Instance?, CFrame: CFrame, FOV: number}? = nil

function CameraFocus.Release(key: string)
    if key ~= owner then return end
    owner = nil
    ContextActionService:UnbindAction(ACTION)
    local previous = original
    original = nil
    local camera = Workspace.CurrentCamera
    if not previous or not camera then return end
    local player = Players.LocalPlayer
    local currentHumanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    camera.CameraSubject = if previous.Subject and previous.Subject.Parent then previous.Subject else currentHumanoid
    camera.CFrame = previous.CFrame
    camera.FieldOfView = previous.FOV
    camera.CameraType = if camera == previous.Camera then previous.Type else Enum.CameraType.Custom
end

function CameraFocus.Begin(key: string)
    if key == owner then return end
    if owner then CameraFocus.Release(owner) end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    owner = key
    original = {Camera = camera, Type = camera.CameraType, Subject = camera.CameraSubject, CFrame = camera.CFrame, FOV = camera.FieldOfView}
    camera.CameraType = Enum.CameraType.Scriptable
    ContextActionService:BindActionAtPriority(ACTION, function()
        return Enum.ContextActionResult.Sink
    end, false, Enum.ContextActionPriority.High.Value + 10,
        Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward,
        Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight,
        Enum.PlayerActions.CharacterJump, Enum.KeyCode.Thumbstick1, Enum.KeyCode.ButtonA)
end

function CameraFocus.Frame(key: string, target: CFrame, fov: number, delta: number, response: number)
    local camera = Workspace.CurrentCamera
    if key ~= owner or not camera then return end
    local alpha = 1 - math.exp(-math.max(0, delta) * response)
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = camera.CFrame:Lerp(target, alpha)
    camera.FieldOfView += (fov - camera.FieldOfView) * alpha
    camera.Focus = CFrame.new(camera.CFrame.Position + camera.CFrame.LookVector * 12)
end

return CameraFocus
