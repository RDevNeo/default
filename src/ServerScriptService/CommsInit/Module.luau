local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)

local serverComm = Comm.ServerComm.new(ReplicatedStorage)

local signals = {
	-- Outfit
	OpenOutfit = serverComm:CreateSignal("OpenOutfit"),
	BuyOutfit = serverComm:CreateSignal("BuyOutfit"),
	WearOutfit = serverComm:CreateSignal("WearOutfit"),

	-- Accessory
	BuyAccessory = serverComm:CreateSignal("buyAccessory"),
	AddToCart = serverComm:CreateSignal("AddToCart"),
	WearAccessory = serverComm:CreateSignal("WearAccessory"),
	LikeAccessory = serverComm:CreateSignal("LikeAccessory"),
}

return signals
