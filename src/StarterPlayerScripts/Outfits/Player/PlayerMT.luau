-- Services
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

-- Dependencies
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)

-- Variables
local LocalPlayer = Players.LocalPlayer

local PlayerMT = {}
PlayerMT.__index = PlayerMT

type playerMt = {
	Prompt: ProximityPrompt,
	Character: Model,
	Player: Player,
	Code: string,
}

local allPlayers: { playerMt } = {}

function PlayerMT.new(player: Player): playerMt?
	if player == LocalPlayer then
		return nil
	end

	local self = setmetatable({}, PlayerMT)

	self.Player = player
	self.Character = player.Character or player.CharacterAdded:Wait()
	self.Character.Archivable = true

	local hrp = self.Character:WaitForChild("HumanoidRootPart")

	self.Prompt = Instance.new("ProximityPrompt")
	self.Prompt.Parent = hrp
	self.Prompt.ActionText = "View Outfit"
	self.Prompt.Name = "PlayerPrompt"
	self.Prompt.RequiresLineOfSight = false

	self.Code = player.Name

	self.Prompt.Triggered:Connect(function(playerWhoTriggered)
		Signals.OpenFromPlayer:Fire(self.Code, self.Character:Clone())
	end)

	table.insert(allPlayers, self)
	return self
end

function PlayerMT.Remove(player: Player)
	for i, stored in ipairs(allPlayers) do
		if stored.Player == player then
			if stored.Prompt then
				stored.Prompt:Destroy()
			end
			table.remove(allPlayers, i)
			break
		end
	end
end

function PlayerMT.GetAllPlayers(): { playerMt }
	return allPlayers
end

-- Set up for players already in the server when script runs
for _, plr in ipairs(Players:GetPlayers()) do
	PlayerMT.new(plr)
	if plr:IsInGroup(995190819) then
		plr:SetAttribute("IsInGroup", true)
	end
end

return PlayerMT
