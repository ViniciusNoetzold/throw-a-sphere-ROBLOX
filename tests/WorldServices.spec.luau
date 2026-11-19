--!strict
-- Production Biome/Weather/Boss modules run against explicit service boundaries.
local timestamp, guid = 0, 0
local os = {clock = function() return timestamp end, time = function() return 1800000000 + timestamp end}
local typeof = type
local warn = function() end
local Color3 = {fromRGB = function() return {} end}
local Vector3 = {zero = {}}
local CFrame = {new = function(position) return position end}
local task = {delay = function(_, callback) error("Unexpected asynchronous retry") end}
local function signal() return {Connect = function() end} end
local players = {PlayerRemoving = signal()}
local replicated = {WaitForChild = function(self, name) return if name == "Shared" then self else name end}
local services = {Players = players, ReplicatedStorage = replicated,
    DataStoreService = {},
    Workspace = {GetServerTimeNow = function() return timestamp end},
    HttpService = {GenerateGUID = function() guid += 1; return "guid-" .. guid end}}
local game = {GetService = function(_, name) return services[name] end}
local Config = {Constants = {DataStoreName = "WorldTests"}, Creatures = {Sproutling = {BaseIncomePerSec = 100, BaseXP = 40}, Pyrokit = {}, Aquapup = {}, Voltmouse = {},
    Meteorgon = {BaseIncomePerSec = 100, BaseXP = 40}, Eclipsion = {BaseIncomePerSec = 100, BaseXP = 40}, Neonlynx = {BaseIncomePerSec = 100, BaseXP = 40}},
    Biomes = {PradariaSolar = {Cost = 0, RequiredBestiary = 0, RequiredLevel = 1, Enabled = true},
    FlorestaNeon = {Name = "Floresta Neon", Cost = 2500, RequiredBestiary = 4, RequiredLevel = 1, Enabled = true}}}
local Numbers = (function()
--[[INJECT_WORLD_NUMBERS]]
end)()
local require = function(module) return if module == "NumberFormatter" then Numbers elseif module == "ConfigWorld" then {} else Config end
local EventConfig = (function()
--[[INJECT_EVENT_CONFIG]]
end)()
local Biomes = (function()
--[[INJECT_BIOMES]]
end)()
local Weather = (function()
--[[INJECT_WEATHER]]
end)()
local Boss = (function()
--[[INJECT_BOSS]]
end)()
local Rankings = (function()
--[[INJECT_RANKINGS]]
end)()
local feedback, broadcasts, profiles, locks = {}, {}, {}, {}
local feedbackRemote = {FireClient = function(_, player, payload) table.insert(feedback, {Player = player, Data = payload}) end}
local worldRemote = {FireAllClients = function(_, payload) table.insert(broadcasts, payload) end}
local remotes = {FindFirstChild = function(_, name) return if name == "ActionFeedback" then feedbackRemote elseif name == "WorldStateUpdate" then worldRemote else nil end}
local data = {
    Get = function(player) return profiles[player] end,
    IsBusy = function(player) return locks[player] ~= nil end,
    TryLock = function(player, owner) if locks[player] then return false end; locks[player] = owner; return true end,
    Unlock = function(player, owner) assert(locks[player] == owner); locks[player] = nil end,
    Sync = function() end, MarkDirty = function() end, AddSnapshotProvider = function() end,
    AddCoins = function(player, amount) profiles[player].Coins += amount; profiles[player].TotalCoinsEarned += amount end,
}
local function person(id)
    local root = {Position = {Zone = "PradariaSolar"}, IsA = function() return true end}
    local character = {FindFirstChild = function() return root end, FindFirstChildOfClass = function() return {Health = 100} end,
        PivotTo = function(_, position) root.Position = position end}
    local player = {UserId = id, DisplayName = "Player" .. id, Parent = players, Character = character, Attributes = {}}
    player.SetAttribute = function(_, key, value) player.Attributes[key] = value end
    profiles[player] = {Coins = 3000, TotalCoinsEarned = 0, TotalCaptures = 0, XP = 0, Level = 1, Rebirths = 0,
        Bestiary = {}, UnlockedBiomes = {PradariaSolar = true}, CapturedCreatures = {}, SanctuarySlots = {}}
    return player
