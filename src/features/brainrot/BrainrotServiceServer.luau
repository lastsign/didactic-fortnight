local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)
local BrainrotBillboard = require(ReplicatedStorage.Source.Features.Brainrot.BrainrotBillboard)

local BRAINROT_TAG = "Brainrot"
local SPAWN_TAG = "BrainrotSpawn"
local PART_SIZE = Vector3.new(2, 2, 2)
local PICKUP_DEBOUNCE = 0.5

type SpawnPoint = {
	part: BasePart,
	index: number,
	zone: number,
	baseCFrame: CFrame,
}

local BrainrotServiceServer = {}
BrainrotServiceServer.spawnPoints = {} :: { [number]: SpawnPoint }
BrainrotServiceServer.activeModels = {} :: { [number]: Model }
BrainrotServiceServer.pickupDebounce = {} :: { [Player]: number }
BrainrotServiceServer.playerDataService = nil :: any

function BrainrotServiceServer.init(self: BrainrotServiceServer)
	self.playerDataService = require(ServerScriptService.Features.Playerdata.PlayerDataServiceServer)

	-- Собираем точки спавна
	for _, spawnPart in CollectionService:GetTagged(SPAWN_TAG) do
		local index = spawnPart:GetAttribute("Index") :: number
		local zone = spawnPart:GetAttribute("Zone") :: number

		if index and zone then
			self.spawnPoints[index] = {
				part = spawnPart,
				index = index,
				zone = zone,
				baseCFrame = spawnPart:GetPivot(),
			}
		else
			warn("[BrainrotService] SpawnPoint missing Index or Zone attribute:", spawnPart:GetFullName())
		end
	end

	-- Заполняем все точки
	for index, spawnPoint in self.spawnPoints do
		self:_spawnAtPoint(index, spawnPoint)
	end

	-- Очищаем дебаунс при выходе игрока
	Players.PlayerRemoving:Connect(function(player)
		self.pickupDebounce[player] = nil
	end)
end

function BrainrotServiceServer._spawnAtPoint(self: BrainrotServiceServer, index: number, spawnPoint: SpawnPoint)
	local brainrot = self:_pickRandomBrainrot(spawnPoint.zone)
	if not brainrot then
		warn("[BrainrotService] No brainrots for zone", spawnPoint.zone)
		return
	end

	local model = self:_createBrainrotModel(brainrot.id, spawnPoint.baseCFrame)
	model:SetAttribute("SpawnIndex", index)
	self.activeModels[index] = model

	self:_connectTouched(model, index)
end

function BrainrotServiceServer._pickRandomBrainrot(self: BrainrotServiceServer, zone: number): GameConfig.Brainrot?
	local pool = GameConfig.getBrainrotsForZone(zone)
	if #pool == 0 then
		return nil
	end

	-- Взвешенный случайный выбор
	local totalWeight = 0
	local weights = {}

	for i, brainrot in pool do
		local rarityInfo = GameConfig.getRarityInfo(brainrot.rarity)
		local weight = if rarityInfo then rarityInfo.weight else 1
		totalWeight += weight
		weights[i] = weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0

	for i, weight in weights do
		cumulative += weight
		if roll <= cumulative then
			return pool[i]
		end
	end

	return pool[#pool]
end

function BrainrotServiceServer._createBrainrotModel(
	self: BrainrotServiceServer,
	brainrotId: number,
	cframe: CFrame
): Model
	local brainrot = GameConfig.getBrainrot(brainrotId) :: GameConfig.Brainrot
	local rarityInfo = GameConfig.getRarityInfo(brainrot.rarity)
	local color = if rarityInfo then rarityInfo.color else Color3.fromRGB(200, 200, 200)

	local model = Instance.new("Model")
	model.Name = "Brainrot_" .. brainrot.name

	local part = Instance.new("Part")
	part.Name = "Body"
	part.Size = PART_SIZE
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = cframe
	part.Parent = model

	model.PrimaryPart = part
	model:SetAttribute("BrainrotId", brainrotId)

	CollectionService:AddTag(model, BRAINROT_TAG)

	BrainrotBillboard.create(part, brainrotId)

	model.Parent = workspace

	return model
end

function BrainrotServiceServer._connectTouched(self: BrainrotServiceServer, model: Model, spawnIndex: number)
	local primaryPart = model.PrimaryPart :: BasePart

	primaryPart.Touched:Connect(function(hit: BasePart)
		local character = hit.Parent
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		-- Дебаунс
		local now = tick()
		local lastPickup = self.pickupDebounce[player]
		if lastPickup and (now - lastPickup) < PICKUP_DEBOUNCE then
			return
		end
		self.pickupDebounce[player] = now

		-- Модель ещё существует?
		if not self.activeModels[spawnIndex] then
			return
		end

		-- Профиль загружен?
		if not self.playerDataService:isProfileLoaded(player) then
			return
		end

		-- Добавить в carry
		local brainrotId = model:GetAttribute("BrainrotId") :: number
		local success = self.playerDataService:addToCarry(player, brainrotId)
		if not success then
			return
		end

		-- Удалить модель и запланировать респавн
		self.activeModels[spawnIndex] = nil
		model:Destroy()

		local brainrot = GameConfig.getBrainrot(brainrotId)
		local rarityInfo = if brainrot then GameConfig.getRarityInfo(brainrot.rarity) else nil
		local respawnTime = if rarityInfo then rarityInfo.respawnTime else 30

		self:_scheduleRespawn(spawnIndex, respawnTime)
	end)
end

function BrainrotServiceServer._scheduleRespawn(self: BrainrotServiceServer, spawnIndex: number, delay: number)
	task.delay(delay, function()
		local spawnPoint = self.spawnPoints[spawnIndex]
		if spawnPoint then
			self:_spawnAtPoint(spawnIndex, spawnPoint)
		end
	end)
end

export type BrainrotServiceServer = typeof(BrainrotServiceServer)

return BrainrotServiceServer
