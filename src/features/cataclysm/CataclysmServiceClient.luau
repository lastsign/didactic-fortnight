local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Networker = require(ReplicatedStorage.Packages.Networker)

local CataclysmServiceClient = {}
CataclysmServiceClient.networker = (nil :: any) :: Networker.Client
CataclysmServiceClient.phase = "peace"
CataclysmServiceClient.cataclysmType = ""
CataclysmServiceClient._cleanupEffects = nil :: (() -> ())?

-- Сохраняем оригинальные настройки Lighting
CataclysmServiceClient._originalLighting = {
	Ambient = Color3.fromRGB(128, 128, 128),
	OutdoorAmbient = Color3.fromRGB(128, 128, 128),
	FogEnd = 100000,
	FogColor = Color3.fromRGB(192, 192, 192),
}

function CataclysmServiceClient.init(self: CataclysmServiceClient)
	self.networker = Networker.client.new("CataclysmService", self)

	-- Сохранить текущие настройки
	self._originalLighting.Ambient = Lighting.Ambient
	self._originalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
	self._originalLighting.FogEnd = Lighting.FogEnd
	self._originalLighting.FogColor = Lighting.FogColor

	self.networker:getServerChangedSignal("phase"):Connect(function(val)
		self.phase = val
		self:_onPhaseChanged()
	end)

	self.networker:getServerChangedSignal("cataclysmType"):Connect(function(val)
		self.cataclysmType = val
	end)
end

function CataclysmServiceClient._onPhaseChanged(self: CataclysmServiceClient)
	-- Очистить предыдущие эффекты
	if self._cleanupEffects then
		self._cleanupEffects()
		self._cleanupEffects = nil
	end

	if self.phase == "active" then
		self:_startEffects()
	elseif self.phase == "peace" then
		self:_restoreLighting()
	end
end

function CataclysmServiceClient._restoreLighting(self: CataclysmServiceClient)
	Lighting.Ambient = self._originalLighting.Ambient
	Lighting.OutdoorAmbient = self._originalLighting.OutdoorAmbient
	Lighting.FogEnd = self._originalLighting.FogEnd
	Lighting.FogColor = self._originalLighting.FogColor
end

function CataclysmServiceClient._startEffects(self: CataclysmServiceClient)
	local catType = self.cataclysmType

	if catType == "MeteorRain" then
		self:_effectMeteorRain()
	elseif catType == "Darkness" then
		self:_effectDarkness()
	elseif catType == "BlackHole" then
		self:_effectBlackHole()
	elseif catType == "Freeze" then
		self:_effectFreeze()
	end
end

------------------------------------------------------------------------
-- Метеоритный дождь — красные круги + падающие Part'ы
------------------------------------------------------------------------

function CataclysmServiceClient._effectMeteorRain(self: CataclysmServiceClient)
	local visuals: { Instance } = {}

	-- Слегка красноватое небо
	Lighting.Ambient = Color3.fromRGB(100, 40, 30)
	Lighting.OutdoorAmbient = Color3.fromRGB(100, 40, 30)

	local conn = self.networker:getServerChangedSignal("meteorTarget"):Connect(function(target)
		if not target or not target.x then
			return
		end

		-- Красный круг-предупреждение на полу
		local warning = Instance.new("Part")
		warning.Name = "MeteorWarning"
		warning.Shape = Enum.PartType.Cylinder
		warning.Size = Vector3.new(0.2, 16, 16)
		warning.CFrame = CFrame.new(target.x, 0.1, target.z) * CFrame.Angles(0, 0, math.rad(90))
		warning.Anchored = true
		warning.CanCollide = false
		warning.Color = Color3.fromRGB(255, 0, 0)
		warning.Material = Enum.Material.Neon
		warning.Transparency = 0.5
		warning.Parent = workspace
		table.insert(visuals, warning)

		-- Через 1.5сек — метеор падает
		task.delay(1.5, function()
			if warning.Parent then
				warning:Destroy()
			end

			local meteor = Instance.new("Part")
			meteor.Name = "Meteor"
			meteor.Shape = Enum.PartType.Ball
			meteor.Size = Vector3.new(3, 3, 3)
			meteor.Position = Vector3.new(target.x, 50, target.z)
			meteor.Anchored = false
			meteor.CanCollide = false
			meteor.Color = Color3.fromRGB(255, 100, 0)
			meteor.Material = Enum.Material.Neon
			meteor.Parent = workspace
			table.insert(visuals, meteor)

			task.delay(2, function()
				if meteor.Parent then
					meteor:Destroy()
				end
			end)
		end)
	end)

	self._cleanupEffects = function()
		conn:Disconnect()
		for _, v in visuals do
			if v.Parent then
				v:Destroy()
			end
		end
		self:_restoreLighting()
	end