end
local first, second = person(1), person(2)
local models, removed, resolved, retired = {}, {}, {}, {}
local spawn = {
    Spawn = function(id, position, options)
        local model = {Id = id, Position = position, Options = options, Attributes = {}}
        model.SetAttribute = function(_, key, value) model.Attributes[key] = value end
        table.insert(models, model)
        return model
    end,
    RemoveEvent = function(id) table.insert(removed, id) end,
    Resolve = function(model, captured) table.insert(resolved, {Model = model, Captured = captured}) end,
    Retire = function(model) table.insert(retired, model) end,
}
local full = {}
local sanctuary = {
    CanCapture = function(player) return not full[player] end,
    AddCapture = function(player, record) table.insert(profiles[player].CapturedCreatures, record); profiles[player].Bestiary[record.CreatureId] = true; return true end,
}
local ctx = {Data = data, Remotes = remotes, Spawn = spawn, Biomes = Biomes, Weather = Weather, Boss = Boss,
    Sanctuary = sanctuary, EventConfig = EventConfig, DisableLoops = true, WorldConfig = {EventPosition = {}, BossPosition = {}},
    World = {GetPodiumFolder = function() return nil end, GetBiomePosition = function(id) return {Zone = id} end, GetHubPosition = function() return {Zone = "Hub"} end,
        GetTradingPosition = function() return {Zone = "TradingPlaza"} end, GetBiomeAtPosition = function(position) return position.Zone end},
    Progression = {GrantXP = function(player, amount) profiles[player].XP += amount end},
    Rewards = {OnProgress = function() end}}
Biomes.Init(ctx)
Boss.Init(ctx)
Weather.Init(ctx)
local checks = 0
local function check(name, callback) callback(); checks += 1; print("PASS " .. name) end

