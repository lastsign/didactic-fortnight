local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataServiceClient = require(ReplicatedStorage.Source.Features.Playerdata.PlayerDataServiceClient)
local BrainrotServiceClient = require(ReplicatedStorage.Source.Features.Brainrot.BrainrotServiceClient)
local MountUI = require(ReplicatedStorage.Source.StartUp.MountUI)

PlayerDataServiceClient:init()
BrainrotServiceClient:init() -- Анимация brainrot'ов + зона сдачи
MountUI:init(PlayerDataServiceClient)
