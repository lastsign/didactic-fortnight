local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)
local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)
local DroppedBrainrot = require(ReplicatedStorage.Source.Features.Cataclysm.DroppedBrainrot)
local PlotServer = require(script.Parent.Parent.Plot.PlotServer)

local CataclysmServiceServer = {}
CataclysmServiceServer.networker = (nil :: any) :: Networker.Server
CataclysmServiceServer.playerDataService = nil :: any
CataclysmServiceServer.phase = "peace" :: "peace" | "warning" | "active"
CataclysmServiceServer.currentType = nil :: string?
CataclysmServiceServer.lastType = nil :: string?
CataclysmServiceServer._activeCleanup = nil :: (() -> ())?

function CataclysmServiceServer.init(self: CataclysmServiceServer, playerDataService: any)
	self.playerDataService = playerDataService
	self.networker = Networker.server.new("CataclysmService", self, {})

	-- Carry drop при смерти
	PlotServer.onPlayerDied = function(player: Player)
		DroppedBrainrot.dropCarry(player, playerDataService)
	end

	task.spawn(function()
		self:_mainLoop()
	end)
end

------------------------------------------------------------------------
-- Главный цикл
------------------------------------------------------------------------

function CataclysmServiceServer._mainLoop(self: CataclysmServiceServer)
	while true do
		-- Фаза покоя
		self:_setPhase("peace", nil)
		local peaceTime = math.random(GameConfig.CATACLYSM_PEACE_TIME_MIN, GameConfig.CATACLYSM_PEACE_TIME_MAX)
		task.wait(peaceTime)

		-- Выбрать катаклизм
		local cataclysmType = GameConfig.pickRandomCataclysm(self.lastType)
		self.lastType = cataclysmType

		-- Фаза предупреждения
		self:_setPhase("warning", cataclysmType)
		task.wait(GameConfig.CATACLYSM_WARNING_TIME)

		-- Фаза катаклизма
		self:_setPhase("active", cataclysmType)
		local duration = math.random(GameConfig.CATACLYSM_DURATION_MIN, GameConfig.CATACLYSM_DURATION_MAX)
		self:_startCataclysm(cataclysmType, duration)
		task.wait(duration)
		self:_stopCataclysm()
	end
end

function CataclysmServiceServer._setPhase(self: CataclysmServiceServer, phase: string, cataclysmType: string?)
	self.phase = phase :: any
	self.currentType = cataclysmType

	for _, player in Players:GetPlayers() do
		self.networker:set(player, "phase", phase)
		self.networker:set(player, "cataclysmType", cataclysmType or "")
	end
end

------------------------------------------------------------------------
-- Утилиты
------------------------------------------------------------------------

function CataclysmServiceServer._getPlayersInCorridor(self: CataclysmServiceServer): { Player }
	local result = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character or not character.PrimaryPart then
			continue
		end
		-- Считаем что все живые игроки потенциально в коридоре
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			table.insert(result, player)
		end
	end
	return result
end

function CataclysmServiceServer._damagePlayer(self: CataclysmServiceServer, player: Player, damage: number)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid:TakeDamage(damage)
	end
end

function CataclysmServiceServer._isNearTag(
	self: CataclysmServiceServer,
	player: Player,
	tag: string,
	radius: number
): boolean
	local character = player.Character
	if not character or not character.PrimaryPart then
		return false
	end

	local pos = character.PrimaryPart.Position
	for _, part in CollectionService:GetTagged(tag) do
		if (part.Position - pos).Magnitude <= radius then
			return true
		end
	end
	return false
end

------------------------------------------------------------------------
-- Катаклизмы
------------------------------------------------------------------------

function CataclysmServiceServer._startCataclysm(self: CataclysmServiceServer, cataclysmType: string, duration: number)
	if cataclysmType == "MeteorRain" then
		self:_startMeteorRain(duration)
	elseif cataclysmType == "Darkness" then
		self:_startDarkness(duration)
	elseif cataclysmType == "BlackHole" then
		self:_startBlackHole(duration)
	elseif cataclysmType == "Freeze" then
		self:_startFreeze(duration)
	end
