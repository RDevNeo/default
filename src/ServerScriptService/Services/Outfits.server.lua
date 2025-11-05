local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local OutfitsMT = require(ServerStorage.Source.Outfits.Handlers.OutfitsMT)
local Signals = require(ServerScriptService.Source.CommsInit.Module)
local OutfitHelper = require(ReplicatedStorage.Helpers.OutfitHelper)
local DataManager = require(ServerStorage.Source.Datastore.DataManager)

for i, outfit in ipairs(OutfitsMT.GetAllOutfits()) do
	print(string.format("  Outfit %d: Name=%s, Code=%s", i, outfit.Name, outfit.Code))
end

local ownershipCache = {} -- [player.UserId] = { [assetId] = true/false }

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
			ownershipCache[uid][id] = owns -- ✅ store for reuse
			results[id] = owns
		end
	end

	return results
end

Signals.BuyOutfit:Connect(function(player: Player, ids: { number })
	print(player.Name)
	print(ids)
end)

Signals.WearOutfit:Connect(function(player: Player, ids: { number })
	if not player then
		return
	end

	for index, assetId in pairs(ids) do
		OutfitHelper.addAccessory(player, assetId)
	end
end)

Signals.BuyAccessory:Connect(function(player: Player, id: number)
	if not player then
		return
	end
	if not id then
		return
	end
	print(player.Name .. " ID >" .. tostring(id) .. " > BUY ACCESSORY")
end)

Signals.AddToCart:Connect(function(player: Player, id: number)
	if not player then
		return
	end
	if not id then
		return
	end
	DataManager.AddCart(player, id)
end)

Signals.TryAccessory:Connect(function(player: Player, id: number)
	if not player then
		return
	end
	if not id then
		return
	end
	OutfitHelper.addAccessory(player, id)
end)

Signals.LikeAccessory:Connect(function(player: Player, id: number)
	if not player then
		return
	end
	if not id then
		return
	end
	DataManager.AddLikedAccessory(player, id)
end)

Signals.UnlikeAccessory:Connect(function(player: Player, id: number)
	if not player then
		return
	end
	if not id then
		return
	end
	DataManager.RemoveLikedAccessory(player, id)
end)

Signals.TakeOff:Connect(function(player: Player, id: number)
	OutfitHelper.removeAccessory(player, id)
end)

Signals.RemoveToCart:Connect(function(player: Player, id: number | { number })
	if type(id) == "number" then
		DataManager.RemoveCart(player, id)
	else
		for _, v in pairs(id) do
			DataManager.RemoveCart(player, v)
		end
	end
end)

Signals.GetCart.OnServerInvoke = function(player: Player): { number? }
	return DataManager.GetCart(player)
end

Signals.GetLikedAccs.OnServerInvoke = function(player): { number? }
	return DataManager.GetLikedAccessories(player)
end

Signals.GetOwnedAssets.OnServerInvoke = function(player: Player, ids: { number }): { [number]: boolean }
	print(checkOwnershipAsync(player, ids))
	return checkOwnershipAsync(player, ids)
end

Signals.GetRunConfig.OnServerInvoke = function(player: Player): number
	local Configuration = ServerStorage:FindFirstChild("Configuration")

	if not Configuration then
		warn("Could not find the folder Configuration on Server Storage, applying default as 32.")
		return 32
	end

	local intValue = Configuration:FindFirstChild("RUN_SPEED")

	if intValue and intValue:IsA("IntValue") then
		return intValue.Value
	end
	warn("Could not find the RUN_SPEED configuration, applying default as 32.")
	return 32
end
