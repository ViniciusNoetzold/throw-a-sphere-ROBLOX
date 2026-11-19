--!strict
-- One durable decision coordinates both profiles. Prepared assets are unusable
-- under the profile locks; committed patches are replayed idempotently on load.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Settings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigGameplay"))

local Trade = {}
local ctx: any
local initialized = false
local coordinatorStore: any = nil
local memoryCoordinators: { [string]: any } = {}
local sessions: { [string]: any } = {}
local playerSessions: { [Player]: string } = {}
local lastAction: { [Player]: number } = {}

local function copy(value: any): any
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in value do result[key] = copy(child) end
	return result
end

local function finite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function feedback(player: Player, message: string, success: boolean?)
	local remote = ctx.Remotes:FindFirstChild("ActionFeedback")
	if remote and player.Parent then remote:FireClient(player, {Message = message, Kind = if success then "Success" else "Error"}) end
end

local function sync(player: Player, allowBusy: boolean?)
	if ctx.Data.Get(player) then ctx.Data.Sync(player, allowBusy) end
end

function Trade.NewId(prefix: string?): string
	return (prefix or "Trade") .. "_" .. string.gsub(HttpService:GenerateGUID(false), "-", "")
end

-- These coordinator operations are also used by the local auction escrow.
function Trade.UpdateCoordinator(key: string, transform: (any) -> any): (boolean, any)
	local ok, result = pcall(function()
		if not ctx.Data.IsPersistent() then
			local nextValue = transform(copy(memoryCoordinators[key]))
			if nextValue ~= nil then memoryCoordinators[key] = copy(nextValue) end
			return copy(memoryCoordinators[key])
		end
		if not coordinatorStore then coordinatorStore = DataStoreService:GetDataStore("ThrowASphere_Transactions_v2") end
		return coordinatorStore:UpdateAsync(key, function(previous: any) return transform(copy(previous)) end)
	end)
	return ok, result
end

function Trade.ReadCoordinator(key: string): (boolean, any)
	-- UpdateAsync supplies a current value and avoids GetAsync's per-server cache.
	return Trade.UpdateCoordinator(key, function(previous: any) return previous end)
end

function Trade.AbortCoordinator(key: string): (boolean, any)
	return Trade.UpdateCoordinator(key, function(previous: any)
		if type(previous) == "table" and (previous.State == "Prepared" or previous.State == "Open") then
			previous.State = "Aborted"
			previous.DecidedAt = os.time()
		end
		return previous
	end)
end

local function refresh(player: Player)
	if ctx.Data.Get(player) and ctx.Sanctuary and ctx.Sanctuary.Refresh then ctx.Sanctuary.Refresh(player) end
	sync(player)
end

local function validCapture(record: any): boolean
	return type(record) == "table" and type(record.Uid) == "string" and #record.Uid > 0 and #record.Uid <= 80
		and type(record.CreatureId) == "string" and type(record.Mutation) == "string" and type(record.Size) == "string"
		and finite(record.IncomePerSec) and record.IncomePerSec >= 0 and finite(record.CapturedAt)
end

function Trade.ValidatePatch(profile: any, patch: any, ignoreKey: string?): (boolean, string?)
	if type(patch) ~= "table" or type(patch.GiveUids) ~= "table" or type(patch.Receive) ~= "table" or not finite(patch.CoinsDelta) then return false, "Transação inválida." end
	local owned, giving, incoming = {}, {}, {}
	for _, record in profile.CapturedCreatures do owned[record.Uid] = true end
	for _, uid in patch.GiveUids do
		if type(uid) ~= "string" or not owned[uid] or giving[uid] then return false, "Uma criatura da oferta não está disponível." end
		giving[uid] = true
	end
	for _, record in patch.Receive do
		if not validCapture(record) or incoming[record.Uid] or (owned[record.Uid] and not giving[record.Uid]) then return false, "Criatura recebida duplicada ou inválida." end
		incoming[record.Uid] = true
	end
	local reserved = if ctx.Data.GetReservedSlots then ctx.Data.GetReservedSlots(profile) else 0
	local ignored = if ignoreKey then profile.PendingTransactions[ignoreKey] else nil
	if ignored then reserved = math.max(0, reserved - (ignored.ReservedSlots or 0)) end
	if #profile.CapturedCreatures - #patch.GiveUids + #patch.Receive + reserved > (Settings.MaxInventoryCreatures or 500) then return false, "Não há espaço no inventário." end
	if profile.Coins + patch.CoinsDelta < 0 or not finite(profile.Coins + patch.CoinsDelta) then return false, "Moedas insuficientes." end
	return true, nil
