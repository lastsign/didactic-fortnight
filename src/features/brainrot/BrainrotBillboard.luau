local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)

local BrainrotBillboard = {}

function BrainrotBillboard.create(parent: BasePart, brainrotId: number): BillboardGui
	local brainrot = GameConfig.getBrainrot(brainrotId)
	if not brainrot then
		error("[BrainrotBillboard] Unknown brainrot id: " .. tostring(brainrotId))
	end

	local rarityInfo = GameConfig.getRarityInfo(brainrot.rarity)
	local color = if rarityInfo then rarityInfo.color else Color3.fromRGB(255, 255, 255)

	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotBillboard"
	gui.Size = UDim2.fromOffset(200, 50)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.fromScale(1, 0.6)
	nameLabel.Position = UDim2.fromScale(0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = brainrot.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.TextScaled = true
	nameLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	nameLabel.Parent = gui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.fromScale(1, 0.4)
	rarityLabel.Position = UDim2.fromScale(0, 0.6)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = brainrot.rarity
	rarityLabel.TextColor3 = color
	rarityLabel.TextStrokeTransparency = 0.5
	rarityLabel.TextScaled = true
	rarityLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	rarityLabel.Parent = gui

	gui.Parent = parent

	return gui
end

return BrainrotBillboard
