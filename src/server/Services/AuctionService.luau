--!strict
-- Room-local 120s auctions. Assets/coins are durably escrowed; the same
-- coordinator decision as trades makes settlement and recovery idempotent.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigGameplay"))

local Auction = {}
local ctx: any
local initialized = false
local lots: { [string]: any } = {}
local refunds: { any } = {}
local lastAction: { [Player]: number } = {}

local function copy(value: any): any
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in value do result[key] = copy(child) end
	return result
end

local function money(value: any): boolean
	return type(value) == "number" and value == value and value > 0 and value < math.huge and value % 1 == 0
end

local function feedback(player: Player, message: string, success: boolean?)
	local remote = ctx.Remotes:FindFirstChild("ActionFeedback")
	if remote and player.Parent then remote:FireClient(player, {Message = message, Kind = if success then "Success" else "Error"}) end
end

local function eligible(player: Player): boolean
	local profile = ctx.Data.Get(player)
	return ctx.Data.IsLoaded(player) and profile ~= nil and profile.Level >= 15 and ctx.Biomes and ctx.Biomes.IsInTradingPlaza(player)
end

local function syncAll()
	for _, player in Players:GetPlayers() do if ctx.Data.Get(player) then ctx.Data.Sync(player) end end
end

local function usedInventory(profile: any): number
	return if ctx.Data.GetInventoryCount then ctx.Data.GetInventoryCount(profile) else #profile.CapturedCreatures
end

function Auction.GetSnapshot(player: Player): any
	local result = {}
	for id, lot in lots do
		table.insert(result, {
			AuctionId = id, Creature = copy(lot.Creature), SellerUserId = lot.SellerUserId, SellerName = lot.SellerName,
			MinimumBid = lot.MinimumBid, HighestBid = lot.HighestBid, HighestBidderUserId = lot.BuyerUserId or 0,
			EndsAt = lot.EndsAt, MyBidReserved = if lot.BuyerUserId == player.UserId then lot.HighestBid else 0,
		})
	end
	table.sort(result, function(a, b) return if a.EndsAt == b.EndsAt then a.AuctionId < b.AuctionId else a.EndsAt < b.EndsAt end)
	return result
end

local function applyOnline(lot: any, decision: any)
	local userIds = copy(lot.EscrowUsers)
	userIds[lot.SellerUserId] = true
	for userId in userIds do
		local player = Players:GetPlayerByUserId(userId)
		if player and ctx.Data.Get(player) then
			local owner = "AuctionSettle:" .. lot.Id
			if ctx.Data.TryLock(player, owner) then
				ctx.Trade.ApplyDecision(player, lot.Id, decision, owner)
				ctx.Data.Unlock(player, owner)
			else table.insert(refunds, {Player = player, Key = lot.Id, Decision = decision}) end
		end
	end
end

local function abort(lot: any): boolean
	local ok, decision = ctx.Trade.AbortCoordinator(lot.Id)
	if not ok or not decision then return false end
	if decision.State ~= "Aborted" and decision.State ~= "Committed" then return false end
	applyOnline(lot, decision)
	lots[lot.Id] = nil
	syncAll()
	return true
end

