local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local Billboard = {}
Billboard.__index = Billboard

export type Config = {
	part: BasePart,
	face: Enum.NormalId?,
	name: string?,
	pixelsPerStud: number?,
}

function Billboard.new(config: Config): Billboard
	local self = setmetatable({}, Billboard)

	local gui = Instance.new("SurfaceGui")
	gui.Name = config.name or "Billboard"
	gui.Face = config.face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = config.pixelsPerStud or 50
	gui.Parent = config.part

	self.gui = gui
	self.part = config.part
	self.root = ReactRoblox.createRoot(gui)

	return self
end

function Billboard.render(self: Billboard, element: React.ReactNode)
	self.root:render(element)
end

function Billboard.getGui(self: Billboard): SurfaceGui
	return self.gui
end

function Billboard.destroy(self: Billboard)
	self.root:unmount()
	self.gui:Destroy()
end

export type Billboard = typeof(setmetatable({} :: {
	gui: SurfaceGui,
	part: BasePart,
	root: any,
}, Billboard))

return Billboard
