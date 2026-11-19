--!nocheck
-- Embedded production modules, not copies of their implementation.
local sources = {MonetizationService = __MONETIZATIONSERVICE_SOURCE__, TradeService = __TRADESERVICE_SOURCE__, AuctionService = __AUCTIONSERVICE_SOURCE__}
local tests = 0
local function check(value, message) assert(value, message or "assertion failed"); tests += 1 end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}; for key, child in value do result[key] = copy(child) end; return result
end
local function capture(uid) return {Uid = uid, CreatureId = "Sproutling", Mutation = "Normal", Size = "Normal", IncomePerSec = 8, CapturedAt = 1000, FusionStage = 0} end
local function profile(uid)
	return {Coins = 100, TotalCoinsEarned = 100, TotalCaptures = 1, Level = 15, XP = 0, Rebirths = 0,
		CapturedCreatures = if uid then {capture(uid)} else {}, SanctuarySlots = if uid then {uid} else {},
		Bestiary = {}, Orbs = {Comum = 25}, ExtraSanctuarySlots = 0, Boosts = {}, Consumables = {},
		OneTimeGrants = {}, ProcessedReceipts = {}, PendingTransactions = {}, AppliedTransactions = {},
		AutomationSettings = {}, Titles = {}, WeeklyPets = 0}
