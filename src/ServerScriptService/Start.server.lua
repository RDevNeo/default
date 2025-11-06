local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Colors = require(ServerStorage.Source.Colors)
local _InstanceCreator = require(ServerStorage.Source.InstancesCreator)

local ColorsFolder = ReplicatedStorage:FindFirstChild("Colors")
if not ColorsFolder then
	ColorsFolder = Instance.new("Folder", ReplicatedStorage)
	ColorsFolder.Name = "Colors"
end

for index, instance in pairs(Colors) do
	if instance:IsA("Color3Value") then
		local new = instance:Clone()
		new.Name = instance.Name
		new.Value = instance.Value
		new.Parent = ColorsFolder
	end
end
