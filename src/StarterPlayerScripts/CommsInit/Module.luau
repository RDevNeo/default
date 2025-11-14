-- ReplicatedStorage/SharedModules/CommClient.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Net = require(ReplicatedStorage.Packages.Net)

return {
	-- Bindables
	OpenOutfit = Signal.new(),
	OpenFromSearch = Signal.new(),
	PromptSinglePurchase = Signal.new(),
	WarnSignal = Signal.new(),
	OpenFromPlayer = Signal.new(),
	OpenTeleportMenu = Signal.new(),
	OpenGroupReward = Signal.new(),

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
	AnnouncePurchase = Net:RemoteEvent("AnnouncePurchase"),

	-- Internal Remotes Functions
	ProfileLoaded = Net:RemoteEvent("ProfileLoaded"),
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
	GetGamesIds = Net:RemoteFunction("GetGamesIds"),

	-- Global Events
	SinglePurchaseMade = Net:RemoteEvent("SinglePurchaseMade"),
	bulkPurchaseMade = Net:RemoteEvent("bulkPurchaseMade"),

	-- Others
	OnDonateClicked = Net:RemoteEvent("OnDonateClicked"),
}
