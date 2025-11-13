-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TextChatService = game:GetService("TextChatService")

-- Dependencies
local DataManager = require(ServerStorage.Source.Datastore.DataManager)
local WebwookHandler = require(ServerStorage.Source.Webook.Handler)
local Helper = require(ServerScriptService.Source.Purchases.Helper)
local Net = require(ReplicatedStorage.Packages.Net)
local systemChannel: TextChannel = TextChatService:WaitForChild("TextChannels"):FindFirstChild("RBXSystem")
local Signals = require(ServerScriptService.Source.CommsInit.Module)

local rbxQuantity: number

-- This handles only single purchases.
Net:Connect("SinglePurchaseMade", function(player, assetId)
	local success, result: { Name: string, PriceInRobux: number }? = pcall(function()
		return MarketplaceService:GetProductInfo(assetId)
	end)

	if success and result then
		DataManager.AddSpent(player, result.PriceInRobux)
		DataManager.AddPurchases(player, 1)
		WebwookHandler.notifyPurchase({
			playerId = player.UserId,
			playerName = player.Name,
			items = 1,
			spent = result.PriceInRobux,
		})
	end

	if result then
		MessagingService:PublishAsync("GlobalPurchase", {
			playerName = player.name,
			itemName = result.Name,
			price = result.PriceInRobux,
		})
	end
end)

MessagingService:SubscribeAsync("GlobalPurchase", function(message)
	local data: { playerName: string, itemName: string, price: number } = message.Data
	local text = string.format(
		'<font color="rgb(0,255,0)">[✅] %s bought "%s" for %s%s!</font>',
		data.playerName,
		data.itemName,
		utf8.char(0xE002),
		tostring(data.price)
	)

	Signals.AnnouncePurchase:FireAllClients(text)
end)

-- This prompts products (Donates)
Net:Connect("OnDonateClicked", function(player, id, quantity)
	MarketplaceService:PromptProductPurchase(player, id)
	rbxQuantity = quantity
end)

-- This handles products (Donates)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
	local success, player = pcall(function()
		return Players:GetPlayerByUserId(userId)
	end)

	if success and isPurchased then
		DataManager.AddDonated(player, rbxQuantity)
	end
end)

-- Format the table and prompt to the player.
Net:Connect("BuyOutfit", function(player, ids)
	local temp = {}

	for index, value in pairs(ids) do
		table.insert(temp, { Type = Enum.MarketplaceProductType.AvatarAsset, Id = tostring(value) })
	end

	MarketplaceService:PromptBulkPurchase(player, temp, {})
end)

-- Gets the Signal from the client and handles on the server.
Net:Connect("bulkPurchaseMade", function(player, results)
	local assetsIds = {}
	local model, meta = Helper.getRightModel(assetsIds)

	if meta and meta.isOutfit then
		Helper.emmitEffect(model)
		DataManager.AddOutfitsPurchase(player, 1)
	else
		Helper.emmitEffect(player)
	end
end)
