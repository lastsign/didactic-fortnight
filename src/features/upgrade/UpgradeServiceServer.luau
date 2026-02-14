local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)

local UpgradeServiceServer = {}
UpgradeServiceServer.playerDataService = nil :: any
UpgradeServiceServer.networker = (nil :: any) :: Networker.Server

function UpgradeServiceServer.init(self: UpgradeServiceServer, playerDataService: any)
	self.playerDataService = playerDataService
	self.networker = Networker.server.new(
		"UpgradeService",
		self,
		{ self.buySpeed, self.buyCarryCapacity, self.buyPlotCapacity, self.prestige }
	)

	-- Применить статы при респавне персонажа
	local function onCharacterAdded(player: Player)
		return function()
			task.defer(function()
				self:_applyStats(player)
			end)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(onCharacterAdded(player))
	end)

	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(onCharacterAdded(player))
		-- Применить к текущему персонажу если уже есть
		if player.Character then
			self:_applyStats(player)
		end
	end
end

function UpgradeServiceServer._applyStats(self: UpgradeServiceServer, player: Player)
	local data = self.playerDataService:getData(player)
	if not data then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = 16 + (data.SpeedLevel - 1) * GameConfig.SPEED_PER_LEVEL
	humanoid.JumpPower = 50 + data.JumpLevel * GameConfig.PRESTIGE_JUMP_PER_LEVEL
end

------------------------------------------------------------------------
-- Client-accessible methods (Networker)
------------------------------------------------------------------------

function UpgradeServiceServer.buySpeed(self: UpgradeServiceServer, player: Player)
	local data = self.playerDataService:getData(player)
	if not data then
		return
	end

	if data.SpeedLevel >= GameConfig.SPEED_MAX_LEVEL then
		return
	end

	local cost = GameConfig.getPlayerUpgradePrice(GameConfig.SPEED_BASE_PRICE, data.SpeedLevel)
	if not self.playerDataService:removeCoins(player, cost) then
		return
	end

	data.SpeedLevel += 1
	self.playerDataService.networker:set(player, "speedLevel", data.SpeedLevel)
	self:_applyStats(player)
end

function UpgradeServiceServer.buyCarryCapacity(self: UpgradeServiceServer, player: Player)
	local data = self.playerDataService:getData(player)
	if not data then
		return
	end

	if data.CarryCapacity >= GameConfig.CARRY_MAX_LEVEL then
		return
	end

	local cost = GameConfig.getPlayerUpgradePrice(GameConfig.CARRY_BASE_PRICE, data.CarryCapacity - 2)
	if not self.playerDataService:removeCoins(player, cost) then
		return
	end

	data.CarryCapacity += 1
	self.playerDataService.networker:set(player, "carryCapacity", data.CarryCapacity)
end

function UpgradeServiceServer.buyPlotCapacity(self: UpgradeServiceServer, player: Player)
	local data = self.playerDataService:getData(player)
	if not data then
		return
	end

	if data.PlotCapacity >= GameConfig.PLOT_CAPACITY_MAX_LEVEL then
		return
	end

	local cost = GameConfig.getPlayerUpgradePrice(GameConfig.PLOT_CAPACITY_BASE_PRICE, data.PlotCapacity - 4)
	if not self.playerDataService:removeCoins(player, cost) then
		return
	end

	data.PlotCapacity += 1
	self.playerDataService.networker:set(player, "plotCapacity", data.PlotCapacity)
end

function UpgradeServiceServer.prestige(self: UpgradeServiceServer, player: Player)
	local data = self.playerDataService:getData(player)
	if not data then
		return
	end

	if not GameConfig.canPrestige(data) then
		return
	end

	-- Сброс
	data.Coins = 0
	data.SpeedLevel = 1
	data.CarryCapacity = 3

	-- Увеличение
	data.PrestigeLevel += 1
	data.JumpLevel += 1

	-- Синхронизация всех данных
	self.playerDataService:_syncToClient(player)
	self:_applyStats(player)
end

export type UpgradeServiceServer = typeof(UpgradeServiceServer)

return UpgradeServiceServer
