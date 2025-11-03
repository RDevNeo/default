-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local ProfileStore = require(ServerStorage.Source.Datastore.ProfileStore)
local PlayerTemplate = require(ServerStorage.Source.Datastore.PlayerTemplate)
local ServerTemplate = require(ServerStorage.Source.Datastore.ServerTemplate)
local DataManager = require(ServerStorage.Source.Datastore.DataManager)
local Signals = require(ServerScriptService.Source.CommsInit.Module)

-- Utility
local function getStoreName(): string
	return RunService:IsStudio() and "Test" or "Live"
end

local PlayerStore = ProfileStore.New(getStoreName(), PlayerTemplate)
local ServerStore = ProfileStore.New(getStoreName(), ServerTemplate)

local GlobalMetricsProfile

local function Initialize(player: Player, profile: typeof(PlayerStore:StartSessionAsync()))
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local Purchases = Instance.new("IntValue")
	Purchases.Name = "Purchases"
	Purchases.Value = profile.Data.Purchases
	Purchases.Parent = leaderstats

	local Spent = Instance.new("IntValue")
	Spent.Name = "Spent"
	Spent.Value = profile.Data.Spent
	Spent.Parent = leaderstats

	local Donated = Instance.new("IntValue")
	Donated.Name = "Donated"
	Donated.Value = profile.Data.Donated
	Donated.Parent = leaderstats
end

local function PlayerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync("Player4_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if not profile then
		warn("[PlayerStore] Failed to start session for", player.Name)
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		player:Kick("Data error occurred. Please re-join.")
	end)

	if player.Parent == Players then
		DataManager.Profiles[player] = profile
		Initialize(player, profile)
	else
		profile:EndSession()
	end
end

task.spawn(function()
	local GlobalCodesProfile = ServerStore:StartSessionAsync("GlobalCodes4", {
		Cancel = function()
			return false
		end,
	})

	if GlobalCodesProfile then
		GlobalCodesProfile:Reconcile()
		GlobalCodesProfile:AddUserId(0)
		GlobalCodesProfile.Data.OutfitsCode = GlobalCodesProfile.Data.OutfitsCode or {}

		DataManager.GlobalCodes = GlobalCodesProfile
	end

	GlobalMetricsProfile = ServerStore:StartSessionAsync("GlobalMetrics4", {
		Cancel = function()
			return false
		end,
	})
	if GlobalMetricsProfile then
		GlobalMetricsProfile:Reconcile()
		GlobalMetricsProfile:AddUserId(0)
		GlobalMetricsProfile.Data.Spent = GlobalMetricsProfile.Data.Spent or {}
		GlobalMetricsProfile.Data.Purchases = GlobalMetricsProfile.Data.Purchases or {}
		GlobalMetricsProfile.Data.Donated = GlobalMetricsProfile.Data.Donated or {}
		DataManager.GlobalMetrics = GlobalMetricsProfile
		Signals.DataManagerLoaded:Fire()
	end
end)

for _, player in Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = DataManager.Profiles[player]
	if profile then
		profile:EndSession()
		DataManager.Profiles[player] = nil
	end
end)

game:BindToClose(function()
	if GlobalMetricsProfile then
		GlobalMetricsProfile:EndSession()
	end
end)
