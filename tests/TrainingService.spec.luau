--!strict
local Rules=(function()
--[[RULES]]
end)()
local Math=(function()
--[[MATH]]
end)()
local function signal()
 local callbacks={}
 return {Connect=function(_,f)table.insert(callbacks,f)end,Fire=function(_,...)for _,f in callbacks do f(...)end end}
end
local Vector3={zero={}}
local vectorMT={}
function Vector3.new(x,y,z)return setmetatable({X=x,Y=y,Z=z},vectorMT)end
vectorMT.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vectorMT.__sub=function(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vectorMT.__index=function(a,k)if k=='Magnitude' then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end end
local CFrame={lookAt=function(p)return p end}
local now,serial=100,0
local player={Parent=true,CharacterRemoving=signal(),attributes={}}
function player:SetAttribute(k,v)self.attributes[k]=v end
local root={Parent=true,Anchored=false,Position=Vector3.new(0,0,0),IsA=function()return true end}
local hum={Parent=true,Health=100,WalkSpeed=16,AutoRotate=true}
local anchor={Position=Vector3.new(0,0,0),IsA=function()return true end}
local character={FindFirstChild=function()return root end,FindFirstChildOfClass=function()return hum end,PivotTo=function(_,p)root.Position=p end}
player.Character=character
local players={PlayerAdded=signal(),PlayerRemoving=signal(),GetPlayers=function()return {player}end}
local services={Players=players,ReplicatedStorage={Shared={ConfigTraining='Rules',TrainingMath='Math'}},Workspace={GetServerTimeNow=function()return now end},HttpService={GenerateGUID=function()serial+=1;return 'qte'..serial end}}
local game={GetService=function(_,k)return services[k]end}
local require=function(k)return if k=='Rules' then Rules else Math end
local Training=(function()
--[[SERVICE]]
end)()
local profile,busy,flight,benefits,messages
local savedTier, worldTier = 0, 0
local academyAnchor, artLevel = nil, 0
local remotes={}
for _,name in {'StartTraining','StopTraining','TrainingQTE'}do remotes[name]={OnServerEvent=signal()}end
remotes.TrainingUpdate={FireClient=function(_,_,data)table.insert(messages,data)end}
remotes.TrainingPose={FireAllClients=function()end}
local ctx={DisableLoops=true,Remotes=remotes,Data={Get=function()return profile end,IsBusy=function()return busy end,IsLoaded=function()return profile~=nil end,
 MarkDirty=function()end,Sync=function()end,AddSnapshotProvider=function()end,
 TryLock=function()return not busy end,Unlock=function()end,SaveNow=function()savedTier=profile.TrainingMachine;return true end},
 World={UpdateTrainingMachine=function(_,tier)worldTier=tier end,GetSanctuary=function()return {FindFirstChild=function()return anchor end}end,
 GetTrainingAnchor=function()return academyAnchor end,UpdateAcademyArt=function(_,level)artLevel=level end},Flight={IsActive=function()return flight end},
 Monetization={GetBenefits=function()return benefits end},Progression={GrantXP=function(_,xp)profile.XP+=xp;return false,xp end}}
Training.Init(ctx)
local function advance(seconds)now+=seconds;Training.Tick()end
local count=0
local function test(name,f)
 Training.Stop(player);now+=10;messages={};profile={TrainingLevel=1,TrainingXP=0,ThrowStrength=10,XP=0}
 busy,flight,benefits=false,false,{};academyAnchor,artLevel=nil,0;player.Character=character;root.Parent=true;root.Position=Vector3.new(0,0,0);hum.Health=100
 f();count+=1;print('PASS '..name)
end
local function three()for _=1,3 do advance(Rules.RepSeconds+.01)end end
local function qte()for i=#messages,1,-1 do if messages[i].State=='QTE' then return messages[i]end end;error('missing QTE')end
test('automatic cycles grant server strength and both XP tracks',function()
    assert(Training.Start(player,true));advance(1);assert(profile.ThrowStrength==10);advance(1)
    assert(profile.ThrowStrength==11 and profile.TrainingXP==8 and profile.XP==3)
    assert(messages[#messages].XPAwarded==8 and messages[#messages].PlayerXPAwarded==3)
end)
test('duplicate start cannot create double rewards',function()assert(Training.Start(player,true));assert(not Training.Start(player,true));advance(2);assert(profile.ThrowStrength==11)end)
test('QTE appears only on each third repetition',function()Training.Start(player,true);advance(2);advance(2);for _,m in messages do assert(m.State~='QTE')end;advance(2);assert(qte().Id)end)
test('successful QTE doubles exactly its own repetition across a level up',function()
    Training.Start(player,true);three();assert(profile.ThrowStrength==13 and profile.TrainingLevel==2)
    assert(Training.HitQTE(player,qte().Id));assert(profile.ThrowStrength==14 and profile.TrainingXP==8 and profile.XP==12)
end)
test('replayed and malformed tokens cannot grant rewards',function()Training.Start(player,true);three();local id=qte().Id;assert(not Training.HitQTE(player,{}));assert(not Training.HitQTE(player,'forged'));assert(Training.HitQTE(player,id));assert(not Training.HitQTE(player,id));assert(profile.ThrowStrength==14)end)
test('expired challenge preserves automatic progress',function()Training.Start(player,true);three();local id=qte().Id;advance(2.1);assert(not Training.HitQTE(player,id));assert(Training.IsTraining(player) and profile.ThrowStrength==14)end)
test('challenge positions vary between groups of repetitions',function()Training.Start(player,true);three();local first=qte();three();local second=qte();assert(first.X~=second.X and first.Id~=second.Id)end)
test('level up consumes threshold and preserves excess XP',function()profile.TrainingXP=21;Training.Start(player,true);advance(2);assert(profile.TrainingLevel==2 and profile.TrainingXP==5)end)
test('level gain improves at configured milestones',function()assert(Math.Gain(1,false,Rules)==1 and Math.Gain(3,false,Rules)==2);assert(Math.Gain(3,true,Rules)==4)end)
test('busy profiles and active flight reject start',function()busy=true;assert(not Training.Start(player,true));busy=false;flight=true;assert(not Training.Start(player,true))end)
test('busy transaction pauses cycles without catchup burst',function()Training.Start(player,true);busy=true;advance(100);assert(profile.ThrowStrength==10);busy=false;advance(.21);assert(profile.ThrowStrength==11)end)
test('station interaction validates distance',function()root.Position=Vector3.new(500,0,0);assert(not Training.Start(player,false))end)
test('academy button travels only to server owned station',function()root.Position=Vector3.new(500,0,0);assert(Training.Start(player,true));assert(root.Position.X==anchor.Position.X and root.Anchored and hum.WalkSpeed==0)end)

test('native annex marker starts training while proximity still checks the owned lot station',function()
 academyAnchor={Position=Vector3.new(150,0,300),IsA=function()return true end}
 root.Position=Vector3.new(500,0,0);assert(not Training.Start(player,false));advance(1)
 root.Position=Vector3.new(0,0,0);assert(Training.Start(player,false))
 assert(root.Position.X==150 and root.Position.Z==300);advance(2)
 assert(profile.ThrowStrength==11 and Training.IsTraining(player))
end)

test('academy level up immediately refreshes native art without changing paid machine tier',function()
 profile.TrainingXP=21;profile.TrainingMachine=1;assert(Training.Start(player,true));advance(2)
 assert(artLevel==2 and profile.TrainingMachine==1 and Training.IsTraining(player))
end)
test('stop restores movement and prevents future rewards',function()Training.Start(player,true);Training.Stop(player);advance(100);assert(not root.Anchored and hum.WalkSpeed==16 and hum.AutoRotate and profile.ThrowStrength==10)end)
test('respawn invalidates pending bonus and session',function()Training.Start(player,true);three();local id=qte().Id;player.Character={};assert(not Training.HitQTE(player,id));Training.Tick();assert(not Training.IsTraining(player))end)
test('death ends academy without rewarding a dead character',function()Training.Start(player,true);hum.Health=0;advance(2);assert(not Training.IsTraining(player) and profile.ThrowStrength==10)end)
test('leaving triggers lifecycle cleanup',function()Training.Start(player,true);players.PlayerRemoving:Fire(player);assert(not Training.IsTraining(player) and not root.Anchored)end)
test('strength and level stay capped',function()profile.TrainingLevel=Rules.MaxLevel;profile.ThrowStrength=Rules.MaxStrength;Training.Start(player,true);advance(2);assert(profile.ThrowStrength==Rules.MaxStrength and profile.TrainingXP==0)end)
test("machine upgrade checks level and persists the paid tier before upgrading rewards", function()
    profile.Coins = 500
    profile.TrainingMachine = 1
    assert(not Training.Upgrade(player, 2))
    assert(profile.Coins == 500)
    advance(.5)
    profile.TrainingLevel = 2
    assert(Training.Upgrade(player, 2))
    assert(profile.Coins == 380 and savedTier == 2 and worldTier == 2)
    advance(.5)
    assert(not Training.Upgrade(player, 2))
    assert(Training.Start(player, true))
    advance(1.76)
    assert(profile.ThrowStrength == 12 and profile.TrainingXP == 12)
    assert(messages[#messages].Interval < Rules.RepSeconds)
end)
test("each new machine increases force and XP while reducing repetition time", function()
    for tier = 2, #Rules.Machines do
        local level = Rules.Machines[tier].Level
        local before, after = Math.Repetition(level, tier - 1, false, Rules), Math.Repetition(level, tier, false, Rules)
        assert(after.Force > before.Force and after.XP > before.XP and after.PlayerXP > before.PlayerXP and after.Interval < before.Interval)
    end
end)
test("early academy levels are quick and later XP targets outgrow rewards", function()
    local function repetitions(level, tier)
        return math.ceil(Math.RequiredXP(level, Rules) / Math.Repetition(level, tier, false, Rules).XP)
    end
    assert(repetitions(1, 1) == 3 and repetitions(2, 2) <= 4)
    assert(repetitions(52, 8) > repetitions(14, 5) and repetitions(99, 8) > repetitions(52, 8))
end)
print('TrainingService: '..count..' progression/security/lifecycle scenarios passed')
