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
