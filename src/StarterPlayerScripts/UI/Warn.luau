local StarterPlayer = game:GetService("StarterPlayer")

local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)

Signals.Warn:Connect(function(msg: string)
	print(msg)
end)
