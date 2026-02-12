local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local PlayerDataServiceServer = require(ServerScriptService.Features.Playerdata.PlayerDataServiceServer)
local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)

-- Мок-утилиты
local function createMockProfile(overrides: { [string]: any }?)
	local defaults = {
		Coins = 0,
		Inventory = {},
		SpeedLevel = 1,
		PrestigeLevel = 0,
		JumpLevel = 1,
		PlotCapacity = 5,
		CarryCapacity = 3,
		TotalEarnings = 0,
	}

	if overrides then
		for key, value in overrides do
			defaults[key] = value
		end
	end

	return { Data = defaults }
end

local function createMockNetworker()
	local calls = {}
	return {
		set = function(_self, player, key, value)
			table.insert(calls, { player = player, key = key, value = value })
		end,
		calls = calls,
		getLastCall = function(self, key: string)
			for i = #self.calls, 1, -1 do
				if self.calls[i].key == key then
					return self.calls[i]
				end
			end
			return nil
		end,
	}
end

local mockPlayer = newproxy(false) :: any
local mockNetworker

-- Сброс состояния перед каждым тестом
beforeEach(function()
	mockNetworker = createMockNetworker()
	PlayerDataServiceServer.profiles = {}
	PlayerDataServiceServer.carryInventory = {}
	PlayerDataServiceServer.networker = mockNetworker :: any
end)

------------------------------------------------------------------------
-- PROFILE_TEMPLATE
------------------------------------------------------------------------

