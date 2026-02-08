local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local ServicePlayerData = require(ReplicatedStorage.Packages.ServicePlayerData)

type PlotSpawn = {
	part: Model,
	index: number,
	plot: Model?,
	owner: Player?,
}

type PlayerData = {
	plotSpawn: PlotSpawn?,
}

local PLAYER_DATA_TEMPLATE: PlayerData = {
	plotSpawn = nil,
}

local PlotServiceServer = {}
PlotServiceServer.plotSpawns = {} :: { [number]: PlotSpawn }
PlotServiceServer.networker = (nil :: any) :: Networker.Server
PlotServiceServer.playerData = (nil :: any) :: ServicePlayerData.ServicePlayerData<PlayerData>

function PlotServiceServer.init(self: PlotServiceServer)
	self.networker = Networker.server.new("PlotService", self, {})
	self.playerData = ServicePlayerData.new(PLAYER_DATA_TEMPLATE :: PlayerData, self)

	local template = ReplicatedStorage.Assets.PlotStorage["1"] :: Model

	for _, plotSpawn in CollectionService:GetTagged("PlotSpawn") do
		local index = plotSpawn:GetAttribute("Index") :: number

		-- Клонируем PlotStorage на каждый baseSpawn при старте
		local plot = template:Clone()
		plot.Parent = workspace
		plot:PivotTo(plotSpawn:GetPivot())

		self.plotSpawns[index] = {
			part = plotSpawn,
			index = index,
			plot = plot,
			owner = nil,
		}
	end

	-- Игроки, которые зашли до init (Play Solo)
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:_claimPlot(player)
		end)
	end
end

function PlotServiceServer._claimPlot(self: PlotServiceServer, player: Player): PlotSpawn?
	-- Если игрок уже занял плот
	for _, plotSpawn in self.plotSpawns do
		if plotSpawn.owner == player then
			return plotSpawn
		end
	end

	-- Найти свободный
	for _, plotSpawn in self.plotSpawns do
		if not plotSpawn.owner then
			plotSpawn.owner = player
			return plotSpawn
		end
	end

	return nil
end

function PlotServiceServer.getPlotSpawn(self: PlotServiceServer, player: Player): PlotSpawn?
	for _, plotSpawn in self.plotSpawns do
		if plotSpawn.owner == player then
			return plotSpawn
		end
	end
	return nil
end

-- Вызывается автоматически ServicePlayerData при PlayerAdded
function PlotServiceServer.playerAdded(self: PlotServiceServer, player: Player, data: PlayerData)
	local plotSpawn = self:_claimPlot(player)
	if not plotSpawn then
		player:Kick("Сервер полный!")
		return
	end

	data.plotSpawn = plotSpawn
end

-- Вызывается автоматически ServicePlayerData при PlayerRemoving
function PlotServiceServer.playerRemoving(self: PlotServiceServer, _player: Player, data: PlayerData)
	if data.plotSpawn then
		data.plotSpawn.owner = nil
		data.plotSpawn = nil
	end
end

export type PlotSpawn = PlotSpawn

type PlotServiceServer = typeof(PlotServiceServer)

return PlotServiceServer