local function finish(lot: any)
	if lot.Busy then return end
	lot.Busy = true
	local seller = Players:GetPlayerByUserId(lot.SellerUserId)
	local buyer = if lot.BuyerUserId then Players:GetPlayerByUserId(lot.BuyerUserId) else nil
	if lot.CancelRequested or not seller or not buyer or not eligible(seller) or not eligible(buyer) then
		abort(lot); lot.Busy = false; return
	end
	local owner = "AuctionCommit:" .. lot.Id
	if not ctx.Data.TryLock(seller, owner) then lot.Busy = false; return end
	if not ctx.Data.TryLock(buyer, owner) then ctx.Data.Unlock(seller, owner); lot.Busy = false; return end
	local buyerProfile, sellerProfile = ctx.Data.Get(buyer), ctx.Data.Get(seller)
	local patches = {
		[tostring(seller.UserId)] = {GiveUids = {}, Receive = {}, CoinsDelta = lot.HighestBid},
		[tostring(buyer.UserId)] = {GiveUids = {}, Receive = {copy(lot.Creature)}, CoinsDelta = 0},
	}
	local valid = buyerProfile and sellerProfile and buyerProfile.PendingTransactions[lot.Id]
		and sellerProfile.PendingTransactions[lot.Id] and ctx.Trade.ValidatePatch(buyerProfile, patches[tostring(buyer.UserId)], lot.Id)
	local ok, decision
	if valid then
		ok, decision = ctx.Trade.UpdateCoordinator(lot.Id, function(previous: any)
			if previous and previous.State == "Open" then
				previous.State = "Committed"; previous.Participants = copy(patches); previous.DecidedAt = os.time()
			end
			return previous
		end)
	else ok, decision = ctx.Trade.AbortCoordinator(lot.Id) end
	if not ok or not decision or (decision.State ~= "Committed" and decision.State ~= "Aborted") then
		ctx.Data.Freeze(seller, "Seu leilão será recuperado ao entrar novamente.")
		ctx.Data.Freeze(buyer, "Seu leilão será recuperado ao entrar novamente.")
		lots[lot.Id] = nil
	else
		ctx.Trade.ApplyDecision(seller, lot.Id, decision, owner)
		ctx.Trade.ApplyDecision(buyer, lot.Id, decision, owner)
		lots[lot.Id] = nil
		feedback(seller, if decision.State == "Committed" then "Leilão concluído e salvo!" else "Leilão cancelado. Sua criatura será restituída.", true)
		feedback(buyer, if decision.State == "Committed" then "Sua criatura do leilão foi entregue!" else "Leilão cancelado. Suas moedas serão restituídas.", true)
	end
	ctx.Data.Unlock(seller, owner); ctx.Data.Unlock(buyer, owner)
	-- Earlier bidders with a delayed refund are absent from the winning patch
	-- and receive only their own escrow refund, never the seller/winner payout.
	if ok and decision and (decision.State == "Committed" or decision.State == "Aborted") then applyOnline(lot, decision) end
	lot.Busy = false
	syncAll()
end

