-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Dependencies
local React = require(ReplicatedStorage.Packages.React)
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)
local OutfitHelper = require(ReplicatedStorage.Helpers.OutfitHelper)

-- Context
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext

-- Color
local Colors = require(StarterPlayer.StarterPlayerScripts.Source.UI.Colors)

local productInfoCache: { [number]: any } = {}

local function createScrollingFrame(props: {
	ids: { number },
	onRemoveItem: (number) -> (),
	setTotalCost: (number) -> number,
	setCurrent: (number?) -> number?,
	current: number?,
	hovered: number?,
	setHovered: (number?) -> number?,
})
	local productInfos, setProductInfos = React.useState({} :: { [number]: any })
	local _isLoading, setIsLoading = React.useState(true)
	local isWearing, setIsWearing = React.useState(nil)

	-- Load product info only when ids change
	React.useEffect(function()
		if not props.ids or #props.ids == 0 then
			setIsLoading(false)
			setProductInfos({})
			return
		end

		setIsLoading(true)
		local newProductInfos = {}
		local loadedCount = 0
		local totalCount = #props.ids
		local cancelled = false
		local hasUpdated = false

		local function tryUpdateState()
			if cancelled or hasUpdated then
				return
			end
			if loadedCount >= totalCount then
				hasUpdated = true
				setProductInfos(newProductInfos)
				setIsLoading(false)
			end
		end

		for _, id in props.ids do
			if productInfoCache[id] then
				newProductInfos[id] = productInfoCache[id]
				loadedCount += 1
				task.defer(tryUpdateState)
			else
				task.spawn(function()
					local success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id)
					if success and info then
						productInfoCache[id] = info
						newProductInfos[id] = info
					end
					loadedCount += 1
					task.defer(tryUpdateState)
				end)
			end
		end

		return function()
			cancelled = true
		end
	end, { props.ids })

	-- Calculate cost
	local totalCost = React.useMemo(function()
		local cost = 0
		for id, assetInfo in pairs(productInfos) do
			if assetInfo and assetInfo.IsForSale and table.find(props.ids, id) then
				cost += assetInfo.PriceInRobux
			end
		end
		return cost
	end, { productInfos, props.ids })

	-- Update isWearing
	React.useEffect(function()
		if props.ids and #props.ids > 0 then
			setIsWearing(OutfitHelper.isUsingAsset(Players.LocalPlayer, props.ids))
		end
	end, { props.ids })

	local function toggleWearing(id: number, shouldWear: boolean)
		local fix = tonumber(id)
		setIsWearing(function(prev)
			local newWearing = table.clone(prev or {})
			newWearing[fix] = shouldWear
			return newWearing
		end)
	end

	-- Update parent with total cost
	React.useEffect(function()
		props.setTotalCost(totalCost)
	end, { totalCost })

	-- Memoize children to prevent unnecessary re-renders
	local children = React.useMemo(function()
		local childElements = {
			React.createElement("UIGridLayout", {
				CellSize = UDim2.fromScale(0.4, 0.4),
				CellPadding = UDim2.fromScale(-0.2, 0.1),
				FillDirectionMaxCells = 4,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}

		if props.ids then
			for index, id in pairs(props.ids) do
				local assetInfo = productInfos[id]
				if assetInfo and assetInfo.IsForSale then
					childElements["OutfitButton" .. id] = React.createElement("Frame", {
						Name = "ShoppingCart" .. tostring(id),
						BackgroundTransparency = 1,
					}, {

						React.createElement("UIAspectRatioConstraint"),

						ShowInfo = React.createElement("TextButton", {
							Size = UDim2.fromScale(0.8, 0.8),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.43),
							BackgroundTransparency = 0.9,
							BackgroundColor3 = Colors.backgroundColor,
							Text = "",
							LayoutOrder = 1,

							[React.Event.MouseEnter] = function(instance: TextButton)
								if props.current ~= id then
									props.setHovered(id)
								end
							end,

							[React.Event.MouseLeave] = function(instance: TextButton)
								if props.current ~= id then
									props.setHovered(nil)
								end
							end,

							[React.Event.Activated] = function(instance: TextButton)
								if props.current == id then
									props.setCurrent(nil)
								else
									props.setCurrent(id)

									if props.setHovered then
										props.setHovered(nil)
									end
								end
							end,
						}, {
							OutfitImage = React.createElement("ImageLabel", {
								Name = "OutfitImage",
								Position = UDim2.fromScale(0.5, 0.5),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Size = UDim2.fromScale(1, 1),
								BackgroundTransparency = 1,
								Image = string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", id),
								ZIndex = 1,
							}, {
								React.createElement("UIAspectRatioConstraint"),
							}),

							Corner = React.createElement("UICorner", {
								CornerRadius = UDim.new(0.1, 0),
							}),

							Stroke = React.createElement("UIStroke", {
								Thickness = 2,
								ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
								Color = Colors.accentColor,
							}),

							React.createElement("UIAspectRatioConstraint"),

							props.current == id and React.createElement("Frame", {
								Name = "ButtonsHolder",
								Size = UDim2.fromScale(1, 1),
								BackgroundTransparency = 1,
							}, {

								BuyAccessory = React.createElement("TextButton", {
									Name = "BuyButton" .. id,
									BackgroundColor3 = Color3.fromRGB(54, 187, 21),
									Position = UDim2.fromScale(0.35, 0.28),
									Size = UDim2.fromScale(0.62, 0.25),
									Text = "BUY",
									TextColor3 = Color3.fromRGB(48, 48, 48),
									TextScaled = true,
									Font = Enum.Font.FredokaOne,
									AnchorPoint = Vector2.new(0.5, 0.5),
									ZIndex = 2,

									[React.Event.Activated] = function(instance)
										Signals.BuyAccessory:Fire(id)
									end,
								}, {

									React.createElement("UICorner", {
										CornerRadius = UDim.new(0.2, 0),
									}),
								}),

								(isWearing and isWearing[id] == true) and React.createElement("TextButton", {
									Name = "TakeOffButton" .. id,
									BackgroundColor3 = Color3.fromRGB(161, 73, 73),
									Position = UDim2.fromScale(0.35, 0.65),
									Size = UDim2.fromScale(0.62, 0.25),
									Text = "TAKE OFF",
									TextColor3 = Color3.fromRGB(48, 48, 48),
									TextScaled = true,
									Font = Enum.Font.FredokaOne,
									AnchorPoint = Vector2.new(0.5, 0.5),
									ZIndex = 2,

									[React.Event.Activated] = function()
										Signals.TakeOff:Fire(tonumber(id))
										toggleWearing(id, false)
									end,
								}, {
									React.createElement("UICorner", {
										CornerRadius = UDim.new(0.2, 0),
									}),
								}) or React.createElement("TextButton", {
									Name = "TryButton" .. id,
									BackgroundColor3 = Color3.fromRGB(54, 187, 21),
									Position = UDim2.fromScale(0.35, 0.65),
									Size = UDim2.fromScale(0.62, 0.25),
									Text = "TRY",
									TextColor3 = Color3.fromRGB(48, 48, 48),
									TextScaled = true,
									Font = Enum.Font.FredokaOne,
									AnchorPoint = Vector2.new(0.5, 0.5),
									ZIndex = 2,

									[React.Event.Activated] = function()
										Signals.TryAccessory:Fire(id)
										toggleWearing(id, true)
									end,
								}, {
									React.createElement("UICorner", {
										CornerRadius = UDim.new(0.2, 0),
									}),
								}),

								RemoveToCart = React.createElement("TextButton", {
									Name = "RemoveToCart" .. id,
									BackgroundColor3 = Color3.fromRGB(161, 73, 73),
									Position = UDim2.fromScale(0.83, 0.5),
									Size = UDim2.fromScale(0.25, 0.25),
									Text = "Remove",
									TextColor3 = Color3.fromRGB(48, 48, 48),
									TextScaled = true,
									Font = Enum.Font.FredokaOne,
									AnchorPoint = Vector2.new(0.5, 0.5),
									ZIndex = 2,

									[React.Event.Activated] = function(instance: TextButton)
										Signals.RemoveToCart:Fire(id)
										props.onRemoveItem(id)
									end,
								}, {

									React.createElement("UICorner", {
										CornerRadius = UDim.new(0.2, 0),
									}),
								}),

								BackgroundFade = React.createElement("Frame", {
									Name = "Background",
									ZIndex = 1,
									Size = UDim2.fromScale(1, 1),
								}, {
									Corner = React.createElement("UICorner", {
										CornerRadius = UDim.new(0.1, 0),
									}),

									React.createElement("UIGradient", {
										Rotation = 90,
										Color = ColorSequence.new({
											ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
											ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
										}),
										Transparency = NumberSequence.new({
											NumberSequenceKeypoint.new(0, 1),
											NumberSequenceKeypoint.new(0.333, 0.840),
											NumberSequenceKeypoint.new(0.647, 0.440),
											NumberSequenceKeypoint.new(1, 0.175),
										}),
									}),
								}),
							}),

							props.hovered == id and React.createElement("ImageButton", {
								Size = UDim2.fromScale(0.3, 0.3),
								BackgroundTransparency = 1,
								Image = "rbxassetid://97542709722551",

								[React.Event.MouseEnter] = function(instance: ImageButton)
									instance.ImageColor3 = Color3.fromRGB(255, 170, 0)
								end,

								[React.Event.MouseLeave] = function(instance: ImageButton)
									instance.ImageColor3 = Color3.fromRGB(255, 255, 255)
								end,

								[React.Event.Activated] = function(instance: ImageButton)
									Signals.LikeAccessory:Fire(id)
									instance.ImageColor3 = Color3.fromRGB(255, 170, 0)
								end,
							}),
						}),

						OutfitName = React.createElement("TextLabel", {
							Name = "OutfitName",
							Size = UDim2.fromScale(0.8, 0.21),
							Position = UDim2.fromScale(0.5, 0.83),
							BackgroundTransparency = 1,
							Font = Enum.Font.FredokaOne,
							Text = assetInfo.Name or "Loading...",
							TextColor3 = Colors.textColor,
							TextScaled = true,
							LayoutOrder = 2,
							AnchorPoint = Vector2.new(0.5, 0),
							TextXAlignment = Enum.TextXAlignment.Left,
						}),

						OutfitPrice = React.createElement("TextLabel", {
							Name = "OutfitPrice",
							Size = UDim2.fromScale(0.8, 0.13),
							Position = UDim2.fromScale(0.5, 1.04),
							BackgroundTransparency = 1,
							Font = Enum.Font.FredokaOne,
							TextColor3 = Colors.textColor,
							Text = utf8.char(0xE002) .. assetInfo.PriceInRobux,
							TextScaled = true,
							LayoutOrder = 3,
							AnchorPoint = Vector2.new(0.5, 0),
							TextXAlignment = Enum.TextXAlignment.Left,
						}),
					})
				end
			end
		end

		return childElements
	end, { productInfos, props.current, props.ids, props.hovered, isWearing })

	if props.ids and #props.ids > 0 then
		return React.createElement("ScrollingFrame", {
			Size = UDim2.fromScale(0.95, 0.95),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			CanvasSize = UDim2.fromOffset(0, #props.ids * 70),
			BackgroundTransparency = 1,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			VerticalScrollBarInset = Enum.ScrollBarInset.Always,
		}, children)
	end
	return nil
end

local function ShoppingCart(props: {
	cart: { number } | {},
	onRemoveItem: (number) -> (),
	removeAll: () -> (),
	onClose: () -> (),
}): Frame?
	local totalCost, setTotalCost = React.useState(0)
	local current, setCurrent = React.useState(nil)
	local hovered, setHovered = React.useState(nil)

	return React.createElement("Frame", {
		Name = "Shopping Cart",
		Size = UDim2.fromScale(0.8, 0.8),
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
			Position = UDim2.fromScale(0.5, -0.06),
			Size = UDim2.fromScale(0.4, 0.13),
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
				Text = "Shopping Cart",
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
			Size = UDim2.fromScale(0.04, 0.07),
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

		Body = React.createElement("Frame", {
			Name = "Body",
			Size = UDim2.fromScale(0.95, 0.6),
			Position = UDim2.fromScale(0.5, 0.45),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			ScrollingFrame = React.createElement(createScrollingFrame, {
				ids = props.cart,
				onRemoveItem = props.onRemoveItem,
				setTotalCost = setTotalCost,
				setCurrent = setCurrent,
				current = current,
				hovered = hovered,
				setHovered = setHovered,
			}),
		}),

		Footer = React.createElement("Frame", {
			Name = "Footer",
			Size = UDim2.fromScale(0.95, 0.2),
			Position = UDim2.fromScale(0.5, 0.88),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		}, {
			TotalItems = React.createElement("TextLabel", {
				Position = UDim2.fromScale(0, 0.38),
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromScale(0.4, 0.4),
				Text = "Total Items: " .. tostring(#props.cart) .. "/20",
				BackgroundTransparency = 1,
				TextScaled = true,
				Font = Enum.Font.FredokaOne,
				TextColor3 = Colors.textColor,
			}),
			TotalRobux = React.createElement("TextLabel", {
				Position = UDim2.fromScale(0, 0.65),
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromScale(0.4, 0.25),
				BackgroundTransparency = 1,
				Text = tostring(totalCost) .. utf8.char(0xE002),
				TextScaled = true,
				Font = Enum.Font.FredokaOne,
				TextColor3 = Color3.fromRGB(134, 134, 134),
			}),

			RemoveAll = React.createElement("TextButton", {
				BackgroundColor3 = Colors.destructiveColor,
				TextColor3 = Colors.textColor,
				Text = "Remove All",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0.55, 0.5),
				Size = UDim2.fromScale(0.2, 0.5),
				TextScaled = true,
				Font = Enum.Font.FredokaOne,

				[React.Event.Activated] = function(rbx)
					props.removeAll()
					Signals.RemoveToCart:Fire(props.cart)
				end,
			}, {
				React.createElement("UICorner", {
					CornerRadius = UDim.new(0.1, 0),
				}),

				React.createElement("UIPadding", {
					PaddingTop = UDim.new(0.02, 0),
					PaddingBottom = UDim.new(0.02, 0),
					PaddingRight = UDim.new(0.02, 0),
					PaddingLeft = UDim.new(0.02, 0),
				}),

				React.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Thickness = 4,
					Color = Color3.new(
						math.clamp(Colors.destructiveColor.R * 0.5, 0, 1),
						math.clamp(Colors.destructiveColor.G * 0.5, 0, 1),
						math.clamp(Colors.destructiveColor.B * 0.5, 0, 1)
					),
				}),
			}),

			BuyAllButton = React.createElement("TextButton", {
				BackgroundColor3 = Colors.foregroundColor,
				TextColor3 = Colors.textColor,
				Text = "Buy All",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0.78, 0.5),
				Size = UDim2.fromScale(0.2, 0.5),
				TextScaled = true,
				Font = Enum.Font.FredokaOne,
			}, {
				React.createElement("UICorner", {
					CornerRadius = UDim.new(0.1, 0),
				}),

				React.createElement("UIPadding", {
					PaddingTop = UDim.new(0.02, 0),
					PaddingBottom = UDim.new(0.02, 0),
					PaddingRight = UDim.new(0.02, 0),
					PaddingLeft = UDim.new(0.02, 0),
				}),

				React.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Thickness = 4,
					Color = Color3.new(
						math.clamp(Colors.foregroundColor.R * 0.5, 0, 1),
						math.clamp(Colors.foregroundColor.G * 0.5, 0, 1),
						math.clamp(Colors.foregroundColor.B * 0.5, 0, 1)
					),
				}),
			}),
		}),
	})
