--!strict
-- Timing meter -> server-owned flight -> rarity reveal.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Workspace=game:GetService("Workspace")
local Rules=require(RS.Shared.ConfigFlight)
local Layout=require(RS.Shared.ConfigWorld)
local Config=require(RS.Shared.Config)
local Math=require(RS.Shared.FlightMath)
local Numbers=require(RS.Shared.NumberFormatter)
local Reveal=require(script.Parent:WaitForChild("Throw"):WaitForChild("RevealDirector"))
local Pose=require(script.Parent:WaitForChild("Throw"):WaitForChild("ThrowPose"))
local remotes=RS:WaitForChild("Remotes")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name,gui.ResetOnSpawn,gui.DisplayOrder,gui.Parent="ThrowFlightHUD",false,80,player:WaitForChild("PlayerGui")
gui:SetAttribute("ReducedMotion",false)
local function round(parent:Instance)
 local r=Instance.new("UICorner");r.CornerRadius,r.Parent=UDim.new(0,12),parent
end
local function label(parent:Instance,name:string,value:string,pos:UDim2,size:UDim2,fontSize:number):TextLabel
 local l=Instance.new("TextLabel")
 l.Name,l.Text,l.Position,l.Size=name,value,pos,size
 l.BackgroundTransparency,l.Font,l.TextColor3,l.TextSize=1,Enum.Font.GothamBlack,Color3.new(1,1,1),fontSize
 l.TextStrokeTransparency,l.Parent=0.4,parent
 return l
end
local ink = Color3.fromRGB(34, 39, 66)
local panel = Instance.new("Frame")
panel.Name, panel.AnchorPoint, panel.Position = "ForcePanel", Vector2.new(.5, 1), UDim2.new(.5, 0, 1, -76)
panel.Size, panel.BackgroundColor3 = UDim2.new(.77, 0, 0, 76), Color3.fromRGB(49, 57, 89)
panel.Visible, panel.Parent = false, gui
round(panel)
local edge = Instance.new("UIStroke")
edge.Color, edge.Thickness, edge.Parent = Color3.fromRGB(255, 225, 126), 2, panel
local limits = Instance.new("UISizeConstraint")
limits.MaxSize, limits.Parent = Vector2.new(288, 76), panel
local title = label(panel, "PowerLabel", "FORÇA", UDim2.fromOffset(7, 2), UDim2.new(1, -14, 0, 22), 15)
local meter = Instance.new("Frame")
meter.Name, meter.Position, meter.Size = "PowerMeter", UDim2.fromOffset(15, 28), UDim2.new(1, -30, 0, 19)
meter.BackgroundColor3, meter.BorderSizePixel, meter.Parent = Color3.new(1, 1, 1), 0, panel
round(meter)
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 105)),
    ColorSequenceKeypoint.new(.23, Color3.fromRGB(255, 198, 70)),
    ColorSequenceKeypoint.new(.5, Color3.fromRGB(94, 245, 133)),
    ColorSequenceKeypoint.new(.77, Color3.fromRGB(255, 198, 70)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 105)),
})
gradient.Parent = meter
local perfect = Instance.new("Frame")
perfect.Position, perfect.Size = UDim2.fromScale(.465, 0), UDim2.fromScale(.07, 1)
perfect.BackgroundColor3, perfect.BackgroundTransparency, perfect.BorderSizePixel = Color3.new(1, 1, 1), .5, 0
perfect.Parent = meter
round(perfect)
local pointer = Instance.new("Frame")
pointer.Name, pointer.Size, pointer.AnchorPoint = "PowerPointer", UDim2.fromOffset(15, 23), Vector2.new(.5, .5)
pointer.BackgroundColor3, pointer.BorderSizePixel, pointer.Parent = Color3.fromRGB(255, 249, 227), 0, meter
round(pointer)
local rim = Instance.new("UIStroke")
rim.Color, rim.Thickness, rim.Parent = ink, 2, pointer
local button = Instance.new("TextButton")
button.Name, button.Position, button.Size = "LaunchButton", UDim2.fromOffset(6, 50), UDim2.new(1, -12, 0, 24)
button.Text, button.TextSize, button.Font = "CLIQUE OU TOQUE  ·  R2", 11, Enum.Font.GothamBold
button.BackgroundTransparency, button.TextColor3, button.Parent = 1, Color3.fromRGB(255, 242, 213), panel
local top=label(gui,"Distance","",UDim2.new(0.5,0,0,70),UDim2.new(0.6,0,0,60),32)
top.AnchorPoint=Vector2.new(0.5,0)
local zone=label(gui,"Biome","",UDim2.new(0.5,0,0,130),UDim2.new(0.6,0,0,36),23)
zone.AnchorPoint=Vector2.new(0.5,0)
local session:any=nil
local generation=0
local cleanup:(()->())?=nil
local chargeHidden:{[ScreenGui]:boolean}={}
local retryAt=0
local suppressUntilExit = false
local blockingMessage: string? = nil
local hint=label(gui,"LaunchHint","Encoste na linha amarela à frente para arremessar",UDim2.new(.5,0,1,-107),UDim2.new(.8,0,0,22),13)
hint.AnchorPoint=Vector2.new(.5,0)
local function atLine():boolean
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return root~=nil and Math.AtLine(root.Position,Rules.LinePosition,Rules.LineWidth,Rules.LineDepth)
end
local function hideChargeHUD()
 for _,screen in player.PlayerGui:GetChildren() do
  if screen~=gui and screen:IsA("ScreenGui") then chargeHidden[screen]=screen.Enabled;screen.Enabled=false end
 end
