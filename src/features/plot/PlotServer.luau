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
}, PlotServer))

return PlotServer
