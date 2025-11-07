-- WarnApp.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local Signal = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)
local Colors = require(StarterPlayer.StarterPlayerScripts.Source.UI.Colors)
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext

local function WarnElement(props: {
	message: string,
	onClose: () -> (),
})
	local size, setSize = ReactFlow.useSpring({
		start = UDim2.fromScale(0, 0.1),
		target = UDim2.fromScale(0.5, 0.1),
		speed = 20,
		damper = 0.7,
	})

	React.useEffect(function()
		setSize({ target = UDim2.fromScale(0.5, 0.1) })

		local timeout = task.delay(5, function()
			setSize({ target = UDim2.fromScale(0, 0) })

			task.delay(0.3, function()
				if props.onClose then
					props.onClose()
				end
			end)
		end)

		return function()
			task.cancel(timeout)
		end
	end, {})

	return React.createElement("TextLabel", {
		Size = size,
		Position = UDim2.fromScale(0.5, 0.05),
		AnchorPoint = Vector2.new(0.5, 0),
		Text = props.message or "",
		TextColor3 = Colors.textColor,
		BackgroundColor3 = Colors.primaryColor,
		TextScaled = true,
		Font = Enum.Font.FredokaOne,
	}, {
		React.createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		React.createElement("UIStroke", {
			Thickness = 3,
			Color = Colors.accentColor,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	})
end

local function WarnApp()
	local message, setMessage = React.useState(nil)
	local isVisible, setVisible = React.useState(false)
	local ui = useUIContext()
	local APP_NAME = "Warn"

	local function onClose()
		setVisible(false)
		setMessage(nil)

		if ui.activeApp == APP_NAME then
			ui.closeApp()
		end
	end

	React.useEffect(function()
		local connection = Signal.WarnSignal:Connect(function(msg)
			setMessage(msg)
			setVisible(true)
			ui.openApp(APP_NAME)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return if isVisible and message ~= nil
		then React.createElement(WarnElement, { message = message, onClose = onClose })
		else nil
end

return WarnApp
