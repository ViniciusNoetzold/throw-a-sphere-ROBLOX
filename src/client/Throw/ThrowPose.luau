--!strict
-- Three procedural throw performances, replicated as a compact server event.
-- No uploaded animation IDs are required; final artist clips can replace this module.
local Run=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local Pose={}
local active:{[Model]:()->()}={}
function Pose.Play(character:Model,power:number,startedAt:number)
 if active[character] then active[character]() end
 local strong=power>=0.8
 local medium=power>=0.35
 local arm=if strong then 2.35 elseif medium then 1.3 else 0.55
 local twist=if strong then 0.48 elseif medium then 0.22 else 0.05
 local joints={}
 for _,joint in character:GetDescendants() do
  local name=joint.Name:gsub(" ",""):lower()
  if (joint:IsA("Motor6D") or joint.ClassName=="AnimationConstraint") and (name=="rightshoulder" or name=="leftshoulder" or name=="waist" or name=="rootjoint") then
   local ok,value=pcall(function()return (joint::any).Transform end)
   if ok and typeof(value)=="CFrame" then table.insert(joints,{Joint=joint,Name=name,Original=value}) end
  end
 end
 local connection:RBXScriptConnection?=nil
 local function clear()
  if connection then connection:Disconnect();connection=nil end
  for _,item in joints do if item.Joint.Parent then pcall(function()item.Joint.Transform=item.Original end) end end
  active[character]=nil
 end
 active[character]=clear
 connection=Run.PreSimulation:Connect(function()
  local t=Workspace:GetServerTimeNow()-startedAt
  if not character.Parent or t>1.25 then clear();return end
  local wind=math.clamp(t/0.55,0,1)
  local release=math.clamp((t-0.55)/0.22,0,1)
  local recover=1-math.clamp((t-0.77)/0.48,0,1)
  local right=(arm*wind-(arm+0.4)*release)*recover
  local body=twist*math.sin(wind*math.pi/2)*(1-2*release)*recover
  for _,item in joints do
   local transform
   if item.Name=="rightshoulder" then transform=CFrame.Angles(-right,0,right*0.12)
   elseif item.Name=="leftshoulder" then transform=CFrame.Angles(if strong then -0.6*wind*recover else -0.08*wind,0,-body)
   else transform=CFrame.Angles(body*0.4,body,body*0.08) end
   if item.Joint.Parent then pcall(function()item.Joint.Transform=item.Original*transform end) end
  end
 end)
end
return Pose
