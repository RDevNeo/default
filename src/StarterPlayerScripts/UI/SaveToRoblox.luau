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

-- Context
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext

-- Cache
local productInfoCache: { [number]: any } = {}

local function createScrollingFrame(props: {
	ids: { number },
	setTotalCost: (number) -> number,
})
	local productInfos, setProductInfos = React.useState({} :: { [number]: any })
	local _isLoading, setIsLoading = React.useState(true)
	local owns, setOwns = React.useState({} :: { [number]: boolean })

	React.useEffect(function()
		if not props.ids then
			return
		end
		local result = Signals.GetOwnedAssets:InvokeServer(props.ids)

		local converted = {}
		for key, value in pairs(result) do
			converted[tonumber(key)] = value
		end

		setOwns(converted)
	end, { props.ids })

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
			UIGridLayout = React.createElement("UIGridLayout", {
				CellSize = UDim2.fromScale(0.33, 0.33),
				CellPadding = UDim2.fromScale(0.005, 0.012),
				FillDirectionMaxCells = 3,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}

		if props.ids then
			for index, id in pairs(props.ids) do
				local assetInfo = productInfos[id]
				if assetInfo and assetInfo.IsForSale then
					if not owns[id] then
						childElements["NotOwned" .. id] = React.createElement("TextButton", {
							Name = "NotOwned" .. tostring(id),
							LayoutOrder = index,
							BackgroundTransparency = 0.97,
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							Text = "",
						}, {
							React.createElement("TextLabel", {
								Text = "Not Owned",
								Size = UDim2.fromScale(0.9, 0.15),
								Position = UDim2.fromScale(0.5, 0),
								AnchorPoint = Vector2.new(0.5, 0),
								BackgroundTransparency = 1,
								Font = Enum.Font.FredokaOne,
								TextScaled = true,
								TextColor3 = Color3.fromRGB(255, 0, 0),
								ZIndex = 2,
							}),

							ItemsHolder = React.createElement("Frame", {
								Name = "ItemsHolder",
								Size = UDim2.fromScale(0.95, 0.95),
								Position = UDim2.fromScale(0.5, 0.5),
								AnchorPoint = Vector2.new(0.5, 0.5),
								BackgroundTransparency = 1,
							}, {
								UIListLayout = React.createElement("UIListLayout", {
									HorizontalAlignment = Enum.HorizontalAlignment.Center,
									VerticalAlignment = Enum.VerticalAlignment.Center,
									FillDirection = Enum.FillDirection.Vertical,
									SortOrder = Enum.SortOrder.LayoutOrder,
								}),

								OutfitImage = React.createElement("ImageLabel", {
									Name = "OutfitImage",
									Position = UDim2.fromScale(0.5, 0.5),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Size = UDim2.fromScale(0.8, 0.8),
									BackgroundTransparency = 1,
									Image = string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", id),
									LayoutOrder = 1,
								}, {
									UIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),
								}),
								OutfitName = React.createElement("TextLabel", {
									Name = "OutfitName",
									Size = UDim2.fromScale(0.8, 0.21),
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
									BackgroundTransparency = 1,
									Font = Enum.Font.FredokaOne,
									TextColor3 = Colors.textColor,
									Text = utf8.char(0xE002) .. assetInfo.PriceInRobux,
									TextScaled = true,
									LayoutOrder = 3,
									AnchorPoint = Vector2.new(0.5, 0),
									TextXAlignment = Enum.TextXAlignment.Left,
								}),
							}),
						})
					else
						childElements["Owned" .. id] = React.createElement("Frame", {
							BackgroundTransparency = 1,
							Name = "Owned" .. tostring(id),
						}, {
							React.createElement("TextLabel", {
								Text = "Owned",
								Size = UDim2.fromScale(0.9, 0.15),
								Position = UDim2.fromScale(0.5, 0),
								AnchorPoint = Vector2.new(0.5, 0),
								BackgroundTransparency = 1,
								Font = Enum.Font.FredokaOne,
								TextScaled = true,
								TextColor3 = Color3.fromRGB(0, 255, 0),
								ZIndex = 2,
							}),

							ItemsHolder = React.createElement("Frame", {
								Name = "ItemsHolder",
								Size = UDim2.fromScale(0.95, 0.95),
								Position = UDim2.fromScale(0.5, 0.5),
								AnchorPoint = Vector2.new(0.5, 0.5),
								BackgroundTransparency = 1,
							}, {
								UIListLayout = React.createElement("UIListLayout", {
									HorizontalAlignment = Enum.HorizontalAlignment.Center,
									VerticalAlignment = Enum.VerticalAlignment.Center,
									FillDirection = Enum.FillDirection.Vertical,
									SortOrder = Enum.SortOrder.LayoutOrder,
								}),

								OutfitImage = React.createElement("ImageLabel", {
									Name = "OutfitImage",
									Position = UDim2.fromScale(0.5, 0.5),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Size = UDim2.fromScale(0.8, 0.8),
									BackgroundTransparency = 1,
									Image = string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", id),
									LayoutOrder = 1,
								}, {
									UIAspectRatioConstraint = React.createElement("UIAspectRatioConstraint"),
								}),
								OutfitName = React.createElement("TextLabel", {
									Name = "OutfitName",
									Size = UDim2.fromScale(0.8, 0.21),
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
									BackgroundTransparency = 1,
									Font = Enum.Font.FredokaOne,
									TextColor3 = Colors.textColor,
									Text = utf8.char(0xE002) .. assetInfo.PriceInRobux,
									TextScaled = true,
									LayoutOrder = 3,
									AnchorPoint = Vector2.new(0.5, 0),
									TextXAlignment = Enum.TextXAlignment.Left,
								}),
							}),
						})
					end
				end
			end
		end

		return childElements
	end, { productInfos, props.ids, owns })

	if props.ids then
		return React.createElement("ScrollingFrame", {
			Size = UDim2.fromScale(1, 0.95),
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

local function SaveToRoblox(props: { onClose: () -> (), onSaveButton: () -> () }): Frame?
	local viewportRef = React.useRef(nil)
	local modelRef = React.useRef(nil :: Model?)
	local ids, setIds = React.useState(nil :: { number }?)
	local totalCost, setTotalCost = React.useState(0)

	React.useEffect(function()
		local viewportFrame = viewportRef.current
		if not viewportFrame then
			return
		end

		-- Character can be cloned if "Archived" is set to true. Which by default, is setted for false.
		local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
		local old = character.Archivable
		character.Archivable = true
		local clone = character:Clone()
		character.Archivable = old

		local model = clone
		model.Parent = workspace
		task.wait(0.1)

		modelRef.current = model
		model.Parent = viewportFrame
		model:PivotTo(CFrame.new(0, 0, -7) * CFrame.Angles(0, math.rad(180), 0))

		setIds(OutfitHelper.getIds(model.Humanoid:GetAppliedDescription()))

		return function()
			if modelRef.current then
				modelRef.current:Destroy()
				modelRef.current = nil
			end
		end
	end, { viewportRef })

	return React.createElement("Frame", {
		Name = "Save to Roblox",
		Size = UDim2.fromScale(0.7, 0.8),
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
				Text = "Save to Roblox",
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

			OutfitFrame = React.createElement("Frame", {
				Size = UDim2.fromScale(0.3, 0.95),
				Position = UDim2.fromScale(0.1, 0),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
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
			}),

			ItemsFrame = React.createElement("Frame", {
				Size = UDim2.fromScale(0.4, 0.95),
				Position = UDim2.fromScale(0.5, -0.02),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				ScrollingFrame = React.createElement(createScrollingFrame, {
					ids = ids,
					setTotalCost = setTotalCost,
				}),
			}),
		}),

		Footer = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 0.15),
			Position = UDim2.fromScale(0, 0.85),
			BackgroundTransparency = 1,
		}, {

			TotalCost = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				Position = UDim2.fromScale(0.5, 0),
				Size = UDim2.fromScale(0.4, 0.4),
				Text = "Total Cost: " .. utf8.char(0xE002) .. tostring(totalCost),
				TextColor3 = Colors.textColor,
				TextScaled = true,
			}),
			BuyOutfit = React.createElement("TextButton", {
				Size = UDim2.fromScale(0.4, 0.5),
				Position = UDim2.fromScale(0.5, 0.4),
				BackgroundColor3 = Color3.fromRGB(69, 190, 77),
				Text = "Buy Outfit",
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

			SaveOutfit = React.createElement("TextButton", {
				Size = UDim2.fromScale(0.4, 0.5),
				Position = UDim2.fromScale(0.05, 0.4),
				BackgroundColor3 = Color3.fromRGB(109, 109, 109),
				Text = "Save",
				TextScaled = true,
				Font = Enum.Font.FredokaOne,
				TextColor3 = Color3.fromRGB(255, 255, 255),

				[React.Event.Activated] = function(instance)
					props.onSaveButton()
				end,
			}, {
				React.createElement("UICorner", {
					CornerRadius = UDim.new(0.1, 0),
				}),
				React.createElement("UIStroke", {
					Thickness = 2,
					Color = Color3.fromRGB(70, 70, 70),
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
			}),
		}),
	})
end

local function SaveToRobloxApp()
	local ui = useUIContext()
	local APP_NAME = "Save To Roblox"

	React.useEffect(function()
		local connection = Signals.OpenOutfit:Connect(function(code: string)
			ui.openApp(APP_NAME)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	local function onSaveButton()
		ui.openApp("Save Confirm")
	end

	return if ui.activeApp == APP_NAME
		then React.createElement(SaveToRoblox, {
			onClose = function()
				ui.closeApp()
			end,
			onSaveButton = onSaveButton,
		})
		else nil
end

return SaveToRobloxApp
