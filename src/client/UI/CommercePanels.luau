--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Settings = require(Shared:WaitForChild("ConfigGameplay"))
local Catalog = require(Shared:WaitForChild("ConfigMonetizacao"))
local Numbers = require(Shared:WaitForChild("NumberFormatter"))
local W = require(script.Parent:WaitForChild("HUDWidgets"))
local Icons = require(script.Parent:WaitForChild("HUDIcons"))
local C = W.Colors

local Commerce = {}

local function preferences(actions: any): any
	actions.Session.Commerce = actions.Session.Commerce or {Scroll = {}, Bids = {}, Selected = {}, MinimumBid = "10", TradePage = 1, AuctionPage = 1}
	return actions.Session.Commerce
end

local function nameOf(record: any): string
	local definition = Config.Creatures[record.CreatureId]
	return if definition then definition.Name else tostring(record.CreatureId)
end

local function uidList(values: any): string
	local result = {}
	for _, value in values or {} do table.insert(result, tostring(value)) end
	table.sort(result)
	return table.concat(result, ",")
end

function Commerce.Signature(kind: string, state: any, session: any): string
	state = state or {}
	session = session or {}
	local preference = session.Commerce or {}
	local values = {kind, tostring(state.CurrentBiome), tostring(state.Level)}
	if kind == "Trocas" then
		local trade = state.Trade or {}
		for _, key in {"SessionId", "Revision", "Phase", "MyReady", "PartnerReady", "MyConfirmed", "PartnerConfirmed"} do table.insert(values, tostring(trade[key])) end
		table.insert(values, uidList(trade.MyOffer)); table.insert(values, uidList(trade.PartnerOffer))
		for _, item in state.TradeCandidates or {} do table.insert(values, tostring(item.UserId) .. item.Name) end
		local selected = {}; for uid, active in preference.Selected or {} do if active then table.insert(selected, uid) end end
		table.insert(values, uidList(selected)); table.insert(values, tostring(preference.TradePage))
	elseif kind == "Leiloes" then
		-- Bids and clocks update in place, preserving an actively edited TextBox.
		for _, lot in state.Auctions or {} do table.insert(values, lot.AuctionId) end
		table.insert(values, tostring(preference.AuctionUid)); table.insert(values, tostring(preference.AuctionPage))
	elseif kind == "GrupoVIP" then
		local benefits = {}; for key, enabled in state.Benefits or {} do table.insert(benefits, key .. tostring(enabled)) end
		table.sort(benefits); table.insert(values, table.concat(benefits, ","))
		table.insert(values, tostring(state.VIPLastClaim)); table.insert(values, tostring((state.Titles or {}).Grupo))
	end
	if kind ~= "GrupoVIP" then
		for _, record in state.CapturedCreatures or {} do table.insert(values, record.Uid .. ":" .. tostring(record.Mutation) .. ":" .. tostring(record.Size) .. ":" .. tostring(record.IncomePerSec)) end
	end
	return table.concat(values, "|")
end

local function serverNow(state: any, actions: any): number
	return (state.ServerTime or os.time()) + (if actions.Elapsed then actions.Elapsed() else 0)
end

local function setCaption(button: TextButton, value: string)
	local caption = button:FindFirstChild("Caption")
	if caption and caption:IsA("TextLabel") then caption.Text = value end
end

local function disable(button: TextButton, value: boolean)
	button.Active = not value
	button.Selectable = not value
	local caption = button:FindFirstChild("Caption")
	if caption and caption:IsA("TextLabel") then caption.TextColor3 = if value then C.Muted else C.White end
end