local function listCreature(player: Player, payload: any)
	if not eligible(player) or ctx.Data.IsBusy(player) then feedback(player, "Visite a praça de trocas no nível 15 ou superior."); return end
	local count = 0
	for _, lot in lots do
		count += 1
		if lot.SellerUserId == player.UserId then feedback(player, "Você já tem um leilão nesta sala."); return end
	end
	if count >= (Settings.MaxAuctionLots or 10) then feedback(player, "Esta sala já tem dez leilões abertos."); return end
	local minimum = payload.MinimumBid
	if type(payload.Uid) ~= "string" or not money(minimum) then feedback(player, "Escolha a criatura e um lance mínimo inteiro positivo."); return end
	local profile = ctx.Data.Get(player)
	local creature = nil
	for _, record in profile.CapturedCreatures do if record.Uid == payload.Uid then creature = copy(record); break end end
	if not creature then return end
	local id = ctx.Trade.NewId("Auction")
	local owner = "AuctionList:" .. id
	if not ctx.Data.TryLock(player, owner) then return end
	profile = ctx.Data.Get(player)
	if not profile then ctx.Data.Unlock(player, owner); return end
	local lot = {Id = id, SellerUserId = player.UserId, SellerName = player.DisplayName, Creature = creature,
		MinimumBid = minimum, HighestBid = 0, BuyerUserId = nil, EndsAt = os.time() + (Settings.AuctionSeconds or 120),
		EscrowUsers = {}, Busy = false, CancelRequested = false}
	local ok, journal = ctx.Trade.UpdateCoordinator(id, function(previous: any)
		if previous then return previous end
		return {Kind = "Auction", State = "Prepared", Participants = {}, CreatedAt = os.time(), Lot = {
			SellerUserId = player.UserId, Creature = copy(creature), MinimumBid = minimum, EndsAt = lot.EndsAt,
		}}
	end)
	if not ok or not journal or journal.State ~= "Prepared" then ctx.Data.Unlock(player, owner); feedback(player, "Não foi possível abrir o leilão."); return end
	local snapshot = copy(profile)
	for index = #snapshot.CapturedCreatures, 1, -1 do if snapshot.CapturedCreatures[index].Uid == creature.Uid then table.remove(snapshot.CapturedCreatures, index) end end
	for index = #snapshot.SanctuarySlots, 1, -1 do if snapshot.SanctuarySlots[index] == creature.Uid then table.remove(snapshot.SanctuarySlots, index) end end
	snapshot.PendingTransactions[id] = {Kind = "Auction", CoordinatorKey = id, PartnerUserId = 0, GiveUids = {},
		Receive = {copy(creature)}, CoinsDelta = 0, State = "Prepared", ReservedSlots = 1}
	if not ctx.Data.Replace(player, snapshot) then
		ctx.Trade.AbortCoordinator(id)
		ctx.Data.Unlock(player, owner)
		feedback(player, "Não foi possível reservar sua criatura.")
		return
	end
	local saved = ctx.Data.SaveNow(player)
	if saved then
		ok, journal = ctx.Trade.UpdateCoordinator(id, function(previous: any)
			if previous and previous.State == "Prepared" then previous.State = "Open" end
			return previous
		end)
	end
	if not saved or not ok or not journal or journal.State ~= "Open" then
		local aborted, decision = ctx.Trade.AbortCoordinator(id)
		if aborted and decision then ctx.Trade.ApplyDecision(player, id, decision, owner)
		else ctx.Data.Freeze(player, "A restituição da sua criatura será recuperada ao entrar novamente.") end
		ctx.Data.Unlock(player, owner)
		return
	end
	lots[id] = lot
	ctx.Data.Unlock(player, owner)
	if ctx.Sanctuary and ctx.Sanctuary.Refresh then ctx.Sanctuary.Refresh(player) end
	syncAll()
	feedback(player, "Criatura reservada. Seu leilão dura 120 segundos nesta sala.", true)
end

local function bid(player: Player, lot: any, amount: any)
	if lot.Busy or lot.CancelRequested or os.time() >= lot.EndsAt or not eligible(player) or player.UserId == lot.SellerUserId or not money(amount)
		or amount < lot.MinimumBid or amount <= lot.HighestBid then feedback(player, "Lance inválido ou leilão indisponível."); return end
	local owner = "AuctionBid:" .. lot.Id
	if not ctx.Data.TryLock(player, owner) then return end
	lot.Busy = true
	local profile = ctx.Data.Get(player)
	if not profile then ctx.Data.Unlock(player, owner); lot.Busy = false; return end
	local alreadyLeading = lot.BuyerUserId == player.UserId
	if not alreadyLeading and profile.PendingTransactions[lot.Id] then
		feedback(player, "Aguarde a restituição do lance anterior antes de ofertar novamente.")
		ctx.Data.Unlock(player, owner); lot.Busy = false; return
	end
	local delta = amount - (if alreadyLeading then lot.HighestBid else 0)
	if profile.Coins < delta or (not alreadyLeading and usedInventory(profile) >= (Settings.MaxInventoryCreatures or 500)) then
		feedback(player, "Moedas ou espaço no inventário insuficientes.")
		ctx.Data.Unlock(player, owner); lot.Busy = false; return
	end
	local previousBuyer = lot.BuyerUserId
	local snapshot = copy(profile)
	snapshot.Coins -= delta
	snapshot.PendingTransactions[lot.Id] = {Kind = "Auction", CoordinatorKey = lot.Id, PartnerUserId = lot.SellerUserId,
		GiveUids = {}, Receive = {}, CoinsDelta = amount, State = "Prepared", ReservedSlots = 1}
	if not ctx.Data.Replace(player, snapshot) then
		ctx.Data.Unlock(player, owner); lot.Busy = false
		feedback(player, "Não foi possível reservar esse lance.")
		return
	end
	lot.EscrowUsers[player.UserId] = true
	local saved = ctx.Data.SaveNow(player)
	local ok, journal = false, nil
	if saved then
		ok, journal = ctx.Trade.UpdateCoordinator(lot.Id, function(previous: any)
			if previous and previous.State == "Open" then
				previous.Lot.HighestBid = amount; previous.Lot.BuyerUserId = player.UserId
			end
			return previous
		end)
	end
	ctx.Data.Unlock(player, owner)
	if not saved then ctx.Data.Freeze(player, "Seu lance será recuperado ao entrar novamente.") end
	if not saved or not ok or not journal or journal.State ~= "Open" then
		lot.CancelRequested = true; lot.Busy = false; finish(lot); return
	end
	lot.HighestBid = amount; lot.BuyerUserId = player.UserId
	if previousBuyer and previousBuyer ~= player.UserId then
		local previousPlayer = Players:GetPlayerByUserId(previousBuyer)
		if previousPlayer and ctx.Data.Get(previousPlayer) then
			if not ctx.Trade.RefundOpenAuction(previousPlayer, lot.Id) then table.insert(refunds, {Player = previousPlayer, Key = lot.Id}) end
			feedback(previousPlayer, "Seu lance foi superado; as moedas reservadas foram devolvidas ou estão em restituição.", true)
		end
	end
	lot.Busy = false
	syncAll()
	feedback(player, "Lance registrado. As moedas ficam reservadas até o resultado.", true)
