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
local panel=Instance.new("Frame")
panel.Name,panel.AnchorPoint,panel.Position="ForcePanel",Vector2.new(0.5,1),UDim2.new(0.5,0,1,-100)
panel.Size,panel.BackgroundColor3,panel.BackgroundTransparency=UDim2.new(0.46,0,0,94),Color3.fromRGB(12,22,42),0.08
panel.Visible=false;panel.Parent=gui;round(panel)
local limits=Instance.new("UISizeConstraint")
limits.MinSize,limits.MaxSize,limits.Parent=Vector2.new(260,94),Vector2.new(430,94),panel
local title=label(panel,"PowerLabel","PREPARE SUA ORBE",UDim2.fromOffset(8,5),UDim2.new(1,-16,0,26),18)
local meter=Instance.new("Frame")
meter.Name,meter.Position,meter.Size="PowerMeter",UDim2.fromOffset(18,33),UDim2.new(1,-36,0,24)
meter.BackgroundColor3,meter.ClipsDescendants,meter.Parent=Color3.new(1,1,1),true,panel;round(meter)
local gradient=Instance.new("UIGradient")
gradient.Color,gradient.Parent=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(245,65,65)),ColorSequenceKeypoint.new(.25,Color3.fromRGB(255,180,55)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(50,240,110)),ColorSequenceKeypoint.new(.75,Color3.fromRGB(255,180,55)),ColorSequenceKeypoint.new(1,Color3.fromRGB(245,65,65))}),meter
local perfect=Instance.new("Frame")
perfect.Position,perfect.Size,perfect.BackgroundColor3,perfect.BackgroundTransparency=UDim2.fromScale(0.47,0),UDim2.fromScale(0.06,1),Color3.new(1,1,1),0.75
perfect.Parent=meter
local pointer=Instance.new("Frame")
pointer.Name,pointer.Size,pointer.AnchorPoint="PowerPointer",UDim2.new(0,6,1,0),Vector2.new(0.5,0)
pointer.BackgroundColor3,pointer.BorderSizePixel,pointer.Parent=Color3.new(1,1,1),0,meter
local button=Instance.new("TextButton")
button.Name,button.Position,button.Size="LaunchButton",UDim2.fromOffset(18,62),UDim2.new(1,-36,0,24)
button.Text,button.TextSize,button.Font="CLIQUE EM QUALQUER LUGAR",12,Enum.Font.GothamBlack
button.BackgroundTransparency=1
button.TextColor3,button.BackgroundColor3,button.Parent=Color3.fromRGB(220,245,230),Color3.fromRGB(105,240,145),panel;round(button)
local top=label(gui,"Distance","",UDim2.new(0.5,0,0,70),UDim2.new(0.6,0,0,60),32)
top.AnchorPoint=Vector2.new(0.5,0)
local zone=label(gui,"Biome","",UDim2.new(0.5,0,0,130),UDim2.new(0.6,0,0,36),23)
zone.AnchorPoint=Vector2.new(0.5,0)
local motion=Instance.new("TextButton")
motion.Name,motion.AnchorPoint,motion.Position,motion.Size="ReducedMotion",Vector2.new(1,1),UDim2.new(1,-14,1,-20),UDim2.fromOffset(156,30)
motion.Text,motion.TextSize,motion.BackgroundColor3,motion.TextColor3="MOVIMENTO: COMPLETO",10,Color3.fromRGB(20,30,45),Color3.new(1,1,1)
motion.Visible=false;motion.Parent=gui;round(motion)
motion.Activated:Connect(function()
 local value=gui:GetAttribute("ReducedMotion")~=true;gui:SetAttribute("ReducedMotion",value)
 motion.Text=if value then "MOVIMENTO: REDUZIDO" else "MOVIMENTO: COMPLETO"
end)
local session:any=nil
local waiting=false
local generation=0
local cleanup:(()->())?=nil
local chargeHidden:{[ScreenGui]:boolean}={}
local retryAt=0
local hint=label(gui,"LaunchHint","Encoste na linha amarela à frente para arremessar",UDim2.new(.5,0,1,-115),UDim2.new(.8,0,0,22),13)
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
 session,waiting=nil,false;restore()
 retryAt=os.clock()+0.6
 title.Text,button.Text="PARE NO CENTRO VERDE","CLIQUE OU TOQUE EM QUALQUER LUGAR"
end
local function activate()
 if waiting or modal() or not atLine() then return end
 if not session then
  waiting=true;remotes.PrepareThrow:FireServer()
  task.delay(2,function() if not session then waiting=false end end)
 elseif session.State=="Charging" then
  session.State="Submitting";button.Text="TRAVANDO FORÇA...";remotes.LaunchThrow:FireServer(session.Id)
 end
end
button.Activated:Connect(activate)
local function overUI(input:InputObject):boolean
 if input.KeyCode==Enum.KeyCode.ButtonR2 then return false end
 local point=if input.UserInputType==Enum.UserInputType.Touch then Vector2.new(input.Position.X,input.Position.Y) else Input:GetMouseLocation()
 for _,object in player.PlayerGui:GetGuiObjectsAtPosition(point.X,point.Y) do
  local current:Instance?=object
  while current and current~=player.PlayerGui do
   if current:IsA("GuiButton") or (current:IsA("GuiObject") and current.Active) then return true end
   current=current.Parent
  end
 end
 return false
end
Input.InputBegan:Connect(function(input,processed)
 local confirm=input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.ButtonR2
 if session and session.State=="Charging" and confirm then activate();return end
 if processed or Input:GetFocusedTextBox() then return end
 if input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB then
  if session and session.State=="Charging" then remotes.CancelThrow:FireServer(session.Id);idle() end
  return
 end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.ButtonR2 then
  if not overUI(input) then activate() end
 end
end)
Run.RenderStepped:Connect(function()
 local near=atLine()
 hint.Visible=not session and not near and not modal() and player:GetAttribute("TrainingActive")~=true
 if not session and near and not waiting and os.clock()>=retryAt and player:GetAttribute("DataLoaded")==true and not modal() then
  retryAt=os.clock()+2
  activate()
 end
 if session and session.State=="Charging" then
  if modal() or not near then remotes.CancelThrow:FireServer(session.Id);idle();return end
  local power=Math.Power(Workspace:GetServerTimeNow()-session.StartedAt,session.Period)
  pointer.Position=UDim2.fromScale(Math.MeterPosition(Workspace:GetServerTimeNow()-session.StartedAt,session.Period),0)
  title.Text=string.format("FORÇA %d%%  %s",math.floor(power*100),if power>=Rules.PerfectThreshold then "• PERFEITO!" else "")
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
 waiting=false
 if data.State=="Charging" then
  session=data;panel.Visible=true;hint.Visible=false
  if not next(chargeHidden) then hideChargeHUD() end
  title.Text,button.Text="PARE NO CENTRO VERDE!","CLIQUE / TOQUE EM QUALQUER LUGAR • R2"
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
Input.WindowFocusReleased:Connect(function()
 if session and session.State=="Charging" then remotes.CancelThrow:FireServer(session.Id);idle() end
end)