end

function CataclysmServiceServer._stopCataclysm(self: CataclysmServiceServer)
	if self._activeCleanup then
		self._activeCleanup()
		self._activeCleanup = nil
	end
end

------------------------------------------------------------------------
-- Метеоритный дождь
------------------------------------------------------------------------

function CataclysmServiceServer._startMeteorRain(self: CataclysmServiceServer, duration: number)
	local config = GameConfig.CataclysmTypes.MeteorRain
	local running = true
	local meteors: { BasePart } = {}

	self._activeCleanup = function()
		running = false
		for _, meteor in meteors do
			if meteor.Parent then
				meteor:Destroy()
			end
		end
	end

	task.spawn(function()
		while running do
			local interval = math.random() * 2 + 1 -- 1-3 сек между метеорами

			-- Рандомная позиция в коридоре (X: -10..40, Z: -200..-100)
			local x = math.random(-10, 40)
			local z = math.random(-200, -100)
			local targetPos = Vector3.new(x, 1, z)

			-- Отправить позицию клиентам для визуала
			for _, player in Players:GetPlayers() do
				self.networker:set(player, "meteorTarget", { x = x, z = z })
			end

			-- Ждём 2 сек (время предупреждения)
			task.wait(2)

			if not running then
				break
			end

			-- Проверяем кто в зоне поражения (радиус 8 studs)
			local radius = 8
			for _, player in self:_getPlayersInCorridor() do
				local character = player.Character
				if character and character.PrimaryPart then
					local dist = (character.PrimaryPart.Position - targetPos).Magnitude
					if dist <= radius then
						self:_damagePlayer(player, config.damagePerHit)
					end
				end
			end

			-- Взрыв (визуальный Part)
			local explosion = Instance.new("Part")
			explosion.Name = "MeteorImpact"
			explosion.Shape = Enum.PartType.Ball
			explosion.Size = Vector3.new(radius * 2, 1, radius * 2)
			explosion.Position = targetPos
			explosion.Anchored = true
			explosion.CanCollide = false
			explosion.Color = Color3.fromRGB(255, 80, 0)
			explosion.Material = Enum.Material.Neon
			explosion.Transparency = 0.3
			explosion.Parent = workspace
			table.insert(meteors, explosion)

			task.delay(1, function()
				if explosion.Parent then
					explosion:Destroy()
				end
			end)

			task.wait(math.max(0, interval - 2))
		end
	end)
end

------------------------------------------------------------------------
-- Тьма + Монстр
------------------------------------------------------------------------

function CataclysmServiceServer._startDarkness(self: CataclysmServiceServer, duration: number)
	local config = GameConfig.CataclysmTypes.Darkness
	local running = true

	-- Создаём монстра (невидимый Part на сервере, позиция синхронизируется)
	local monster = Instance.new("Part")
	monster.Name = "DarknessMonster"
	monster.Size = Vector3.new(4, 8, 4)
	monster.Anchored = true
	monster.CanCollide = false
	monster.Transparency = 1
	monster.Position = Vector3.new(15, 4, -100)
	monster.Parent = workspace

	self._activeCleanup = function()
		running = false
		if monster.Parent then
			monster:Destroy()
		end
	end

	task.spawn(function()
		local direction = -1 -- движется вглубь коридора
		local zPos = -100

		while running do
			task.wait(0.1)

			-- Двигаем монстра
			zPos += direction * config.monsterSpeed * 0.1
			if zPos < -200 then
				direction = 1
			elseif zPos > -100 then
				direction = -1
			end

			monster.Position = Vector3.new(15, 4, zPos)

			-- Синхронизируем позицию клиентам
			for _, player in Players:GetPlayers() do
				self.networker:set(player, "monsterPos", { x = 15, z = zPos })
			end

			-- Проверяем касание — мгновенная смерть
			for _, player in self:_getPlayersInCorridor() do
				-- Не убивать рядом с TorchLight
				if self:_isNearTag(player, "TorchLight", 10) then
					continue
				end

				local character = player.Character
				if character and character.PrimaryPart then
					local dist = (character.PrimaryPart.Position - monster.Position).Magnitude
					if dist <= 6 then
						self:_damagePlayer(player, 9999)
					end
				end
			end
		end
	end)
