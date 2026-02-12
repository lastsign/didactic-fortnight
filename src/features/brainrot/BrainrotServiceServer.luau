local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)
local BrainrotBillboard = require(ReplicatedStorage.Source.Features.Brainrot.BrainrotBillboard)
local UpgradeButton = require(ReplicatedStorage.Source.Features.Brainrot.UpgradeButton)

local BRAINROT_TAG = "Brainrot"
local SPAWN_TAG = "BrainrotSpawn"
local BRAINROT_MODEL_TAG = "BrainrotModel"
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
BrainrotServiceServer.plotService = nil :: any
BrainrotServiceServer.modelTemplates = {} :: { [number]: Model }
BrainrotServiceServer.upgradeButtons = {} :: { [string]: UpgradeButton.UpgradeButton }

function BrainrotServiceServer.init(self: BrainrotServiceServer)
	self.playerDataService = require(ServerScriptService.Features.Playerdata.PlayerDataServiceServer)
	self.plotService = require(ServerScriptService.Features.Plot.PlotServiceServer)

	-- Собираем шаблоны моделей brainrot'ов
	for _, modelTemplate in CollectionService:GetTagged(BRAINROT_MODEL_TAG) do
		local id = modelTemplate:GetAttribute("BrainrotId") :: number
		if id then
			self.modelTemplates[id] = modelTemplate
		else
			warn("[BrainrotService] BrainrotModel missing BrainrotId attribute:", modelTemplate:GetFullName())
		end
	end

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

	-- Подключаем колбэки на PlayerDataService
	self:_wireCallbacks()
end

------------------------------------------------------------------------
-- Колбэки для визуализации на плоте
------------------------------------------------------------------------

function BrainrotServiceServer._wireCallbacks(self: BrainrotServiceServer)
	self.playerDataService.onBrainrotDeposited = function(player: Player, brainrotId: number, slot: number)
		self:_placeBrainrotOnPlot(player, brainrotId, slot)
	end

	self.playerDataService.onBrainrotRemoved = function(player: Player, slot: number)
		self:_removeBrainrotFromPlot(player, slot)
	end

	self.playerDataService.onBrainrotUpgraded = function(player: Player, brainrotId: number, slot: number, newLevel: number)
		self:_updatePlotBrainrot(player, brainrotId, slot, newLevel)
	end

	self.playerDataService.onProfileLoaded = function(player: Player)
		self:_restorePlotVisuals(player)
	end
end

function BrainrotServiceServer._placeBrainrotOnPlot(
	self: BrainrotServiceServer,
	player: Player,
	brainrotId: number,
	slot: number
)
	local plot = self.plotService:getPlot(player)
	if not plot then
		return
	end

	local brainrot = GameConfig.getBrainrot(brainrotId)
	if not brainrot then
		return
	end

	local model = self:_createPlotModel(brainrotId)
	if not model then
		return
	end

	plot:placeModelAtSlot(slot, model)

	-- Добавить SurfaceGui кнопку для апгрейда на PlotSlot
	local slotPart = plot:getSlotPart(slot)
	if slotPart then
		self:_createUpgradeButton(slotPart, player, brainrotId, slot)
	end
end

function BrainrotServiceServer._removeBrainrotFromPlot(
	self: BrainrotServiceServer,
	player: Player,
	slot: number
)
	local plot = self.plotService:getPlot(player)
	if not plot then
		return
	end

	-- Убрать SurfaceGui и ClickDetector со слота
	local slotPart = plot:getSlotPart(slot)
	if slotPart then
		local oldGui = slotPart:FindFirstChild("UpgradeGui")
		if oldGui then
			oldGui:Destroy()
		end
		local oldClick = slotPart:FindFirstChild("UpgradeClick")
		if oldClick then
			oldClick:Destroy()
		end
	end

	plot:removeModelAtSlot(slot)
end

function BrainrotServiceServer._updatePlotBrainrot(
	self: BrainrotServiceServer,
	player: Player,
	brainrotId: number,
	slot: number,
	newLevel: number
)
	local plot = self.plotService:getPlot(player)
	if not plot then
		return
	end

	local slotPart = plot:getSlotPart(slot)
	if not slotPart then
		return
	end

	local upgradeGui = slotPart:FindFirstChild("UpgradeGui") :: SurfaceGui?
	if not upgradeGui then
		return
	end

	local brainrot = GameConfig.getBrainrot(brainrotId)
	if newLevel >= GameConfig.UPGRADE_MAX_LEVEL then
		local label = upgradeGui:FindFirstChild("UpgradeLabel") :: TextButton?
		if label then
			label.Text = brainrot.name .. " Lv.MAX"
		end
	else
		local nextCost = GameConfig.getUpgradeCost(brainrotId, newLevel)
		local label = upgradeGui:FindFirstChild("UpgradeLabel") :: TextButton?
		if label then
			label.Text = brainrot.name .. " Lv." .. tostring(newLevel) .. "\nUpgrade $" .. tostring(nextCost)
		end
	end