check("unknown biome and unmet requirements never debit coins", function()
    assert(not Biomes.Unlock(first, "ForgedBiome"))
    profiles[first].Bestiary = {Sproutling = true, Pyrokit = true, Aquapup = true, ForgedSpecies = true}
    assert(not Biomes.Unlock(first, "FlorestaNeon") and profiles[first].Coins == 3000)
end)
check("unique known bestiary entries unlock and debit exactly once", function()
    timestamp += 1; profiles[first].Bestiary.Voltmouse = true
    assert(Biomes.Unlock(first, "FlorestaNeon") and profiles[first].Coins == 500)
    assert(Biomes.Unlock(first, "FlorestaNeon") and profiles[first].Coins == 500)
end)
check("busy profiles cannot unlock or travel", function()
    locks[second] = "Trade"
    assert(not Biomes.Unlock(second, "FlorestaNeon") and not Biomes.Travel(second, "PradariaSolar"))
    locks[second] = nil
end)
check("travel verifies biome ownership and trading level on the server", function()
    assert(not Biomes.Travel(second, "FlorestaNeon"))
    profiles[second].Level = 14
    assert(not Biomes.Travel(second, "TradingPlaza"))
    profiles[second].Level = 15
    assert(Biomes.Travel(second, "TradingPlaza") and Biomes.IsInTradingPlaza(second))
    second.Attributes.CurrentBiome = "PradariaSolar"
    assert(Biomes.IsInTradingPlaza(second), "a client-facing attribute must not authorize position")
end)
check("internal rebirth return works under its existing transaction lock", function()
    locks[second] = "Rebirth"
    assert(Biomes.ReturnToMeadow(second) and Biomes.GetCurrentBiome(second) == "PradariaSolar")
    locks[second] = nil
end)
check("event interval and special spawn are based on the actual server clock", function()
    timestamp = 1199; Weather.Step(); assert(Weather.GetState().Id == "")
    timestamp = 1200; Weather.Step()
    assert(Weather.GetState().EventId == "Meteoros" and Weather.GetState().EndsAt == 1500)
    assert(models[1].Id == "Meteorgon" and models[1].Options.BiomeId == "PradariaSolar" and models[1].Options.NoRespawn)
    assert(models[2].Options.Kind == "Boss" and Boss.GetState().Stability == 100)
end)
check("global totems stack bounded duration and multiply event luck", function()
    assert(Weather.UseTotem(first) and Weather.UseTotem(first))
    assert(not Weather.UseTotem(first), "a third token at the duration cap must remain unconsumed")
    assert(Weather.GetState().TotemEndsAt == 3000 and Weather.GetLuckMultiplier() == 10)
end)
check("boss caps each hit and rewards every contributor once", function()
    local model = models[2]
    full[second] = true
    assert(Boss.TryHit(first, model, 1e9))
    assert(Boss.GetState().Stability == 75, "huge orb power must not bypass the per-hit cap")
    assert(Boss.TryHit(second, model, 1e9))
    assert(Boss.TryHit(first, model, 1e9))
    local accepted, defeated = Boss.TryHit(second, model, 1e9)
    assert(accepted and defeated and #resolved == 1)
    assert(#profiles[first].CapturedCreatures == 1 and profiles[first].TotalCaptures == 1 and profiles[first].XP == 40)
    assert(#profiles[second].CapturedCreatures == 0 and profiles[second].Coins == 9000 and profiles[second].TotalCoinsEarned == 6000 and profiles[second].XP == 40)
    assert(profiles[second].Bestiary.Meteorgon == true)
    assert(not Boss.TryHit(first, model, 1e9) and #profiles[first].CapturedCreatures == 1)
end)
check("event cleanup and rotation make both required global species reachable", function()
    timestamp = 1500; Weather.Step(); assert(Weather.GetState().Id == "" and #removed == 1)
    timestamp = 2400; Weather.Step(); assert(Weather.GetState().EventId == "Eclipse" and models[3].Id == "Eclipsion")
    assert(not Weather.SummonEvent(first), "an event token cannot replace an event in progress")
    timestamp = 2700; Weather.Step()
    timestamp = 3600; Weather.Step(); assert(Weather.GetState().EventId == "Tempestade")
end)
check("ranking score keeps large values ordered without writing huge integers", function()
    assert(Rankings.EncodeScore(1e57) > Rankings.EncodeScore(1e24))
    assert(Rankings.EncodeScore(1e57) < 1e9 and Rankings.EncodeScore(0) == 0)
    assert(Rankings.EncodeScore(0 / 0) == 0 and Rankings.EncodeScore(math.huge) == 0)
end)
local persistent, storeFailure = false, false
local summaryRecords = {}
local storeImplementation = {
    GetOrderedDataStore = function()
        if storeFailure then error("offline") end
        local values = {}
        return {SetAsync = function(_, key, value) values[key] = value end,
            GetSortedAsync = function()
                local page = {}
                for key, value in values do table.insert(page, {key = key, value = value}) end
                table.sort(page, function(a,b) return a.value > b.value end)
                return {GetCurrentPage = function() return page end}
            end}
    end,
    GetDataStore = function() return {SetAsync = function(_, key, value) summaryRecords[key] = value end, GetAsync = function(_, key) return summaryRecords[key] end} end,
}
for name, callback in storeImplementation do services.DataStoreService[name] = callback end
-- Rankings cached the service at require time; keep the original service object stable.
data.IsPersistent = function() return persistent end
players.GetPlayers = function() return {first, second} end
Rankings.Init(ctx)
check("Studio ranking reads session totals rather than current spendable balance", function()
    Rankings.Refresh()
    assert(Rankings.GetState().Mode == "Session" and Rankings.GetState().Boards.Coins[1].UserId == second.UserId)
end)
check("global ranking failure retains the last valid result", function()
    persistent, storeFailure = true, true
    profiles[first].TotalCoinsEarned = 999999
    Rankings.Refresh()
    assert(Rankings.GetState().Boards.Coins[1].UserId == second.UserId)
end)
check("global ranking recovers after service initialization failure", function()
    storeFailure = false
    Rankings.Refresh()
    assert(Rankings.GetState().Mode == "Global" and Rankings.GetState().Boards.Coins[1].UserId == first.UserId)
    assert(summaryRecords[tostring(first.UserId)].Coins == 999999, "summary must preserve actual values rather than logarithmic display scores")
end)
print(string.format("WorldServices: %d access, event and cooperative boss scenarios passed.", checks))
