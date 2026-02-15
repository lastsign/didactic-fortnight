--[[
	UITheme — shared design system for all UI components.
	All sizing uses Scale-based UDim2 for mobile responsiveness.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UITheme = {}

-- ─── Fonts ──────────────────────────────────────────────
UITheme.Font = {
	Bold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
	SemiBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
	Medium = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
	Regular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
	Heavy = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy),
}

-- ─── Color Palette (dark cyber/neon theme) ──────────────
UITheme.Colors = {
	BgDark = Color3.fromRGB(12, 12, 20),
	BgPanel = Color3.fromRGB(18, 18, 32),
	BgCard = Color3.fromRGB(25, 25, 42),
	BgOverlay = Color3.fromRGB(0, 0, 0),

	Accent = Color3.fromRGB(255, 210, 50),
	AccentDark = Color3.fromRGB(200, 160, 20),

	Purple = Color3.fromRGB(140, 80, 255),
	PurpleDark = Color3.fromRGB(90, 40, 180),
	PurpleGlow = Color3.fromRGB(180, 120, 255),

	Green = Color3.fromRGB(40, 200, 100),
	GreenDark = Color3.fromRGB(20, 140, 60),
	GreenGlow = Color3.fromRGB(80, 255, 140),

	Red = Color3.fromRGB(230, 60, 50),
	RedDark = Color3.fromRGB(160, 30, 20),
	RedGlow = Color3.fromRGB(255, 100, 90),

	Orange = Color3.fromRGB(240, 140, 30),
	OrangeDark = Color3.fromRGB(180, 90, 10),

	TextPrimary = Color3.fromRGB(240, 240, 255),
	TextSecondary = Color3.fromRGB(160, 160, 185),
	TextMuted = Color3.fromRGB(100, 100, 130),
	TextGold = Color3.fromRGB(255, 220, 80),

	Border = Color3.fromRGB(50, 50, 80),
	BorderLight = Color3.fromRGB(70, 70, 110),

	Common = Color3.fromRGB(180, 180, 190),
	Uncommon = Color3.fromRGB(50, 220, 80),
	Rare = Color3.fromRGB(50, 140, 255),
	Epic = Color3.fromRGB(170, 60, 255),
	Legendary = Color3.fromRGB(255, 190, 30),
	Mythic = Color3.fromRGB(255, 50, 80),

	CatWarn = Color3.fromRGB(200, 40, 20),
	CatFreeze = Color3.fromRGB(30, 80, 200),
	CatDark = Color3.fromRGB(40, 10, 60),
	CatBlackHole = Color3.fromRGB(80, 20, 140),
}

-- ─── Helpers ────────────────────────────────────────────

function UITheme.formatNumber(n: number): string
	if n >= 1_000_000_000 then
		return string.format("%.1fB", n / 1_000_000_000)
	elseif n >= 1_000_000 then
		return string.format("%.1fM", n / 1_000_000)
	elseif n >= 1_000 then
		return string.format("%.1fK", n / 1_000)
	end
	return tostring(math.floor(n))
end

function UITheme.getRarityColor(rarity: string): Color3
	return UITheme.Colors[rarity] or UITheme.Colors.Common
end

return UITheme
