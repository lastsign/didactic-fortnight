local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Networker = require(ReplicatedStorage.Packages.Networker)
local GameConfig = require(ReplicatedStorage.Source.Game.GameConfig)
local PlotServer = require(script.Parent.Parent.Plot.PlotServer)

local PvPServiceServer = {}
PvPServiceServer.networker = (nil :: any) :: Networker.Server
PvPServiceServer._cooldowns = {} :: { [string]: number } -- "attackerId_targetId" → timestamp

function PvPServiceServer.init(self: PvPServiceServer)
	self.networker = Networker.server.new("PvPService", self, {})
	self._cooldowns = {}

	task.spawn(function()
		self:_mainLoop()
	end)
end

function PvPServiceServer._mainLoop(self: PvPServiceServer)
	while true do
		task.wait(0.2)
		self:_checkCollisions()
	end
end

function PvPServiceServer._checkCollisions(self: PvPServiceServer)
	local players = Players:GetPlayers()
	local now = os.clock()

	for i = 1, #players do
		for j = i + 1, #players do
			local p1 = players[i]
			local p2 = players[j]
			self:_checkPair(p1, p2, now)
		end
	end
end

function PvPServiceServer._checkPair(self: PvPServiceServer, p1: Player, p2: Player, now: number)
	local c1 = p1.Character
	local c2 = p2.Character
	if not c1 or not c2 then
		return
	end

	local root1 = c1.PrimaryPart
	local root2 = c2.PrimaryPart
	if not root1 or not root2 then
		return
	end

	local h1 = c1:FindFirstChildOfClass("Humanoid")
	local h2 = c2:FindFirstChildOfClass("Humanoid")
	if not h1 or not h2 or h1.Health <= 0 or h2.Health <= 0 then
		return
	end

	local dist = (root1.Position - root2.Position).Magnitude
	if dist > GameConfig.PVP_HIT_RADIUS then
		return
	end

	local vel1 = root1.AssemblyLinearVelocity.Magnitude
	local vel2 = root2.AssemblyLinearVelocity.Magnitude

	-- Determine attacker (faster player)
	if vel1 >= GameConfig.PVP_MIN_SPEED then
		self:_tryKnockback(p1, p2, root1, root2, h1, h2, vel1, vel2, now)
	end
	if vel2 >= GameConfig.PVP_MIN_SPEED then
		self:_tryKnockback(p2, p1, root2, root1, h2, h1, vel2, vel1, now)
	end
end

function PvPServiceServer._tryKnockback(
	self: PvPServiceServer,
	attacker: Player,
	target: Player,
	attackerRoot: BasePart,
	targetRoot: BasePart,
	_attackerHumanoid: Humanoid,
	targetHumanoid: Humanoid,
	attackerSpeed: number,
	targetSpeed: number,
	now: number
)
	-- Safe zone check
	if self:_isInSafeZone(target) then
		return
	end

	-- Spawn invulnerability
	local spawnTime = PlotServer.spawnTimes[target]
	if spawnTime and (now - spawnTime) < GameConfig.PVP_SPAWN_INVULNERABILITY then
		return
	end

	-- Cooldown check
	local cooldownKey = tostring(attacker.UserId) .. "_" .. tostring(target.UserId)
	local lastHit = self._cooldowns[cooldownKey]
	if lastHit and (now - lastHit) < GameConfig.PVP_COOLDOWN then
		return
	end

	-- Apply knockback
	self._cooldowns[cooldownKey] = now

	local force = GameConfig.getKnockbackForce(attackerSpeed, targetSpeed)
	local direction = (targetRoot.Position - attackerRoot.Position).Unit
	-- Add upward component
	direction = Vector3.new(direction.X, 0.3, direction.Z).Unit

	local bv = Instance.new("BodyVelocity")
	bv.Name = "PvPKnockback"
	bv.MaxForce = Vector3.new(force * 100, force * 50, force * 100)
	bv.Velocity = direction * force
	bv.Parent = targetRoot

	task.delay(0.3, function()
		if bv.Parent then
			bv:Destroy()
		end
	end)

	-- Ragdoll if strong enough
	if force >= GameConfig.PVP_RAGDOLL_THRESHOLD then
		self:_applyRagdoll(targetHumanoid, target)
	end

	-- Notify client
	self.networker:set(target, "hitReceived", now)
end

function PvPServiceServer._applyRagdoll(self: PvPServiceServer, humanoid: Humanoid, player: Player)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)

	self.networker:set(player, "ragdoll", true)

	task.delay(GameConfig.PVP_RAGDOLL_DURATION, function()
		if humanoid and humanoid.Parent and humanoid.Health > 0 then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			self.networker:set(player, "ragdoll", false)
		end
	end)
end

function PvPServiceServer._isInSafeZone(self: PvPServiceServer, player: Player): boolean
	local character = player.Character
	if not character or not character.PrimaryPart then
		return false
	end

	local pos = character.PrimaryPart.Position
	for _, part in CollectionService:GetTagged("PlotSpawn") do
		if (part.Position - pos).Magnitude <= GameConfig.PVP_SAFE_ZONE_RADIUS then
			return true
		end
	end
	return false
end

export type PvPServiceServer = typeof(PvPServiceServer)

return PvPServiceServer
