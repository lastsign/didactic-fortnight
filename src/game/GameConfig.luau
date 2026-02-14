export type Brainrot = {
	id: number,
	name: string,
	rarity: string,
	incomePerSec: number,
	zone: number,
}

export type RarityInfo = {
	weight: number,
	respawnTime: number,
	color: Color3,
}

local GameConfig = {}

GameConfig.PRESTIGE_BONUS_PER_LEVEL = 0.1
GameConfig.PRESTIGE_JUMP_PER_LEVEL = 5

GameConfig.UPGRADE_MAX_LEVEL = 10
GameConfig.UPGRADE_BASE_COST = 50
GameConfig.UPGRADE_COST_MULTIPLIER = 1.5
GameConfig.UPGRADE_INCOME_MULTIPLIER = 0.5

GameConfig.RarityConfig = {
	Common = { weight = 10, respawnTime = 30, color = Color3.fromRGB(200, 200, 200) },
	Uncommon = { weight = 5, respawnTime = 45, color = Color3.fromRGB(0, 200, 0) },
	Rare = { weight = 2, respawnTime = 60, color = Color3.fromRGB(0, 120, 255) },
	Epic = { weight = 1, respawnTime = 90, color = Color3.fromRGB(180, 0, 255) },
	Legendary = { weight = 0.5, respawnTime = 120, color = Color3.fromRGB(255, 200, 0) },
} :: { [string]: RarityInfo }

GameConfig.Brainrots = {
	[1] = { id = 1, name = "Skibidi Toilet", rarity = "Common", incomePerSec = 1, zone = 1 },
	[2] = { id = 2, name = "Sigma Cat", rarity = "Common", incomePerSec = 2, zone = 1 },
	[3] = { id = 3, name = "Ohio Rizz", rarity = "Uncommon", incomePerSec = 5, zone = 2 },
	[4] = { id = 4, name = "Grimace Shake", rarity = "Uncommon", incomePerSec = 8, zone = 2 },
	[5] = { id = 5, name = "Baby Gronk", rarity = "Rare", incomePerSec = 15, zone = 3 },
	[6] = { id = 6, name = "Livvy Dunne Gyatt", rarity = "Rare", incomePerSec = 25, zone = 3 },
	[7] = { id = 7, name = "Duke Dennis", rarity = "Epic", incomePerSec = 50, zone = 4 },
	[8] = { id = 8, name = "Fanum Tax", rarity = "Legendary", incomePerSec = 100, zone = 4 },
} :: { [number]: Brainrot }

-- Player upgrade configs
GameConfig.SPEED_BASE_PRICE = 100
GameConfig.SPEED_MAX_LEVEL = 50
GameConfig.SPEED_PER_LEVEL = 2 -- WalkSpeed = 16 + (level - 1) * 2

GameConfig.CARRY_BASE_PRICE = 200
GameConfig.CARRY_MAX_LEVEL = 10 -- 3 → 10

GameConfig.PLOT_CAPACITY_BASE_PRICE = 500
GameConfig.PLOT_CAPACITY_MAX_LEVEL = 20 -- 5 → 20

-- Prestige requirements per level: { totalEarnings, speedLevel }
GameConfig.PrestigeRequirements = {
	[1] = { totalEarnings = 5000, speedLevel = 10 },
	[2] = { totalEarnings = 25000, speedLevel = 15 },
	[3] = { totalEarnings = 100000, speedLevel = 20 },
	[4] = { totalEarnings = 500000, speedLevel = 25 },
	[5] = { totalEarnings = 2000000, speedLevel = 30 },
	[6] = { totalEarnings = 10000000, speedLevel = 35 },
	[7] = { totalEarnings = 50000000, speedLevel = 40 },
	[8] = { totalEarnings = 200000000, speedLevel = 45 },
	[9] = { totalEarnings = 1000000000, speedLevel = 48 },
	[10] = { totalEarnings = 5000000000, speedLevel = 50 },
}

function GameConfig.getPlayerUpgradePrice(basePrice: number, currentLevel: number): number
	return math.floor(basePrice * (currentLevel ^ 1.5))
end

function GameConfig.getPrestigeRequirements(nextPrestigeLevel: number): { totalEarnings: number, speedLevel: number }?
	return GameConfig.PrestigeRequirements[nextPrestigeLevel]
end

