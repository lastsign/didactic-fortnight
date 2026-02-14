local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)

local LIFETIME = GameConfig.DROPPED_BRAINROT_LIFETIME
local PICKUP_DEBOUNCE = 0.5

local DroppedBrainrot = {}

function DroppedBrainrot.spawn(position: Vector3, brainrotId: number, playerDataService: any)
	local brainrot = GameConfig.getBrainrot(brainrotId)
	if not brainrot then
		return
	end

	local rarityInfo = GameConfig.getRarityInfo(brainrot.rarity)
	local color = if rarityInfo then rarityInfo.color else Color3.fromRGB(200, 200, 200)

	local part = Instance.new("Part")
	part.Name = "DroppedBrainrot"
	part.Size = Vector3.new(2, 2, 2)
	part.Shape = Enum.PartType.Ball
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Anchored = false
	part.CanCollide = true
	part.Position = position + Vector3.new(0, 3, 0)
	part:SetAttribute("BrainrotId", brainrotId)

	-- Billboard с именем
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(100, 30)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = brainrot.name
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	label.Parent = billboard

	-- Pickup через Touched
	local pickedUp = false
	local debounces: { [Player]: number } = {}

	part.Touched:Connect(function(hit: BasePart)
		if pickedUp then
			return
		end

		local character = hit.Parent :: Model
		if not character then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local now = tick()
		if debounces[player] and now - debounces[player] < PICKUP_DEBOUNCE then
			return
		end
		debounces[player] = now

		local success = playerDataService:addToCarry(player, brainrotId)
		if success then
			pickedUp = true
			part:Destroy()
		end
	end)

	part.Parent = workspace

	-- Таймер исчезновения
	task.delay(LIFETIME, function()
		if not pickedUp and part.Parent then
			part:Destroy()
		end
	end)
end

function DroppedBrainrot.dropCarry(player: Player, playerDataService: any)
	local carry = playerDataService:getCarryInventory(player)
	if #carry == 0 then
		return
	end

	local character = player.Character
	local position = if character and character.PrimaryPart
		then character.PrimaryPart.Position
		else Vector3.new(0, 5, 0)

	for i, brainrotId in carry do
		-- Немного разбросать
		local offset = Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
		DroppedBrainrot.spawn(position + offset, brainrotId, playerDataService)
	end

	playerDataService:clearCarry(player)
end

return DroppedBrainrot
