-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local OutfitHelper = require(ReplicatedStorage.Helpers.OutfitHelper)

local module = {}

local cache = {
	initialized = false,
	modelData = {},
	idToModels = {},
}

local function collectOutfitsFallback()
	local results = {}
	for _, v in ipairs(CollectionService:GetTagged("Outfit")) do
		if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
			table.insert(results, v)
		end
	end
	return results
end

local function buildCache(outfits)
	outfits = outfits or collectOutfitsFallback()
	assert(type(outfits) == "table", "buildCache expects an array/table of Models (outfits)")

	-- reset
	cache.modelData = {}
	cache.idToModels = {}

	for _, model in ipairs(outfits) do
		if typeof(model) == "Instance" and model:IsA("Model") then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local description = humanoid:GetAppliedDescription()
				local ids = OutfitHelper.getIds(description) or {}

				local idSet = {}
				local idList = {}

				for _, id in ipairs(ids) do
					local idStr = tostring(id)
					if not idSet[idStr] then
						idSet[idStr] = true
						table.insert(idList, idStr)

						cache.idToModels[idStr] = cache.idToModels[idStr] or {}
						table.insert(cache.idToModels[idStr], model)
					end
				end

				cache.modelData[model] = {
					idSet = idSet,
					idList = idList,
					size = #idList,
				}
			end
		end
	end

	cache.initialized = true
end

local function ensureCache(outfits)
	if not cache.initialized then
		buildCache(outfits)
	end
end

module.getRightModel = function(purchasedIds, outfits)
	ensureCache(outfits)

	local minMatches = 6

	if not purchasedIds or #purchasedIds == 0 then
		return nil, { matchCount = 0, matchRatio = 0, isOutfit = false, reason = "no_purchased_ids" }
	end

	local unique = {}
	for _, id in ipairs(purchasedIds) do
		if id ~= nil then
			unique[tostring(id)] = true
		end
	end

	local matchCounts = {}
	for idStr, _ in pairs(unique) do
		local models = cache.idToModels[idStr]
		if models then
			for _, model in ipairs(models) do
				matchCounts[model] = (matchCounts[model] or 0) + 1
			end
		end
	end

	if next(matchCounts) == nil then
		return nil, { matchCount = 0, matchRatio = 0, isOutfit = false, reason = "no_matches" }
	end

	local bestModel, bestCount, bestRatio = nil, -1, -1
	for model, count in pairs(matchCounts) do
		local data = cache.modelData[model]
		local size = (data and data.size) or 0
		local ratio = (size > 0) and (count / size) or 0

		if count > bestCount or (count == bestCount and ratio > bestRatio) then
			bestModel, bestCount, bestRatio = model, count, ratio
		end
	end

	local meta = {
		matchCount = bestCount,
		matchRatio = bestRatio,
		isOutfit = false,
		reason = "below_threshold",
	}

	if bestCount >= minMatches then
		meta.isOutfit = true
		meta.reason = "matched"
		return bestModel, meta
	end

	return nil, meta
end

module.emmitEffect = function(target: Model | Player)
	local baseModel
	if typeof(target) == "Instance" and target:IsA("Player") then
		baseModel = target.Character
	elseif typeof(target) == "Instance" and target:IsA("Model") then
		baseModel = target
	end

	local hrp = baseModel:FindFirstChild("HumanoidRootPart")
		or baseModel:FindFirstChildOfClass("BasePart")
		or baseModel.PrimaryPart

	local emitters = {}
	for _, obj in ipairs(hrp:GetDescendants()) do
		if obj:IsA("ParticleEmitter") then
			table.insert(emitters, obj)
		end
	end

	for _, e in ipairs(emitters) do
		e.Enabled = true
	end

	task.delay(7, function()
		for _, e in ipairs(emitters) do
			e.Enabled = false
		end
	end)
end

return module
