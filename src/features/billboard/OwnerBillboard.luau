local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local Billboard = require(script.Parent.Billboard)

local OwnerBillboard = {}
OwnerBillboard.__index = OwnerBillboard

export type Config = {
	part: BasePart,
	name: string,
	face: Enum.NormalId?,
}

local function OwnerLabel(props: { name: string })
	return React.createElement("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = props.name,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextStrokeTransparency = 0.5,
		TextScaled = true,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
	})
end

function OwnerBillboard.new(config: Config): OwnerBillboard
	local self = setmetatable({}, OwnerBillboard)

	self.billboard = Billboard.new({
		part = config.part,
		face = config.face,
		name = "OwnerBillboard",
	})

	self.name = config.name
	self.billboard:render(React.createElement(OwnerLabel, { name = config.name }))

	return self
end

function OwnerBillboard.setText(self: OwnerBillboard, text: string)
	self.name = text
	self.billboard:render(React.createElement(OwnerLabel, { name = text }))
end

function OwnerBillboard.destroy(self: OwnerBillboard)
	self.billboard:destroy()
end

export type OwnerBillboard = typeof(setmetatable({} :: {
	billboard: Billboard.Billboard,
	name: string,
}, OwnerBillboard))

return OwnerBillboard