function Commerce.Update(parent: GuiObject, state: any, actions: any)
	if not state then return end
	local now = serverNow(state, actions)
	local lots = {}; for _, lot in state.Auctions or {} do lots[lot.AuctionId] = lot end
	for _, object in parent:GetDescendants() do
		local at = object:GetAttribute("CommerceClockAt")
		if object:IsA("TextButton") and object.Name == "ConfirmTrade" then at = (state.Trade or {}).ReadyAt or at end
		if type(at) == "number" then
			local remaining = math.max(0, math.ceil(at - now))
			if object:IsA("TextLabel") then
				object.Text = if remaining > 0 then "ENCERRA EM " .. string.format("%02d:%02d", math.floor(remaining / 60), remaining % 60) else "ENCERRANDO..."
			elseif object:IsA("TextButton") and object.Name == "ConfirmTrade" then
				local trade = state.Trade or {}
				disable(object, remaining > 0 or trade.Phase ~= "Review" or trade.MyConfirmed == true)
				setCaption(object, if trade.MyConfirmed then "CONFIRMADO" elseif remaining > 0 then "REVISE • " .. remaining .. "s" else "CONFIRMAR TROCA")
			end
		end
		local auctionId = object:GetAttribute("CommerceAuctionId")
		local lot = if type(auctionId) == "string" then lots[auctionId] else nil
		if lot then
			if object:IsA("TextLabel") then object.Text = "MAIOR LANCE: $" .. Numbers.Format(lot.HighestBid) .. " • MÍNIMO: $" .. Numbers.Format(lot.MinimumBid)
			elseif object:IsA("TextButton") and object.Name == "CancelAuction" then
				disable(object, lot.HighestBid > 0); setCaption(object, if lot.HighestBid > 0 then "LOTE COM LANCE • AGUARDE" else "CANCELAR E RECEBER DE VOLTA")
			elseif object:IsA("TextButton") then
				setCaption(object, if lot.HighestBidderUserId == Players.LocalPlayer.UserId then "AUMENTAR LANCE" else "DAR LANCE")
			end
		end
		if object:IsA("TextButton") and object.Name == "ClaimVIP" then
			local vip = ((state.Rewards or {}).VIP or {})
			local remaining = math.max(0, math.ceil((vip.NextClaimAt or 0) - now))
			disable(object, remaining > 0 or (state.Benefits or {}).GoldenVIP ~= true)
			setCaption(object, if remaining > 0 then "BAÚ VIP EM " .. string.format("%02dh %02dm", math.floor(remaining / 3600), math.floor(remaining / 60) % 60) else "ABRIR BAÚ VIP DIÁRIO")
		end
	end
end

