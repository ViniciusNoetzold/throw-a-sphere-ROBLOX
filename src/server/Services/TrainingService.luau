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
local upgradeRequests: {[Player]: number} = {}

local function machine(profile: any): any
    return Rules.Machines[profile.TrainingMachine or 1]
end
function Training.IsTraining(player:Player):boolean return sessions[player]~=nil end
local function snapshot(player:Player):any
    local p=ctx.Data.Get(player)
    if not p then return {} end
    local s=sessions[player]
    local tier = p.TrainingMachine or 1
    local titan = ctx.Monetization.GetBenefits(player).TitanArms == true
    local stats = Math.Repetition(p.TrainingLevel, tier, titan, Rules)
    local nextStats = if Rules.Machines[tier + 1] then Math.Repetition(p.TrainingLevel, tier + 1, titan, Rules) else nil
    return {Active=s~=nil,Level=p.TrainingLevel,XP=p.TrainingXP,RequiredXP=Math.RequiredXP(p.TrainingLevel,Rules),
        MaxLevel = Rules.MaxLevel, Strength = p.ThrowStrength, Gain = stats.Force, XPPerRep = stats.XP,
        Reps = if s then s.Reps else 0, Interval = if s then s.Interval else stats.Interval, NextRepAt = if s then s.NextAt else nil,
        MachineTier = tier, MachineName = machine(p).Name, NextMachineStats = nextStats}
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
    local profile = ctx.Data.Get(player)
    if now<(requests[player] or 0) or sessions[player] or ctx.Data.IsBusy(player) or not ctx.Data.IsLoaded(player) or not profile or (ctx.Flight and ctx.Flight.IsActive(player)) then return false end
    requests[player]=now+Rules.RequestCooldown
    local lot=ctx.World.GetSanctuary(player)
    local anchor=lot and lot:FindFirstChild("PersonalTraining")
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not anchor or not anchor:IsA("BasePart") or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health<=0 then return false end
    if not travel and (root.Position-anchor.Position).Magnitude>16 then return false end
    local interval = Rules.RepSeconds - machine(profile).Speed
    local s={Character=character,Root=root,Humanoid=humanoid,Anchored=root.Anchored,Speed=humanoid.WalkSpeed,AutoRotate=humanoid.AutoRotate,
        Anchor=anchor,Reps=0,StartedAt=now,Interval=interval,NextAt=now+interval,QTE=nil}
    sessions[player]=s
    character:PivotTo(CFrame.lookAt(anchor.Position+Vector3.new(0,3,0),anchor.Position+Vector3.new(0,3,-10)))
    root.Anchored,humanoid.WalkSpeed,humanoid.AutoRotate=true,0,false
    player:SetAttribute("TrainingActive",true)
    ctx.Remotes.TrainingPose:FireAllClients({Player=player,Active=true,StartedAt=now,Interval=interval})
    send(player,"Started")
    return true
end
local function award(player: Player, stats: any): any
    local p=ctx.Data.Get(player)
    if not p then return {} end
    local appliedForce = math.min(stats.Force, math.max(0, Rules.MaxStrength - p.ThrowStrength))
    p.ThrowStrength += appliedForce
    local leveled, academyXP = Math.AddXP(p, stats.XP, Rules)
    local _, gainedPlayerXP = ctx.Progression.GrantXP(player, stats.PlayerXP)
    ctx.Data.MarkDirty(player)
    ctx.Data.Sync(player)
    return {GainAwarded = appliedForce, XPAwarded = academyXP, PlayerXPAwarded = gainedPlayerXP or 0, LeveledUp = leveled}
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
            s.NextAt=now+s.Interval;s.Reps+=1
            local stats = Math.Repetition(p.TrainingLevel, p.TrainingMachine or 1, ctx.Monetization.GetBenefits(player).TitanArms == true, Rules)
            send(player, "Rep", award(player, stats))
            if s.Reps%Rules.QTEEvery==0 then
                local locations={{.23,.3},{.73,.45},{.29,.64},{.71,.27}}
                local point=locations[(math.floor(s.Reps/Rules.QTEEvery)-1)%#locations+1]
                s.QTE={Id=Http:GenerateGUID(false),ExpiresAt=now+Rules.QTESeconds,Stats=stats}
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
    local stats = s.QTE.Stats
    s.QTE=nil -- Consume before any callback: one bonus per three repetitions.
    send(player, "Perfect", award(player, stats))
    return true
end
function Training.Upgrade(player: Player, expectedTier: any): (boolean, string)
    local now = Workspace:GetServerTimeNow()
    if type(expectedTier) ~= "number" or now < (upgradeRequests[player] or 0) or ctx.Data.IsBusy(player)
        or (ctx.Flight and ctx.Flight.IsActive(player)) or sessions[player] then
        return false, "Pare o treino e conclua sua ação antes de evoluir."
    end
    upgradeRequests[player] = now + 0.4
    local profile = ctx.Data.Get(player)
    if not profile or not ctx.World.GetSanctuary(player) then return false, "Santuário indisponível." end
    local target = Rules.Machines[(profile.TrainingMachine or 1) + 1]
    if not target or expectedTier ~= (profile.TrainingMachine or 1) + 1 then return false, "Confira a próxima máquina." end
    if profile.TrainingLevel < target.Level then return false, "Alcance o nível " .. target.Level .. " na academia." end
    if profile.Coins < target.Cost then return false, "Moedas insuficientes para evoluir a máquina." end
    local lock = "TrainingMachine"
    if not ctx.Data.TryLock(player, lock) then return false, "Aguarde a ação atual." end
    profile.Coins -= target.Cost
    profile.TrainingMachine = expectedTier
    ctx.Data.MarkDirty(player)
    local saved = ctx.Data.SaveNow(player)
    ctx.Data.Unlock(player, lock)
    if not saved then
        ctx.Data.Freeze(player, "Salvamento da máquina indisponível.")
        return false, "Não foi possível salvar sua evolução."
    end
    ctx.World.UpdateTrainingMachine(player, expectedTier, target.Name)
    ctx.Data.Sync(player)
    return true, target.Name .. " liberada!"
end

function Training.Init(context:any)
    ctx=context
    ctx.Remotes.StartTraining.OnServerEvent:Connect(function(player) Training.Start(player,true) end)
    ctx.Remotes.StopTraining.OnServerEvent:Connect(Training.Stop)
    ctx.Remotes.TrainingQTE.OnServerEvent:Connect(Training.HitQTE)
    local upgrade = ctx.Remotes.UpgradeTrainingMachine
    if upgrade then upgrade.OnServerEvent:Connect(function(player, tier)
        local success, message = Training.Upgrade(player, tier)
        ctx.Remotes.ActionFeedback:FireClient(player, {Message = message, Kind = if success then "Success" else "Error"})
    end) end
    ctx.Data.AddSnapshotProvider(function(player)return {Training=snapshot(player)}end)
    local function bind(player:Player)player.CharacterRemoving:Connect(function()Training.Stop(player)end)end
    Players.PlayerAdded:Connect(bind)
    for _,player in Players:GetPlayers() do bind(player) end
    Players.PlayerRemoving:Connect(function(player)Training.Stop(player);requests[player]=nil;upgradeRequests[player]=nil end)
    if not ctx.DisableLoops then task.spawn(function()while true do task.wait(.1);Training.Tick()end end)end
end
return Training
