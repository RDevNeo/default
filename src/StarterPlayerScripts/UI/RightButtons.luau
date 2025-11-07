-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Dependencies
local Colors = require("./Colors")
local React = require(ReplicatedStorage.Packages.React)
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local HoverSound = ReplicatedStorage:WaitForChild("HoverSound") :: Sound

local createButtons = function(props: { Name: string, APP_NAME: string, Order: number })
	local ui = useUIContext()

	local size, setSize = ReactFlow.useSpring({
		start = UDim2.fromScale(0.9, 0.07),
		target = UDim2.fromScale(0.9, 0.07),
		speed = 18,
		damper = 0.8,
	})

	local function onHover()
		setSize({
			target = UDim2.fromScale(1, 0.08),
		})
		HoverSound:Play()
	end

	local function onUnhover()
		setSize({
			target = UDim2.fromScale(0.9, 0.07),
		})
	end

	return React.createElement("TextButton", {
		Size = size,
		Name = props.Name,
		BackgroundColor3 = Colors.primaryColor,
		TextColor3 = Colors.textColor,
		Font = Enum.Font.FredokaOne,
		Text = props.Name,
		TextScaled = true,
		LayoutOrder = props.Order,

		[React.Event.MouseEnter] = onHover,
		[React.Event.MouseLeave] = onUnhover,

		[React.Event.Activated] = function(rbx)
			ui.openApp(props.APP_NAME)
		end,
	}, {
		React.createElement("UICorner", {
			CornerRadius = UDim.new(0.2, 0),
		}),

		React.createElement("UIStroke", {
			Thickness = 2,
			Color = Colors.accentColor,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),

		React.createElement("UIPadding", {
			PaddingTop = UDim.new(0.02, 0),
			PaddingBottom = UDim.new(0.02, 0),
			PaddingRight = UDim.new(0.02, 0),
			PaddingLeft = UDim.new(0.02, 0),
		}),
	})
end

local function ShopApp()
	local ui = useUIContext()

	return if ui.activeApp == nil
		then React.createElement("Frame", {
			Name = "LeftButtons",
			Size = UDim2.fromScale(0.18, 1),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.82, 0.5),
			BackgroundTransparency = 1,
		}, {
			React.createElement("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0.02, 0),
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			SearchOutfit = React.createElement(
				createButtons,
				{ Name = "Search Outfit", APP_NAME = "Search Outfit", Order = 1 }
			),

			ShoppingCart = React.createElement(
				createButtons,
				{ Name = "Shopping Cart", APP_NAME = "Shopping Cart", Order = 2 }
			),

			LikedAccessories = React.createElement(
				createButtons,
				{ Name = "Liked Accessories", APP_NAME = "Liked Accessories", Order = 3 }
			),

			SaveToRoblox = React.createElement(
				createButtons,
				{ Name = "Save To Roblox", APP_NAME = "Save To Roblox", Order = 4 }
			),
		})
		else nil
end

return ShopApp
