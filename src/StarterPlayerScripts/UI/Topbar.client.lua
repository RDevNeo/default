-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local Topbar = require(ReplicatedStorage.Packages.TopBarPlus)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

-- Variables
local player = Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MyReactUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local root = ReactRoblox.createRoot(screenGui)

local TeleportIcon = Topbar.new()
TeleportIcon:setLabel("Teleports")
TeleportIcon:setName("Teleport")

local function App()
	return React.createElement("Frame", {
		Size = UDim2.fromScale(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
	})
end

local function toggleUI(bool: boolean)
	if bool then
		root:render(React.createElement(App))
	else
		root:render()
	end
end

TeleportIcon:bindEvent("selected", function(selfIcon)
	toggleUI(true)
end)

TeleportIcon:bindEvent("deselected", function(selfIcon)
	toggleUI(false)
end)
