local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)
local UITheme = require(ReplicatedStorage.Source.Core.UITheme)

local Colors = UITheme.Colors
local Fonts = UITheme.Font
local fmt = UITheme.formatNumber

-- ─── iOS-style rounded corner radius ───────────────────
local PANEL_RADIUS = UDim.new(0, 18)
local CARD_RADIUS = UDim.new(0, 14)
local BTN_RADIUS = UDim.new(0, 12)
local SMALL_RADIUS = UDim.new(0, 8)

-- ─── Tab Button ────────────────────────────────────────
local function TabButton(props: {
	text: string,
	active: boolean,
	activeColor: Color3,
	order: number,
	onPress: () -> (),
})
	return React.createElement("TextButton", {
		Size = UDim2.fromScale(0.48, 1),
		BackgroundColor3 = if props.active then props.activeColor else Colors.BgCard,
		BackgroundTransparency = if props.active then 0 else 0.3,
		Text = props.text,
		TextColor3 = if props.active then Colors.BgDark else Colors.TextMuted,
		TextScaled = true,
		FontFace = if props.active then Fonts.Heavy else Fonts.SemiBold,
		LayoutOrder = props.order,
		[React.Event.Activated] = props.onPress,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = BTN_RADIUS }),
		Padding = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 2),
		}),
	})
end

-- ─── Upgrade Card ──────────────────────────────────────
local function UpgradeCard(props: {
	icon: string,
	title: string,
	level: number,
	maxLevel: number,
	cost: number,
	coins: number,
	accentColor: Color3,
	order: number,
	onBuy: () -> (),
})
	local isMaxed = props.level >= props.maxLevel
	local canAfford = props.coins >= props.cost
	local progress = props.level / props.maxLevel

	local btnColor = if isMaxed
		then Colors.TextMuted
		elseif canAfford then Colors.Green
		else Colors.RedDark

	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = Colors.BgCard,
		BackgroundTransparency = 0.05,
		LayoutOrder = props.order,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = CARD_RADIUS }),
		Stroke = React.createElement("UIStroke", {
			Color = props.accentColor,
			Thickness = 1,
			Transparency = 0.75,
		}),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),

		-- Icon
		Icon = React.createElement("TextLabel", {
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.new(0, 0, 0, 2),
			BackgroundTransparency = 1,
			Text = props.icon,
			TextScaled = true,
		}),

		-- Title + Level
		Title = React.createElement("TextLabel", {
			Size = UDim2.new(0.45, 0, 0, 14),
			Position = UDim2.new(0, 30, 0, 0),
			BackgroundTransparency = 1,
			Text = props.title,
			TextColor3 = Colors.TextPrimary,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Fonts.SemiBold,
		}),
		Level = React.createElement("TextLabel", {
			Size = UDim2.new(0.3, 0, 0, 11),
			Position = UDim2.new(0, 30, 0, 16),
			BackgroundTransparency = 1,
			Text = "Lv." .. props.level .. "/" .. props.maxLevel,
			TextColor3 = Colors.TextSecondary,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Fonts.Medium,
		}),

		-- Progress bar
		ProgressBg = React.createElement("Frame", {
			Size = UDim2.new(0.5, 0, 0, 4),
			Position = UDim2.new(0, 30, 0, 32),
			BackgroundColor3 = Color3.fromRGB(30, 30, 50),
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Fill = React.createElement("Frame", {
				Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1),
				BackgroundColor3 = props.accentColor,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
			}),
		}),

		-- Buy button
		BuyButton = React.createElement("TextButton", {
			Size = UDim2.new(0.3, 0, 0, 28),
			Position = UDim2.new(0.7, 0, 0.5, -14),
			AnchorPoint = Vector2.new(0, 0),
			BackgroundColor3 = btnColor,
			Text = if isMaxed then "MAX" else fmt(props.cost),
			TextColor3 = Colors.TextPrimary,
			TextScaled = true,
			FontFace = Fonts.Bold,
			AutoButtonColor = not isMaxed and canAfford,
			[React.Event.Activated] = if isMaxed then nil else props.onBuy,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = SMALL_RADIUS }),
			Padding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 2),
				PaddingBottom = UDim.new(0, 2),
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
			}),
		}),
	})
end

