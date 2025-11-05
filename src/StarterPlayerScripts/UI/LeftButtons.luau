-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

-- Dependencies
local Colors = require(StarterPlayer.StarterPlayerScripts.Source.UI.Colors)
local React = require(ReplicatedStorage.Packages.React)
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local Humanoid = character.Humanoid :: Humanoid

local createButton = function(
	props: {
		Name: string, -- dynamic text label (reactive)
		Order: number,
		onPress: ((Instance?) -> ())?,
	}
)
	return React.createElement("TextButton", {
		Size = UDim2.fromScale(0.9, 0.07),
		Name = props.Name,
		BackgroundColor3 = Colors.primaryColor,
		TextColor3 = Colors.textColor,
		Font = Enum.Font.FredokaOne,
		Text = props.Name,
		TextScaled = true,
		LayoutOrder = props.Order,

		[React.Event.Activated] = function(rbx)
			if props.onPress then
				props.onPress(rbx)
			end
		end,
	}, {
		UICorner = React.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
		UIStroke = React.createElement("UIStroke", {
			Thickness = 2,
			Color = Colors.accentColor,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		UIPadding = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0.02, 0),
			PaddingBottom = UDim.new(0.02, 0),
			PaddingRight = UDim.new(0.02, 0),
			PaddingLeft = UDim.new(0.02, 0),
		}),
	})
end

local function ShopApp()
	local run, setRun = React.useState(false)
	local ui = useUIContext()

	local function toggleRun()
		setRun(function(prev)
			return not prev
		end)
	end

	React.useEffect(function()
		if run then
			Humanoid.WalkSpeed = Signals.GetRunConfig:InvokeServer()
		else
			Humanoid.WalkSpeed = 16
		end
	end, { run })

	React.useEffect(function()
		local connection = UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.LeftShift then
				toggleRun()
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return if ui.activeApp == nil
		then React.createElement("Frame", {
			Name = "RightButtons",
			Size = UDim2.fromScale(0.16, 1),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			BackgroundTransparency = 1,
		}, {
			UIListLayout = React.createElement("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0.02, 0),
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			Run = React.createElement(createButton, {
				Name = run and "Walk" or "Run",
				Order = 4,
				onPress = toggleRun,
			}),

			Donate = React.createElement(createButton, { Name = "Donate", Order = 1, onPress = print }),
			Likes = React.createElement(createButton, { Name = "Likes", Order = 2, onPress = print }),
			Reset = React.createElement(createButton, { Name = "Reset", Order = 3, onPress = print }),
			MusicOff = React.createElement(createButton, { Name = "Toggle Music", Order = 5, onPress = print }),
		})
		else nil
end

return ShopApp
