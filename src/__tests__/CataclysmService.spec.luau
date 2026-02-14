local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)

describe("Cataclysm System Config", function()
	describe("Cataclysm timing constants", function()
		it("should have valid peace time range", function()
			expect(GameConfig.CATACLYSM_PEACE_TIME_MIN > 0).toBe(true)
			expect(GameConfig.CATACLYSM_PEACE_TIME_MAX > GameConfig.CATACLYSM_PEACE_TIME_MIN).toBe(true)
		end)

		it("should have positive warning time", function()
			expect(GameConfig.CATACLYSM_WARNING_TIME > 0).toBe(true)
		end)

		it("should have valid duration range", function()
			expect(GameConfig.CATACLYSM_DURATION_MIN > 0).toBe(true)
			expect(GameConfig.CATACLYSM_DURATION_MAX > GameConfig.CATACLYSM_DURATION_MIN).toBe(true)
		end)

		it("should have positive dropped brainrot lifetime", function()
			expect(GameConfig.DROPPED_BRAINROT_LIFETIME > 0).toBe(true)
		end)
	end)

	describe("CataclysmTypes", function()
		it("should have 4 cataclysm types", function()
			expect(#GameConfig.CataclysmTypeList).toBe(4)
		end)

		it("should have MeteorRain with damagePerHit", function()
			local t = GameConfig.CataclysmTypes.MeteorRain
			expect(t).toBeDefined()
			expect(t.name).toBe("Meteor Rain")
			expect(t.weight > 0).toBe(true)
			expect(t.damagePerHit > 0).toBe(true)
		end)

		it("should have Darkness with monsterSpeed", function()
			local t = GameConfig.CataclysmTypes.Darkness
			expect(t).toBeDefined()
			expect(t.name).toBe("Darkness")
			expect(t.weight > 0).toBe(true)
			expect(t.monsterSpeed > 0).toBe(true)
		end)

		it("should have BlackHole with pullForce and damagePerSec", function()
			local t = GameConfig.CataclysmTypes.BlackHole
			expect(t).toBeDefined()
			expect(t.name).toBe("Black Hole")
			expect(t.weight > 0).toBe(true)
			expect(t.pullForce > 0).toBe(true)
			expect(t.damagePerSec > 0).toBe(true)
		end)

		it("should have Freeze with slowSpeed and damagePerSec", function()
			local t = GameConfig.CataclysmTypes.Freeze
			expect(t).toBeDefined()
			expect(t.name).toBe("Freeze")
			expect(t.weight > 0).toBe(true)
			expect(t.slowSpeed > 0).toBe(true)
			expect(t.damagePerSec > 0).toBe(true)
			expect(t.damageInterval > 0).toBe(true)
		end)

		it("should have all types in CataclysmTypeList", function()
			for _, key in GameConfig.CataclysmTypeList do
				expect(GameConfig.CataclysmTypes[key]).toBeDefined()
			end
		end)

		it("should have positive weights for all types", function()
			for _, key in GameConfig.CataclysmTypeList do
				expect(GameConfig.CataclysmTypes[key].weight > 0).toBe(true)
			end
		end)
	end)

	describe("pickRandomCataclysm", function()
		it("should return a valid cataclysm type", function()
			local result = GameConfig.pickRandomCataclysm(nil)
			expect(GameConfig.CataclysmTypes[result]).toBeDefined()
		end)

		it("should never return the same type as lastType", function()
			for _ = 1, 50 do
				local result = GameConfig.pickRandomCataclysm("MeteorRain")
				expect(result).never.toBe("MeteorRain")
			end
		end)

		it("should return different types over many calls", function()
			local seen = {}
			for _ = 1, 100 do
				local result = GameConfig.pickRandomCataclysm(nil)
				seen[result] = true
			end

			-- Should see at least 3 out of 4 types over 100 rolls
			local count = 0
			for _ in seen do
				count += 1
			end
			expect(count >= 3).toBe(true)
		end)

		it("should work when excluding each type", function()
			for _, excludeType in GameConfig.CataclysmTypeList do
				for _ = 1, 10 do
					local result = GameConfig.pickRandomCataclysm(excludeType)
					expect(result).never.toBe(excludeType)
					expect(GameConfig.CataclysmTypes[result]).toBeDefined()
				end
			end
		end)

		it("should respect weights (statistical)", function()
			-- MeteorRain and Freeze have weight 3, Darkness and BlackHole have weight 2
			-- So MeteorRain+Freeze should appear more than Darkness+BlackHole
			local counts = {}
			for _, key in GameConfig.CataclysmTypeList do
				counts[key] = 0
			end

			for _ = 1, 1000 do
				local result = GameConfig.pickRandomCataclysm(nil)
				counts[result] += 1
			end

			local highWeight = counts.MeteorRain + counts.Freeze
			local lowWeight = counts.Darkness + counts.BlackHole
			-- High weight types (total weight 6) should appear more than low (total weight 4)
			expect(highWeight > lowWeight).toBe(true)
		end)
	end)
end)
