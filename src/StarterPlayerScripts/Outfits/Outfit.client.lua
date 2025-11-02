-- Services
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Dependencies
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local OutfitHelper = require(ReplicatedStorage.Helpers.OutfitHelper)
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)

-- Variables
local screenGui = Instance.new("ScreenGui", PlayerGui)
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local root = ReactRoblox.createRoot(screenGui)

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
	textColor: Color3,
	secondaryColor: Color3,
	setTotalCost: (number) -> number,
	setCurrent: (number?) -> number?,
	current: number?,
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
				CellSize = UDim2.fromScale(0.2, 0.3),
				CellPadding = UDim2.fromScale(0.05, 0.05),
				FillDirectionMaxCells = 4,
			}),
			React.createElement("UIPadding", {
				PaddingTop = UDim.new(0.02, 0),
				PaddingLeft = UDim.new(0.02, 0),
				PaddingBottom = UDim.new(0.02, 0),
			}),
		}

		if props.ids then
			for index, id in pairs(props.ids) do
				local assetInfo = productInfos[id]
				if assetInfo and assetInfo.IsForSale then
					childElements["OutfitButton" .. id] = React.createElement("TextButton", {
						Text = "",
						Name = "OutfitViewerFrame" .. tostring(id),
						BackgroundColor3 = Color3.fromRGB(163, 162, 165),
						BackgroundTransparency = 0.9,

						[React.Event.Activated] = function(instance: TextButton)
							if props.current == id then
								props.setCurrent(nil)
							else
								props.setCurrent(id)
							end
						end,
					}, {
						OutfitImage = React.createElement("ImageLabel", {
							Name = "OutfitImage",
							Position = UDim2.fromScale(0.5, 0.5),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Size = UDim2.fromScale(0.85, 0.85),
							BackgroundTransparency = 1,
							Image = string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", id),
							ZIndex = 1,
						}),

						OutfitName = React.createElement("TextLabel", {
							Name = "OutfitName",
							Size = UDim2.fromScale(0.95, 0.15),
							Position = UDim2.fromScale(0.5, 0.02),
							BackgroundTransparency = 1,
							Font = Enum.Font.FredokaOne,
							Text = assetInfo.Name or "Loading...",
							TextColor3 = props.textColor,
							TextScaled = true,
							ZIndex = 2,
							AnchorPoint = Vector2.new(0.5, 0),
						}),

						OutfitPrice = React.createElement("TextLabel", {
							Name = "OutfitPrice",
							Size = UDim2.fromScale(1, 0.15),
							Position = UDim2.fromScale(0.5, 0.82),
							BackgroundTransparency = 1,
							Font = Enum.Font.FredokaOne,
							Text = assetInfo.PriceInRobux .. utf8.char(0xE002),
							TextColor3 = props.textColor,
							TextScaled = true,
							ZIndex = 2,
							AnchorPoint = Vector2.new(0.5, 0),
						}),

						UIStroke = React.createElement("UIStroke", {
							Thickness = 3,
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = props.secondaryColor,
						}),

						UICorner = React.createElement("UICorner"),

						props.current == id and React.createElement("Frame", {
							Name = "ButtonsHolder",
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
						}, {
							UIGridLayout = React.createElement("UIGridLayout", {
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								FillDirectionMaxCells = 2,
								FillDirection = Enum.FillDirection.Horizontal,
								SortOrder = Enum.SortOrder.LayoutOrder,
								CellSize = UDim2.fromScale(0.27, 0.27),
								CellPadding = UDim2.fromScale(0.2, 0.07),
							}),

							BuyAccessory = React.createElement("TextButton", {
								Name = "BuyButton" .. id,
								Text = "",
								BackgroundColor3 = Color3.fromRGB(54, 187, 21),
								LayoutOrder = 1,

								[React.Event.Activated] = function(instance)
									Signals.BuyAccessory:Fire(id)
								end,
							}, {
								React.createElement("UIStroke", {
									ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
									Thickness = 2,
									Color = Color3.fromRGB(27, 99, 10),
								}),

								React.createElement("UICorner"),

								React.createElement("ImageLabel", {
									BackgroundTransparency = 1,
									Size = UDim2.fromScale(0.8, 0.8),
									Position = UDim2.fromScale(0.5, 0.5),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Image = "rbxassetid://88173809464018",
								}),
							}),

							AddToCart = React.createElement("TextButton", {
								Name = "AddToCart" .. id,
								Text = "",
								BackgroundColor3 = Color3.fromRGB(21, 154, 187),
								LayoutOrder = 2,

								[React.Event.Activated] = function(instance)
									Signals.AddToCart:Fire(id)
								end,
							}, {
								React.createElement("UIStroke", {
									ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
									Thickness = 2,
									Color = Color3.fromRGB(10, 63, 99),
								}),

								React.createElement("UICorner"),

								React.createElement("ImageLabel", {
									BackgroundTransparency = 1,
									Size = UDim2.fromScale(0.8, 0.8),
									Position = UDim2.fromScale(0.5, 0.5),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Image = "rbxassetid://93218144966540",
								}),
							}),

							WearAccessory = React.createElement("TextButton", {
								Name = "WearAccessory" .. id,
								Text = "",
								BackgroundColor3 = Color3.fromRGB(132, 17, 167),
								LayoutOrder = 3,

								[React.Event.Activated] = function(instance)
									Signals.WearAccessory:Fire(id)
								end,
							}, {
								React.createElement("UIStroke", {
									ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
									Thickness = 2,
									Color = Color3.fromRGB(70, 9, 88),
								}),

								React.createElement("UICorner"),

								React.createElement("ImageLabel", {
									BackgroundTransparency = 1,
									Size = UDim2.fromScale(0.8, 0.8),
									Position = UDim2.fromScale(0.5, 0.5),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Image = "rbxassetid://138938975034981",
								}),
							}),

							LikeAccessory = React.createElement("TextButton", {
								Name = "LikeAccessory" .. id,
								Text = "",
								BackgroundColor3 = Color3.fromRGB(187, 32, 21),
								LayoutOrder = 4,

								[React.Event.Activated] = function(instance)
									Signals.LikeAccessory:Fire(id)
								end,
							}, {
								React.createElement("UIStroke", {
									ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
									Thickness = 2,
									Color = Color3.fromRGB(99, 16, 10),
								}),

								React.createElement("UICorner"),

								React.createElement("ImageLabel", {
									BackgroundTransparency = 1,
									Size = UDim2.fromScale(0.8, 0.8),
									Position = UDim2.fromScale(0.5, 0.5),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Image = "rbxassetid://77582976084943",
								}),
							}),
						}),
					})
				end
			end
		end

		return childElements
	end, { productInfos, props.current, props.textColor, props.secondaryColor, props.ids })

	if props.ids then
		return React.createElement("ScrollingFrame", {
			Size = UDim2.fromScale(0.95, 0.95),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			CanvasSize = UDim2.fromOffset(0, #props.ids * 70),
			BackgroundTransparency = 1,
		}, children)
	end
	return nil
end

local function OutfitViewer(props: {
	code: string,
	primaryColor: Color3,
	secondaryColor: Color3,
	textColor: Color3,
	onClose: () -> (),
}): Frame?
	local viewportRef = React.useRef(nil)
	local modelRef = React.useRef(nil :: Model?)
	local ids, setIds = React.useState(nil :: { number }?)
	local totalCost, setTotalCost = React.useState(0)
	local current, setCurrent = React.useState(nil :: number?)

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
		Size = UDim2.fromScale(0.7, 0.7),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = props.primaryColor,
	}, {
		React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 10),
		}),
		React.createElement("UIStroke", {
			Thickness = 5,
			Color = props.secondaryColor,
		}),

		Name = React.createElement("Frame", {
			Name = "Name",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, -0.06),
			Size = UDim2.fromScale(0.4, 0.13),
			BackgroundColor3 = props.primaryColor,
		}, {
			React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 10),
			}),
			React.createElement("UIStroke", {
				Thickness = 5,
				Color = props.secondaryColor,
			}),
			Title = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				Text = "Outfit Viewer",
				TextColor3 = props.textColor,
				TextScaled = true,
			}),
		}),

		CloseButton = React.createElement("TextButton", {
			Name = "CloseButton",
			Size = UDim2.fromScale(0.04, 0.07),
			Position = UDim2.fromScale(0.97, 0.02),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.fromRGB(220, 53, 69),
			Text = "X",
			TextColor3 = props.textColor,
			TextScaled = true,
			Font = Enum.Font.FredokaOne,

			[React.Event.Activated] = props.onClose,
		}, {
			React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 10),
			}),
			React.createElement("UIStroke", {
				Thickness = 3,
				Color = Color3.fromRGB(139, 33, 43),
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
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
					BackgroundColor3 = Color3.fromRGB(164, 164, 255),
					TextColor3 = props.textColor,
					ZIndex = 2,
					TextScaled = true,
					Text = "99 Likes",
					Font = Enum.Font.FredokaOne,
				}, {
					React.createElement("UICorner", {
						CornerRadius = UDim.new(0, 10),
					}),

					React.createElement("UIStroke", {
						Thickness = 5,
						Color = props.secondaryColor,
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
						CornerRadius = UDim.new(0, 10),
					}),

					React.createElement("UIStroke", {
						Thickness = 5,
						Color = props.secondaryColor,
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
						CornerRadius = UDim.new(0, 10),
					}),
					React.createElement("UIStroke", {
						Thickness = 3,
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
						CornerRadius = UDim.new(0, 10),
					}),
					React.createElement("UIStroke", {
						Thickness = 3,
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
					textColor = props.textColor,
					secondaryColor = props.secondaryColor,
					setTotalCost = setTotalCost,
					setCurrent = setCurrent,
					current = current,
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
				TextColor3 = props.textColor,
				TextScaled = true,
			}),

			CodeText = React.createElement("TextLabel", {
				Position = UDim2.fromScale(0.87, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.2, 0.75),
				BackgroundColor3 = Color3.fromRGB(164, 164, 255),
				TextColor3 = props.textColor,
				ZIndex = 2,
				TextScaled = true,
				Text = props.code,
				Font = Enum.Font.FredokaOne,
			}, {
				React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 10),
				}),
				React.createElement("UIStroke", {
					Thickness = 5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = props.secondaryColor,
				}),
			}),
		}),
	})
end

local function OutfitApp()
	local isOpen, setIsOpen = React.useState(false)
	local outfitCode, setOutfitCode = React.useState("")

	local primaryColor = Color3.fromRGB(29, 31, 35)
	local secondaryColor = Color3.fromRGB(118, 118, 212)
	local textColor = Color3.fromRGB(255, 255, 255)

	React.useEffect(function()
		local connection = Signals.OpenOutfit:Connect(function(code: string)
			setOutfitCode(code)
			setIsOpen(true)
			print("Received outfit:", code)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	local function handleClose()
		setIsOpen(false)
	end

	return if isOpen
		then React.createElement(OutfitViewer, {
			code = outfitCode,
			primaryColor = primaryColor,
			secondaryColor = secondaryColor,
			textColor = textColor,
			onClose = handleClose,
		})
		else nil
end

root:render(React.createElement(OutfitApp))