end

local function ShoppingCartApp()
	local ui = useUIContext()
	local cart, setCart = React.useState({} :: { number })
	local hasFetchedCart, setHasFetchedCart = React.useState(false)

	local APP_NAME = "Shopping Cart"

	-- Only fetch cart when app is opened and hasn't been fetched yet
	React.useEffect(function()
		if ui.activeApp == APP_NAME and not hasFetchedCart then
			local fetchedCart = Signals.GetCart:InvokeServer()
			if fetchedCart then
				setCart(fetchedCart)
				setHasFetchedCart(true)
			end
		end
	end, { ui.activeApp })

	-- Reset fetch flag when app closes
	React.useEffect(function()
		if ui.activeApp ~= APP_NAME then
			setHasFetchedCart(false)
		end
	end, { ui.activeApp })

	-- Handle removing items from cart
	local removeFromCart = React.useCallback(function(id: number)
		setCart(function(prevCart)
			local newCart = {}
			for _, itemId in ipairs(prevCart) do
				if itemId ~= id then
					table.insert(newCart, itemId)
				end
			end
			return newCart
		end)
	end, {})

	local removeAll = function()
		setCart({})
	end

	return if ui.activeApp == APP_NAME
		then React.createElement(ShoppingCart, {
			cart = cart,
			onRemoveItem = removeFromCart,
			removeAll = removeAll,

			onClose = function()
				ui.closeApp()
			end,
		})
		else nil
end

return ShoppingCartApp
