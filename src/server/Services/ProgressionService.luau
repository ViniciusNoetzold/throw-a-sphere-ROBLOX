--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ProgressionService = {}
local dataService: any
local sanctuaryService: any
local lastActions: { [Player]: { [string]: number } } = {}
local remotes: Folder

local function allowed(player: Player, action: string, cooldown: number): boolean
	local actions = lastActions[player]
	if not actions then
		actions = {}
		lastActions[player] = actions
	end
	local now = os.clock()
	if now - (actions[action] or -math.huge) < cooldown then
		return false
	end
	actions[action] = now
	return dataService.IsLoaded(player)
end

local function feedback(player: Player, message: string, kind: string?)
	local remote = remotes:WaitForChild("ActionFeedback") :: RemoteEvent
	remote:FireClient(player, { Message = message, Kind = kind or "Error" })
end

function ProgressionService.GrantXP(player: Player, amount: number): boolean
	local profile = dataService.Get(player)
	if not profile or amount ~= amount or amount <= 0 or amount == math.huge then
		return false
	end
	if profile.Level >= Config.Constants.MaxLevel then
		profile.XP = 0
		return false
	end
	profile.XP += math.floor(amount)
	local leveledUp = false
	while profile.Level < Config.Constants.MaxLevel and profile.XP >= Config.GetXPRequiredForLevel(profile.Level) do
		profile.XP -= Config.GetXPRequiredForLevel(profile.Level)
		profile.Level += 1
		profile.Coins += profile.Level * 25
		leveledUp = true
	end
	if profile.Level == Config.Constants.MaxLevel then
		profile.XP = 0
	end
	if leveledUp then
		sanctuaryService.Refresh(player)
	end
	dataService.MarkDirty(player)
	return leveledUp
end

function ProgressionService.Init(service: any, sanctuary: any, remoteFolder: Folder)
	dataService = service
	sanctuaryService = sanctuary
	remotes = remoteFolder
	local buyOrb = remotes:WaitForChild("BuyOrb") :: RemoteEvent
	buyOrb.OnServerEvent:Connect(function(player: Player, orbId: any, quantity: any)
		if typeof(orbId) ~= "string" or typeof(quantity) ~= "number" or quantity ~= quantity or quantity % 1 ~= 0 or quantity < 1 or quantity > 100 then
			return
		end
		if not allowed(player, "BuyOrb", 0.25) then
			return
		end
		local profile = dataService.Get(player)
		local orb = Config.Orbs[orbId]
		if not profile or not orb or orb.IsMaster or orb.Price <= 0 then
			feedback(player, "Esta orbe não está disponível por moedas.")
			return
		end
		local price = orb.Price * quantity
		if profile.Coins < price then
			feedback(player, "Moedas insuficientes. Capture criaturas ou treine para ganhar moedas.")
			return
		end
		profile.Coins -= price
		profile.Orbs[orbId] = (profile.Orbs[orbId] or 0) + quantity
		dataService.MarkDirty(player)
		dataService.Sync(player)
		feedback(player, string.format("Comprou %dx %s!", quantity, orb.Name), "Success")
	end)
	local equipOrb = remotes:WaitForChild("EquipOrb") :: RemoteEvent
	equipOrb.OnServerEvent:Connect(function(player: Player, orbId: any)
		if typeof(orbId) ~= "string" or not allowed(player, "EquipOrb", 0.2) then
			return
		end
		local profile = dataService.Get(player)
		if not profile or not Config.Orbs[orbId] or (profile.Orbs[orbId] or 0) < 1 then
			feedback(player, "Você precisa ter essa orbe no inventário.")
			return
		end
		profile.EquippedOrb = orbId
		dataService.MarkDirty(player)
		dataService.Sync(player)
	end)
	local train = remotes:WaitForChild("TrainThrowPower") :: RemoteEvent
	train.OnServerEvent:Connect(function(player: Player)
		if not allowed(player, "TrainThrowPower", 0.5) then
			return
		end
		local profile = dataService.Get(player)
		if not profile then
			return
		end
		profile.ThrowStrength = math.min(10000, profile.ThrowStrength + (Config.Constants.TrainingStrength or 1))
		profile.Coins += Config.Constants.TrainingCoins or 5
		dataService.MarkDirty(player)
		dataService.Sync(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastActions[player] = nil
	end)
end

return ProgressionService
