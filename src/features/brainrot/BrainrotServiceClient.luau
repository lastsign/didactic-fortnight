local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerDataServiceClient = require(ReplicatedStorage.Source.Features.Playerdata.PlayerDataServiceClient)

local BRAINROT_TAG = "Brainrot"
local DEPOSIT_TAG = "DepositZone"
local FLOAT_SPEED = 2
local FLOAT_AMPLITUDE = 0.5
local SPIN_SPEED = 1
local DEPOSIT_DEBOUNCE = 1

local BrainrotServiceClient = {}
BrainrotServiceClient.baseCFrames = {} :: { [Model]: CFrame }
BrainrotServiceClient.lastDeposit = 0

function BrainrotServiceClient.init(self: BrainrotServiceClient)
	self:_setupAnimation()
	self:_setupDepositZone()
end

function BrainrotServiceClient._setupAnimation(self: BrainrotServiceClient)
	-- Запоминаем базовую позицию при появлении brainrot'а
	local function onBrainrotAdded(model: Instance)
		if not model:IsA("Model") or not model.PrimaryPart then
			return
		end
		self.baseCFrames[model :: Model] = model:GetPivot()
	end

	local function onBrainrotRemoved(model: Instance)
		self.baseCFrames[model :: Model] = nil
	end

	for _, model in CollectionService:GetTagged(BRAINROT_TAG) do
		onBrainrotAdded(model)
	end

	CollectionService:GetInstanceAddedSignal(BRAINROT_TAG):Connect(onBrainrotAdded)
	CollectionService:GetInstanceRemovedSignal(BRAINROT_TAG):Connect(onBrainrotRemoved)

	-- Анимация: парение + вращение
	RunService.Heartbeat:Connect(function()
		local t = tick()

		for model, baseCF in self.baseCFrames do
			if model.PrimaryPart then
				local floatOffset = math.sin(t * FLOAT_SPEED) * FLOAT_AMPLITUDE
				local rotation = CFrame.Angles(0, t * SPIN_SPEED, 0)
				model:PivotTo(baseCF * CFrame.new(0, floatOffset, 0) * rotation)
			end
		end
	end)
end

function BrainrotServiceClient._setupDepositZone(self: BrainrotServiceClient)
	local function connectDeposit(zone: Instance)
		if not zone:IsA("BasePart") then
			return
		end

		zone.Touched:Connect(function(hit: BasePart)
			local character = hit.Parent
			if not character then
				return
			end

			local player = Players:GetPlayerFromCharacter(character)
			if player ~= Players.LocalPlayer then
				return
			end

			local now = tick()
			if (now - self.lastDeposit) < DEPOSIT_DEBOUNCE then
				return
			end
			self.lastDeposit = now

			PlayerDataServiceClient:depositBrainrots()
		end)
	end

	for _, zone in CollectionService:GetTagged(DEPOSIT_TAG) do
		connectDeposit(zone)
	end

	CollectionService:GetInstanceAddedSignal(DEPOSIT_TAG):Connect(connectDeposit)
end

export type BrainrotServiceClient = typeof(BrainrotServiceClient)

return BrainrotServiceClient
