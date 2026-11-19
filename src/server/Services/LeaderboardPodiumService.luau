--!strict
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Numbers = require(Shared:WaitForChild("NumberFormatter"))
local Layout = require(Shared:WaitForChild("ConfigWorld"))
local Rankings = {}
local ctx: any
local ordered: any
local summaries: any
local lastResult: any = {Mode = "Session", UpdatedAt = 0, Boards = {Coins = {}, Capture = {}, Level = {}, Bestiary = {}}}
local busy = false
local boards: {[string]: TextLabel} = {}
local podium: {[number]: BasePart} = {}
local displayed: {[number]: string} = {}
local avatars: {[number]: Model} = {}
local keys = {"Coins", "Capture", "Level", "Bestiary"}
local titles = {Coins = "MOEDAS TOTAIS", Capture = "MELHOR CAPTURA • $/s", Level = "NÍVEL E REBIRTHS", Bestiary = "BESTIÁRIO"}

function Rankings.EncodeScore(value: number): number
    if value ~= value or value < 0 or value == math.huge then return 0 end
    return math.floor(math.log10(value + 1) * 1000000 + 0.5)
end
local function summarize(player: Player, profile: any): any
    local bestIncome, strongest = 0, nil
    local equipped: {[string]: boolean} = {}
    for _, uid in profile.SanctuarySlots or {} do equipped[uid] = true end
    for _, creature in profile.CapturedCreatures do
        bestIncome = math.max(bestIncome, creature.IncomePerSec)
        if equipped[creature.Uid] and (not strongest or creature.IncomePerSec > strongest.IncomePerSec) then
            strongest = {CreatureId = creature.CreatureId, Mutation = creature.Mutation, Size = creature.Size, IncomePerSec = creature.IncomePerSec}
        end
    end
    return {UserId = player.UserId, DisplayName = player.DisplayName, Coins = profile.TotalCoinsEarned or profile.Coins,
        Capture = bestIncome, Level = profile.Level + profile.Rebirths * 100, Bestiary = ctx.Biomes.CountBestiary(profile),
        ActualLevel = profile.Level, Rebirths = profile.Rebirths, Strongest = strongest}
end
local function sessionBoards(): any
    local result = {Coins = {}, Capture = {}, Level = {}, Bestiary = {}}
    for _, player in Players:GetPlayers() do
        local profile = ctx.Data.Get(player)
        if profile then
            local entry = summarize(player, profile)
            for _, key in keys do table.insert(result[key], entry) end
        end
    end
    for _, key in keys do table.sort(result[key], function(a, b) return if a[key] == b[key] then a.UserId < b.UserId else a[key] > b[key] end) end
    return result
end
local function globalBoards(localBoards: any): any
    if not ordered then
        local newOrdered = {}
        local prefix = Config.Constants.DataStoreName .. "_Ranks_v2_"
        for _, key in keys do newOrdered[key] = DataStoreService:GetOrderedDataStore(prefix .. key) end
        local newSummaries = DataStoreService:GetDataStore(prefix .. "Summaries")
        ordered, summaries = newOrdered, newSummaries
    end
    local cache = {}
    for _, entry in localBoards.Coins do
        summaries:SetAsync(tostring(entry.UserId), entry)
        cache[entry.UserId] = entry
        for _, key in keys do ordered[key]:SetAsync(tostring(entry.UserId), Rankings.EncodeScore(entry[key])) end
    end
    local result = {}
    for _, key in keys do
        result[key] = {}
        local page = ordered[key]:GetSortedAsync(false, 10):GetCurrentPage()
        for _, item in page do
            local userId = tonumber(item.key)
            if userId and not cache[userId] then cache[userId] = summaries:GetAsync(item.key) end
            local entry = userId and cache[userId]
            if type(entry) == "table" and type(entry.DisplayName) == "string" and type(entry[key]) == "number" then table.insert(result[key], entry) end
        end
    end
    return result
end
local function valueLabel(key: string, entry: any): string
    if key == "Coins" or key == "Capture" then return "$" .. Numbers.Format(entry[key]) .. (if key == "Capture" then "/s" else "") end
    if key == "Level" then return "NV." .. entry.ActualLevel .. " • " .. entry.Rebirths .. " rebirths" end
    return entry.Bestiary .. "/30 espécies"
