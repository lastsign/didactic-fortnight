local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Networker = require(ReplicatedStorage.Packages.Networker)
local ProfileService = require(ServerScriptService.ServerPackages.ProfileService)

local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)

local PROFILE_TEMPLATE = {
	Coins = 0,
	Inventory = {},
	SpeedLevel = 1,
	PrestigeLevel = 0,
	JumpLevel = 1,
	PlotCapacity = 5,
	CarryCapacity = 3,
	TotalEarnings = 0,
}

local PlayerDataServiceServer = {}
PlayerDataServiceServer.profileStore = nil :: any
PlayerDataServiceServer.profiles = {} :: { [Player]: any }
PlayerDataServiceServer.carryInventory = {} :: { [Player]: { number } }
PlayerDataServiceServer.networker = (nil :: any) :: Networker.Server
PlayerDataServiceServer.onBrainrotDeposited = nil :: ((player: Player, brainrotId: number, slot: number) -> ())?
PlayerDataServiceServer.onBrainrotRemoved = nil :: ((player: Player, slot: number) -> ())?
PlayerDataServiceServer.onBrainrotUpgraded = nil :: ((player: Player, brainrotId: number, slot: number, newLevel: number) -> ())?
PlayerDataServiceServer.onProfileLoaded = nil :: ((player: Player) -> ())?

