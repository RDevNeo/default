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
	RemoveToCart = serverComm:CreateSignal("RemoveToCart"),
	TakeOff = serverComm:CreateSignal("TakeOff"),

	-- DataStore
	DataManagerLoaded = Signals.new(),

	-- Player
	PlayerEntered = serverComm:CreateSignal("PlayerEntered"),
	OutfitCodeInputed = serverComm:CreateSignal("OutfitCodeInputed"),
	Warn = serverComm:CreateSignal("Warn"),

	-- Remote Functions (Global, created by Rojo)
	ProfileLoaded = serverComm:CreateSignal("ProfileLoaded"),
	GetCart = ReplicatedStorage.RF.GetCart,
}

return signals
