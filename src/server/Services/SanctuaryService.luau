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

function SanctuaryService.HasArt(id: string): boolean
	return not context or not context.AuthoredCreatures or context.AuthoredCreatures[id] == true
end

local function recordIndex(records: {any}, uid: any): number?
	if type(uid) ~= "string" or #uid > 80 then return nil end
	for index, record in records do
		if record.Uid == uid then return index end
	end
	return nil
end

local function bestRecords(profile: any): {any}
	local candidates = {}
	for _, record in profile.CapturedCreatures do
		if SanctuaryService.HasArt(record.CreatureId) then table.insert(candidates, record) end
	end
	table.sort(candidates, function(a, b)
		if a.IncomePerSec ~= b.IncomePerSec then return a.IncomePerSec > b.IncomePerSec end
		return a.Uid < b.Uid
	end)
	return candidates
end

function SanctuaryService.GetSlotCapacity(profile: any, playerBenefits: any?): number
	if GameplayMath.GetSlotCapacity then return GameplayMath.GetSlotCapacity(profile, playerBenefits or {}) end
	return Config.Constants.BaseSanctuarySlots + (if profile.Level >= 5 then 1 else 0) + (if profile.Level >= 15 then 1 else 0)
end

function SanctuaryService.CalculateBaseIncome(profile: any, playerBenefits: any?, shares: {[string]: number}?): number
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
		if definition and not seen[uid] and (SanctuaryService.HasArt(record.CreatureId) or (context and context.AuthoredCreatures and not next(context.AuthoredCreatures))) then
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
		local share = record.IncomePerSec * groupBonus
		income += share
		if shares then shares[record.Uid] = share * (if starterTrio then 1.4 else 1) end
	end
	return income * (if starterTrio then 1.4 else 1)
end

function SanctuaryService.CalculateIncome(profile: any, playerBenefits: any?, now: number?, shares: {[string]: number}?): number
	local multiplier = if GameplayMath.GetIncomeMultiplier then GameplayMath.GetIncomeMultiplier(profile, playerBenefits or {}, now or os.time()) else 1 + profile.Rebirths
	local income = SanctuaryService.CalculateBaseIncome(profile, playerBenefits, shares) * multiplier
	if shares then for uid, share in shares do shares[uid] = share * multiplier end end
	return income
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
	if not profile or not SanctuaryService.HasArt(record.CreatureId) or not SanctuaryService.CanCapture(player) then
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

function SanctuaryService.Manage(player: Player, action: any, uid: any, outgoing: any): (boolean, string)
	if action ~= "Best" and action ~= "Replace" and action ~= "Sell" then return false, "Ação inválida." end
	if not dataService.IsLoaded(player) or dataService.IsBusy(player) then return false, "Aguarde a ação atual." end
	local profile = dataService.Get(player)
	if not profile then return false, "Carregando suas criaturas." end
	local slots, records = profile.SanctuarySlots, profile.CapturedCreatures
	if action == "Best" then
		local nextSlots = {}
		local capacity = SanctuaryService.GetSlotCapacity(profile, benefits(player))
		for index, record in bestRecords(profile) do
			if index > capacity then break end
			table.insert(nextSlots, record.Uid)
		end
		if #nextSlots == 0 then return false, "Nenhuma criatura com modelo disponível." end
		profile.SanctuarySlots = nextSlots
	elseif action == "Replace" then
		local index = recordIndex(records, uid)
		local slot = if type(outgoing) == "string" and #outgoing <= 80 then table.find(slots, outgoing) else nil
		if not index or not slot or table.find(slots, uid) or not SanctuaryService.HasArt(records[index].CreatureId) then
			return false, "Atualize a seleção e escolha novamente."
		end
		slots[slot] = uid
	else
		local index = recordIndex(records, uid)
		if not index or table.find(slots, uid) then return false, "Só é possível vender criaturas do inventário." end
		local owner = "SellCreature"
		if not dataService.TryLock(player, owner) then return false, "Aguarde a ação atual." end
		local price = GameplayMath.GetCreatureSalePrice(records[index].IncomePerSec)
		if not dataService.AddCoins(player, price) then
			dataService.Unlock(player, owner)
			return false, "O saldo não pôde ser atualizado."
		end
		table.remove(records, index)
		dataService.MarkDirty(player)
		local saved = dataService.SaveNow(player)
		if not saved then dataService.Freeze(player, "Salvamento da venda indisponível.") end
		dataService.Unlock(player, owner)
		if not saved then return false, "Não foi possível confirmar a venda." end
	end
	SanctuaryService.Refresh(player)
	dataService.MarkDirty(player)
	dataService.Sync(player)
	return true, if action == "Best" then "Curral atualizado com as melhores rendas." elseif action == "Replace" then "Criatura substituída." else "Criatura vendida."
end

function SanctuaryService.Init(service: any, world: any, ctx: any?)
	dataService = service
	worldService = world
	context = ctx
	dataService.OnLoaded(function(player: Player, profile: any)
		worldService.AssignSanctuary(player)
		if context and context.AuthoredCreatures and next(context.AuthoredCreatures) then
			local oldCount = #profile.SanctuarySlots
			local visible: {[string]: boolean} = {}
			for _, record in profile.CapturedCreatures do
				if SanctuaryService.HasArt(record.CreatureId) then visible[record.Uid] = true end
			end
			local slots = profile.SanctuarySlots
			for index = #slots, 1, -1 do
				if not visible[slots[index]] then table.remove(slots, index) end
			end
			if #slots < oldCount then
				local target = math.min(oldCount, SanctuaryService.GetSlotCapacity(profile, benefits(player)))
				for _, record in bestRecords(profile) do
					if #slots >= target then break end
					if not table.find(slots, record.Uid) then table.insert(slots, record.Uid) end
				end
			end
		end
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
	local manage = remoteFolder:FindFirstChild("ManageCreature")
	if manage and manage:IsA("RemoteEvent") then
		manage.OnServerEvent:Connect(function(player, action, uid, outgoing)
			local now = os.clock()
			if now - (lastEquip[player] or -math.huge) < .3 then return end
			lastEquip[player] = now
			local ok, message = SanctuaryService.Manage(player, action, uid, outgoing)
			local feedback = remoteFolder:WaitForChild("ActionFeedback") :: RemoteEvent
			feedback:FireClient(player, {Message = message, Kind = if ok then "Success" else "Error"})
		end)
	end
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
		local index = recordIndex(profile.CapturedCreatures, uid)
		if not index then
			return
		end
		local slot = table.find(profile.SanctuarySlots, uid)
		if slot then
			table.remove(profile.SanctuarySlots, slot)
		elseif SanctuaryService.HasArt(profile.CapturedCreatures[index].CreatureId) and #profile.SanctuarySlots < SanctuaryService.GetSlotCapacity(profile, benefits(player)) then
			table.insert(profile.SanctuarySlots, uid)
		else
			(remoteFolder:WaitForChild("ActionFeedback") :: RemoteEvent):FireClient(player, { Message = "Curral cheio ou arte indisponível. Confira o inventário.", Kind = "Error" })
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
					local shares = if worldService.UpdateSanctuaryIncome then {} else nil
					profile.IncomePerSec = SanctuaryService.CalculateIncome(profile, benefits(player), nil, shares)
					if shares then worldService.UpdateSanctuaryIncome(player, shares) end
					if service.AddCoins then service.AddCoins(player, profile.IncomePerSec) else profile.Coins += profile.IncomePerSec end
					dataService.Sync(player)
				end
			end
		end
	end)
end

return SanctuaryService
