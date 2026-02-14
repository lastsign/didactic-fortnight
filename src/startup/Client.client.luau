local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataServiceClient = require(ReplicatedStorage.Source.Features.Playerdata.PlayerDataServiceClient)
local BrainrotServiceClient = require(ReplicatedStorage.Source.Features.Brainrot.BrainrotServiceClient)
local UpgradeServiceClient = require(ReplicatedStorage.Source.Features.Upgrade.UpgradeServiceClient)
local CataclysmServiceClient = require(ReplicatedStorage.Source.Features.Cataclysm.CataclysmServiceClient)
local PvPServiceClient = require(ReplicatedStorage.Source.Features.Pvp.PvPServiceClient)
local MountUI = require(ReplicatedStorage.Source.StartUp.MountUI)

PlayerDataServiceClient:init()
BrainrotServiceClient:init() -- Анимация brainrot'ов + зона сдачи
UpgradeServiceClient:init()
CataclysmServiceClient:init()
PvPServiceClient:init()
MountUI:init(PlayerDataServiceClient, UpgradeServiceClient, CataclysmServiceClient)
