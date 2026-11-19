--!strict
local timestamp, serial, roll = 100, 0, 0.5
local os = {clock = function() return timestamp end}
local Color3 = {fromRGB = function() return {} end}
local vectorMeta = {}
local Vector3 = {new = function(x,y,z) return setmetatable({X=x,Y=y,Z=z}, vectorMeta) end}
vectorMeta.__sub = function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vectorMeta.__index = function(a,key) return if key == "Magnitude" then math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) else nil end
local Random = {new = function() return {NextNumber = function() return roll end, NextInteger = function() return 2 end} end}
local players = {PlayerRemoving = {Connect = function() end}}
local services = {Players = players, ReplicatedStorage = {}, Workspace = {GetServerTimeNow = function() return timestamp end}, HttpService = {GenerateGUID = function() serial += 1; return "drop-"..serial end}}
local game = {GetService = function(_,name) return services[name] end}
local Rules = (function()
--[[INJECT_DROP_CONFIG]]
end)()
local VariantRules = (function()
--[[INJECT_VARIANT_RULES]]
end)()
local Variants = (function()
--[[INJECT_VARIANTS]]
end)()
local Drops = (function()
--[[INJECT_DROPS]]
end)()
local profiles, locks, homes, benefits = {}, {}, {}, {}
local saveOK, frozen = true, false
local function person(id)
    local root = {Position = Vector3.new(0,0,0)}
    local player = {UserId=id,Parent=players,Character={FindFirstChild=function()return root end,FindFirstChildOfClass=function()return{Health=100}end}}
    profiles[player] = {Coins=0,TotalCoinsEarned=0,OrbFragments=0,Orbs={Comum=0,Mestre=0},Level=1}
    benefits[player] = {}
    return player,root
end
local first, firstRoot = person(1)
local second = person(2)
local data = {Get=function(player)return profiles[player]end, IsLoaded=function()return true end, IsBusy=function(player)return locks[player]~=nil end,
    TryLock=function(player,owner)if locks[player]then return false end;locks[player]=owner;return true end,
    Unlock=function(player,owner)assert(locks[player]==owner);locks[player]=nil end,
    MarkDirty=function()end,Sync=function()end,AddSnapshotProvider=function()end,SaveNow=function()return saveOK end,
    Freeze=function()frozen=true end,AddCoins=function(player,amount)profiles[player].Coins+=amount;profiles[player].TotalCoinsEarned+=amount end}
Drops.Init({Data=data,DropConfig=Rules,DisableVisuals=true,DisableLoops=true,Remotes={FindFirstChild=function()return nil end},
    Monetization={GetBenefits=function(player)return benefits[player]end},World={IsAtSanctuary=function(player)return homes[player]==true end}})
