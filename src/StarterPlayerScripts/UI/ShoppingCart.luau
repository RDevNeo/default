-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Dependencies
local React = require(ReplicatedStorage.Packages.React)
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)
local OutfitHelper = require(ReplicatedStorage.Helpers.OutfitHelper)
local Colors = require(StarterPlayer.StarterPlayerScripts.Source.UI.Colors)
local Net = require(ReplicatedStorage.Packages.Net)

-- Context
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext

-- Cache
local productInfoCache: { [number]: any } = {}

local function createScrollingFrame(props: {
	ids: { number },
	likedAccs: { number } | {},
	onRemoveItem: (number) -> (),
	setTotalCost: (number) -> number,
	setCurrent: (number?) -> number?,
	current: number?,
	hovered: number?,
	setHovered: (number?) -> number?,
	removeFromLikeds: (number) -> (),
	addToLikes: (number) -> (),
})
	local productInfos, setProductInfos = React.useState({} :: { [number]: any })
	local _isLoading, setIsLoading = React.useState(true)
	local isWearing, setIsWearing = React.useState(nil)

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

	local totalCost = React.useMemo(function()
		local cost = 0
		for id, assetInfo in pairs(productInfos) do
			if assetInfo and assetInfo.IsForSale and table.find(props.ids, id) then
				cost += assetInfo.PriceInRobux
			end
		end
		return cost
	end, { productInfos, props.ids })

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

	React.useEffect(function()
		props.setTotalCost(totalCost)
	end, { totalCost })

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
										Signals.PromptSinglePurchase:Fire(id)
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
										Signals.TakeOff:FireServer(tonumber(id))
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
										Signals.TryAccessory:FireServer(id)
										toggleWearing(id, true)
									end,
								}, {
									React.createElement("UICorner", {
										CornerRadius = UDim.new(0.2, 0),
									}),
								}),

								RemoveToCart = React.createElement("ImageButton", {
									Name = "RemoveCart" .. id,
									BackgroundTransparency = 1,
									Position = UDim2.fromScale(0.83, 0.28),
									Image = "rbxassetid://135209363113234",
									ImageColor3 = Color3.fromRGB(155, 155, 155),
									Size = UDim2.fromScale(0.3, 0.3),
									AnchorPoint = Vector2.new(0.5, 0.5),
									ZIndex = 2,

									[React.Event.Activated] = function(instance)
										Signals.RemoveToCart:FireServer(id)
										props.onRemoveItem(id)
									end,
								}),

								(table.find(props.likedAccs, id) ~= nil) and React.createElement("ImageButton", {
									Name = "RemoveLikes" .. id,
									BackgroundTransparency = 1,
									Position = UDim2.fromScale(0.83, 0.65),
									Image = "rbxassetid://97542709722551",
									ImageColor3 = Color3.fromRGB(255, 255, 0),
									Size = UDim2.fromScale(0.3, 0.3),
									AnchorPoint = Vector2.new(0.5, 0.5),
									ZIndex = 2,

									[React.Event.Activated] = function(instance)
										Signals.UnlikeAccessory:FireServer(id)
										props.removeFromLikeds(id)
									end,
								}) or React.createElement("ImageButton", {
									Name = "AddLike" .. id,
									Image = "rbxassetid://97542709722551",
									ImageColor3 = Color3.fromRGB(255, 255, 255),
									BackgroundTransparency = 1,
									Position = UDim2.fromScale(0.83, 0.65),
									Size = UDim2.fromScale(0.3, 0.3),
									AnchorPoint = Vector2.new(0.5, 0.5),
									ZIndex = 2,

									[React.Event.Activated] = function(instance)
										Signals.LikeAccessory:FireServer(id)
										props.addToLikes(id)
									end,
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
	end, {
		productInfos,
		props.current,
		props.ids,
		props.hovered,
		isWearing,
		props.addToLikes,
		props.removeFromLikeds,
		props.likedAccs,
	})

	if props.ids and #props.ids > 0 then
		return React.createElement("ScrollingFrame", {
			Size = UDim2.fromScale(0.95, 0.95),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			CanvasSize = UDim2.fromOffset(0, #props.ids * 70),
			BackgroundTransparency = 1,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			VerticalScrollBarInset = Enum.ScrollBarInset.Always,
			BorderSizePixel = 0,
		}, children)
	end
	return nil
end

local function ShoppingCart(props: {
	cart: { number } | {},
	likedAccs: { number } | {},
	onRemoveItem: (number) -> (),
	removeAll: () -> (),
	onClose: () -> (),
	removeFromLikeds: (id: number) -> (),
	addToLikes: (id: number) -> (),
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
				removeFromLikeds = props.removeFromLikeds,
				addToLikes = props.addToLikes,
				likedAccs = props.likedAccs,
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
					Signals.RemoveToCart:FireServer(props.cart)
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
	local likedAccs, setLikedsAccs = React.useState({} :: { number })
	local APP_NAME = "Shopping Cart"
	React.useEffect(function()
		if ui.activeApp == APP_NAME then
			local fetchedCart = Net:Invoke("GetCart")
			local fetchedLikeds = Net:Invoke("GetLikedAccs")
			if fetchedCart and fetchedLikeds then
				setCart(fetchedCart)
				setLikedsAccs(fetchedLikeds)
			end
		end
	end, { ui.activeApp })
	local removeFromLikeds = React.useCallback(function(id: number)
		setLikedsAccs(function(prevLiked)
			local newCart = {}
			for _, itemId in ipairs(prevLiked) do
				if itemId ~= id then
					table.insert(newCart, itemId)
				end
			end
			return newCart
		end)
	end, {})
	local addToLikes = React.useCallback(function(id: number)
		setLikedsAccs(function(prevLiked)
			if table.find(prevLiked, id) ~= nil then
				return prevLiked
			end
			local newCart = table.clone(prevLiked)
			table.insert(newCart, id)
			return newCart
		end)
	end, {})
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
			likedAccs = likedAccs,
			removeFromLikeds = removeFromLikeds,
			addToLikes = addToLikes,
			onClose = function()
				ui.closeApp()
			end,
		})
		else nil
end

return ShoppingCartApp
