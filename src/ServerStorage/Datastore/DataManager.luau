local ServerStorage = game:GetService("ServerStorage")
local DataManager = {} :: {}

-- Dependencies
local Badge = require(ServerStorage.Source.Configs.Badges)
local InternalEnum = require(ServerStorage.Source.Configs.InternalEnum)

DataManager.Profiles = {}
DataManager.GlobalMetrics = nil

local function addGlobalMetric(metric: string, playerUserId: number, amount: number)
	local global = DataManager.GlobalMetrics
	if not global then
		return
	end
	global.Data[metric][playerUserId] = (global.Data[metric][playerUserId] or 0) + amount
end

local function getGlobalTop(metric: string, n: number)
	task.wait(5)
	local global = DataManager.GlobalMetrics
	if not global then
		return {}
	end

	local results = {}
	for userId, value in pairs(global.Data[metric]) do
		table.insert(results, { UserId = userId, Value = value })
	end

	table.sort(results, function(a, b)
		return a.Value > b.Value
	end)

	local topN = {}
	for i = 1, math.min(n, #results) do
		table.insert(topN, results[i])
	end

	return topN
end

local function waitForGlobalCodes(timeout)
	local start = tick()
	while not DataManager.GlobalCodes or not DataManager.GlobalCodes.Data do
		if tick() - start >= (timeout or 5) then
			return nil
		end
		task.wait(0.05)
	end
	return DataManager.GlobalCodes
end

DataManager.AddSpent = function(player: Player, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then
		return
	end

	profile.Data.Spent += amount
	if player:FindFirstChild("leaderstats") then
		local leaderstats = player:FindFirstChild("leaderstats") :: Folder
		leaderstats.Spent.Value = profile.Data.Spent
	end

	-- Update global metric
	addGlobalMetric("Spent", player.UserId, amount)
end

DataManager.AddOutfitsPurchase = function(player: Player, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then
		return
	end

	if profile.Data.OutfitsPurchased == 0 then
		-- Not sure if we should be handling badges inside a Datastore, but it's here for now
		Badge.Award(player, InternalEnum.BadgeName.FullOutfitPurchase)
	elseif profile.Data.OutfitsPurchased == 4 then
		Badge.Award(player, InternalEnum.BadgeName.FiveTimesFullOutfitPurchase)
	end

	profile.Data.OutfitsPurchased += amount
end

DataManager.AddPurchases = function(player: Player, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then
		return
	end

	if profile.Data.Purchases == 0 then
		Badge.Award(player, InternalEnum.BadgeName.FirstPurchase)
	end

	profile.Data.Purchases += amount

	if player:FindFirstChild("leaderstats") then
		local leaderstats = player:FindFirstChild("leaderstats") :: Folder
		leaderstats.Purchases.Value = profile.Data.Purchases
	end

	addGlobalMetric("Purchases", player.UserId, amount)
end

DataManager.AddDonated = function(player: Player, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then
		return
	end

	profile.Data.Donated += amount
	if player:FindFirstChild("leaderstats") then
		local leaderstats = player:FindFirstChild("leaderstats") :: Folder
		leaderstats.Donated.Value = profile.Data.Donated
	end

	addGlobalMetric("Donated", player.UserId, amount)
end

DataManager.AddCart = function(player: Player, assetId: string | number)
	local profile = DataManager.Profiles[player]
	if not profile then
		warn(`[DataManager.AddCart] No profile found for player {player.Name}`)
		return
	end

	local fixed = tonumber(assetId)
	if not fixed then
		warn(`[DataManager.AddCart] Invalid assetId for player {player.Name}`)
		return
	end

	if not profile.Data or not profile.Data.Cart then
		warn(`[DataManager.AddCart] Missing Cart data for player {player.Name}`)
		return
	end

	if table.find(profile.Data.Cart, fixed) then
		warn(`[DataManager.AddCart] Asset {fixed} already in cart for player {player.Name}`)
		return
	end

	table.insert(profile.Data.Cart, fixed)
end

DataManager.AddLikedAccessory = function(player: Player, assetId: string | number)
	local profile = DataManager.Profiles[player]
	if not profile then
		warn(`[DataManager.AddLikedAccessory] No profile found for player {player.Name}`)
		return
	end

	local fixed = tonumber(assetId)
	if not fixed then
		warn(`[DataManager.AddLikedAccessory] Invalid assetId for player {player.Name}`)
		return
	end

	if not profile.Data or not profile.Data.LikedAccessories then
		warn(`[DataManager.AddLikedAccessory] Missing LikedAccessories data for player {player.Name}`)
		return
	end

	if table.find(profile.Data.LikedAccessories, fixed) then
		warn(`[DataManager.AddLikedAccessory] Asset {fixed} already liked for player {player.Name}`)
		return
	end

	table.insert(profile.Data.LikedAccessories, fixed)
end

DataManager.AddLikedOutfit = function(player: Player, code: string | number)
	local profile = DataManager.Profiles[player]
	if not profile then
		warn(`[DataManager.AddLikedOutfit] No profile found for player {player.Name}`)
		return
	end

	if not profile.Data or not profile.Data.LikedOutfits then
		warn(`[DataManager.AddLikedOutfit] Missing LikedOutfits data for player {player.Name}`)
		return
	end

	-- Normalize code as string
	local fixed = tostring(code)

	-- Avoid duplicates
	if table.find(profile.Data.LikedOutfits, fixed) then
		warn(`[DataManager.AddLikedOutfit] Outfit {fixed} already liked for player {player.Name}`)
		return
	end

	-- Add to player's liked outfits
	table.insert(profile.Data.LikedOutfits, fixed)

	-- Add to global likes (smartly)
	DataManager.AddGlobalOutfitLike(fixed)
end

DataManager.AddGlobalOutfitLike = function(code: string | number)
	local global = waitForGlobalCodes(5)
	if not global then
		warn("[DataManager.AddGlobalOutfitLike] Global codes profile not ready; like not recorded")
		return
	end

	global.Data.OutfitsCode = global.Data.OutfitsCode or {}
	local key = tostring(code)
	global.Data.OutfitsCode[key] = (global.Data.OutfitsCode[key] or 0) + 1
end

DataManager.RemoveCart = function(player: Player, assetId: string | number)
	local profile = DataManager.Profiles[player]
	if not profile then
		warn(`[DataManager.RemoveCart] No profile found for player {player.Name}`)
		return
	end

	local fixed = tonumber(assetId)
	if not fixed then
		warn(`[DataManager.RemoveCart] Invalid assetId for player {player.Name}`)
		return
	end

	if not profile.Data or not profile.Data.Cart then
		warn(`[DataManager.RemoveCart] Missing Cart data for player {player.Name}`)
		return
	end

	local index = table.find(profile.Data.Cart, fixed)
	if not index then
		warn(`[DataManager.RemoveCart] Tried to remove asset {fixed} that isn’t in cart for player {player.Name}`)
		return
	end

	table.remove(profile.Data.Cart, index)
end

DataManager.RemoveGlobalOutfitLike = function(code: string | number)
	local global = DataManager.GlobalCodes
	if not global then
		warn("[DataManager.RemoveGlobalOutfitLike] No global codes profile found!")
		return
	end

	local fixed = tostring(code)

	if not global.Data.OutfitsCode[fixed] then
		return
	end

	global.Data.OutfitsCode[fixed] = math.max(0, global.Data.OutfitsCode[fixed] - 1)
end

DataManager.RemoveLikedAccessory = function(player: Player, assetId: string | number)
	local profile = DataManager.Profiles[player]
	if not profile then
		warn(`[DataManager.RemoveLikedAccessory] No profile found for player {player.Name}`)
		return
	end

	local fixed = tonumber(assetId)
	if not fixed then
		warn(`[DataManager.RemoveLikedAccessory] Invalid assetId for player {player.Name}`)
		return
	end

	if not profile.Data or not profile.Data.LikedAccessories then
		warn(`[DataManager.RemoveLikedAccessory] Missing LikedAccessories data for player {player.Name}`)
		return
	end

	local index = table.find(profile.Data.LikedAccessories, fixed)
	if not index then
		warn(
			`[DataManager.RemoveLikedAccessory] Tried to remove asset {fixed} that isn’t liked for player {player.Name}`
		)
		return
	end

	table.remove(profile.Data.LikedAccessories, index)
end

DataManager.RemoveLikedOutfit = function(player: Player, code: string | number)
	local profile = DataManager.Profiles[player]
	if not profile then
		warn(`[DataManager.RemoveLikedOutfit] No profile found for player {player.Name}`)
		return
	end

	if not profile.Data or not profile.Data.LikedOutfits then
		warn(`[DataManager.RemoveLikedOutfit] Missing LikedOutfits data for player {player.Name}`)
		return
	end

	-- Normalize code as string
	local fixed = tostring(code)

	-- Find index in player's liked outfits
	local index = table.find(profile.Data.LikedOutfits, fixed)
	if not index then
		warn(
			`[DataManager.RemoveLikedOutfit] Tried to remove outfit {fixed} that isn’t liked for player {player.Name}`
		)
		return
	end

	-- Remove from player's liked outfits
	table.remove(profile.Data.LikedOutfits, index)

	-- Remove from global likes (safely)
	DataManager.RemoveGlobalOutfitLike(fixed)
end

DataManager.GetCart = function(player: Player): { number } | {}
	local profile = DataManager.Profiles[player]
	if not profile then
		warn(`[DataManager.GetCart] No profile found for player {player.Name}`)
		return {}
	end

	return profile.Data.Cart
end

DataManager.GetPurchases = function(player: Player): number | nil
	local profile = DataManager.Profiles[player]
	if not profile then
		return nil
	end
	return profile.Data.Purchases
end

DataManager.GetOufitsPurchases = function(player: Player): number | nil
	local profile = DataManager.Profiles[player]
	if not profile then
		return nil
	end
	return profile.Data.OutfitsPurchased
end

DataManager.GetDonated = function(player: Player): number | nil
	local profile = DataManager.Profiles[player]
	if not profile then
		return nil
	end
	return profile.Data.Donated
end

DataManager.GetLikedAccessories = function(player: Player): { number } | {}
	local profile = DataManager.Profiles[player]
	if not profile then
		warn(`[DataManager.GetLikedAccessories] No profile found for player {player.Name}`)
		return {}
	end

	return profile.Data.LikedAccessories
end

DataManager.GetLikedOutfits = function(player: Player): { number }
	local profile = DataManager.Profiles[player]
	if not profile then
		warn(`[DataManager.GetLikedOutfits] No profile found for player {player.Name}`)
		return {}
	end

	return profile.Data.LikedOutfits
end

DataManager.GetGlobalOutfitLikes = function(code: string): number
	-- Wait up to 5s for the global codes profile to exist (safe)
	local global = waitForGlobalCodes(5)
	if not global then
		warn("[DataManager.GetGlobalOutfitLikes] Global codes profile not ready after timeout; returning 0")
		return 0
	end

	-- Ensure OutfitsCode exists and normalize key
	global.Data.OutfitsCode = global.Data.OutfitsCode or {}
	code = tostring(code)

	if global.Data.OutfitsCode[code] == nil then
		global.Data.OutfitsCode[code] = 0
	end

	return global.Data.OutfitsCode[code]
end

DataManager.IsAssetInCart = function(player: Player, assetId: string | number): boolean
	local profile = DataManager.Profiles[player]
	if not profile then
		warn(`[DataManager.IsAssetInCart] No profile found for player {player.Name}`)
		return false
	end

	local fixed = tonumber(assetId)
	if not fixed then
		warn(`[DataManager.IsAssetInCart] Invalid assetId for player {player.Name}`)
		return false
	end

	local hasAsset = table.find(profile.Data.Cart, fixed) ~= nil
	return hasAsset
end

DataManager.IsAccessoryLiked = function(player: Player, assetId: string | number): boolean
	local profile = DataManager.Profiles[player]
	if not profile then
		warn(`[DataManager.IsAccessoryLiked] No profile found for player {player.Name}`)
		return false
	end

	local fixed = tonumber(assetId)
	if not fixed then
		warn(`[DataManager.IsAccessoryLiked] Invalid assetId for player {player.Name}`)
		return false
	end

	local hasAsset = table.find(profile.Data.LikedAccessories, fixed) ~= nil
	return hasAsset
end

DataManager.IsOutfitLiked = function(player: Player, code: string | number): boolean
	local profile = DataManager.Profiles[player]
	if not profile or not profile.Data then
		warn(`[DataManager.IsOutfitLiked] No profile data found for player {player.Name}`)
		return false
	end

	-- Ensure LikedOutfits exists
	profile.Data.LikedOutfits = profile.Data.LikedOutfits or {}

	-- Normalize code to string
	local fixed = tostring(code)
	if not fixed then
		warn(`[DataManager.IsOutfitLiked] Invalid outfit code for player {player.Name}`)
		return false
	end

	-- Check if the outfit is in the player's liked outfits
	local hasCode = table.find(profile.Data.LikedOutfits, fixed) ~= nil
	return hasCode
end

DataManager.GetTopSpent = function(n)
	return getGlobalTop("Spent", n)
end

DataManager.GetTopPurchases = function(n)
	return getGlobalTop("Purchases", n)
end

DataManager.GetTopDonated = function(n)
	return getGlobalTop("Donated", n)
end

return DataManager
