--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local GameplayMath = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameplayMath"))

local SanctuaryService = {}
local dataService: any
local worldService: any
local context: any = nil
local function benefits(player: Player): any
	return if context and context.Monetization then context.Monetization.GetBenefits(player) else {}
end

function SanctuaryService.GetSlotCapacity(profile: any, playerBenefits: any?): number
	if GameplayMath.GetSlotCapacity then return GameplayMath.GetSlotCapacity(profile, playerBenefits or {}) end
	return Config.Constants.BaseSanctuarySlots + (if profile.Level >= 5 then 1 else 0) + (if profile.Level >= 15 then 1 else 0)
end

function SanctuaryService.CalculateBaseIncome(profile: any, playerBenefits: any?): number
	local records: { [string]: any } = {}
	for _, record in ipairs(profile.CapturedCreatures) do
		records[record.Uid] = record
	end
	local elementCounts: { [string]: number } = {}
	local equipped = {}
	local seen = {}
	for index, uid in ipairs(profile.SanctuarySlots) do
		if index > SanctuaryService.GetSlotCapacity(profile, playerBenefits) then
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
	return income * (if starterTrio then 1.4 else 1)
end

function SanctuaryService.CalculateIncome(profile: any, playerBenefits: any?, now: number?): number
	local multiplier = if GameplayMath.GetIncomeMultiplier then GameplayMath.GetIncomeMultiplier(profile, playerBenefits or {}, now or os.time()) else 1 + profile.Rebirths
	return SanctuaryService.CalculateBaseIncome(profile, playerBenefits) * multiplier
end

function SanctuaryService.Refresh(player: Player)
	local profile = dataService.Get(player)
	if profile then
		profile.IncomePerSec = SanctuaryService.CalculateIncome(profile, benefits(player))
		worldService.UpdateSanctuary(player, profile)
	end
end

function SanctuaryService.CanCapture(player: Player): boolean
	local profile = dataService.Get(player)
	if not profile then return false end
	local count = if dataService.GetInventoryCount then dataService.GetInventoryCount(profile) else #profile.CapturedCreatures
	return count < (Config.Constants.MaxInventoryCreatures or 500)
end

function SanctuaryService.AddCapture(player: Player, record: any): boolean
	local profile = dataService.Get(player)
	if not profile or not SanctuaryService.CanCapture(player) then
		return false
	end
	table.insert(profile.CapturedCreatures, record)
	profile.Bestiary[record.CreatureId] = true
	if #profile.SanctuarySlots < SanctuaryService.GetSlotCapacity(profile, benefits(player)) then
		table.insert(profile.SanctuarySlots, record.Uid)
	end
	SanctuaryService.Refresh(player)
	dataService.MarkDirty(player)
	return true
end

function SanctuaryService.Init(service: any, world: any, ctx: any?)
	dataService = service
	worldService = world
	context = ctx
	dataService.OnLoaded(function(player: Player, profile: any)
		worldService.AssignSanctuary(player)
		local playerBenefits = benefits(player)
		profile.IncomePerSec = SanctuaryService.CalculateIncome(profile, playerBenefits)
		local elapsed = math.clamp(os.time() - profile.LastSeen, 0, Config.Constants.MaxOfflineSeconds)
		-- No offline grant in ephemeral Studio sessions (LastSeen is initialized at join).
		profile.OfflineReward = if GameplayMath.GetOfflineIncome then math.floor(GameplayMath.GetOfflineIncome(profile, SanctuaryService.CalculateBaseIncome(profile, playerBenefits), elapsed, playerBenefits, os.time())) else math.floor(elapsed * profile.IncomePerSec)
		if service.AddCoins then service.AddCoins(player, profile.OfflineReward) else profile.Coins += profile.OfflineReward end
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
		if not service.IsLoaded(player) or (service.IsBusy and service.IsBusy(player)) then return end
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
		elseif #profile.SanctuarySlots < SanctuaryService.GetSlotCapacity(profile, benefits(player)) then
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
	if service.AddSnapshotProvider then service.AddSnapshotProvider(function(player: Player, profile: any)
		return {SlotCapacity = SanctuaryService.GetSlotCapacity(profile, benefits(player))}
	end) end
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local profile = dataService.Get(player)
				if profile and (not (service.IsBusy and service.IsBusy(player)) or (player.GetAttribute and player:GetAttribute("FlightInProgress") == true)) then
					profile.IncomePerSec = SanctuaryService.CalculateIncome(profile, benefits(player))
					if service.AddCoins then service.AddCoins(player, profile.IncomePerSec) else profile.Coins += profile.IncomePerSec end
					dataService.Sync(player)
				end
			end
		end
	end)
end

return SanctuaryService
