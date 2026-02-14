local ServerScriptService = game:GetService("ServerScriptService")

local ExampleServiceServer = require(ServerScriptService.Services.ExampleService.ExampleServiceServer)
local PlotServiceServer = require(ServerScriptService.Features.Plot.PlotServiceServer)
local SpawnServiceServer = require(ServerScriptService.Features.Spawn.SpawnServiceServer)
local PlayerDataServiceServer = require(ServerScriptService.Features.Playerdata.PlayerDataServiceServer)
local BrainrotServiceServer = require(ServerScriptService.Features.Brainrot.BrainrotServiceServer)
local UpgradeServiceServer = require(ServerScriptService.Features.Upgrade.UpgradeServiceServer)
local CataclysmServiceServer = require(ServerScriptService.Features.Cataclysm.CataclysmServiceServer)
local PvPServiceServer = require(ServerScriptService.Features.Pvp.PvPServiceServer)

ExampleServiceServer:init()
SpawnServiceServer:init() -- CharacterAutoLoads = false до спавна
PlayerDataServiceServer:init() -- Загрузка профилей, пассивный доход
UpgradeServiceServer:init(PlayerDataServiceServer) -- Прокачка скорости, вместимости, престиж
PlotServiceServer:init() -- Клеймит плоты и спавнит персонажей
BrainrotServiceServer:init() -- Спавн brainrot'ов в коридоре
CataclysmServiceServer:init(PlayerDataServiceServer) -- Катаклизмы + carry drop
PvPServiceServer:init() -- PvP knockback
