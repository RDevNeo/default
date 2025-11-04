-- ReplicatedStorage/SharedModules/CommClient.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)

local clientComm = Comm.ClientComm.new(ReplicatedStorage, false)

return {
	-- Outfit
	OpenOutfit = clientComm:GetSignal("OpenOutfit"),
	BuyOutfit = clientComm:GetSignal("BuyOutfit"),
	WearOutfit = clientComm:GetSignal("WearOutfit"),

	-- Accessory
	BuyAccessory = clientComm:GetSignal("buyAccessory"),
	AddToCart = clientComm:GetSignal("AddToCart"),
	TryAccessory = clientComm:GetSignal("TryAccessory"),
	LikeAccessory = clientComm:GetSignal("buyAccessory"),
	RemoveToCart = clientComm:GetSignal("RemoveToCart"),
	TakeOff = clientComm:GetSignal("TakeOff"),

	-- Player
	PlayerEntered = clientComm:GetSignal("PlayerEntered"),
	OutfitCodeInputed = clientComm:GetSignal("OutfitCodeInputed"),
	Warn = clientComm:GetSignal("Warn"),

	-- Remote Functions (Global, created by Rojo)
	ProfileLoaded = clientComm:GetSignal("ProfileLoaded"),
	GetCart = ReplicatedStorage.RF.GetCart,
}
