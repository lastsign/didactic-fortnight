local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)

local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)

export type Props = {
	cataclysmClient: any,
}

local function CataclysmWarning(props: Props)
	local client = props.cataclysmClient

	local phase, setPhase = React.useState(client.phase or "peace")
	local cataclysmType, setCataclysmType = React.useState(client.cataclysmType or "")
	local blink, setBlink = React.useState(true)

	React.useEffect(function()
		local networker = client.networker
		local connections = {
			networker:getServerChangedSignal("phase"):Connect(function(val)
				setPhase(val)
			end),
			networker:getServerChangedSignal("cataclysmType"):Connect(function(val)
				setCataclysmType(val)
			end),
		}
		return function()
			for _, conn in connections do
				conn:Disconnect()
			end
		end
	end, {})

	-- Мигание для warning фазы
	React.useEffect(function()
		if phase ~= "warning" then
			return
		end

		local running = true
		task.spawn(function()
			while running do
				task.wait(0.5)
				if not running then
					break
				end
				setBlink(function(prev)
					return not prev
				end)
			end
		end)

		return function()
			running = false
		end
	end, { phase })

	if phase == "peace" then
		return nil
	end

	local typeConfig = GameConfig.CataclysmTypes[cataclysmType]
	local displayName = if typeConfig then typeConfig.name else cataclysmType

	if phase == "warning" then
		return React.createElement("Frame", {
			Size = UDim2.fromScale(0.4, 0.08),
			Position = UDim2.fromScale(0.3, 0.05),
			BackgroundColor3 = Color3.fromRGB(150, 0, 0),
			BackgroundTransparency = if blink then 0.2 else 0.6,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Text = React.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "CATACLYSM: " .. displayName .. " INCOMING!",
				TextColor3 = Color3.fromRGB(255, 255, 50),
				TextStrokeTransparency = 0,
				TextScaled = true,
				FontFace = FONT,
			}),
		})
	end

	-- active phase
	local bgColor = Color3.fromRGB(100, 0, 0)
	if cataclysmType == "Freeze" then
		bgColor = Color3.fromRGB(0, 50, 150)
	elseif cataclysmType == "Darkness" then
		bgColor = Color3.fromRGB(30, 0, 50)
	elseif cataclysmType == "BlackHole" then
		bgColor = Color3.fromRGB(60, 0, 100)
	end

	return React.createElement("Frame", {
		Size = UDim2.fromScale(0.3, 0.06),
		Position = UDim2.fromScale(0.35, 0.05),
		BackgroundColor3 = bgColor,
		BackgroundTransparency = 0.3,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Text = React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = displayName .. " ACTIVE",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextStrokeTransparency = 0,
			TextScaled = true,
			FontFace = FONT,
		}),
	})
end

return CataclysmWarning
