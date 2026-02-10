local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local FONT_MEDIUM = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)

local function formatNumber(n: number): string
	if n >= 1_000_000 then
		return string.format("%.1fM", n / 1_000_000)
	elseif n >= 1_000 then
		return string.format("%.1fK", n / 1_000)
	end
	return tostring(n)
end

local function StatLabel(props: { icon: string, text: string, order: number })
	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.3,
		LayoutOrder = props.order,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
		Icon = React.createElement("TextLabel", {
			Size = UDim2.new(0, 24, 1, 0),
			BackgroundTransparency = 1,
			Text = props.icon,
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Label = React.createElement("TextLabel", {
			Size = UDim2.new(1, -30, 1, 0),
			Position = UDim2.new(0, 30, 0, 0),
			BackgroundTransparency = 1,
			Text = props.text,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextStrokeTransparency = 0.5,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = FONT_MEDIUM,
		}),
	})
end

export type Props = {
	playerDataClient: any,
}

local function HudApp(props: Props)
	local client = props.playerDataClient

	local coins, setCoins = React.useState(client.coins or 0)
	local carryCount, setCarryCount = React.useState(client.carryCount or 0)
	local carryCapacity, setCarryCapacity = React.useState(client.carryCapacity or 3)
	local inventoryCount, setInventoryCount = React.useState(client.inventoryCount or 0)
	local plotCapacity, setPlotCapacity = React.useState(client.plotCapacity or 5)
	local incomePerSec, setIncomePerSec = React.useState(client.incomePerSec or 0)

	React.useEffect(function()
		local networker = client.networker
		local connections = {
			networker:getServerChangedSignal("coins"):Connect(function(val)
				setCoins(val)
			end),
			networker:getServerChangedSignal("carryCount"):Connect(function(val)
				setCarryCount(val)
			end),
			networker:getServerChangedSignal("carryCapacity"):Connect(function(val)
				setCarryCapacity(val)
			end),
			networker:getServerChangedSignal("inventoryCount"):Connect(function(val)
				setInventoryCount(val)
			end),
			networker:getServerChangedSignal("plotCapacity"):Connect(function(val)
				setPlotCapacity(val)
			end),
			networker:getServerChangedSignal("incomePerSec"):Connect(function(val)
				setIncomePerSec(val)
			end),
		}

		return function()
			for _, conn in connections do
				conn:Disconnect()
			end
		end
	end, {})

	return React.createElement("Frame", {
		Size = UDim2.new(0, 200, 0, 160),
		Position = UDim2.new(0, 12, 0, 12),
		BackgroundTransparency = 1,
	}, {
		Layout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
		Title = React.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Text = "STATS",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextStrokeTransparency = 0.3,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = FONT,
			LayoutOrder = 0,
		}),
		Coins = React.createElement(StatLabel, {
			icon = "\xF0\x9F\x92\xB0",
			text = formatNumber(coins),
			order = 1,
		}),
		Carry = React.createElement(StatLabel, {
			icon = "\xF0\x9F\x8E\x92",
			text = carryCount .. "/" .. carryCapacity,
			order = 2,
		}),
		Plot = React.createElement(StatLabel, {
			icon = "\xF0\x9F\x93\xA6",
			text = inventoryCount .. "/" .. plotCapacity,
			order = 3,
		}),
		Income = React.createElement(StatLabel, {
			icon = "\xF0\x9F\x92\xB5",
			text = "+" .. formatNumber(incomePerSec) .. "/sec",
			order = 4,
		}),
	})
end

return HudApp