function Commerce.Render(parent: GuiObject, kind: string, state: any, actions: any): () -> ()
	state = state or {}
	local prefs = preferences(actions)
	local running: boolean = true
	local connections: {RBXScriptConnection} = {}
	local list = W.List(parent, "Commerce_" .. kind, UDim2.new(), UDim2.fromScale(1, 1))
	local order = 0
	local function ordered(object: GuiObject)
		order += 1; object.LayoutOrder = order
	end
	local function line(value: string, height: number?, color: Color3?): TextLabel
		local label = W.Label(list, "Hint", value, UDim2.new(), UDim2.new(1, -2, 0, height or 42), 13, color or C.Muted, true)
		label.TextWrapped = true; ordered(label)
		return label
	end
	local function card(name: string, height: number, color: Color3?): Frame
		local frame = W.Frame(list, name, UDim2.new(), UDim2.new(1, -2, 0, height), color or C.Card)
		ordered(frame); return frame
	end
	local function actionButton(name: string, value: string, color: Color3, callback: () -> (), height: number?): TextButton
		local button = W.Button(list, name, value, UDim2.new(), UDim2.new(1, -2, 0, height or 46), color, 14)
		ordered(button); button.Activated:Connect(callback)
		return button
	end
	local function textbox(container: Frame, name: string, initial: string, position: UDim2, size: UDim2, changed: (string) -> ()): TextBox
		local box = Instance.new("TextBox")
		box.Name = name; box.Position = position; box.Size = size
		box.BackgroundColor3 = C.Ink; box.TextColor3 = C.Gold; box.BorderSizePixel = 0
		box.Font = Enum.Font.GothamBold; box.TextSize = 15; box.ClearTextOnFocus = false
		box.Text = initial; box.PlaceholderText = "Moedas"; box.Parent = container
		W.Round(box, 8); W.Outline(box, 2, C.Blue)
		table.insert(connections, box:GetPropertyChangedSignal("Text"):Connect(function() changed(box.Text) end))
		return box
	end
	local function eligible(): boolean return (state.Level or 1) >= 15 and state.CurrentBiome == "TradingPlaza" end
	local function plazaHint()
		line("PRAÇA DE TROCAS • Nível 15+ • Apenas criaturas e moedas do jogo nesta sala.", 43)
		if not eligible() then
			local travel = actionButton("VisitPlaza", "IR À PRAÇA DE TROCAS", C.Blue, function() actions.Send("TravelToBiome", "TradingPlaza") end)
			disable(travel, (state.Level or 1) < 15)
		end
	end
	local function creatureRow(record: any, selected: boolean, callback: (() -> ())?, suffix: string?)
		local row = card("Creature_" .. record.Uid, 78)
		local iconHost = Instance.new("Frame")
		iconHost.BackgroundTransparency = 1; iconHost.Size = UDim2.fromOffset(46, 46); iconHost.Position = UDim2.fromOffset(8, 14); iconHost.Parent = row
		local definition = Config.Creatures[record.CreatureId]
		Icons.Draw(iconHost, if definition then definition.Element else "Paw", if selected then C.Gold else C.Blue)
		local name = W.Label(row, "Name", nameOf(record), UDim2.fromOffset(63, 7), UDim2.new(1, if callback then -157 else -74, 0, 24), 15, if selected then C.Gold else C.White)
		name.TextTruncate = Enum.TextTruncate.AtEnd
		local detail = W.Label(row, "Details", tostring(record.Mutation) .. " / " .. tostring(record.Size) .. " • $" .. Numbers.Format(record.IncomePerSec or 0) .. "/s", UDim2.fromOffset(63, 32), UDim2.new(1, if callback then -157 else -74, 0, 20), 10, C.Muted, true)
		detail.TextTruncate = Enum.TextTruncate.AtEnd
		W.Label(row, "Id", suffix or ("ID " .. string.sub(record.Uid, -8)), UDim2.fromOffset(63, 54), UDim2.new(1, -75, 0, 16), 9, C.Muted, true)
		if callback then
			local select = W.Button(row, "Select_" .. record.Uid, if selected then "ESCOLHIDA" else "ESCOLHER", UDim2.new(1, -89, 0.5, -23), UDim2.fromOffset(80, 46), if selected then C.Orange else C.Green, 10)
			select.Activated:Connect(callback)
		end
	end
	local function inventoryPage(pageKey: string, selected: (string) -> boolean, choose: (string) -> ())
		local records = state.CapturedCreatures or {}
		local pages = math.max(1, math.ceil(#records / 20))
		local page = math.clamp(prefs[pageKey] or 1, 1, pages)
		prefs[pageKey] = page
		line("MINHAS CRIATURAS • Página " .. page .. " / " .. pages, 28, C.Gold)
		for index = (page - 1) * 20 + 1, math.min(#records, page * 20) do
			local record = records[index]
			creatureRow(record, selected(record.Uid), function() choose(record.Uid) end)
		end
		if #records == 0 then line("Capture uma criatura para começar sua coleção.", 50) end
		if pages > 1 then
			local pagination = card("Pagination", 58)
			local previous = W.Button(pagination, "PreviousPage", "ANTERIOR", UDim2.fromOffset(8, 7), UDim2.new(0.5, -12, 0, 44), C.Blue, 12)
			local nextPage = W.Button(pagination, "NextPage", "PRÓXIMA", UDim2.new(0.5, 4, 0, 7), UDim2.new(0.5, -12, 0, 44), C.Purple, 12)
			disable(previous, page == 1); disable(nextPage, page == pages)
			previous.Activated:Connect(function() prefs[pageKey] = math.max(1, page - 1); actions.Refresh() end)
			nextPage.Activated:Connect(function() prefs[pageKey] = math.min(pages, page + 1); actions.Refresh() end)
		end
	end

	if kind == "Trocas" then
		plazaHint()
		local trade = state.Trade or {}
		if not trade.SessionId then
			prefs.TradeId = nil; prefs.Selected = {}
			line("Convide alguém da praça. Confira as ofertas, aceite e revise por 3 segundos antes da confirmação final.", 58)
			for _, candidate in state.TradeCandidates or {} do
				local row = card("Player_" .. candidate.UserId, 66)
				local name = W.Label(row, "Name", candidate.Name, UDim2.fromOffset(12, 7), UDim2.new(1, -127, 1, -14), 17)
				name.TextTruncate = Enum.TextTruncate.AtEnd
				local invite = W.Button(row, "Invite_" .. candidate.UserId, "CONVIDAR", UDim2.new(1, -110, 0, 10), UDim2.fromOffset(100, 46), C.Green, 12)
				disable(invite, not eligible())
				invite.Activated:Connect(function() actions.Send("TradeAction", "Invite", {TargetUserId = candidate.UserId}) end)
			end
			if #(state.TradeCandidates or {}) == 0 then line("Nenhum outro jogador está disponível na praça agora.", 55) end
		else
			if prefs.TradeId ~= trade.SessionId then
				prefs.TradeId = trade.SessionId; prefs.Selected = {}
				for _, uid in trade.MyOffer or {} do prefs.Selected[uid] = true end
			end
			local id, revision = trade.SessionId, trade.Revision
			local function sendTrade(action: string, extra: any?)
				local latest = if actions.GetState then actions.GetState() else state
				if (latest.Trade or {}).SessionId ~= id or (latest.Trade or {}).Revision ~= revision then actions.Notify("A oferta mudou. Confira a versão atual."); return end
				local payload = extra or {}; payload.SessionId = id; payload.Revision = revision
				actions.Send("TradeAction", action, payload)
			end
			line("TROCA COM " .. tostring(trade.PartnerName) .. " • OFERTA #" .. tostring(revision), 35, C.Gold)
			if trade.Phase == "Invited" then
				line(if trade.InviterUserId == Players.LocalPlayer.UserId then "Convite enviado. Aguarde a resposta do outro jogador." else "Você recebeu um convite de troca. Aceite para escolher as criaturas.", 63)
				if trade.InviterUserId ~= Players.LocalPlayer.UserId then actionButton("AcceptTrade", "ACEITAR CONVITE", C.Green, function() sendTrade("Accept") end) end
			elseif trade.Phase == "Offering" then
				local selected = {}; for uid, active in prefs.Selected do if active then table.insert(selected, uid) end end; table.sort(selected)
				line("Selecione até 8 criaturas e envie sua oferta. Toda alteração reinicia as confirmações.", 48)
				actionButton("SendOffer", "ENVIAR OFERTA • " .. #selected .. " CRIATURAS", C.Blue, function() sendTrade("Offer", {Uids = selected}) end)
				local ready = actionButton("ReadyTrade", if trade.MyReady then "PRONTO • AGUARDANDO PARCEIRO" else "ACEITAR OFERTAS PARA REVISÃO", C.Green, function() sendTrade("Ready") end)
				disable(ready, trade.MyReady == true or uidList(selected) ~= uidList(trade.MyOffer))
			elseif trade.Phase == "Review" then
				line("AS OFERTAS ESTÃO TRAVADAS. Confira nomes, variantes e renda dos dois lados antes de confirmar.", 58, C.Gold)
				local confirm = actionButton("ConfirmTrade", "REVISANDO...", C.Green, function() sendTrade("Confirm") end)
				confirm:SetAttribute("CommerceClockAt", trade.ReadyAt or 0)
				actionButton("EditOffer", "EDITAR OFERTA E RECOMEÇAR REVISÃO", C.Orange, function() sendTrade("Offer", {Uids = trade.MyOffer or {}}) end)
			else line("SALVANDO A TROCA... Aguarde a confirmação do servidor.", 65, C.Gold) end
			line("VOCÊ OFERECE", 28, C.Blue)
			local mine = {}; for _, uid in trade.MyOffer or {} do mine[uid] = true end
			for _, record in state.CapturedCreatures or {} do if mine[record.Uid] then creatureRow(record, true, nil) end end
			if #(trade.MyOffer or {}) == 0 then line("Nenhuma criatura na sua oferta.", 30) end
			line("VOCÊ RECEBE DE " .. tostring(trade.PartnerName), 30, C.Pink)
			for _, record in trade.PartnerCreatures or {} do creatureRow(record, false, nil) end
			if #(trade.PartnerOffer or {}) == 0 then line("O parceiro ainda não adicionou criaturas.", 35) end
			if trade.Phase == "Offering" then
				inventoryPage("TradePage", function(uid: string) return prefs.Selected[uid] == true end, function(uid: string)
					local count = 0; for _, active in prefs.Selected do if active then count += 1 end end
					if not prefs.Selected[uid] and count >= 8 then actions.Notify("Selecione no máximo 8 criaturas."); return end
					prefs.Selected[uid] = if prefs.Selected[uid] then nil else true; actions.Refresh()
				end)
			end
			if trade.Phase ~= "Committing" then actionButton("CancelTrade", "CANCELAR TROCA", C.Pink, function() sendTrade("Cancel") end) end
		end
	elseif kind == "Leiloes" then
		plazaHint()
		line("LEILÕES DESTA SALA • 120 segundos • Máximo de 10 lotes. Lances usam somente moedas do jogo.", 58, C.Gold)
		line("Criaturas e moedas ficam reservadas. Um lance superado é restituído; saídas ou interrupções cancelam o lote com restituição segura.", 62)
		local owned = {}; for _, record in state.CapturedCreatures or {} do owned[record.Uid] = record end
		if prefs.AuctionUid and not owned[prefs.AuctionUid] then prefs.AuctionUid = nil end
		local form = card("CreateAuction", 124)
		local chosen = owned[prefs.AuctionUid or ""]
		local summary = W.Label(form, "SelectedCreature", if chosen then "LOTE: " .. nameOf(chosen) else "ESCOLHA UMA CRIATURA ABAIXO", UDim2.fromOffset(12, 7), UDim2.new(1, -24, 0, 27), 15, C.Gold)
		summary.TextTruncate = Enum.TextTruncate.AtEnd
		W.Label(form, "PriceHint", "Lance mínimo em moedas", UDim2.fromOffset(12, 39), UDim2.new(1, -24, 0, 18), 11, C.Muted, true)
		textbox(form, "MinimumBid", prefs.MinimumBid or "10", UDim2.fromOffset(12, 65), UDim2.new(0.5, -18, 0, 46), function(value: string) prefs.MinimumBid = value end)
		local create = W.Button(form, "ListCreature", "CRIAR LEILÃO", UDim2.new(0.5, 5, 0, 65), UDim2.new(0.5, -17, 0, 46), C.Green, 12)
		disable(create, not chosen or not eligible())
		create.Activated:Connect(function()
			local amount = tonumber(prefs.MinimumBid)
			if not amount or amount <= 0 or amount == math.huge or amount % 1 ~= 0 then actions.Notify("Digite um lance mínimo inteiro e positivo."); return end
			actions.Send("AuctionAction", "List", {Uid = prefs.AuctionUid, MinimumBid = amount})
		end)
		for _, lot in state.Auctions or {} do
			local row = card("Auction_" .. lot.AuctionId, 180)
			local record = lot.Creature
			local name = W.Label(row, "Name", nameOf(record) .. " • " .. tostring(lot.SellerName), UDim2.fromOffset(12, 6), UDim2.new(1, -24, 0, 25), 16, C.Gold)
			name.TextTruncate = Enum.TextTruncate.AtEnd
			W.Label(row, "Details", tostring(record.Mutation) .. " / " .. tostring(record.Size) .. " • $" .. Numbers.Format(record.IncomePerSec or 0) .. "/s", UDim2.fromOffset(12, 34), UDim2.new(1, -24, 0, 20), 11, C.Muted, true)
			local clock = W.Label(row, "Deadline", "", UDim2.fromOffset(12, 59), UDim2.new(1, -24, 0, 20), 12, C.Pink)
			clock:SetAttribute("CommerceClockAt", lot.EndsAt)
				local bidLabel = W.Label(row, "Bid", "MAIOR LANCE: $" .. Numbers.Format(lot.HighestBid) .. " • MÍNIMO: $" .. Numbers.Format(lot.MinimumBid), UDim2.fromOffset(12, 85), UDim2.new(1, -24, 0, 22), 11, C.Green, true)
				bidLabel:SetAttribute("CommerceAuctionId", lot.AuctionId)
			if lot.SellerUserId == Players.LocalPlayer.UserId then
				local cancel = W.Button(row, "CancelAuction", if lot.HighestBid > 0 then "LOTE COM LANCE • AGUARDE" else "CANCELAR E RECEBER DE VOLTA", UDim2.fromOffset(12, 122), UDim2.new(1, -24, 0, 46), C.Orange, 12)
				cancel:SetAttribute("CommerceAuctionId", lot.AuctionId)
				disable(cancel, lot.HighestBid > 0)
				cancel.Activated:Connect(function() actions.Send("AuctionAction", "Cancel", {AuctionId = lot.AuctionId}) end)
			else
				prefs.Bids[lot.AuctionId] = prefs.Bids[lot.AuctionId] or tostring(math.max(lot.MinimumBid, lot.HighestBid + 1))
				textbox(row, "BidAmount_" .. lot.AuctionId, prefs.Bids[lot.AuctionId], UDim2.fromOffset(12, 122), UDim2.new(0.5, -18, 0, 46), function(value: string) prefs.Bids[lot.AuctionId] = value end)
				local bid = W.Button(row, "Bid_" .. lot.AuctionId, if lot.HighestBidderUserId == Players.LocalPlayer.UserId then "AUMENTAR LANCE" else "DAR LANCE", UDim2.new(0.5, 5, 0, 122), UDim2.new(0.5, -17, 0, 46), C.Green, 12)
				bid:SetAttribute("CommerceAuctionId", lot.AuctionId)
				disable(bid, not eligible())
				bid.Activated:Connect(function()
					local amount = tonumber(prefs.Bids[lot.AuctionId])
					if not amount or amount <= 0 or amount == math.huge or amount % 1 ~= 0 then actions.Notify("Digite um lance inteiro e positivo."); return end
					actions.Send("AuctionAction", "Bid", {AuctionId = lot.AuctionId, Amount = amount})
				end)
			end
		end
		if #(state.Auctions or {}) == 0 then line("Nenhum lote aberto nesta sala. Você pode criar o primeiro.", 55) end
		inventoryPage("AuctionPage", function(uid: string) return prefs.AuctionUid == uid end, function(uid: string) prefs.AuctionUid = uid; actions.Refresh() end)
	elseif kind == "GrupoVIP" then
		local groupConfigured = type(Settings.GroupId) == "number" and Settings.GroupId > 0
		local member = groupConfigured and (state.Benefits or {}).GroupMember == true
		line("GRUPO & VIP • Benefícios verificados pelo servidor", 38, C.Gold)
		local group = card("Group", 160)
		W.Label(group, "Title", if member then "MEMBRO DO GRUPO VERIFICADO" elseif groupConfigured then "GRUPO OFICIAL" else "GRUPO AINDA NÃO CONFIGURADO", UDim2.fromOffset(12, 9), UDim2.new(1, -24, 0, 30), 17, if member then C.Green else C.Blue).TextWrapped = true
		local description = W.Label(group, "Description", if groupConfigured then "+10% sorte, +1 espaço no santuário e acesso ao Auto-Treino para membros. Reentre após entrar no grupo para atualizar a verificação." else "O grupo oficial ainda não foi conectado. Os benefícios de membro não estão ativos.", UDim2.fromOffset(12, 46), UDim2.new(1, -24, 0, 55), 12, C.Muted, true)
		description.TextWrapped = true
		local groupClaim = W.Button(group, "ClaimGroup", "RECONHECER BÔNUS DE GRUPO", UDim2.fromOffset(12, 108), UDim2.new(1, -24, 0, 44), C.Green, 12)
		disable(groupClaim, not member or (state.Titles or {}).Grupo == true)
		groupClaim.Activated:Connect(function() actions.Send("ClaimGroupReward") end)
		local vipConfigured = false
		for _, item in Catalog.Items do if item.Key == "GoldenVIP" and item.Id > 0 then vipConfigured = true end end
		local vip = vipConfigured and (state.Benefits or {}).GoldenVIP == true
		line(if vip then "VIP DOURADO ATIVO" else "VIP DOURADO • LOJA EM PREPARAÇÃO", 35, C.Gold)
		line(if vip then "Seu VIP concede +25% moedas e XP, tag dourada e baú diário." else "Previsto: +25% moedas e XP, tag dourada, aura e baú diário. O passe ainda não está à venda.", 63)
		if vip then actionButton("ClaimVIP", "ABRIR BAÚ VIP DIÁRIO", C.Gold, function() actions.Send("ClaimVIPReward") end) end
		actionButton("Shop", "VER CATÁLOGO DA LOJA", C.Pink, function() actions.Open("Loja") end)
		actionButton("Automation", "VER AUTOMAÇÕES", C.Blue, function() actions.Open("Auto") end)
	end

	table.insert(connections, list:GetPropertyChangedSignal("CanvasPosition"):Connect(function() prefs.Scroll[kind] = list.CanvasPosition end))
	local scroll = prefs.Scroll[kind]
	if scroll then task.delay(0.05, function() if running and list.Parent then list.CanvasPosition = scroll end end) end
	Commerce.Update(parent, state, actions)
	return function()
		if not running then return end
		running = false
		prefs.Scroll[kind] = list.CanvasPosition
		for _, connection in connections do connection:Disconnect() end
		list:Destroy()
	end
end

return Commerce
