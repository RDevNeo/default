-- Services
local ServerStorage = game:GetService("ServerStorage")

-- Variables
local Instances: { Instance } = ServerStorage:FindFirstChild("Colors"):FindFirstChild("UI"):GetDescendants()

return Instances
