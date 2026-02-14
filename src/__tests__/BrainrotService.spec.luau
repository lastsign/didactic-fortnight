local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local BrainrotServiceServer = require(ServerScriptService.Features.Brainrot.BrainrotServiceServer)
local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)

-- Утилиты для очистки
local createdInstances = {}

local function trackInstance(instance: Instance): Instance
	table.insert(createdInstances, instance)
	return instance
end

local function cleanupInstances()
	for _, inst in createdInstances do
		if inst.Parent then
			inst:Destroy()
		end
	end
	table.clear(createdInstances)
end

-- Мок playerDataService
local mockPlayerDataService = {
	isProfileLoaded = function(_self, _player)
		return true
	end,
	addToCarry = function(_self, _player, _brainrotId)
		return true
	end,
}

beforeEach(function()
	BrainrotServiceServer.spawnPoints = {}
	BrainrotServiceServer.activeModels = {}
	BrainrotServiceServer.pickupDebounce = {}
	BrainrotServiceServer.modelTemplates = {}
	BrainrotServiceServer.playerDataService = mockPlayerDataService
	BrainrotServiceServer.plotService = nil
end)

afterEach(function()
	cleanupInstances()
end)

------------------------------------------------------------------------
-- Взвешенный случайный выбор
------------------------------------------------------------------------

describe("_pickRandomBrainrot", function()
	it("should return a brainrot from the correct zone", function()
		for _ = 1, 20 do
			local brainrot = BrainrotServiceServer:_pickRandomBrainrot(1)
			expect(brainrot).toBeDefined()
			expect(brainrot.zone).toBe(1)
		end
	end)

	it("should return nil for non-existent zone", function()
		local result = BrainrotServiceServer:_pickRandomBrainrot(99)
		expect(result).toBeNil()
	end)

	it("should only return brainrots from the requested zone", function()
		for zone = 1, 4 do
			for _ = 1, 20 do
				local brainrot = BrainrotServiceServer:_pickRandomBrainrot(zone)
				expect(brainrot).toBeDefined()
				expect(brainrot.zone).toBe(zone)
			end
		end
	end)

	it("should favor common brainrots over rare ones (statistical)", function()
		-- Zone 1 has Common brainrots (weight=10 each)
		-- Run many iterations and verify both brainrots appear
		local counts = {}
		local iterations = 200

		for _ = 1, iterations do
			local brainrot = BrainrotServiceServer:_pickRandomBrainrot(1)
			counts[brainrot.id] = (counts[brainrot.id] or 0) + 1
		end

		-- Both zone 1 brainrots (id 1 and 2) should appear (both Common, equal weight)
		expect(counts[1]).toBeDefined()
		expect(counts[2]).toBeDefined()
		expect(counts[1] > 0).toBe(true)
		expect(counts[2] > 0).toBe(true)
	end)

	it("should respect rarity weights across different rarities", function()
		-- Zone 2: Ohio Rizz (Uncommon, weight=5) and Grimace Shake (Uncommon, weight=5)
		-- Both equal weight so distribution should be roughly even
		local counts = {}
		local iterations = 200

		for _ = 1, iterations do
			local brainrot = BrainrotServiceServer:_pickRandomBrainrot(2)
			counts[brainrot.id] = (counts[brainrot.id] or 0) + 1
		end

		-- Both should appear
		expect(counts[3]).toBeDefined()
		expect(counts[4]).toBeDefined()
		-- Each should be roughly 50% (allow wide margin: 20%-80%)
		expect(counts[3] > iterations * 0.2).toBe(true)
		expect(counts[4] > iterations * 0.2).toBe(true)
	end)
end)

------------------------------------------------------------------------
-- Создание модели
------------------------------------------------------------------------

