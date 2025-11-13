-- Services
local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Dependencies
local Topbar = require(ReplicatedStorage.Packages.TopBarPlus)
local React = require(ReplicatedStorage.Packages.React)
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)
local Colors = require(StarterPlayer.StarterPlayerScripts.Source.UI.Colors)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local Net = require(ReplicatedStorage.Packages.Net)

-- Context
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext
local e = React.createElement

local APP_NAME = "Group Reward"

-- Create Topbar Icon
local GroupReward = Topbar.new()
GroupReward:setLabel("Rewards")
GroupReward:setName("Rewards")

local function GroupRewardBody()
	local groupId = 995190819
	local info = GroupService:GetGroupInfoAsync(groupId)
	local groupName = info.Name
	local groupIcon = info.EmblemUrl
	local isInGroup, setIsInGroup = React.useState(false)

	React.useEffect(function()
		setIsInGroup(Players.LocalPlayer:IsInGroup(groupId))
	end, {})

	return e("Frame", {
		Size = UDim2.fromScale(0.85, 0.85),
		Position = UDim2.fromScale(0.5, 0.54),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	}, {
		e("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0.05, 0),
		}),

		GroupFrame = e("Frame", {
			LayoutOrder = 1,
			Size = UDim2.fromScale(0.4, 0.8),
			BackgroundColor3 = Colors.secondaryColor,
		}, {
			e("TextLabel", {
				Size = UDim2.fromScale(1, 0.13),
				BackgroundTransparency = 1,
				TextColor3 = Colors.textColor,
				Text = "JOIN",
				Font = Enum.Font.FredokaOne,
				TextScaled = true,
			}),

			e("UICorner", {
				CornerRadius = UDim.new(0.1, 0),
			}),

			GroupName = e("TextLabel", {
				Size = UDim2.fromScale(1, 0.15),
				Position = UDim2.fromScale(0, 0.13),
				BackgroundTransparency = 1,
				TextColor3 = Colors.textColor,
				Text = groupName,
				Font = Enum.Font.FredokaOne,
				TextScaled = true,
			}),

			GroupImage = e("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(0.52, 0.52),
				Position = UDim2.fromScale(0.5, 0.56),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = groupIcon,
			}, {
				e("UICorner", {
					CornerRadius = UDim.new(0.1, 0),
				}),
			}),

			GroupStatus = isInGroup and e("TextLabel", {
				Text = "Group Member ✅",
				BackgroundColor3 = Colors.primaryColor,
				TextColor3 = Colors.textColor,
				Font = Enum.Font.FredokaOne,
				TextScaled = true,
				Position = UDim2.fromScale(0.5, 0.91),
				Size = UDim2.fromScale(0.9, 0.12),
				AnchorPoint = Vector2.new(0.5, 0.5),
			}, {
				e("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
				e("UIPadding", {
					PaddingTop = UDim.new(0.1, 0),
					PaddingBottom = UDim.new(0.1, 0),
					PaddingLeft = UDim.new(0.1, 0),
					PaddingRight = UDim.new(0.1, 0),
				}),
			}) or React.createElement("TextLabel", {
				Text = "Not Joined ❌",
				BackgroundColor3 = Colors.primaryColor,
				TextColor3 = Colors.textColor,
				Font = Enum.Font.FredokaOne,
				TextScaled = true,
				Position = UDim2.fromScale(0.5, 0.91),
				Size = UDim2.fromScale(0.9, 0.12),
				AnchorPoint = Vector2.new(0.5, 0.5),
			}, {
				e("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),

				e("UIPadding", {
					PaddingTop = UDim.new(0.1, 0),
					PaddingBottom = UDim.new(0.1, 0),
					PaddingLeft = UDim.new(0.1, 0),
					PaddingRight = UDim.new(0.1, 0),
				}),
			}),
		}),

		HolderFrame = e("Frame", {
			Size = UDim2.fromScale(0.55, 0.8),
			LayoutOrder = 2,
			BackgroundTransparency = 1,
		}, {
			e("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0.1, 0),
			}, {
				e("UICorner", {
					CornerRadius = UDim.new(0.2, 0),
				}),
			}),

			TagText = e("Frame", {
				Size = UDim2.fromScale(0.9, 0.45),
				BackgroundColor3 = Colors.secondaryColor,
				LayoutOrder = 1,
			}, {
				e("UICorner", {
					CornerRadius = UDim.new(0.2, 0),
				}),

				Title = e("TextLabel", {
					Size = UDim2.fromScale(1, 0.4),
					BackgroundTransparency = 1,
					Text = "Get an exclusive VIP chat tag!",
					TextColor3 = Colors.textColor,
					Font = Enum.Font.FredokaOne,
					TextScaled = true,
				}),

				ExampleTag = e("TextLabel", {
					Position = UDim2.fromScale(0.5, 0.63),
					Size = UDim2.fromScale(0.8, 0.55),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Colors.primaryColor,
					TextScaled = true,
					Text = "[VIP] " .. Players.LocalPlayer.Name,
					TextColor3 = Colors.textColor,
					Font = Enum.Font.FredokaOne,
				}, {
					e("UIPadding", {
						PaddingTop = UDim.new(0.02, 0),
						PaddingBottom = UDim.new(0.02, 0),
						PaddingLeft = UDim.new(0.02, 0),
						PaddingRight = UDim.new(0.02, 0),
					}),

					e("UICorner", {
						CornerRadius = UDim.new(0.2, 0),
					}),
				}),
			}),

			PlushImage = e("Frame", {
				Size = UDim2.fromScale(0.9, 0.45),
				BackgroundColor3 = Colors.secondaryColor,
				LayoutOrder = 2,
			}, {
				e("UICorner", {
					CornerRadius = UDim.new(0.2, 0),
				}),

				PlushImage = e("ImageLabel", {
					LayoutOrder = 1,
					Size = UDim2.fromScale(0.5, 1.3),
					Position = UDim2.fromScale(0.25, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "rbxassetid://132087209275199",
				}, {
					e("UICorner", {
						CornerRadius = UDim.new(0.2, 0),
					}),
				}),

				Title = e("TextLabel", {
					Size = UDim2.fromScale(0.5, 0.8),
					Position = UDim2.fromScale(0.75, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Text = "Get this beauty and exclusive cute Hashi!",
					TextColor3 = Colors.textColor,
					Font = Enum.Font.FredokaOne,
					TextScaled = true,
					LayoutOrder = 2,
				}),
			}),
		}),
	})
end

local function GroupRewardFrame()
	local ui = useUIContext()
	local size, setSize = ReactFlow.useSpring({
		start = UDim2.fromScale(0, 0),
		target = UDim2.fromScale(0.45, 0.45),
		speed = 20,
		damper = 0.7,
	})

	local function onClose()
		setSize({ target = UDim2.fromScale(0, 0) })
		ui.closeApp()
	end

	React.useEffect(function()
		setSize({ target = UDim2.fromScale(0.45, 0.45) })
	end, {})

	return e("Frame", {
		Size = size,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Colors.primaryColor,
		BorderSizePixel = 0,
	}, {
		e("UIStroke", {
			Thickness = 4,
			Color = Colors.secondaryColor,
		}),
		e("UICorner", {
			CornerRadius = UDim.new(0.05, 0),
		}),

		Name = e("Frame", {
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
				Text = "Group Reward",
				TextColor3 = Colors.textColor,
				TextScaled = true,
			}),

			React.createElement("UIStroke", {
				Thickness = 4,
				Color = Colors.secondaryColor,
			}),
		}),

		Body = e(GroupRewardBody),

		CloseButton = e("TextButton", {
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
	})
end

GroupReward:bindEvent("selected", function()
	Signals.OpenGroupReward:Fire(true)
end)

GroupReward:bindEvent("deselected", function()
	Signals.OpenGroupReward:Fire(false)
end)

local function GroupRewardApp()
	local ui = useUIContext()
	local isAlreadyShown = React.useRef(false)

	local function onClose()
		GroupReward:deselect()
		ui.closeApp()
	end

	React.useEffect(function()
		local canceled = false

		task.delay(20, function()
			if canceled then
				return
			end
			if isAlreadyShown.current then
				return
			end

			isAlreadyShown.current = true
			ui.openApp(APP_NAME)
		end)

		return function()
			canceled = true
		end
	end, {})

	React.useEffect(function()
		local connection = Signals.OpenGroupReward:Connect(function(isOpen: boolean)
			if isOpen then
				isAlreadyShown.current = true
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
		return React.createElement(GroupRewardFrame)
	end
	return nil
end

return GroupRewardApp
