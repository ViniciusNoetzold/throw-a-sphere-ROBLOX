--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = script.Parent.Services
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WorldService = require(Services.WorldService)
local SpawnService = require(Services.SpawnService)
local DataService = require(Services.DataService)
local SanctuaryService = require(Services.SanctuaryService)
local ProgressionService = require(Services.ProgressionService)
local CaptureService = require(Services.CaptureService)

WorldService.Init()
SpawnService.Init(WorldService)
-- Register profile callbacks before starting the asynchronous load lifecycle.
SanctuaryService.Init(DataService, WorldService)
ProgressionService.Init(DataService, SanctuaryService, Remotes)
CaptureService.Init(DataService, SpawnService, ProgressionService, SanctuaryService, Remotes)
DataService.Init(Remotes)
print("[ThrowASphere] Passo 1 iniciado: mira, captura, santuário e progressão.")