end

local function patched(profile: any, patch: any, key: string, markApplied: boolean): any
	local result = copy(profile)
	local giving: { [string]: boolean } = {}
	for _, uid in patch.GiveUids or {} do giving[uid] = true end
	local captures = {}
	local owned = {}
	for _, record in result.CapturedCreatures do
		if not giving[record.Uid] then table.insert(captures, record); owned[record.Uid] = true end
	end
	for _, record in patch.Receive or {} do
		assert(validCapture(record), "Invalid transaction capture")
		-- A retry can observe a receive that was already applied. Never clone its UID.
		if not owned[record.Uid] then table.insert(captures, copy(record)); owned[record.Uid] = true end
		result.Bestiary[record.CreatureId] = true
	end
	result.CapturedCreatures = captures
	local slots = {}
	for _, uid in result.SanctuarySlots do if owned[uid] then table.insert(slots, uid) end end
	result.SanctuarySlots = slots
	result.Coins += patch.CoinsDelta or 0
	assert(finite(result.Coins) and result.Coins >= 0, "Invalid transaction balance")
	result.PendingTransactions[key] = nil
	if markApplied then result.AppliedTransactions[key] = true end
	-- Transfers do not create lifetime coins/capture counts and cannot inflate ranks.
	return result
end

function Trade.ApplyDecision(player: Player, key: string, decision: any, owner: string): boolean
	if type(decision) ~= "table" or (decision.State ~= "Committed" and decision.State ~= "Aborted") then return false end
	local profile = ctx.Data.Get(player)
	if not profile then return false end
	local pending = profile.PendingTransactions[key]
	if not pending then return true end
	if profile.AppliedTransactions[key] then
		local snapshot = copy(profile)
		snapshot.PendingTransactions[key] = nil
		if not ctx.Data.Replace(player, snapshot) then ctx.Data.Freeze(player, "Sua transação requer recuperação segura."); return false end
	else
		local patch = nil
		if decision.State == "Committed" then patch = (decision.Participants or {})[tostring(player.UserId)] end
		if not patch then
			-- Auction escrows have already removed the asset/coins. On abort, or
			-- for an outbid participant absent from the winner set, refund them.
			patch = if pending.Kind == "Auction" then {GiveUids = {}, Receive = pending.Receive or {}, CoinsDelta = pending.CoinsDelta or 0}
				else {GiveUids = {}, Receive = {}, CoinsDelta = 0}
		end
		if not ctx.Data.Replace(player, patched(profile, patch, key, true)) then ctx.Data.Freeze(player, "Sua transação requer recuperação segura."); return false end
	end
	if not ctx.Data.SaveNow(player) then
		ctx.Data.Freeze(player, "Sua transação será recuperada com segurança ao entrar novamente.")
		return false
	end
	refresh(player)
	return true
end

-- Refund an outbid escrow while the auction remains open. Clearing the pending
-- record and returning the balance happen in the same durable profile write.
function Trade.RefundOpenAuction(player: Player, key: string): boolean
	local owner = "AuctionRefund:" .. key
	if not ctx.Data.TryLock(player, owner) then return false end
	local profile = ctx.Data.Get(player)
	local pending = profile and profile.PendingTransactions[key]
	if not pending then ctx.Data.Unlock(player, owner); return profile ~= nil end
	local snapshot = patched(profile, {GiveUids = {}, Receive = pending.Receive or {}, CoinsDelta = pending.CoinsDelta or 0}, key, false)
	if not ctx.Data.Replace(player, snapshot) then
		ctx.Data.Freeze(player, "Sua restituição requer recuperação segura.")
		ctx.Data.Unlock(player, owner)
		return false
	end
	local saved = ctx.Data.SaveNow(player)
	if not saved then ctx.Data.Freeze(player, "Sua restituição será recuperada ao entrar novamente.") end
	ctx.Data.Unlock(player, owner)
	if saved then refresh(player) end
	return saved
