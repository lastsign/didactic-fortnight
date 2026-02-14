local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)

describe("Upgrade System Config", function()
	describe("Player upgrade constants", function()
		it("should have valid speed upgrade config", function()
			expect(GameConfig.SPEED_BASE_PRICE).toBeDefined()
			expect(GameConfig.SPEED_BASE_PRICE > 0).toBe(true)
			expect(GameConfig.SPEED_MAX_LEVEL).toBeDefined()
			expect(GameConfig.SPEED_MAX_LEVEL > 1).toBe(true)
			expect(GameConfig.SPEED_PER_LEVEL > 0).toBe(true)
		end)

		it("should have valid carry capacity config", function()
			expect(GameConfig.CARRY_BASE_PRICE > 0).toBe(true)
			expect(GameConfig.CARRY_MAX_LEVEL > 3).toBe(true)
		end)

		it("should have valid plot capacity config", function()
			expect(GameConfig.PLOT_CAPACITY_BASE_PRICE > 0).toBe(true)
			expect(GameConfig.PLOT_CAPACITY_MAX_LEVEL > 5).toBe(true)
		end)

		it("should have prestige jump bonus", function()
			expect(GameConfig.PRESTIGE_JUMP_PER_LEVEL > 0).toBe(true)
		end)
	end)

	describe("getPlayerUpgradePrice", function()
		it("should return positive price at level 1", function()
			local price = GameConfig.getPlayerUpgradePrice(100, 1)
			expect(price > 0).toBe(true)
		end)

		it("should increase price with level", function()
			local price1 = GameConfig.getPlayerUpgradePrice(100, 1)
			local price5 = GameConfig.getPlayerUpgradePrice(100, 5)
			local price10 = GameConfig.getPlayerUpgradePrice(100, 10)
			expect(price5 > price1).toBe(true)
			expect(price10 > price5).toBe(true)
		end)

		it("should match formula: floor(basePrice * level ^ 1.5)", function()
			for level = 1, 10 do
				local expected = math.floor(100 * (level ^ 1.5))
				expect(GameConfig.getPlayerUpgradePrice(100, level)).toBe(expected)
			end
		end)

		it("should scale with base price", function()
			local cheap = GameConfig.getPlayerUpgradePrice(100, 5)
			local expensive = GameConfig.getPlayerUpgradePrice(500, 5)
			expect(expensive > cheap).toBe(true)
		end)
	end)

	describe("PrestigeRequirements", function()
		it("should have 10 prestige levels", function()
			local count = 0
			for _ in GameConfig.PrestigeRequirements do
				count += 1
			end
			expect(count).toBe(10)
		end)

		it("should have increasing totalEarnings per level", function()
			for i = 2, 10 do
				local prev = GameConfig.PrestigeRequirements[i - 1].totalEarnings
				local curr = GameConfig.PrestigeRequirements[i].totalEarnings
				expect(curr > prev).toBe(true)
			end
		end)

		it("should have increasing speedLevel per level", function()
			for i = 2, 10 do
				local prev = GameConfig.PrestigeRequirements[i - 1].speedLevel
				local curr = GameConfig.PrestigeRequirements[i].speedLevel
				expect(curr >= prev).toBe(true)
			end
		end)

		it("should have speedLevel within max speed level", function()
			for _, req in GameConfig.PrestigeRequirements do
				expect(req.speedLevel <= GameConfig.SPEED_MAX_LEVEL).toBe(true)
			end
		end)
	end)

	describe("getPrestigeRequirements", function()
		it("should return requirements for valid level", function()
			local req = GameConfig.getPrestigeRequirements(1)
			expect(req).toBeDefined()
			expect(req.totalEarnings).toBeDefined()
			expect(req.speedLevel).toBeDefined()
		end)

		it("should return nil for level 0", function()
			expect(GameConfig.getPrestigeRequirements(0)).toBeNil()
		end)

		it("should return nil for level beyond max", function()
			expect(GameConfig.getPrestigeRequirements(11)).toBeNil()
		end)
	end)

	describe("canPrestige", function()
		it("should return false when requirements not met", function()
			local result = GameConfig.canPrestige({
				TotalEarnings = 0,
				SpeedLevel = 1,
				PrestigeLevel = 0,
			})
			expect(result).toBe(false)
		end)

		it("should return true when all requirements met for prestige 1", function()
			local req = GameConfig.PrestigeRequirements[1]
			local result = GameConfig.canPrestige({
				TotalEarnings = req.totalEarnings,
				SpeedLevel = req.speedLevel,
				PrestigeLevel = 0,
			})
			expect(result).toBe(true)
		end)

		it("should return false when only earnings met", function()
			local req = GameConfig.PrestigeRequirements[1]
			local result = GameConfig.canPrestige({
				TotalEarnings = req.totalEarnings,
				SpeedLevel = 1,
				PrestigeLevel = 0,
			})
			expect(result).toBe(false)
		end)

		it("should return false when only speed met", function()
			local req = GameConfig.PrestigeRequirements[1]
			local result = GameConfig.canPrestige({
				TotalEarnings = 0,
				SpeedLevel = req.speedLevel,
				PrestigeLevel = 0,
			})
			expect(result).toBe(false)
		end)

		it("should return false at max prestige", function()
			local result = GameConfig.canPrestige({
				TotalEarnings = 999999999999,
				SpeedLevel = 50,
				PrestigeLevel = 10,
			})
			expect(result).toBe(false)
		end)

		it("should check correct next level requirements", function()
			-- At prestige 2, should check requirements for level 3
			local req3 = GameConfig.PrestigeRequirements[3]
			local result = GameConfig.canPrestige({
				TotalEarnings = req3.totalEarnings,
				SpeedLevel = req3.speedLevel,
				PrestigeLevel = 2,
			})
			expect(result).toBe(true)
		end)
	end)
end)
