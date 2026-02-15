local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)
local UITheme = require(ReplicatedStorage.Source.Core.UITheme)

local Colors = UITheme.Colors
local Fonts = UITheme.Font

local CATACLYSM_STYLES = {
	MeteorRain = { bg = Colors.Red, glow = Colors.RedGlow, icon = "\xF0\x9F\x94\xA5" },
	Darkness = { bg = Colors.CatDark, glow = Color3.fromRGB(100, 30, 130), icon = "\xF0\x9F\x91\x81" },
	BlackHole = { bg = Colors.CatBlackHole, glow = Color3.fromRGB(140, 50, 200), icon = "\xF0\x9F\x8C\x80" },
	Freeze = { bg = Colors.CatFreeze, glow = Color3.fromRGB(80, 160, 255), icon = "\xE2\x9D\x84" },
}
local DEFAULT_STYLE = { bg = Colors.Red, glow = Colors.RedGlow, icon = "\xE2\x9A\xA0" }

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
			networker:getServerChangedSignal("phase"):Connect(function(val) setPhase(val) end),
			networker:getServerChangedSignal("cataclysmType"):Connect(function(val) setCataclysmType(val) end),
		}
		return function()
			for _, conn in connections do conn:Disconnect() end
		end
	end, {})

	React.useEffect(function()
		if phase ~= "warning" then return end
		local running = true
		task.spawn(function()
			while running do
				task.wait(0.4)
				if not running then break end
				setBlink(function(prev) return not prev end)
			end
		end)
		return function() running = false end
	end, { phase })

	if phase == "peace" then
		return nil
	end

	local typeConfig = GameConfig.CataclysmTypes[cataclysmType]
	local displayName = if typeConfig then typeConfig.name else cataclysmType
	local style = CATACLYSM_STYLES[cataclysmType] or DEFAULT_STYLE

	if phase == "warning" then
		-- Responsive warning banner: 50% width, capped 120-400px
		return React.createElement("Frame", {
			Size = UDim2.fromScale(0.5, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Position = UDim2.new(0.5, 0, 0, 6),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Colors.CatWarn,
			BackgroundTransparency = if blink then 0.05 else 0.2,
		}, {
			SizeConstraint = React.createElement("UISizeConstraint", {
				MinSize = Vector2.new(120, 0),
				MaxSize = Vector2.new(400, 60),
			}),
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 14) }),
			Stroke = React.createElement("UIStroke", {
				Color = if blink then Colors.Accent else Colors.CatWarn,
				Thickness = if blink then 2 else 1,
				Transparency = if blink then 0.2 else 0.6,
			}),
			Gradient = React.createElement("UIGradient", {
				Color = ColorSequence.new(
					Color3.fromRGB(180, 30, 20),
					Color3.fromRGB(110, 10, 10)
				),
				Rotation = 90,
			}),
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
			}),
			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 1),
			}),
			Top = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 16),
				BackgroundTransparency = 1,
				Text = "\xE2\x9A\xA0\xEF\xB8\x8F CATACLYSM INCOMING",
				TextColor3 = Colors.Accent,
				TextStrokeColor3 = Color3.new(0, 0, 0),
				TextStrokeTransparency = 0.3,
				TextScaled = true,
				FontFace = Fonts.Heavy,
				LayoutOrder = 1,
			}),
			Bottom = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 13),
				BackgroundTransparency = 1,
				Text = style.icon .. " " .. displayName .. " — GET TO SAFETY!",
				TextColor3 = Colors.TextPrimary,
				TextStrokeColor3 = Color3.new(0, 0, 0),
				TextStrokeTransparency = 0.5,
				TextScaled = true,
				FontFace = Fonts.SemiBold,
				LayoutOrder = 2,
			}),
		})
	end

	-- Active phase — compact banner
	return React.createElement("Frame", {
		Size = UDim2.fromScale(0.35, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0.5, 0, 0, 6),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = style.bg,
		BackgroundTransparency = 0.1,
	}, {
		SizeConstraint = React.createElement("UISizeConstraint", {
			MinSize = Vector2.new(100, 0),
			MaxSize = Vector2.new(300, 40),
		}),
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Stroke = React.createElement("UIStroke", {
			Color = style.glow,
			Thickness = 1.5,
			Transparency = 0.35,
		}),
		Gradient = React.createElement("UIGradient", {
			Color = ColorSequence.new(
				style.bg,
				style.bg:Lerp(Color3.new(0, 0, 0), 0.4)
			),
			Rotation = 90,
		}),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 5),
			PaddingBottom = UDim.new(0, 5),
		}),
		Text = React.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = style.icon .. "  " .. displayName .. " ACTIVE",
			TextColor3 = Colors.TextPrimary,
			TextStrokeColor3 = Color3.new(0, 0, 0),
			TextStrokeTransparency = 0.3,
			TextScaled = true,
			FontFace = Fonts.Bold,
		}),
	})
end

return CataclysmWarning