end

function Auction.HandleAction(player: Player, action: any, payload: any)
	if type(action) ~= "string" or type(payload) ~= "table" then return end
	local now = os.clock()
	if now - (lastAction[player] or -math.huge) < 0.25 then return end
	lastAction[player] = now
	if action == "List" then listCreature(player, payload); return end
	local lot = type(payload.AuctionId) == "string" and lots[payload.AuctionId]
	if not lot then return end
	if action == "Bid" then bid(player, lot, payload.Amount)
	elseif action == "Cancel" and lot.SellerUserId == player.UserId and lot.HighestBid == 0 then
		lot.CancelRequested = true; finish(lot)
	end
end

function Auction.Tick()
	for _, lot in lots do
		if lot.CancelRequested or os.time() >= lot.EndsAt then finish(lot) end
	end
	for index = #refunds, 1, -1 do
		local item = refunds[index]
		if not ctx.Data.Get(item.Player) then table.remove(refunds, index)
		elseif not ctx.Data.IsBusy(item.Player) then
			local success
			if item.Decision then
				local owner = "AuctionRecovery:" .. item.Key
				if ctx.Data.TryLock(item.Player, owner) then
					success = ctx.Trade.ApplyDecision(item.Player, item.Key, item.Decision, owner)
					ctx.Data.Unlock(item.Player, owner)
				end
			else success = ctx.Trade.RefundOpenAuction(item.Player, item.Key) end
			if success then table.remove(refunds, index) end
		end
	end
end

function Auction.Init(context: any)
	assert(not initialized, "AuctionService.Init must only run once")
	initialized = true; ctx = context
	ctx.Data.AddSnapshotProvider(function(player: Player, _profile: any) return {Auctions = Auction.GetSnapshot(player)} end)
	ctx.Data.OnRemoving(function(player: Player)
		lastAction[player] = nil
		for _, lot in lots do
			if lot.SellerUserId == player.UserId or lot.BuyerUserId == player.UserId then lot.CancelRequested = true end
		end
		-- The departing profile's final save preserves its escrow; recovery
		-- refunds it on the next load, while the online partner is refunded now.
		task.defer(Auction.Tick)
	end)
	local remote = ctx.Remotes:WaitForChild("AuctionAction") :: RemoteEvent
	remote.OnServerEvent:Connect(Auction.HandleAction)
	task.spawn(function() while true do task.wait(1); Auction.Tick() end end)
end

return Auction
