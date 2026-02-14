local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)

local UpgradeServiceClient = {}
UpgradeServiceClient.networker = (nil :: any) :: Networker.Client

function UpgradeServiceClient.init(self: UpgradeServiceClient)
	self.networker = Networker.client.new("UpgradeService", self)
end

function UpgradeServiceClient.buySpeed(self: UpgradeServiceClient)
	self.networker:fire("buySpeed")
end

function UpgradeServiceClient.buyCarryCapacity(self: UpgradeServiceClient)
	self.networker:fire("buyCarryCapacity")
end

function UpgradeServiceClient.buyPlotCapacity(self: UpgradeServiceClient)
	self.networker:fire("buyPlotCapacity")
end

function UpgradeServiceClient.prestige(self: UpgradeServiceClient)
	self.networker:fire("prestige")
end

export type UpgradeServiceClient = typeof(UpgradeServiceClient)

return UpgradeServiceClient
