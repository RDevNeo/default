local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Signals = require(ReplicatedStorage.Packages.Signal)

local serverComm = Comm.ServerComm.new(ReplicatedStorage)

local signals = {
	-- Outfit
	OpenOutfit = serverComm:CreateSignal("OpenOutfit"),
	BuyOutfit = serverComm:CreateSignal("BuyOutfit"),
	WearOutfit = serverComm:CreateSignal("WearOutfit"),

	-- Accessory
	BuyAccessory = serverComm:CreateSignal("buyAccessory"),
	AddToCart = serverComm:CreateSignal("AddToCart"),
	TryAccessory = serverComm:CreateSignal("TryAccessory"),
	LikeAccessory = serverComm:CreateSignal("LikeAccessory"),

	-- DataStore
	DataManagerLoaded = Signals.new(),

	-- Player
	PlayerEntered = serverComm:CreateSignal("PlayerEntered"),
}

return signals
