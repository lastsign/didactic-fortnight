local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networker = require(ReplicatedStorage.Packages.Networker)

local PvPServiceClient = {}
PvPServiceClient.networker = (nil :: any) :: Networker.Client

function PvPServiceClient.init(self: PvPServiceClient)
	self.networker = Networker.client.new("PvPService", self)

	self.networker:getServerChangedSignal("hitReceived"):Connect(function(_val)
		self:_showHitFlash()
	end)
end

function PvPServiceClient._showHitFlash(self: PvPServiceClient)
	local player = Players.LocalPlayer
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PvPHitFlash"
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 100

	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	flash.BackgroundTransparency = 0.5
	flash.BorderSizePixel = 0
	flash.Parent = screenGui

	screenGui.Parent = playerGui

	task.spawn(function()
		local steps = 6
		for i = 1, steps do
			flash.BackgroundTransparency = 0.5 + (0.5 * i / steps)
			task.wait(0.05)
		end
		screenGui:Destroy()
	end)
end

export type PvPServiceClient = typeof(PvPServiceClient)

return PvPServiceClient
