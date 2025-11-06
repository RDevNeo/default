-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

-- Dependencies
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)

-- Handle single items.
Signals.PromptSinglePurchase:Connect(function(id: number)
	MarketplaceService:PromptPurchase(Players.LocalPlayer, id)
end)

-- Handles single items.
MarketplaceService.PromptPurchaseFinished:Connect(function(player, assetId, isPurchased)
	if isPurchased then
		Signals.SinglePurchaseMade:FireServer(assetId)
	end
end)

-- This Handles BulkPurchases.
MarketplaceService.PromptBulkPurchaseFinished:Connect(
	function(player: Player, status: Enum.MarketplaceBulkPurchasePromptStatus, results: { [any]: any })
		if status == Enum.MarketplaceBulkPurchasePromptStatus.Completed then
			for _, lineItem in pairs(results.Items) do
				if lineItem.status == Enum.MarketplaceItemPurchaseStatus.Success then
					Signals.bulkPurchaseMade:FireServer(results)
				end
			end
		end
	end
)
