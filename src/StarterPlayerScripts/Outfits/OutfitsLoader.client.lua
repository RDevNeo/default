local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Dependencies
local Net = require(ReplicatedStorage.Packages.Net)

local DEFAULT_INBOUND_RADIUS = 75
local DEFAULT_MODEL_RANGE = Net:Invoke("GetPlayerModelRange")
local DEFAULT_HYSTERESIS_BUFFER = 2
local DEFAULT_UPDATE_INTERVAL = 0.1
local DEFAULT_CHUNK_SIZE = 50

local localPlayer = Players.LocalPlayer

local inboundRadius = DEFAULT_INBOUND_RADIUS
local modelRange = DEFAULT_MODEL_RANGE
local hysteresisBuffer = DEFAULT_HYSTERESIS_BUFFER
local updateInterval = DEFAULT_UPDATE_INTERVAL
local chunkSize = DEFAULT_CHUNK_SIZE

local lastUpdateTime = 0
local outfitsStates = {}
local scannerIndex = 1
local allModels = {}
local desiredInRange = {}
local running = false
local heartbeatConnection

local STATE_WS = "WS"
local STATE_STORAGE = "storage"

local function safeSetParent(instance, parent, maxRetries, delay)
	maxRetries = maxRetries or 3
	delay = delay or 0.05
	for i = 1, maxRetries do
		local ok, _ = pcall(function()
			instance.Parent = parent
		end)
		if ok then
			return true
		end
		task.wait(delay)
	end
	warn("safeSetParent failed for", instance, "->", parent)
	return false
end

local function ensureInboundPart(character)
	if not character then
		return nil
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end

	local inboundPart = hrp:FindFirstChild("InboundPart")
	if not inboundPart then
		inboundPart = Instance.new("Part")
		inboundPart.Name = "InboundPart"
		inboundPart.Size = Vector3.new(inboundRadius * 2, 0.5, inboundRadius * 2)
		inboundPart.CanCollide = false
		inboundPart.Transparency = 1
		inboundPart.Massless = true
		inboundPart.Anchored = false
		inboundPart.Parent = hrp
	end

	inboundPart.CFrame = hrp.CFrame

	return inboundPart
end

local function rebuildModelCache()
	allModels = {}

	for _, model in ipairs(CollectionService:GetTagged("Outfit")) do
		if model:IsA("Model") then
			table.insert(allModels, model)

			if model.Parent ~= Workspace and model.Parent ~= ReplicatedStorage then
				model.Parent = ReplicatedStorage
			end
		end
	end

	scannerIndex = 1
end

local function startScannerLoop()
	if running then
		return
	end
	running = true

	rebuildModelCache()
	desiredInRange = {}

	local inboundPart = ensureInboundPart(localPlayer.Character)
	if inboundPart then
		inboundPart.Anchored = true
	end

	lastUpdateTime = 0
	scannerIndex = 1

	heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		if not running then
			return
		end

		lastUpdateTime = lastUpdateTime + dt
		if lastUpdateTime < updateInterval then
			return
		end
		lastUpdateTime = 0

		local character = localPlayer and localPlayer.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				if not inboundPart or not inboundPart.Parent then
					inboundPart = ensureInboundPart(character)
					if inboundPart then
						inboundPart.Anchored = true
					end
				end
				if inboundPart and hrp then
					inboundPart.CFrame = hrp.CFrame
				end
			end
		else
			return
		end

		local inboundPos = inboundPart and inboundPart.Position
		if not inboundPos then
			return
		end

		if #allModels == 0 then
			rebuildModelCache()
			return
		end

		local processed = 0
		while processed < chunkSize and scannerIndex <= #allModels do
			local m = allModels[scannerIndex]
			scannerIndex = scannerIndex + 1
			processed = processed + 1

			if m and m:IsA("Model") then
				if m.PrimaryPart and m.PrimaryPart:IsA("BasePart") then
					local dx = m.PrimaryPart.Position - inboundPos
					local distSq = dx:Dot(dx)

					local thr = modelRange
					if outfitsStates[m] == STATE_WS then
						thr = thr + hysteresisBuffer
					end
					local thrSq = thr * thr

					desiredInRange[m] = (distSq <= thrSq)
				else
					desiredInRange[m] = false
				end
			else
				desiredInRange[m] = false
			end
		end

		if scannerIndex > #allModels then
			for _, m in ipairs(allModels) do
				local shouldBeInWorld = desiredInRange[m] == true
				local currentParent = m and m.Parent

				if shouldBeInWorld and currentParent ~= Workspace then
					local ok = safeSetParent(m, Workspace, 4, 0.05)
					if ok then
						outfitsStates[m] = STATE_WS
					end
				elseif not shouldBeInWorld and currentParent ~= ReplicatedStorage then
					local ok = safeSetParent(m, ReplicatedStorage, 4, 0.05)
					if ok then
						outfitsStates[m] = STATE_STORAGE
					end
				end
			end

			scannerIndex = 1
			desiredInRange = {}
		end
	end)
end

local function stopScannerLoop()
	running = false
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
	outfitsStates = {}
	allModels = {}
	desiredInRange = {}
	scannerIndex = 1
end

local function resetAllModels()
	for _, m in ipairs(Workspace:GetChildren()) do
		if m:IsA("Model") then
			safeSetParent(m, ReplicatedStorage, 4, 0.05)
			outfitsStates[m] = STATE_STORAGE
		end
	end
end

local function onCharacterAdded(character)
	task.defer(function()
		ensureInboundPart(character)
		rebuildModelCache()
	end)

	startScannerLoop()

	-- Detect death to reset models
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			stopScannerLoop()
			resetAllModels()
		end)
	end

	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			stopScannerLoop()
			resetAllModels()
		end
	end)
end

if localPlayer then
	localPlayer.CharacterAdded:Connect(onCharacterAdded)
	if localPlayer.Character then
		onCharacterAdded(localPlayer.Character)
	end
end
