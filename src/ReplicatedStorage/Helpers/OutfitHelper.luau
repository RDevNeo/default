local module = {}

-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local AvatarEditorService = game:GetService("AvatarEditorService")

-- Modules
local GeneralAssetTypes = require(script.Parent.AssetTypes)
local Accessories = require(script.Parent.Accessories)
local Animations = require(script.Parent.Animations)
local BodyParts = require(script.Parent.BodyParts)
local Clothing = require(script.Parent.Clothing)
local LayeredClothing = require(script.Parent.LayeredClothing)
local AssetTypesConversionList = { GeneralAssetTypes, LayeredClothing, Accessories, Clothing, BodyParts, Animations }

local function RetrieveHumanoidDescriptionEquivalent(assetTypeName)
	for _, conversionInfo in pairs(AssetTypesConversionList) do
		if type(conversionInfo) == "table" then
			local typesTable = conversionInfo.AssetTypes or conversionInfo

			if type(typesTable) == "table" then
				if typesTable[assetTypeName] then
					return typesTable[assetTypeName]
				end

				for key, value in pairs(typesTable) do
					if value == assetTypeName then
						return value
					end
				end
			end
		end
	end

	return nil
end

module.addAccessory = function(reference: Player | Model, Id: number)
	local Character
	local Humanoid
	local HumanoidDescription

	if reference:IsA("Player") then
		Character = reference.Character or reference.CharacterAdded:Wait()
	else
		Character = reference
	end

	Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then
		warn("[addAccessory] No Humanoid found in character:", Character.Name)
		return
	end

	HumanoidDescription = Humanoid:FindFirstChildOfClass("HumanoidDescription")
	if not HumanoidDescription then
		HumanoidDescription = Instance.new("HumanoidDescription")
		HumanoidDescription.Name = "HumanoidDescription"
		HumanoidDescription.Parent = Humanoid
	end

	local success, ItemDetails = pcall(function()
		return MarketplaceService:GetProductInfo(Id, Enum.InfoType.Asset)
	end)

	if not success or not ItemDetails then
		warn("[addAccessory] Failed to get item info for assetId:", Id)
		return
	end

	local AssetTypeName = GeneralAssetTypes[ItemDetails.AssetTypeId]

	if not AssetTypeName then
		warn("[addAccessory] Unknown asset type:", ItemDetails.AssetTypeId)
		return
	end

	if LayeredClothing.AssetTypes[AssetTypeName] then
		local AccessoryBlob = HumanoidDescription:GetAccessories(true)
		local AccessoryType = Enum.AccessoryType[string.gsub(AssetTypeName, "Accessory", "")]

		local ToAdd = {
			["AccessoryType"] = AccessoryType,
			["AssetId"] = Id,
			["IsLayered"] = true,
			["Order"] = #AccessoryBlob,
		}

		table.insert(AccessoryBlob, ToAdd)
		HumanoidDescription:SetAccessories(AccessoryBlob, true)
	elseif Accessories.AssetTypes[AssetTypeName] then
		local Property = RetrieveHumanoidDescriptionEquivalent(AssetTypeName)
		if HumanoidDescription[Property] == "" then
			HumanoidDescription[Property] = tostring(Id)
		else
			HumanoidDescription[Property] = Id
		end
	else
		local Property = RetrieveHumanoidDescriptionEquivalent(AssetTypeName)
		HumanoidDescription[Property] = Id
	end

	local CheckedHumanoidDescription = AvatarEditorService:CheckApplyDefaultClothing(HumanoidDescription)
	Humanoid:ApplyDescriptionReset(CheckedHumanoidDescription or HumanoidDescription)
end

module.removeAccessory = function(reference: Player | Model, Id: number)
	local Character
	local Humanoid
	local HumanoidDescription

	if reference:IsA("Player") then
		Character = reference.Character or reference.CharacterAdded:Wait()
	else
		Character = reference
	end

	Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then
		warn("[removeAccessory] No Humanoid found in character:", Character.Name)
		return
	end

	HumanoidDescription = Humanoid:GetAppliedDescription()
	if not HumanoidDescription then
		warn("[removeAccessory] No HumanoidDescription found or applied for:", Character.Name)
		return
	end

	local success, ItemDetails = pcall(function()
		return MarketplaceService:GetProductInfo(Id, Enum.InfoType.Asset)
	end)
	if not success or not ItemDetails then
		warn("[removeAccessory] Failed to get item info for assetId:", Id)
		return
	end

	local AssetTypeName = GeneralAssetTypes[ItemDetails.AssetTypeId]
	if not AssetTypeName then
		warn("[removeAccessory] Unknown asset type:", ItemDetails.AssetTypeId)
		return
	end

	if LayeredClothing.AssetTypes[AssetTypeName] then
		local AccessoryBlob = HumanoidDescription:GetAccessories(true)

		for index, details in ipairs(AccessoryBlob) do
			if details.AssetId == Id then
				print(Id)
				table.remove(AccessoryBlob, index)
				break
			end
		end

		HumanoidDescription:SetAccessories(AccessoryBlob, true)
	else
		local Property = RetrieveHumanoidDescriptionEquivalent(AssetTypeName)
		if not Property or not HumanoidDescription[Property] then
			return
		end

		local updated = tostring(HumanoidDescription[Property])
		updated = updated:gsub("(^,)", "")
		updated = updated:gsub("," .. Id, "")
		updated = updated:gsub(Id .. ",", "")
		updated = updated:gsub(tostring(Id), "")
		updated = updated:gsub(",+", ",")
		updated = updated:gsub("^,", "")
		updated = updated:gsub(",$", "")

		HumanoidDescription[Property] = updated
	end

	local CheckedHumanoidDescription = AvatarEditorService:CheckApplyDefaultClothing(HumanoidDescription)
	Humanoid:ApplyDescriptionReset(CheckedHumanoidDescription or HumanoidDescription)
end

module.getIds = function(humanoidDescription: HumanoidDescription): { number }
	local ids: { number } = {}

	local accessories = humanoidDescription:GetAccessories(true)

	for _, accessoryDetails in pairs(accessories) do
		table.insert(ids, accessoryDetails.AssetId)
	end

	-- Get face (1)
	if humanoidDescription.Face ~= 0 then
		table.insert(ids, humanoidDescription.Face)
	end

	-- Get shirt (1)
	if humanoidDescription.Shirt ~= 0 then
		table.insert(ids, humanoidDescription.Shirt)
	end

	-- Get tshirt (1)
	if humanoidDescription.GraphicTShirt ~= 0 then
		table.insert(ids, humanoidDescription.GraphicTShirt)
	end

	-- Get pants (1)
	if humanoidDescription.Pants ~= 0 then
		table.insert(ids, humanoidDescription.Pants)
	end

	return ids
end

module.isUsingAsset = function(humanoidDesc: HumanoidDescription, assetId: number | { number })
	local ids = module.getIds(humanoidDesc)

	local lookup = {}
	for _, v in pairs(ids) do
		lookup[v] = true
	end

	if type(assetId) == "number" then
		return lookup[tonumber(assetId)] == true
	end

	local results = {}
	for _, id in pairs(assetId) do
		id = tonumber(id)
		results[id] = lookup[id] == true
	end

	return results
end

return module
