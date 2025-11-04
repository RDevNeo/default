local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local Signals = require(ServerScriptService.Source.CommsInit.Module)

local Outfits = {}
Outfits.__index = Outfits

type Outfit = {
	Name: string,
	Code: string,
	Model: Model,
	Prompt: ProximityPrompt,
	Click: ClickDetector,
	Highlight: Highlight,
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

	-- Logics
	self.Prompt.PromptShown:Connect(function()
		self.Highlight.Enabled = true
	end)

	self.Prompt.PromptHidden:Connect(function()
		self.Highlight.Enabled = false
	end)

	self.Prompt.Triggered:Connect(function(player)
		Signals.OpenOutfit:Fire(player, self.Code)
	end)

	self.Click.MouseClick:Connect(function(playerWhoTriggered)
		Signals.OpenOutfit:Fire(playerWhoTriggered, self.Code)
	end)

	self.Click.MouseHoverEnter:Connect(function()
		self.Highlight.Enabled = true
	end)

	self.Click.MouseHoverLeave:Connect(function()
		self.Highlight.Enabled = false
	end)

	table.insert(allOutfits, self)

	return self
end

-- Populating
for _, model in ipairs(CollectionService:GetTagged("Outfit")) do
	Outfits.new(model)
end

-- Single connection for outfit code lookups (avoid per-instance duplication)
Signals.OutfitCodeInputed:Connect(function(player: Player, code: string)
	if player and code then
		if Outfits:IsOutfit(code) then
			Signals.OpenOutfit:Fire(player, string.upper(code))
		else
			local msg = "No Outfit found with that code!"
			Signals.Warn:Fire(player, msg)
			return
		end
	end
end)

-- Function to get all the model clothes or the desc

-- Function to get all the items (accs and clothes) in the formated table to prompt purchase.

return Outfits
