local Players = game:GetService("Players")

local SpawnServiceServer = {}

function SpawnServiceServer.init(self: SpawnServiceServer)
	Players.CharacterAutoLoads = false
end

export type SpawnServiceServer = typeof(SpawnServiceServer)

return SpawnServiceServer
