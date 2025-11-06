local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)
local Net = require(ReplicatedStorage.Packages.Net)

local Outfits = Net:Invoke("GetOutfits")

for index, value in pairs(Outfits) do
	local Click: ClickDetector = value["Click"]
	local Prompt: ProximityPrompt = value["Prompt"]
	local Highlight: Highlight = value["Highlight"]
	local Code: string = value["Code"]
	local Model: Model = value["Model"]

	Click.MouseHoverEnter:Connect(function()
		Highlight.Enabled = true
	end)

	Click.MouseHoverLeave:Connect(function()
		Highlight.Enabled = false
	end)

	Prompt.PromptShown:Connect(function()
		Highlight.Enabled = true
	end)

	Prompt.PromptHidden:Connect(function()
		Highlight.Enabled = false
	end)

	Prompt.Triggered:Connect(function()
		Signals.OpenOutfit:Fire(Code, Model)
	end)

	Click.MouseClick:Connect(function()
		Signals.OpenOutfit:Fire(Code, Model)
	end)
end