end

function Trade.RecoverPlayer(player: Player, profile: any)
	local keys = {}
	for key in profile.PendingTransactions do table.insert(keys, key) end
	table.sort(keys)
	if #keys == 0 then return end
	local owner = "Recovery"
	assert(ctx.Data.TryLock(player, owner), "Recovery could not acquire profile")
	for _, key in keys do
		local ok, decision = Trade.ReadCoordinator(key)
		if not ok or type(decision) ~= "table" then
			ctx.Data.Unlock(player, owner)
			error("Transaction coordinator unavailable; profile preserved")
		end
		if decision.State == "Prepared" or decision.State == "Open" then ok, decision = Trade.AbortCoordinator(key) end
		if not ok or type(decision) ~= "table" or (decision.State ~= "Committed" and decision.State ~= "Aborted") then
			ctx.Data.Unlock(player, owner)
			error("Transaction decision unavailable; profile preserved")
		end
		if not Trade.ApplyDecision(player, key, decision, owner) then
			ctx.Data.Unlock(player, owner)
			error("Transaction recovery save failed; profile preserved")
		end
	end
	ctx.Data.Unlock(player, owner)
end

local function releaseSession(session: any)
	for _, player in session.Players do ctx.Data.Unlock(player, session.Id) end
end

local function removeSession(session: any, message: string?)
	releaseSession(session)
	sessions[session.Id] = nil
	for _, player in session.Players do
		if playerSessions[player] == session.Id then playerSessions[player] = nil end
		if message then feedback(player, message, true) end
		sync(player)
	end
end

local function locationAllowed(player: Player): boolean
	return ctx.Biomes ~= nil and ctx.Biomes.IsInTradingPlaza ~= nil and ctx.Biomes.IsInTradingPlaza(player)
end

local function eligible(player: Player): boolean
	local profile = ctx.Data.Get(player)
	return ctx.Data.IsLoaded(player) and profile ~= nil and profile.Level >= 15 and locationAllowed(player)
end

function Trade.GetSnapshot(player: Player): any
	local session = sessions[playerSessions[player] or ""]
	if not session then return {} end
	local partner = if session.Players[1] == player then session.Players[2] else session.Players[1]
	local partnerCreatures = {}
	local partnerProfile = ctx.Data.Get(partner)
	if partnerProfile then
		local offered = {}
		for _, uid in session.Offers[partner.UserId] do offered[uid] = true end
		for _, record in partnerProfile.CapturedCreatures do if offered[record.Uid] then table.insert(partnerCreatures, copy(record)) end end
	end
	return {
		SessionId = session.Id, PartnerUserId = partner.UserId, PartnerName = partner.DisplayName,
		Revision = session.Revision, Phase = session.Phase,
		ReadyAt = if session.ReadyAt then os.time() + math.max(0, session.ReadyAt - os.clock()) else 0,
		MyOffer = copy(session.Offers[player.UserId]), PartnerOffer = copy(session.Offers[partner.UserId]),
		PartnerCreatures = partnerCreatures,
		MyReady = session.Ready[player.UserId] == true, PartnerReady = session.Ready[partner.UserId] == true,
		MyConfirmed = session.Confirmed[player.UserId] == true, PartnerConfirmed = session.Confirmed[partner.UserId] == true,
		InviterUserId = session.Players[1].UserId,
	}
end

local function syncSession(session: any)
	for _, player in session.Players do sync(player, session.Phase == "Review" or session.Phase == "Committing") end
end

local function findRecords(profile: any, uids: any): ({any}?, string?)
	if type(uids) ~= "table" or #uids > (Settings.MaxTradeOfferCreatures or 8) then return nil, "Oferta inválida." end
	local byUid = {}
	for _, record in profile.CapturedCreatures do byUid[record.Uid] = record end
	local seen, records = {}, {}
	for key, uid in uids do
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > #uids then return nil, "Oferta inválida." end
		if type(uid) ~= "string" or not byUid[uid] or seen[uid] then return nil, "Você não possui uma das criaturas ofertadas." end
		seen[uid] = true
		table.insert(records, copy(byUid[uid]))
	end
	if #records ~= #uids then return nil, "Oferta inválida." end
	return records, nil
