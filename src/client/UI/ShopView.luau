--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigMonetizacao"))
local Icons = require(script.Parent:WaitForChild("HUDIcons"))
type ShopItem = Catalog.ShopItem

local ShopView = {}
local BLACK = Color3.fromRGB(11, 15, 30)
local WHITE = Color3.fromRGB(255, 255, 255)
local MUTED = Color3.fromRGB(198, 211, 240)
local themes: { [string]: Color3 } = {
	Gold = Color3.fromRGB(255, 200, 60), Orange = Color3.fromRGB(255, 142, 61),
	Green = Color3.fromRGB(91, 231, 121), Blue = Color3.fromRGB(75, 156, 255),
	Violet = Color3.fromRGB(174, 110, 255), Pink = Color3.fromRGB(255, 112, 200),
	Cyan = Color3.fromRGB(61, 222, 232),
}

local function round(parent: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function stroke(parent: GuiObject, thickness: number, textStroke: boolean?, color: Color3?): UIStroke
	local outline = Instance.new("UIStroke")
	outline.Color = color or BLACK
	outline.Thickness = thickness
	outline.ApplyStrokeMode = if textStroke then Enum.ApplyStrokeMode.Contextual else Enum.ApplyStrokeMode.Border
	outline.Parent = parent
	return outline
end

local function surface(parent: GuiObject, top: Color3, bottom: Color3, rotation: number?): UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Name = "Surface"
	gradient.Color = ColorSequence.new(top, bottom)
	gradient.Rotation = rotation or 90
	gradient.Parent = parent
	return gradient
end

local function frame(parent: Instance, name: string, position: UDim2, size: UDim2, color: Color3, zIndex: number): Frame
	local item = Instance.new("Frame")
	item.Name = name
	item.Position = position
	item.Size = size
	item.BackgroundColor3 = color
	item.BorderSizePixel = 0
	item.ZIndex = zIndex
	item.Parent = parent
	return item
end

-- Eight embossed studs and three quiet diagonal bands keep the cards textured,
-- while leaving their title, benefit and unavailable purchase state easy to read.
local function cardPattern(parent: Frame)
	local pattern = frame(parent, "EmbossedPattern", UDim2.fromOffset(5, 5), UDim2.new(1, -10, 1, -10), WHITE, 31)
	pattern.BackgroundTransparency = 1
	pattern.ClipsDescendants = true
	round(pattern, 12)
	for index = 1, 3 do
		local band = frame(pattern, "Diagonal" .. index, UDim2.fromScale((index - 1) * 0.43 - 0.2, -0.5), UDim2.fromScale(0.2, 2), WHITE, 31)
		band.Rotation = -26
		band.BackgroundTransparency = 0.9
	end
	for row = 1, 2 do
		for column = 1, 4 do
			local stud = frame(pattern, "Stud" .. row .. "_" .. column, UDim2.fromScale(0.12 + (column - 1) * 0.24, if row == 1 then 0.13 else 0.7), UDim2.fromOffset(10, 10), WHITE, 31)
			stud.BackgroundTransparency = 0.87
			round(stud, 2)
			local rim = stroke(stud, 1, false, WHITE)
			rim.Transparency = 0.78
		end
	end
end

local function crystal(parent: GuiObject, name: string, position: UDim2, color: Color3)
	local gem = frame(parent, name, position, UDim2.fromOffset(20, 26), WHITE, 33)
	gem.Rotation = 24
	round(gem, 5)
	stroke(gem, 2.5)
	surface(gem, color:Lerp(WHITE, 0.6), color:Lerp(BLACK, 0.25), 125)
	local facet = frame(gem, "Facet", UDim2.fromScale(0.13, 0.08), UDim2.fromScale(0.31, 0.72), WHITE, 33)
	facet.BackgroundTransparency = 0.55
	round(facet, 3)
end

local function label(parent: Instance, name: string, value: string, size: number, boldTitle: boolean?): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.BackgroundTransparency = 1
	text.Font = if boldTitle then Enum.Font.FredokaOne else Enum.Font.GothamBold
	text.TextColor3 = WHITE
	text.TextSize = size
	text.Text = value
	text.TextWrapped = true
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Center
	text.ZIndex = 32
	text.Parent = parent
	if boldTitle then stroke(text, 2, true) end
	return text
end

local function button(parent: Instance, name: string, value: string): TextButton
	local item = Instance.new("TextButton")
	item.Name = name
	item.BackgroundColor3 = WHITE
	item.BorderSizePixel = 0
	item.Text = value
	item.Font = Enum.Font.FredokaOne
	item.TextSize = 15
	item.TextColor3 = WHITE
	item.TextWrapped = true
	item.ZIndex = 33
	item.Parent = parent
	stroke(item, 2, true)
	round(item, 9)
	surface(item, Color3.fromRGB(100, 128, 192), Color3.fromRGB(45, 59, 104))
	local edge = frame(item, "BeveledEdge", UDim2.fromOffset(1, 1), UDim2.new(1, -2, 1, -2), WHITE, 33)
	edge.BackgroundTransparency = 1
	round(edge, 9)
	stroke(edge, 2, false)
	local gleam = frame(item, "TopGloss", UDim2.fromOffset(7, 3), UDim2.new(1, -14, 0, 3), WHITE, 33)
	gleam.BackgroundTransparency = 0.48
	round(gleam, 3)
	local bottom = frame(item, "BottomBevel", UDim2.new(0, 6, 1, -5), UDim2.new(1, -12, 0, 3), BLACK, 33)
	bottom.BackgroundTransparency = 0.68
	round(bottom, 3)
	return item
end

local function buttonColor(item: TextButton, top: Color3, bottom: Color3)
	local gradient = item:FindFirstChild("Surface")
	if gradient and gradient:IsA("UIGradient") then gradient.Color = ColorSequence.new(top, bottom) end
end

local function canOffer(item: ShopItem): boolean
	return Catalog.SalesEnabled == true and item.FulfillmentReady == true
		and item.Id > 0 and item.Id < math.huge and item.Id % 1 == 0
end

-- No receipt or entitlement is ever granted by this client view.
function ShopView.Render(parent: GuiObject, notify: (string) -> ()): () -> ()
	local running: boolean = true
	local revision = 0
	local selectedCategory = "Gamepasses"
	local connections: { RBXScriptConnection } = {}
	local cardConnections: { RBXScriptConnection } = {}
	local tiles: { Frame } = {}
	local currentPrompt: string? = nil
	local root = Instance.new("Frame")
	root.Name = "ShopView"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.fromRGB(84, 80, 100)
	root.BorderSizePixel = 0
	root.ZIndex = 30
	root.Parent = parent
	round(root, 14)
	stroke(root, 3.5)
	surface(root, Color3.fromRGB(117, 109, 124), Color3.fromRGB(58, 56, 76))
	for index, point in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) } do
		local stone = frame(root, "StoneCorner" .. index, UDim2.new(point.X, if point.X == 0 then 7 else -7, point.Y, if point.Y == 0 then 7 else -7), UDim2.fromOffset(14, 14), Color3.fromRGB(123, 116, 129), 31)
		stone.AnchorPoint = point
		stone.Rotation = if index % 2 == 0 then 12 else -12
		round(stone, 4)
		stroke(stone, 1.5)
		surface(stone, Color3.fromRGB(150, 140, 154), Color3.fromRGB(80, 76, 94), 45)
	end
	local inlay = frame(root, "StoneInlay", UDim2.fromOffset(6, 6), UDim2.new(1, -12, 1, -12), Color3.fromRGB(32, 28, 50), 30)
	round(inlay, 10)
	stroke(inlay, 2.5, false, Color3.fromRGB(37, 32, 48))
	local header = frame(root, "ShopHeader", UDim2.fromOffset(12, 9), UDim2.new(1, -24, 0, 43), WHITE, 31)
	round(header, 9)
	stroke(header, 2.5)
	surface(header, Color3.fromRGB(255, 232, 89), Color3.fromRGB(248, 151, 28), 35)
	for index = 1, 8 do
		local stud = frame(header, "HeaderStud" .. index, UDim2.new(index / 9, -4, 0.5, -4), UDim2.fromOffset(9, 9), WHITE, 31)
		stud.BackgroundTransparency = 0.72
		round(stud, 2)
		local rim = stroke(stud, 1, false, Color3.fromRGB(159, 90, 17))
		rim.Transparency = 0.67
	end
	local headerInset = frame(header, "HeaderBevel", UDim2.fromOffset(4, 4), UDim2.new(1, -8, 1, -8), WHITE, 31)
	headerInset.BackgroundTransparency = 1
	round(headerInset, 7)
	local headerRim = stroke(headerInset, 1, false, Color3.fromRGB(255, 250, 181))
	headerRim.Transparency = 0.2
	local shopTitle = label(header, "ShopTitle", "LOJA", 27, true)
	shopTitle.Position = UDim2.fromOffset(38, 0)
	shopTitle.Size = UDim2.new(1, -76, 1, 0)
	shopTitle.TextXAlignment = Enum.TextXAlignment.Center
	crystal(header, "EmeraldCorner", UDim2.fromOffset(8, 8), themes.Green)
	crystal(header, "VioletCorner", UDim2.new(1, -28, 0, 8), themes.Violet)

	local tabs = Instance.new("Frame")
	tabs.Name = "ShopTabs"
	tabs.Position = UDim2.fromOffset(12, 61)
	tabs.Size = UDim2.new(1, -24, 0, 44)
	tabs.BackgroundTransparency = 1
	tabs.ZIndex = 31
	tabs.Parent = root

	local subtitle = label(root, "ShopAvailability", "CATÁLOGO EM PREPARAÇÃO · Compras indisponíveis", 12)
	subtitle.Position = UDim2.fromOffset(12, 111)
	subtitle.Size = UDim2.new(1, -24, 0, 30)
	subtitle.TextColor3 = MUTED
	subtitle.TextXAlignment = Enum.TextXAlignment.Center

	local list = Instance.new("ScrollingFrame")
	list.Name = "ShopItems"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(9, 147)
	list.Size = UDim2.new(1, -18, 1, -156)
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 5
	list.ScrollBarImageColor3 = themes.Cyan
	list.ZIndex = 31
	list.Parent = root
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 3)
	padding.PaddingLeft = UDim.new(0, 3)
	padding.PaddingRight = UDim.new(0, 11)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = list
	local grid = Instance.new("UIGridLayout")
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.CellPadding = UDim2.fromOffset(12, 12)
	grid.CellSize = UDim2.new(1, 0, 0, 182)
	grid.Parent = list

	local function alive(token: number, itemFrame: GuiObject?): boolean
		return running and revision == token and root.Parent ~= nil
			and (itemFrame == nil or itemFrame:IsDescendantOf(root))
	end

	local function resize()
		local columns = if root.AbsoluteSize.X >= 520 then 2 else 1
		grid.CellSize = UDim2.new(1 / columns, if columns == 2 then -6 else 0, 0, 182)
		local short = root.AbsoluteSize.Y < 350
		header.Visible = not short
		tabs.Position = UDim2.fromOffset(12, if short then 10 else 61)
		subtitle.Position = UDim2.fromOffset(12, if short then 59 else 111)
		local listTop = if short then 95 else 147
		list.Position = UDim2.fromOffset(9, listTop)
		list.Size = UDim2.new(1, -18, 1, -listTop - 9)
	end
	table.insert(connections, root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))

	local function clearCards()
		for _, connection in cardConnections do connection:Disconnect() end
		table.clear(cardConnections)
		for _, tile in tiles do tile:Destroy() end
		table.clear(tiles)
	end

	local function createCard(entry: ShopItem, index: number, token: number)
		local color = themes[entry.Theme] or themes.Blue
		local card = Instance.new("Frame")
		card.Name = "ShopItem_" .. entry.Key
		card.BackgroundColor3 = WHITE
		card.BorderSizePixel = 0
		card.LayoutOrder = index
		card.ZIndex = 31
		card.Parent = list
		round(card, 13)
		stroke(card, 2.5)
		local topColor = if entry.Category == "Gamepasses" then Color3.fromRGB(255, 226, 80) else color:Lerp(WHITE, 0.27)
		local bottomColor = if entry.Category == "Gamepasses" then Color3.fromRGB(239, 140, 26) else color:Lerp(Color3.fromRGB(63, 24, 118), 0.45)
		surface(card, topColor, bottomColor, 28)
		cardPattern(card)
		local innerRim = frame(card, "InnerRim", UDim2.fromOffset(4, 4), UDim2.new(1, -8, 1, -8), WHITE, 31)
		innerRim.BackgroundTransparency = 1
		round(innerRim, 10)
		local innerStroke = stroke(innerRim, 1, false, Color3.fromRGB(255, 250, 185))
		innerStroke.Transparency = 0.32
		table.insert(tiles, card)

		local iconHost = frame(card, "Icon", UDim2.fromOffset(11, 10), UDim2.fromOffset(54, 54), WHITE, 32)
		iconHost.BackgroundTransparency = 1
		local iconIds = {
			StarterPack = "Gift", TitanArms = "Sword", AutoThrow = "Bolt", DoubleCoins = "Shop",
			DoubleLuck = "Leaf", GiantSanctuary = "Paw", GoldenVIP = "Trophy", FusionXP = "Fusion",
			TripleThrow = "Orb", EternalPrism = "Cosmic", MegaCollector = "Gift", GlobalLuckTotem = "Leaf",
			SummonEvent = "Cosmic", PotionPack = "Water", SanctuarySlot = "Paw", SkipFusion = "Bolt",
		}
		Icons.Draw(iconHost, iconIds[entry.Key] or "Orb", color)
		local glyph = label(card, "IconAmount", entry.Glyph, 10, true)
		glyph.Position = UDim2.fromOffset(10, 50)
		glyph.Size = UDim2.fromOffset(56, 16)
		glyph.TextXAlignment = Enum.TextXAlignment.Center
		local title = label(card, "Name", entry.Name, 17, true)
		title.Position = UDim2.fromOffset(76, 10)
		title.Size = UDim2.new(1, -88, 0, 51)
		local descriptionBacking = frame(card, "BenefitBacking", UDim2.fromOffset(10, 66), UDim2.new(1, -20, 0, 54), BLACK, 31)
		descriptionBacking.BackgroundTransparency = 0.48
		round(descriptionBacking, 8)
		local description = label(card, "Description", "Previsto: " .. entry.Description, 12)
		description.Position = UDim2.fromOffset(13, 68)
		description.Size = UDim2.new(1, -26, 0, 48)
		description.TextYAlignment = Enum.TextYAlignment.Top
		description.TextColor3 = WHITE
		local priceBacking = frame(card, "PlannedPriceBacking", UDim2.new(0, 10, 1, -54), UDim2.new(1, -138, 0, 43), BLACK, 31)
		priceBacking.BackgroundTransparency = 0.36
		round(priceBacking, 8)
		local price = label(card, "Price", "Planejado: " .. tostring(entry.PlannedPrice) .. " Robux", 12)
		price.Position = UDim2.new(0, 13, 1, -49)
		price.Size = UDim2.new(1, -144, 0, 36)
		price.TextColor3 = WHITE
		local buy = button(card, "Purchase", "EM BREVE")
		buy.AnchorPoint = Vector2.new(1, 1)
		buy.Position = UDim2.new(1, -12, 1, -13)
		buy.Size = UDim2.fromOffset(112, 44)
		buttonColor(buy, Color3.fromRGB(119, 174, 108), Color3.fromRGB(53, 97, 57))
		buy.TextColor3 = Color3.fromRGB(232, 239, 220)
		buy.Active = false
		buy.Selectable = false
		buy.AutoButtonColor = false
		local scale = Instance.new("UIScale")
		scale.Parent = buy
		local buyable: boolean = false
		local function bounce(value: number)
			if not buyable or not alive(token, card) then return end
			TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = value }):Play()
		end
		table.insert(cardConnections, buy.MouseEnter:Connect(function() bounce(1.04) end))
		table.insert(cardConnections, buy.MouseLeave:Connect(function() bounce(1) end))
		table.insert(cardConnections, buy.MouseButton1Down:Connect(function() bounce(0.96) end))
		table.insert(cardConnections, buy.MouseButton1Up:Connect(function() bounce(1) end))
		table.insert(cardConnections, buy.Activated:Connect(function()
			if not alive(token, card) or not buyable or not canOffer(entry) or currentPrompt then return end
			currentPrompt = entry.Key
			local ok = pcall(function()
				if entry.Kind == "GamePass" then
					MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, entry.Id)
				else
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, entry.Id)
				end
			end)
			if not ok then
				currentPrompt = nil
				if alive(token, card) then notify("Não foi possível abrir a compra. Tente novamente mais tarde.") end
			end
		end))

		if not canOffer(entry) then return end
		buy.Text = "CONSULTANDO..."
		price.Text = "Consultando Roblox..."
		task.spawn(function()
			local ok, productInfo = pcall(function()
				return MarketplaceService:GetProductInfoAsync(entry.Id, if entry.Kind == "GamePass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
			end)
			if not alive(token, card) then return end
			if not ok or type(productInfo) ~= "table" or type(productInfo.PriceInRobux) ~= "number"
				or productInfo.PriceInRobux ~= productInfo.PriceInRobux or productInfo.PriceInRobux < 0
				or productInfo.PriceInRobux >= math.huge or productInfo.IsForSale == false then
				buy.Text = "INDISPONÍVEL"
				price.Text = "Preço indisponível"
				return
			end
			if entry.Kind == "GamePass" then
				local checked, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(Players.LocalPlayer.UserId, entry.Id)
				end)
				if not alive(token, card) then return end
				if not checked then
					buy.Text = "INDISPONÍVEL"
					price.Text = "Tente mais tarde"
					return
				elseif owns then
					buy.Text = "JÁ POSSUI"
					price.Text = "Passe permanente"
					return
				end
			end
			if not canOffer(entry) then return end
			price.Text = tostring(productInfo.PriceInRobux) .. " Robux"
			buy.Text = "COMPRAR"
			buttonColor(buy, Color3.fromRGB(161, 255, 66), Color3.fromRGB(35, 160, 57))
			buy.TextColor3 = WHITE
			buy.Active = true
			buy.Selectable = true
			buy.AutoButtonColor = true
			buyable = true
		end)
	end

	local tabButtons: { [string]: TextButton } = {}
	local function render(category: string)
		if not running then return end
		revision += 1
		selectedCategory = category
		clearCards()
		list.CanvasPosition = Vector2.zero
		for key, tab in tabButtons do
			buttonColor(tab, if key == category then themes.Gold else Color3.fromRGB(132, 122, 180), if key == category then themes.Orange else Color3.fromRGB(65, 56, 107))
		end
		local index = 0
		for _, item in Catalog.Items do
			if item.Category == category and item.Key ~= "EternalPrism" then
				index += 1
				createCard(item, index, revision)
			end
		end
		resize()
	end
	for index, tab in { { Key = "Gamepasses", Name = "Gamepasses" }, { Key = "Boosts", Name = "Totens & Poções" } } do
		local item = button(tabs, tab.Key, tab.Name)
		item.TextSize = 13
		item.Position = UDim2.new((index - 1) / 2, if index == 1 then 0 else 3, 0, 0)
		item.Size = UDim2.new(1 / 2, -5, 1, 0)
		tabButtons[tab.Key] = item
		table.insert(connections, item.Activated:Connect(function() render(tab.Key) end))
	end
	if Catalog.SalesEnabled == true then subtitle.Text = "Confira o preço atual no Roblox antes de comprar." end
	table.insert(connections, MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, _purchased: boolean)
		if not running or player ~= Players.LocalPlayer or not currentPrompt then return end
		for _, item in Catalog.Items do
			if item.Kind == "GamePass" and item.Id == passId and item.Key == currentPrompt then
				currentPrompt = nil
				render(selectedCategory)
				return
			end
		end
	end))
	table.insert(connections, MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId: number, productId: number, _purchased: boolean)
		if not running or userId ~= Players.LocalPlayer.UserId or not currentPrompt then return end
		for _, item in Catalog.Items do
			if item.Kind == "Product" and item.Id == productId and item.Key == currentPrompt then
				currentPrompt = nil -- Only the server receipt handler can confirm delivery.
				return
			end
		end
	end))
	render("Gamepasses")
	return function()
		if not running then return end
		running = false
		revision += 1
		clearCards()
		for _, connection in connections do connection:Disconnect() end
		table.clear(connections)
		root:Destroy()
	end
end

return ShopView