end
local function engine(options)
	options = options or {}
	local clock, serial = 0, 0
	local queue = {}
	local taskMock = {}
	function taskMock.spawn(callback, ...) table.insert(queue, {At = clock, Thread = coroutine.create(callback), Args = table.pack(...)}) end
	taskMock.defer = taskMock.spawn
	function taskMock.wait(seconds) return coroutine.yield(seconds or 0.03) end
	local function advance(seconds)
		local finish = clock + seconds; local guard = 0
		while true do
			local index, time = nil, math.huge
			for i, item in queue do if item.At < time then index, time = i, item.At end end
			if not index or time > finish then break end
			guard += 1; assert(guard < 10000, "scheduler runaway")
			local item = table.remove(queue, index); clock = item.At
			local ok, wait = coroutine.resume(item.Thread, table.unpack(item.Args, 1, item.Args.n)); assert(ok, tostring(wait))
			if coroutine.status(item.Thread) ~= "dead" then table.insert(queue, {At = clock + (wait or 0.03), Thread = item.Thread, Args = table.pack(wait)}) end
		end
		clock = finish
	end
	local function signal()
		local callbacks = {}; return {Connect = function(_, callback) table.insert(callbacks, callback); return {Disconnect = function() end} end,
			Fire = function(_, ...) for _, callback in callbacks do callback(...) end end}
	end
	local function node(name)
		local result = {Name = name, Children = {}}
		function result:WaitForChild(child) assert(self.Children[child], child); return self.Children[child] end
		function result:FindFirstChild(child) return self.Children[child] end
		return result
	end
	local players = {List = {}}
	function players:GetPlayers() return table.clone(self.List) end
	function players:GetPlayerByUserId(id) for _, player in self.List do if player.UserId == id then return player end end; return nil end
	local a = {UserId = 101, DisplayName = "Ana", Parent = players, InPlaza = true}
	local b = {UserId = 202, DisplayName = "Beto", Parent = players, InPlaza = true}
	local c = {UserId = 303, DisplayName = "Cris", Parent = players, InPlaza = true}
	players.List = {a, b, c}
	for _, player in players.List do function player:IsInGroupAsync() return false end end
	local shared = node("Shared")
	for _, name in {"ConfigGameplay", "ConfigMonetizacao"} do shared.Children[name] = node(name) end
	local storage = node("ReplicatedStorage"); storage.Children.Shared = shared
	local remotes = node("Remotes")
	for _, name in {"ActionFeedback", "TradeAction", "AuctionAction"} do
		local remote = {OnServerEvent = signal(), Messages = {}}
		function remote:FireClient(player, data) table.insert(self.Messages, {Player = player, Data = copy(data)}) end
		remotes.Children[name] = remote
	end
	local settings = {GroupId = 0, TradingPlaceId = 0, MaxInventoryCreatures = options.Capacity or 500, MaxSanctuarySlots = 24}
	local catalog = {SalesEnabled = false, Items = {
		{Key = "MasterOrb1", Kind = "Product", Id = 777, FulfillmentReady = true},
		{Key = "SanctuarySlot", Kind = "Product", Id = 778, FulfillmentReady = true},
		{Key = "PotionPack", Kind = "Product", Id = 779, FulfillmentReady = true},
		{Key = "StarterPack", Kind = "GamePass", Id = 600, FulfillmentReady = false},
	}}
	local journal = options.Journal or {}
	local failAfterCommit = options.FailAfterCommit
	local store = {}
	function store:UpdateAsync(key, transform)
		local updated = transform(copy(journal[key]))
		if updated ~= nil then journal[key] = copy(updated) end
		if failAfterCommit and updated and updated.State == "Committed" then failAfterCommit = false; error("lost commit response") end
		return copy(updated)
	end
	local market = {PromptGamePassPurchaseFinished = signal()}
	function market:UserOwnsGamePassAsync(_userId, _passId) return options.OwnsStarter == true end
	local data = {Profiles = {}, Durable = options.Durable or {}, Frozen = {}, Locks = {}, Loaded = {}, Removing = {}, Providers = {}, Saves = 0}
	for _, player in players.List do
		local initial = copy(data.Durable[player.UserId] or profile(if player == a then "a" elseif player == b then "b" else nil))
		data.Profiles[player] = initial; if not data.Durable[player.UserId] then data.Durable[player.UserId] = copy(initial) end
	end
	function data.Get(player) return if not data.Frozen[player] and not data.Leaving then data.Profiles[player] else nil end
	function data.IsLoaded(player) return not options.Loading and data.Get(player) ~= nil end
	function data.IsPersistent() return true end
	function data.IsBusy(player) return data.Locks[player] ~= nil end
	function data.TryLock(player, owner)
		if not data.Get(player) or (data.Locks[player] and data.Locks[player] ~= owner) then return false end
		data.Locks[player] = owner; return true
	end
	function data.Unlock(player, owner) if data.Locks[player] == owner then data.Locks[player] = nil end end
	function data.Freeze(player, _message) data.Frozen[player] = true end
	function data.Replace(player, snapshot) assert(data.Locks[player], "unlocked replacement"); if options.RejectReplace then return false end; data.Profiles[player] = copy(snapshot); return true end
	function data.SaveNow(player)
		if not data.Get(player) then return false end
		data.Saves += 1
		local fail = (options.FailSaveAt and data.Saves == options.FailSaveAt) or (options.FailAllSavesAfter and data.Saves >= options.FailAllSavesAfter)
		if not fail or options.FailAfterWrite then data.Durable[player.UserId] = copy(data.Profiles[player]) end
		return not fail
	end
	function data.Sync(_player) end
	function data.MarkDirty(_player) end
	function data.GetReservedSlots(p) local total = 0; for _, pending in p.PendingTransactions do total += pending.ReservedSlots or 0 end; return total end
	function data.GetInventoryCount(p) return #p.CapturedCreatures + data.GetReservedSlots(p) end
	function data.OnLoaded(callback) table.insert(data.Loaded, callback) end
	function data.OnRemoving(callback) table.insert(data.Removing, callback) end
	function data.AddSnapshotProvider(callback) table.insert(data.Providers, callback) end
	function data.AddCoins(player, amount) local p = data.Get(player); p.Coins += amount; p.TotalCoinsEarned += amount end
	local services = {Players = players, MarketplaceService = market, ReplicatedStorage = storage, DataStoreService = {GetDataStore = function() return store end},
		HttpService = {GenerateGUID = function() serial += 1; return tostring(serial) end}}
	local gameMock = {GetService = function(_, name) assert(services[name], name); return services[name] end}
	local environment = setmetatable({game = gameMock, os = setmetatable({time = function() return 1000 + math.floor(clock) end, clock = function() return clock end}, {__index = os}),
		task = taskMock, Enum = {ProductPurchaseDecision = {NotProcessedYet = "Pending", PurchaseGranted = "Granted"}},
		require = function(module) if module.Name == "ConfigGameplay" then return settings elseif module.Name == "ConfigMonetizacao" then return catalog else error(module.Name) end end}, {__index = getfenv(0)})
	local modules = {}
	for name, source in sources do local fn = assert(loadstring(source, name)); setfenv(fn, environment); modules[name] = fn() end
	local context = {Data = data, Remotes = remotes, Sanctuary = {Refresh = function() end},
		Biomes = {IsInTradingPlaza = function(player) return player.InPlaza end},
		Trade = modules.TradeService, Auction = modules.AuctionService, Monetization = modules.MonetizationService}
	modules.TradeService.Init(context); modules.AuctionService.Init(context); modules.MonetizationService.Init(context)
	local function load(player) for _, callback in data.Loaded do callback(player, data.Profiles[player]) end end
	local function leave(player)
		data.Frozen[player] = true
		for _, callback in data.Removing do callback(player, data.Profiles[player]) end
		data.Durable[player.UserId] = copy(data.Profiles[player]); player.Parent = nil
		local index = table.find(players.List, player); if index then table.remove(players.List, index) end
	end
	return {A = a, B = b, C = c, Data = data, Trade = modules.TradeService, Auction = modules.AuctionService, Mono = modules.MonetizationService,
		Advance = advance, Journal = journal, Catalog = catalog, Load = load, Leave = leave}
