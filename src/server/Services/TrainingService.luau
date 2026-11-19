--!strict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local Http=game:GetService("HttpService")
local Rules=require(RS.Shared.ConfigTraining)
local Math=require(RS.Shared.TrainingMath)
local Training={}
local ctx:any
local sessions:{[Player]:any}={}
local requests:{[Player]:number}={}
function Training.IsTraining(player:Player):boolean return sessions[player]~=nil end
local function snapshot(player:Player):any
    local p=ctx.Data.Get(player)
    if not p then return {} end
    local s=sessions[player]
    return {Active=s~=nil,Level=p.TrainingLevel,XP=p.TrainingXP,RequiredXP=Math.RequiredXP(p.TrainingLevel,Rules),
        Gain=Math.Gain(p.TrainingLevel,ctx.Monetization.GetBenefits(player).TitanArms==true,Rules),Reps=if s then s.Reps else 0,Interval=Rules.RepSeconds}
end
local function send(player:Player,state:string,extra:any?)
    local data=snapshot(player)
    data.State=state
    for k,v in extra or {} do data[k]=v end
    if player.Parent then ctx.Remotes.TrainingUpdate:FireClient(player,data) end
end
function Training.Stop(player:Player)
    local s=sessions[player]
    if not s then return end
    sessions[player]=nil
    player:SetAttribute("TrainingActive",false)
    if s.Root and s.Root.Parent then s.Root.Anchored=s.Anchored;s.Root.AssemblyLinearVelocity=Vector3.zero end
    if s.Humanoid and s.Humanoid.Parent then s.Humanoid.WalkSpeed=s.Speed;s.Humanoid.AutoRotate=s.AutoRotate end
    ctx.Remotes.TrainingPose:FireAllClients({Player=player,Active=false})
    send(player,"Stopped")
    ctx.Data.MarkDirty(player);ctx.Data.Sync(player)
end
function Training.Start(player:Player,travel:boolean?):boolean
    local now=Workspace:GetServerTimeNow()
    if now<(requests[player] or 0) or sessions[player] or ctx.Data.IsBusy(player) or not ctx.Data.IsLoaded(player) or (ctx.Flight and ctx.Flight.IsActive(player)) then return false end
    requests[player]=now+Rules.RequestCooldown
    local lot=ctx.World.GetSanctuary(player)
    local anchor=lot and lot:FindFirstChild("PersonalTraining")
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not anchor or not anchor:IsA("BasePart") or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health<=0 then return false end
    if not travel and (root.Position-anchor.Position).Magnitude>16 then return false end
    local s={Character=character,Root=root,Humanoid=humanoid,Anchored=root.Anchored,Speed=humanoid.WalkSpeed,AutoRotate=humanoid.AutoRotate,
        Anchor=anchor,Reps=0,StartedAt=now,NextAt=now+Rules.RepSeconds,QTE=nil}
    sessions[player]=s
    character:PivotTo(CFrame.lookAt(anchor.Position+Vector3.new(0,3,0),anchor.Position+Vector3.new(0,3,-10)))
    root.Anchored,humanoid.WalkSpeed,humanoid.AutoRotate=true,0,false
    player:SetAttribute("TrainingActive",true)
    ctx.Remotes.TrainingPose:FireAllClients({Player=player,Active=true,StartedAt=now,Interval=Rules.RepSeconds})
    send(player,"Started")
    return true
end
local function award(player:Player,gain:number,xp:number)
    local p=ctx.Data.Get(player)
    if not p then return end
    p.ThrowStrength=math.min(Rules.MaxStrength,p.ThrowStrength+gain)
    Math.AddXP(p,xp,Rules)
    ctx.Progression.GrantXP(player,Rules.PlayerXPPerRep)
    ctx.Data.MarkDirty(player)
    ctx.Data.Sync(player)
end
function Training.Tick()
    local now=Workspace:GetServerTimeNow()
    for player,s in sessions do
        local p=ctx.Data.Get(player)
        if not p or player.Character~=s.Character or not s.Root.Parent or s.Humanoid.Health<=0 or (s.Root.Position-s.Anchor.Position).Magnitude>10 then Training.Stop(player);continue end
        if ctx.Data.IsBusy(player) then s.NextAt=math.max(s.NextAt,now+0.2);continue end
        if s.QTE and now>s.QTE.ExpiresAt then s.QTE=nil;send(player,"Missed") end
        if now>=s.NextAt then
            -- Never catch up a paused server with a large burst of rewards.
            s.NextAt=now+Rules.RepSeconds;s.Reps+=1
            local gain=Math.Gain(p.TrainingLevel,ctx.Monetization.GetBenefits(player).TitanArms==true,Rules)
            award(player,gain,Rules.XPPerRep)
            send(player,"Rep",{GainAwarded=gain})
            if s.Reps%Rules.QTEEvery==0 then
                local locations={{.23,.3},{.73,.45},{.29,.64},{.71,.27}}
                local point=locations[(math.floor(s.Reps/Rules.QTEEvery)-1)%#locations+1]
                s.QTE={Id=Http:GenerateGUID(false),ExpiresAt=now+Rules.QTESeconds,Gain=gain}
                send(player,"QTE",{Id=s.QTE.Id,ExpiresAt=s.QTE.ExpiresAt,X=point[1],Y=point[2]})
            end
        end
    end
end
function Training.HitQTE(player:Player,id:any):boolean
    if type(id)~="string" or #id>80 or ctx.Data.IsBusy(player) then return false end
    local s=sessions[player]
    local now=Workspace:GetServerTimeNow()
    if not s or player.Character~=s.Character or not s.QTE or s.QTE.Id~=id or now>s.QTE.ExpiresAt or not s.Root.Parent or (s.Root.Position-s.Anchor.Position).Magnitude>10 or s.Humanoid.Health<=0 then return false end
    local gain=s.QTE.Gain
    s.QTE=nil -- Consume before any callback: one bonus per three repetitions.
    award(player,gain,Rules.XPPerRep)
    send(player,"Perfect",{GainAwarded=gain})
    return true
end
function Training.Init(context:any)
    ctx=context
    ctx.Remotes.StartTraining.OnServerEvent:Connect(function(player) Training.Start(player,true) end)
    ctx.Remotes.StopTraining.OnServerEvent:Connect(Training.Stop)
    ctx.Remotes.TrainingQTE.OnServerEvent:Connect(Training.HitQTE)
    ctx.Data.AddSnapshotProvider(function(player)return {Training=snapshot(player)}end)
    local function bind(player:Player)player.CharacterRemoving:Connect(function()Training.Stop(player)end)end
    Players.PlayerAdded:Connect(bind)
    for _,player in Players:GetPlayers() do bind(player) end
    Players.PlayerRemoving:Connect(function(player)Training.Stop(player);requests[player]=nil end)
    if not ctx.DisableLoops then task.spawn(function()while true do task.wait(.1);Training.Tick()end end)end
end
return Training