end
local function displayPodium(entries: {any})
    local folder = ctx.World.GetPodiumFolder()
    if not folder then return end
    for rank = 1, 3 do
        local entry, pedestal = entries[rank], podium[rank]
        local signature = if entry then tostring(entry.UserId) .. ":" .. (if entry.Strongest then entry.Strongest.CreatureId .. entry.Strongest.Mutation .. entry.Strongest.Size else "") else ""
        if signature == displayed[rank] then continue end
        local previous = folder:FindFirstChild("Winner_" .. rank)
        if previous then previous:Destroy() end
        displayed[rank] = signature
        if not entry or not pedestal then continue end
        local holder = Instance.new("Folder")
        holder.Name, holder.Parent = "Winner_" .. rank, folder
        if not avatars[entry.UserId] and entry.UserId > 0 then
            local ok, avatar = pcall(function() return Players:CreateHumanoidModelFromUserIdAsync(entry.UserId) end)
            if ok then avatars[entry.UserId] = avatar end
        end
        if avatars[entry.UserId] then
            local avatar = avatars[entry.UserId]:Clone()
            avatar.Name = entry.DisplayName
            for _, descendant in avatar:GetDescendants() do
                if descendant:IsA("BasePart") then descendant.CanCollide = false end
                if descendant:IsA("BaseScript") then descendant.Enabled = false end
            end
            local root = avatar:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then root.Anchored = true end
            avatar:PivotTo(CFrame.new(pedestal.Position + Vector3.new(-2, pedestal.Size.Y / 2 + 3.2, 0)))
            avatar.Parent = holder
        end
        local definition = entry.Strongest and Config.Creatures[entry.Strongest.CreatureId]
        if definition and ctx.AuthoredCreatures and ctx.AuthoredCreatures[entry.Strongest.CreatureId] then
            local pet = Instance.new("Model")
            pet.Name = "StrongestCreature"
            pet:SetAttribute("CreatureId", entry.Strongest.CreatureId)
            pet:SetAttribute("Mutation", entry.Strongest.Mutation)
            pet:SetAttribute("Size", entry.Strongest.Size)
            local root = Instance.new("Part")
            root.Anchored, root.CanCollide, root.CanQuery, root.CanTouch, root.Transparency = true, false, false, false, 1
            root.Position = pedestal.Position + Vector3.new(3, pedestal.Size.Y / 2 + 1.1, 0)
            root.Parent = pet
            pet.PrimaryPart, pet.Parent = root, holder
            ctx.World.Label(root, definition.Name, Vector3.new(0, 2, 0))
            CollectionService:AddTag(pet, "PodiumCreature")
        end
        local oldLabel = pedestal:FindFirstChild("Label")
        if oldLabel then oldLabel:Destroy() end
        ctx.World.Label(pedestal, "#" .. rank .. " " .. entry.DisplayName, Vector3.new(0, 7, 0))
    end
    local used: {[number]: boolean} = {}
    for rank = 1, math.min(3, #entries) do used[entries[rank].UserId] = true end
    for userId, avatar in avatars do if not used[userId] then avatar:Destroy(); avatars[userId] = nil end end
end
local function render()
    for _, key in keys do
        local lines = {titles[key], if lastResult.Mode == "Global" then "GLOBAL" else "DESTA SESSÃO"}
        for rank, entry in lastResult.Boards[key] do if rank > 10 then break end; table.insert(lines, rank .. ". " .. entry.DisplayName .. "  " .. valueLabel(key, entry)) end
        if boards[key] then boards[key].Text = table.concat(lines, "\n") end
    end
    displayPodium(lastResult.Boards.Coins)
end
function Rankings.Refresh()
    if busy then return end
    busy = true
    local ok, problem = pcall(function()
        local localBoards = sessionBoards()
        if ctx.Data.IsPersistent and ctx.Data.IsPersistent() then
            local globalOK, globalResult = pcall(globalBoards, localBoards)
            if globalOK then lastResult = {Mode = "Global", UpdatedAt = os.time(), Boards = globalResult}
            elseif lastResult.UpdatedAt == 0 then lastResult = {Mode = "SessionFallback", UpdatedAt = os.time(), Boards = localBoards}
            else warn("[Rankings] Keeping previous result after store failure:", globalResult) end
        else lastResult = {Mode = "Session", UpdatedAt = os.time(), Boards = localBoards} end
        render()
    end)
    busy = false
    if not ok then warn("[Rankings] Refresh failed:", problem) end
end
function Rankings.GetState(): any return lastResult end
function Rankings.Init(context: any)
    ctx = context
    local folder = ctx.World.GetPodiumFolder()
    if folder then
        for rank = 1, 3 do
            local pedestal = Instance.new("Part")
            pedestal.Name, pedestal.Anchored = "Place_" .. rank, true
            local height = if rank == 1 then 6 elseif rank == 2 then 4 else 2
            pedestal.Size = Vector3.new(12, height, 10)
            pedestal.Position = Layout.HubPosition + Vector3.new(if rank == 1 then 0 elseif rank == 2 then -15 else 15, height / 2, 12)
            pedestal.Color = if rank == 1 then Color3.fromRGB(255,212,63) elseif rank == 2 then Color3.fromRGB(190,205,220) else Color3.fromRGB(190,120,65)
            pedestal.Parent, podium[rank] = folder, pedestal
        end
        for index, key in keys do
            local board = Instance.new("Part")
            board.Name, board.Anchored, board.Size = "Leaderboard_" .. key, true, Vector3.new(27, 16, 1)
            board.Position, board.Color, board.Parent = Vector3.new(-45 + (index - 1) * 30, 9, 124), Color3.fromRGB(20,26,48), folder
            local surface = Instance.new("SurfaceGui")
            surface.Name, surface.Face, surface.CanvasSize, surface.Parent = "Board", Enum.NormalId.Front, Vector2.new(700, 500), board
            local text = Instance.new("TextLabel")
            text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 1
            text.Font, text.TextSize, text.TextWrapped = Enum.Font.GothamBold, 26, true
            text.TextColor3, text.TextYAlignment, text.Parent = Color3.new(1,1,1), Enum.TextYAlignment.Top, surface
            boards[key] = text
        end
    end
    if ctx.Data.AddSnapshotProvider then ctx.Data.AddSnapshotProvider(function() return {Leaderboards = lastResult} end) end
    if ctx.Data.OnLoaded then ctx.Data.OnLoaded(function() task.defer(Rankings.Refresh) end) end
    if not ctx.DisableLoops then task.spawn(function() while true do task.wait(60); Rankings.Refresh() end end) end
end
return Rankings
