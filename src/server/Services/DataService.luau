--!strict
-- Production profiles use a renewable UpdateAsync session lease. Studio is ephemeral by default.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Settings = Config.Constants

export type Capture = {
	Uid: string,
	CreatureId: string,
	Mutation: string,
	Size: string,
	IncomePerSec: number,
	CapturedAt: number,
	FusionStage: number?,
	SpawnChance: number?,
}

export type Profile = {
	Coins: number,
	Gems: number,
	XP: number,
	Level: number,
	Rebirths: number,
	ThrowStrength: number,
	PityBonus: number,
	EquippedOrb: string,
	Orbs: { [string]: number },
	CapturedCreatures: { Capture },
	SanctuarySlots: { string },
	Bestiary: { [string]: boolean },
	ComboStreak: number,
	LastSeen: number,
	UnlockedBiomes: { [string]: boolean },
	OfflineReward: number,
	IncomePerSec: number,
	TotalCoinsEarned: number,
	TotalCaptures: number,
	FirstJoinedAt: number,
	ExtraSanctuarySlots: number,
	DailyStreak: number,
	LastDailyClaim: number,
	PlaytimeDay: number,
	OnlineSecondsToday: number,
	PlaytimeClaimed: {[string]: boolean},
	MissionDay: number,
	MissionCounters: {[string]: number},
	MissionClaimed: {[string]: boolean},
	BestiaryRewardClaimed: {[string]: boolean},
	RedeemedCodes: {[string]: boolean},
	Consumables: {[string]: number},
	Boosts: {[string]: {Multiplier: number, ExpiresAt: number}},
	Titles: {[string]: boolean},
	WeeklyPets: number,
	FusionReadyAt: number,
	OrbFragments: number,
	VIPLastClaim: number,
	GroupRewardClaimed: boolean,
	AutomationSettings: {[string]: boolean},
	OneTimeGrants: {[string]: boolean},
	ProcessedReceipts: {[string]: boolean},
	PendingTransactions: {[string]: any},
	AppliedTransactions: {[string]: boolean},
}

type LoadedCallback = (Player, Profile) -> ()
local DataService = {}
local profiles: { [Player]: Profile } = {}
local leaving: { [Player]: boolean } = {}
local saving: { [Player]: boolean } = {}
local removalStarted: { [Player]: boolean } = {}
local loading: { [Player]: boolean } = {}
local operationLocks: {[Player]: string} = {}
local initializationFailed: {[Player]: boolean} = {}
local snapshotProviders: {(Player, Profile) -> any} = {}
local leaseExpires: { [Player]: number } = {}
local loadedCallbacks: { LoadedCallback } = {}
local removingCallbacks: { LoadedCallback } = {}
local remotes: Folder
local store: GlobalDataStore?
local initialized = false
local shuttingDown = false
local persistent = false
local sessionId = if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false)
local SCHEMA_VERSION = 2

local function copy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in pairs(value) do
		result[key] = copy(child)
	end
	return result
end

local function finite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function newProfile(): Profile
	return {
		Coins = Settings.InitialCoins,
		Gems = 0,
		XP = 0,
		Level = 1,
		Rebirths = 0,
		ThrowStrength = Settings.InitialThrowStrength,
		PityBonus = 0,
		EquippedOrb = "Comum",
		Orbs = { Comum = Settings.InitialOrbs },
		CapturedCreatures = {},
		SanctuarySlots = {},
		Bestiary = {},
		ComboStreak = 0,
		LastSeen = os.time(),
		UnlockedBiomes = { PradariaSolar = true },
		OfflineReward = 0,
		IncomePerSec = 0,
		TotalCoinsEarned = Settings.InitialCoins,
		TotalCaptures = 0,
		FirstJoinedAt = os.time(),
		ExtraSanctuarySlots = 0,
		DailyStreak = 0, LastDailyClaim = 0,
		PlaytimeDay = 0, OnlineSecondsToday = 0, PlaytimeClaimed = {},
		MissionDay = 0, MissionCounters = {Captures = 0, Criticals = 0, Fusions = 0}, MissionClaimed = {},
		BestiaryRewardClaimed = {}, RedeemedCodes = {}, Consumables = {}, Boosts = {}, Titles = {},
		WeeklyPets = 0, FusionReadyAt = 0, OrbFragments = 0, VIPLastClaim = 0,
		GroupRewardClaimed = false,
		AutomationSettings = {Throw = false, Train = false, Fusion = false},
		OneTimeGrants = {}, ProcessedReceipts = {}, PendingTransactions = {}, AppliedTransactions = {},
	}
