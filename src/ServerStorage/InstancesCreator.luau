-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

-- Dependencies
local Colors = require(ServerStorage.Source.Colors)

-- Main
local module = {}

local CameraParts = Workspace:FindFirstChild("CameraParts")
if not CameraParts then
	warn("Created CameraParts in Workspace because none was found.")
	CameraParts = Instance.new("Folder", Workspace)
	CameraParts.Name = "CameraParts"
end

local BackgroundSound = ReplicatedStorage:FindFirstChild("BackgroundSound")
if not BackgroundSound then
	BackgroundSound = Instance.new("Sound")
	BackgroundSound.Parent = ReplicatedStorage
	BackgroundSound.Looped = true
	BackgroundSound.Playing = true
	BackgroundSound.Volume = 0.3
	BackgroundSound.Name = "BackgroundSound"
	warn("Created BackgroundSound in Replicated Storage because none was found.")
end

local ColorsFolder = ReplicatedStorage:FindFirstChild("Colors")
if not ColorsFolder then
	ColorsFolder = Instance.new("Folder")
	ColorsFolder.Parent = ReplicatedStorage
	ColorsFolder.Name = "Colors"
	warn("Created a copy of the Color folder in Replicated Storage.")
end

for index, instance in pairs(Colors) do
	if instance:IsA("Color3Value") then
		local new = instance:Clone()
		new.Name = instance.Name
		new.Value = instance.Value
		new.Parent = ColorsFolder
	end
end

local HoverSound = ReplicatedStorage:FindFirstChild("HoverSound")
if not HoverSound then
	HoverSound = Instance.new("Sound")
	HoverSound.Parent = ReplicatedStorage
	HoverSound.Name = "HoverSound"
	HoverSound.SoundId = "rbxassetid://139800881181209"
end

local playerModels = ReplicatedStorage:FindFirstChild("PlayerModels")
if not playerModels then
	playerModels = Instance.new("Folder")
	playerModels.Parent = ReplicatedStorage
	playerModels.Name = "playerModels"
end

return module
