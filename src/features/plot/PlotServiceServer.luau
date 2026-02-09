local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local ServicePlayerData = require(ReplicatedStorage.Packages.ServicePlayerData)

local PlotTypes = require(ReplicatedStorage.Source.Features.Plot.PlotTypes)
local PlotServer = require(script.Parent.PlotServer)

type PlayerData = {
	plot: PlotServer.Plot?,
}

local PLAYER_DATA_TEMPLATE: PlayerData = {
	plot = nil,
}

local PlotServiceServer = {}
PlotServiceServer.plotSpawns = {} :: { [number]: PlotTypes.PlotSpawn }
PlotServiceServer.claimedSpawns = {} :: { [number]: boolean }
PlotServiceServer.networker = (nil :: any) :: Networker.Server
PlotServiceServer.playerData = (nil :: any) :: ServicePlayerData.ServicePlayerData<PlayerData>

function PlotServiceServer.init(self: PlotServiceServer)
	self.networker = Networker.server.new("PlotService", self, {})
	self.playerData = ServicePlayerData.new(PLAYER_DATA_TEMPLATE :: PlayerData, self)

	for _, plotSpawn in CollectionService:GetTagged("PlotSpawn") do
		local index = plotSpawn:GetAttribute("Index") :: number
		self.plotSpawns[index] = {
			part = plotSpawn,
			index = index,
		}
	end

	-- Игроки, которые зашли до init (Play Solo)
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:_claimPlot(player)
		end)
	end
end

function PlotServiceServer._claimPlot(self: PlotServiceServer, player: Player): PlotServer.Plot?
	-- Найти свободный spawn
	for index, plotSpawn in self.plotSpawns do
		if not self.claimedSpawns[index] then
			self.claimedSpawns[index] = true
			local plot = PlotServer.new(plotSpawn, player)
			return plot
		end
	end

	return nil
end

function PlotServiceServer.getPlot(self: PlotServiceServer, player: Player): PlotServer.Plot?
	local data = self.playerData:get(player)
	if data then
		return data.plot
	end
	return nil
end

-- Вызывается автоматически ServicePlayerData при PlayerAdded
function PlotServiceServer.playerAdded(self: PlotServiceServer, player: Player, data: PlayerData)
	local plot = self:_claimPlot(player)
	if not plot then
		player:Kick("Сервер полный!")
		return
	end

	data.plot = plot
end

-- Вызывается автоматически ServicePlayerData при PlayerRemoving
function PlotServiceServer.playerRemoving(self: PlotServiceServer, _player: Player, data: PlayerData)
	if data.plot then
		local index = data.plot.index
		data.plot:destroy()
		self.claimedSpawns[index] = nil
		data.plot = nil
	end
end

type PlotServiceServer = typeof(PlotServiceServer)

return PlotServiceServer
