-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Dependencies
local React = require(ReplicatedStorage.Packages.React)
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)
local Net = require(ReplicatedStorage.Packages.Net)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)

-- Context
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext

-- Color
local Colors = require(StarterPlayer.StarterPlayerScripts.Source.UI.Colors)

type Outfit = {
	Name: string,
	Code: string,
	Model: Model,
	Prompt: ProximityPrompt,
	Click: ClickDetector,
	Highlight: Highlight,
	CameraPart: Part,
}

local function SearchOutfit()
	local code, setCode = React.useState(nil)
	local debounceRef = React.useRef(nil)
	local ui = useUIContext()
	local DEBOUNCE_SECONDS = 0.1
	local size, setSize = ReactFlow.useSpring({
		start = UDim2.fromScale(0, 0),
		target = UDim2.fromScale(0.5, 0.3),
		speed = 20,
		damper = 0.7,
	})

	local function onClose()
		setSize({ target = UDim2.fromScale(0, 0) })
		ui.closeApp()
	end

	React.useEffect(function()
		setSize({ target = UDim2.fromScale(0.5, 0.3) })
	end, {})

	local function debouncedFire(inputText: string?)
		setCode(inputText)

		if debounceRef.current ~= nil then
			task.cancel(debounceRef.current)
			debounceRef.current = nil
		end

		if inputText and inputText ~= "" then
			debounceRef.current = task.delay(DEBOUNCE_SECONDS, function()
				local Outfit: Outfit = Net:Invoke("GetModelByCode", string.upper(inputText))

				if Outfit then
					Signals.OpenFromSearch:Fire(Outfit.Code, Outfit.Model)
					debounceRef.current = nil
				else
					Signals.WarnSignal:Fire("No outfit with that code.")
					onClose()
				end
			end)
		end
	end

	return React.createElement("Frame", {
		Name = "Search Outfit",
		Size = size,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Colors.primaryColor,
	}, {
		React.createElement("UICorner", {
			CornerRadius = UDim.new(0.05, 0),
		}),

		React.createElement("UIStroke", {
			Thickness = 4,
			Color = Colors.secondaryColor,
		}),

		Name = React.createElement("Frame", {
			Name = "Name",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, -0.11),
			Size = UDim2.fromScale(0.5, 0.25),
			BackgroundColor3 = Colors.primaryColor,
		}, {
			React.createElement("UICorner", {
				CornerRadius = UDim.new(0.1, 0),
			}),
			Title = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				Text = "Search Outfit",
				TextColor3 = Colors.textColor,
				TextScaled = true,
			}),

			React.createElement("UIStroke", {
				Thickness = 4,
				Color = Colors.secondaryColor,
			}),
		}),

		CloseButton = React.createElement("TextButton", {
			Name = "CloseButton",
			Size = UDim2.fromScale(0.15, 0.15),
			Position = UDim2.fromScale(0.97, 0.06),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Colors.destructiveColor,
			Text = "X",
			TextColor3 = Colors.textColor,
			TextScaled = true,
			Font = Enum.Font.FredokaOne,

			[React.Event.Activated] = onClose,
		}, {
			React.createElement("UICorner", {
				CornerRadius = UDim.new(0.1, 0),
			}),
			React.createElement("UIStroke", {
				Thickness = 3,
				Color = Color3.new(
					math.clamp(Colors.destructiveColor.R * 0.5, 0, 1),
					math.clamp(Colors.destructiveColor.G * 0.5, 0, 1),
					math.clamp(Colors.destructiveColor.B * 0.5, 0, 1)
				),
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			React.createElement("UIAspectRatioConstraint"),
		}),

		InputCode = React.createElement("TextBox", {
			BackgroundColor3 = Colors.backgroundColor,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromScale(0.7, 0.3),
			Font = Enum.Font.FredokaOne,
			PlaceholderColor3 = Color3.new(
				math.clamp(Colors.textColor.R * 0.8, 0, 1),
				math.clamp(Colors.textColor.G * 0.8, 0, 1),
				math.clamp(Colors.textColor.B * 0.8, 0, 1)
			),
			TextColor3 = Colors.textColor,
			TextScaled = true,
			PlaceholderText = "Enter Code",
			Text = "",
			ClearTextOnFocus = false,

			[React.Event.FocusLost] = function(rbx)
				debouncedFire(rbx.Text)
			end,
		}, {
			React.createElement("UICorner", {
				CornerRadius = UDim.new(0.2, 0),
			}),
		}),

		SearchButton = React.createElement("TextButton", {
			BackgroundColor3 = Color3.new(
				math.clamp(Colors.primaryColor.R * 0.95, 0, 1),
				math.clamp(Colors.primaryColor.G * 0.95, 0, 1),
				math.clamp(Colors.primaryColor.B * 0.95, 0, 1)
			),
			Position = UDim2.fromScale(0.5, 0.75),
			Size = UDim2.fromScale(0.4, 0.18),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Font = Enum.Font.FredokaOne,
			TextScaled = true,
			TextColor3 = Colors.textColor,
			Text = "Search",
			ZIndex = 2,

			[React.Event.Activated] = function(rbx)
				if code and code ~= "" then
					debouncedFire(code)
				end
			end,
		}, {
			React.createElement("UICorner", {
				CornerRadius = UDim.new(0.2, 0),
			}),
			React.createElement("UIStroke", {
				Thickness = 2,
				Color = Colors.secondaryColor,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}),
	})
end

local function SearchOutfitApp()
	local ui = useUIContext()

	local APP_NAME = "Search Outfit"

	return if ui.activeApp == APP_NAME then React.createElement(SearchOutfit, {}) else nil
end

return SearchOutfitApp
