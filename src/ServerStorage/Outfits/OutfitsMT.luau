local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Outfits = {}
Outfits.__index = Outfits

export type Outfit = {
	Name: string,
	Code: string,
	Model: Model,
	Prompt: ProximityPrompt,
	Click: ClickDetector,
	Highlight: Highlight,
	CameraPart: Part,
} & typeof(Outfits)

local allOutfits: { Outfit } = {}

function Outfits:IsOutfit(code: string): boolean
	if type(code) ~= "string" or code == "" then
		return false
	end

	for _, model in ipairs(CollectionService:GetTagged("Outfit")) do
		local modelCode = model:GetAttribute("Code")
		if typeof(modelCode) == "string" and string.lower(modelCode) == string.lower(code) then
			return true
		end
	end
	return false
end

function Outfits:GetOutfitByCode(code: string): Model?
	if type(code) ~= "string" or code == "" then
		return nil
	end

	for _, model in ipairs(CollectionService:GetTagged("Outfit")) do
		local modelCode = model:GetAttribute("Code")
		if typeof(modelCode) == "string" and string.lower(modelCode) == string.lower(code) then
			return model
		end
	end
	return nil
end

function Outfits:GetAllOutfits(): { Outfit }
	return allOutfits
end

function Outfits.new(model: Model): Outfit
	local self = setmetatable({}, Outfits)

	self.Model = model :: Model
	self.Name = model.Name :: string
	self.Code = model:GetAttribute("Code") :: string

	-- Proximity Prompt
	self.Prompt = Instance.new("ProximityPrompt", model) :: ProximityPrompt
	self.Prompt.UIOffset = Vector2.new(0, 200)
	self.Prompt.ActionText = "View Outfit"
	self.Prompt.RequiresLineOfSight = false

	-- Click Detector
	self.Click = Instance.new("ClickDetector", model) :: ClickDetector

	-- Highlight
	self.Highlight = Instance.new("Highlight", model) :: Highlight
	self.Highlight.FillColor = Color3.fromRGB(255, 255, 255)
	self.Highlight.FillTransparency = 0.9
	self.Highlight.Enabled = false

	-- Camera Part
	self.CameraPart = Instance.new("Part", model) :: Part
	self.CameraPart.Name = "cameraPart"
	self.CameraPart.Size = Vector3.new(1, 1, 1)
	self.CameraPart.Transparency = 1
	self.CameraPart.CanCollide = false
	self.CameraPart.CanTouch = false
	self.CameraPart.Anchored = true
	self.CameraPart:SetAttribute("Code", self.Code)
	local root = self.Model.PrimaryPart
	local offset = 4

	local pos = root.Position + (root.CFrame.LookVector * offset)
	local look = pos + root.CFrame.LookVector

	self.CameraPart:PivotTo(CFrame.new(pos, look))

	table.insert(allOutfits, self)

	return self
end

-- Populating
for _, model in ipairs(CollectionService:GetTagged("Outfit")) do
	Outfits.new(model)
end

return Outfits
