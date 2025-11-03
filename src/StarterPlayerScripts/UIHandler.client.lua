-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Dependencies
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

-- Context
local UIContextProvider = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).UIContextProvider

-- UI Components
local OutfitViewer = require(StarterPlayer.StarterPlayerScripts.Source.UI.OutfitViewer)
local LeftButtons = require(StarterPlayer.StarterPlayerScripts.Source.UI.LeftButtons)

-- Variables
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui", PlayerGui)
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 1
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local root = ReactRoblox.createRoot(screenGui)

local function AppRouter()
	return React.createElement(UIContextProvider, {}, {
		React.createElement(OutfitViewer),
		React.createElement(LeftButtons),
	})
end

root:render(React.createElement(AppRouter))
