--!strict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Workspace=game:GetService("Workspace")
local Debris=game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Numbers = require(RS.Shared.NumberFormatter)
local Focus = require(script.Parent:WaitForChild("CameraFocus"))
local player=Players.LocalPlayer
local remotes=RS:WaitForChild("Remotes")
local gui=Instance.new("ScreenGui")
gui.Name,gui.ResetOnSpawn,gui.DisplayOrder,gui.Parent="AcademyHUD",false,75,player:WaitForChild("PlayerGui")
local card=Instance.new("Frame")
card.Name,card.AnchorPoint,card.Position,card.Size="TrainingCard",Vector2.new(.5,1),UDim2.new(.5,0,1,-20),UDim2.new(.92,0,0,163)
card.BackgroundColor3,card.Visible,card.Parent=Color3.fromRGB(45,43,71),false,gui
local max=Instance.new("UISizeConstraint")
max.MinSize,max.MaxSize,max.Parent=Vector2.new(0,163),Vector2.new(369,163),card
local round=Instance.new("UICorner");round.CornerRadius,round.Parent=UDim.new(0,14),card
local accent = Instance.new("UIStroke")
accent.Color, accent.Thickness, accent.Parent = Color3.fromRGB(255, 194, 103), 2, card
local function text(name:string,y:number,h:number,size:number):TextLabel
 local label=Instance.new("TextLabel")
 label.Name,label.Position,label.Size=name,UDim2.fromOffset(12,y),UDim2.new(1,-24,0,h)
 label.BackgroundTransparency,label.TextColor3,label.TextSize,label.Font=1,Color3.new(1,1,1),size,Enum.Font.GothamBold
 label.Parent=card;return label
end
local title=text("AcademyLevel",5,24,16)
local xp=text("AcademyXP",29,17,12)
local track=Instance.new("Frame")
track.Name,track.Position,track.Size,track.BackgroundColor3,track.Parent="XPTrack",UDim2.fromOffset(16,48),UDim2.new(1,-32,0,12),Color3.fromRGB(38,54,72),card
local fill=Instance.new("Frame")
fill.Name,fill.Size,fill.BackgroundColor3,fill.BorderSizePixel,fill.Parent="XPFill",UDim2.fromScale(0,1),Color3.fromRGB(70,220,255),0,track
local reps=text("RepInfo",69,19,12)
local reward = text("RepReward", 90, 20, 12)
local rewardLimit = Instance.new("UITextSizeConstraint")
rewardLimit.MinTextSize, rewardLimit.MaxTextSize, rewardLimit.Parent = 8, 12, reward
reward.TextScaled, reward.TextColor3 = true, Color3.fromRGB(133, 244, 175)
local cadence = Instance.new("Frame")
cadence.Name, cadence.Size, cadence.Position = "RepProgress", UDim2.new(1, -32, 0, 4), UDim2.fromOffset(16, 63)
cadence.BackgroundColor3, cadence.BorderSizePixel, cadence.Parent = Color3.fromRGB(73, 70, 102), 0, card
local progress = Instance.new("Frame")
progress.Size, progress.BackgroundColor3, progress.BorderSizePixel, progress.Parent = UDim2.fromScale(0, 1), Color3.fromRGB(255, 194, 103), 0, cadence
local nextRepAt, interval = 0, 1.8
local xpTween: Tween?

