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
local RightButtons = require(StarterPlayer.StarterPlayerScripts.Source.UI.RightButtons)
local SearchOutfit = require(StarterPlayer.StarterPlayerScripts.Source.UI.SearchOutfit)
local ShoppingCart = require(StarterPlayer.StarterPlayerScripts.Source.UI.ShoppingCart)
local LikedAccessories = require(StarterPlayer.StarterPlayerScripts.Source.UI.LikedAccessories)
local SaveToRoblox = require(StarterPlayer.StarterPlayerScripts.Source.UI.SaveToRoblox)
local SaveConfirm = require(StarterPlayer.StarterPlayerScripts.Source.UI.SaveConfirm)

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
		React.createElement(RightButtons),
		React.createElement(SearchOutfit),
		React.createElement(ShoppingCart),
		React.createElement(LikedAccessories),
		React.createElement(SaveToRoblox),
		React.createElement(SaveConfirm),
	})
end

root:render(React.createElement(AppRouter))
