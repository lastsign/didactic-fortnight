local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)

local PlayerDataServiceClient = {}
PlayerDataServiceClient.coins = 0
PlayerDataServiceClient.inventory = {}
PlayerDataServiceClient.inventoryCount = 0
PlayerDataServiceClient.plotCapacity = 5
PlayerDataServiceClient.carryCount = 0
PlayerDataServiceClient.carryInventory = {}
PlayerDataServiceClient.carryCapacity = 3
PlayerDataServiceClient.incomePerSec = 0
PlayerDataServiceClient.networker = (nil :: any) :: Networker.Client

function PlayerDataServiceClient.init(self: PlayerDataServiceClient)
	self.networker = Networker.client.new("PlayerDataService", self)
end

function PlayerDataServiceClient.depositOneBrainrot(self: PlayerDataServiceClient)
	self.networker:fire("depositOneBrainrot")
end

function PlayerDataServiceClient.upgradeBrainrot(self: PlayerDataServiceClient, slot: number)
	self.networker:fire("upgradeBrainrot", slot)
end

function PlayerDataServiceClient.pickupFromPlot(self: PlayerDataServiceClient, slot: number)
	self.networker:fire("pickupFromPlot", slot)
end

export type PlayerDataServiceClient = typeof(PlayerDataServiceClient)

return PlayerDataServiceClient
