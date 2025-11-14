-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TeleportService = game:GetService("TeleportService")

-- Dependencies
local Topbar = require(ReplicatedStorage.Packages.TopBarPlus)
local React = require(ReplicatedStorage.Packages.React)
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)
local Colors = require(StarterPlayer.StarterPlayerScripts.Source.UI.Colors)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local Net = require(ReplicatedStorage.Packages.Net)

local HoverSound = ReplicatedStorage:WaitForChild("HoverSound") :: Sound

-- Context
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext

local APP_NAME = "TeleportMenu"

-- Create Topbar Icon
local TeleportIcon = Topbar.new()
TeleportIcon:setLabel("Teleports")
TeleportIcon:setName("Teleport")

local GameThumbnailCache = {}

local function createScrollingFrame()
	local data, setData = React.useState(nil)

	React.useEffect(function()
		setData(Net:Invoke("GetGamesIds"))
	end, {})

	local children = React.useMemo(function()
		local childElements = {
			UIListLayout = React.createElement("UIGridLayout", {
				CellSize = UDim2.fromScale(0.45, 0.45),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				FillDirectionMaxCells = 2,
				SortOrder = Enum.SortOrder.LayoutOrder,
				CellPadding = UDim2.fromScale(0.1, 0.07),
			}),
		}

		if data and data.data then
			for index, value in ipairs(data.data) do
				local gameName = value.name
				local gameId = value.id
				local placeId = value.rootPlace.id

				if placeId ~= game.PlaceId and #gameName > 5 and gameId ~= game.GameId then
					local thumbnailId = GameThumbnailCache[gameId]

					if not thumbnailId then
						local thumbnailData = Net:Invoke("GetGameThumbnail", gameId)

						if thumbnailData and thumbnailData.data and thumbnailData.data[1] then
							thumbnailId = thumbnailData.data[1].imageId
						else
							thumbnailId = 0
						end

						GameThumbnailCache[gameId] = thumbnailId
					end

					childElements["Item_" .. index] = React.createElement("TextButton", {
						Size = UDim2.new(0.3, 0, 0.1, 0),
						BackgroundColor3 = Colors.secondaryColor,
						LayoutOrder = index,
						BorderSizePixel = 0,
						Text = "",

						[React.Event.MouseEnter] = function(rbx)
							HoverSound:Play()
						end,

						[React.Event.Activated] = function(rbx)
							TeleportService:Teleport(placeId)
						end,
					}, {

						AspectRatio = React.createElement("UIAspectRatioConstraint"),
						React.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
						React.createElement(
							"UIStroke",
							{ Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Colors.accentColor }
						),

						GroupImage = React.createElement("ImageLabel", {
							Size = UDim2.fromScale(0.75, 0.75),
							Position = UDim2.fromScale(0.5, 0.5),
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							Image = "rbxthumb://type=Asset&id=" .. thumbnailId .. "&w=420&h=420",
						}, {
							React.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
						}),

						Name = React.createElement("TextLabel", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0),
							Size = UDim2.fromScale(0.8, 0.2),
							BackgroundColor3 = Colors.accentColor,
							TextColor3 = Colors.textColor,
							Text = gameName,
							ZIndex = 2,
							Font = Enum.Font.FredokaOne,
							TextScaled = true,
						}, {
							React.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
							React.createElement("UIPadding", {
								PaddingTop = UDim.new(0.05, 0),
								PaddingBottom = UDim.new(0.05, 0),
								PaddingLeft = UDim.new(0.05, 0),
								PaddingRight = UDim.new(0.05, 0),
							}),
							React.createElement("UIStroke", {
								Thickness = 3,
								ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
								Color = Colors.accentColor,
							}),
						}),
					})
				end
			end
		end

		return childElements
	end, { data })

	if data and data.data then
		return React.createElement("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.fromOffset(0, #data.data * 80),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			ScrollingDirection = Enum.ScrollingDirection.Y,
		}, children)
	end
	return nil
end

local function TeleportMenu()
	local ui = useUIContext()
	local size, setSize = ReactFlow.useSpring({
		start = UDim2.fromScale(0, 0),
		target = UDim2.fromScale(0.3, 0.7),
		speed = 20,
		damper = 0.7,
	})

	local function onClose()
		setSize({ target = UDim2.fromScale(0, 0) })
		ui.closeApp()
	end

	React.useEffect(function()
		setSize({ target = UDim2.fromScale(0.3, 0.7) })
	end, {})

	return React.createElement("Frame", {
		Size = size,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Colors.primaryColor,
		BorderSizePixel = 0,
	}, {
		React.createElement("UIStroke", {
			Thickness = 4,
			Color = Colors.secondaryColor,
		}),
		React.createElement("UICorner", {
			CornerRadius = UDim.new(0.05, 0),
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
				Text = "Teleport Menu",
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

			[React.Event.Activated] = function(rbx)
				onClose()
			end,
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

		Body = React.createElement("Frame", {
			Size = UDim2.fromScale(0.8, 0.8),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.55),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			ScrollingFrame = React.createElement(createScrollingFrame),
		}),
	})
end

TeleportIcon:bindEvent("selected", function()
	Signals.OpenTeleportMenu:Fire(true)
end)

TeleportIcon:bindEvent("deselected", function()
	Signals.OpenTeleportMenu:Fire(false)
end)

local function TeleportMenuApp()
	local ui = useUIContext()
	local _, setOpen = React.useState(nil)

	local function onClose()
		TeleportIcon:deselect()
		setOpen(false)
		ui.closeApp()
	end

	React.useEffect(function()
		local connection = Signals.OpenTeleportMenu:Connect(function(isOpen: boolean)
			setOpen(isOpen)

			if isOpen then
				ui.openApp(APP_NAME)
			else
				onClose()
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	if ui.activeApp == APP_NAME then
		return React.createElement(TeleportMenu)
	end
	return nil
end

return TeleportMenuApp