-- ─── Sell Card ─────────────────────────────────────────
local function SellCard(props: {
	brainrot: GameConfig.Brainrot,
	sellPrice: number,
	order: number,
	onSell: () -> (),
})
	local rarityColor = UITheme.getRarityColor(props.brainrot.rarity)

	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = Colors.BgCard,
		BackgroundTransparency = 0.05,
		LayoutOrder = props.order,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = CARD_RADIUS }),
		Stroke = React.createElement("UIStroke", {
			Color = rarityColor,
			Thickness = 1,
			Transparency = 0.6,
		}),
		-- Left accent bar
		AccentBar = React.createElement("Frame", {
			Size = UDim2.new(0, 3, 0.6, 0),
			Position = UDim2.new(0, 6, 0.2, 0),
			BackgroundColor3 = rarityColor,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
		}),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}),
		Name = React.createElement("TextLabel", {
			Size = UDim2.new(0.5, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = props.brainrot.name,
			TextColor3 = rarityColor,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Fonts.SemiBold,
		}),
		Info = React.createElement("TextLabel", {
			Size = UDim2.new(0.5, 0, 0, 11),
			Position = UDim2.new(0, 0, 0, 18),
			BackgroundTransparency = 1,
			Text = props.brainrot.rarity .. "  +" .. props.brainrot.incomePerSec .. "/s",
			TextColor3 = Colors.TextMuted,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Fonts.Medium,
		}),
		SellButton = React.createElement("TextButton", {
			Size = UDim2.new(0.28, 0, 0, 26),
			Position = UDim2.new(0.72, 0, 0.5, -13),
			BackgroundColor3 = Colors.Orange,
			Text = fmt(props.sellPrice),
			TextColor3 = Colors.TextPrimary,
			TextScaled = true,
			FontFace = Fonts.Bold,
			[React.Event.Activated] = props.onSell,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = SMALL_RADIUS }),
			Padding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 2),
				PaddingBottom = UDim.new(0, 2),
			}),
		}),
	})
end

-- ─── Prestige Section ──────────────────────────────────
local function PrestigeSection(props: {
	prestigeLevel: number,
	canPrestige: boolean,
	nextReq: { totalEarnings: number, speedLevel: number }?,
	totalEarnings: number,
	speedLevel: number,
	order: number,
	onPrestige: () -> (),
})
	local ep, sp = 0, 0
	if props.nextReq then
		ep = math.clamp(props.totalEarnings / props.nextReq.totalEarnings, 0, 1)
		sp = math.clamp(props.speedLevel / props.nextReq.speedLevel, 0, 1)
	end

	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 88),
		BackgroundColor3 = if props.canPrestige then Color3.fromRGB(35, 15, 55) else Colors.BgCard,
		BackgroundTransparency = 0.05,
		LayoutOrder = props.order,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = CARD_RADIUS }),
		Stroke = React.createElement("UIStroke", {
			Color = if props.canPrestige then Colors.PurpleGlow else Colors.Border,
			Thickness = if props.canPrestige then 1.5 else 1,
			Transparency = if props.canPrestige then 0.3 else 0.6,
		}),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}),
		Title = React.createElement("TextLabel", {
			Size = UDim2.new(0.6, 0, 0, 14),
			BackgroundTransparency = 1,
			Text = "\xE2\xAD\x90 PRESTIGE Lv." .. props.prestigeLevel,
			TextColor3 = Colors.PurpleGlow,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Fonts.Heavy,
		}),

		-- Earnings bar
		ELabel = React.createElement("TextLabel", {
			Size = UDim2.new(0.6, 0, 0, 10),
			Position = UDim2.new(0, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = if props.nextReq then fmt(props.totalEarnings) .. "/" .. fmt(props.nextReq.totalEarnings) else "MAX",
			TextColor3 = Colors.TextMuted,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Fonts.Medium,
		}),
		EBar = React.createElement("Frame", {
			Size = UDim2.new(0.58, 0, 0, 4),
			Position = UDim2.new(0, 0, 0, 32),
			BackgroundColor3 = Color3.fromRGB(30, 30, 50),
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Fill = React.createElement("Frame", {
				Size = UDim2.fromScale(ep, 1),
				BackgroundColor3 = Colors.Purple,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
			}),
		}),

		-- Speed bar
		SLabel = React.createElement("TextLabel", {
			Size = UDim2.new(0.6, 0, 0, 10),
			Position = UDim2.new(0, 0, 0, 40),
			BackgroundTransparency = 1,
			Text = if props.nextReq then "Speed " .. props.speedLevel .. "/" .. props.nextReq.speedLevel else "",
			TextColor3 = Colors.TextMuted,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Fonts.Medium,
		}),
		SBar = React.createElement("Frame", {
			Size = UDim2.new(0.58, 0, 0, 4),
			Position = UDim2.new(0, 0, 0, 52),
			BackgroundColor3 = Color3.fromRGB(30, 30, 50),
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Fill = React.createElement("Frame", {
				Size = UDim2.fromScale(sp, 1),
				BackgroundColor3 = Colors.Purple,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
			}),
		}),

		-- Button
		Btn = React.createElement("TextButton", {
			Size = UDim2.new(0.32, 0, 0, 30),
			Position = UDim2.new(0.68, 0, 0.5, -8),
			BackgroundColor3 = if props.canPrestige then Colors.Purple else Colors.TextMuted,
			Text = "PRESTIGE",
			TextColor3 = Colors.TextPrimary,
			TextScaled = true,
			FontFace = Fonts.Heavy,
			AutoButtonColor = props.canPrestige,
			[React.Event.Activated] = if props.canPrestige then props.onPrestige else nil,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = SMALL_RADIUS }),
			Padding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 2),
				PaddingBottom = UDim.new(0, 2),
			}),
			Stroke = if props.canPrestige then React.createElement("UIStroke", {
				Color = Colors.PurpleGlow,
				Thickness = 1.5,
				Transparency = 0.4,
			}) else nil,
		}),
	})
