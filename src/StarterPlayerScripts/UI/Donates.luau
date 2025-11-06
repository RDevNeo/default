-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Dependencies
local React = require(ReplicatedStorage.Packages.React)
local Colors = require(StarterPlayer.StarterPlayerScripts.Source.UI.Colors)
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)
local Net = require(ReplicatedStorage.Packages.Net)

-- Context
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext

local function createButtons()
	local int, setInt = React.useState({} :: { IntValue? })

	React.useEffect(function()
		setInt(Net:Invoke("GetIntValues"))
	end, {})

	local children = React.useMemo(function()
		local childElements = {
			React.createElement("UIGridLayout", {
				CellSize = UDim2.fromScale(0.75, 0.09),
				CellPadding = UDim2.fromScale(0, 0.03),
				FillDirectionMaxCells = 1,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),

			React.createElement("UIPadding", {
				PaddingTop = UDim.new(0.02, 0),
			}),
		}

		if int then
			for index, donateInfo in ipairs(int) do
				table.insert(
					childElements,
					React.createElement("TextButton", {
						Name = donateInfo.name,
						LayoutOrder = index,
						BackgroundColor3 = Colors.secondaryColor,
						TextColor3 = Colors.textColor,
						TextScaled = true,
						Font = Enum.Font.FredokaOne,

						Text = utf8.char(0xE002) .. tostring(donateInfo.amount),

						[React.Event.Activated] = function()
							Signals.OnDonateClicked:FireServer(donateInfo.id, donateInfo.amount)
						end,
					}, {
						React.createElement("UICorner", {
							CornerRadius = UDim.new(0.05, 0),
						}),

						React.createElement("UIStroke", {
							Thickness = 4,
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = Color3.new(
								math.clamp(Colors.secondaryColor.R * 0.5, 0, 1),
								math.clamp(Colors.secondaryColor.G * 0.5, 0, 1),
								math.clamp(Colors.secondaryColor.B * 0.5, 0, 1)
							),
						}),
					})
				)
			end
		end
		return childElements
	end, { int })

	if int then
		return React.createElement("ScrollingFrame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(1, 0.8),
			Position = UDim2.fromScale(0.5, 0.48),
			CanvasSize = UDim2.fromOffset(0, #int * 50),
			BackgroundTransparency = 1,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			VerticalScrollBarInset = Enum.ScrollBarInset.Always,
			BorderSizePixel = 0,
		}, children)
	end
	return nil
end

local function Donates(props: {
	onClose: () -> (),
	quantity: number,
})
	return React.createElement("Frame", {
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(0.35, 0.8),
		BackgroundColor3 = Colors.primaryColor,
		Name = "Donates",
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
			Position = UDim2.fromScale(0.5, -0.06),
			Size = UDim2.fromScale(0.6, 0.13),
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
				Text = "Donates",
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
			Size = UDim2.fromScale(0.08, 0.08),
			Position = UDim2.fromScale(0.97, 0.02),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Colors.destructiveColor,
			Text = "X",
			TextColor3 = Colors.textColor,
			TextScaled = true,
			Font = Enum.Font.FredokaOne,

			[React.Event.Activated] = props.onClose,
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

		DonateYou = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.49, 0.92),
			Size = UDim2.fromScale(0.74, 0.13),
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			Text = "Total Donated" .. utf8.char(0xE002) .. tostring(props.quantity),
			TextColor3 = Colors.textColor,
			TextScaled = true,
		}, {
			React.createElement("UICorner", {
				CornerRadius = UDim.new(0.05, 0),
			}),

			React.createElement("UIStroke", {
				Thickness = 4,
				Color = Colors.secondaryColor,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),

			React.createElement("UIPadding", {
				PaddingTop = UDim.new(0.02, 0),
				PaddingBottom = UDim.new(0.02, 0),
				PaddingLeft = UDim.new(0.02, 0),
				PaddingRight = UDim.new(0.02, 0),
			}),
		}),

		ScrollingFrame = React.createElement(createButtons),
	})
end

local function DonatesApp()
	local ui = useUIContext()
	local APP_NAME = "Donates"
	local quantity = Net:Invoke("GetDonatedValue")

	return if ui.activeApp == APP_NAME
		then React.createElement(Donates, {
			onClose = function()
				ui.closeApp()
			end,
			quantity = quantity,
		})
		else nil
end

return DonatesApp
