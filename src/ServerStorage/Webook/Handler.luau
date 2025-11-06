local module = {}

-- Services
local GroupService = game:GetService("GroupService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

-- Modules
local SendMessage = require(ServerStorage.Source.Webook.SendMessage)

-- Constants
local ALL_SALES_WEBHOOK_URL =
	"https://discord.com/api/webhooks/1432551786731798548/Uhai8xpOg1mS6POP_thtt388K6fssQyPBWMgY98TDVFKVhepgs5N9NzeFOEp9h8snvek"

local PORTAL_WEBHOOK_URL =
	"https://discord.com/api/webhooks/1434603684683317426/BwwVCODU60tV5tcc5do8NnwhYVqJaTm7EX8S19hy7DvxOMjzDVTRYTOlDRNRFlYX6zj1"

local isValidDiscordWebhookUrl = function(url: string): boolean
	if typeof(url) ~= "string" then
		return false
	end

	-- Trim surrounding whitespace
	url = string.gsub(url, "^%s+", "")
	url = string.gsub(url, "%s+$", "")

	-- Strict Discord webhook format:
	-- https://discord.com/api/webhooks/{id}/{token}
	local pattern = "^https://discord%.com/api/webhooks/%d+/[%w%-%._]+$"
	return string.match(url, pattern) ~= nil
end

local getWebhookURL = function(): string
	local WebhookConfiguration: Instance? = ServerStorage:WaitForChild("Configuration")
		:WaitForChild("NotifyPurchaseWebhookURL")
	if not WebhookConfiguration then
		return error(
			'Missing Webhook Configuration, add a "NotifyPurchaseWebhookURL" StringValue in the Configuration folder at the Server Storage.'
		)
	end

	if not WebhookConfiguration:IsA("StringValue") then
		return error(
			'Webhook Configuration is not a StringValue, add a "NotifyPurchaseWebhookURL" StringValue in the Configuration folder at the Server Storage.'
		)
	end

	local webhookURL = WebhookConfiguration.Value

	if webhookURL == "" then
		return error(
			'Webhook URL is empty, add a "NotifyPurchaseWebhookURL" StringValue in the Configuration folder at the Server Storage.'
		)
	end

	if not isValidDiscordWebhookUrl(webhookURL) then
		return error('Invalid Discord webhook URL. Expected format: "https://discord.com/api/webhooks/{id}/{token}".')
	end

	return webhookURL
end

local groupInfo: { Name: string, Id: number }? = nil

local getGroupInfo = function()
	if groupInfo then
		return groupInfo
	end

	local ok, info = pcall(function()
		return GroupService:GetGroupInfoAsync(game.CreatorId)
	end)

	if not ok then
		return error("Failed to get group information.")
	end

	groupInfo = { Name = info.Name, Id = info.Id }
	return groupInfo
end

type Props = {
	playerId: number,
	playerName: string,
	items: number,
	spent: number,
	attempts: number?,
}

local function notifyAllSalesPurchase(props: Props): nil
	local groupInfo = getGroupInfo()

	local playerProfileUrl = "https://www.roblox.com/users/" .. props.playerId .. "/profile/"

	local embedData = {
		embeds = {
			{
				title = `:shopping_cart: [{groupInfo.Name}] - New Purchase!`,
				description = `[{props.playerName}]({playerProfileUrl}) purchased **{props.items}** items for **{props.spent}** Robux`,
				color = 16776960,
			},
		},
	}

	local body = HttpService:JSONEncode(embedData)

	SendMessage(ALL_SALES_WEBHOOK_URL, body)

	return nil
end

type PortalUsageProps = {
	playerId: number,
	playerName: string,
	portalGameName: string,
	currentPlaceName: string,
}

local portalUsageDebounce: { [number]: number } = {}
local PORTAL_USAGE_DEBOUNCE_TIME = 30

module.notifyPortalUsage = function(props: PortalUsageProps): nil
	local currentTime = os.time()
	local lastNotificationTime = portalUsageDebounce[props.playerId]

	if lastNotificationTime and (currentTime - lastNotificationTime) < PORTAL_USAGE_DEBOUNCE_TIME then
		return nil
	end

	portalUsageDebounce[props.playerId] = currentTime

	print("[WEBHOOK] Sending portal usage webhook")
	local playerProfileUrl = "https://www.roblox.com/users/" .. props.playerId .. "/profile/"

	local embedData = {
		embeds = {
			{
				title = `:door: - Portal Usage!`,
				description = `[{props.playerName}]({playerProfileUrl}) at **{props.currentPlaceName}** used the portal to teleport to **{props.portalGameName}**`,
			},
		},
	}

	SendMessage(PORTAL_WEBHOOK_URL, HttpService:JSONEncode(embedData))

	return nil
end

local function notifyGroupSalePurchase(props: Props): nil
	local playerProfileUrl = "https://www.roblox.com/users/" .. props.playerId .. "/profile/"

	local embedData = {
		embeds = {
			{
				title = `:shopping_cart: - New Purchase!`,
				description = `[{props.playerName}]({playerProfileUrl}) purchased **{props.items}** items for **{props.spent}** Robux`,
				color = 16776960,
			},
		},
	}

	SendMessage(getWebhookURL(), HttpService:JSONEncode(embedData))

	return nil
end

module.notifyPurchase = function(props: Props): nil
	notifyAllSalesPurchase(props)
	notifyGroupSalePurchase(props)

	return nil
end

return module
