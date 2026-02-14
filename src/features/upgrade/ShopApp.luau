local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)

local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local FONT_MEDIUM = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)

local function formatNumber(n: number): string
	if n >= 1_000_000_000 then
		return string.format("%.1fB", n / 1_000_000_000)
	elseif n >= 1_000_000 then
		return string.format("%.1fM", n / 1_000_000)
	elseif n >= 1_000 then
		return string.format("%.1fK", n / 1_000)
	end
	return tostring(n)
end

local function UpgradeCard(props: {
	title: string,
	level: number,
	maxLevel: number,
	cost: number,
	coins: number,
	order: number,
	onBuy: () -> (),
})
	local isMaxed = props.level >= props.maxLevel
	local canAfford = props.coins >= props.cost

	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundColor3 = Color3.fromRGB(35, 35, 45),
		LayoutOrder = props.order,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
		Title = React.createElement("TextLabel", {
			Size = UDim2.new(0.5, 0, 0.4, 0),
			BackgroundTransparency = 1,
			Text = props.title,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = FONT,
		}),
		Level = React.createElement("TextLabel", {
			Size = UDim2.new(0.5, 0, 0.4, 0),
			Position = UDim2.fromScale(0, 0.45),
			BackgroundTransparency = 1,
			Text = "Lv." .. props.level .. "/" .. props.maxLevel,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = FONT_MEDIUM,
		}),
		BuyButton = React.createElement("TextButton", {
			Size = UDim2.new(0.35, 0, 0.7, 0),
			Position = UDim2.fromScale(0.65, 0.15),
			BackgroundColor3 = if isMaxed
				then Color3.fromRGB(80, 80, 80)
				elseif canAfford then Color3.fromRGB(0, 180, 80)
				else Color3.fromRGB(120, 40, 40),
			Text = if isMaxed then "MAX" else formatNumber(props.cost),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			FontFace = FONT,
			[React.Event.Activated] = if isMaxed then nil else props.onBuy,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
		}),
	})
end

export type Props = {
	playerDataClient: any,
	upgradeClient: any,
	visible: boolean,
}

local function ShopApp(props: Props)
	local pdClient = props.playerDataClient
	local upgradeClient = props.upgradeClient

	local coins, setCoins = React.useState(pdClient.coins or 0)
	local speedLevel, setSpeedLevel = React.useState(pdClient.speedLevel or 1)
	local carryCapacity, setCarryCapacity = React.useState(pdClient.carryCapacity or 3)
	local plotCapacity, setPlotCapacity = React.useState(pdClient.plotCapacity or 5)
	local prestigeLevel, setPrestigeLevel = React.useState(pdClient.prestigeLevel or 0)
	local totalEarnings, setTotalEarnings = React.useState(pdClient.totalEarnings or 0)

	React.useEffect(function()
		local networker = pdClient.networker
		local connections = {
			networker:getServerChangedSignal("coins"):Connect(function(val)
				setCoins(val)
			end),
			networker:getServerChangedSignal("speedLevel"):Connect(function(val)
				setSpeedLevel(val)
			end),
			networker:getServerChangedSignal("carryCapacity"):Connect(function(val)
				setCarryCapacity(val)
			end),
			networker:getServerChangedSignal("plotCapacity"):Connect(function(val)
				setPlotCapacity(val)
			end),
			networker:getServerChangedSignal("prestigeLevel"):Connect(function(val)
				setPrestigeLevel(val)
			end),
			networker:getServerChangedSignal("totalEarnings"):Connect(function(val)
				setTotalEarnings(val)
			end),
		}
		return function()
			for _, conn in connections do
				conn:Disconnect()
			end
		end
	end, {})

	if not props.visible then
		return nil
	end

	local speedCost = GameConfig.getPlayerUpgradePrice(GameConfig.SPEED_BASE_PRICE, speedLevel)
	local carryCost = GameConfig.getPlayerUpgradePrice(GameConfig.CARRY_BASE_PRICE, carryCapacity - 2)
	local plotCost = GameConfig.getPlayerUpgradePrice(GameConfig.PLOT_CAPACITY_BASE_PRICE, plotCapacity - 4)

	local canPrestige = GameConfig.canPrestige({
		TotalEarnings = totalEarnings,
		SpeedLevel = speedLevel,
		PrestigeLevel = prestigeLevel,
	})
	local nextReq = GameConfig.getPrestigeRequirements(prestigeLevel + 1)

	return React.createElement("Frame", {
		Size = UDim2.fromScale(0.25, 0.55),
		Position = UDim2.fromScale(0.375, 0.22),
		BackgroundColor3 = Color3.fromRGB(20, 20, 30),
		BackgroundTransparency = 0.1,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
		}),
		Layout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
		Title = React.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = "UPGRADES",
			TextColor3 = Color3.fromRGB(255, 220, 50),
			TextScaled = true,
			FontFace = FONT,
			LayoutOrder = 0,
		}),
		Speed = React.createElement(UpgradeCard, {
			title = "Speed",
			level = speedLevel,
			maxLevel = GameConfig.SPEED_MAX_LEVEL,
			cost = speedCost,
			coins = coins,
			order = 1,
			onBuy = function()
				upgradeClient:buySpeed()
			end,
		}),
		Carry = React.createElement(UpgradeCard, {
			title = "Carry Capacity",
			level = carryCapacity,
			maxLevel = GameConfig.CARRY_MAX_LEVEL,
			cost = carryCost,
			coins = coins,
			order = 2,
			onBuy = function()
				upgradeClient:buyCarryCapacity()
			end,
		}),
		PlotCap = React.createElement(UpgradeCard, {
			title = "Plot Capacity",
			level = plotCapacity,
			maxLevel = GameConfig.PLOT_CAPACITY_MAX_LEVEL,
			cost = plotCost,
			coins = coins,
			order = 3,
			onBuy = function()
				upgradeClient:buyPlotCapacity()
			end,
		}),
		PrestigeSection = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 80),
			BackgroundColor3 = if canPrestige then Color3.fromRGB(50, 20, 70) else Color3.fromRGB(30, 30, 35),
			LayoutOrder = 10,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
			}),
			Label = React.createElement("TextLabel", {
				Size = UDim2.new(0.6, 0, 0.35, 0),
				BackgroundTransparency = 1,
				Text = "PRESTIGE Lv." .. prestigeLevel,
				TextColor3 = Color3.fromRGB(200, 150, 255),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = FONT,
			}),
			Req = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0.35, 0),
				Position = UDim2.fromScale(0, 0.35),
				BackgroundTransparency = 1,
				Text = if nextReq
					then "Need: " .. formatNumber(nextReq.totalEarnings) .. " earned, Speed Lv." .. nextReq.speedLevel
					else "MAX PRESTIGE",
				TextColor3 = Color3.fromRGB(150, 150, 150),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = FONT_MEDIUM,
			}),
			PrestigeBtn = React.createElement("TextButton", {
				Size = UDim2.new(0.35, 0, 0.5, 0),
				Position = UDim2.fromScale(0.65, 0.4),
				BackgroundColor3 = if canPrestige then Color3.fromRGB(150, 50, 255) else Color3.fromRGB(60, 60, 60),
				Text = "PRESTIGE",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				FontFace = FONT,
				[React.Event.Activated] = if canPrestige
					then function()
						upgradeClient:prestige()
					end
					else nil,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
			}),
		}),
	})
end

return ShopApp
