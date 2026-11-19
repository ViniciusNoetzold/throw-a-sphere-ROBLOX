--!nocheck
-- The Python runner embeds the actual production sources; no mirrored implementation.
local sources = {__PRODUCTION_SOURCES__}
local passed = 0
local function clone(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in value do result[key] = clone(child) end
    return result
end
local function signal()
    local listeners = {}
    return {Connect = function(_, callback) table.insert(listeners, callback); return {Disconnect = function() end} end,
        Fire = function(_, ...) for _, callback in listeners do callback(...) end end}
end
local function fixture(options)
    options = options or {}
    local f = {Time = options.Time or 1700000000, Clock = 1, Benefits = options.Benefits or {}, Busy = nil, Frozen = false,
        Saves = 0, Syncs = 0, ThrowCalls = 0, AtBase = true, ReservedSlots = 0, WeatherAccepts = true, WeatherCalls = 0, Providers = {}}
    f.Player = {UserId = 42, DisplayName = "Tester", Parent = true}
    local playerList = {f.Player}
    local Players = {PlayerRemoving = signal(), GetPlayers = function() return playerList end}
    local serial = 0
    local Http = {GenerateGUID = function() serial += 1; return "generated-" .. serial end}
    local Shared = setmetatable({}, {__index = function(_, name) return {Name = name} end})
    function Shared:WaitForChild(name) return {Name = name} end
    local remotes = {}
    for _, name in {"EvolveOrb", "EquipOrb", "EquipToSanctuary", "TrainThrowPower", "ActionFeedback", "RebirthRequest", "BuySanctuarySlot", "FuseCreatures", "ClaimDailyReward", "ClaimPlaytimeReward", "ClaimMissionReward", "ClaimBestiaryReward", "RedeemCode", "UseConsumable", "ClaimGroupReward", "SetAutoMode"} do
        remotes[name] = {Name = name, OnServerEvent = signal(), FireClient = function() end}
    end
    function remotes:WaitForChild(name) assert(self[name], "missing remote " .. name); return self[name] end
    function remotes:FindFirstChild(name) return self[name] end
    local Replicated = {WaitForChild = function(_, name) return if name == "Shared" then Shared else remotes end}
    local cache = {}
    local environment = setmetatable({
        game = {GetService = function(_, name) return ({Players = Players, ReplicatedStorage = Replicated, HttpService = Http})[name] end},
        Color3 = {fromRGB = function(...) return table.pack(...) end, new = function(...) return table.pack(...) end},
        os = {time = function() return f.Time end, clock = function() return f.Clock end},
        task = {spawn = function() end, wait = function() error("Background loop executed unexpectedly") end},
        warn = function() end,
    }, {__index = getfenv()})
    environment.require = function(module)
        local name = if type(module) == "string" then module else module.Name
        if cache[name] then return cache[name] end
        assert(sources[name], "Unknown required module " .. tostring(name))
        local body = assert(loadstring(sources[name], name))
        local env = setmetatable({script = {Parent = Shared}}, {__index = environment})
        setfenv(body, env)
        cache[name] = body()
        return cache[name]
    end
    local function load(name) return environment.require({Name = name}) end
    f.Config, f.Rules, f.Math = load("Config"), load("ConfigRecompensas"), load("GameplayMath")
    f.Profile = options.Profile or {Coins = 150, Gems = 0, XP = 0, Level = 1, Rebirths = 0, ThrowStrength = 10, PityBonus = 0,
        EquippedOrb = "Comum", Orbs = {Comum = 25}, CapturedCreatures = {}, SanctuarySlots = {}, Bestiary = {}, ComboStreak = 0,
        LastSeen = f.Time, UnlockedBiomes = {PradariaSolar = true}, OfflineReward = 0, IncomePerSec = 0,
        DailyStreak = 0, LastDailyClaim = 0, PlaytimeDay = 0, OnlineSecondsToday = 0, PlaytimeClaimed = {},
        MissionDay = 0, MissionCounters = {Captures = 0, Criticals = 0, Fusions = 0}, MissionClaimed = {}, BestiaryRewardClaimed = {},
        RedeemedCodes = {}, Consumables = {}, Boosts = {}, Titles = {}, WeeklyPets = 0, FusionReadyAt = 0, ExtraSanctuarySlots = 0,
        GroupRewardClaimed = false, AutomationSettings = {Throw = false, Train = false, Fusion = false}, TotalCoinsEarned = 150, TotalCaptures = 0}
    local loadedCallbacks, removingCallbacks = {}, {}
    local Data = {
        Get = function(player) return if player == f.Player and not f.Frozen then f.Profile else nil end,
        IsLoaded = function(player) return player == f.Player and not f.Frozen end,
        IsBusy = function() return f.Busy ~= nil end,
        TryLock = function(_, owner) if f.Busy or f.Frozen then return false end; f.Busy = owner; return true end,
        Unlock = function(_, owner) assert(f.Busy == owner); f.Busy = nil end,
        Freeze = function() f.Frozen = true end,
        SaveNow = function() f.Saves += 1; if f.FailSave then return false end; f.Saved = clone(f.Profile); return true end,
        AddCoins = function(_, amount) assert(amount >= 0); f.Profile.Coins += amount; f.Profile.TotalCoinsEarned += amount end,
        MarkDirty = function() end,
        Sync = function() f.Syncs += 1 end,
        AddSnapshotProvider = function(callback) table.insert(f.Providers, callback) end,
        OnLoaded = function(callback) table.insert(loadedCallbacks, callback) end,
        OnRemoving = function(callback) table.insert(removingCallbacks, callback) end,
        GetInventoryCount = function(profile) return #profile.CapturedCreatures + f.ReservedSlots end,
    }
    local World = {AssignSanctuary = function() end, UpdateSanctuary = function() end, ReleaseSanctuary = function() end,
        IsInSanctuary = function() return f.AtBase end}
    f.Sanctuary, f.Progression, f.Rewards, f.Fusion, f.Automation = load("SanctuaryService"), load("ProgressionService"), load("RewardService"), load("FusionService"), load("AutomationService")
    f.Context = {Data = Data, World = World, Remotes = remotes, Sanctuary = f.Sanctuary, Progression = f.Progression,
        Rewards = f.Rewards, Fusion = f.Fusion, Monetization = {GetBenefits = function() return f.Benefits end},
        Biomes = {GetCurrentBiome = function() return "PradariaSolar" end, ReturnToMeadow = function() f.Returned = true end},
        Spawn = {FindAutoTarget = function() return {}, {} end}, Capture = {TryThrow = function() f.ThrowCalls += 1; return true end},
        Weather = {ActivateGlobalLuck = function() f.WeatherCalls += 1; return f.WeatherAccepts end, SummonEvent = function() f.WeatherCalls += 1; return f.WeatherAccepts end}}
    f.Sanctuary.Init(Data, World, f.Context)
    f.Progression.Init(Data, f.Sanctuary, remotes, f.Context)
    f.Rewards.Init(f.Context)
    f.Fusion.Init(f.Context)
    f.Automation.Init(f.Context)
    for _, callback in loadedCallbacks do callback(f.Player, f.Profile) end
    function f.Advance(seconds) f.Time += seconds; f.Clock += seconds end
    function f.AddCreature(id, mutation, size, displayed)
        serial += 1
        local record = {Uid = "captured-" .. serial, CreatureId = id or "Sproutling", Mutation = mutation or "Normal", Size = size or "Normal", IncomePerSec = 8, CapturedAt = f.Time}
        table.insert(f.Profile.CapturedCreatures, record)
        if displayed then table.insert(f.Profile.SanctuarySlots, record.Uid) end
        return record.Uid
    end
    function f.Selection(count, id, mutation, size)
        local result = {}
        for _ = 1, count do table.insert(result, f.AddCreature(id, mutation, size)) end
        return result
    end
    return f
end
local function test(name, callback)
    local ok, message = pcall(callback)
    assert(ok, name .. ": " .. tostring(message))
    passed += 1
    print("PASS " .. name)
end

test("XP applies rebirth and pass once", function()
    local f = fixture({Benefits = {FusionXP = true}})
    f.Profile.Rebirths = 1
    local leveled, gained = f.Progression.GrantXP(f.Player, 100)
    assert(leveled and gained == 300 and f.Profile.Level == 2 and f.Profile.XP == 200)
end)
test("XP cap reports effective zero", function()
    local f = fixture(); f.Profile.Level = 1000
    local leveled, gained = f.Progression.GrantXP(f.Player, 1000)
    assert(not leveled and gained == 0 and f.Profile.XP == 0)
end)
test("Huge XP clamps to remaining progress", function()
    local f = fixture(); f.Profile.Level = 999
    local _, gained = f.Progression.GrantXP(f.Player, 1e25)
    assert(gained == f.Config.GetXPRequiredForLevel(999) and f.Profile.Level == 1000)
end)
test("Training multiplier and shared cooldown", function()
    local f = fixture({Benefits = {TitanArms = true}})
    assert(f.Progression.Train(f.Player)); assert(f.Profile.ThrowStrength == 12 and f.Profile.Coins == 155)
    assert(not f.Progression.Train(f.Player)); f.Advance(0.5); assert(f.Progression.Train(f.Player)); assert(f.Profile.ThrowStrength == 14)
end)
test("Busy training preserves coins and strength", function()
    local f = fixture(); f.Busy = "Trade"
    assert(not f.Progression.Train(f.Player)); assert(f.Profile.Coins == 150 and f.Profile.ThrowStrength == 10)
end)
test("Rebirth requirement and preservation", function()
    local f = fixture(); f.Profile.Level = 39; assert(not f.Progression.Rebirth(f.Player))
    f.Advance(1); f.Profile.Level, f.Profile.XP, f.Profile.Coins = 40, 123, 90000
    local uid = f.AddCreature("Pyrokit", nil, nil, true)
    f.Profile.Orbs.Rubi, f.Profile.Bestiary.Pyrokit, f.Profile.RedeemedCodes.OLD = 7, true, true
    f.Profile.UnlockedBiomes.FlorestaNeon = true
    assert(f.Progression.Rebirth(f.Player))
    assert(f.Profile.Level == 1 and f.Profile.XP == 0 and f.Profile.Coins == 150 and f.Profile.Gems == 5 and f.Profile.Rebirths == 1)
    assert(f.Profile.CapturedCreatures[1].Uid == uid and f.Profile.Orbs.Rubi == 7 and f.Profile.Bestiary.Pyrokit and f.Profile.RedeemedCodes.OLD)
    assert(not f.Profile.UnlockedBiomes.FlorestaNeon and f.Returned and f.Saves == 1)
end)
test("Failed rebirth save freezes profile", function()
    local f = fixture(); f.Profile.Level = 40; f.FailSave = true
    assert(not f.Progression.Rebirth(f.Player)); assert(f.Frozen and not f.Busy)
end)
test("Coin slots use growing prices and cap", function()
    local f = fixture(); f.Profile.Coins = 40000
    assert(f.Progression.BuySlot(f.Player)); assert(f.Profile.Coins == 30000 and f.Profile.ExtraSanctuarySlots == 1)
    f.Advance(0.5); assert(f.Progression.BuySlot(f.Player)); assert(f.Profile.Coins == 10000 and f.Profile.ExtraSanctuarySlots == 2)
    f.Advance(0.5); f.Profile.ExtraSanctuarySlots = 18; assert(not f.Progression.BuySlot(f.Player))
end)
test("Base synergy excludes cash and rebirth modifiers", function()
    local f = fixture({Benefits = {DoubleCoins = true}}); f.Profile.Rebirths = 2
    for _ = 1, 3 do f.AddCreature("Sproutling", nil, nil, true) end
    assert(f.Sanctuary.CalculateBaseIncome(f.Profile) == 30)
    assert(f.Sanctuary.CalculateIncome(f.Profile, f.Benefits) == 180)
end)
test("Inventory capacity includes escrow reservations", function()
    local f = fixture(); f.ReservedSlots = 500
    assert(not f.Sanctuary.CanCapture(f.Player))
    local valid = f.Rewards.CanGrant(f.Profile, {Creature = {Id = "Voltmouse", Mutation = "Dourada", Size = "Normal"}})
    assert(not valid)
end)
test("Fusion consumes exact UIDs and preserves size", function()
    local f = fixture(); f.Profile.Level = 10
    local selected = f.Selection(5, "Sproutling", "Normal", "Grande")
    table.insert(f.Profile.SanctuarySlots, selected[1])
    assert(f.Fusion.Fuse(f.Player, selected))
    local output = f.Profile.CapturedCreatures[1]
    assert(#f.Profile.CapturedCreatures == 1 and output.Mutation == "Dourada" and output.Size == "Grande" and output.IncomePerSec == 36 and output.FusionStage == 1)
    assert(f.Profile.FusionReadyAt == f.Time + 30 and f.Profile.SanctuarySlots[1] == output.Uid and f.Profile.MissionCounters.Fusions == 1)
end)
test("Fusion rejects duplicate and mismatched inputs", function()
    local f = fixture(); f.Profile.Level = 10
    local selected = f.Selection(5); selected[5] = selected[1]
    assert(not f.Fusion.Fuse(f.Player, selected)); assert(#f.Profile.CapturedCreatures == 5 and f.Saves == 0)
    f.Advance(1); local original = f.Profile.CapturedCreatures[5]; selected[5] = original.Uid; original.Size = "Grande"
    assert(not f.Fusion.Fuse(f.Player, selected)); assert(#f.Profile.CapturedCreatures == 5)
end)
test("Fusion pass uses four and independent multiplier", function()
    local f = fixture({Benefits = {FusionXP = true}}); f.Profile.Level = 10
    assert(f.Fusion.Fuse(f.Player, f.Selection(4, "Sproutling", "Dourada")))
    assert(f.Profile.CapturedCreatures[1].Mutation == "Cristal" and f.Profile.CapturedCreatures[1].IncomePerSec == 48)
    assert(f.Profile.FusionReadyAt == f.Time)
end)
test("Fusion cooldown blocks repeated use", function()
    local f = fixture(); f.Profile.Level = 10; f.Profile.FusionReadyAt = f.Time + 30
    assert(not f.Fusion.Fuse(f.Player, f.Selection(5))); assert(f.Saves == 0)
end)
test("Auto-fusion excludes rares and displayed creatures", function()
    local f = fixture(); f.Profile.Level = 10
    f.Selection(5, "Voltmouse"); assert(f.Fusion.FindAutomaticSelection(f.Player) == nil)
    f.Selection(4, "Sproutling"); f.AddCreature("Sproutling", nil, nil, true)
    assert(f.Fusion.FindAutomaticSelection(f.Player) == nil)
    f.AddCreature("Sproutling"); assert(#f.Fusion.FindAutomaticSelection(f.Player) == 5)
end)
test("Daily bundle advances once and preserves level rewards", function()
    local f = fixture(); assert(f.Rewards.ClaimDaily(f.Player))
    assert(f.Profile.DailyStreak == 1 and f.Profile.Orbs.Comum == 35 and f.Profile.Level == 2 and f.Profile.Coins == 700)
    f.Advance(1); assert(not f.Rewards.ClaimDaily(f.Player)); assert(f.Saves == 1)
end)
test("Daily continues after 24h and resets after 48h", function()
    local f = fixture(); assert(f.Rewards.ClaimDaily(f.Player))
    f.Advance(86400); assert(f.Rewards.ClaimDaily(f.Player)); assert(f.Profile.DailyStreak == 2 and f.Profile.Consumables.PotionLuck2 == 1)
    f.Advance(172800); assert(f.Rewards.ClaimDaily(f.Player)); assert(f.Profile.DailyStreak == 1)
end)
test("Daily creature does not consume reserved inventory slots", function()
    local f = fixture(); f.Profile.DailyStreak = 3; f.Profile.LastDailyClaim = f.Time - 86400; f.ReservedSlots = 500
    assert(not f.Rewards.ClaimDaily(f.Player)); assert(f.Profile.DailyStreak == 3 and f.Saves == 0)
end)
test("Seventh daily records weekly cosmetic and gems", function()
    local f = fixture(); f.Profile.DailyStreak = 6; f.Profile.LastDailyClaim = f.Time - 86400
    assert(f.Rewards.ClaimDaily(f.Player)); assert(f.Profile.WeeklyPets == 1 and f.Profile.Gems == 5 and f.Profile.Orbs.Mestre == 1 and f.Profile.Titles.Fiel)
end)
test("Playtime uses server elapsed seconds and one claim", function()
    local f = fixture(); f.Advance(119); assert(not f.Rewards.ClaimPlaytime(f.Player, 1))
    f.Advance(1); assert(f.Rewards.ClaimPlaytime(f.Player, 1)); assert(f.Profile.PlaytimeClaimed["1"])
    f.Advance(1); assert(not f.Rewards.ClaimPlaytime(f.Player, 1))
end)
test("Playtime rollover discards previous UTC day", function()
    local boundary = math.floor(1700000000 / 86400) * 86400 + 86390
    local f = fixture({Time = boundary}); f.Profile.PlaytimeClaimed["1"] = true
    f.Advance(20); local snapshot = f.Rewards.GetSnapshot(f.Player, f.Profile)
    assert(snapshot.Rewards.Playtime.Seconds == 10 and not snapshot.Rewards.Playtime.Claimed["1"])
    assert(not f.Rewards.ClaimPlaytime(f.Player, 1)); assert(f.Profile.OnlineSecondsToday == 10 and not f.Profile.PlaytimeClaimed["1"])
end)
test("Reconnect keeps daily claims and excludes offline playtime", function()
    local first = fixture(); first.Advance(120); assert(first.Rewards.ClaimPlaytime(first.Player, 1))
    local second = fixture({Profile = clone(first.Profile), Time = first.Time + 600})
    local snapshot = second.Rewards.GetSnapshot(second.Player, second.Profile)
    assert(snapshot.Rewards.Playtime.Seconds == 120 and snapshot.Rewards.Playtime.Claimed["1"])
    assert(not second.Rewards.ClaimPlaytime(second.Player, 1))
end)
test("Missions unlock at five and pay once", function()
    local f = fixture(); f.Profile.Level = 4; f.Rewards.OnProgress(f.Player, "Captures", 15); assert(f.Profile.MissionCounters.Captures == 0)
    f.Profile.Level = 5; f.Rewards.OnProgress(f.Player, "Captures", 15)
    assert(f.Rewards.ClaimMission(f.Player, "Capture15")); assert(f.Profile.Gems == 1 and f.Profile.Orbs.Comum == 28)
    f.Advance(1); assert(not f.Rewards.ClaimMission(f.Player, "Capture15"))
    f.Advance(86400); f.Rewards.OnProgress(f.Player, "Criticals", 1); assert(f.Profile.MissionCounters.Captures == 0 and not f.Profile.MissionClaimed.Capture15)
end)
test("Bestiary claim grants one permanent luck increment", function()
    local f = fixture()
    for id, definition in f.Config.Creatures do if definition.Biome == "PradariaSolar" then f.Profile.Bestiary[id] = true end end
    assert(f.Rewards.ClaimBestiary(f.Player, "PradariaSolar")); assert(f.Profile.Coins == 1150 and f.Profile.BestiaryRewardClaimed.PradariaSolar)
    assert(math.abs(f.Math.GetLuck(f.Profile, {}, 1, f.Time) - 1.1) < 0.0001)
    f.Advance(1); assert(not f.Rewards.ClaimBestiary(f.Player, "PradariaSolar"))
end)
test("Fusion mission cannot be claimed before level ten", function()
    local f = fixture(); f.Profile.Level = 5; f.Rewards.OnProgress(f.Player, "Fusions", 1)
    assert(not f.Rewards.ClaimMission(f.Player, "Fusion1")); assert(f.Profile.Gems == 0)
    f.Advance(1); f.Profile.Level = 10; assert(f.Rewards.ClaimMission(f.Player, "Fusion1")); assert(f.Profile.Gems == 2)
end)
test("Potions extend equal, replace stronger, reject weaker", function()
    local f = fixture(); f.Profile.Consumables = {PotionLuck2 = 3, PotionLuck3 = 1}
    assert(f.Rewards.UseConsumable(f.Player, "PotionLuck2")); assert(f.Profile.Boosts.Luck.ExpiresAt == f.Time + 600)
    f.Advance(1); assert(f.Rewards.UseConsumable(f.Player, "PotionLuck2")); assert(f.Profile.Boosts.Luck.ExpiresAt == f.Time + 1199)
    f.Advance(1); assert(f.Rewards.UseConsumable(f.Player, "PotionLuck3")); assert(f.Profile.Boosts.Luck.Multiplier == 3)
    f.Advance(1); assert(not f.Rewards.UseConsumable(f.Player, "PotionLuck2")); assert(f.Profile.Consumables.PotionLuck2 == 1)
end)
test("Skip fusion does not waste a ready machine token", function()
    local f = fixture(); f.Profile.Consumables.SkipFusion = 1
    assert(not f.Rewards.UseConsumable(f.Player, "SkipFusion")); assert(f.Profile.Consumables.SkipFusion == 1)
    f.Advance(1); f.Profile.FusionReadyAt = f.Time + 30; assert(f.Rewards.UseConsumable(f.Player, "SkipFusion")); assert(f.Profile.FusionReadyAt == 0 and f.Profile.Consumables.SkipFusion == 0)
end)
test("Global tokens are consumed only after weather accepts", function()
    local f = fixture(); f.Profile.Consumables.GlobalLuckTotem = 1; f.WeatherAccepts = false
    assert(not f.Rewards.UseConsumable(f.Player, "GlobalLuckTotem")); assert(f.Profile.Consumables.GlobalLuckTotem == 1 and f.Saved.Consumables.GlobalLuckTotem == 1 and f.Saves == 2)
    f.Advance(1); f.WeatherAccepts = true; assert(f.Rewards.UseConsumable(f.Player, "GlobalLuckTotem")); assert(f.Profile.Consumables.GlobalLuckTotem == 0)
end)
test("Global effect never activates before a durable debit", function()
    local f = fixture(); f.Profile.Consumables.SummonEvent = 1; f.FailSave = true
    assert(not f.Rewards.UseConsumable(f.Player, "SummonEvent")); assert(f.Frozen and f.WeatherCalls == 0)
end)
test("Sanctuary slot token is preserved at capacity", function()
    local f = fixture(); f.Profile.Consumables.SanctuarySlot = 2
    f.Profile.ExtraSanctuarySlots = 18; assert(not f.Rewards.UseConsumable(f.Player, "SanctuarySlot")); assert(f.Profile.Consumables.SanctuarySlot == 2)
    f.Advance(1); f.Profile.ExtraSanctuarySlots = 0; assert(f.Rewards.UseConsumable(f.Player, "SanctuarySlot")); assert(f.Profile.ExtraSanctuarySlots == 1 and f.Profile.Consumables.SanctuarySlot == 1)
end)
test("Prismatic equip requires verified pass rather than fake stock", function()
    local f = fixture()
    f.Context.Remotes.EquipOrb.OnServerEvent:Fire(f.Player, "Prismatica"); assert(f.Profile.EquippedOrb == "Comum")
    f.Advance(1); f.Benefits.EternalPrism = true
    f.Context.Remotes.EquipOrb.OnServerEvent:Fire(f.Player, "Prismatica"); assert(f.Profile.EquippedOrb == "Prismatica" and not f.Profile.Orbs.Prismatica)
end)
test("VIP chest validates pass and daily cooldown", function()
    local f = fixture(); assert(not f.Rewards.ClaimVIP(f.Player))
    f.Advance(1); f.Benefits.GoldenVIP = true; assert(f.Rewards.ClaimVIP(f.Player)); assert(f.Profile.Orbs.Esmeralda == 3 and f.Profile.VIPLastClaim == f.Time)
    f.Advance(1); assert(not f.Rewards.ClaimVIP(f.Player))
    f.Advance(86400); assert(f.Rewards.ClaimVIP(f.Player)); assert(f.Profile.Orbs.Esmeralda == 6)
end)
test("No invented codes and configured code redeems once", function()
    local f = fixture(); assert(not f.Rewards.RedeemCode(f.Player, "FAKE"))
    f.Rules.Codes.REAL = {Reward = {Coins = 123, Orbs = {Comum = 2}}}
    f.Advance(1); assert(f.Rewards.RedeemCode(f.Player, " real ")); assert(f.Profile.Coins == 273 and f.Profile.Orbs.Comum == 27)
    f.Advance(1); assert(not f.Rewards.RedeemCode(f.Player, "REAL"))
    f.Rules.Codes.EXPIRED = {ExpiresAt = f.Time - 1, Reward = {Coins = 999}}
    f.Advance(1); assert(not f.Rewards.RedeemCode(f.Player, "EXPIRED")); assert(f.Profile.Coins == 273)
end)
test("Automation checks grants, location and busy state", function()
    local f = fixture(); assert(not f.Automation.SetMode(f.Player, "Throw", true))
    f.Advance(1); f.Benefits.GroupMember = true; assert(f.Automation.SetMode(f.Player, "Train", true))
    f.Automation.TickPlayer(f.Player); assert(f.Profile.ThrowStrength == 11)
    f.Advance(1); f.AtBase = false; f.Automation.TickPlayer(f.Player); assert(f.Profile.ThrowStrength == 11)
    f.Advance(1); f.Benefits.AutoThrow = true; assert(f.Automation.SetMode(f.Player, "Throw", true))
    f.Automation.TickPlayer(f.Player); assert(f.ThrowCalls == 1)
    f.Busy = "Trade"; f.Automation.TickPlayer(f.Player); assert(f.ThrowCalls == 1)
    f.Busy = nil; f.Benefits.AutoThrow = false; f.Automation.TickPlayer(f.Player); assert(not f.Profile.AutomationSettings.Throw)
end)
test("Failed claim save freezes rather than claiming success", function()
    local f = fixture(); f.FailSave = true; assert(not f.Rewards.ClaimDaily(f.Player)); assert(f.Frozen and not f.Busy)
end)
test("Malformed client payloads never change rewards or automation", function()
    local f = fixture()
    assert(not f.Rewards.ClaimPlaytime(f.Player, 0 / 0))
    assert(not f.Rewards.ClaimPlaytime(f.Player, 1.5))
    assert(not f.Rewards.RedeemCode(f.Player, string.rep("X", 65)))
    assert(not f.Automation.SetMode(f.Player, "Throw", "true"))
    assert(not f.Fusion.Fuse(f.Player, {[1] = "x", [2] = "x"}))
    assert(f.Profile.Coins == 150 and f.Saves == 0)
end)
print(string.format("Progression systems: %d scenarios passed", passed))
