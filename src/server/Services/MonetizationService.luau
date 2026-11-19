--!strict
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("ConfigMonetizacao"))
local Settings = require(Shared:WaitForChild("ConfigGameplay"))

local Monetization = {}
local ctx: any
local benefits: { [Player]: { [string]: boolean } } = {}
local checking: { [Player]: boolean } = {}
local initialized = false

local function copy(value: any): any
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in value do result[key] = copy(child) end
	return result
end

local function validId(id: any): boolean
	return type(id) == "number" and id > 0 and id < math.huge and id % 1 == 0
end

local function addCoins(profile: any, amount: number)
	profile.Coins += amount
	profile.TotalCoinsEarned = (profile.TotalCoinsEarned or 0) + amount
end

function Monetization.GetBenefits(player: Player): { [string]: boolean }
	return copy(benefits[player] or {})
end

local function refreshWorld(player: Player)
	if ctx.Sanctuary and ctx.Sanctuary.Refresh then ctx.Sanctuary.Refresh(player) end
	ctx.Data.Sync(player)
end

local function grantStarter(player: Player): boolean
	local profile = ctx.Data.Get(player)
	if not profile or profile.OneTimeGrants.StarterPack then return profile ~= nil end
	local owner = "StarterPack"
	if not ctx.Data.TryLock(player, owner) then return false end
	profile = ctx.Data.Get(player)
	if not profile or profile.OneTimeGrants.StarterPack then ctx.Data.Unlock(player, owner); return profile ~= nil end
	local snapshot = copy(profile)
	local used = if ctx.Data.GetInventoryCount then ctx.Data.GetInventoryCount(profile) else #profile.CapturedCreatures
	if used >= (Settings.MaxInventoryCreatures or 500) then ctx.Data.Unlock(player, owner); return false end
	addCoins(snapshot, 50000)
	snapshot.Orbs.Rubi = (snapshot.Orbs.Rubi or 0) + 10
	-- A curated promotional record, independent of the wild creature's base income.
	table.insert(snapshot.CapturedCreatures, {
		Uid = HttpService:GenerateGUID(false), CreatureId = "Cybermantis", Mutation = "Dourada", Size = "Normal",
		IncomePerSec = 500, CapturedAt = os.time(), FusionStage = 0,
	})
	snapshot.Bestiary.Cybermantis = true
	local oldBoost = snapshot.Boosts.Luck or { Multiplier = 1, ExpiresAt = 0 }
	snapshot.Boosts.Luck = { Multiplier = math.max(2, oldBoost.Multiplier), ExpiresAt = math.max(os.time(), oldBoost.ExpiresAt) + 1200 }
	snapshot.OneTimeGrants.StarterPack = true
	if not ctx.Data.Replace(player, snapshot) then
		ctx.Data.Freeze(player, "A recompensa precisa ser recuperada com segurança ao entrar novamente.")
		ctx.Data.Unlock(player, owner)
		return false
	end
	local saved = ctx.Data.SaveNow(player)
	if not saved then ctx.Data.Freeze(player, "Não foi possível confirmar sua recompensa. Entre novamente para protegê-la.") end
	ctx.Data.Unlock(player, owner)
	if saved then refreshWorld(player) end
	return saved
end

function Monetization.RefreshBenefits(player: Player)
	if checking[player] then return end
	checking[player] = true
	local result: { [string]: boolean } = {}
	for _, item in Catalog.Items do
		if item.Kind == "GamePass" then
			result[item.Key] = false
			if validId(item.Id) then
				local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, item.Id) end)
				-- Keep a verified session entitlement when a refresh cannot reach Roblox.
				result[item.Key] = if ok then owns == true else (benefits[player] or {})[item.Key] == true
			end
		end
	end
	result.GroupMember = false
	if validId(Settings.GroupId) then
		local ok, member = pcall(function() return player:IsInGroupAsync(Settings.GroupId) end)
		result.GroupMember = if ok then member == true else (benefits[player] or {}).GroupMember == true
	end
	checking[player] = nil
	if not player.Parent or not ctx.Data.Get(player) then return end
	benefits[player] = result
	if result.StarterPack then grantStarter(player) end
	refreshWorld(player)
