local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Signal = require(ServerScriptService.Source.CommsInit.Module)
local Colors = require(ServerStorage.Source.Colors)

for index, instance in pairs(Colors) do
	if instance:IsA("Color3Value") then
		local new = instance:Clone()
		new.Name = instance.Name
		new.Value = instance.Value
		new.Parent = ReplicatedStorage.Colors
	end
end

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(char)
		if char then
			print("Player loaded")
			Signal.PlayerEntered:Fire(player)
		end
	end)
end)