end
local function modal():boolean
 for _,s in player.PlayerGui:GetChildren() do
  if s~=gui and s:IsA("ScreenGui") and s.Enabled and s:GetAttribute("ModalOpen")==true then return true end
 end
 return false
end
local function restore()
 generation+=1
 if cleanup then cleanup();cleanup=nil end
 for screen,enabled in chargeHidden do if screen.Parent then screen.Enabled=enabled end end
 chargeHidden={}
 gui:SetAttribute("ModalOpen",false)
 panel.Visible=false;top.Text,zone.Text="",""
end
local function idle()
    session = nil
    blockingMessage = nil
    restore()
    retryAt = os.clock() + .18
end
local function confirm()
    if not session or session.State ~= "Charging" or not atLine() then return end
    session.State = "Submitting"
    button.Text = "ARREMESSANDO…"
    remotes.LaunchThrow:FireServer(session.Id)
end
button.Activated:Connect(confirm)

Input.InputBegan:Connect(function(input)
    if not session or session.State ~= "Charging" or Input:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
        suppressUntilExit = true
        remotes.CancelThrow:FireServer(session.Id)
        idle()
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
        or input.KeyCode == Enum.KeyCode.ButtonR2 then
        confirm()
    end
end)

Run.RenderStepped:Connect(function()
    local near = atLine()
    local inModal = modal()
    local training = player:GetAttribute("TrainingActive") == true
    if not near then
        suppressUntilExit = false
        if not session and panel.Visible then idle() end
    end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    hint.Visible = not near and not session and not inModal and not training and root ~= nil
        and (root.Position - Rules.LinePosition).Magnitude < 50
    if not session and near and not suppressUntilExit and not inModal and not training
        and player:GetAttribute("DataLoaded") == true then
        panel.Visible = true
        pointer.Visible = false
        title.Text = if blockingMessage then "ORBE INDISPONÍVEL" else "PREPARE SUA ORBE"
        button.Text = blockingMessage or "PREPARANDO…"
        if os.clock() >= retryAt then
            retryAt = os.clock() + .18
            remotes.PrepareThrow:FireServer()
        end
    elseif not session then
        panel.Visible = false
    end
    if session and session.State == "Charging" then
        if inModal or not near then
            remotes.CancelThrow:FireServer(session.Id)
            idle()
            return
        end
        local elapsed = Workspace:GetServerTimeNow() - session.StartedAt
        local power = Math.Power(elapsed, session.Period)
        pointer.Position = UDim2.fromScale(Math.MeterPosition(elapsed, session.Period), .5)
        title.Text = if power >= Rules.PerfectThreshold then "PERFEITO!" else "FORÇA " .. math.floor(power * 100) .. "%"
    end
end)
local function flight(data:any)
 restore()
 local myGeneration=generation
 local camera=Workspace.CurrentCamera
 if not camera then idle();return end
 local oldType,oldSubject,oldFOV=camera.CameraType,camera.CameraSubject,camera.FieldOfView
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local speed=humanoid and humanoid.WalkSpeed
 local hidden:{[ScreenGui]:boolean}={}
 for _,screen in player.PlayerGui:GetChildren() do
  if screen~=gui and screen:IsA("ScreenGui") then hidden[screen]=screen.Enabled;screen.Enabled=false end
 end
 if humanoid then humanoid.WalkSpeed=0 end
 camera.CameraType=Enum.CameraType.Scriptable
 local folder=Instance.new("Folder");folder.Name,folder.Parent="FlightLocalEffects",Workspace
 local orb=Instance.new("Part")
 orb.Name,orb.Shape,orb.Size,orb.Anchored="FlyingOrb",Enum.PartType.Ball,Vector3.new(1.8,1.8,1.8),true
 orb.Material,orb.Color,orb.CanCollide,orb.CanTouch,orb.CanQuery=Enum.Material.Neon,data.Color,false,false,false
 orb.Parent=folder
 local a,b,trail,light=Instance.new("Attachment"),Instance.new("Attachment"),Instance.new("Trail"),Instance.new("PointLight")
 a.Position,b.Position,a.Parent,b.Parent=Vector3.new(0,0.65,0),Vector3.new(0,-0.65,0),orb,orb
 trail.Attachment0,trail.Attachment1,trail.Color,trail.Lifetime,trail.Parent=a,b,ColorSequence.new(data.Color),0.65,orb
 light.Color,light.Brightness,light.Range,light.Parent=data.Color,2,15,orb
 local extras:{Part}={}
 for _=2,data.Count or 1 do local extra=orb:Clone();extra.Parent=folder;table.insert(extras,extra) end
 cleanup=function()
  folder:Destroy()
  for screen,enabled in hidden do if screen.Parent then screen.Enabled=enabled end end
  if humanoid and humanoid.Parent and speed then humanoid.WalkSpeed=speed end
  local current=Workspace.CurrentCamera
  if current then
   current.FieldOfView=oldFOV;current.CameraType=if current==camera then oldType else Enum.CameraType.Custom
   local live=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
   current.CameraSubject=live or oldSubject
  end
 end
 gui:SetAttribute("ModalOpen",true);panel.Visible=false
 local function alive():boolean return generation==myGeneration and gui.Parent~=nil end
 local ok,problem=pcall(function()
  while alive() and session and session.State=="Flying" do
   local elapsed=Workspace:GetServerTimeNow()-data.StartedAt
   local alpha=math.clamp((elapsed-Rules.WindupSeconds)/(data.Duration-Rules.WindupSeconds),0,1)
   local travel=1-(1-alpha)^1.4
   local pos=data.StartPos:Lerp(data.EndPos,travel)+Vector3.new(0,math.sin(alpha*math.pi)*math.min(45,10+data.Distance*0.025),0)
   orb.CFrame=CFrame.new(pos)*CFrame.Angles(alpha*20,alpha*8,0)
   for index,extra in extras do extra.CFrame=orb.CFrame*CFrame.new((if index==1 then -1 else 1)*4,0,2) end
   local reduced=gui:GetAttribute("ReducedMotion")==true
   if elapsed<Rules.WindupSeconds then
    camera.CFrame=CFrame.lookAt(data.StartPos+Vector3.new(7,4,9),data.StartPos)
    top.Text=if data.Perfect then "PERFEITO!" else "FORÇA "..math.floor(data.Power*100).."%"
    zone.Text="PREPARANDO O ARREMESSO"
   else
    camera.CFrame=CFrame.lookAt(pos+Vector3.new(if reduced then 0 else math.sin(alpha*math.pi)*3,5,15),pos+Vector3.new(0,0,-14))
    camera.FieldOfView=if reduced then oldFOV else oldFOV+math.sin(alpha*math.pi)*14
    top.Text=Numbers.Format(data.Distance*travel).." STUDS"
    local biome=Layout.BiomeOrder[math.clamp(math.floor(data.Distance*travel/Rules.ZoneLength)+1,1,#Layout.BiomeOrder)]
    zone.Text=Config.Biomes[biome].Name
   end
   if elapsed>data.Duration+10 then error("Resultado do servidor não chegou") end
   Run.RenderStepped:Wait()
  end
  if alive() and session and session.Result then top.Text,zone.Text="","";Reveal.Play(gui,session.Result,alive) end
 end)
 if alive() then restore();panel.Visible=false end
 if not ok then warn("[FlightController]",problem);idle() end
end
(remotes:WaitForChild("FlightUpdate")::RemoteEvent).OnClientEvent:Connect(function(data:any)
 if typeof(data)~="table" then return end
 if data.State=="Charging" then
  if not atLine() or modal() or suppressUntilExit then
   remotes.CancelThrow:FireServer(data.Id)
   return
  end
  session=data;panel.Visible=true;pointer.Visible=true;hint.Visible=false
  if not next(chargeHidden) then hideChargeHUD() end
  title.Text,button.Text="PARE NO CENTRO VERDE!","CLIQUE OU TOQUE  ·  R2"
 elseif data.State=="Blocked" then
  blockingMessage="CONFIRA SUA ORBE E A COLEÇÃO"
  retryAt=os.clock()+1
 elseif data.State=="Flying" then
  session=data
  title.Text=string.format("FORÇA CONFIRMADA: %d%%",math.floor(data.Power*100))
  task.spawn(flight,data)
 elseif data.State=="Landed" and session and data.Id==session.Id then session.State,session.Result="Revealing",data.Result
 elseif (data.State=="Cancelled" or data.State=="Ready") and session and data.Id==session.Id then idle() end
end)
;(remotes:WaitForChild("ThrowWindup")::RemoteEvent).OnClientEvent:Connect(function(data:any)
 if typeof(data)=="table" and typeof(data.Thrower)=="Instance" and data.Thrower:IsA("Player") and data.Thrower.Character then
  Pose.Play(data.Thrower.Character,data.Power,data.StartedAt)
 end
end)
player.CharacterRemoving:Connect(idle)
