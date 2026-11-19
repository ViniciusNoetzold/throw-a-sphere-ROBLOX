--!strict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Workspace=game:GetService("Workspace")
local Debris=game:GetService("Debris")
local player=Players.LocalPlayer
local remotes=RS:WaitForChild("Remotes")
local gui=Instance.new("ScreenGui")
gui.Name,gui.ResetOnSpawn,gui.DisplayOrder,gui.Parent="AcademyHUD",false,75,player:WaitForChild("PlayerGui")
local card=Instance.new("Frame")
card.Name,card.AnchorPoint,card.Position,card.Size="TrainingCard",Vector2.new(.5,1),UDim2.new(.5,0,1,-25),UDim2.new(.65,0,0,155)
card.BackgroundColor3,card.Visible,card.Parent=Color3.fromRGB(15,25,43),false,gui
local max=Instance.new("UISizeConstraint")
max.MinSize,max.MaxSize,max.Parent=Vector2.new(280,155),Vector2.new(440,155),card
local round=Instance.new("UICorner");round.CornerRadius,round.Parent=UDim.new(0,14),card
local function text(name:string,y:number,h:number,size:number):TextLabel
 local label=Instance.new("TextLabel")
 label.Name,label.Position,label.Size=name,UDim2.fromOffset(12,y),UDim2.new(1,-24,0,h)
 label.BackgroundTransparency,label.TextColor3,label.TextSize,label.Font=1,Color3.new(1,1,1),size,Enum.Font.GothamBold
 label.Parent=card;return label
end
local title=text("AcademyLevel",8,25,19)
local xp=text("AcademyXP",37,20,13)
local track=Instance.new("Frame")
track.Name,track.Position,track.Size,track.BackgroundColor3,track.Parent="XPTrack",UDim2.fromOffset(16,62),UDim2.new(1,-32,0,12),Color3.fromRGB(38,54,72),card
local fill=Instance.new("Frame")
fill.Name,fill.Size,fill.BackgroundColor3,fill.BorderSizePixel,fill.Parent="XPFill",UDim2.fromScale(0,1),Color3.fromRGB(70,220,255),0,track
local reps=text("RepInfo",81,22,14)
local stop=Instance.new("TextButton")
stop.Name,stop.Position,stop.Size="StopTraining",UDim2.new(.5,-90,1,-40),UDim2.fromOffset(180,30)
stop.Text,stop.TextSize,stop.TextColor3,stop.BackgroundColor3="PARAR TREINO  [B / ESC]",12,Color3.new(1,1,1),Color3.fromRGB(65,80,105)
stop.Parent=card
stop.Activated:Connect(function()remotes.StopTraining:FireServer()end)
local qte=Instance.new("TextButton")
qte.Name,qte.AnchorPoint,qte.Size="DoubleTrainingQTE",Vector2.new(.5,.5),UDim2.fromOffset(90,90)
qte.Text,qte.TextSize,qte.Font="2×\nAGORA!\n[E / X]",19,Enum.Font.GothamBlack
qte.TextColor3,qte.BackgroundColor3,qte.Visible,qte.Selectable,qte.ZIndex=Color3.fromRGB(10,35,25),Color3.fromRGB(100,255,150),false,true,15
qte.Parent=gui
local corner,stroke=Instance.new("UICorner"),Instance.new("UIStroke")
corner.CornerRadius,corner.Parent=UDim.new(1,0),qte
stroke.Color,stroke.Thickness,stroke.Parent=Color3.new(1,1,1),4,qte
local hidden:{[ScreenGui]:boolean}={}
local current:any=nil
local active=false
local function show(value:boolean)
 if value==active then return end
 active=value;card.Visible=value
 if value then
  for _,screen in player.PlayerGui:GetChildren() do if screen~=gui and screen:IsA("ScreenGui") then hidden[screen]=screen.Enabled;screen.Enabled=false end end
 else
  for screen,enabled in hidden do if screen.Parent then screen.Enabled=enabled end end
  hidden={};current=nil;qte.Visible=false
 end
end
local function hit()
 if not current then return end
 local id=current.Id;current=nil;qte.Visible=false
 remotes.TrainingQTE:FireServer(id)
