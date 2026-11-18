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
}

type LoadedCallback = (Player, Profile) -> ()
local DataService = {}
local profiles: { [Player]: Profile } = {}
local leaving: { [Player]: boolean } = {}
local saving: { [Player]: boolean } = {}
local removalStarted: { [Player]: boolean } = {}
local loading: { [Player]: boolean } = {}
local leaseExpires: { [Player]: number } = {}
local loadedCallbacks: { LoadedCallback } = {}
local removingCallbacks: { LoadedCallback } = {}
local remotes: Folder
local store: GlobalDataStore?
local initialized = false
local shuttingDown = false
local persistent = false
local sessionId = if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false)
local SCHEMA_VERSION = 1

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
	}
end

-- Reject incompatible/corrupt saves rather than replacing them with a fresh profile.
local function decode(envelope: any): Profile
	assert(type(envelope) == "table", "Invalid saved profile envelope")
	assert(envelope.SchemaVersion == SCHEMA_VERSION, "Unsupported saved profile version")
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
	assert(result.Level >= 1 and result.Level <= Settings.MaxLevel, "Invalid saved level")
	assert(result.Level % 1 == 0, "Non-integral saved level")
	assert(type(Config.Orbs[result.EquippedOrb]) == "table", "Unknown equipped orb")
	for orbId, quantity in pairs(result.Orbs) do
		assert(type(orbId) == "string" and Config.Orbs[orbId] ~= nil, "Unknown saved orb")
		assert(finite(quantity) and quantity >= 0 and quantity % 1 == 0, "Invalid orb quantity")
	end
	local captureIds = {}
	for _, record in ipairs(result.CapturedCreatures) do
		assert(type(record) == "table" and type(record.Uid) == "string", "Invalid captured record")
		assert(not captureIds[record.Uid], "Duplicate captured record")
		assert(Config.Creatures[record.CreatureId] ~= nil, "Unknown saved creature")
		assert(type(record.Mutation) == "string" and type(record.Size) == "string", "Invalid variant")
		assert(finite(record.IncomePerSec) and record.IncomePerSec >= 0, "Invalid saved income")
		assert(finite(record.CapturedAt), "Invalid capture timestamp")
		captureIds[record.Uid] = true
	end
	local equippedIds = {}
	for _, uid in ipairs(result.SanctuarySlots) do
		assert(type(uid) == "string" and captureIds[uid] and not equippedIds[uid], "Invalid sanctuary slot")
		equippedIds[uid] = true
	end
	for key, value in pairs(result.Bestiary) do
		assert(type(key) == "string" and type(value) == "boolean", "Invalid bestiary")
	end
	for key, value in pairs(result.UnlockedBiomes) do
		assert(type(key) == "string" and type(value) == "boolean", "Invalid biome unlock")
	end
	result.OfflineReward = 0
	result.IncomePerSec = 0 -- Recomputed from equipped records by SanctuaryService.
	return result :: Profile
end

local function runCallbacks(callbacks: { LoadedCallback }, player: Player, profile: Profile): boolean
	for _, callback in ipairs(callbacks) do
		local ok, err = pcall(callback, player, profile)
		if not ok then
			warn("[DataService] Profile callback failed:", err)
			return false
		end
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
	return profiles[player] ~= nil and not leaving[player]
end

function DataService.MarkDirty(_player: Player)
	-- Every loaded session is saved periodically, even when idle, to renew its lease.
end

function DataService.Sync(player: Player)
	local profile = DataService.Get(player)
	if not profile or not player.Parent then
		return
	end
	local snapshot = copy(profile)
	snapshot.MaxRange = Config.GetMaxThrowRange(profile.ThrowStrength, profile.Level)
	snapshot.XPRequired = Config.GetXPRequiredForLevel(profile.Level)
	snapshot.DataMode = if persistent then "DataStore" else "StudioMemory"
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local coins = stats:FindFirstChild("Moedas") :: NumberValue
		local level = stats:FindFirstChild("Nivel") :: IntValue
		local captures = stats:FindFirstChild("Capturas") :: IntValue
		coins.Value = profile.Coins
		level.Value = profile.Level
		captures.Value = #profile.CapturedCreatures
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
	if not persistent then
		return true
	end
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
	local beforeCallbacks = copy(profile)
	if not runCallbacks(loadedCallbacks, player, profile) then
		-- A partially initialized session must not save partially awarded rewards.
		leaving[player] = true
		runCallbacks(removingCallbacks, player, profile)
		profiles[player] = beforeCallbacks
		save(player, true, true)
		profiles[player] = nil
		leaseExpires[player] = nil
		loading[player] = nil
		leaving[player] = nil
		player:Kick("Não foi possível iniciar sua sessão. Seu progresso anterior foi preservado; tente novamente.")
		return
	end
	player:SetAttribute("DataLoaded", true)
	DataService.Sync(player)
	loading[player] = nil
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
	leaving[player] = true
	runCallbacks(removingCallbacks, player, profile)
	if not save(player, true) then
		warn("[DataService] Could not save on departure:", player.UserId, "The last successful autosave is preserved.")
	end
	profiles[player] = nil
	leaving[player] = nil
	leaseExpires[player] = nil
	removalStarted[player] = nil
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