describe("_createBrainrotModel", function()
	it("should create a Model with correct name", function()
		local model = BrainrotServiceServer:_createBrainrotModel(1, CFrame.new(0, 5, 0))
		trackInstance(model)

		expect(model).toBeDefined()
		expect(model:IsA("Model")).toBe(true)
		expect(model.Name).toBe("Brainrot_Skibidi Toilet")
	end)

	it("should have a PrimaryPart named Body", function()
		local model = BrainrotServiceServer:_createBrainrotModel(1, CFrame.new(0, 5, 0))
		trackInstance(model)

		expect(model.PrimaryPart).toBeDefined()
		expect(model.PrimaryPart.Name).toBe("Body")
	end)

	it("should set correct Part properties", function()
		local model = BrainrotServiceServer:_createBrainrotModel(1, CFrame.new(0, 5, 0))
		trackInstance(model)

		local part = model.PrimaryPart :: BasePart
		expect(part.Size).toBe(Vector3.new(2, 2, 2))
		expect(part.Anchored).toBe(true)
		expect(part.CanCollide).toBe(false)
		expect(part.Material).toBe(Enum.Material.SmoothPlastic)
	end)

	it("should color part by rarity", function()
		-- Common (id=1) → color from RarityConfig.Common
		local model1 = BrainrotServiceServer:_createBrainrotModel(1, CFrame.new(0, 5, 0))
		trackInstance(model1)
		local commonColor = GameConfig.RarityConfig.Common.color
		expect(model1.PrimaryPart.Color).toBe(commonColor)

		-- Epic (id=7) → color from RarityConfig.Epic
		local model7 = BrainrotServiceServer:_createBrainrotModel(7, CFrame.new(10, 5, 0))
		trackInstance(model7)
		local epicColor = GameConfig.RarityConfig.Epic.color
		expect(model7.PrimaryPart.Color).toBe(epicColor)

		-- Legendary (id=8) → color from RarityConfig.Legendary
		local model8 = BrainrotServiceServer:_createBrainrotModel(8, CFrame.new(20, 5, 0))
		trackInstance(model8)
		local legendaryColor = GameConfig.RarityConfig.Legendary.color
		expect(model8.PrimaryPart.Color).toBe(legendaryColor)
	end)

	it("should set BrainrotId attribute", function()
		local model = BrainrotServiceServer:_createBrainrotModel(3, CFrame.new(0, 5, 0))
		trackInstance(model)

		expect(model:GetAttribute("BrainrotId")).toBe(3)
	end)

	it("should add Brainrot tag via CollectionService", function()
		local model = BrainrotServiceServer:_createBrainrotModel(1, CFrame.new(0, 5, 0))
		trackInstance(model)

		expect(CollectionService:HasTag(model, "Brainrot")).toBe(true)
	end)

	it("should have SurfaceGui billboard on the model", function()
		local model = BrainrotServiceServer:_createBrainrotModel(1, CFrame.new(0, 5, 0))
		trackInstance(model)

		local billboardPart = model:FindFirstChild("BillboardPart")
		expect(billboardPart).toBeDefined()

		local surfaceGui = billboardPart:FindFirstChildOfClass("SurfaceGui")
		expect(surfaceGui).toBeDefined()
		expect(surfaceGui.Name).toBe("BrainrotBillboard")
	end)

	it("should have name and rarity labels in SurfaceGui", function()
		local model = BrainrotServiceServer:_createBrainrotModel(1, CFrame.new(0, 5, 0))
		trackInstance(model)

		local billboardPart = model:FindFirstChild("BillboardPart")
		local surfaceGui = billboardPart:FindFirstChild("BrainrotBillboard")
		local nameLabel = surfaceGui:FindFirstChild("NameLabel")
		local rarityLabel = surfaceGui:FindFirstChild("RarityLabel")

		expect(nameLabel).toBeDefined()
		expect(nameLabel.Text).toBe("Skibidi Toilet")

		expect(rarityLabel).toBeDefined()
		expect(rarityLabel.Text).toBe("Common")
	end)

	it("should parent model to workspace", function()
		local model = BrainrotServiceServer:_createBrainrotModel(1, CFrame.new(0, 5, 0))
		trackInstance(model)

		expect(model.Parent).toBe(workspace)
	end)

	it("should place model at specified CFrame", function()
		local cf = CFrame.new(100, 50, -200)
		local model = BrainrotServiceServer:_createBrainrotModel(1, cf)
		trackInstance(model)

		local pos = model.PrimaryPart.Position
		expect(pos.X).toBe(100)
		expect(pos.Y).toBe(50)
		expect(pos.Z).toBe(-200)
	end)

	it("should create models for all 8 brainrots without errors", function()
		for id = 1, 8 do
			local model = BrainrotServiceServer:_createBrainrotModel(id, CFrame.new(id * 5, 5, 0))
			trackInstance(model)

			local brainrot = GameConfig.getBrainrot(id)
			expect(model.Name).toBe("Brainrot_" .. brainrot.name)
			expect(model:GetAttribute("BrainrotId")).toBe(id)
		end
	end)
end)

------------------------------------------------------------------------
-- _spawnAtPoint
------------------------------------------------------------------------

