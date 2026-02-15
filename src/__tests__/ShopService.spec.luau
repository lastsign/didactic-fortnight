local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)

describe("Shop & Selling System", function()
	describe("SELL_PRICE_MULTIPLIER", function()
		it("should be defined and positive", function()
			expect(GameConfig.SELL_PRICE_MULTIPLIER).toBeDefined()
			expect(GameConfig.SELL_PRICE_MULTIPLIER > 0).toBe(true)
		end)

		it("should equal 100", function()
			expect(GameConfig.SELL_PRICE_MULTIPLIER).toBe(100)
		end)
	end)

	describe("getSellPrice", function()
		it("should return incomePerSec * 100 at level 1", function()
			for _, brainrot in GameConfig.Brainrots do
				local price = GameConfig.getSellPrice(brainrot.id, 1)
				expect(price).toBe(math.floor(brainrot.incomePerSec * 100))
			end
		end)

		it("should increase sell price with level", function()
			local price1 = GameConfig.getSellPrice(1, 1)
			local price5 = GameConfig.getSellPrice(1, 5)
			local price10 = GameConfig.getSellPrice(1, 10)
			expect(price5 > price1).toBe(true)
			expect(price10 > price5).toBe(true)
		end)

		it("should account for level income scaling", function()
			for level = 1, GameConfig.UPGRADE_MAX_LEVEL do
				local income = GameConfig.getIncomeForLevel(1, level)
				local sellPrice = GameConfig.getSellPrice(1, level)
				expect(sellPrice).toBe(math.floor(income * GameConfig.SELL_PRICE_MULTIPLIER))
			end
		end)

		it("should return 0 for invalid brainrot id", function()
			expect(GameConfig.getSellPrice(999, 1)).toBe(0)
		end)

		it("should return higher price for rarer brainrots", function()
			local commonPrice = GameConfig.getSellPrice(1, 1) -- Skibidi Toilet, 1/sec
			local legendaryPrice = GameConfig.getSellPrice(8, 1) -- Fanum Tax, 100/sec
			expect(legendaryPrice > commonPrice).toBe(true)
		end)
	end)
end)
