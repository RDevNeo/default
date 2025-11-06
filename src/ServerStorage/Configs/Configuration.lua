-- Services
local ServerStorage = game:GetService("ServerStorage")

-- Dependencies
local InternalEnum = require(script.Parent.InternalEnum)

local module = {}

local function GetConfigurationFolder(): Folder
	local ConfigurationFolder = ServerStorage:FindFirstChild("Configuration")

	if not ConfigurationFolder then
		return error("Configuration folder not found")
	end

	if not ConfigurationFolder:IsA("Folder") then
		return error("Configuration folder is not a folder")
	end

	return ConfigurationFolder
end

local function isAllIntValues(table: { any }): boolean
	for _, value in table do
		if not value:IsA("IntValue") then
			return false
		end
	end

	return true
end

module.GetBadges = function(): {
	Welcome: number,
	NiceToMeetYou: number,
	FirstPurchase: number,
	FullOutfitPurchase: number,
	FiveTimesFullOutfitPurchase: number,
}
	local configurationFolder = GetConfigurationFolder()

	local badgeIdsFolder = configurationFolder:FindFirstChild("Badges")

	if not badgeIdsFolder then
		return error("Badge ids folder not found")
	end

	if not badgeIdsFolder:IsA("Folder") then
		return error("Badge ids folder is not a folder")
	end

	local badgeIds = badgeIdsFolder:GetChildren()

	if not isAllIntValues(badgeIds) then
		return error("All badge ids must be IntValues")
	end

	local badgeIdsTable: { [string]: number } = {}

	for badgeName in pairs(InternalEnum.BadgeName) do
		local badgeId = badgeIdsFolder:FindFirstChild(badgeName)

		if not badgeId then
			return error(`Badge "{badgeName}" id not found`)
		end

		if not badgeId:IsA("IntValue") then
			return error(`Badge "{badgeName}" id is not an IntValue`)
		end

		badgeIdsTable[badgeName] = badgeId.Value
	end

	return badgeIdsTable
end

module.GetDonates = function(): {
	DONATE_100: number,
	DONATE_500: number,
	DONATE_1000: number,
	DONATE_5000: number,
	DONATE_10000: number,
	DONATE_25000: number,
	DONATE_50000: number,
	DONATE_100000: number,
}
	local configurationFolder = GetConfigurationFolder()

	local donateIdsFolder = configurationFolder:FindFirstChild("Donates")
	if not donateIdsFolder then
		return error("Donate ids folder not found")
	end

	if not donateIdsFolder:IsA("Folder") then
		return error("Donate ids folder is not a folder")
	end

	local donateIds = donateIdsFolder:GetChildren()

	if not isAllIntValues(donateIds) then
		return error("All donate ids must be IntValues")
	end

	local donateIdsTable: { [string]: number } = {}

	for donateName in pairs(InternalEnum.DonateName) do
		local donateId = donateIdsFolder:FindFirstChild(donateName)

		if not donateId then
			return error(`Donate "{donateName}" id not found`)
		end

		if not donateId:IsA("IntValue") then
			return error(`Donate "{donateName}" id is not an IntValue`)
		end

		donateIdsTable[donateName] = donateId.Value
	end

	return donateIdsTable
end

return module
