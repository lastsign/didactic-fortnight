local ServerScriptService = game:GetService("ServerScriptService")

local ExampleServiceServer = require(ServerScriptService.Services.ExampleService.ExampleServiceServer)
local PlotServiceServer = require(ServerScriptService.Features.Plot.PlotServiceServer)
local SpawnServiceServer = require(ServerScriptService.Features.Spawn.SpawnServiceServer)

ExampleServiceServer:init()
SpawnServiceServer:init() -- CharacterAutoLoads = false до спавна
PlotServiceServer:init() -- Клеймит плоты и спавнит персонажей
