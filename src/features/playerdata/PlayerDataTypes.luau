local PlayerDataTypes = {}

export type BrainrotEntry = {
	id: number,
	slot: number,
}

export type ProfileData = {
	Coins: number,
	Inventory: { BrainrotEntry },
	SpeedLevel: number,
	PrestigeLevel: number,
	JumpLevel: number,
	PlotCapacity: number,
	CarryCapacity: number,
	TotalEarnings: number,
}

return PlayerDataTypes
