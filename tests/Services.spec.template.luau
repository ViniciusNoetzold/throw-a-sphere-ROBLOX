--!nocheck
-- Sources are embedded by run_data_tests.py; do not run this template directly.
local sources = {
	DataService = __DATASERVICE_SOURCE__,
	SanctuaryService = __SANCTUARYSERVICE_SOURCE__,
	ProgressionService = __PROGRESSIONSERVICE_SOURCE__,
}

local function clone(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = clone(child) end
	return result
end

local Config = {
	Constants = {
		MaxLevel = 100, BaseSanctuarySlots = 6, MaxOfflineSeconds = 28800,
		DataStoreName = "TestOnly", StudioPersistence = false,
		AutoSaveSeconds = 60, SessionLeaseSeconds = 180,
		InitialCoins = 150, InitialOrbs = 25, InitialThrowStrength = 10,
		TrainingCoins = 5, TrainingStrength = 1,
	},
	Orbs = {
		Comum = { Name = "Orbe Comum", Price = 25 },
		Esmeralda = { Name = "Orbe Esmeralda", Price = 180 },
		Mestre = { Name = "Orbe Mestre", Price = 0, IsMaster = true },
	},
	Creatures = {
		Pyrokit = { Element = "Fogo" }, Aquapup = { Element = "Agua" },
		Sproutling = { Element = "Planta" }, Voltmouse = { Element = "Raio" },
	},
	GetXPRequiredForLevel = function(level) return math.floor(100 * level ^ 1.6) end,
	GetMaxThrowRange = function(strength, level) return 40 + strength * 0.5 + level * 2 end,
}

local function createStore()
	local store = { Records = {}, Writes = 0, Fail = false }
	function store:UpdateAsync(key, transform)
		if self.Fail then error("DataStore unavailable (test fixture)") end
		local replacement = transform(clone(self.Records[key]))
		if replacement ~= nil then
			self.Records[key] = clone(replacement)
			self.Writes += 1
		end
		return clone(replacement)
	end
	return store
end

local function engine(options)
	options = options or {}
	local now = options.Time or 0
	local epoch = 1700000000
	local queue = {}
	local function spawn(callback, ...)
		table.insert(queue, { At = now, Thread = coroutine.create(callback), Arguments = table.pack(...) })
	end
	local taskMock = { spawn = spawn }
	function taskMock.wait(seconds)
		return coroutine.yield(seconds or 0.03)
	end
	local function advance(seconds)
		local untilTime = now + seconds
		local guard = 0
		while true do
			local index, earliest = nil, math.huge
			for candidate, item in ipairs(queue) do
				if item.At < earliest then index, earliest = candidate, item.At end
			end
			if not index or earliest > untilTime then break end
			guard += 1
			assert(guard < 10000, "Mock scheduler runaway")
			local item = table.remove(queue, index)
			now = item.At
			local ok, wait = coroutine.resume(item.Thread, table.unpack(item.Arguments, 1, item.Arguments.n))
			assert(ok, tostring(wait))
			if coroutine.status(item.Thread) ~= "dead" then
				table.insert(queue, { At = now + (wait or 0.03), Thread = item.Thread, Arguments = table.pack(wait or 0.03) })
			end
		end
		now = untilTime
	end
	local function signal()
		local listeners = {}
		return {
			Connect = function(_, callback)
				table.insert(listeners, callback)
				return { Disconnect = function() end }
			end,
			Fire = function(_, ...)
				for _, callback in ipairs(listeners) do spawn(callback, ...) end
			end,
		}
	end
	local methods = {}
	local objectMeta = {
		__index = function(object, key)
			if key == "Parent" then return rawget(object, "_parent") end
			return methods[key]
		end,
		__newindex = function(object, key, value)
			if key == "Parent" then
				local old = rawget(object, "_parent")
				if old then
					local index = table.find(old._children, object)
					if index then table.remove(old._children, index) end
				end
				rawset(object, "_parent", value)
				if value then table.insert(value._children, object) end
			else
				rawset(object, key, value)
			end
		end,
	}
	local function object(className, name)
		return setmetatable({ ClassName = className, Name = name or className, _children = {}, _attributes = {} }, objectMeta)
	end
	function methods:FindFirstChild(name)
		for _, child in ipairs(self._children) do if child.Name == name then return child end end
		return nil
	end
	function methods:WaitForChild(name)
		local child = self:FindFirstChild(name)
		assert(child, "Missing fixture child: " .. name)
		return child
	end
	function methods:SetAttribute(name, value) self._attributes[name] = value end
	function methods:GetAttribute(name) return self._attributes[name] end
	function methods:Kick(reason) self.Kicked = reason; self.Parent = nil end
	local players = object("Players")
	players.PlayerAdded = signal()
	players.PlayerRemoving = signal()
	function players:GetPlayers() return clone(self._players) end
	-- Player identity must survive enumeration (deep copying would not model Instances).
	players.GetPlayers = function(self) return table.clone(self._players) end
	players._players = {}
	local storage = object("ReplicatedStorage")
	local shared = object("Folder", "Shared"); shared.Parent = storage
	local configNode = object("ModuleScript", "Config"); configNode.Parent = shared
	local remotes = object("Folder", "Remotes"); remotes.Parent = storage
	for _, name in ipairs({ "StateUpdate", "RequestState", "EquipToSanctuary", "ActionFeedback", "BuyOrb", "EquipOrb", "TrainThrowPower" }) do
		local remote = object("RemoteEvent", name)
		remote.OnServerEvent = signal()
		remote.Messages = {}
		function remote:FireClient(player, payload) table.insert(self.Messages, { Player = player, Data = clone(payload) }) end
		remote.Parent = remotes
	end
	local store = options.Store or createStore()
	local services = {
		Players = players, ReplicatedStorage = storage,
		DataStoreService = { GetDataStore = function() return store end },
		RunService = { IsStudio = function() return options.Studio == true end },
		HttpService = { GenerateGUID = function() return "mock-guid" end },
	}
	local gameMock = { JobId = options.JobId or "server-a", Closers = {} }
	function gameMock:GetService(name) assert(services[name], name); return services[name] end
	function gameMock:BindToClose(callback) table.insert(self.Closers, callback) end
	local osMock = setmetatable({ time = function() return epoch + math.floor(now) end, clock = function() return now end }, { __index = os })
	local environment = setmetatable({
		game = gameMock, task = taskMock, os = osMock,
		Instance = { new = function(kind) return object(kind) end },
		require = function(node) assert(node == configNode, "Unexpected mocked require"); return Config end,
		warn = function() end,
	}, { __index = getfenv() })
	local function loadModule(name)
		local chunk, err = loadstring(sources[name], name)
		assert(chunk, err)
		setfenv(chunk, environment)
		return chunk()
	end
	local data = loadModule("DataService")
	local sanctuary = loadModule("SanctuaryService")
	local progression = loadModule("ProgressionService")
	local world = { AssignSanctuary = function() end, UpdateSanctuary = function() end, ReleaseSanctuary = function() end }
	if options.WithEconomy then
		sanctuary.Init(data, world)
		progression.Init(data, sanctuary, remotes)
	end
	data.Init(remotes)
	local context = { Data = data, Sanctuary = sanctuary, Progression = progression, Store = store, Remotes = remotes, Advance = advance }
	function context.AddPlayer(id)
		local player = object("Player", "Player" .. tostring(id))
		player.UserId = id
		player.Parent = players
		table.insert(players._players, player)
		players.PlayerAdded:Fire(player)
		advance(0)
		return player
	end
	function context.RemovePlayer(player)
		player.Parent = nil
		local index = table.find(players._players, player)
		if index then table.remove(players._players, index) end
		players.PlayerRemoving:Fire(player)
		advance(0)
	end
	function context.Shutdown()
		for _, closer in ipairs(gameMock.Closers) do spawn(closer) end
		advance(26)
	end
	function context.Request(name, player, ...)
		remotes:FindFirstChild(name).OnServerEvent:Fire(player, ...)
		advance(0)
	end
	return context
end

local tests = 0
local function test(name, callback)
	callback()
	tests += 1
	print("PASS", name)
end

local function record(uid, creatureId, income)
	return { Uid = uid, CreatureId = creatureId, Mutation = "Normal", Size = "Normal", IncomePerSec = income, CapturedAt = 1700000000 }
end

test("new production profile acquires a lease and syncs initial state", function()
	local e = engine()
	local p = e.AddPlayer(1)
	local profile = assert(e.Data.Get(p))
	assert(profile.Coins == 150 and profile.Orbs.Comum == 25)
	assert(e.Store.Records.Player_1.Session.Id == "server-a")
	assert(p:GetAttribute("DataLoaded") == true)
	local messages = e.Remotes:FindFirstChild("StateUpdate").Messages
	assert(messages[#messages].Data.MaxRange == 47)
	assert(messages[#messages].Data.DataMode == "DataStore")
end)

test("clean departure saves the latest profile and releases its lease", function()
	local e = engine()
	local p = e.AddPlayer(2)
	e.Data.Get(p).Coins = 1234
	e.RemovePlayer(p)
	local saved = e.Store.Records.Player_2
	assert(saved.Data.Coins == 1234 and saved.Session == nil)
	local second = engine({ Store = e.Store, JobId = "server-b" })
	local rejoined = second.AddPlayer(2)
	assert(second.Data.Get(rejoined).Coins == 1234)
end)

test("foreign live session blocks loading without overwriting its data", function()
	local first = engine()
	first.AddPlayer(3)
	local writes = first.Store.Writes
	local second = engine({ Store = first.Store, JobId = "server-b" })
	local p = second.AddPlayer(3)
	second.Advance(7)
	assert(second.Data.Get(p) == nil and p.Kicked)
	assert(first.Store.Writes == writes)
	assert(first.Store.Records.Player_3.Session.Id == "server-a")
end)

test("unavailable DataStore never falls back to writable default data", function()
	local store = createStore(); store.Fail = true
	local e = engine({ Store = store })
	local p = e.AddPlayer(4)
	e.Advance(7)
	assert(e.Data.Get(p) == nil and p.Kicked)
	assert(store.Writes == 0 and store.Records.Player_4 == nil)
end)

test("corrupt or future-version data is preserved and rejected", function()
	for _, saved in ipairs({
		{ SchemaVersion = 2, Data = {} },
		{ SchemaVersion = 1, Data = { Coins = 999 } },
	}) do
		local store = createStore()
		store.Records.Player_5 = clone(saved)
		local e = engine({ Store = store })
		local p = e.AddPlayer(5)
		e.Advance(7)
		assert(e.Data.Get(p) == nil and p.Kicked and store.Writes == 0)
		assert(store.Records.Player_5.SchemaVersion == saved.SchemaVersion)
	end
end)

test("autosave renews its lease and saves current state", function()
	local e = engine()
	local p = e.AddPlayer(6)
	e.Data.Get(p).Coins = 456
	e.Advance(61)
	assert(e.Store.Records.Player_6.Data.Coins == 456)
	assert(e.Store.Records.Player_6.Session.ExpiresAt == 1700000240)
end)

test("lost session ownership freezes writes and preserves the other save", function()
	local e = engine()
	local p = e.AddPlayer(7)
	e.Store.Records.Player_7.Session.Id = "new-owner"
	e.Store.Records.Player_7.Data.Coins = 999
	e.Advance(61)
	assert(p.Kicked and e.Data.Get(p) == nil)
	assert(e.Store.Records.Player_7.Data.Coins == 999)
end)

test("save outage preserves the previous save and freezes before the lease expires", function()
	local e = engine()
	local p = e.AddPlayer(70)
	e.Data.Get(p).Coins = 999
	e.Store.Fail = true
	e.Advance(165)
	assert(p.Kicked and e.Data.Get(p) == nil)
	assert(e.Store.Records.Player_70.Data.Coins == 150)
	assert(e.Store.Records.Player_70.Session.ExpiresAt > 1700000165)
end)

test("failed profile initialization restores the original data and releases its lease", function()
	local e = engine()
	e.Data.OnLoaded(function(_, profile)
		profile.Coins = 999999
		error("Simulated initialization error")
	end)
	local p = e.AddPlayer(71)
	assert(p.Kicked and not p:GetAttribute("DataLoaded") and e.Data.Get(p) == nil)
	assert(e.Store.Records.Player_71.Data.Coins == 150)
	assert(e.Store.Records.Player_71.Session == nil)
end)

test("expired foreign session can be acquired without resetting its data", function()
	local first = engine()
	local p = first.AddPlayer(72)
	first.Data.Get(p).Coins = 789
	first.Advance(60)
	local second = engine({ Store = first.Store, JobId = "server-b", Time = 241 })
	local rejoined = second.AddPlayer(72)
	assert(second.Data.Get(rejoined).Coins == 789)
	assert(second.Store.Records.Player_72.Session.Id == "server-b")
end)

test("Studio sessions are ephemeral and never access the DataStore", function()
	local store = createStore(); store.Fail = true
	local e = engine({ Studio = true, Store = store })
	local p = e.AddPlayer(8)
	assert(e.Data.Get(p).Coins == 150)
	assert(p:GetAttribute("DataMode") == "StudioMemory")
	e.RemovePlayer(p)
	assert(store.Writes == 0)
end)

test("shutdown saves every player and releases all session leases", function()
	local e = engine()
	local a = e.AddPlayer(9)
	local b = e.AddPlayer(10)
	e.Data.Get(a).Coins = 901
	e.Data.Get(b).Coins = 1001
	e.Shutdown()
	assert(e.Store.Records.Player_9.Data.Coins == 901 and e.Store.Records.Player_9.Session == nil)
	assert(e.Store.Records.Player_10.Data.Coins == 1001 and e.Store.Records.Player_10.Session == nil)
end)

test("only equipped creatures generate income; elemental synergy is applied", function()
	local e = engine({ Studio = true })
	local records = {
		record("a", "Pyrokit", 10), record("b", "Pyrokit", 10), record("c", "Pyrokit", 10),
		record("d", "Pyrokit", 10), record("e", "Pyrokit", 10), record("f", "Pyrokit", 10),
	}
	local profile = { CapturedCreatures = records, SanctuarySlots = { "a", "b", "c" }, Rebirths = 0, Level = 1 }
	assert(e.Sanctuary.CalculateIncome(profile) == 37.5)
	profile.SanctuarySlots = { "a", "b", "c", "d", "e", "f" }
	assert(math.abs(e.Sanctuary.CalculateIncome(profile) - 96) < 1e-8)
	profile.SanctuarySlots = {}
	assert(e.Sanctuary.CalculateIncome(profile) == 0)
end)

test("starter trio receives its 40 percent income bonus", function()
	local e = engine({ Studio = true })
	local profile = {
		CapturedCreatures = { record("a", "Pyrokit", 10), record("b", "Aquapup", 10), record("c", "Sproutling", 10) },
		SanctuarySlots = { "a", "b", "c" }, Rebirths = 0, Level = 1,
	}
	assert(e.Sanctuary.CalculateIncome(profile) == 42)
end)

test("offline income is capped at eight hours and survives rejoin", function()
	local first = engine({ WithEconomy = true })
	local p = first.AddPlayer(11)
	assert(first.Sanctuary.AddCapture(p, record("one", "Pyrokit", 10)))
	first.RemovePlayer(p)
	local second = engine({ WithEconomy = true, Store = first.Store, JobId = "server-b", Time = 40000 })
	local rejoined = second.AddPlayer(11)
	local profile = second.Data.Get(rejoined)
	assert(profile.OfflineReward == 288000)
	assert(profile.Coins == 288150)
	assert(profile.CapturedCreatures[1].Uid == "one" and profile.IncomePerSec == 10)
end)

test("purchase validation forbids Master coin purchases and invalid quantities", function()
	local e = engine({ Studio = true, WithEconomy = true })
	local p = e.AddPlayer(12)
	e.Request("BuyOrb", p, "Mestre", 1)
	e.Request("BuyOrb", p, "Comum", -1)
	e.Request("BuyOrb", p, "Comum", 0 / 0)
	assert(e.Data.Get(p).Coins == 150 and e.Data.Get(p).Orbs.Mestre == nil)
	e.Advance(0.3)
	e.Request("BuyOrb", p, "Comum", 2)
	assert(e.Data.Get(p).Coins == 100 and e.Data.Get(p).Orbs.Comum == 27)
end)

test("training is rate limited and gives a recovery path when money/orbs run out", function()
	local e = engine({ Studio = true, WithEconomy = true })
	local p = e.AddPlayer(13)
	e.Data.Get(p).Coins = 0
	e.Request("TrainThrowPower", p)
	e.Request("TrainThrowPower", p)
	assert(e.Data.Get(p).Coins == 5 and e.Data.Get(p).ThrowStrength == 11)
	e.Advance(0.5)
	e.Request("TrainThrowPower", p)
	assert(e.Data.Get(p).Coins == 10 and e.Data.Get(p).ThrowStrength == 12)
end)

test("only owned creatures can be toggled into and out of the sanctuary", function()
	local e = engine({ Studio = true, WithEconomy = true })
	local p = e.AddPlayer(73)
	assert(e.Sanctuary.AddCapture(p, record("owned", "Pyrokit", 10)))
	e.Request("EquipToSanctuary", p, "forged")
	assert(#e.Data.Get(p).SanctuarySlots == 1)
	e.Advance(0.3)
	e.Request("EquipToSanctuary", p, "owned")
	assert(#e.Data.Get(p).SanctuarySlots == 0 and e.Data.Get(p).IncomePerSec == 0)
	e.Advance(0.3)
	e.Request("EquipToSanctuary", p, "owned")
	assert(#e.Data.Get(p).SanctuarySlots == 1 and e.Data.Get(p).IncomePerSec == 10)
	e.Advance(1)
	assert(e.Data.Get(p).Coins == 160)
end)

test("XP rollover advances levels and caps at level 100", function()
	local e = engine({ Studio = true, WithEconomy = true })
	local p = e.AddPlayer(14)
	assert(e.Progression.GrantXP(p, 110))
	assert(e.Data.Get(p).Level == 2 and e.Data.Get(p).XP == 10)
	e.Data.Get(p).Level = 99
	e.Data.Get(p).XP = 0
	e.Progression.GrantXP(p, 1000000000)
	assert(e.Data.Get(p).Level == 100 and e.Data.Get(p).XP == 0)
end)

print(string.format("All %d service scenarios passed.", tests))
