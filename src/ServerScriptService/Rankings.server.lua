-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

-- Dependencies
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local DataManager = require(ServerStorage.Source.Datastore.DataManager)
local Colors = require(StarterPlayer.StarterPlayerScripts.Source.UI.Colors)

local SpentContainer = Workspace.SL.Screen.SurfaceGui.Container
local PurchaseContainer = Workspace.PL.Screen.SurfaceGui.Container

local spentRoot = ReactRoblox.createRoot(SpentContainer)
local purchaseRoot = ReactRoblox.createRoot(PurchaseContainer)

type Ranking = {
	UserId: string,
	Value: number,
}

local function Spent()
	local spent, setSpent = React.useState({} :: { Ranking })

	React.useEffect(function()
		setSpent(DataManager.GetTopSpent(50))
	end, {})

	local children = React.useMemo(function()
		local childElements = {
			UIGridLayout = React.createElement("UIGridLayout", {
				CellSize = UDim2.fromScale(0.95, 0.08),
				CellPadding = UDim2.fromScale(0, 0.02),
				FillDirectionMaxCells = 1,
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,

				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			UIPadding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0.02, 0),
			}),
		}

		for i, ranking in ipairs(spent) do
			childElements["Rank" .. i] = React.createElement("Frame", {
				LayoutOrder = i,
				BackgroundColor3 = Color3.fromRGB(0, 124, 60),
			}, {
				UICorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0.2, 0),
				}),
			}, {

				UIListLayout = React.createElement("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0.03, 0),
				}),

				Thumbnail = React.createElement("ImageLabel", {
					LayoutOrder = 1,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(0.178, 0.879),
					Image = Players:GetUserThumbnailAsync(
						ranking.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size100x100
					),
				}, {

					UICorner = React.createElement("UICorner", {
						CornerRadius = UDim.new(0.2, 0),
					}),

					UIStroke = React.createElement("UIStroke", {
						Thickness = 2,
						Color = Color3.fromRGB(255, 255, 255),
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}),

				NamesHolders = React.createElement("Frame", {
					LayoutOrder = 2,
					Size = UDim2.fromScale(0.535, 0.879),
					BackgroundTransparency = 1,
				}, {
					React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),

					Username = React.createElement("TextLabel", {
						LayoutOrder = 1,
						Text = Players:GetNameFromUserIdAsync(ranking.UserId),
						TextColor3 = Colors.textColor,
						Size = UDim2.fromScale(1, 0.43),
						BackgroundTransparency = 1,
						TextScaled = true,
						Font = Enum.Font.FredokaOne,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					Quantity = React.createElement("TextLabel", {
						LayoutOrder = 2,
						Text = utf8.char(0xE002) .. tostring(ranking.Value) .. " spent",
						TextColor3 = Colors.textColor,
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 0.5),
						TextScaled = true,
						Font = Enum.Font.FredokaOne,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
				}),

				PositionText = React.createElement("TextLabel", {
					LayoutOrder = 3,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(0.178, 0.879),
					Text = "# " .. tostring(i),
					TextScaled = true,
					TextColor3 = Colors.textColor,
					Font = Enum.Font.FredokaOne,
				}),
			})
		end

		return childElements
	end, { spent })

	return React.createElement("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, children)
end

local function Purchase()
	local spent, setSpent = React.useState({} :: { Ranking })

	React.useEffect(function()
		setSpent(DataManager.GetTopPurchases(50))
	end, {})

	local children = React.useMemo(function()
		local childElements = {
			UIGridLayout = React.createElement("UIGridLayout", {
				CellSize = UDim2.fromScale(0.95, 0.08),
				CellPadding = UDim2.fromScale(0, 0.02),
				FillDirectionMaxCells = 1,
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,

				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			UIPadding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0.02, 0),
			}),
		}

		for i, ranking in ipairs(spent) do
			childElements["Rank" .. i] = React.createElement("Frame", {
				LayoutOrder = i,
				BackgroundColor3 = Color3.fromRGB(0, 124, 60),
			}, {
				UICorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0.2, 0),
				}),
			}, {

				UIListLayout = React.createElement("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0.03, 0),
				}),

				Thumbnail = React.createElement("ImageLabel", {
					LayoutOrder = 1,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(0.178, 0.879),
					Image = Players:GetUserThumbnailAsync(
						ranking.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size100x100
					),
				}, {

					UICorner = React.createElement("UICorner", {
						CornerRadius = UDim.new(0.2, 0),
					}),

					UIStroke = React.createElement("UIStroke", {
						Thickness = 2,
						Color = Color3.fromRGB(255, 255, 255),
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}),

				NamesHolders = React.createElement("Frame", {
					LayoutOrder = 2,
					Size = UDim2.fromScale(0.535, 0.879),
					BackgroundTransparency = 1,
				}, {
					React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),

					Username = React.createElement("TextLabel", {
						LayoutOrder = 1,
						Text = Players:GetNameFromUserIdAsync(ranking.UserId),
						TextColor3 = Colors.textColor,
						Size = UDim2.fromScale(1, 0.43),
						BackgroundTransparency = 1,
						TextScaled = true,
						Font = Enum.Font.FredokaOne,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					Quantity = React.createElement("TextLabel", {
						LayoutOrder = 2,
						Text = "👜 " .. tostring(ranking.Value),
						TextColor3 = Colors.textColor,
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 0.5),
						TextScaled = true,
						Font = Enum.Font.FredokaOne,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
				}),

				PositionText = React.createElement("TextLabel", {
					LayoutOrder = 3,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(0.178, 0.879),
					Text = "# " .. tostring(i),
					TextScaled = true,
					TextColor3 = Colors.textColor,
					Font = Enum.Font.FredokaOne,
				}),
			})
		end

		return childElements
	end, { spent })

	return React.createElement("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, children)
end

-- Initial Start
spentRoot:render(React.createElement(Spent))
purchaseRoot:render(React.createElement(Purchase))

-- Update every 5 minutes.
while task.wait(300) do
	spentRoot:render(React.createElement(Spent))
	purchaseRoot:render(React.createElement(Purchase))
end