end

function BrainrotServiceServer._createUpgradeButton(
	self: BrainrotServiceServer,
	slotPart: BasePart,
	player: Player,
	brainrotId: number,
	slot: number
)
	local key = tostring(player.UserId) .. "_" .. tostring(slot)

	-- Удалить старую кнопку если есть
	local oldButton = self.upgradeButtons[key]
	if oldButton then
		oldButton:destroy()
		self.upgradeButtons[key] = nil
	end
	local oldClick = slotPart:FindFirstChild("UpgradeClick")
	if oldClick then
		oldClick:Destroy()
	end

	local brainrot = GameConfig.getBrainrot(brainrotId)
	if not brainrot then
		return
	end

	local entry = self.playerDataService:getInventoryEntry(player, slot)
	local currentLevel = if entry then (entry.level or 1) else 1
	local isMaxLevel = currentLevel >= GameConfig.UPGRADE_MAX_LEVEL
	local cost = if not isMaxLevel then GameConfig.getUpgradeCost(brainrotId, currentLevel) else nil

	local button = UpgradeButton.new({
		part = slotPart,
		name = brainrot.name,
		level = currentLevel,
		cost = cost,
		isMaxLevel = isMaxLevel,
	})

	self.upgradeButtons[key] = button

	-- ClickDetector для серверного клика
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.Name = "UpgradeClick"
	clickDetector.MaxActivationDistance = 15
	clickDetector.Parent = slotPart

	clickDetector.MouseClick:Connect(function(clickPlayer: Player)
		if clickPlayer ~= player then
			return
		end
		self.playerDataService:upgradeBrainrot(player, slot)
	end)
end

function BrainrotServiceServer._restorePlotVisuals(self: BrainrotServiceServer, player: Player)
	local data = self.playerDataService:getData(player)
	if not data then
		return
	end

	for _, entry in data.Inventory do
		self:_placeBrainrotOnPlot(player, entry.id, entry.slot)
	end
end

function BrainrotServiceServer._createPlotModel(self: BrainrotServiceServer, brainrotId: number): Model?
	local brainrot = GameConfig.getBrainrot(brainrotId)
	if not brainrot then
		return nil
	end

	local template = self.modelTemplates[brainrotId]
	local model: Model

	if template then
		model = template:Clone()
		model.Name = "PlotBrainrot_" .. brainrot.name

		for _, desc in model:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
			end
		end

		if not model.PrimaryPart then
			local firstPart = model:FindFirstChildWhichIsA("BasePart", true)
			if firstPart then
				model.PrimaryPart = firstPart :: BasePart
			end
		end
	else
		local rarityInfo = GameConfig.getRarityInfo(brainrot.rarity)
		local color = if rarityInfo then rarityInfo.color else Color3.fromRGB(200, 200, 200)

		model = Instance.new("Model")
		model.Name = "PlotBrainrot_" .. brainrot.name

		local part = Instance.new("Part")
		part.Name = "Body"
		part.Size = PART_SIZE
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.Parent = model

		model.PrimaryPart = part
	end

	if model.PrimaryPart then
		BrainrotBillboard.create(model.PrimaryPart, brainrotId)
	end

	return model
end

------------------------------------------------------------------------
-- Спавн brainrot'ов в коридоре
------------------------------------------------------------------------

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

	local template = self.modelTemplates[brainrotId]
	local model: Model

	if template then
		model = template:Clone()
		model.Name = "Brainrot_" .. brainrot.name
		model:PivotTo(cframe)

		for _, desc in model:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
			end
		end

		if not model.PrimaryPart then
			local firstPart = model:FindFirstChildWhichIsA("BasePart", true)
			if firstPart then
				model.PrimaryPart = firstPart :: BasePart
			end
		end
	else
		local color = if rarityInfo then rarityInfo.color else Color3.fromRGB(200, 200, 200)

		model = Instance.new("Model")
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
	end

	model:SetAttribute("BrainrotId", brainrotId)
	CollectionService:AddTag(model, BRAINROT_TAG)

	if model.PrimaryPart then
		BrainrotBillboard.create(model.PrimaryPart, brainrotId)
	end

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
		local brainrotRarityInfo = if brainrot then GameConfig.getRarityInfo(brainrot.rarity) else nil
		local respawnTime = if brainrotRarityInfo then brainrotRarityInfo.respawnTime else 30

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