end

-- Reject incompatible/corrupt saves rather than replacing them with a fresh profile.
local function validKey(key: any): boolean
	return type(key) == "string" and #key > 0 and #key <= 200
end

local function validateBooleanMap(value: any, name: string)
	assert(type(value) == "table", "Invalid map: " .. name)
	local count = 0
	for key, flag in pairs(value) do
		count += 1
		assert(count <= 20000 and validKey(key) and type(flag) == "boolean", "Invalid map entry: " .. name)
	end
end

local function validateArray(value: any, name: string, limit: number)
	assert(type(value) == "table" and #value <= limit, "Invalid array: " .. name)
	local count = 0
	for index in pairs(value) do
		count += 1
		assert(type(index) == "number" and index % 1 == 0 and index >= 1 and index <= #value, "Sparse array: " .. name)
	end
	assert(count == #value, "Sparse array: " .. name)
end

local function validateCapture(record: any)
	assert(type(record) == "table" and validKey(record.Uid), "Invalid captured record")
	assert(Config.Creatures[record.CreatureId] ~= nil, "Unknown saved creature")
	assert(type(record.Mutation) == "string" and type(record.Size) == "string", "Invalid variant")
	assert(finite(record.IncomePerSec) and record.IncomePerSec >= 0, "Invalid saved income")
	assert(finite(record.CapturedAt) and record.CapturedAt >= 0, "Invalid capture timestamp")
	if record.FusionStage ~= nil then
		assert(finite(record.FusionStage) and record.FusionStage % 1 == 0 and record.FusionStage >= 0 and record.FusionStage <= 3, "Invalid fusion stage")
	end
	if record.SpawnChance ~= nil then
		assert(finite(record.SpawnChance) and record.SpawnChance > 0 and record.SpawnChance <= 1, "Invalid spawn probability")
	end
end

local function validateJournalValue(value: any, depth: number, budget: {number})
	budget[1] += 1
	assert(depth <= 9 and budget[1] <= 12000, "Transaction journal is too large")
	local kind = type(value)
	if kind == "table" then
		for key, child in pairs(value) do
			assert(validKey(key) or (type(key) == "number" and finite(key) and key >= 1 and key % 1 == 0), "Invalid journal key")
			validateJournalValue(child, depth + 1, budget)
		end
	elseif kind == "number" then assert(finite(value), "Invalid journal number")
	elseif kind == "string" then assert(#value <= 4096, "Invalid journal string")
	else assert(kind == "boolean", "Invalid journal value") end
end

local function decode(envelope: any): Profile
	assert(type(envelope) == "table", "Invalid saved profile envelope")
	assert(envelope.SchemaVersion == 1 or envelope.SchemaVersion == SCHEMA_VERSION, "Unsupported saved profile version")
	if envelope.Session ~= nil then
		assert(type(envelope.Session) == "table" and type(envelope.Session.Id) == "string" and finite(envelope.Session.ExpiresAt), "Invalid saved session lease")
	end
	local data = envelope.Data
	assert(type(data) == "table", "Missing saved profile data")
	for _, key in ipairs({ "Coins", "XP", "Level", "Orbs", "CapturedCreatures", "SanctuarySlots", "LastSeen" }) do
		assert(data[key] ~= nil, "Missing essential saved field: " .. key)
	end
	local result = newProfile() :: any
	for key, default in pairs(result) do
		local value = data[key]
		if value ~= nil then
			assert(type(value) == type(default), "Invalid saved field: " .. key)
			if type(default) == "number" then
				assert(finite(value) and value >= 0, "Invalid saved number: " .. key)
			end
			result[key] = copy(value)
		end
	end
	-- v1 did not record lifetime counters. Preserve at least its current balance
	-- and collection; no earlier spending/captures can be reconstructed.
	if data.TotalCoinsEarned == nil then result.TotalCoinsEarned = result.Coins end
	if data.TotalCaptures == nil then result.TotalCaptures = #result.CapturedCreatures end
	if data.FirstJoinedAt == nil then result.FirstJoinedAt = result.LastSeen end
	assert(result.Level >= 1 and result.Level <= Settings.MaxLevel, "Invalid saved level")
	assert(result.Level % 1 == 0, "Non-integral saved level")
	assert(type(Config.Orbs[result.EquippedOrb]) == "table", "Unknown equipped orb")
	for orbId, quantity in pairs(result.Orbs) do
		assert(type(orbId) == "string" and Config.Orbs[orbId] ~= nil, "Unknown saved orb")
		assert(finite(quantity) and quantity >= 0 and quantity % 1 == 0, "Invalid orb quantity")
	end
	validateArray(result.CapturedCreatures, "CapturedCreatures", Settings.MaxInventoryCreatures or 500)
	local captureIds = {}
	for _, record in ipairs(result.CapturedCreatures) do
		validateCapture(record)
		assert(not captureIds[record.Uid], "Duplicate captured record")
		captureIds[record.Uid] = true
	end
	validateArray(result.SanctuarySlots, "SanctuarySlots", Settings.MaxSanctuarySlots or 24)
	local equippedIds = {}
	for _, uid in ipairs(result.SanctuarySlots) do
		assert(type(uid) == "string" and captureIds[uid] and not equippedIds[uid], "Invalid sanctuary slot")
		equippedIds[uid] = true
	end
	for _, key in {"Bestiary", "UnlockedBiomes", "PlaytimeClaimed", "MissionClaimed", "BestiaryRewardClaimed", "RedeemedCodes", "Titles", "OneTimeGrants", "ProcessedReceipts", "AppliedTransactions"} do
		validateBooleanMap(result[key], key)
	end
	for _, key in {"TotalCaptures", "Rebirths", "ExtraSanctuarySlots", "DailyStreak", "PlaytimeDay", "OnlineSecondsToday", "MissionDay", "WeeklyPets", "OrbFragments"} do
		assert(result[key] % 1 == 0, "Non-integral saved field: " .. key)
	end
	assert(result.DailyStreak <= 7 and result.ExtraSanctuarySlots <= (Settings.MaxSanctuarySlots or 24), "Invalid progression capacity")
	for _, key in {"Captures", "Criticals", "Fusions"} do
		local amount = result.MissionCounters[key]
		if amount == nil then result.MissionCounters[key] = 0
		else assert(finite(amount) and amount >= 0 and amount % 1 == 0, "Invalid mission counter") end
	end
	for key, amount in pairs(result.MissionCounters) do
		assert((key == "Captures" or key == "Criticals" or key == "Fusions") and finite(amount), "Unknown mission counter")
	end
	for key, amount in pairs(result.Consumables) do
		assert(validKey(key) and finite(amount) and amount >= 0 and amount % 1 == 0, "Invalid consumable")
	end
	for key, boost in pairs(result.Boosts) do
		assert((key == "Luck" or key == "Coins" or key == "XP") and type(boost) == "table", "Invalid boost category")
		assert(finite(boost.Multiplier) and boost.Multiplier >= 1 and boost.Multiplier <= 1000, "Invalid boost multiplier")
		assert(finite(boost.ExpiresAt) and boost.ExpiresAt >= 0, "Invalid boost expiration")
	end
	for _, key in {"Throw", "Train", "Fusion"} do
		if result.AutomationSettings[key] == nil then result.AutomationSettings[key] = false end
		assert(type(result.AutomationSettings[key]) == "boolean", "Invalid automation setting")
	end
	for key in pairs(result.AutomationSettings) do assert(key == "Throw" or key == "Train" or key == "Fusion", "Unknown automation setting") end
	local pendingCount = 0
	for id, transaction in pairs(result.PendingTransactions) do
		pendingCount += 1
		assert(pendingCount <= 100 and validKey(id) and type(transaction) == "table", "Invalid pending transaction")
		validateJournalValue(transaction, 0, {0})
		if transaction.ReservedSlots ~= nil then assert(finite(transaction.ReservedSlots) and transaction.ReservedSlots >= 0 and transaction.ReservedSlots <= 500 and transaction.ReservedSlots % 1 == 0, "Invalid reserved slots") end
		if transaction.Receive ~= nil then
			validateArray(transaction.Receive, "Transaction.Receive", 500)
			for _, record in transaction.Receive do validateCapture(record) end
		end
	end
	result.OfflineReward = 0
	result.IncomePerSec = 0 -- Recomputed from equipped records by SanctuaryService.
	return result :: Profile
end

local function runCallbacks(callbacks: { LoadedCallback }, player: Player, profile: Profile, stopWhenLeaving: boolean?): boolean
	for _, callback in ipairs(callbacks) do
		-- Recovery and receipt callbacks can replace the validated profile table.
		local currentProfile = if stopWhenLeaving then profiles[player] or profile else profile
		local ok, err = pcall(callback, player, currentProfile)
		if not ok then
			warn("[DataService] Profile callback failed:", err)
			return false
		end
		if stopWhenLeaving and (leaving[player] or not player.Parent) then return false end
	end
	return true
end

function DataService.Get(player: Player): Profile?
	if leaving[player] then
		return nil
	end
	return profiles[player]
end

function DataService.IsLoaded(player: Player): boolean
	return profiles[player] ~= nil and not leaving[player] and not loading[player] and not removalStarted[player]
end

function DataService.IsPersistent(): boolean
	return persistent
end

function DataService.IsBusy(player: Player): boolean
	return operationLocks[player] ~= nil or loading[player] == true or leaving[player] == true or removalStarted[player] == true
end

function DataService.TryLock(player: Player, owner: string): boolean
	if type(owner) ~= "string" or #owner == 0 or #owner > 256 or not profiles[player] or leaving[player] or removalStarted[player] or operationLocks[player] then return false end
	operationLocks[player] = owner
	return true
end

function DataService.Unlock(player: Player, owner: string)
	if operationLocks[player] == owner then operationLocks[player] = nil end
end

function DataService.Freeze(player: Player, message: string?)
	leaving[player] = true
	operationLocks[player] = "Frozen"
	player:Kick(message or "Sua operação está sendo protegida. Entre novamente para reconciliar seu progresso salvo.")
end

function DataService.GetReservedSlots(profile: any): number
	local total = 0
	for _, transaction in pairs(profile.PendingTransactions or {}) do
		local reserved = transaction.ReservedSlots
		if finite(reserved) then total += math.max(0, math.floor(reserved))
		elseif type(transaction.Receive) == "table" then total += #transaction.Receive end
	end
	return total
end

function DataService.GetInventoryCount(profile: any): number
	return #(profile.CapturedCreatures or {}) + DataService.GetReservedSlots(profile)
end

function DataService.AddCoins(player: Player, amount: number): boolean
	local profile = DataService.Get(player)
	if not profile or not finite(amount) or amount <= 0 then return false end
	local balance = profile.Coins + amount
	local lifetime = profile.TotalCoinsEarned + amount
	if not finite(balance) or not finite(lifetime) then return false end
	profile.Coins = balance
	profile.TotalCoinsEarned = lifetime
	return true
end

function DataService.AddSnapshotProvider(callback: (Player, Profile) -> any)
	table.insert(snapshotProviders, callback)
end

function DataService.Replace(player: Player, replacement: any): boolean
	if not profiles[player] or leaving[player] or not operationLocks[player] then return false end
	local ok, validated = pcall(decode, {SchemaVersion = SCHEMA_VERSION, Data = replacement})
	if not ok then return false end
	validated.IncomePerSec = replacement.IncomePerSec
	validated.OfflineReward = replacement.OfflineReward
	profiles[player] = validated
	return true
end

function DataService.MarkDirty(_player: Player)
	-- Every loaded session is saved periodically, even when idle, to renew its lease.
end

local PUBLIC_FIELDS = {
	"Coins", "Gems", "XP", "Level", "Rebirths", "ThrowStrength", "PityBonus", "EquippedOrb", "Orbs",
	"CapturedCreatures", "SanctuarySlots", "Bestiary", "ComboStreak", "UnlockedBiomes", "OfflineReward", "IncomePerSec",
	"TotalCoinsEarned", "TotalCaptures", "ExtraSanctuarySlots", "DailyStreak", "LastDailyClaim", "PlaytimeDay",
	"OnlineSecondsToday", "PlaytimeClaimed", "MissionDay", "MissionCounters", "MissionClaimed", "BestiaryRewardClaimed",
	"Consumables", "Boosts", "Titles", "WeeklyPets", "FusionReadyAt", "OrbFragments", "VIPLastClaim", "AutomationSettings",
}

function DataService.Sync(player: Player, allowBusy: boolean?)
	local profile = DataService.Get(player)
	if not profile or not player.Parent or loading[player] or (DataService.IsBusy(player) and not allowBusy) then
		return
	end
	local snapshot: any = {}
	for _, key in PUBLIC_FIELDS do snapshot[key] = copy((profile :: any)[key]) end
	snapshot.MaxRange = Config.GetMaxThrowRange(profile.ThrowStrength, profile.Level)
	snapshot.XPRequired = Config.GetXPRequiredForLevel(profile.Level)
	snapshot.DataMode = if persistent then "DataStore" else "StudioMemory"
	snapshot.ServerTime = os.time()
	snapshot.InventoryCapacity = Settings.MaxInventoryCreatures or 500
	snapshot.InventoryReservedSlots = DataService.GetReservedSlots(profile)
	snapshot.SlotCapacity = math.min(Settings.MaxSanctuarySlots or 24, Settings.BaseSanctuarySlots + profile.ExtraSanctuarySlots + (if profile.Level >= 5 then 1 else 0) + (if profile.Level >= 15 then 1 else 0))
	for _, provider in snapshotProviders do
		local ok, extension = pcall(provider, player, profile)
		if ok and type(extension) == "table" then
			for key, value in extension do snapshot[key] = copy(value) end
		elseif not ok then warn("[DataService] Snapshot provider failed:", extension) end
	end
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local coins = stats:FindFirstChild("Moedas") :: NumberValue
		local level = stats:FindFirstChild("Nivel") :: IntValue
		local captures = stats:FindFirstChild("Capturas") :: IntValue
		coins.Value = profile.Coins
		level.Value = profile.Level
		captures.Value = profile.TotalCaptures
	end
	local stateUpdate = remotes:WaitForChild("StateUpdate") :: RemoteEvent
	stateUpdate:FireClient(player, snapshot)
end

function DataService.OnLoaded(callback: LoadedCallback)
	table.insert(loadedCallbacks, callback)
	for player, profile in pairs(profiles) do
		if not leaving[player] then
			callback(player, profile)
		end
	end
end

function DataService.OnRemoving(callback: LoadedCallback)
	table.insert(removingCallbacks, callback)
end

local function save(player: Player, release: boolean, preserveLastSeen: boolean?): boolean
	local start = os.clock()
	while saving[player] do
		if os.clock() - start > 20 then
			return false
		end
		task.wait(0.1)
	end
	local profile = profiles[player]
	if not profile then
		return true
	end
	saving[player] = true
	local snapshot = copy(profile)
	if not preserveLastSeen then
		snapshot.LastSeen = os.time()
	end
	local valid, validationError = pcall(decode, {SchemaVersion = SCHEMA_VERSION, Data = snapshot})
	if not valid then
		saving[player] = nil
		warn("[DataService] Refused an invalid outgoing profile:", validationError)
		if not release then DataService.Freeze(player, "Seu progresso anterior foi preservado. Entre novamente para continuar.") end
		return false
	end
	if not persistent then saving[player] = nil; return true end
	local success = false
	local lockLost = false
	for attempt = 1, 3 do
		local written = false
		local expiry = os.time() + Settings.SessionLeaseSeconds
		local ok, err = pcall(function()
			(store :: GlobalDataStore):UpdateAsync("Player_" .. player.UserId, function(previous: any)
				written = false -- UpdateAsync may invoke this callback more than once.
				if type(previous) ~= "table" or type(previous.Session) ~= "table" or previous.Session.Id ~= sessionId then
					lockLost = true
					return nil
				end
				written = true
				return {
					SchemaVersion = SCHEMA_VERSION,
					Data = snapshot,
					Session = if release then nil else { Id = sessionId, ExpiresAt = expiry },
				}
			end)
		end)
		if ok and written then
			success = true
			leaseExpires[player] = if release then nil else expiry
			break
		end
		if lockLost then
			warn("[DataService] Session lease lost for", player.UserId)
			break
		end
		warn("[DataService] Save attempt failed for", player.UserId, err)
		if attempt < 3 then
			task.wait(attempt)
		end
	end
	saving[player] = nil
	if not success and not release and (lockLost or os.time() >= (leaseExpires[player] or 0) - 15) then
		leaving[player] = true -- Freeze mutations immediately when ownership is uncertain.
		player:Kick("Sua sessão de dados perdeu a conexão. Entre novamente para proteger o progresso salvo.")
	end
	return success
end

function DataService.SaveNow(player: Player): boolean
	if not profiles[player] or leaving[player] or initializationFailed[player] then return false end
	return save(player, false)
end

-- Callback recovery can durably reconcile a trade/receipt before a later callback
-- fails. Release ownership using the latest stored Data, never an older snapshot.
local function releasePreservingData(player: Player)
	if not persistent then return end
	local ok, err = pcall(function()
		(store :: GlobalDataStore):UpdateAsync("Player_" .. player.UserId, function(previous: any)
			if type(previous) ~= "table" or type(previous.Session) ~= "table" or previous.Session.Id ~= sessionId then return nil end
			return {SchemaVersion = previous.SchemaVersion, Data = previous.Data, Session = nil}
		end)
	end)
	if not ok then warn("[DataService] Lease release deferred:", err) end
end

local function load(player: Player)
	if loading[player] or profiles[player] then
		return
	end
	loading[player] = true
	local profile: Profile?
	if persistent then
		for attempt = 1, 3 do
			local acquired = false
			local loadedProfile: Profile? = nil
			local busy = false
			local expiry = os.time() + Settings.SessionLeaseSeconds
			local ok, err = pcall(function()
				(store :: GlobalDataStore):UpdateAsync("Player_" .. player.UserId, function(previous: any)
					acquired = false
					loadedProfile = nil
					if previous ~= nil then
						loadedProfile = decode(previous)
						local lease = previous.Session
						if type(lease) == "table" and lease.Id ~= sessionId and finite(lease.ExpiresAt) and lease.ExpiresAt > os.time() then
							busy = true
							return nil
						end
					else
						loadedProfile = newProfile()
					end
					acquired = true
					return {
						SchemaVersion = SCHEMA_VERSION,
						Data = loadedProfile,
						Session = { Id = sessionId, ExpiresAt = expiry },
					}
				end)
			end)
			if ok and acquired and loadedProfile then
				profile = loadedProfile
				leaseExpires[player] = expiry
				break
			end
			warn("[DataService] Load blocked for", player.UserId, if busy then "another session owns the lease" else tostring(err))
			if attempt < 3 then
				task.wait(attempt * 2)
			end
		end
	else
		profile = newProfile()
	end
	if not profile then
		loading[player] = nil
		if player.Parent then
			player:Kick("Não foi possível carregar seus dados com segurança. Feche outra sessão e tente novamente em instantes.")
		end
		return
	end
	profiles[player] = profile
	if not player.Parent or shuttingDown then
		save(player, true)
		profiles[player] = nil
		loading[player] = nil
		return
	end
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for name, kind in pairs({ Moedas = "NumberValue", Nivel = "IntValue", Capturas = "IntValue" }) do
		local value = Instance.new(kind)
		value.Name = name
		value.Parent = stats
	end
	stats.Parent = player
	player:SetAttribute("DataMode", if persistent then "DataStore" else "StudioMemory")
	if not runCallbacks(loadedCallbacks, player, profile, true) then
		initializationFailed[player] = true
		leaving[player] = true
		runCallbacks(removingCallbacks, player, profile)
		releasePreservingData(player)
		profiles[player] = nil
		leaseExpires[player] = nil
		loading[player] = nil
		leaving[player] = nil
		operationLocks[player] = nil
		initializationFailed[player] = nil
		player:Kick("Não foi possível iniciar sua sessão. Seu progresso anterior foi preservado; tente novamente.")
		return
	end
	player:SetAttribute("DataLoaded", true)
	loading[player] = nil
	DataService.Sync(player)
end

local function remove(player: Player)
	if removalStarted[player] then
		while profiles[player] do
			task.wait(0.1)
		end
		return
	end
	local profile = profiles[player]
	if not profile then
		return
	end
	removalStarted[player] = true
	-- Let an already-owned receipt/consumable transaction finish its durable
	-- write or refund. New requests cannot acquire locks during this window.
	local deadline = os.clock() + 20
	while operationLocks[player] and not leaving[player] and os.clock() < deadline do task.wait(0.1) end
	profile = profiles[player] or profile
	leaving[player] = true
	runCallbacks(removingCallbacks, player, profile)
	if not save(player, true) then
		warn("[DataService] Could not save on departure:", player.UserId, "The last successful autosave is preserved.")
	end
	profiles[player] = nil
	leaving[player] = nil
	leaseExpires[player] = nil
	removalStarted[player] = nil
	operationLocks[player] = nil
	initializationFailed[player] = nil
end

function DataService.Init(remoteFolder: Folder)
	assert(not initialized, "DataService.Init must only run once")
	initialized = true
	remotes = remoteFolder
	persistent = not RunService:IsStudio() or Settings.StudioPersistence == true
	if persistent then
		store = DataStoreService:GetDataStore(Settings.DataStoreName)
	else
		warn("[Throw a Sphere] StudioMemory: progress resets when Play stops. Production always uses DataStore.")
	end
	local lastRequest: { [Player]: number } = {}
	(remotes:WaitForChild("RequestState") :: RemoteEvent).OnServerEvent:Connect(function(player: Player)
		local now = os.clock()
		if now - (lastRequest[player] or -math.huge) >= 1 then
			lastRequest[player] = now
			DataService.Sync(player)
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(load, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
		remove(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(load, player)
	end
	task.spawn(function()
		while not shuttingDown do
			task.wait(Settings.AutoSaveSeconds)
			for player in pairs(profiles) do
				if not leaving[player] then
					task.spawn(save, player, false)
				end
			end
		end
	end)
	if persistent then
		task.spawn(function()
			while not shuttingDown do
				task.wait(5)
				for player, expiry in pairs(leaseExpires) do
					if not leaving[player] and os.time() >= expiry - 15 then
						-- Freeze before expiration even if a DataStore request is stalled.
						leaving[player] = true
						player:Kick("Não foi possível renovar sua sessão de dados. Entre novamente para proteger o progresso salvo.")
					end
				end
			end
		end)
	end
	game:BindToClose(function()
		shuttingDown = true
		local pending = 0
		for player in pairs(profiles) do
			pending += 1
			task.spawn(function()
				remove(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while (pending > 0 or next(loading) ~= nil) and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
