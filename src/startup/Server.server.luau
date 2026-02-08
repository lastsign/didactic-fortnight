local ServerScriptService = game:GetService("ServerScriptService")

local ExampleServiceServer = require(ServerScriptService.Services.ExampleService.ExampleServiceServer)
local PlotServiceServer = require(ServerScriptService.Features.Plot.PlotServiceServer)
local SpawnServiceServer = require(ServerScriptService.Features.Spawn.SpawnServiceServer)

ExampleServiceServer:init()
PlotServiceServer:init() -- Сначала плоты — клеймим до спавна
SpawnServiceServer:init()
