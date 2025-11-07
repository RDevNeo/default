-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local Net = require(ReplicatedStorage.Packages.Net)
local Signals = require(ReplicatedStorage.Packages.Signal)

local signals = {

	-- Bindables
	DataManagerLoaded = Signals.new(),

	-- Outfit
	BuyOutfit = Net:RemoteEvent("BuyOutfit"),
	WearOutfit = Net:RemoteEvent("WearOutfit"),

	-- Accessory
	AddToCart = Net:RemoteEvent("AddToCart"),
	TryAccessory = Net:RemoteEvent("TryAccessory"),
	LikeAccessory = Net:RemoteEvent("LikeAccessory"),
	UnlikeAccessory = Net:RemoteEvent("UnlikeAccessory"),
	RemoveToCart = Net:RemoteEvent("RemoveToCart"),
	TakeOff = Net:RemoteEvent("TakeOff"),

	-- Likes
	AddOutfitLike = Net:RemoteEvent("AddOutfitLike"),
	RemoveOutfitLike = Net:RemoteEvent("RemoveOutfitLike"),

	-- Player
	PlayerEntered = Net:RemoteEvent("PlayerEntered"),
	OutfitCodeInputed = Net:RemoteEvent("OutfitCodeInputed"),
	Warn = Net:RemoteEvent("Warn"),
	Reset = Net:RemoteEvent("Reset"),

	-- Remotes Functions
	GetMusicID = Net:RemoteFunction("GetMusicID"),
	GetPlayerModelRange = Net:RemoteFunction("GetPlayerModelRange"),
	GetRunConfig = Net:RemoteFunction("GetRunConfig"),
	GetDonatedValue = Net:RemoteFunction("GetDonatedValue"),
	GetIntValues = Net:RemoteFunction("GetIntValues"),
	GetCart = Net:RemoteFunction("GetCart"),
	GetLikedAccs = Net:RemoteFunction("GetLikedAccs"),
	GetLikedOutfits = Net:RemoteFunction("GetLikedOutfits"),
	GetOwnedAssets = Net:RemoteFunction("GetOwnedAssets"),
	GetOutfits = Net:RemoteFunction("GetOutfits"),
	GetLikedOuftiObject = Net:RemoteFunction("GetLikedOuftiObject"),
	GetModelByCode = Net:RemoteFunction("GetModelByCode"),
	GetOutfitLikes = Net:RemoteFunction("GetOutfitLikes"),

	-- Global Events
	bulkPurchaseMade = Net:RemoteEvent("bulkPurchaseMade"),
	SinglePurchaseMade = Net:RemoteEvent("SinglePurchaseMade"),

	-- Others
	OnDonateClicked = Net:RemoteEvent("OnDonateClicked"),
	ProfileLoaded = Net:RemoteEvent("ProfileLoaded"),
}

return signals
