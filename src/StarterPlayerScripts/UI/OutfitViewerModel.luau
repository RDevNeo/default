-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Dependencies
local React = require(ReplicatedStorage.Packages.React)
local OutfitHelper = require(ReplicatedStorage.Helpers.OutfitHelper)
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)
local Colors = require(StarterPlayer.StarterPlayerScripts.Source.UI.Colors)
local Net = require(ReplicatedStorage.Packages.Net)

-- Context
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext

-- Cache
local productInfoCache: { [number]: any } = {}

local function createScrollingFrame(props: {
	ids: { number },
	cart: { number },
	likedAccs: { number },
	current: number?,
	hovered: number?,
	removeFromLikeds: (id: number) -> (),
	addToLikes: (id: number) -> (),
	addToCart: (id: number) -> (),
	removeFromCart: (number) -> (),
	setHovered: (number?) -> number?,
	setTotalCost: (number) -> number,
	setCurrent: (number?) -> number?,
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
		local newProductInfos: { [number]: any } = {}
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

		for _, id in pairs(props.ids) do
			if productInfoCache[id] then
				newProductInfos[id] = productInfoCache[id]
				loadedCount += 1
				task.defer(tryUpdateState)
			else
				task.spawn(function()
					local success, assetInfo = pcall(function()
						return MarketplaceService:GetProductInfo(id)
					end)

					if success and assetInfo then
						productInfoCache[id] = assetInfo
						newProductInfos[id] = assetInfo
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

	React.useEffect(function() end)

	local totalCost = React.useMemo(function()
		local cost = 0
		for id, assetInfo in pairs(productInfos) do
			if assetInfo and assetInfo.IsForSale then
				cost += assetInfo.PriceInRobux
			end
		end
		return cost
	end, { productInfos })

	React.useEffect(function()
		props.setTotalCost(totalCost)
	end, { totalCost })

	local children = React.useMemo(function()
		local childElements = {
			React.createElement("UIGridLayout", {
				CellSize = UDim2.fromScale(0.25, 0.25),
				CellPadding = UDim2.fromScale(0, 0.05),
				FillDirectionMaxCells = 4,
			}),
			React.createElement("UIPadding", {
				PaddingTop = UDim.new(0.02, 0),
				PaddingRight = UDim.new(0.05, 0),
			}),
		}

		if props.ids then
			for index, id in pairs(props.ids) do
				local assetInfo = productInfos[id]
				if assetInfo and assetInfo.IsForSale then
					childElements["OutfitButton" .. id] = React.createElement("Frame", {
						Name = "OutfitViewerFrame" .. tostring(id),
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

								(table.find(props.cart, id) ~= nil)
										and React.createElement("ImageButton", {
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
												props.removeFromCart(id)
											end,
											-- Add to Cart
										})
									or React.createElement("ImageButton", {
										Name = "AddCart" .. id,
										Image = "rbxassetid://135209363113234",
										ImageColor3 = Color3.fromRGB(255, 255, 255),
										BackgroundTransparency = 1,
										Position = UDim2.fromScale(0.83, 0.28),
										Size = UDim2.fromScale(0.3, 0.3),
										AnchorPoint = Vector2.new(0.5, 0.5),
										ZIndex = 2,

										[React.Event.Activated] = function(instance)
											Signals.AddToCart:FireServer(id)
											props.addToCart(id)
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
		props.cart,
		props.likedAccs,
		props.addToLikes,
		props.removeFromLikeds,
	})

	if props.ids then
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

local function OutfitViewer(props: {
	code: string,
	model: Model,
	cart: { number },
	removeFromCart: (number) -> (),
	likedAccs: { number },
	addToLikes: (number) -> (),
	removeFromLikeds: (number) -> (),
	addToCart: (id: number) -> (),
	onClose: () -> (),
	likeOutfit: (string) -> (),
	unlikeOutfit: (string) -> (),
	likedOutfits: { string },
	outfitLikes: string,
}): Frame?
	local viewportRef = React.useRef(nil)
	local modelRef = React.useRef(nil :: Model?)
	local ids, setIds = React.useState(nil :: { number }?)
	local totalCost, setTotalCost = React.useState(0)
	local current, setCurrent = React.useState(nil :: number?)
	local hovered, setHovered = React.useState(nil :: number?)
	local isLiked = table.find(props.likedOutfits, props.code) ~= nil
	local likes, setLikes = React.useState(props.outfitLikes)

	React.useEffect(function()
		local viewportFrame = viewportRef.current
		if not viewportFrame then
			return
		end

		if modelRef.current then
			modelRef.current:Destroy()
			modelRef.current = nil
		end

		local model = props.model:Clone()

		modelRef.current = model
		if model then
			model.Parent = viewportFrame
			model:PivotTo(CFrame.new(0, 0.8, -6) * CFrame.Angles(0, math.rad(180), 0))

			setIds(OutfitHelper.getIds(model.Humanoid:GetAppliedDescription()))
		end

		return function()
			if modelRef.current then
				modelRef.current:Destroy()
				modelRef.current = nil
			end
		end
	end, { props.code })

	return React.createElement("Frame", {
		Name = "OutfitViewer",
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
				Text = "Outfit Viewer",
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
			Size = UDim2.fromScale(1, 0.8),
			Position = UDim2.fromScale(0, 0.1),
			BackgroundTransparency = 1,
		}, {

			React.createElement("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				ItemLineAlignment = Enum.ItemLineAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10),
			}),

			OutfitFrame = React.createElement("Frame", {
				Size = UDim2.fromScale(0.3, 0.95),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {

				LikesText = React.createElement("TextLabel", {
					Position = UDim2.fromScale(0.5, -0.014),
					AnchorPoint = Vector2.new(0.5, 0),
					Size = UDim2.fromScale(0.4, 0.06),
					BackgroundColor3 = Colors.accentColor,
					TextColor3 = Colors.textColor,
					ZIndex = 2,
					TextScaled = true,
					Text = likes .. " Likes",
					Font = Enum.Font.FredokaOne,
				}, {
					React.createElement("UICorner", {
						CornerRadius = UDim.new(0.1, 0),
					}),

					React.createElement("UIStroke", {
						Thickness = 4,
						Color = Colors.secondaryColor,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}),

				ViewportFrame = React.createElement("ViewportFrame", {
					Size = UDim2.fromScale(0.95, 0.95),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					ref = viewportRef,
					BackgroundTransparency = 0,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				}, {
					React.createElement("UICorner", {
						CornerRadius = UDim.new(0.1, 0),
					}),

					React.createElement("UIStroke", {
						Thickness = 4,
						Color = Colors.secondaryColor,
					}),

					React.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(212, 138, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(243, 225, 255)),
						}),
						Rotation = -90,
					}),

					isLiked and props.code and React.createElement("ImageButton", {
						Name = "Liked",
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						Image = "rbxassetid://113364820523022",
						Position = UDim2.fromScale(0.78, 0.02),
						Size = UDim2.fromScale(0.15, 0.12),
						BackgroundTransparency = 1,

						[React.Event.Activated] = function(rbx)
							props.unlikeOutfit(props.code)
							Signals.RemoveOutfitLike:FireServer(props.code)
							setLikes(likes - 1)
						end,
					}) or React.createElement("ImageButton", {
						Name = "Not Liked",
						Image = "rbxassetid://113364820523022",
						ImageColor3 = Color3.fromRGB(40, 40, 40),
						Position = UDim2.fromScale(0.78, 0.02),
						Size = UDim2.fromScale(0.15, 0.12),
						BackgroundTransparency = 1,

						[React.Event.Activated] = function(rbx)
							props.likeOutfit(props.code)
							Signals.AddOutfitLike:FireServer(props.code)
							setLikes(likes + 1)
						end,
					}),
				}),

				BuyOutfit = React.createElement("TextButton", {
					Size = UDim2.fromScale(0.35, 0.08),
					Position = UDim2.fromScale(0.1, 0.85),
					BackgroundColor3 = Color3.fromRGB(69, 190, 77),
					Text = "Buy",
					TextScaled = true,
					Font = Enum.Font.FredokaOne,
					TextColor3 = Color3.fromRGB(255, 255, 255),

					[React.Event.Activated] = function(instance)
						Signals.BuyOutfit:FireServer(ids)
						props.onClose()
					end,
				}, {
					React.createElement("UICorner", {
						CornerRadius = UDim.new(0.1, 0),
					}),
					React.createElement("UIStroke", {
						Thickness = 2,
						Color = Color3.fromRGB(35, 100, 40),
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}),

				WearOutfit = React.createElement("TextButton", {
					Size = UDim2.fromScale(0.35, 0.08),
					Position = UDim2.fromScale(0.57, 0.85),
					BackgroundColor3 = Color3.fromRGB(54, 161, 161),
					Text = "Wear",
					TextScaled = true,
					Font = Enum.Font.FredokaOne,
					TextColor3 = Color3.fromRGB(255, 255, 255),

					[React.Event.Activated] = function(instance)
						props.onClose()
						Signals.WearOutfit:FireServer(props.code)
					end,
				}, {
					React.createElement("UICorner", {
						CornerRadius = UDim.new(0.1, 0),
					}),
					React.createElement("UIStroke", {
						Thickness = 2,
						Color = Color3.fromRGB(33, 100, 100),
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}),
			}),

			ItemsFrame = React.createElement("Frame", {
				Size = UDim2.fromScale(0.636, 0.95),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				ScrollingFrame = React.createElement(createScrollingFrame, {
					ids = ids,
					cart = props.cart,
					removeFromCart = props.removeFromCart,
					addToCart = props.addToCart,
					textColor = Colors.textColor,
					secondaryColor = Colors.secondaryColor,
					setTotalCost = setTotalCost,
					setCurrent = setCurrent,
					current = current,
					hovered = hovered,
					setHovered = setHovered,
					likedAccs = props.likedAccs or {},
					addToLikes = props.addToLikes,
					removeFromLikeds = props.removeFromLikeds,
				}),
			}),
		}),

		Footer = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 0.1),
			Position = UDim2.fromScale(0, 0.9),
			BackgroundTransparency = 1,
		}, {

			TotalCost = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				Position = UDim2.fromScale(0.035, 0),
				Size = UDim2.fromScale(0.29, 1),
				Text = "Total Cost: " .. utf8.char(0xE002) .. tostring(totalCost),
				TextColor3 = Colors.textColor,
				TextScaled = true,
			}),

			CodeText = React.createElement("TextLabel", {
				Position = UDim2.fromScale(0.87, 0.4),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.2, 0.75),
				BackgroundColor3 = Colors.primaryColor,
				TextColor3 = Colors.textColor,
				ZIndex = 2,
				TextScaled = true,
				Text = props.code,
				Font = Enum.Font.FredokaOne,
			}, {
				React.createElement("UICorner", {
					CornerRadius = UDim.new(0.1, 0),
				}),
				React.createElement("UIStroke", {
					Thickness = 2,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Color3.new(
						math.clamp(Colors.primaryColor.R * 0.5, 0, 1),
						math.clamp(Colors.primaryColor.G * 0.5, 0, 1),
						math.clamp(Colors.primaryColor.B * 0.5, 0, 1)
					),
				}),
			}),
		}),
	})