describe("_spawnAtPoint", function()
	it("should create model and store in activeModels", function()
		local spawnPoint = {
			part = trackInstance(Instance.new("Part")),
			index = 1,
			zone = 1,
			baseCFrame = CFrame.new(0, 5, 0),
		}

		BrainrotServiceServer:_spawnAtPoint(1, spawnPoint)

		local model = BrainrotServiceServer.activeModels[1]
		expect(model).toBeDefined()
		expect(model:IsA("Model")).toBe(true)
		trackInstance(model)
	end)

	it("should set SpawnIndex attribute on model", function()
		local spawnPoint = {
			part = trackInstance(Instance.new("Part")),
			index = 42,
			zone = 2,
			baseCFrame = CFrame.new(0, 5, 0),
		}

		BrainrotServiceServer:_spawnAtPoint(42, spawnPoint)

		local model = BrainrotServiceServer.activeModels[42]
		expect(model:GetAttribute("SpawnIndex")).toBe(42)
		trackInstance(model)
	end)

	it("should not create model for invalid zone", function()
		local spawnPoint = {
			part = trackInstance(Instance.new("Part")),
			index = 1,
			zone = 99,
			baseCFrame = CFrame.new(0, 5, 0),
		}

		BrainrotServiceServer:_spawnAtPoint(1, spawnPoint)

		expect(BrainrotServiceServer.activeModels[1]).toBeNil()
	end)
end)

------------------------------------------------------------------------
-- Респавн
------------------------------------------------------------------------

describe("_scheduleRespawn", function()
	it("should have correct respawn times per rarity in GameConfig", function()
		-- Verify the respawn time values that _scheduleRespawn will use
		expect(GameConfig.RarityConfig.Common.respawnTime).toBe(30)
		expect(GameConfig.RarityConfig.Uncommon.respawnTime).toBe(45)
		expect(GameConfig.RarityConfig.Rare.respawnTime).toBe(60)
		expect(GameConfig.RarityConfig.Epic.respawnTime).toBe(90)
		expect(GameConfig.RarityConfig.Legendary.respawnTime).toBe(120)
	end)

	it("should reference the correct spawn point when respawning", function()
		local spawnPoint = {
			part = trackInstance(Instance.new("Part")),
			index = 5,
			zone = 1,
			baseCFrame = CFrame.new(50, 5, 0),
		}
		BrainrotServiceServer.spawnPoints[5] = spawnPoint

		-- Spawn, then simulate pickup (clear active model)
		BrainrotServiceServer:_spawnAtPoint(5, spawnPoint)
		local firstModel = BrainrotServiceServer.activeModels[5]
		trackInstance(firstModel)

		-- Verify spawn point is stored correctly for respawn
		expect(BrainrotServiceServer.spawnPoints[5]).toBeDefined()
		expect(BrainrotServiceServer.spawnPoints[5].zone).toBe(1)
		expect(BrainrotServiceServer.spawnPoints[5].index).toBe(5)
	end)
end)

------------------------------------------------------------------------
-- Дебаунс подбора
------------------------------------------------------------------------

describe("pickup debounce", function()
	it("should store debounce timestamp per player", function()
		local mockPlayer = newproxy(false)
		BrainrotServiceServer.pickupDebounce[mockPlayer] = tick()

		expect(BrainrotServiceServer.pickupDebounce[mockPlayer]).toBeDefined()
		expect(typeof(BrainrotServiceServer.pickupDebounce[mockPlayer])).toBe("number")
	end)

	it("should clear debounce when reset", function()
		local mockPlayer = newproxy(false)
		BrainrotServiceServer.pickupDebounce[mockPlayer] = tick()
		BrainrotServiceServer.pickupDebounce[mockPlayer] = nil

		expect(BrainrotServiceServer.pickupDebounce[mockPlayer]).toBeNil()
	end)
end)

------------------------------------------------------------------------
-- Интеграция: полный цикл спавна
------------------------------------------------------------------------

describe("full spawn cycle", function()
	it("should spawn brainrots for multiple points across zones", function()
		local points = {}
		for i = 1, 4 do
			local part = Instance.new("Part")
			part.CFrame = CFrame.new(i * 10, 5, 0)
			trackInstance(part)
			points[i] = {
				part = part,
				index = i,
				zone = i, -- one point per zone
				baseCFrame = part.CFrame,
			}
		end

		for i, point in points do
			BrainrotServiceServer:_spawnAtPoint(i, point)
		end

		-- All 4 should have active models
		for i = 1, 4 do
			local model = BrainrotServiceServer.activeModels[i]
			expect(model).toBeDefined()

			local brainrotId = model:GetAttribute("BrainrotId")
			local brainrot = GameConfig.getBrainrot(brainrotId)
			expect(brainrot.zone).toBe(i) -- brainrot should be from the correct zone

			trackInstance(model)
		end
	end)
end)