local stop=Instance.new("TextButton")
stop.Name,stop.Position,stop.Size="StopTraining",UDim2.new(.5,-90,1,-48),UDim2.fromOffset(180,42)
stop.Text,stop.TextSize,stop.TextColor3,stop.BackgroundColor3="PARAR TREINO",12,Color3.new(1,1,1),Color3.fromRGB(65,80,105)
stop.Parent=card
local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius, stopCorner.Parent = UDim.new(0, 11), stop
stop.Font = Enum.Font.GothamBold
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
  reward.Text = ""
  Focus.Begin("Academy")
  gui:SetAttribute("ModalOpen", true)
  for _,screen in player.PlayerGui:GetChildren() do if screen~=gui and screen:IsA("ScreenGui") then hidden[screen]=screen.Enabled;screen.Enabled=false end end
 else
  Focus.Release("Academy")
  gui:SetAttribute("ModalOpen", false)
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
 title.Text = (data.MachineName or "Academia") .. "  ·  Nv. " .. tostring(data.Level or 1)
 local maxed = data.Level >= data.MaxLevel
 xp.Text = if maxed then "Nível máximo" else Numbers.Format(data.XP) .. " / " .. Numbers.Format(data.RequiredXP) .. " XP"
 if xpTween then xpTween:Cancel() end
 local fillAmount = if maxed then 1 else math.clamp(data.XP / math.max(1, data.RequiredXP), 0, 1)
 xpTween = TweenService:Create(fill, TweenInfo.new(.18), {Size = UDim2.fromScale(fillAmount, 1)})
 xpTween:Play()
 nextRepAt, interval = data.NextRepAt or 0, data.Interval or 1.8
 reps.Text = "Força " .. Numbers.Format(data.Strength) .. "  ·  +" .. Numbers.Format(data.Gain) .. " força / rep  ·  +" .. Numbers.Format(data.XPPerRep) .. " XP / rep"
 if data.GainAwarded then
  local prefix = if data.LeveledUp then "NV. " .. data.Level .. "!  " elseif data.State == "Perfect" then "2×  " else ""
  reward.Text = prefix .. "+" .. data.GainAwarded .. " força  ·  +" .. data.XPAwarded .. " XP  ·  +" .. data.PlayerXPAwarded .. " XP jogador"
 end
end
(remotes:WaitForChild("TrainingUpdate")::RemoteEvent).OnClientEvent:Connect(function(data:any)
 if typeof(data)~="table" then return end
 show(data.Active==true)
 if not data.Active then return end
 render(data)
 if data.State=="QTE" then current=data;qte.Position=UDim2.fromScale(data.X,data.Y);qte.Visible=true
 elseif data.State=="Perfect" then
  current=nil;qte.Visible=false
  local sound=Instance.new("Sound")
  sound.SoundId,sound.Volume,sound.PlaybackSpeed,sound.Parent="rbxasset://sounds/volume_slider.ogg",.15,1.5,game:GetService("SoundService")
  sound:Play();Debris:AddItem(sound,3)
 elseif data.State=="Missed" then current=nil;qte.Visible=false end
end)
Run.RenderStepped:Connect(function(delta)
 if active then
  local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if root and root:IsA("BasePart") then
   local target = root.Position + Vector3.new(0, 1.1, 0)
   local position = target + root.CFrame.RightVector * 9 + root.CFrame.LookVector * 9 + Vector3.new(0, 2.3, 0)
   Focus.Frame("Academy", CFrame.lookAt(position, target), 56, delta, 8)
  end
 end
 if active and nextRepAt > 0 then
  local fraction = 1 - math.clamp((nextRepAt - Workspace:GetServerTimeNow()) / interval, 0, 1)
  progress.Size = UDim2.fromScale(fraction, 1)
 end
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
  if (joint:IsA("Motor6D") or joint.ClassName=="AnimationConstraint") and (name=="rightshoulder" or name=="leftshoulder" or name=="waist" or name=="rootjoint" or name=="root" or name=="rightelbow" or name=="leftelbow") then
   local ok,value=pcall(function()return (joint::any).Transform end)
   if ok and typeof(value)=="CFrame" then table.insert(joints,{Joint=joint,Name=name,Original=value})end
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
   elseif item.Name=="rightelbow" or item.Name=="leftelbow" then value=CFrame.Angles(-lift*.9,0,0)
   elseif item.Name=="waist" then value=CFrame.Angles(-lift*.11,0,0)
   else value=CFrame.new(0,lift*.72,0)*CFrame.Angles(-lift*.05,0,0)end
   if item.Joint.Parent then pcall(function()item.Joint.Transform=item.Original*value end)end
  end
 end)
 animations[who]={Joints=joints,Connection=connection}
end)
player.CharacterRemoving:Connect(function()show(false);stopPose(player)end)
Players.PlayerRemoving:Connect(stopPose)