function PlayerDataServiceServer.init(self: PlayerDataServiceServer)
	self.profileStore = ProfileService.GetProfileStore("PlayerData", PROFILE_TEMPLATE)
	self.networker = Networker.server.new("PlayerDataService", self, { self.depositOneBrainrot, self.upgradeBrainrot })

	Players.PlayerAdded:Connect(function(player)
		self:_loadProfile(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_releaseProfile(player)
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:_loadProfile(player)
		end)
	end

	task.spawn(function()
		self:_incomeLoop()
	end)
end

-- Загрузка профиля при заходе игрока
function PlayerDataServiceServer._loadProfile(self: PlayerDataServiceServer, player: Player)
	local profile = self.profileStore:LoadProfileAsync("Player_" .. player.UserId)

	if not profile then
		player:Kick("Не удалось загрузить данные. Попробуй позже.")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile:ListenToRelease(function()
		self.profiles[player] = nil
		self.carryInventory[player] = nil
		if player.Parent then
			player:Kick("Данные были загружены в другой сессии.")
		end
	end)

	if not player:IsDescendantOf(Players) then
		profile:Release()
		return
	end

	self.profiles[player] = profile
	self.carryInventory[player] = {}

	-- Миграция: добавить level = 1 для старых записей
	for _, entry in profile.Data.Inventory do
		if entry.level == nil then
			entry.level = 1
		end
	end

	self:_syncToClient(player)

	if self.onProfileLoaded then
		self.onProfileLoaded(player)
	end
end

-- Освобождение профиля при выходе
function PlayerDataServiceServer._releaseProfile(self: PlayerDataServiceServer, player: Player)
	local profile = self.profiles[player]
	if profile then
		profile:Release()
	end
	self.profiles[player] = nil
	self.carryInventory[player] = nil
end

-- Пассивный доход: каждую секунду
function PlayerDataServiceServer._incomeLoop(self: PlayerDataServiceServer)
	while true do
		task.wait(1)

		for player, profile in self.profiles do
			if not player.Parent then
				continue
			end

			local data = profile.Data
			local totalIncome = 0

			for _, entry in data.Inventory do
				local level = entry.level or 1
				totalIncome += GameConfig.getIncomeForLevel(entry.id, level)
			end

			local prestigeMultiplier = 1 + (data.PrestigeLevel * GameConfig.PRESTIGE_BONUS_PER_LEVEL)
			totalIncome = math.floor(totalIncome * prestigeMultiplier)

			if totalIncome > 0 then
				data.Coins += totalIncome
				data.TotalEarnings += totalIncome
				self.networker:set(player, "coins", data.Coins)
			end

			self.networker:set(player, "incomePerSec", totalIncome)
		end
	end
end

-- Синхронизация всех данных клиенту
function PlayerDataServiceServer._syncToClient(self: PlayerDataServiceServer, player: Player)
	local profile = self.profiles[player]
	if not profile then
		return
	end

	local data = profile.Data
	local carry = self.carryInventory[player] or {}

	self.networker:set(player, "coins", data.Coins)
	self.networker:set(player, "inventory", data.Inventory)
	self.networker:set(player, "inventoryCount", #data.Inventory)
	self.networker:set(player, "plotCapacity", data.PlotCapacity)
	self.networker:set(player, "carryCount", #carry)
	self.networker:set(player, "carryCapacity", data.CarryCapacity)
	self.networker:set(player, "speedLevel", data.SpeedLevel)
	self.networker:set(player, "prestigeLevel", data.PrestigeLevel)
	self.networker:set(player, "jumpLevel", data.JumpLevel)
	self.networker:set(player, "totalEarnings", data.TotalEarnings)

	-- Рассчитать текущий доход
	local totalIncome = 0
	for _, entry in data.Inventory do
		local level = entry.level or 1
		totalIncome += GameConfig.getIncomeForLevel(entry.id, level)
	end
	local prestigeMultiplier = 1 + (data.PrestigeLevel * GameConfig.PRESTIGE_BONUS_PER_LEVEL)
	totalIncome = math.floor(totalIncome * prestigeMultiplier)
	self.networker:set(player, "incomePerSec", totalIncome)
end

------------------------------------------------------------------------
-- Публичное API (для других серверных сервисов)
------------------------------------------------------------------------

function PlayerDataServiceServer.isProfileLoaded(self: PlayerDataServiceServer, player: Player): boolean
	return self.profiles[player] ~= nil
end

function PlayerDataServiceServer.getData(self: PlayerDataServiceServer, player: Player)
	local profile = self.profiles[player]
	if profile then
		return profile.Data
	end
	return nil
end

function PlayerDataServiceServer.addCoins(self: PlayerDataServiceServer, player: Player, amount: number)
	local profile = self.profiles[player]
	if not profile then
		return
	end

	profile.Data.Coins += amount
	profile.Data.TotalEarnings += amount
	self.networker:set(player, "coins", profile.Data.Coins)
end

function PlayerDataServiceServer.removeCoins(self: PlayerDataServiceServer, player: Player, amount: number): boolean
	local profile = self.profiles[player]
	if not profile then
		return false
	end

	if profile.Data.Coins < amount then
		return false
	end

	profile.Data.Coins -= amount
	self.networker:set(player, "coins", profile.Data.Coins)
	return true
end

function PlayerDataServiceServer.addBrainrotToInventory(
	self: PlayerDataServiceServer,
	player: Player,
	brainrotId: number
): boolean
	local profile = self.profiles[player]
	if not profile then
		return false
	end

	local data = profile.Data
	if #data.Inventory >= data.PlotCapacity then
		return false
	end

	-- Найти свободный слот
	local usedSlots = {}
	for _, entry in data.Inventory do
		usedSlots[entry.slot] = true
	end

	local freeSlot = nil
	for i = 1, data.PlotCapacity do
		if not usedSlots[i] then
			freeSlot = i
			break
		end
	end

	if not freeSlot then
		return false
	end

	table.insert(data.Inventory, { id = brainrotId, slot = freeSlot, level = 1 })

	self.networker:set(player, "inventory", data.Inventory)
	self.networker:set(player, "inventoryCount", #data.Inventory)

	-- Пересчитать доход
	self:_syncIncomeToClient(player)

	if self.onBrainrotDeposited then
		self.onBrainrotDeposited(player, brainrotId, freeSlot)
	end

	return true
end

function PlayerDataServiceServer.removeBrainrotFromInventory(
	self: PlayerDataServiceServer,
	player: Player,
	slot: number
)
	local profile = self.profiles[player]
	if not profile then
		return
	end

	local data = profile.Data
	for i, entry in data.Inventory do
		if entry.slot == slot then
			table.remove(data.Inventory, i)
			break
		end
	end

	self.networker:set(player, "inventory", data.Inventory)
	self.networker:set(player, "inventoryCount", #data.Inventory)
	self:_syncIncomeToClient(player)

	if self.onBrainrotRemoved then
		self.onBrainrotRemoved(player, slot)
	end
end

function PlayerDataServiceServer.addToCarry(
	self: PlayerDataServiceServer,
	player: Player,
	brainrotId: number
): boolean
	local profile = self.profiles[player]
	if not profile then
		return false
	end

	local carry = self.carryInventory[player]
	if not carry then
		return false
	end

	if #carry >= profile.Data.CarryCapacity then
		return false
	end

	table.insert(carry, brainrotId)
	self.networker:set(player, "carryCount", #carry)
	return true
end

function PlayerDataServiceServer.getCarryInventory(self: PlayerDataServiceServer, player: Player): { number }
	return self.carryInventory[player] or {}
end

function PlayerDataServiceServer.clearCarry(self: PlayerDataServiceServer, player: Player)
	self.carryInventory[player] = {}
	self.networker:set(player, "carryCount", 0)
end

------------------------------------------------------------------------
-- Клиентские методы (Networker clientAccess)
------------------------------------------------------------------------

-- Сдать одного brainrot'а с рук на плот
function PlayerDataServiceServer.depositOneBrainrot(self: PlayerDataServiceServer, player: Player)
	local profile = self.profiles[player]
	if not profile then
		return
	end

	local carry = self.carryInventory[player]
	if not carry or #carry == 0 then
		return
	end

	local data = profile.Data
	if #data.Inventory >= data.PlotCapacity then
		return
	end

	local brainrotId = table.remove(carry, 1)
	self.networker:set(player, "carryCount", #carry)
	self:addBrainrotToInventory(player, brainrotId)
end

-- Улучшить brainrot'а на плоте
function PlayerDataServiceServer.upgradeBrainrot(self: PlayerDataServiceServer, player: Player, slot: number)
	local profile = self.profiles[player]
	if not profile then
		return
	end

	local data = profile.Data
	local entry = nil
	for _, e in data.Inventory do
		if e.slot == slot then
			entry = e
			break
		end
	end

	if not entry then
		return
	end

	if (entry.level or 1) >= GameConfig.UPGRADE_MAX_LEVEL then
		return
	end

	local cost = GameConfig.getUpgradeCost(entry.id, entry.level or 1)
	if not self:removeCoins(player, cost) then
		return
	end

	entry.level = (entry.level or 1) + 1

	self.networker:set(player, "inventory", data.Inventory)
	self:_syncIncomeToClient(player)

	if self.onBrainrotUpgraded then
		self.onBrainrotUpgraded(player, entry.id, slot, entry.level)
	end
end

-- Сдать всех brainrot'ов (внутренний API)
function PlayerDataServiceServer.depositBrainrots(self: PlayerDataServiceServer, player: Player)
	local profile = self.profiles[player]
	if not profile then
		return
	end

	local carry = self.carryInventory[player]
	if not carry or #carry == 0 then
		return
	end

	local data = profile.Data
	for _, brainrotId in carry do
		if #data.Inventory >= data.PlotCapacity then
			break
		end
		self:addBrainrotToInventory(player, brainrotId)
	end

	self:clearCarry(player)
end

------------------------------------------------------------------------
-- Утилиты
------------------------------------------------------------------------

function PlayerDataServiceServer.getInventoryEntry(self: PlayerDataServiceServer, player: Player, slot: number)
	local profile = self.profiles[player]
	if not profile then
		return nil
	end
	for _, entry in profile.Data.Inventory do
		if entry.slot == slot then
			return entry
		end
	end
	return nil
end

function PlayerDataServiceServer._syncIncomeToClient(self: PlayerDataServiceServer, player: Player)
	local profile = self.profiles[player]
	if not profile then
		return
	end

	local data = profile.Data
	local totalIncome = 0
	for _, entry in data.Inventory do
		local level = entry.level or 1
		totalIncome += GameConfig.getIncomeForLevel(entry.id, level)
	end

	local prestigeMultiplier = 1 + (data.PrestigeLevel * GameConfig.PRESTIGE_BONUS_PER_LEVEL)
	totalIncome = math.floor(totalIncome * prestigeMultiplier)
	self.networker:set(player, "incomePerSec", totalIncome)
end

export type PlayerDataServiceServer = typeof(PlayerDataServiceServer)

return PlayerDataServiceServer
