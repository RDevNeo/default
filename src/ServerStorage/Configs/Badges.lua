-- Services
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Dependencies
local Configuration = require(ServerStorage.Source.Configs.Configuration)
local InternalEnum = require(ServerStorage.Source.Configs.InternalEnum)

local module = {}

-- Returns nil if the badge is already awarded,
-- Returns boolean for the award badge result
module.Award = function(player: Player, badgeName: string): boolean?
	local badgeId = Configuration.GetBadges()[badgeName]

	if not badgeId then
		return error(`Badge "{badgeName}" not found`)
	end

	local _, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
	end)

	if hasBadge then
		print(`Badge "{badgeName}" already awarded to player "{player.Name}"`)
		return nil
	end

	local awardSuccess, _ = pcall(function()
		return BadgeService:AwardBadge(player.UserId, badgeId)
	end)

	return awardSuccess
end

module.Init = function()
	local targetGroupId = ServerStorage.Configuration.GROUP_ID.Value
	local allowedRanks = { 254, 255 }

	local function onPlayerAdded(player: Player)
		module.Award(player, InternalEnum.BadgeName.Welcome)
	end

	local function onOwnerAdded(player: Player)
		local rank = player:GetRankInGroup(targetGroupId)

		if table.find(allowedRanks, rank) then
			module.Award(player, InternalEnum.BadgeName.NiceToMeetYou)
		end
	end

	Players.PlayerAdded:Connect(function(player: Player)
		onPlayerAdded(player)
		onOwnerAdded(player)
	end)
end

return module
