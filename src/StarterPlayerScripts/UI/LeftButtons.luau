-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Dependencies
local React = require(ReplicatedStorage.Packages.React)
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext

local function ShopApp()
	local ui = useUIContext()
	local APP_NAME = "LeftButtons"

	React.useEffect(function()
		local connection = Signals.PlayerEntered:Connect(function()
			--ui.openApp(APP_NAME)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return if ui.activeApp == APP_NAME
		then React.createElement("Frame", {
			Name = "LeftButtons",
			Size = UDim2.fromScale(0.16, 1),
			Position = UDim2.fromScale(0.84, 0),
		}, {})
		else nil
end

return ShopApp
