local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)

local BILLBOARD_SIZE = Vector3.new(4, 1.5, 0.05)
local BILLBOARD_OFFSET = CFrame.new(0, 3, 0)
local PIXELS_PER_STUD = 50

local BrainrotBillboard = {}

function BrainrotBillboard.create(parent: BasePart, brainrotId: number): BasePart
	local brainrot = GameConfig.getBrainrot(brainrotId)
	if not brainrot then
		error("[BrainrotBillboard] Unknown brainrot id: " .. tostring(brainrotId))
	end

	local rarityInfo = GameConfig.getRarityInfo(brainrot.rarity)
	local color = if rarityInfo then rarityInfo.color else Color3.fromRGB(255, 255, 255)

	local billboardPart = Instance.new("Part")
	billboardPart.Name = "BillboardPart"
	billboardPart.Size = BILLBOARD_SIZE
	billboardPart.Transparency = 1
	billboardPart.Anchored = true
	billboardPart.CanCollide = false
	billboardPart.CanQuery = false
	billboardPart.CanTouch = false
	billboardPart.CFrame = parent.CFrame * BILLBOARD_OFFSET

	local function createGui(face: Enum.NormalId, name: string): SurfaceGui
		local gui = Instance.new("SurfaceGui")
		gui.Name = name
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = PIXELS_PER_STUD
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

		gui.Parent = billboardPart
		return gui
	end

	createGui(Enum.NormalId.Front, "BrainrotBillboard")
	createGui(Enum.NormalId.Back, "BrainrotBillboardBack")

	billboardPart.Parent = parent.Parent

	return billboardPart
end

return BrainrotBillboard
