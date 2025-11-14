-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local InternalEnum = require(script.Parent.InternalEnum)
local GameConfigs = require(ReplicatedStorage.GameConfigs)

local module = {}

module.GetBadges = function(): {
	["Welcome"]: number,
	["NiceToMeetYou"]: number,
	["FirstPurchase"]: number,
	["FullOutfitPurchase"]: number,
	["FiveTimesFullOutfitPurchase"]: number,
}
	local badgeIdsTable: { [string]: number } = {}

	for badgeName, badgeValue in pairs(GameConfigs.Badges) do
		badgeIdsTable[badgeName] = badgeValue
	end
	return badgeIdsTable
end

module.GetDonates = function(): {
	["DONATE_100"]: number,
	["DONATE_500"]: number,
	["DONATE_1000"]: number,
	["DONATE_5000"]: number,
	["DONATE_10000"]: number,
	["DONATE_25000"]: number,
	["DONATE_50000"]: number,
	["DONATE_100000"]: number,
}
	local donateIdsTable: { [string]: number } = {}

	for donateName, donateId in pairs(InternalEnum.DonateName) do
		donateIdsTable[donateName] = donateId
	end

	return donateIdsTable
end

return module
