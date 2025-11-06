-- Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

-- Dependencies
local Webhook = require(ServerStorage.Source.Webook.Handler)

local recentlyTeleportedPlayers = {}
local currentPlaceName = nil

local function handlePortal(portal: Instance)
	print("Processing portal " .. portal.Name)
	if not portal:IsA("Model") then
		error("Portal " .. portal.Name .. " is not a Model")
	end

	local portalPlaceId = portal:FindFirstChild("TARGET_PLACE_ID")
	if not portalPlaceId then
		error("Portal " .. portal.Name .. " does not have a TARGET_PLACE_ID")
	end

	if not portalPlaceId:IsA("IntValue") then
		error("Portal " .. portal.Name .. " does not have a TARGET_PLACE_ID that is an IntValue")
	end

	if portalPlaceId.Value == 0 then
		error("Portal " .. portal.Name .. " does not have a TARGET_PLACE_ID that is not 0")
	end

	for index, instance in ipairs(portal:GetDescendants()) do
		if instance:IsA("ImageLabel") then
			instance.Image = "rbxthumb://type=Asset&id=" .. portalPlaceId.Value .. "&w=420&h=420"
		end
	end

	local portalGameName = nil

	-- Checking to see if the model has a TextLabel on it.
	for index, instance in ipairs(portal:GetDescendants()) do
		if instance:IsA("TextLabel") then
			local success, result = pcall(function()
				return game:GetService("MarketplaceService"):GetProductInfo(portalPlaceId.Value)
			end)
			if success and result then
				instance.Text = result.Name
				portalGameName = result.Name
			end
		end
	end

	-- Setting up the teleporter part
	local teleporter = Instance.new("Part")
	teleporter.Size = Vector3.new(9, 15, 2)
	teleporter.CFrame = portal:GetPivot() * CFrame.Angles(0, math.rad(90), 0)
	teleporter.Anchored = true
	teleporter.Parent = portal
	teleporter.Transparency = 0.8

	teleporter.Touched:Connect(function(part)
		local player = Players:GetPlayerFromCharacter(part.Parent)

		if not player then
			return
		end

		-- Checking if the player has recently teleported (avoid calling the teleport unnecessary)
		if recentlyTeleportedPlayers[player] then
			print("debouncing")
			return
		end

		Webhook.notifyPortalUsage({
			playerId = player.UserId,
			playerName = player.Name,
			portalGameName = portalGameName or "Unknown",
			currentPlaceName = currentPlaceName or "Unknown",
		})

		-- Adding the player to the recently teleported players table
		recentlyTeleportedPlayers[player] = true

		-- Removing after 5 second (It works like a debounce)
		task.delay(5, function()
			recentlyTeleportedPlayers[player] = nil
		end)

		TeleportService:Teleport(portalPlaceId.Value, player)
	end)
end

local portals = CollectionService:GetTagged("Portal")
for _, portal in portals do
	handlePortal(portal)
end

CollectionService:GetInstanceAddedSignal("Portal"):Connect(handlePortal)

local ok, info = pcall(function()
	return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
end)

if ok and info then
	currentPlaceName = info.Name
else
	error("Failed to get current place name")
end
