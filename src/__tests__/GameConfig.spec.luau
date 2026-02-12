local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)

describe("GameConfig", function()
	describe("Brainrots table", function()
		it("should have 8 brainrots", function()
			local count = 0
			for _ in GameConfig.Brainrots do
				count += 1
			end
			expect(count).toBe(8)
		end)

		it("should have sequential ids from 1 to 8", function()
			for i = 1, 8 do
				expect(GameConfig.Brainrots[i]).toBeDefined()
				expect(GameConfig.Brainrots[i].id).toBe(i)
			end
		end)

		it("should have all required fields for each brainrot", function()
			for _, brainrot in GameConfig.Brainrots do
				expect(brainrot.id).toBeDefined()
				expect(brainrot.name).toBeDefined()
				expect(brainrot.rarity).toBeDefined()
				expect(brainrot.incomePerSec).toBeDefined()
				expect(brainrot.zone).toBeDefined()
				expect(typeof(brainrot.id)).toBe("number")
				expect(typeof(brainrot.name)).toBe("string")
				expect(typeof(brainrot.rarity)).toBe("string")
				expect(typeof(brainrot.incomePerSec)).toBe("number")
				expect(typeof(brainrot.zone)).toBe("number")
			end
		end)

		it("should have positive incomePerSec values", function()
			for _, brainrot in GameConfig.Brainrots do
				expect(brainrot.incomePerSec > 0).toBe(true)
			end
		end)

		it("should have zones between 1 and 4", function()
			for _, brainrot in GameConfig.Brainrots do
				expect(brainrot.zone >= 1).toBe(true)
				expect(brainrot.zone <= 4).toBe(true)
			end
		end)

		it("should have only valid rarities", function()
			local validRarities = { Common = true, Uncommon = true, Rare = true, Epic = true, Legendary = true }
			for _, brainrot in GameConfig.Brainrots do
				expect(validRarities[brainrot.rarity]).toBe(true)
			end
		end)

		it("should have increasing income with rarity", function()
			-- Common < Uncommon < Rare < Epic < Legendary (min income per rarity)
			local rarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
			local maxPerRarity = {}

			for _, brainrot in GameConfig.Brainrots do
				local current = maxPerRarity[brainrot.rarity]
				if not current or brainrot.incomePerSec > current then
					maxPerRarity[brainrot.rarity] = brainrot.incomePerSec
				end
			end

			for i = 2, #rarityOrder do
				local prev = maxPerRarity[rarityOrder[i - 1]]
				local curr = maxPerRarity[rarityOrder[i]]
				if prev and curr then
					expect(curr > prev).toBe(true)
				end
			end
		end)
	end)

	describe("getBrainrot", function()
		it("should return correct brainrot by id", function()
			local brainrot = GameConfig.getBrainrot(1)
			expect(brainrot).toBeDefined()
			expect(brainrot.name).toBe("Skibidi Toilet")
			expect(brainrot.rarity).toBe("Common")
			expect(brainrot.incomePerSec).toBe(1)
			expect(brainrot.zone).toBe(1)
		end)

		it("should return nil for non-existent id", function()
			expect(GameConfig.getBrainrot(0)).toBeNil()
			expect(GameConfig.getBrainrot(999)).toBeNil()
		end)

		it("should return all brainrots by their id", function()
			for id, expected in GameConfig.Brainrots do
				local brainrot = GameConfig.getBrainrot(id)
				expect(brainrot).toBeDefined()
				expect(brainrot.name).toBe(expected.name)
			end
		end)
	end)

	describe("getBrainrotsForZone", function()
		it("should return brainrots for zone 1", function()
			local zone1 = GameConfig.getBrainrotsForZone(1)
			expect(#zone1).toBe(2)
			for _, brainrot in zone1 do
				expect(brainrot.zone).toBe(1)
			end
		end)

		it("should return brainrots for zone 2", function()
			local zone2 = GameConfig.getBrainrotsForZone(2)
			expect(#zone2).toBe(2)
			for _, brainrot in zone2 do
				expect(brainrot.zone).toBe(2)
			end
		end)

		it("should return brainrots for zone 3", function()
			local zone3 = GameConfig.getBrainrotsForZone(3)
			expect(#zone3).toBe(2)
			for _, brainrot in zone3 do
				expect(brainrot.zone).toBe(3)
			end
		end)

		it("should return brainrots for zone 4", function()
			local zone4 = GameConfig.getBrainrotsForZone(4)
			expect(#zone4).toBe(2)
			for _, brainrot in zone4 do
				expect(brainrot.zone).toBe(4)
			end
		end)

		it("should return empty table for non-existent zone", function()
			local result = GameConfig.getBrainrotsForZone(99)
			expect(#result).toBe(0)
		end)

		it("should cover all brainrots across all zones", function()
			local total = 0
			for zone = 1, 4 do
				total += #GameConfig.getBrainrotsForZone(zone)
			end
			expect(total).toBe(8)
		end)
	end)

	describe("RarityConfig", function()
		it("should have config for all 5 rarities", function()
			local rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
			for _, rarity in rarities do
				expect(GameConfig.RarityConfig[rarity]).toBeDefined()
			end
		end)

		it("should have positive weights", function()
			for _, config in GameConfig.RarityConfig do
				expect(config.weight > 0).toBe(true)
			end
		end)

		it("should have decreasing weights with rarity", function()
			local rarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
			for i = 2, #rarityOrder do
				local prev = GameConfig.RarityConfig[rarityOrder[i - 1]].weight
				local curr = GameConfig.RarityConfig[rarityOrder[i]].weight
				expect(curr < prev).toBe(true)
			end
		end)

		it("should have positive respawn times", function()
			for _, config in GameConfig.RarityConfig do
				expect(config.respawnTime > 0).toBe(true)
			end
		end)

		it("should have increasing respawn times with rarity", function()
			local rarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
			for i = 2, #rarityOrder do
				local prev = GameConfig.RarityConfig[rarityOrder[i - 1]].respawnTime
				local curr = GameConfig.RarityConfig[rarityOrder[i]].respawnTime
				expect(curr > prev).toBe(true)
			end
		end)

		it("should have Color3 values", function()
			for _, config in GameConfig.RarityConfig do
				expect(typeof(config.color)).toBe("Color3")
			end
		end)
	end)

	describe("getRarityInfo", function()
		it("should return correct info for Common", function()
			local info = GameConfig.getRarityInfo("Common")
			expect(info).toBeDefined()
			expect(info.weight).toBe(10)
			expect(info.respawnTime).toBe(30)
		end)

		it("should return correct info for Legendary", function()
			local info = GameConfig.getRarityInfo("Legendary")
			expect(info).toBeDefined()
			expect(info.weight).toBe(0.5)
			expect(info.respawnTime).toBe(120)
		end)

		it("should return nil for invalid rarity", function()
			expect(GameConfig.getRarityInfo("NonExistent")).toBeNil()
		end)
	end)

	describe("PRESTIGE_BONUS_PER_LEVEL", function()
		it("should be a positive number", function()
			expect(typeof(GameConfig.PRESTIGE_BONUS_PER_LEVEL)).toBe("number")
			expect(GameConfig.PRESTIGE_BONUS_PER_LEVEL > 0).toBe(true)
		end)

		it("should be 0.1", function()
			expect(GameConfig.PRESTIGE_BONUS_PER_LEVEL).toBe(0.1)
		end)
	end)

	describe("all brainrot rarities have matching RarityConfig", function()
		it("every brainrot rarity should exist in RarityConfig", function()
			for _, brainrot in GameConfig.Brainrots do
				local info = GameConfig.getRarityInfo(brainrot.rarity)
				expect(info).toBeDefined()
			end
		end)
	end)

	describe("Upgrade constants", function()
		it("should have valid upgrade constants", function()
			expect(GameConfig.UPGRADE_MAX_LEVEL).toBeDefined()
			expect(GameConfig.UPGRADE_MAX_LEVEL > 1).toBe(true)
			expect(GameConfig.UPGRADE_BASE_COST > 0).toBe(true)
			expect(GameConfig.UPGRADE_COST_MULTIPLIER > 1).toBe(true)
			expect(GameConfig.UPGRADE_INCOME_MULTIPLIER > 0).toBe(true)
		end)
	end)

	describe("getUpgradeCost", function()
		it("should return a positive cost for valid brainrot", function()
			local cost = GameConfig.getUpgradeCost(1, 1)
			expect(cost > 0).toBe(true)
		end)

		it("should increase cost with level", function()
			local cost1 = GameConfig.getUpgradeCost(1, 1)
			local cost2 = GameConfig.getUpgradeCost(1, 2)
			local cost3 = GameConfig.getUpgradeCost(1, 3)

			expect(cost2 > cost1).toBe(true)
			expect(cost3 > cost2).toBe(true)
		end)

		it("should scale with brainrot income", function()
			-- Higher income brainrot should cost more to upgrade
			local costLow = GameConfig.getUpgradeCost(1, 1) -- income=1
			local costHigh = GameConfig.getUpgradeCost(8, 1) -- income=100

			expect(costHigh > costLow).toBe(true)
		end)

		it("should return math.huge for invalid brainrot", function()
			local cost = GameConfig.getUpgradeCost(999, 1)
			expect(cost).toBe(math.huge)
		end)

		it("should match formula: floor(BASE_COST * income * MULTIPLIER^(level-1))", function()
			local brainrot = GameConfig.getBrainrot(1)
			local baseCost = GameConfig.UPGRADE_BASE_COST * brainrot.incomePerSec

			for level = 1, 5 do
				local expected = math.floor(baseCost * (GameConfig.UPGRADE_COST_MULTIPLIER ^ (level - 1)))
				expect(GameConfig.getUpgradeCost(1, level)).toBe(expected)
			end
		end)
	end)

	describe("getIncomeForLevel", function()
		it("should return base income at level 1", function()
			local brainrot = GameConfig.getBrainrot(1)
			local income = GameConfig.getIncomeForLevel(1, 1)
			expect(income).toBe(brainrot.incomePerSec)
		end)

		it("should increase income with level", function()
			local income1 = GameConfig.getIncomeForLevel(1, 1)
			local income2 = GameConfig.getIncomeForLevel(1, 2)
			local income5 = GameConfig.getIncomeForLevel(1, 5)

			expect(income2 > income1).toBe(true)
			expect(income5 > income2).toBe(true)
		end)

		it("should return 0 for invalid brainrot", function()
			expect(GameConfig.getIncomeForLevel(999, 1)).toBe(0)
		end)

		it("should match formula: income * (1 + (level-1) * MULTIPLIER)", function()
			local brainrot = GameConfig.getBrainrot(2) -- Sigma Cat, income=2

			for level = 1, 5 do
				local expected = brainrot.incomePerSec * (1 + (level - 1) * GameConfig.UPGRADE_INCOME_MULTIPLIER)
				expect(GameConfig.getIncomeForLevel(2, level)).toBe(expected)
			end
		end)
	end)
end)
