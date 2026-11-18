--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local SanctuaryService = {}
local dataService: any
local worldService: any

function SanctuaryService.GetSlotCapacity(profile: any): number
	return Config.Constants.BaseSanctuarySlots + (if profile.Level >= 5 then 1 else 0) + (if profile.Level >= 15 then 1 else 0)
end

function SanctuaryService.CalculateIncome(profile: any): number
	local records: { [string]: any } = {}
	for _, record in ipairs(profile.CapturedCreatures) do
		records[record.Uid] = record
	end
	local elementCounts: { [string]: number } = {}
	local equipped = {}
	local seen = {}
	for index, uid in ipairs(profile.SanctuarySlots) do
		if index > SanctuaryService.GetSlotCapacity(profile) then
			break
		end
		local record = records[uid]
		local definition = record and Config.Creatures[record.CreatureId]
		if definition and not seen[uid] then
			seen[uid] = true
			table.insert(equipped, record)
			elementCounts[definition.Element] = (elementCounts[definition.Element] or 0) + 1
		end
	end
	local starterTrio = false
	local starters = { Pyrokit = false, Aquapup = false, Sproutling = false }
	for _, record in ipairs(equipped) do
		if starters[record.CreatureId] ~= nil then
			starters[record.CreatureId] = true
		end
	end
	starterTrio = starters.Pyrokit and starters.Aquapup and starters.Sproutling
	local income = 0
	for _, record in ipairs(equipped) do
		local count = elementCounts[Config.Creatures[record.CreatureId].Element]
		local groupBonus = if count >= 6 then 1.6 elseif count >= 3 then 1.25 else 1
		income += record.IncomePerSec * groupBonus
	end
	return income * (if starterTrio then 1.4 else 1) * (1 + profile.Rebirths)
end

function SanctuaryService.Refresh(player: Player)
	local profile = dataService.Get(player)
	if profile then
		profile.IncomePerSec = SanctuaryService.CalculateIncome(profile)
		worldService.UpdateSanctuary(player, profile)
	end
end

function SanctuaryService.CanCapture(player: Player): boolean
	local profile = dataService.Get(player)
	return profile ~= nil and #profile.CapturedCreatures < (Config.Constants.MaxInventoryCreatures or 500)
end

function SanctuaryService.AddCapture(player: Player, record: any): boolean
	local profile = dataService.Get(player)
	if not profile or not SanctuaryService.CanCapture(player) then
		return false
	end
	table.insert(profile.CapturedCreatures, record)
	profile.Bestiary[record.CreatureId] = true
	if #profile.SanctuarySlots < SanctuaryService.GetSlotCapacity(profile) then
		table.insert(profile.SanctuarySlots, record.Uid)
	end
	SanctuaryService.Refresh(player)
	dataService.MarkDirty(player)
	return true
end

function SanctuaryService.Init(service: any, world: any)
	dataService = service
	worldService = world
	dataService.OnLoaded(function(player: Player, profile: any)
		worldService.AssignSanctuary(player)
		profile.IncomePerSec = SanctuaryService.CalculateIncome(profile)
		local elapsed = math.clamp(os.time() - profile.LastSeen, 0, Config.Constants.MaxOfflineSeconds)
		-- No offline grant in ephemeral Studio sessions (LastSeen is initialized at join).
		profile.OfflineReward = math.floor(elapsed * profile.IncomePerSec)
		profile.Coins += profile.OfflineReward
		profile.LastSeen = os.time()
		worldService.UpdateSanctuary(player, profile)
	end)
	dataService.OnRemoving(function(player: Player)
		worldService.ReleaseSanctuary(player)
	end)
	local remoteFolder = ReplicatedStorage:WaitForChild("Remotes")
	local lastEquip: { [Player]: number } = {}
	(remoteFolder:WaitForChild("EquipToSanctuary") :: RemoteEvent).OnServerEvent:Connect(function(player: Player, uid: any)
		if typeof(uid) ~= "string" or #uid > 80 then
			return
		end
		local now = os.clock()
		if now - (lastEquip[player] or -math.huge) < 0.25 then
			return
		end
		lastEquip[player] = now
		local profile = dataService.Get(player)
		if not profile then
			return
		end
		local exists = false
		for _, record in ipairs(profile.CapturedCreatures) do
			if record.Uid == uid then
				exists = true
				break
			end
		end
		if not exists then
			return
		end
		local slot = table.find(profile.SanctuarySlots, uid)
		if slot then
			table.remove(profile.SanctuarySlots, slot)
		elseif #profile.SanctuarySlots < SanctuaryService.GetSlotCapacity(profile) then
			table.insert(profile.SanctuarySlots, uid)
		else
			(remoteFolder:WaitForChild("ActionFeedback") :: RemoteEvent):FireClient(player, { Message = "Seu Santuário está cheio. Desequipe uma criatura primeiro.", Kind = "Error" })
			return
		end
		SanctuaryService.Refresh(player)
		dataService.MarkDirty(player)
		dataService.Sync(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastEquip[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local profile = dataService.Get(player)
				if profile then
					profile.IncomePerSec = SanctuaryService.CalculateIncome(profile)
					profile.Coins += profile.IncomePerSec
					dataService.Sync(player)
				end
			end
		end
	end)
end

return SanctuaryService
