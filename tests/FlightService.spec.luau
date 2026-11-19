--!strict
local Math=(function()
--[[MATH]]
end)()
local realRequire=require
local now=100
local delayed={}
local Vector3={}
local vm={}
function Vector3.new(x,y,z) return setmetatable({X=x,Y=y,Z=z},vm) end
Vector3.zero=Vector3.new(0,0,0)
local CFrame={new=function(position)return position end,lookAt=function(position)return position end}
vm.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vm.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vm.__mul=function(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vm.__index=function(a,k) if k=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end end
local function signal()
 local callbacks={}
 return {Connect=function(_,f)table.insert(callbacks,f)end,Fire=function(_,...)for _,f in callbacks do f(...) end end}
end
local player={Parent=true,CharacterRemoving=signal(),attributes={}}
function player:SetAttribute(k,v) self.attributes[k]=v end
local root={Parent=true,Anchored=false,Position=Vector3.new(0,0,0),IsA=function()return true end}
local character={FindFirstChild=function()return root end,FindFirstChildOfClass=function()return {Health=100} end}
function character:PivotTo(position) root.Position=position end
player.Character=character
local profile
local busy=false
local synced=0
local saved=true
local frozen=false
local messages={}
local results={}
local serial=0
local rngRoll=0
local Config={Orbs={Comum={Power=10,Color="blue",Tier=1},Mestre={Power=1000,IsMaster=true},Prismatica={Power=25,IsPrismatic=true}},
 Creatures={Sproutling={Name="Sproutling",Biome="PradariaSolar",Rarity="Comum",Difficulty=1,BaseXP=25,BaseIncomePerSec=8},
 Glowshroom={Name="Glowshroom",Biome="FlorestaNeon",Rarity="Comum",Difficulty=1,BaseXP=25,BaseIncomePerSec=8}},
 Mutations={{Name="Normal",Multiplier=1}},Sizes={{Name="Normal",Multiplier=1}},Constants={MaxInventoryCreatures=500},
 CalculateShakeProbability=function()return 1 end}
local rules={LaunchOrigin=Vector3.new(0,0,0),Direction=Vector3.new(0,0,-1),LinePosition=Vector3.new(0,0,0),LineWidth=42,LineDepth=7,MeterPeriod=1.6,ChargeTimeout=12,PerfectThreshold=.94,ZoneLength=300,WindupSeconds=.55,MinFlightSeconds=3.5,MaxFlightSeconds=7}
local modules={Config=Config,ConfigFlight=rules,ConfigReveal={Comum={Duration=2.5,Rank=1}},ConfigEvents={SecretSpawnChance=1e-6,SpeciesWeights={Comum=55}},FlightMath=Math,VariantMath={FromQuantile=function(items)return items[1]end}}
local shared=setmetatable({},{__index=function(_,k)return k end})
local require=function(key)return modules[key]end
local task={delay=function(t,f)table.insert(delayed,{At=now+t,Run=f})end}
local os={time=function()return 1800000000 end}
local Random={new=function()return {NextNumber=function()return rngRoll end}end}
local players={PlayerAdded=signal(),PlayerRemoving=signal(),GetPlayers=function()return {player}end}
local services={Players=players,ReplicatedStorage={WaitForChild=function()return shared end},Workspace={GetServerTimeNow=function()return now end},HttpService={GenerateGUID=function()serial+=1;return "id"..serial end}}
local game={GetService=function(_,k)return services[k]end}
local Flight=(function()
--[[SERVICE]]
end)()
local benefits={}
local remotes={}
for _,name in {"PrepareThrow","LaunchThrow","CancelThrow","ChooseAfterThrow"} do remotes[name]={OnServerEvent=signal()} end
remotes.FlightUpdate={FireClient=function(_,_,data)table.insert(messages,data)end}
remotes.ActionFeedback={FireClient=function()end}
remotes.ThrowWindup={FireAllClients=function()end}
remotes.ThrowResult={FireAllClients=function(_,data)table.insert(results,data)end}
local ctx={Remotes=remotes,Layout={BiomeOrder={"PradariaSolar","FlorestaNeon"}},
 World={GetSanctuaryReturnPosition=function()return Vector3.new(91,4,23) end},
 Data={Get=function()return profile end,IsLoaded=function()return profile~=nil end,IsBusy=function()return busy end,
 TryLock=function()if busy then return false end;busy=true;return true end,Unlock=function()busy=false end,
 MarkDirty=function()end,Sync=function()synced+=1 end,SaveNow=function()return saved end,
 Freeze=function()frozen=true end,GetInventoryCount=function(p)return #p.CapturedCreatures end},
 Monetization={GetBenefits=function()return benefits end},Sanctuary={CanCapture=function()return #profile.CapturedCreatures<500 end,
 AddCapture=function(_,record)table.insert(profile.CapturedCreatures,record);return true end},
 Weather={GetLuckMultiplier=function()return 1 end},Gameplay={GetLuck=function()return 1 end},Rewards={OnProgress=function()end},
 Drops={AwardFailureFragments=function()return 1 end,OnCapture=function()end},
 Progression={GrantXP=function(_,xp)profile.XP+=xp;return false,xp end}}
Flight.Init(ctx)
local function advance(t)
 now+=t
 local again=true
 while again do
  again=false
  for i=#delayed,1,-1 do if delayed[i].At<=now then local f=delayed[i].Run;table.remove(delayed,i);f();again=true end end
 end
end
local count=0
local function test(name,f)
 profile={Coins=150,Level=1,ThrowStrength=10,EquippedOrb="Comum",Orbs={Comum=25,Mestre=1},UnlockedBiomes={PradariaSolar=true},CapturedCreatures={},ComboStreak=0,PityBonus=0,TotalCaptures=0,XP=0}
 busy,saved,frozen=false,true,false;benefits={};messages={};results={};rngRoll=.5;player.Character=character;root.Position=Vector3.zero
 f();players.PlayerRemoving:Fire(player);delayed={};now+=20;count+=1;print("PASS "..name)
end
local function prepare()
 assert(Flight.Prepare(player));return messages[#messages].Id
end
test("preparing locks movement and cancelling releases it without spending",function()
 local id=prepare()
 assert(root.Anchored and profile.Orbs.Comum==25 and not busy)
 assert(Flight.Cancel(player,id))
 assert(not root.Anchored)
end)
test("flight holds the stance through landing and releases after the reveal", function()
 local id=prepare()
 advance(.4)
 assert(Flight.Launch(player,id) and root.Anchored)
 advance(8)
 assert(#results==1 and root.Anchored)
 advance(10)
 assert(not root.Anchored)
end)
test("foreign or forged nonce never launches",function()prepare();advance(.4);assert(not Flight.Launch(player,"forged"));assert(profile.Orbs.Comum==25)end)
test("server meter fixes power; client extra values are ignored",function()
 local id=prepare();advance(.4);assert(Flight.Launch(player,id));local m=messages[#messages];assert(m.Perfect and math.abs(m.Power-1)<1e-9);assert(profile.Orbs.Comum==24)
end)
test("single launch consumes once and rejects replay",function()local id=prepare();advance(.3);assert(Flight.Launch(player,id));assert(not Flight.Launch(player,id));assert(profile.Orbs.Comum==24)end)
test("species is not rolled or awarded before landing",function()local id=prepare();advance(.4);Flight.Launch(player,id);assert(#results==0 and #profile.CapturedCreatures==0);advance(3);assert(#profile.CapturedCreatures==0)end)
test("landing awards exactly once and has serializable nonrecursive bundle",function()
 local id=prepare();advance(.4);Flight.Launch(player,id);advance(8);assert(#profile.CapturedCreatures==1 and #results==1 and not busy);assert(results[1].Bundle[1]~=results[1]);advance(20);assert(#profile.CapturedCreatures==1)
end)
test("remote cancellation cannot refund an in-flight orb",function()local id=prepare();advance(.4);Flight.Launch(player,id);remotes.CancelThrow.OnServerEvent:Fire(player,id);assert(profile.Orbs.Comum==24 and busy)end)
test("departure refunds an unresolved flight and unlocks data",function()local id=prepare();advance(.4);Flight.Launch(player,id);players.PlayerRemoving:Fire(player);assert(profile.Orbs.Comum==25 and not busy);advance(10);assert(#profile.CapturedCreatures==0)end)
test("respawn cancels unresolved flight",function()local id=prepare();advance(.4);Flight.Launch(player,id);player.CharacterRemoving:Fire();assert(profile.Orbs.Comum==25 and not busy)end)
test("resolved result can never be refunded",function()local id=prepare();advance(.4);Flight.Launch(player,id);advance(8);Flight.Cancel(player,id);assert(profile.Orbs.Comum==24 and #profile.CapturedCreatures==1)end)
test("expired charge never consumes stock",function()prepare();advance(13);assert(profile.Orbs.Comum==25 and not busy)end)
test("stock is rechecked after charging",function()local id=prepare();profile.Orbs.Comum=0;advance(.4);assert(not Flight.Launch(player,id) and not busy)end)
test("full inventory rejects preparation",function()for i=1,500 do profile.CapturedCreatures[i]={}end;assert(not Flight.Prepare(player))end)
test("transaction lock rejects preparation",function()busy=true;assert(not Flight.Prepare(player))end)
test("prepare rejects a player outside the launch area",function()root.Position=Vector3.new(1000,0,0);assert(not Flight.Prepare(player));root.Position=Vector3.new(0,0,0)end)
test("launch rechecks departure from the launch area",function()local id=prepare();advance(.4);root.Position=Vector3.new(1000,0,0);assert(not Flight.Launch(player,id));assert(profile.Orbs.Comum==25);root.Position=Vector3.new(0,0,0)end)
test("extra client arguments cannot select power or biome",function()local id=prepare();advance(.3);remotes.LaunchThrow.OnServerEvent:Fire(player,id,true,math.huge,"VazioCosmico");local m=messages[#messages];assert(math.abs(m.Power-Math.Power(.3,1.6))<1e-9 and m.BiomeId==Math.Zone(m.Distance,ctx.Layout.BiomeOrder,rules.ZoneLength))end)
test("forged premium orb is rejected",function()profile.EquippedOrb="Prismatica";profile.Orbs.Prismatica=100;assert(not Flight.Prepare(player))end)
test("a permanent evolution launches with zero consumable stock", function()
    profile.OrbTier = 1
    profile.Orbs.Comum = 0
    local id = prepare()
    advance(.4)
    assert(Flight.Launch(player, id))
    advance(8)
    assert(profile.Orbs.Comum == 0 and #profile.CapturedCreatures == 1)
end)
test("verified eternal orb consumes no stock",function()profile.EquippedOrb="Prismatica";benefits.EternalPrism=true;local id=prepare();advance(.4);Flight.Launch(player,id);advance(8);assert(profile.Orbs.Prismatica==nil and #profile.CapturedCreatures==1)end)
test("triple throw consumes three and grants three",function()benefits.TripleThrow=true;local id=prepare();advance(.4);Flight.Launch(player,id);advance(8);assert(profile.Orbs.Comum==22 and #profile.CapturedCreatures==3 and #results[1].Bundle==3)end)
test("failed save freezes without sending a successful result",function()local id=prepare();advance(.4);Flight.Launch(player,id);saved=false;advance(8);assert(frozen and #results==0)end)
test("early release restores charging rather than sticking",function()local id=prepare();assert(not Flight.Launch(player,id));assert(messages[#messages].State=="Charging")end)
test("auto throw requires a verified benefit",function()assert(not Flight.AutoThrow(player));benefits.AutoThrow=true;assert(Flight.AutoThrow(player));advance(.3);assert(profile.Orbs.Comum==24)end)
assert(Math.Power(0,1.6)==0)
assert(math.abs(Math.Power(.4,1.6)-1)<1e-9)
assert(math.abs(Math.Power(1.6,1.6))<1e-9)
assert(Math.Distance(100,20,25,1)>Math.Distance(100,20,25,0))
assert(Math.Distance(35,1,10,.75)>Math.Distance(10,1,10,.75))
assert(Math.RareBoost(599,1800,.8,1)>Math.RareBoost(299,1800,.8,1))
assert(Math.RareBoost(299,1800,.8,1.25)>Math.RareBoost(299,1800,.8,1))
local order={"PradariaSolar","FlorestaNeon","CanionVulcanico"}
assert(Math.Zone(299.9,order,300)=="PradariaSolar" and Math.Zone(300,order,300)=="FlorestaNeon")
local pool={A={Biome="PradariaSolar",Rarity="Comum"},B={Biome="PradariaSolar",Rarity="Rara"},C={Biome="FlorestaNeon",Rarity="Rara"}}
local weights={Comum=55,Rara=12}
local _, weakOdds=Math.Species(pool,"PradariaSolar",weights,.99,0)
local _, strongOdds=Math.Species(pool,"PradariaSolar",weights,.99,1)
local _, diverseOdds=Math.Species(pool,"PradariaSolar",weights,.99,0,"A")
assert(strongOdds>weakOdds and diverseOdds>weakOdds)
local course = {"PradariaSolar","FlorestaNeon","CanionVulcanico","AbismoGlacial","RuinasAncestrais","VazioCosmico"}
local milestones={{Level=1},{Level=50},{Level=200},{Level=400},{Level=650},{Level=900}}
assert(Math.Limit(1800,course,300,1800,10,milestones)==299)
assert(Math.Limit(1800,course,300,1800,100,milestones)==599)
assert(Math.Limit(1800,course,300,1800,1000,milestones)==1800)
for index, milestone in milestones do
 local ceiling = if index == #course then 1800 else index*300-1
 assert(Math.Limit(1800,course,300,1800,milestone.Level,milestones)==ceiling)
 if index > 1 then
  assert(Math.Limit(1800,course,300,1800,milestone.Level-1,milestones)==(index-1)*300-1)
 end
 local baseline = Math.Distance(10,milestone.Level,10,.65) + Math.LevelDistance(index,300,.65)
 assert(baseline >= (index-1)*300)
end
local artPools = Math.BuildPools(pool, order, {FlorestaNeon={"A","missing"} })
assert(artPools.FlorestaNeon.Comum[1]=="A" and artPools.FlorestaNeon.Rara[1]=="C")
local rareGroups = {Comum={"A"},Mitica={"B"}}
local ultra = {Mitica=2500000}
local exact = {NextNumber=function() return 0 end}
local mythic, baseChance = Math.Encounter(rareGroups, ultra, exact, 1)
local _, boostedChance = Math.Encounter(rareGroups, ultra, exact, 2)
assert(mythic=="B" and baseChance==1/2500000 and boostedChance==2*baseChance)
test("a strong throw enters the next biome before buying travel access",function()
 local id=prepare();advance(.4);assert(Flight.Launch(player,id));advance(8)
 assert(not profile.UnlockedBiomes.FlorestaNeon and results[1].Distance>=300 and results[1].CreatureId=="Glowshroom")
end)
test("result offers retry once the reveal ends without spending another orb",function()
 local id=prepare();advance(.4);assert(Flight.Launch(player,id));advance(8)
 assert(not Flight.Choose(player,id,"Retry"));advance(10)
 assert(not Flight.Choose(player,"forged","Retry") and Flight.Choose(player,id,"Retry"))
 assert(not Flight.Choose(player,id,"Retry") and profile.Orbs.Comum==24 and Flight.Prepare(player))
end)
test("return after a result teleports only to the player's own sanctuary",function()
 local id=prepare();advance(.4);assert(Flight.Launch(player,id));advance(8);advance(10)
 assert(not Flight.Choose(player,id,"other") and Flight.Choose(player,id,"Base"))
 assert(root.Position.X==91 and root.Position.Z==23 and not root.Anchored and profile.Orbs.Comum==24)
end)
print("FlightService: "..count.." lifecycle/security scenarios plus meter, biome and encounter checks passed")
