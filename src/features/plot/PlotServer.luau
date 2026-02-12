local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Packages.Janitor)

local PlotTypes = require(ReplicatedStorage.Source.Features.Plot.PlotTypes)

local OwnerBillboard = require(ReplicatedStorage.Source.Features.Billboard.OwnerBillboard)

local CHAR_SPAWN_OFFSET = CFrame.new(0, 5, 0)
local RESPAWN_DELAY = 5

local PlotServer = {}
PlotServer.__index = PlotServer

function PlotServer.new(plotSpawn: PlotTypes.PlotSpawn, player: Player): Plot
	local self = setmetatable({}, PlotServer)
	self.player = player
	self.index = plotSpawn.index
	self.cf = plotSpawn.part:GetPivot()
	self.janitor = Janitor.new()

	self.plotModel = self:_buildPlotModel(plotSpawn)
	self.slotPositions = {} :: { [number]: BasePart }
	self.placedModels = {} :: { [number]: Model }
	self:_cacheSlotPositions()
	self:_buildOwnerBillboard()
	self:_initCharacterSpawning()

	return self
end

function PlotServer._buildPlotModel(self: Plot, plotSpawn: PlotTypes.PlotSpawn): Model
	local template = ReplicatedStorage.Assets.PlotStorage["1"] :: Model
	local templatePivot = template:GetPivot()
	local targetPivot = plotSpawn.part:GetPivot()
	local delta = targetPivot * templatePivot:Inverse()

	local plot = Instance.new("Model")
	plot.Name = "Plot_" .. tostring(self.index)

	for _, child in template:GetChildren() do
		local cloned = child:Clone()
		if cloned:IsA("BasePart") then
			cloned.CFrame = delta * cloned.CFrame
			cloned.Anchored = true
		end
		for _, desc in cloned:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.CFrame = delta * desc.CFrame
				desc.Anchored = true
			end
		end
		cloned.Parent = plot
		if template.PrimaryPart and child.Name == template.PrimaryPart.Name then
			plot.PrimaryPart = cloned :: BasePart
		end
	end

	plot.Parent = workspace
	self.janitor:Add(plot)

	return plot
end

function PlotServer._cacheSlotPositions(self: Plot)
	for _, child in self.plotModel:GetDescendants() do
		if child:IsA("BasePart") and child.Name == "PlotSlot" then
			local slotNum = child:GetAttribute("Slot") :: number
			if slotNum then
				self.slotPositions[slotNum] = child
			end
		end
	end
end

function PlotServer.getSlotPart(self: Plot, slot: number): BasePart?
	return self.slotPositions[slot]
end

function PlotServer.placeModelAtSlot(self: Plot, slot: number, model: Model)
	if self.placedModels[slot] then
		self.placedModels[slot]:Destroy()
	end

	local slotPart = self.slotPositions[slot]
	if not slotPart then
		warn("[PlotServer] No slot position found for slot:", slot)
		return
	end

	-- Рассчитываем позицию: модель ставится НА ВЕРХ слота
	local slotTop = slotPart.CFrame * CFrame.new(0, slotPart.Size.Y / 2, 0)

	-- Высота модели от пивота до низа
	local _, modelSize = model:GetBoundingBox()
	local modelHalfHeight = modelSize.Y / 2

	model:PivotTo(slotTop * CFrame.new(0, modelHalfHeight, 0))
	model.Parent = self.plotModel
	self.placedModels[slot] = model
end

function PlotServer.removeModelAtSlot(self: Plot, slot: number)
	local model = self.placedModels[slot]
	if model then
		model:Destroy()
		self.placedModels[slot] = nil
	end
end

function PlotServer._buildOwnerBillboard(self: Plot)
	local signBoard = self.plotModel:FindFirstChild("SignBoard", true)
	if not signBoard then
		warn("[PlotServer] SignBoard not found in plot template")
		return
	end

	self.ownerBillboard = OwnerBillboard.new({
		part = signBoard,
		name = self.player.DisplayName,
	})
	self.janitor:Add(self.ownerBillboard, "destroy")
end

function PlotServer._initCharacterSpawning(self: Plot)
	self.janitor:Add(self.player.CharacterAdded:Connect(function(character: Model)
		character:PivotTo(self.cf * CHAR_SPAWN_OFFSET)

		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			task.wait(RESPAWN_DELAY)
			if self.player.Parent then
				self.player:LoadCharacterAsync()
			end
		end)
	end))

	-- Initial spawn
	self.player:LoadCharacterAsync()
	local character = self.player.Character or self.player.CharacterAdded:Wait()
	character:PivotTo(self.cf * CHAR_SPAWN_OFFSET)
end

function PlotServer.destroy(self: Plot)
	self.janitor:Destroy()
end

export type Plot = typeof(setmetatable({} :: {
	player: Player,
	cf: CFrame,
	index: number,
	plotModel: Model,
	janitor: Janitor.Janitor,
	slotPositions: { [number]: BasePart },
	placedModels: { [number]: Model },
}, PlotServer))

return PlotServer