end

local function productForId(productId: number): any
	for _, item in Catalog.Items do
		if item.Kind == "Product" and validId(item.Id) and item.Id == productId then return item end
	end
	return nil
end

function Monetization.ProcessReceipt(receipt: any): any
	local pending = Enum.ProductPurchaseDecision.NotProcessedYet
	if type(receipt) ~= "table" or not validId(receipt.PlayerId) or not validId(receipt.ProductId)
		or type(receipt.PurchaseId) ~= "string" or #receipt.PurchaseId == 0 or #receipt.PurchaseId > 200 then return pending end
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player or not ctx.Data.IsLoaded(player) then return pending end
	local item = productForId(receipt.ProductId)
	if not item or item.FulfillmentReady ~= true then return pending end
	local owner = "Receipt:" .. receipt.PurchaseId
	if not ctx.Data.TryLock(player, owner) then return pending end
	local profile = ctx.Data.Get(player)
	if not profile then ctx.Data.Unlock(player, owner); return pending end
	local snapshot = copy(profile)
	if not snapshot.ProcessedReceipts[receipt.PurchaseId] then
		local masters = { MasterOrb1 = 1, MasterOrb3 = 3, MasterOrb10 = 10 }
		local quantity = masters[item.Key]
		if quantity then snapshot.Orbs.Mestre = (snapshot.Orbs.Mestre or 0) + quantity
		elseif item.Key == "SanctuarySlot" then
			-- A token is redeemable when capacity allows; purchases can never vanish at the cap.
			snapshot.Consumables.SanctuarySlot = (snapshot.Consumables.SanctuarySlot or 0) + 1
		elseif item.Key == "PotionPack" then
			snapshot.Consumables.PotionLuck3 = (snapshot.Consumables.PotionLuck3 or 0) + 1
			snapshot.Consumables.PotionCoins3 = (snapshot.Consumables.PotionCoins3 or 0) + 1
		elseif item.Key == "GlobalLuckTotem" or item.Key == "SummonEvent" or item.Key == "SkipFusion" then
			snapshot.Consumables[item.Key] = (snapshot.Consumables[item.Key] or 0) + 1
		else ctx.Data.Unlock(player, owner); return pending end
		snapshot.ProcessedReceipts[receipt.PurchaseId] = true
		if not ctx.Data.Replace(player, snapshot) then
			ctx.Data.Freeze(player, "A compra será recuperada com segurança ao entrar novamente.")
			ctx.Data.Unlock(player, owner)
			return pending
		end
	end
	local saved = ctx.Data.SaveNow(player)
	if not saved then ctx.Data.Freeze(player, "A confirmação da compra será recuperada ao entrar novamente.") end
	ctx.Data.Unlock(player, owner)
	if not saved then return pending end
	refreshWorld(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Monetization.Init(context: any)
	assert(not initialized, "MonetizationService.Init must only run once")
	initialized = true
	ctx = context
	ctx.Data.AddSnapshotProvider(function(player: Player, _profile: any)
		return { Benefits = Monetization.GetBenefits(player), SalesEnabled = Catalog.SalesEnabled == true }
	end)
	ctx.Data.OnLoaded(function(player: Player) Monetization.RefreshBenefits(player) end)
	ctx.Data.OnRemoving(function(player: Player) benefits[player] = nil; checking[player] = nil end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, _passId: number, purchased: boolean)
		if purchased and ctx.Data.IsLoaded(player) then Monetization.RefreshBenefits(player) end
	end)
	MarketplaceService.ProcessReceipt = Monetization.ProcessReceipt
end

return Monetization
