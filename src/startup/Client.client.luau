local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataServiceClient = require(ReplicatedStorage.Source.Features.Playerdata.PlayerDataServiceClient)
local MountUI = require(ReplicatedStorage.Source.StartUp.MountUI)

PlayerDataServiceClient:init()
MountUI:init(PlayerDataServiceClient)
