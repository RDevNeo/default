task.defer(function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local VERSION = require(ReplicatedStorage.Packages._Index["foreverhd_topbarplus@1.0.0"].Version)
	local appVersion = VERSION.getAppVersion()
	local latestVersion = VERSION.getLatestVersion()
	local isOutdated = not VERSION.isUpToDate()
	if not RunService:IsStudio() then
		print(`🍍 Running TopbarPlus {appVersion} by @ForeverHD & HD Admin`)
	end
	if isOutdated then
		warn(
			`A new version of TopbarPlus ({latestVersion}) is available: https://devforum.roblox.com/t/topbarplus/1017485`
		)
	end
end)

return {}