describe("PROFILE_TEMPLATE", function()
	it("should have correct default values when profile is created", function()
		local profile = createMockProfile()
		local data = profile.Data

		expect(data.Coins).toBe(0)
		expect(data.SpeedLevel).toBe(1)
		expect(data.PrestigeLevel).toBe(0)
		expect(data.JumpLevel).toBe(1)
		expect(data.PlotCapacity).toBe(5)
		expect(data.CarryCapacity).toBe(3)
		expect(data.TotalEarnings).toBe(0)
		expect(#data.Inventory).toBe(0)
	end)
end)

------------------------------------------------------------------------
-- isProfileLoaded / getData
------------------------------------------------------------------------

describe("isProfileLoaded", function()
	it("should return false when no profile loaded", function()
		expect(PlayerDataServiceServer:isProfileLoaded(mockPlayer)).toBe(false)
	end)

	it("should return true when profile is loaded", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		expect(PlayerDataServiceServer:isProfileLoaded(mockPlayer)).toBe(true)
	end)
end)

describe("getData", function()
	it("should return nil when no profile", function()
		expect(PlayerDataServiceServer:getData(mockPlayer)).toBeNil()
	end)

	it("should return profile data", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({ Coins = 100 })
		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(data).toBeDefined()
		expect(data.Coins).toBe(100)
	end)
end)

------------------------------------------------------------------------
-- addCoins
------------------------------------------------------------------------

describe("addCoins", function()
	it("should increase Coins and TotalEarnings", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer:addCoins(mockPlayer, 50)

		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(data.Coins).toBe(50)
		expect(data.TotalEarnings).toBe(50)
	end)

	it("should accumulate multiple calls", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer:addCoins(mockPlayer, 30)
		PlayerDataServiceServer:addCoins(mockPlayer, 70)

		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(data.Coins).toBe(100)
		expect(data.TotalEarnings).toBe(100)
	end)

	it("should sync coins to client via networker", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer:addCoins(mockPlayer, 25)

		local call = mockNetworker:getLastCall("coins")
		expect(call).toBeDefined()
		expect(call.value).toBe(25)
	end)

	it("should do nothing if profile not loaded", function()
		PlayerDataServiceServer:addCoins(mockPlayer, 100)
		-- No error, no crash
		expect(#mockNetworker.calls).toBe(0)
	end)
end)

------------------------------------------------------------------------
-- removeCoins
------------------------------------------------------------------------

describe("removeCoins", function()
	it("should decrease Coins and return true", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({ Coins = 100 })
		local result = PlayerDataServiceServer:removeCoins(mockPlayer, 40)

		expect(result).toBe(true)
		expect(PlayerDataServiceServer:getData(mockPlayer).Coins).toBe(60)
	end)

	it("should return false if not enough coins", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({ Coins = 10 })
		local result = PlayerDataServiceServer:removeCoins(mockPlayer, 50)

		expect(result).toBe(false)
		expect(PlayerDataServiceServer:getData(mockPlayer).Coins).toBe(10) -- unchanged
	end)

	it("should return false if exact amount equals coins (edge: less than)", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({ Coins = 50 })
		local result = PlayerDataServiceServer:removeCoins(mockPlayer, 50)

		-- Coins < amount is false when Coins == amount, so should succeed
		expect(result).toBe(true)
		expect(PlayerDataServiceServer:getData(mockPlayer).Coins).toBe(0)
	end)

	it("should return false if no profile", function()
		local result = PlayerDataServiceServer:removeCoins(mockPlayer, 10)
		expect(result).toBe(false)
	end)

	it("should sync to client after removal", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({ Coins = 100 })
		PlayerDataServiceServer:removeCoins(mockPlayer, 30)

		local call = mockNetworker:getLastCall("coins")
		expect(call).toBeDefined()
		expect(call.value).toBe(70)
	end)
end)

------------------------------------------------------------------------
-- addBrainrotToInventory
------------------------------------------------------------------------

describe("addBrainrotToInventory", function()
	it("should add brainrot and assign slot 1 with level 1", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		local result = PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 1)

		expect(result).toBe(true)
		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(#data.Inventory).toBe(1)
		expect(data.Inventory[1].id).toBe(1)
		expect(data.Inventory[1].slot).toBe(1)
		expect(data.Inventory[1].level).toBe(1)
	end)

	it("should assign sequential slots", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 1)
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 2)
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 3)

		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(#data.Inventory).toBe(3)
		expect(data.Inventory[1].slot).toBe(1)
		expect(data.Inventory[2].slot).toBe(2)
		expect(data.Inventory[3].slot).toBe(3)
	end)

	it("should reuse freed slots", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 1)
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 2)
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 3)

		-- Remove slot 2
		PlayerDataServiceServer:removeBrainrotFromInventory(mockPlayer, 2)

		-- Add new — should get slot 2
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 4)
		local data = PlayerDataServiceServer:getData(mockPlayer)

		local foundSlot2 = false
		for _, entry in data.Inventory do
			if entry.id == 4 and entry.slot == 2 then
				foundSlot2 = true
			end
		end
		expect(foundSlot2).toBe(true)
	end)

	it("should reject when inventory is full", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({ PlotCapacity = 2 })
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 1)
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 2)
		local result = PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 3)

		expect(result).toBe(false)
		expect(#PlayerDataServiceServer:getData(mockPlayer).Inventory).toBe(2)
	end)

	it("should return false if no profile", function()
		local result = PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 1)
		expect(result).toBe(false)
	end)

	it("should sync inventory and inventoryCount to client", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 1)

		local inventoryCall = mockNetworker:getLastCall("inventoryCount")
		expect(inventoryCall).toBeDefined()
		expect(inventoryCall.value).toBe(1)
	end)

	it("should sync incomePerSec after adding", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 1) -- Skibidi Toilet, income=1

		local incomeCall = mockNetworker:getLastCall("incomePerSec")
		expect(incomeCall).toBeDefined()
		expect(incomeCall.value).toBe(1)
	end)
end)

------------------------------------------------------------------------
-- removeBrainrotFromInventory
------------------------------------------------------------------------

describe("removeBrainrotFromInventory", function()
	it("should remove brainrot by slot", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 1)
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 2)

		PlayerDataServiceServer:removeBrainrotFromInventory(mockPlayer, 1)

		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(#data.Inventory).toBe(1)
		expect(data.Inventory[1].id).toBe(2)
	end)

	it("should do nothing for non-existent slot", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 1)

		PlayerDataServiceServer:removeBrainrotFromInventory(mockPlayer, 99)

		expect(#PlayerDataServiceServer:getData(mockPlayer).Inventory).toBe(1)
	end)

	it("should recalculate income after removal", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 1) -- income=1
		PlayerDataServiceServer:addBrainrotToInventory(mockPlayer, 2) -- income=2

		PlayerDataServiceServer:removeBrainrotFromInventory(mockPlayer, 1)

		local incomeCall = mockNetworker:getLastCall("incomePerSec")
		expect(incomeCall).toBeDefined()
		expect(incomeCall.value).toBe(2) -- only Sigma Cat left
	end)
end)

------------------------------------------------------------------------
-- addToCarry / getCarryInventory / clearCarry
------------------------------------------------------------------------