end
qte.Activated:Connect(hit)
Input.InputBegan:Connect(function(input,processed)
 if not active or Input:GetFocusedTextBox() then return end
 if input.KeyCode==Enum.KeyCode.E or input.KeyCode==Enum.KeyCode.ButtonX then hit()
 elseif input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB then remotes.StopTraining:FireServer() end
end)
local function render(data:any)
 title.Text="ACADEMIA • NÍVEL "..tostring(data.Level or 1)
 xp.Text=tostring(data.XP or 0).." / "..tostring(data.RequiredXP or 60).." XP"
 fill.Size=UDim2.fromScale(math.clamp((data.XP or 0)/math.max(1,data.RequiredXP or 1),0,1),1)
 reps.Text=tostring(data.Reps or 0).." repetições  •  +"..tostring(data.Gain or 1).." força por ciclo"
end
(remotes:WaitForChild("TrainingUpdate")::RemoteEvent).OnClientEvent:Connect(function(data:any)
 if typeof(data)~="table" then return end
 show(data.Active==true);render(data)
 if data.State=="QTE" then current=data;qte.Position=UDim2.fromScale(data.X,data.Y);qte.Visible=true
 elseif data.State=="Perfect" then
  current=nil;qte.Visible=false;reps.Text="PERFEITO! 2× FORÇA E XP NESTA REPETIÇÃO"
  local sound=Instance.new("Sound")
  sound.SoundId,sound.Volume,sound.PlaybackSpeed,sound.Parent="rbxasset://sounds/volume_slider.ogg",.15,1.5,game:GetService("SoundService")
  sound:Play();Debris:AddItem(sound,3)
 elseif data.State=="Missed" then current=nil;qte.Visible=false end
end)
Run.RenderStepped:Connect(function()
 if current then
  local remaining=current.ExpiresAt-Workspace:GetServerTimeNow()
  if remaining<=0 then current=nil;qte.Visible=false;return end
  stroke.Transparency=math.clamp(1-remaining/2,0,.9)
 end
end)
local animations:{[Player]:any}={}
local function stopPose(who:Player)
 local entry=animations[who];if not entry then return end
 entry.Connection:Disconnect()
 for _,item in entry.Joints do if item.Joint.Parent then pcall(function()item.Joint.Transform=item.Original end)end end
 animations[who]=nil
end
(remotes:WaitForChild("TrainingPose")::RemoteEvent).OnClientEvent:Connect(function(data:any)
 if typeof(data)~="table" or typeof(data.Player)~="Instance" or not data.Player:IsA("Player") then return end
 local who=data.Player
 stopPose(who)
 if not data.Active or not who.Character then return end
 local character=who.Character
 local joints={}
 for _,joint in character:GetDescendants() do
  local name=joint.Name:gsub(" ",""):lower()
  if (joint:IsA("Motor6D") or joint.ClassName=="AnimationConstraint") and (name=="rightshoulder" or name=="leftshoulder" or name=="waist" or name=="rootjoint") then
   local ok,value=pcall(function()return (joint::any).Transform end)
   if ok then table.insert(joints,{Joint=joint,Name=name,Original=value})end
  end
 end
 local connection
 connection=Run.PreSimulation:Connect(function()
  if not character.Parent or who.Character~=character then stopPose(who);return end
  local phase=(Workspace:GetServerTimeNow()-data.StartedAt)/data.Interval*math.pi*2
  local lift=(1-math.cos(phase))*.5
  for _,item in joints do
   local value
   if item.Name=="rightshoulder" then value=CFrame.Angles(-2.5+lift*.7,0,.15)
   elseif item.Name=="leftshoulder" then value=CFrame.Angles(-2.5+lift*.7,0,-.15)
   else value=CFrame.new(0,lift*.55,0)*CFrame.Angles(-lift*.05,0,0)end
   if item.Joint.Parent then pcall(function()item.Joint.Transform=item.Original*value end)end
  end
 end)
 animations[who]={Joints=joints,Connection=connection}
end)
player.CharacterRemoving:Connect(function()show(false);stopPose(player)end)
Players.PlayerRemoving:Connect(stopPose)
