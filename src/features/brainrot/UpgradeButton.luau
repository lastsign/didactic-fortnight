local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local Billboard = require(ReplicatedStorage.Source.Features.Billboard.Billboard)

local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local FONT_MEDIUM = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)

export type Props = {
	name: string,
	level: number,
	cost: number?,
	isMaxLevel: boolean,
}

local function UpgradeLabel(props: Props)
	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Layout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0.02, 0),
		}),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0.05, 0),
			PaddingRight = UDim.new(0.05, 0),
			PaddingTop = UDim.new(0.05, 0),
			PaddingBottom = UDim.new(0.05, 0),
		}),
		NameLabel = React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 0.35),
			BackgroundTransparency = 1,
			Text = props.name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextStrokeTransparency = 0.3,
			TextScaled = true,
			FontFace = FONT,
			LayoutOrder = 1,
		}),
		LevelLabel = React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 0.3),
			BackgroundTransparency = 1,
			Text = "Lv." .. tostring(props.level),
			TextColor3 = Color3.fromRGB(255, 255, 100),
			TextStrokeTransparency = 0.3,
			TextScaled = true,
			FontFace = FONT,
			LayoutOrder = 2,
		}),
		CostLabel = React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 0.25),
			BackgroundTransparency = 1,
			Text = if props.isMaxLevel then "MAX" else "Upgrade $" .. tostring(props.cost or 0),
			TextColor3 = if props.isMaxLevel
				then Color3.fromRGB(100, 255, 100)
				else Color3.fromRGB(200, 200, 200),
			TextStrokeTransparency = 0.5,
			TextScaled = true,
			FontFace = FONT_MEDIUM,
			LayoutOrder = 3,
		}),
	})
end

------------------------------------------------------------------------

local UpgradeButton = {}
UpgradeButton.__index = UpgradeButton

export type Config = {
	part: BasePart,
	name: string,
	level: number,
	cost: number?,
	isMaxLevel: boolean,
}

function UpgradeButton.new(config: Config): UpgradeButton
	local self = setmetatable({}, UpgradeButton)

	self.billboard = Billboard.new({
		part = config.part,
		face = Enum.NormalId.Top,
		name = "UpgradeGui",
		pixelsPerStud = 50,
	})

	self.props = {
		name = config.name,
		level = config.level,
		cost = config.cost,
		isMaxLevel = config.isMaxLevel,
	} :: Props

	self.billboard:render(React.createElement(UpgradeLabel, self.props))

	return self
end

function UpgradeButton.update(self: UpgradeButton, props: Props)
	self.props = props
	self.billboard:render(React.createElement(UpgradeLabel, props))
end

function UpgradeButton.destroy(self: UpgradeButton)
	self.billboard:destroy()
end

export type UpgradeButton = typeof(setmetatable({} :: {
	billboard: Billboard.Billboard,
	props: Props,
}, UpgradeButton))

return UpgradeButton
