local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local ShopApp = require(ReplicatedStorage.Source.Features.Upgrade.ShopApp)
local CataclysmWarning = require(ReplicatedStorage.Source.Features.Cataclysm.CataclysmWarning)

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
		Size = UDim2.fromScale(1, 0.18),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.3,
		LayoutOrder = props.order,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.25, 0) }),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0.05, 0),
			PaddingRight = UDim.new(0.05, 0),
		}),
		Icon = React.createElement("TextLabel", {
			Size = UDim2.fromScale(0.15, 1),
			BackgroundTransparency = 1,
			Text = props.icon,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Label = React.createElement("TextLabel", {
			Size = UDim2.fromScale(0.8, 1),
			Position = UDim2.fromScale(0.2, 0),
			BackgroundTransparency = 1,
			Text = props.text,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextStrokeTransparency = 0.5,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = FONT_MEDIUM,
		}),
	})
end

export type Props = {
	playerDataClient: any,
	upgradeClient: any,
	cataclysmClient: any,
}

local function HudApp(props: Props)
	local client = props.playerDataClient
	local shopOpen, setShopOpen = React.useState(false)

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
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Stats = React.createElement("Frame", {
			Size = UDim2.fromScale(0.13, 0.22),
			Position = UDim2.fromScale(0.005, 0.015),
			BackgroundTransparency = 1,
		}, {
			SizeConstraint = React.createElement("UISizeConstraint", {
				MaxSize = Vector2.new(220, 180),
				MinSize = Vector2.new(120, 100),
			}),
			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0.02, 0),
			}),
			Title = React.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 0.12),
				BackgroundTransparency = 1,
				Text = "STATS",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextStrokeTransparency = 0.3,
				TextScaled = true,
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
			ShopButton = React.createElement("TextButton", {
				Size = UDim2.fromScale(1, 0.16),
				BackgroundColor3 = Color3.fromRGB(50, 30, 80),
				Text = "SHOP",
				TextColor3 = Color3.fromRGB(255, 220, 50),
				TextScaled = true,
				FontFace = FONT,
				LayoutOrder = 5,
				[React.Event.Activated] = function()
					setShopOpen(function(prev)
						return not prev
					end)
				end,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.25, 0) }),
			}),
		}),
		Shop = React.createElement(ShopApp, {
			playerDataClient = client,
			upgradeClient = props.upgradeClient,
			visible = shopOpen,
		}),
		Cataclysm = React.createElement(CataclysmWarning, {
			cataclysmClient = props.cataclysmClient,
		}),
	})
end

return HudApp
