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

-- Context
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext

-- Cache
local productInfoCache: { [number]: any } = {}

local function createScrollingFrame(props: {
	cart: { number } | {},
	likedAccs: { number } | {},
	onAddItem: (number) -> (),
	onRemoveItem: (number) -> (),
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

	-- Load product info only when likedAccs list changes (and cache results)
	React.useEffect(function()
		if not props.likedAccs or #props.likedAccs == 0 then
			setIsLoading(false)
			setProductInfos({})
			return
		end

		setIsLoading(true)
		local newProductInfos = {}
		local loadedCount = 0
		local totalCount = #props.likedAccs
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

		for _, id in ipairs(props.likedAccs) do
			if productInfoCache[id] then
				newProductInfos[id] = productInfoCache[id]
				loadedCount += 1
				task.defer(tryUpdateState)
			else
				-- spawn to avoid blocking
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
	end, { props.likedAccs })

	React.useEffect(function()
		if props.likedAccs and #props.likedAccs > 0 then
			setIsWearing(OutfitHelper.isUsingAsset(Players.LocalPlayer, props.likedAccs))
		else
			setIsWearing({})
		end
	end, { props.likedAccs })

	-- Immediate optimistic toggle for try/takeoff (keeps UI snappy)
	local function toggleWearing(id: number, shouldWear: boolean)
		local fix = tonumber(id)
		setIsWearing(function(prev)
			local newWearing = table.clone(prev or {})
			newWearing[fix] = shouldWear
			return newWearing
		end)
	end

	-- Build children (memoized)
	local children = React.useMemo(function()
		local childElements = {
			React.createElement("UIGridLayout", {
				CellSize = UDim2.fromScale(0.4, 0.4),
				CellPadding = UDim2.fromScale(-0.2, 0.1),
				FillDirectionMaxCells = 4,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}

		if props.likedAccs then
			for index, id in ipairs(props.likedAccs) do
				local assetInfo = productInfos[id]
				if assetInfo and assetInfo.IsForSale then
					local inCart = table.find(props.cart or {}, id) ~= nil

					childElements["LikedAccessory" .. id] = React.createElement("Frame", {
						Name = "LikedAccessories" .. tostring(id),
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

							[React.Event.MouseEnter] = function()
								if props.current ~= id then
									props.setHovered(id)
								end
							end,

							[React.Event.MouseLeave] = function()
								if props.current ~= id then
									props.setHovered(nil)
								end
							end,

							[React.Event.Activated] = function()
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

									[React.Event.Activated] = function()
										Signals.BuyAccessory:Fire(id)
									end,
								}, {
									React.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
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
										toggleWearing(id, false)
										Signals.TakeOff:Fire(tonumber(id))
									end,
								}, {
									React.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
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
										toggleWearing(id, true)
										Signals.TryAccessory:Fire(id)
									end,
								}, {
									React.createElement("UICorner", { CornerRadius = UDim.new(0.2, 0) }),
								}),
								inCart and React.createElement("ImageButton", {
									Name = "RemoveCart" .. id,
									BackgroundTransparency = 1,
									Position = UDim2.fromScale(0.83, 0.28),
									Image = "rbxassetid://135209363113234",
									ImageColor3 = Color3.fromRGB(155, 155, 155),
									Size = UDim2.fromScale(0.3, 0.3),
									AnchorPoint = Vector2.new(0.5, 0.5),
									ZIndex = 2,

									[React.Event.Activated] = function()
										props.onRemoveItem(id)
										Signals.RemoveToCart:Fire(id)
									end,
								}) or React.createElement("ImageButton", {
									Name = "AddCart" .. id,
									Image = "rbxassetid://135209363113234",
									ImageColor3 = Color3.fromRGB(255, 255, 255),
									BackgroundTransparency = 1,
									Position = UDim2.fromScale(0.83, 0.28),
									Size = UDim2.fromScale(0.3, 0.3),
									AnchorPoint = Vector2.new(0.5, 0.5),
									ZIndex = 2,

									[React.Event.Activated] = function()
										props.onAddItem(id)
										Signals.AddToCart:Fire(id)
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

									[React.Event.Activated] = function()
										props.removeFromLikeds(id)
										Signals.UnlikeAccessory:Fire(id)
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

									[React.Event.Activated] = function()
										props.addToLikes(id)
										Signals.LikeAccessory:Fire(id)
									end,
								}),

								BackgroundFade = React.createElement("Frame", {
									Name = "Background",
									ZIndex = 1,
									Size = UDim2.fromScale(1, 1),
								}, {
									React.createElement("UICorner", { CornerRadius = UDim.new(0.1, 0) }),
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
		props.likedAccs,
		props.cart,
		props.hovered,
		isWearing,
	})

	if props.likedAccs and #props.likedAccs > 0 then
		return React.createElement("ScrollingFrame", {
			Size = UDim2.fromScale(0.95, 0.95),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			CanvasSize = UDim2.fromOffset(0, #props.likedAccs * 70),
			BackgroundTransparency = 1,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			VerticalScrollBarInset = Enum.ScrollBarInset.Always,
		}, children)
	end

	return nil
end

local function LikedAccessories(props: {
	cart: { number } | {},
	likedAccs: { number } | {},
	onAddItem: (number) -> (),
	onRemoveItem: (number) -> (),
	onClose: () -> (),
	removeFromLikeds: (id: number) -> (),
	addToLikes: (id: number) -> (),
}): Frame?
	local current, setCurrent = React.useState(nil)
	local hovered, setHovered = React.useState(nil)

	return React.createElement("Frame", {
		Name = "Liked Accessories",
		Size = UDim2.fromScale(0.8, 0.8),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Colors.primaryColor,
	}, {
		React.createElement("UICorner", { CornerRadius = UDim.new(0.05, 0) }),
		React.createElement("UIStroke", { Thickness = 4, Color = Colors.secondaryColor }),

		Name = React.createElement("Frame", {
			Name = "Name",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, -0.06),
			Size = UDim2.fromScale(0.4, 0.13),
			BackgroundColor3 = Colors.primaryColor,
		}, {
			React.createElement("UICorner", { CornerRadius = UDim.new(0.1, 0) }),
			Title = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				Text = "Liked Accessories",
				TextColor3 = Colors.textColor,
				TextScaled = true,
			}),
			React.createElement("UIStroke", { Thickness = 4, Color = Colors.secondaryColor }),
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
			React.createElement("UICorner", { CornerRadius = UDim.new(0.1, 0) }),
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
				cart = props.cart or {},
				onAddItem = props.onAddItem,
				onRemoveItem = props.onRemoveItem,
				setCurrent = setCurrent,
				current = current,
				hovered = hovered,
				setHovered = setHovered,
				removeFromLikeds = props.removeFromLikeds,
				addToLikes = props.addToLikes,
				likedAccs = props.likedAccs or {},
			}),
		}),
	})
end

local function LikedAccessoriesApp()
	local ui = useUIContext()
	local cart, setCart = React.useState({} :: { number })
	local likedAccs, setLikedsAccs = React.useState({} :: { number })

	local APP_NAME = "Liked Accessories"

	React.useEffect(function()
		if ui.activeApp == APP_NAME then
			local fetchedCart = Signals.GetCart:InvokeServer()
			local fetchedLikeds = Signals.GetLikedAccs:InvokeServer()
			if fetchedCart then
				setCart(fetchedCart)
			end
			if fetchedLikeds then
				setLikedsAccs(fetchedLikeds)
			end
		end
	end, { ui.activeApp })

	local addToLikes = React.useCallback(function(id: number)
		setLikedsAccs(function(prev)
			if table.find(prev, id) then
				return prev
			end
			local new = table.clone(prev)
			table.insert(new, id)
			return new
		end)
	end, {})

	local removeFromLikeds = React.useCallback(function(id: number)
		setLikedsAccs(function(prev)
			local new = {}
			for _, v in ipairs(prev) do
				if v ~= id then
					table.insert(new, v)
				end
			end
			return new
		end)
	end, {})

	local addToCart = React.useCallback(function(id: number)
		setCart(function(prev)
			if table.find(prev, id) then
				return prev
			end
			local new = table.clone(prev)
			table.insert(new, id)
			return new
		end)
	end, {})

	local removeFromCart = React.useCallback(function(id: number)
		setCart(function(prev)
			local new = {}
			for _, v in ipairs(prev) do
				if v ~= id then
					table.insert(new, v)
				end
			end
			return new
		end)
	end, {})

	return if ui.activeApp == APP_NAME
		then React.createElement(LikedAccessories, {
			cart = cart,
			onAddItem = addToCart,
			onRemoveItem = removeFromCart,
			likedAccs = likedAccs,
			removeFromLikeds = removeFromLikeds,
			addToLikes = addToLikes,

			onClose = function()
				ui.closeApp()
			end,
		})
		else nil
end

return LikedAccessoriesApp