end

------------------------------------------------------------------------
-- Чёрная дыра
------------------------------------------------------------------------

function CataclysmServiceServer._startBlackHole(self: CataclysmServiceServer, duration: number)
	local config = GameConfig.CataclysmTypes.BlackHole
	local running = true
	local bodyVelocities: { BodyVelocity } = {}

	-- Позиция чёрной дыры — конец коридора
	local holePosition = Vector3.new(15, 5, -200)

	self._activeCleanup = function()
		running = false
		for _, bv in bodyVelocities do
			if bv.Parent then
				bv:Destroy()
			end
		end
	end

	task.spawn(function()
		while running do
			task.wait(0.5)

			for _, player in self:_getPlayersInCorridor() do
				local character = player.Character
				if not character or not character.PrimaryPart then
					continue
				end

				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if not humanoid or humanoid.Health <= 0 then
					continue
				end

				-- Направление к чёрной дыре
				local direction = (holePosition - character.PrimaryPart.Position).Unit

				-- Применяем силу через BodyVelocity (временно)
				local existing = character.PrimaryPart:FindFirstChild("BlackHolePull")
				if not existing then
					local bv = Instance.new("BodyVelocity")
					bv.Name = "BlackHolePull"
					bv.MaxForce = Vector3.new(config.pullForce * 100, 0, config.pullForce * 100)
					bv.Velocity = direction * config.pullForce
					bv.Parent = character.PrimaryPart
					table.insert(bodyVelocities, bv)

					task.delay(0.4, function()
						if bv.Parent then
							bv:Destroy()
						end
					end)
				end

				-- Урон/сек
				self:_damagePlayer(player, config.damagePerSec * 0.5)
			end
		end
	end)
end

------------------------------------------------------------------------
-- Заморозка
------------------------------------------------------------------------

function CataclysmServiceServer._startFreeze(self: CataclysmServiceServer, duration: number)
	local config = GameConfig.CataclysmTypes.Freeze
	local running = true
	local originalSpeeds: { [Player]: number } = {}

	-- Запомнить и снизить скорость
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				originalSpeeds[player] = humanoid.WalkSpeed
				humanoid.WalkSpeed = config.slowSpeed
			end
		end
	end

	self._activeCleanup = function()
		running = false
		-- Восстановить скорость
		for player, speed in originalSpeeds do
			if player.Parent then
				local character = player.Character
				if character then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid.WalkSpeed = speed
					end
				end
			end
		end
	end

	task.spawn(function()
		while running do
			task.wait(config.damageInterval)

			if not running then
				break
			end

			for _, player in self:_getPlayersInCorridor() do
				-- Рядом с костром — безопасно
				if self:_isNearTag(player, "Campfire", 10) then
					-- Восстановить скорость рядом с костром
					local character = player.Character
					if character then
						local humanoid = character:FindFirstChildOfClass("Humanoid")
						if humanoid and originalSpeeds[player] then
							humanoid.WalkSpeed = originalSpeeds[player]
						end
					end
					continue
				end

				-- Убедиться что скорость снижена
				local character = player.Character
				if character then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid and humanoid.WalkSpeed > config.slowSpeed then
						humanoid.WalkSpeed = config.slowSpeed
					end
				end

				self:_damagePlayer(player, config.damagePerSec * config.damageInterval)
			end
		end
	end)
end

export type CataclysmServiceServer = typeof(CataclysmServiceServer)

return CataclysmServiceServer
