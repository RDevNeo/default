-- Services
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Dependencies
local React = require(ReplicatedStorage.Packages.React)
local OutfitHelper = require(ReplicatedStorage.Helpers.OutfitHelper)
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)

-- Context
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext

-- Color
local Colors = require(StarterPlayer.StarterPlayerScripts.Source.UI.Colors)

-- Cache for product info to avoid repeated API calls
local productInfoCache: { [number]: any } = {}

local function getModelByCode(code: string): Model?
	local allModels = CollectionService:GetTagged("Outfit")

	for index, model in pairs(allModels) do
		if model:GetAttribute("Code") == code then
			return model:Clone()
		end
	end
	return nil
end

local function createScrollingFrame(props: {
	ids: { number },
	setTotalCost: (number) -> number,
	setCurrent: (number?) -> number?,
	current: number?,
	hovered: number?,
	setHovered: (number?) -> number?,
})
	local productInfos, setProductInfos = React.useState({} :: { [number]: any })
	local _isLoading, setIsLoading = React.useState(true)

	-- Load product info asynchronously and cache results
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

		-- Helper function to safely update state
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
				-- Load asynchronously
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

	-- Calculate total cost only when productInfos change
	local totalCost = React.useMemo(function()
		local cost = 0
		for id, assetInfo in pairs(productInfos) do
			if assetInfo and assetInfo.IsForSale then
				cost += assetInfo.PriceInRobux
			end
		end
		return cost
	end, { productInfos })

	-- Update parent total cost
	React.useEffect(function()
		props.setTotalCost(totalCost)
	end, { totalCost })

	-- Memoize children to prevent unnecessary re-renders
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
										Signals.BuyAccessory:Fire(id)
									end,
								}, {

									React.createElement("UICorner"),
								}),

								Try = React.createElement("TextButton", {
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

									[React.Event.Activated] = function(instance)
										Signals.TryAccessory:Fire(id)
									end,
								}, {

									React.createElement("UICorner"),
								}),

								AddToCart = React.createElement("TextButton", {
									Name = "AddToCartButton" .. id,
									BackgroundColor3 = Color3.fromRGB(156, 156, 156),
									Position = UDim2.fromScale(0.83, 0.5),
									Size = UDim2.fromScale(0.25, 0.25),
									Text = "Cart",
									TextColor3 = Color3.fromRGB(48, 48, 48),
									TextScaled = true,
									Font = Enum.Font.FredokaOne,
									AnchorPoint = Vector2.new(0.5, 0.5),
									ZIndex = 2,

									[React.Event.Activated] = function(instance)
										Signals.AddToCart:Fire(id)
									end,
								}, {

									React.createElement("UICorner"),
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
	end, { productInfos, props.current, props.ids, props.hovered })

	if props.ids then
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

local function OutfitViewer(props: {
	code: string,
	onClose: () -> (),
}): Frame?
	local viewportRef = React.useRef(nil)
	local modelRef = React.useRef(nil :: Model?)
	local ids, setIds = React.useState(nil :: { number }?)
	local totalCost, setTotalCost = React.useState(0)
	local current, setCurrent = React.useState(nil :: number?)
	local hovered, setHovered = React.useState(nil :: number?)

	React.useEffect(function()
		local viewportFrame = viewportRef.current
		if not viewportFrame then
			return
		end

		if modelRef.current then
			modelRef.current:Destroy()
			modelRef.current = nil
		end

		local model = getModelByCode(props.code)

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
					Text = "99 Likes",
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
						Signals.BuyOutfit:Fire(ids)
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
						Signals.WearOutfit:Fire(ids)
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
					textColor = Colors.textColor,
					secondaryColor = Colors.secondaryColor,
					setTotalCost = setTotalCost,
					setCurrent = setCurrent,
					current = current,
					hovered = hovered,
					setHovered = setHovered,
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
				Text = "Total Cost: " .. tostring(totalCost) .. utf8.char(0xE002),
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

	local APP_NAME = "OutfitViewer"

	React.useEffect(function()
		local connection = Signals.OpenOutfit:Connect(function(code: string)
			setOutfitCode(code)
			ui.openApp(APP_NAME)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return if ui.activeApp == APP_NAME and outfitCode ~= ""
		then React.createElement(OutfitViewer, {
			code = outfitCode,
			onClose = function()
				ui.closeApp()
				setOutfitCode("")
			end,
		})
		else nil
end

return OutfitApp