end

local function execute(session: any)
	local patches = {}
	local players = session.Players
	for index, player in players do
		local partner = players[3 - index]
		local profile, other = ctx.Data.Get(player), ctx.Data.Get(partner)
		if not profile or not other or not eligible(player) then removeSession(session, "A troca foi cancelada."); return end
		local received = findRecords(other, session.Offers[partner.UserId])
		if not received then removeSession(session, "Uma oferta mudou. A troca foi cancelada."); return end
		patches[tostring(player.UserId)] = { GiveUids = copy(session.Offers[player.UserId]), Receive = received, CoinsDelta = 0 }
		local valid, reason = Trade.ValidatePatch(profile, patches[tostring(player.UserId)])
		if not valid then removeSession(session, reason); return end
	end
	local ok, journal = Trade.UpdateCoordinator(session.Id, function(previous: any)
		if previous ~= nil then return previous end
		return {Kind = "Trade", State = "Prepared", Participants = patches, CreatedAt = os.time()}
	end)
	if not ok or not journal or journal.State ~= "Prepared" then
		removeSession(session, "Não foi possível preparar a troca. Nada foi transferido."); return
	end
	local prepared = true
	for index, player in players do
		local profile = ctx.Data.Get(player)
		if not profile then prepared = false; break end
		local snapshot = copy(profile)
		local patch = patches[tostring(player.UserId)]
		snapshot.PendingTransactions[session.Id] = {
			Kind = "Trade", CoordinatorKey = session.Id, PartnerUserId = players[3 - index].UserId,
			GiveUids = copy(patch.GiveUids), Receive = copy(patch.Receive), CoinsDelta = 0, State = "Prepared",
			ReservedSlots = math.max(0, #patch.Receive - #patch.GiveUids),
		}
		if not ctx.Data.Replace(player, snapshot) then prepared = false; break end
		if not ctx.Data.SaveNow(player) then prepared = false; break end
	end
	if prepared then
		for _, player in players do if not player.Parent or not ctx.Data.Get(player) then prepared = false end end
	end
	if prepared then
		ok, journal = Trade.UpdateCoordinator(session.Id, function(previous: any)
			if previous and previous.State == "Prepared" then previous.State = "Committed"; previous.DecidedAt = os.time() end
			return previous
		end)
	else ok, journal = Trade.AbortCoordinator(session.Id) end
	if not ok or not journal or (journal.State ~= "Committed" and journal.State ~= "Aborted") then
		for _, player in players do if ctx.Data.Get(player) then ctx.Data.Freeze(player, "A decisão da troca será recuperada ao entrar novamente.") end end
		removeSession(session)
		return
	end
	for _, player in players do
		if ctx.Data.Get(player) then Trade.ApplyDecision(player, session.Id, journal, session.Id) end
	end
	removeSession(session, if journal.State == "Committed" then "Troca concluída e salva!" else "Troca cancelada. Suas criaturas foram preservadas.")
end

function Trade.HandleAction(player: Player, action: any, payload: any)
	if type(action) ~= "string" or type(payload) ~= "table" then return end
	local now = os.clock()
	if now - (lastAction[player] or -math.huge) < 0.15 then return end
	lastAction[player] = now
	if action == "Invite" then
		if not eligible(player) or ctx.Data.IsBusy(player) or playerSessions[player] then feedback(player, "Vá à praça de trocas no nível 15 ou superior."); return end
		if not finite(payload.TargetUserId) then return end
		local target = Players:GetPlayerByUserId(payload.TargetUserId)
		if not target or target == player or not eligible(target) or ctx.Data.IsBusy(target) or playerSessions[target] then feedback(player, "Esse jogador não está disponível para troca."); return end
		local id = Trade.NewId()
		local session = { Id = id, Players = {player, target}, Offers = {[player.UserId] = {}, [target.UserId] = {}},
			Revision = 1, Phase = "Invited", Ready = {}, Confirmed = {}, ExpiresAt = now + 60 }
		sessions[id] = session; playerSessions[player] = id; playerSessions[target] = id
		syncSession(session)
		return
	end
	local session = sessions[playerSessions[player] or ""]
	if not session or payload.SessionId ~= session.Id or session.Phase == "Committing" then return end
	if action == "Cancel" then removeSession(session, "Troca cancelada."); return end
	if not eligible(player) then removeSession(session, "A troca foi cancelada ao sair da praça."); return end
	if action == "Accept" then
		if session.Phase ~= "Invited" or player == session.Players[1] then return end
		session.Phase = "Offering"; session.ExpiresAt = now + 180; syncSession(session); return
	end
	if payload.Revision ~= session.Revision or session.Phase == "Invited" then feedback(player, "A oferta mudou. Confira a versão atual."); return end
	if action == "Offer" then
		local profile = ctx.Data.Get(player)
		if not profile then return end
		local records, reason = findRecords(profile, payload.Uids)
		if not records then feedback(player, reason or "Oferta inválida."); return end
		releaseSession(session)
		session.Offers[player.UserId] = copy(payload.Uids)
		session.Revision += 1; session.Ready = {}; session.Confirmed = {}; session.ReadyAt = nil
		session.Phase = "Offering"; session.ExpiresAt = now + 180
		syncSession(session)
	elseif action == "Ready" and session.Phase == "Offering" then
		session.Ready[player.UserId] = true
		local first, second = session.Players[1], session.Players[2]
		if session.Ready[first.UserId] and session.Ready[second.UserId] then
			if #session.Offers[first.UserId] + #session.Offers[second.UserId] == 0 then session.Ready = {}; feedback(player, "Escolha ao menos uma criatura."); syncSession(session); return end
			if not eligible(first) or not eligible(second) or not ctx.Data.TryLock(first, session.Id) then session.Ready = {}; syncSession(session); return end
			if not ctx.Data.TryLock(second, session.Id) then ctx.Data.Unlock(first, session.Id); session.Ready = {}; syncSession(session); return end
			session.Phase = "Review"; session.ReadyAt = now + 3; session.ExpiresAt = now + 60
		end
		syncSession(session)
	elseif action == "Confirm" and session.Phase == "Review" then
		if now < session.ReadyAt then feedback(player, "Revise a troca e aguarde os 3 segundos."); return end
		session.Confirmed[player.UserId] = true
		local first, second = session.Players[1], session.Players[2]
		if session.Confirmed[first.UserId] and session.Confirmed[second.UserId] then
			session.Phase = "Committing"
			syncSession(session)
			task.spawn(execute, session)
		else syncSession(session) end
	end
end

function Trade.Init(context: any)
	assert(not initialized, "TradeService.Init must only run once")
	initialized = true
	ctx = context
	ctx.Data.OnLoaded(Trade.RecoverPlayer)
	ctx.Data.OnRemoving(function(player: Player)
		lastAction[player] = nil
		local session = sessions[playerSessions[player] or ""]
		if session and session.Phase ~= "Committing" then removeSession(session, "O outro jogador saiu. Troca cancelada.") end
	end)
	ctx.Data.AddSnapshotProvider(function(player: Player, _profile: any)
		local candidates = {}
		for _, other in Players:GetPlayers() do
			if other ~= player and eligible(other) and not ctx.Data.IsBusy(other) and not playerSessions[other] then
				table.insert(candidates, {UserId = other.UserId, Name = other.DisplayName})
			end
		end
		table.sort(candidates, function(a, b) return a.UserId < b.UserId end)
		return {Trade = Trade.GetSnapshot(player), TradeCandidates = candidates}
	end)
	local remote = ctx.Remotes:WaitForChild("TradeAction") :: RemoteEvent
	remote.OnServerEvent:Connect(Trade.HandleAction)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, session in sessions do
				if session.Phase ~= "Committing" and (os.clock() >= session.ExpiresAt
					or not eligible(session.Players[1]) or not eligible(session.Players[2])) then removeSession(session, "Troca encerrada sem transferências.") end
			end
		end
	end)
end

return Trade