end

local function OutfitApp()
	local ui = useUIContext()
	local outfitCode, setOutfitCode = React.useState("")
	local cart, setCart = React.useState({} :: { number })
	local likedAccs, setLikedsAccs = React.useState({} :: { number })
	local likedOutfits, setLikedOutfits = React.useState({} :: { number })
	local model, setModel = React.useState(nil)
	local outfitLikes, setOufitLikes = React.useState(nil)

	local APP_NAME = "OutfitViewer"

	React.useEffect(function()
		if ui.activeApp == APP_NAME then
			local fetchedCart = Net:Invoke("GetCart")
			local fetchedLikedOutfits = Net:Invoke("GetLikedOutfits")
			local fetchedLikeds = Net:Invoke("GetLikedAccs")
			if fetchedCart and fetchedLikeds then
				setCart(fetchedCart)
				setLikedOutfits(fetchedLikedOutfits)
				setLikedsAccs(fetchedLikeds)
			end
		end
	end, { ui.activeApp })

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

	local addToCart = React.useCallback(function(id: number)
		setCart(function(prevCart)
			if table.find(prevCart, id) ~= nil then
				return prevCart
			end

			local newCart = table.clone(prevCart)
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

	local likeOutfit = React.useCallback(function(code: string)
		setLikedOutfits(function(prev)
			local new = table.clone(prev)
			table.insert(new, code)
			return new
		end)
	end, {})

	local unlikeOutfit = React.useCallback(function(code: string)
		setLikedOutfits(function(prev)
			local new = table.clone(prev)
			local index = table.find(new, code)
			if index then
				table.remove(new, index)
			end
			return new
		end)
	end)

	React.useEffect(function()
		local connection = Signals.OpenOutfit:Connect(function(code: string, model: Model)
			setOufitLikes(Net:Invoke("GetOutfitLikes", code))
			setOutfitCode(code)
			setModel(model)
			ui.openApp(APP_NAME)
		end)

		local otherConnection = Signals.OpenFromSearch:Connect(function(code: string, model: Model)
			setOufitLikes(Net:Invoke("GetOutfitLikes", code))
			setOutfitCode(code)
			setModel(model)
			ui.openApp(APP_NAME)
		end)

		local oneMoreConnection = Signals.OpenFromPlayer:Connect(function(code: string, model: Model)
			setOufitLikes(0)
			setOutfitCode(code)
			setModel(model)
			ui.openApp(APP_NAME)
		end)

		return function()
			connection:Disconnect()
			otherConnection:Disconnect()
			oneMoreConnection:Disconnect()
		end
	end, {})

	return if ui.activeApp == APP_NAME and outfitCode ~= ""
		then React.createElement(OutfitViewer, {
			code = outfitCode,
			model = model,
			cart = cart,
			likedAccs = likedAccs,
			removeFromCart = removeFromCart,
			addToCart = addToCart,
			removeFromLikeds = removeFromLikeds,
			addToLikes = addToLikes,
			likeOutfit = likeOutfit,
			unlikeOutfit = unlikeOutfit,
			likedOutfits = likedOutfits,
			outfitLikes = outfitLikes,
			onClose = function()
				ui.closeApp()
				setOutfitCode("")
			end,
		})
		else nil
end

return OutfitApp
