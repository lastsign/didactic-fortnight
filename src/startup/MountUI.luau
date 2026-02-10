local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local HudApp = require(ReplicatedStorage.Source.Features.Hud.HudApp)

local MountUI = {}

function MountUI.init(self: typeof(MountUI), playerDataClient: any)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local root = ReactRoblox.createRoot(screenGui)
	root:render(React.createElement(HudApp, { playerDataClient = playerDataClient }))
end

return MountUI
