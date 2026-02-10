export type Brainrot = {
	id: number,
	name: string,
	rarity: string,
	incomePerSec: number,
	zone: number,
}

local GameConfig = {}

GameConfig.PRESTIGE_BONUS_PER_LEVEL = 0.1

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

return GameConfig