end

local function receipt(id, product) return {PlayerId = 101, ProductId = product or 777, PurchaseId = id or "receipt-1"} end
do
	local e = engine()
	check(e.Mono.ProcessReceipt(receipt()) == "Granted", "receipt not granted")
	check(e.Data.Get(e.A).Orbs.Mestre == 1)
	check(e.Mono.ProcessReceipt(receipt()) == "Granted")
	check(e.Data.Get(e.A).Orbs.Mestre == 1, "duplicate receipt granted twice")
	check(e.Mono.ProcessReceipt(receipt("wrong", 999)) == "Pending")
	check(e.Mono.ProcessReceipt({PlayerId = 999, ProductId = 777, PurchaseId = "gone"}) == "Pending")
	check(e.Mono.ProcessReceipt(receipt("slot", 778)) == "Granted")
	check(e.Data.Get(e.A).Consumables.SanctuarySlot == 1)
	check(e.Mono.ProcessReceipt(receipt("potions", 779)) == "Granted")
	check(e.Data.Get(e.A).Consumables.PotionLuck3 == 1 and e.Data.Get(e.A).Consumables.PotionCoins3 == 1)
end
do
	local e = engine({RejectReplace = true})
	check(e.Mono.ProcessReceipt(receipt()) == "Pending", "rejected profile replacement acknowledged receipt")
	check(e.Data.Profiles[e.A].Orbs.Mestre == nil)
end
for _, afterWrite in {false, true} do
	local e = engine({FailSaveAt = 1, FailAfterWrite = afterWrite})
	check(e.Mono.ProcessReceipt(receipt()) == "Pending")
	check(e.Data.Frozen[e.A], "uncertain receipt state was not frozen")
	local recovered = engine({Durable = e.Data.Durable, Journal = e.Journal})
	check(recovered.Mono.ProcessReceipt(receipt()) == "Granted")
	check(recovered.Data.Get(recovered.A).Orbs.Mestre == 1, "receipt retry duplicated grant")
