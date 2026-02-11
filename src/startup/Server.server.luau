local ServerScriptService = game:GetService("ServerScriptService")

local ExampleServiceServer = require(ServerScriptService.Services.ExampleService.ExampleServiceServer)
local PlotServiceServer = require(ServerScriptService.Features.Plot.PlotServiceServer)
local SpawnServiceServer = require(ServerScriptService.Features.Spawn.SpawnServiceServer)
local PlayerDataServiceServer = require(ServerScriptService.Features.Playerdata.PlayerDataServiceServer)
local BrainrotServiceServer = require(ServerScriptService.Features.Brainrot.BrainrotServiceServer)

ExampleServiceServer:init()
SpawnServiceServer:init() -- CharacterAutoLoads = false до спавна
PlayerDataServiceServer:init() -- Загрузка профилей, пассивный доход
PlotServiceServer:init() -- Клеймит плоты и спавнит персонажей
BrainrotServiceServer:init() -- Спавн brainrot'ов в коридоре
