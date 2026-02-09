local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlotServiceServer = require(ServerScriptService.Features.Plot.PlotServiceServer)

local RESPAWN_DELAY = 5
local CHAR_SPAWN_OFFSET = CFrame.new(0, 5, 0)

local SpawnServiceServer = {}

function SpawnServiceServer.init(self: SpawnServiceServer)
	Players.CharacterAutoLoads = false

	Players.PlayerAdded:Connect(function(player)
		self:_spawnPlayer(player)
	end)

	-- Игроки, которые зашли до init (Play Solo)
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:_spawnPlayer(player)
		end)
	end
end

function SpawnServiceServer._spawnPlayer(_self: SpawnServiceServer, player: Player)
	-- Ждём пока PlotServiceServer назначит плот
	local plotSpawn = nil
	for _ = 1, 50 do
		plotSpawn = PlotServiceServer:getPlotSpawn(player)
		if plotSpawn then
			break
		end
		task.wait(0.1)
	end

	if not plotSpawn or not plotSpawn.plot then
		return
	end

	-- Телепорт на маркер baseSpawn при каждом спавне
	local function teleportToPlot(character: Model)
		character:PivotTo(plotSpawn.part:GetPivot() * CHAR_SPAWN_OFFSET)
	end

	-- Респавн при смерти + телепорт
	player.CharacterAdded:Connect(function(character)
		teleportToPlot(character)

		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			task.wait(RESPAWN_DELAY)
			if player.Parent then
				player:LoadCharacterAsync()
			end
		end)
	end)

	-- Первый спавн
	player:LoadCharacterAsync()
	local character = player.Character or player.CharacterAdded:Wait()
	teleportToPlot(character)
end

export type SpawnServiceServer = typeof(SpawnServiceServer)

return SpawnServiceServer