end

------------------------------------------------------------------------
-- Тьма — чёрный Lighting + монстр с красными глазами
------------------------------------------------------------------------

function CataclysmServiceClient._effectDarkness(self: CataclysmServiceClient)
	Lighting.Ambient = Color3.fromRGB(0, 0, 0)
	Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
	Lighting.FogEnd = 30
	Lighting.FogColor = Color3.fromRGB(0, 0, 0)

	-- Визуальный монстр (красные глаза)
	local monsterVisual = Instance.new("Part")
	monsterVisual.Name = "MonsterVisual"
	monsterVisual.Size = Vector3.new(1, 1, 1)
	monsterVisual.Shape = Enum.PartType.Ball
	monsterVisual.Color = Color3.fromRGB(255, 0, 0)
	monsterVisual.Material = Enum.Material.Neon
	monsterVisual.Anchored = true
	monsterVisual.CanCollide = false
	monsterVisual.Transparency = 0

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 0, 0)
	light.Brightness = 3
	light.Range = 15
	light.Parent = monsterVisual

	monsterVisual.Parent = workspace

	local conn = self.networker:getServerChangedSignal("monsterPos"):Connect(function(pos)
		if pos and pos.x then
			monsterVisual.Position = Vector3.new(pos.x, 5, pos.z)
		end
	end)

	self._cleanupEffects = function()
		conn:Disconnect()
		if monsterVisual.Parent then
			monsterVisual:Destroy()
		end
		self:_restoreLighting()
	end
end

------------------------------------------------------------------------
-- Чёрная дыра — фиолетовый шар + эффекты
------------------------------------------------------------------------

function CataclysmServiceClient._effectBlackHole(self: CataclysmServiceClient)
	Lighting.Ambient = Color3.fromRGB(40, 0, 60)

	-- Визуальный шар чёрной дыры
	local hole = Instance.new("Part")
	hole.Name = "BlackHoleVisual"
	hole.Shape = Enum.PartType.Ball
	hole.Size = Vector3.new(15, 15, 15)
	hole.Position = Vector3.new(15, 10, -200)
	hole.Anchored = true
	hole.CanCollide = false
	hole.Color = Color3.fromRGB(50, 0, 80)
	hole.Material = Enum.Material.Neon
	hole.Transparency = 0.3
	hole.Parent = workspace

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(150, 0, 255)
	light.Brightness = 5
	light.Range = 40
	light.Parent = hole

	-- Вращение
	local running = true
	local heartbeat = RunService.Heartbeat:Connect(function()
		if not running or not hole.Parent then
			return
		end
		local t = tick()
		hole.CFrame = CFrame.new(15, 10 + math.sin(t * 2) * 1, -200) * CFrame.Angles(t, t * 0.7, 0)
	end)

	self._cleanupEffects = function()
		running = false
		heartbeat:Disconnect()
		if hole.Parent then
			hole:Destroy()
		end
		self:_restoreLighting()
	end
end

------------------------------------------------------------------------
-- Заморозка — белый fog + синий оттенок
------------------------------------------------------------------------

function CataclysmServiceClient._effectFreeze(self: CataclysmServiceClient)
	Lighting.Ambient = Color3.fromRGB(100, 150, 220)
	Lighting.OutdoorAmbient = Color3.fromRGB(100, 150, 220)
	Lighting.FogEnd = 80
	Lighting.FogColor = Color3.fromRGB(200, 220, 255)

	self._cleanupEffects = function()
		self:_restoreLighting()
	end
end

export type CataclysmServiceClient = typeof(CataclysmServiceClient)

return CataclysmServiceClient