local checks=0
local function check(name,callback)callback();checks+=1;print("PASS "..name)end
check("private variant quantiles never downgrade shared creatures",function()
    for step=0,9999 do
        local u=step/10000
        for _,items in {VariantRules.Mutations,VariantRules.Sizes}do
            local base=Variants.FromQuantile(items,1,u)
            local better=Variants.FromQuantile(items,2,u)
            assert(better.Multiplier>=base.Multiplier)
        end
    end
    local result,bonus=Variants.Apply({Mutation="Dourada",Size="Enorme",IncomePerSec=60,MutationRoll=0.929,SizeRoll=0.98,VariantLuck=1},VariantRules.Mutations,VariantRules.Sizes,12,2)
    assert(result.Mutation=="Cristal" and result.Size=="Titanica" and result.IncomePerSec==210 and bonus.MutationFrom=="Dourada")
end)
check("personal luck requires benefits or a currently active potion",function()
    assert(Variants.GetPersonalLuck({EquippedOrb="Comum"},{},100)==1)
    assert(Variants.GetPersonalLuck({EquippedOrb="Prismatica",Boosts={Luck={Multiplier=3,ExpiresAt=101}}},{DoubleLuck=true,EternalPrism=true},100)==60)
    assert(Variants.GetPersonalLuck({EquippedOrb="Comum",Boosts={Luck={Multiplier=3,ExpiresAt=99}}},{DoubleLuck=true},100)==2)
end)
check("drops enforce ownership distance and single-use collection",function()
    local id=Drops.Spawn(first,Vector3.new(5,0,0),{Coins=25,MasterOrbs=1})
    assert(not Drops.Collect(second,id))
    firstRoot.Position=Vector3.new(100,0,0);assert(not Drops.Collect(first,id))
    firstRoot.Position=Vector3.new(0,0,0);assert(Drops.Collect(first,id))
    assert(not Drops.Collect(first,id) and profiles[first].Coins==25 and profiles[first].Orbs.Mestre==1)
end)
check("expiry invalidates unclaimed packages",function()
    local id=Drops.Spawn(first,Vector3.new(0,0,0),{Coins=5})
    timestamp+=61;Drops.Tick();assert(not Drops.Collect(first,id))
end)
check("physical cap merges owned loot without creating additional parcels",function()
    for _=1,Rules.MaxActivePerPlayer+1 do Drops.Spawn(first,Vector3.new(0,0,0),{Coins=1})end
    local state=Drops.GetSnapshot(first,profiles[first])
    assert(state.DropInfo.ActiveCount==Rules.MaxActivePerPlayer)
    local amount=0
    for _,record in state.DropInfo.Drops do amount+=record.Coins;assert(Drops.Collect(first,record.Id))end
    assert(amount==Rules.MaxActivePerPlayer+1)
end)
check("level three collects at own sanctuary and Mega collects anywhere",function()
    profiles[first].Level=3
    local id=Drops.Spawn(first,Vector3.new(500,0,0),{Coins=10})
    Drops.Tick();assert(Drops.GetSnapshot(first,profiles[first]).DropInfo.ActiveCount==1)
    homes[first]=true;Drops.Tick();assert(not Drops.Collect(first,id))
    benefits[second].MegaCollector=true
    local other=Drops.Spawn(second,Vector3.new(500,0,0),{Coins=10})
    Drops.Tick();assert(not Drops.Collect(second,other) and profiles[second].Coins==10)
end)
check("rare Master drop uses the configured actual probability",function()
    roll=0.0005
    Drops.OnCapture(first,{IncomePerSec=10},Vector3.new(0,0,0))
    local state=Drops.GetSnapshot(first,profiles[first])
    assert(state.DropInfo.Drops[1].MasterOrbs==1 and state.DropInfo.MasterChance==0.001)
    assert(Drops.Collect(first,state.DropInfo.Drops[1].Id));roll=0.5
end)
check("failed capture fragments craft once with a saved ten-to-one debit",function()
    assert(Drops.AwardFailureFragments(first)==2 and profiles[first].OrbFragments==2)
    profiles[first].OrbFragments=12
    assert(Drops.CraftOrbFragments(first))
    assert(profiles[first].OrbFragments==2 and profiles[first].Orbs.Comum==1)
    assert(not Drops.CraftOrbFragments(first) and profiles[first].Orbs.Comum==1)
end)
check("busy state insufficient fragments and stock cap never consume fragments",function()
    timestamp+=1;locks[first]="Trade";assert(not Drops.CraftOrbFragments(first));locks[first]=nil
    timestamp+=1;assert(not Drops.CraftOrbFragments(first) and profiles[first].OrbFragments==2)
    timestamp+=1;profiles[first].OrbFragments=10;profiles[first].Orbs.Comum=1e9
    assert(not Drops.CraftOrbFragments(first) and profiles[first].OrbFragments==10)
end)
check("failed craft save freezes further economic changes",function()
    timestamp+=1;profiles[first].Orbs.Comum=0;saveOK=false
    assert(not Drops.CraftOrbFragments(first) and frozen)
end)
print(string.format("DropService: %d loot/crafting/variant scenarios passed (20,000 monotonic quantile checks).",checks))