describe("addToCarry", function()
	it("should add brainrot to carry", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer.carryInventory[mockPlayer] = {}

		local result = PlayerDataServiceServer:addToCarry(mockPlayer, 1)
		expect(result).toBe(true)

		local carry = PlayerDataServiceServer:getCarryInventory(mockPlayer)
		expect(#carry).toBe(1)
		expect(carry[1]).toBe(1)
	end)

	it("should respect CarryCapacity limit", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({ CarryCapacity = 2 })
		PlayerDataServiceServer.carryInventory[mockPlayer] = {}

		expect(PlayerDataServiceServer:addToCarry(mockPlayer, 1)).toBe(true)
		expect(PlayerDataServiceServer:addToCarry(mockPlayer, 2)).toBe(true)
		expect(PlayerDataServiceServer:addToCarry(mockPlayer, 3)).toBe(false)

		expect(#PlayerDataServiceServer:getCarryInventory(mockPlayer)).toBe(2)
	end)

	it("should sync carryCount to client", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer.carryInventory[mockPlayer] = {}
		PlayerDataServiceServer:addToCarry(mockPlayer, 1)

		local call = mockNetworker:getLastCall("carryCount")
		expect(call).toBeDefined()
		expect(call.value).toBe(1)
	end)

	it("should return false if no profile", function()
		expect(PlayerDataServiceServer:addToCarry(mockPlayer, 1)).toBe(false)
	end)

	it("should return false if no carry table", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		-- carryInventory[mockPlayer] is nil
		expect(PlayerDataServiceServer:addToCarry(mockPlayer, 1)).toBe(false)
	end)
end)

describe("getCarryInventory", function()
	it("should return empty table if no carry", function()
		local carry = PlayerDataServiceServer:getCarryInventory(mockPlayer)
		expect(#carry).toBe(0)
	end)

	it("should return current carry", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer.carryInventory[mockPlayer] = { 1, 3, 5 }

		local carry = PlayerDataServiceServer:getCarryInventory(mockPlayer)
		expect(#carry).toBe(3)
	end)
end)

describe("clearCarry", function()
	it("should empty carry inventory", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer.carryInventory[mockPlayer] = { 1, 2, 3 }

		PlayerDataServiceServer:clearCarry(mockPlayer)

		expect(#PlayerDataServiceServer:getCarryInventory(mockPlayer)).toBe(0)
	end)

	it("should sync carryCount=0 to client", function()
		PlayerDataServiceServer.carryInventory[mockPlayer] = { 1 }
		PlayerDataServiceServer:clearCarry(mockPlayer)

		local call = mockNetworker:getLastCall("carryCount")
		expect(call).toBeDefined()
		expect(call.value).toBe(0)
	end)
end)

------------------------------------------------------------------------
-- depositBrainrots
------------------------------------------------------------------------

describe("depositBrainrots", function()
	it("should transfer carry to inventory", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer.carryInventory[mockPlayer] = { 1, 2 }

		PlayerDataServiceServer:depositBrainrots(mockPlayer)

		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(#data.Inventory).toBe(2)
		expect(#PlayerDataServiceServer:getCarryInventory(mockPlayer)).toBe(0)
	end)

	it("should stop when inventory is full", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({ PlotCapacity = 2 })
		PlayerDataServiceServer.carryInventory[mockPlayer] = { 1, 2, 3 }

		PlayerDataServiceServer:depositBrainrots(mockPlayer)

		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(#data.Inventory).toBe(2) -- only 2 fit
		-- carry is cleared regardless
		expect(#PlayerDataServiceServer:getCarryInventory(mockPlayer)).toBe(0)
	end)

	it("should do nothing if carry is empty", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer.carryInventory[mockPlayer] = {}

		PlayerDataServiceServer:depositBrainrots(mockPlayer)

		expect(#PlayerDataServiceServer:getData(mockPlayer).Inventory).toBe(0)
	end)

	it("should do nothing if no profile", function()
		PlayerDataServiceServer:depositBrainrots(mockPlayer)
		-- no error
		expect(#mockNetworker.calls).toBe(0)
	end)
end)

------------------------------------------------------------------------
-- Пассивный доход (формула)
------------------------------------------------------------------------

describe("income calculation (_syncIncomeToClient)", function()
	it("should calculate income from inventory brainrots", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({
			Inventory = {
				{ id = 1, slot = 1 }, -- Skibidi Toilet: 1/sec
				{ id = 2, slot = 2 }, -- Sigma Cat: 2/sec
			},
		})

		PlayerDataServiceServer:_syncIncomeToClient(mockPlayer)

		local call = mockNetworker:getLastCall("incomePerSec")
		expect(call).toBeDefined()
		expect(call.value).toBe(3) -- 1 + 2
	end)

	it("should apply prestige multiplier", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({
			PrestigeLevel = 2,
			Inventory = {
				{ id = 1, slot = 1 }, -- income = 1
				{ id = 2, slot = 2 }, -- income = 2
			},
		})

		PlayerDataServiceServer:_syncIncomeToClient(mockPlayer)

		local call = mockNetworker:getLastCall("incomePerSec")
		-- 3 * (1 + 2 * 0.1) = 3 * 1.2 = 3.6 → floor = 3
		expect(call.value).toBe(3)
	end)

	it("should apply higher prestige correctly", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({
			PrestigeLevel = 5,
			Inventory = {
				{ id = 5, slot = 1 }, -- Baby Gronk: 15/sec
				{ id = 7, slot = 2 }, -- Duke Dennis: 50/sec
			},
		})

		PlayerDataServiceServer:_syncIncomeToClient(mockPlayer)

		local call = mockNetworker:getLastCall("incomePerSec")
		-- 65 * (1 + 5 * 0.1) = 65 * 1.5 = 97.5 → floor = 97
		expect(call.value).toBe(97)
	end)

	it("should return 0 income for empty inventory", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()

		PlayerDataServiceServer:_syncIncomeToClient(mockPlayer)

		local call = mockNetworker:getLastCall("incomePerSec")
		expect(call).toBeDefined()
		expect(call.value).toBe(0)
	end)

	it("should match the formula: sum(incomePerSec) * (1 + prestige * 0.1)", function()
		-- Test with all brainrots at prestige 1
		local inventory = {}
		local expectedRawIncome = 0
		for i = 1, 8 do
			table.insert(inventory, { id = i, slot = i })
			local brainrot = GameConfig.getBrainrot(i)
			expectedRawIncome += brainrot.incomePerSec
		end

		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({
			PrestigeLevel = 1,
			PlotCapacity = 10,
			Inventory = inventory,
		})

		PlayerDataServiceServer:_syncIncomeToClient(mockPlayer)

		local call = mockNetworker:getLastCall("incomePerSec")
		local expected = math.floor(expectedRawIncome * (1 + 1 * GameConfig.PRESTIGE_BONUS_PER_LEVEL))
		expect(call.value).toBe(expected)
	end)
end)

------------------------------------------------------------------------
-- _syncToClient
------------------------------------------------------------------------

describe("_syncToClient", function()
	it("should sync all fields to client", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({
			Coins = 500,
			PlotCapacity = 5,
			CarryCapacity = 3,
			Inventory = { { id = 1, slot = 1 } },
		})
		PlayerDataServiceServer.carryInventory[mockPlayer] = { 2 }

		PlayerDataServiceServer:_syncToClient(mockPlayer)

		expect(mockNetworker:getLastCall("coins").value).toBe(500)
		expect(mockNetworker:getLastCall("inventoryCount").value).toBe(1)
		expect(mockNetworker:getLastCall("plotCapacity").value).toBe(5)
		expect(mockNetworker:getLastCall("carryCount").value).toBe(1)
		expect(mockNetworker:getLastCall("carryCapacity").value).toBe(3)
		expect(mockNetworker:getLastCall("incomePerSec")).toBeDefined()
	end)

	it("should do nothing if no profile", function()
		PlayerDataServiceServer:_syncToClient(mockPlayer)
		expect(#mockNetworker.calls).toBe(0)
	end)
end)

------------------------------------------------------------------------
-- depositOneBrainrot
------------------------------------------------------------------------

describe("depositOneBrainrot", function()
	it("should transfer exactly one brainrot from carry to inventory", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer.carryInventory[mockPlayer] = { 1, 2, 3 }

		PlayerDataServiceServer:depositOneBrainrot(mockPlayer)

		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(#data.Inventory).toBe(1)
		expect(data.Inventory[1].id).toBe(1)
		expect(#PlayerDataServiceServer:getCarryInventory(mockPlayer)).toBe(2)
	end)

	it("should deposit first brainrot from carry (FIFO)", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer.carryInventory[mockPlayer] = { 5, 3, 1 }

		PlayerDataServiceServer:depositOneBrainrot(mockPlayer)

		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(data.Inventory[1].id).toBe(5)

		local carry = PlayerDataServiceServer:getCarryInventory(mockPlayer)
		expect(carry[1]).toBe(3)
		expect(carry[2]).toBe(1)
	end)

	it("should do nothing if carry is empty", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer.carryInventory[mockPlayer] = {}

		PlayerDataServiceServer:depositOneBrainrot(mockPlayer)

		expect(#PlayerDataServiceServer:getData(mockPlayer).Inventory).toBe(0)
	end)

	it("should do nothing if inventory is full", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({ PlotCapacity = 1 })
		PlayerDataServiceServer.carryInventory[mockPlayer] = { 1, 2 }

		PlayerDataServiceServer:depositOneBrainrot(mockPlayer)
		PlayerDataServiceServer:depositOneBrainrot(mockPlayer)

		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(#data.Inventory).toBe(1)
		expect(#PlayerDataServiceServer:getCarryInventory(mockPlayer)).toBe(1)
	end)

	it("should set level = 1 on deposited brainrot", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile()
		PlayerDataServiceServer.carryInventory[mockPlayer] = { 1 }

		PlayerDataServiceServer:depositOneBrainrot(mockPlayer)

		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(data.Inventory[1].level).toBe(1)
	end)
end)

------------------------------------------------------------------------
-- upgradeBrainrot
------------------------------------------------------------------------

describe("upgradeBrainrot", function()
	it("should increase level and deduct coins", function()
		local cost = GameConfig.getUpgradeCost(1, 1)
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({
			Coins = cost + 100,
			Inventory = { { id = 1, slot = 1, level = 1 } },
		})

		PlayerDataServiceServer:upgradeBrainrot(mockPlayer, 1)

		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(data.Inventory[1].level).toBe(2)
		expect(data.Coins).toBe(100)
	end)

	it("should not upgrade if not enough coins", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({
			Coins = 0,
			Inventory = { { id = 1, slot = 1, level = 1 } },
		})

		PlayerDataServiceServer:upgradeBrainrot(mockPlayer, 1)

		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(data.Inventory[1].level).toBe(1)
	end)

	it("should not upgrade past max level", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({
			Coins = 999999,
			Inventory = { { id = 1, slot = 1, level = GameConfig.UPGRADE_MAX_LEVEL } },
		})

		PlayerDataServiceServer:upgradeBrainrot(mockPlayer, 1)

		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(data.Inventory[1].level).toBe(GameConfig.UPGRADE_MAX_LEVEL)
	end)

	it("should do nothing for non-existent slot", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({
			Coins = 999999,
			Inventory = { { id = 1, slot = 1, level = 1 } },
		})

		PlayerDataServiceServer:upgradeBrainrot(mockPlayer, 99)

		local data = PlayerDataServiceServer:getData(mockPlayer)
		expect(data.Inventory[1].level).toBe(1)
	end)

	it("should recalculate income after upgrade", function()
		local cost = GameConfig.getUpgradeCost(1, 1)
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({
			Coins = cost,
			Inventory = { { id = 1, slot = 1, level = 1 } },
		})

		PlayerDataServiceServer:upgradeBrainrot(mockPlayer, 1)

		local call = mockNetworker:getLastCall("incomePerSec")
		expect(call).toBeDefined()
		local expectedIncome = math.floor(GameConfig.getIncomeForLevel(1, 2))
		expect(call.value).toBe(expectedIncome)
	end)
end)

------------------------------------------------------------------------
-- getInventoryEntry
------------------------------------------------------------------------

describe("getInventoryEntry", function()
	it("should return entry by slot", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({
			Inventory = { { id = 1, slot = 1, level = 1 }, { id = 2, slot = 2, level = 3 } },
		})

		local entry = PlayerDataServiceServer:getInventoryEntry(mockPlayer, 2)
		expect(entry).toBeDefined()
		expect(entry.id).toBe(2)
		expect(entry.level).toBe(3)
	end)

	it("should return nil for non-existent slot", function()
		PlayerDataServiceServer.profiles[mockPlayer] = createMockProfile({
			Inventory = { { id = 1, slot = 1, level = 1 } },
		})

		local entry = PlayerDataServiceServer:getInventoryEntry(mockPlayer, 99)
		expect(entry).toBeNil()
	end)

	it("should return nil if no profile", function()
		local entry = PlayerDataServiceServer:getInventoryEntry(mockPlayer, 1)
		expect(entry).toBeNil()
	end)
end)