function GameConfig.canPrestige(data: { TotalEarnings: number, SpeedLevel: number, PrestigeLevel: number }): boolean
	local req = GameConfig.PrestigeRequirements[data.PrestigeLevel + 1]
	if not req then
		return false
	end
	return data.TotalEarnings >= req.totalEarnings and data.SpeedLevel >= req.speedLevel
end

-- PvP system
GameConfig.PVP_KNOCKBACK_BASE = 50
GameConfig.PVP_KNOCKBACK_SPEED_MULT = 2
GameConfig.PVP_COOLDOWN = 5
GameConfig.PVP_SPAWN_INVULNERABILITY = 3
GameConfig.PVP_RAGDOLL_THRESHOLD = 80
GameConfig.PVP_RAGDOLL_DURATION = 2
GameConfig.PVP_HIT_RADIUS = 4
GameConfig.PVP_MIN_SPEED = 10
GameConfig.PVP_SAFE_ZONE_RADIUS = 30

function GameConfig.getKnockbackForce(attackerSpeed: number, targetSpeed: number): number
	local speedDiff = math.max(0, attackerSpeed - targetSpeed)
	return GameConfig.PVP_KNOCKBACK_BASE + speedDiff * GameConfig.PVP_KNOCKBACK_SPEED_MULT
end

-- Cataclysm system
GameConfig.CATACLYSM_PEACE_TIME_MIN = 60
GameConfig.CATACLYSM_PEACE_TIME_MAX = 120
GameConfig.CATACLYSM_WARNING_TIME = 10
GameConfig.CATACLYSM_DURATION_MIN = 15
GameConfig.CATACLYSM_DURATION_MAX = 30
GameConfig.DROPPED_BRAINROT_LIFETIME = 15

export type CataclysmType = {
	name: string,
	weight: number,
	damagePerHit: number?,
	damagePerSec: number?,
	damageInterval: number?,
	monsterSpeed: number?,
	pullForce: number?,
	slowSpeed: number?,
}

GameConfig.CataclysmTypes = {
	MeteorRain = {
		name = "Meteor Rain",
		weight = 3,
		damagePerHit = 100,
	},
	Darkness = {
		name = "Darkness",
		weight = 2,
		monsterSpeed = 40,
	},
	BlackHole = {
		name = "Black Hole",
		weight = 2,
		pullForce = 30,
		damagePerSec = 10,
	},
	Freeze = {
		name = "Freeze",
		weight = 3,
		slowSpeed = 4,
		damagePerSec = 5,
		damageInterval = 2,
	},
} :: { [string]: CataclysmType }

GameConfig.CataclysmTypeList = { "MeteorRain", "Darkness", "BlackHole", "Freeze" }

function GameConfig.pickRandomCataclysm(lastType: string?): string
	local totalWeight = 0
	for _, key in GameConfig.CataclysmTypeList do
		if key ~= lastType then
			totalWeight += GameConfig.CataclysmTypes[key].weight
		end
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, key in GameConfig.CataclysmTypeList do
		if key ~= lastType then
			cumulative += GameConfig.CataclysmTypes[key].weight
			if roll <= cumulative then
				return key
			end
		end
	end

	return GameConfig.CataclysmTypeList[1]
end

function GameConfig.getBrainrot(id: number): Brainrot?
	return GameConfig.Brainrots[id]
end

function GameConfig.getBrainrotsForZone(zone: number): { Brainrot }
	local result = {}
	for _, brainrot in GameConfig.Brainrots do
		if brainrot.zone == zone then
			table.insert(result, brainrot)
		end
	end
	return result
end

function GameConfig.getRarityInfo(rarity: string): RarityInfo?
	return GameConfig.RarityConfig[rarity]
end

function GameConfig.getUpgradeCost(brainrotId: number, currentLevel: number): number
	local brainrot = GameConfig.getBrainrot(brainrotId)
	if not brainrot then
		return math.huge
	end

	local baseCost = GameConfig.UPGRADE_BASE_COST * brainrot.incomePerSec
	return math.floor(baseCost * (GameConfig.UPGRADE_COST_MULTIPLIER ^ (currentLevel - 1)))
end

function GameConfig.getIncomeForLevel(brainrotId: number, level: number): number
	local brainrot = GameConfig.getBrainrot(brainrotId)
	if not brainrot then
		return 0
	end

	return brainrot.incomePerSec * (1 + (level - 1) * GameConfig.UPGRADE_INCOME_MULTIPLIER)
end

return GameConfig
