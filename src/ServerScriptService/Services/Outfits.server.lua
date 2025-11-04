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
	print(player.Name .. " ID >" .. tostring(id) .. " > LIKE ACCESSORY")
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
