local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local OutfitsMT = require(ServerStorage.Source.Outfits.OutfitsMT)
OutfitHelper = require(ReplicatedStorage.Helpers.OutfitHelper)
local DataManager = require(ServerStorage.Source.Datastore.DataManager)
local Net = require(ReplicatedStorage.Packages.Net)
local _InstanceCreator = require(ServerStorage.Source.InstancesCreator)

type Outfit = OutfitsMT.Outfit

local ownershipCache = {}
local originalDesc = {}

local function checkOwnershipAsync(player, ids)
	local uid = player.UserId
	ownershipCache[uid] = ownershipCache[uid] or {}

	local results = {}

	for _, id in ipairs(ids) do
		-- Use cached result if available
		if ownershipCache[uid][id] ~= nil then
			results[id] = ownershipCache[uid][id]
		else
			local success, owns = pcall(MarketplaceService.PlayerOwnsAsset, MarketplaceService, player, id)
			owns = success and owns or false
			ownershipCache[uid][id] = owns
			results[id] = owns
		end
	end

	return results
end

local function IntHelpers()
	local Donates = ServerStorage:FindFirstChild("Configuration"):FindFirstChild("Donates") :: Folder
	if not Donates then
		return {}
	end

	local result = {}

	for _, int in ipairs(Donates:GetChildren()) do
		if int:IsA("IntValue") then
			table.insert(result, {
				name = int.Name,
				id = int.Value,
				amount = tonumber(int.Name:match("%d+")),
			})
		end
	end

	table.sort(result, function(a, b)
		return a.amount < b.amount
	end)

	return result
end

Players.PlayerAdded:Connect(function(player)
	local success, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(player.UserId)
	end)

	if success and desc then
		originalDesc[player.UserId] = desc:Clone()
	end
end)

Players.PlayerRemoving:Connect(function(player)
	originalDesc[player.UserId] = nil
end)

-- Remote Functions
Net:Connect("WearOutfit", function(player, code: string)
	if not player then
		return
	end

	local character = player.Character
	local Humanoid = character:FindFirstChildWhichIsA("Humanoid")

	if code then
		local Outfit: Model? = OutfitsMT:GetOutfitByCode(code)

		if Outfit then
			local outfitHumanoid = Outfit:FindFirstChildWhichIsA("Humanoid")

			if outfitHumanoid then
				local newDesc = outfitHumanoid:GetAppliedDescription()

				Humanoid:ApplyDescription(newDesc)
			end
		end
	end
end)

Net:Connect("AddToCart", function(player, id)
	if not player then
		return
	end
	if not id then
		return
	end
	DataManager.AddCart(player, id)
end)

Net:Connect("TryAccessory", function(player, id)
	if not player then
		return
	end
	if not id then
		return
	end
	OutfitHelper.addAccessory(player, id)
end)

Net:Connect("LikeAccessory", function(player, id)
	if not player then
		return
	end
	if not id then
		return
	end
	DataManager.AddLikedAccessory(player, id)
end)

Net:Connect("UnlikeAccessory", function(player, id)
	if not player then
		return
	end
	if not id then
		return
	end
	DataManager.RemoveLikedAccessory(player, id)
end)

Net:Connect("RemoveToCart", function(player, id)
	if type(id) == "number" then
		DataManager.RemoveCart(player, id)
	else
		for _, v in pairs(id) do
			DataManager.RemoveCart(player, v)
		end
	end
end)

Net:Connect("TakeOff", function(player, id)
	OutfitHelper.removeAccessory(player, id)
end)

Net:Connect("AddOutfitLike", function(player, code)
	DataManager.AddLikedOutfit(player, code)
end)

Net:Connect("RemoveOutfitLike", function(player, code)
	DataManager.RemoveLikedOutfit(player, code)
end)

Net:Connect("Warn", function(player, msg)
	print(msg)
end)

Net:Connect("Reset", function(player: Player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local originalDesc = originalDesc[player.UserId]
	if not originalDesc then
		return
	end

	humanoid:ApplyDescription(originalDesc)
end)

-- Remote Functions
Net:Handle("GetCart", function(player)
	return DataManager.GetCart(player)
end)

Net:Handle("GetLikedAccs", function(player)
	return DataManager.GetLikedAccessories(player)
end)

Net:Handle("GetLikedOutfits", function(player)
	return DataManager.GetLikedOutfits(player)
end)

Net:Handle("GetOwnedAssets", function(player, ids)
	return checkOwnershipAsync(player, ids)
end)

Net:Handle("GetOutfits", function(player)
	local outfits = OutfitsMT:GetAllOutfits()
	return outfits
end)

Net:Handle("GetLikedOuftiObject", function(player, likedOutfits: { string })
	local allOutfits = OutfitsMT:GetAllOutfits()

	local result = {}

	for _, outfit in pairs(allOutfits) do
		local code = tostring(outfit.Code)

		if table.find(likedOutfits, code) then
			table.insert(result, outfit)
		end
	end

	return result
end)

Net:Handle("GetDonatedValue", function(player)
	return DataManager.GetDonated(player)
end)

Net:Handle("GetIntValues", function(player)
	return IntHelpers()
end)

Net:Handle("GetRunConfig", function(player)
	return ServerStorage:FindFirstChild("Configuration"):FindFirstChild("RUN_SPEED").Value
end)

Net:Handle("GetPlayerModelRange", function(player)
	return ServerStorage:FindFirstChild("Configuration"):FindFirstChild("PLAYER_MODEL_RANGE").Value
end)

Net:Handle("GetMusicID", function(player)
	return ServerStorage:FindFirstChild("Configuration"):FindFirstChild("DEFAULT_MUSIC_ID").Value
end)

Net:Handle("GetModelByCode", function(player, code: string)
	local outfits = OutfitsMT:GetAllOutfits()

	for index, value in pairs(outfits) do
		if value.Code == code then
			return value
		end
	end

	return
end)

Net:Handle("GetOutfitLikes", function(player, code: string)
	local fixed = tostring(DataManager.GetGlobalOutfitLikes(code))
	return fixed
end)
