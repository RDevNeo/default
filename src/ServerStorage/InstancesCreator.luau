local Workspace = game:GetService("Workspace")
local module = {}

local CameraParts = Workspace:FindFirstChild("CameraParts")

if not CameraParts then
	warn("CameraParts not found in Workspace, script created it manually.")
	CameraParts = Instance.new("Folder", Workspace)
	CameraParts.Name = "CameraParts"
end

return module