end
do
	local e = engine({OwnsStarter = true})
	e.Mono.RefreshBenefits(e.A); e.Mono.RefreshBenefits(e.A)
	check(e.Data.Get(e.A).Coins == 50100)
	check(e.Data.Get(e.A).Orbs.Rubi == 10)
	check(#e.Data.Get(e.A).CapturedCreatures == 2)
	check(e.Mono.GetBenefits(e.A).StarterPack == true)
end
do
	local e = engine({OwnsStarter = true, Loading = true})
	e.Mono.RefreshBenefits(e.A)
	check(e.Mono.GetBenefits(e.A).StarterPack == true, "benefit unavailable during trusted load callback")
end

local function action(e, player, name, payload) e.Advance(0.2); e.Trade.HandleAction(player, name, payload) end
local function offered(e)
	action(e, e.A, "Invite", {TargetUserId = e.B.UserId})
	local id = e.Trade.GetSnapshot(e.A).SessionId
	action(e, e.B, "Accept", {SessionId = id})
	action(e, e.A, "Offer", {SessionId = id, Revision = 1, Uids = {"a"}})
	action(e, e.B, "Offer", {SessionId = id, Revision = 2, Uids = {"b"}})
	return id
end
local function ready(e, id)
	action(e, e.A, "Ready", {SessionId = id, Revision = 3}); action(e, e.B, "Ready", {SessionId = id, Revision = 3})
end
local function confirm(e, id)
	e.Advance(3.1); action(e, e.A, "Confirm", {SessionId = id, Revision = 3}); action(e, e.B, "Confirm", {SessionId = id, Revision = 3}); e.Advance(0)
end
do
	local e = engine(); local id = offered(e); ready(e, id)
	action(e, e.A, "Confirm", {SessionId = id, Revision = 3})
	check(e.Trade.GetSnapshot(e.A).MyConfirmed == false, "three-second review bypassed")
	confirm(e, id)
	check(e.Data.Get(e.A).CapturedCreatures[1].Uid == "b")
	check(e.Data.Get(e.B).CapturedCreatures[1].Uid == "a")
	check(e.Data.Get(e.A).Coins == 100 and e.Data.Get(e.B).Coins == 100)
	check(#e.Data.Get(e.A).SanctuarySlots == 0)
	check(e.Journal[id].State == "Committed")
	e.Trade.RecoverPlayer(e.A, e.Data.Get(e.A)); check(#e.Data.Get(e.A).CapturedCreatures == 1)
end
do
	local e = engine(); local id = offered(e); ready(e, id)
	action(e, e.A, "Offer", {SessionId = id, Revision = 3, Uids = {}})
	check(e.Trade.GetSnapshot(e.A).Revision == 4 and e.Trade.GetSnapshot(e.A).Phase == "Offering")
	check(not e.Data.IsBusy(e.A) and not e.Data.IsBusy(e.B))
	action(e, e.B, "Confirm", {SessionId = id, Revision = 3})
	check(e.Data.Get(e.A).CapturedCreatures[1].Uid == "a", "stale confirmation accepted")
	action(e, e.A, "Offer", {SessionId = id, Revision = 4, Uids = {Named = "a"}})
	check(e.Trade.GetSnapshot(e.A).Revision == 4, "dictionary offer bypassed dense-array validation")
end
do
	local e = engine({FailAllSavesAfter = 2}); local id = offered(e); ready(e, id); confirm(e, id)
	check(e.Journal[id].State == "Aborted", "failed prepare committed")
	local recovered = engine({Durable = e.Data.Durable, Journal = e.Journal}); recovered.Load(recovered.A); recovered.Load(recovered.B)
	check(recovered.Data.Get(recovered.A).CapturedCreatures[1].Uid == "a")
	check(recovered.Data.Get(recovered.B).CapturedCreatures[1].Uid == "b")
end
for _, commitResponseLost in {false, true} do
	local e = engine({FailAllSavesAfter = if commitResponseLost then nil else 3, FailAfterCommit = commitResponseLost})
	local id = offered(e); ready(e, id); confirm(e, id)
	check(e.Journal[id].State == "Committed")
	local recovered = engine({Durable = e.Data.Durable, Journal = e.Journal}); recovered.Load(recovered.A); recovered.Load(recovered.B)
	check(recovered.Data.Get(recovered.A).CapturedCreatures[1].Uid == "b", "committed trade not recovered")
	check(recovered.Data.Get(recovered.B).CapturedCreatures[1].Uid == "a")
	check(#recovered.Data.Get(recovered.A).CapturedCreatures == 1 and #recovered.Data.Get(recovered.B).CapturedCreatures == 1)
end
do
	local e = engine(); local id = offered(e); ready(e, id); e.Leave(e.B); e.Advance(0)
	check(e.Data.Get(e.A).CapturedCreatures[1].Uid == "a")
	check(not e.Data.IsBusy(e.A), "disconnect retained review lock")
end

local function auction(e, player, name, payload) e.Advance(0.3); e.Auction.HandleAction(player, name, payload); e.Advance(0) end
local function listed(e)
	auction(e, e.A, "List", {Uid = "a", MinimumBid = 10})
	return e.Auction.GetSnapshot(e.A)[1].AuctionId
end
do
	local e = engine(); local id = listed(e)
	check(#e.Data.Get(e.A).CapturedCreatures == 0 and e.Data.GetReservedSlots(e.Data.Get(e.A)) == 1)
	auction(e, e.B, "Bid", {AuctionId = id, Amount = 20})
	check(e.Data.Get(e.B).Coins == 80)
	auction(e, e.C, "Bid", {AuctionId = id, Amount = 30})
	check(e.Data.Get(e.B).Coins == 100, "outbid funds were not returned")
	e.Advance(121)
	check(e.Data.Get(e.A).Coins == 130 and e.Data.Get(e.C).Coins == 70)
	check(e.Data.Get(e.C).CapturedCreatures[1].Uid == "a")
	check(e.Data.Get(e.A).TotalCoinsEarned == 100, "auction transfer inflated lifetime coins")
	check(e.Data.Get(e.A).Coins + e.Data.Get(e.B).Coins + e.Data.Get(e.C).Coins == 300)
	check(#e.Auction.GetSnapshot(e.A) == 0)
end
do
	local e = engine(); local id = listed(e)
	auction(e, e.B, "Bid", {AuctionId = id, Amount = 20}); auction(e, e.B, "Bid", {AuctionId = id, Amount = 25})
	check(e.Data.Get(e.B).Coins == 75, "raising own bid debited full amount twice")
	local recovered = engine({Durable = e.Data.Durable, Journal = e.Journal}); recovered.Load(recovered.A); recovered.Load(recovered.B)
	check(recovered.Data.Get(recovered.A).CapturedCreatures[1].Uid == "a", "open auction asset lost on restart")
	check(recovered.Data.Get(recovered.B).Coins == 100, "open auction escrow lost on restart")
end
do
	local e = engine(); local id = listed(e); auction(e, e.A, "Cancel", {AuctionId = id})
	check(e.Data.Get(e.A).CapturedCreatures[1].Uid == "a")
	check(e.Data.Get(e.A).PendingTransactions[id] == nil)
end
do
	local e = engine(); local id = listed(e); auction(e, e.B, "Bid", {AuctionId = id, Amount = 20}); e.Leave(e.B); e.Advance(0)
	check(e.Data.Get(e.A).CapturedCreatures[1].Uid == "a")
	local recovered = engine({Durable = e.Data.Durable, Journal = e.Journal}); recovered.Load(recovered.B)
	check(recovered.Data.Get(recovered.B).Coins == 100, "departing bidder refund lost")
end
do
	local e = engine({Capacity = 1}); local id = listed(e)
	auction(e, e.B, "Bid", {AuctionId = id, Amount = 20})
	check(e.Data.Get(e.B).Coins == 100, "full inventory bid accepted")
	check(e.Auction.GetSnapshot(e.A)[1].HighestBid == 0)
end
do
	local e = engine({Capacity = 2})
	local p = e.Data.Get(e.A)
	p.PendingTransactions.other = {Kind = "Auction", CoordinatorKey = "other", Receive = {}, CoinsDelta = 0, ReservedSlots = 1}
	local valid = e.Trade.ValidatePatch(p, {GiveUids = {}, Receive = {capture("incoming")}, CoinsDelta = 0})
	check(not valid, "incoming trade ignored a different auction's reserved slot")
	valid = e.Trade.ValidatePatch(p, {GiveUids = {}, Receive = {capture("incoming")}, CoinsDelta = 0}, "other")
	check(valid, "settlement counted its own incoming reservation twice")
	valid = e.Trade.ValidatePatch(p, {GiveUids = {}, Receive = {capture("a")}, CoinsDelta = 0})
	check(not valid, "duplicate received UID accepted")
end
for _, afterWrite in {false, true} do
	local e = engine({FailSaveAt = 2, FailAfterWrite = afterWrite}); local id = listed(e)
	auction(e, e.B, "Bid", {AuctionId = id, Amount = 20})
	local recovered = engine({Durable = e.Data.Durable, Journal = e.Journal}); recovered.Load(recovered.A); recovered.Load(recovered.B)
	check(recovered.Data.Get(recovered.A).CapturedCreatures[1].Uid == "a")
	check(recovered.Data.Get(recovered.B).Coins == 100, "uncertain bid write lost or duplicated refund")
end
print(string.format("Economy/transactions: %d scenarios passed", tests))