end

-- ─── Main Shop ─────────────────────────────────────────

export type Props = {
	playerDataClient: any,
	upgradeClient: any,
	visible: boolean,
	onClose: (() -> ())?,
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
	local carryInventory, setCarryInventory = React.useState(pdClient.carryInventory or {})
	local activeTab, setActiveTab = React.useState("upgrades")

	React.useEffect(function()
		local networker = pdClient.networker
		local connections = {
			networker:getServerChangedSignal("coins"):Connect(function(val) setCoins(val) end),
			networker:getServerChangedSignal("speedLevel"):Connect(function(val) setSpeedLevel(val) end),
			networker:getServerChangedSignal("carryCapacity"):Connect(function(val) setCarryCapacity(val) end),
			networker:getServerChangedSignal("plotCapacity"):Connect(function(val) setPlotCapacity(val) end),
			networker:getServerChangedSignal("prestigeLevel"):Connect(function(val) setPrestigeLevel(val) end),
			networker:getServerChangedSignal("totalEarnings"):Connect(function(val) setTotalEarnings(val) end),
			networker:getServerChangedSignal("carryInventory"):Connect(function(val) setCarryInventory(val) end),
		}
		return function()
			for _, conn in connections do conn:Disconnect() end
		end
	end, {})

	if not props.visible then
		return nil
	end

	-- Build tab content
	local scrollContent = {}

	if activeTab == "upgrades" then
		local speedCost = GameConfig.getPlayerUpgradePrice(GameConfig.SPEED_BASE_PRICE, speedLevel)
		local carryCost = GameConfig.getPlayerUpgradePrice(GameConfig.CARRY_BASE_PRICE, carryCapacity - 2)
		local plotCost = GameConfig.getPlayerUpgradePrice(GameConfig.PLOT_CAPACITY_BASE_PRICE, plotCapacity - 4)

		local canPrestige = GameConfig.canPrestige({
			TotalEarnings = totalEarnings,
			SpeedLevel = speedLevel,
			PrestigeLevel = prestigeLevel,
		})
		local nextReq = GameConfig.getPrestigeRequirements(prestigeLevel + 1)

		scrollContent.Speed = React.createElement(UpgradeCard, {
			icon = "\xE2\x9A\xA1", title = "Speed", level = speedLevel,
			maxLevel = GameConfig.SPEED_MAX_LEVEL, cost = speedCost, coins = coins,
			accentColor = Colors.Accent, order = 1,
			onBuy = function() upgradeClient:buySpeed() end,
		})
		scrollContent.Carry = React.createElement(UpgradeCard, {
			icon = "\xF0\x9F\x8E\x92", title = "Carry", level = carryCapacity,
			maxLevel = GameConfig.CARRY_MAX_LEVEL, cost = carryCost, coins = coins,
			accentColor = Colors.Green, order = 2,
			onBuy = function() upgradeClient:buyCarryCapacity() end,
		})
		scrollContent.PlotCap = React.createElement(UpgradeCard, {
			icon = "\xF0\x9F\x8F\xA0", title = "Plot", level = plotCapacity,
			maxLevel = GameConfig.PLOT_CAPACITY_MAX_LEVEL, cost = plotCost, coins = coins,
			accentColor = Colors.Rare, order = 3,
			onBuy = function() upgradeClient:buyPlotCapacity() end,
		})
		scrollContent.Prestige = React.createElement(PrestigeSection, {
			prestigeLevel = prestigeLevel, canPrestige = canPrestige, nextReq = nextReq,
			totalEarnings = totalEarnings, speedLevel = speedLevel, order = 5,
			onPrestige = function() upgradeClient:prestige() end,
		})
	else
		local totalSellValue = 0
		for i, brainrotId in carryInventory do
			local brainrot = GameConfig.getBrainrot(brainrotId)
			if brainrot then
				local sellPrice = GameConfig.getSellPrice(brainrotId, 1)
				totalSellValue += sellPrice
				local ci = i
				scrollContent["C_" .. i] = React.createElement(SellCard, {
					brainrot = brainrot, sellPrice = sellPrice, order = i,
					onSell = function() upgradeClient:sellCarryBrainrot(ci) end,
				})
			end
		end
		if #carryInventory == 0 then
			scrollContent.Empty = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 60),
				BackgroundTransparency = 1,
				Text = "Pick up brainrots to sell them",
				TextColor3 = Colors.TextMuted,
				TextScaled = true,
				FontFace = Fonts.Medium,
				LayoutOrder = 1,
			})
		else
			scrollContent.SellAll = React.createElement("TextButton", {
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundColor3 = Colors.Red,
				Text = "SELL ALL  " .. fmt(totalSellValue),
				TextColor3 = Colors.TextPrimary,
				TextScaled = true,
				FontFace = Fonts.Heavy,
				LayoutOrder = 200,
				[React.Event.Activated] = function() upgradeClient:sellAllCarry() end,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = SMALL_RADIUS }),
			})
		end
	end

	-- Panel: 85% width (max 360px), 70% height (max 460px), centered
	return React.createElement(React.Fragment, nil, {
		-- Dim overlay
		Overlay = React.createElement("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Colors.BgOverlay,
			BackgroundTransparency = 0.35,
			Text = "",
			ZIndex = 10,
			[React.Event.Activated] = props.onClose,
		}),

		-- Shop panel
		Panel = React.createElement("Frame", {
			Size = UDim2.fromScale(0.85, 0.7),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Colors.BgPanel,
			BackgroundTransparency = 0.02,
			ZIndex = 11,
		}, {
			SizeConstraint = React.createElement("UISizeConstraint", {
				MaxSize = Vector2.new(360, 460),
				MinSize = Vector2.new(200, 240),
			}),
			Corner = React.createElement("UICorner", { CornerRadius = PANEL_RADIUS }),
			Stroke = React.createElement("UIStroke", {
				Color = Colors.BorderLight,
				Thickness = 1.5,
				Transparency = 0.35,
			}),
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
			}),

			-- Header row
			Header = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundTransparency = 1,
			}, {
				Title = React.createElement("TextLabel", {
					Size = UDim2.new(0.5, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "SHOP",
					TextColor3 = Colors.Accent,
					TextStrokeColor3 = Color3.new(0, 0, 0),
					TextStrokeTransparency = 0.6,
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					FontFace = Fonts.Heavy,
				}),
				Coins = React.createElement("TextLabel", {
					Size = UDim2.new(0.35, 0, 0.8, 0),
					Position = UDim2.fromScale(0.5, 0.1),
					BackgroundTransparency = 1,
					Text = "\xF0\x9F\xAA\x99 " .. fmt(coins),
					TextColor3 = Colors.TextGold,
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Right,
					FontFace = Fonts.Bold,
				}),
				CloseBtn = React.createElement("TextButton", {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, 0, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundColor3 = Colors.RedDark,
					BackgroundTransparency = 0.2,
					Text = "X",
					TextColor3 = Colors.TextPrimary,
					TextScaled = true,
					FontFace = Fonts.Bold,
					[React.Event.Activated] = props.onClose,
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
				}),
			}),

			-- Tabs
			TabBar = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 26),
				Position = UDim2.new(0, 0, 0, 34),
				BackgroundTransparency = 1,
			}, {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
				Upgrades = React.createElement(TabButton, {
					text = "UPGRADES", active = activeTab == "upgrades",
					activeColor = Colors.Accent, order = 1,
					onPress = function() setActiveTab("upgrades") end,
				}),
				Sell = React.createElement(TabButton, {
					text = "SELL", active = activeTab == "sell",
					activeColor = Colors.Orange, order = 2,
					onPress = function() setActiveTab("sell") end,
				}),
			}),

			-- Scrollable content
			Content = React.createElement("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -68),
				Position = UDim2.new(0, 0, 0, 66),
				BackgroundTransparency = 1,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = Colors.Border,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				BorderSizePixel = 0,
			}, {
				Layout = React.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
				}),
				Items = React.createElement(React.Fragment, nil, scrollContent),
			}),
		}),
	})
end

return ShopApp
