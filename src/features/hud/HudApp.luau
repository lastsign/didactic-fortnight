local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local ShopApp = require(ReplicatedStorage.Source.Features.Upgrade.ShopApp)
local CataclysmWarning = require(ReplicatedStorage.Source.Features.Cataclysm.CataclysmWarning)
local UITheme = require(ReplicatedStorage.Source.Core.UITheme)

local Colors = UITheme.Colors
local Fonts = UITheme.Font
local fmt = UITheme.formatNumber

-- ─── Compact stat row (icon + value only, no label) ────
local function StatRow(props: {
	icon: string,
	value: string,
	accentColor: Color3?,
	order: number,
})
	local color = props.accentColor or Colors.TextPrimary

	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = Colors.BgCard,
		BackgroundTransparency = 0.2,
		LayoutOrder = props.order,
	}, {
		Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Stroke = React.createElement("UIStroke", {
			Color = color,
			Thickness = 1,
			Transparency = 0.8,
		}),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
		}),
		Icon = React.createElement("TextLabel", {
			Size = UDim2.new(0, 16, 1, 0),
			BackgroundTransparency = 1,
			Text = props.icon,
			TextScaled = true,
		}),
		Value = React.createElement("TextLabel", {
			Size = UDim2.new(1, -20, 1, 0),
			Position = UDim2.new(0, 20, 0, 0),
			BackgroundTransparency = 1,
			Text = props.value,
			TextColor3 = color,
			TextStrokeColor3 = Color3.new(0, 0, 0),
			TextStrokeTransparency = 0.7,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Right,
			FontFace = Fonts.Bold,
		}),
	})
end

-- ─── Main HUD ──────────────────────────────────────────

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
			networker:getServerChangedSignal("coins"):Connect(function(val) setCoins(val) end),
			networker:getServerChangedSignal("carryCount"):Connect(function(val) setCarryCount(val) end),
			networker:getServerChangedSignal("carryCapacity"):Connect(function(val) setCarryCapacity(val) end),
			networker:getServerChangedSignal("inventoryCount"):Connect(function(val) setInventoryCount(val) end),
			networker:getServerChangedSignal("plotCapacity"):Connect(function(val) setPlotCapacity(val) end),
			networker:getServerChangedSignal("incomePerSec"):Connect(function(val) setIncomePerSec(val) end),
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
		-- Stats panel — scale-based, bottom-left to avoid Roblox top-left buttons
		StatsPanel = React.createElement("Frame", {
			-- 15% width on any screen, clamped between 110-200px
			Size = UDim2.fromScale(0.15, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Position = UDim2.new(0, 6, 1, -6),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = Colors.BgPanel,
			BackgroundTransparency = 0.12,
		}, {
			SizeConstraint = React.createElement("UISizeConstraint", {
				MinSize = Vector2.new(110, 0),
				MaxSize = Vector2.new(200, 400),
			}),
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
			Stroke = React.createElement("UIStroke", {
				Color = Colors.Border,
				Thickness = 1,
				Transparency = 0.5,
			}),
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
			}),
			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),

			-- Coin display (compact)
			Coins = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundColor3 = Colors.BgCard,
				BackgroundTransparency = 0.1,
				LayoutOrder = 1,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Stroke = React.createElement("UIStroke", {
					Color = Colors.Accent,
					Thickness = 1,
					Transparency = 0.5,
				}),
				Gradient = React.createElement("UIGradient", {
					Color = ColorSequence.new(
						Color3.fromRGB(40, 35, 15),
						Colors.BgCard
					),
					Rotation = 0,
				}),
				Padding = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
				}),
				Icon = React.createElement("TextLabel", {
					Size = UDim2.new(0, 18, 1, 0),
					BackgroundTransparency = 1,
					Text = "\xF0\x9F\xAA\x99",
					TextScaled = true,
				}),
				Amount = React.createElement("TextLabel", {
					Size = UDim2.new(1, -22, 1, 0),
					Position = UDim2.new(0, 22, 0, 0),
					BackgroundTransparency = 1,
					Text = fmt(coins),
					TextColor3 = Colors.TextGold,
					TextStrokeColor3 = Color3.new(0, 0, 0),
					TextStrokeTransparency = 0.6,
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Right,
					FontFace = Fonts.Heavy,
				}),
			}),

			-- Carry
			Carry = React.createElement(StatRow, {
				icon = "\xF0\x9F\x8E\x92",
				value = carryCount .. "/" .. carryCapacity,
				accentColor = if carryCount >= carryCapacity then Colors.Red else Colors.Green,
				order = 2,
			}),
			-- Base
			Plot = React.createElement(StatRow, {
				icon = "\xF0\x9F\x93\xA6",
				value = inventoryCount .. "/" .. plotCapacity,
				accentColor = if inventoryCount >= plotCapacity then Colors.Red else Colors.TextPrimary,
				order = 3,
			}),
			-- Income
			Income = React.createElement(StatRow, {
				icon = "\xF0\x9F\x92\xB8",
				value = "+" .. fmt(incomePerSec) .. "/s",
				accentColor = Colors.GreenGlow,
				order = 4,
			}),

			-- Shop button (compact)
			ShopBtn = React.createElement("TextButton", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = if shopOpen then Colors.PurpleDark else Colors.Purple,
				Text = if shopOpen then "CLOSE" else "SHOP",
				TextColor3 = Colors.TextPrimary,
				TextScaled = true,
				FontFace = Fonts.Bold,
				LayoutOrder = 5,
				[React.Event.Activated] = function()
					setShopOpen(function(prev) return not prev end)
				end,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Stroke = React.createElement("UIStroke", {
					Color = Colors.PurpleGlow,
					Thickness = 1,
					Transparency = 0.6,
				}),
			}),
		}),

		-- Shop overlay
		ShopOverlay = React.createElement(ShopApp, {
			playerDataClient = client,
			upgradeClient = props.upgradeClient,
			visible = shopOpen,
			onClose = function() setShopOpen(false) end,
		}),

		-- Cataclysm warning
		Cataclysm = React.createElement(CataclysmWarning, {
			cataclysmClient = props.cataclysmClient,
		}),
	})
end

return HudApp
