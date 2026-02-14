local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)

describe("PvP System Config", function()
	describe("PvP constants", function()
		it("should have positive knockback base", function()
			expect(GameConfig.PVP_KNOCKBACK_BASE > 0).toBe(true)
		end)

		it("should have positive knockback speed multiplier", function()
			expect(GameConfig.PVP_KNOCKBACK_SPEED_MULT > 0).toBe(true)
		end)

		it("should have positive cooldown", function()
			expect(GameConfig.PVP_COOLDOWN > 0).toBe(true)
		end)

		it("should have positive spawn invulnerability", function()
			expect(GameConfig.PVP_SPAWN_INVULNERABILITY > 0).toBe(true)
		end)

		it("should have positive ragdoll threshold", function()
			expect(GameConfig.PVP_RAGDOLL_THRESHOLD > 0).toBe(true)
		end)

		it("should have positive ragdoll duration", function()
			expect(GameConfig.PVP_RAGDOLL_DURATION > 0).toBe(true)
		end)

		it("should have positive hit radius", function()
			expect(GameConfig.PVP_HIT_RADIUS > 0).toBe(true)
		end)

		it("should have positive min speed", function()
			expect(GameConfig.PVP_MIN_SPEED > 0).toBe(true)
		end)

		it("should have positive safe zone radius", function()
			expect(GameConfig.PVP_SAFE_ZONE_RADIUS > 0).toBe(true)
		end)

		it("should have ragdoll threshold greater than knockback base", function()
			expect(GameConfig.PVP_RAGDOLL_THRESHOLD > GameConfig.PVP_KNOCKBACK_BASE).toBe(true)
		end)
	end)

	describe("getKnockbackForce", function()
		it("should return base force when speeds are equal", function()
			local force = GameConfig.getKnockbackForce(20, 20)
			expect(force).toBe(GameConfig.PVP_KNOCKBACK_BASE)
		end)

		it("should increase force with speed difference", function()
			local force1 = GameConfig.getKnockbackForce(20, 10)
			local force2 = GameConfig.getKnockbackForce(30, 10)
			expect(force2 > force1).toBe(true)
		end)

		it("should not go below base when target is faster", function()
			local force = GameConfig.getKnockbackForce(10, 30)
			expect(force).toBe(GameConfig.PVP_KNOCKBACK_BASE)
		end)

		it("should match formula: base + max(0, attackerSpeed - targetSpeed) * mult", function()
			local attackerSpeed = 25
			local targetSpeed = 15
			local expected = GameConfig.PVP_KNOCKBACK_BASE
				+ (attackerSpeed - targetSpeed) * GameConfig.PVP_KNOCKBACK_SPEED_MULT
			expect(GameConfig.getKnockbackForce(attackerSpeed, targetSpeed)).toBe(expected)
		end)

		it("should trigger ragdoll at sufficient speed difference", function()
			-- Find speed diff that causes ragdoll
			local neededForce = GameConfig.PVP_RAGDOLL_THRESHOLD
			local neededDiff = (neededForce - GameConfig.PVP_KNOCKBACK_BASE) / GameConfig.PVP_KNOCKBACK_SPEED_MULT
			local force = GameConfig.getKnockbackForce(neededDiff + 10, 10)
			expect(force >= GameConfig.PVP_RAGDOLL_THRESHOLD).toBe(true)
		end)
	end)
end)
