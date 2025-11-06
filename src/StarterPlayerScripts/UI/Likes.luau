-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Dependencies
local OutfitHelper = require(ReplicatedStorage.Helpers.OutfitHelper)
local React = require(ReplicatedStorage.Packages.React)
local Colors = require(StarterPlayer.StarterPlayerScripts.Source.UI.Colors)
local Signals = require(StarterPlayer.StarterPlayerScripts.Source.CommsInit.Module)
local Net = require(ReplicatedStorage.Packages.Net)

type Outfit = {
	Name: string,
	Code: string,
	Model: Model,
	Prompt: ProximityPrompt,
	Click: ClickDetector,
	Highlight: Highlight,
	CameraPart: Part,
}

-- Context
local useUIContext = require(StarterPlayer.StarterPlayerScripts.Source.UIContext.Context).useUIContext

local function disableWalking()
	local char = Players.LocalPlayer.Character
	if char and char:FindFirstChild("Humanoid") then
		char.Humanoid.WalkSpeed = 0
		char.Humanoid.JumpPower = 0
	end
end

local function enableWalking()
	local char = Players.LocalPlayer.Character
	if char and char:FindFirstChild("Humanoid") then
		char.Humanoid.WalkSpeed = 16
		char.Humanoid.JumpPower = 50
	end
end

local function setCharacterTransparency(char: Model, transparency: number)
	if not char then
		return
	end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") then
			part.LocalTransparencyModifier = transparency
		elseif part:IsA("LayeredClothing") then
			part.Enabled = transparency < 1
		end
	end
end

local function makeAllPlayersInvisible()
	for _, plr in ipairs(Players:GetPlayers()) do
		setCharacterTransparency(plr.Character, 1)
	end
end

local function makeAllPlayersVisible()
	for _, plr in ipairs(Players:GetPlayers()) do
		setCharacterTransparency(plr.Character, 0)
	end
end

local function Likes(props: {
	onClose: () -> (),
	current: number,
	setCurrent: (number) -> (),
	onNext: () -> (),
	onPrev: () -> (),
	onRemove: () -> (),
	onBuy: () -> (),
	onWear: () -> (),
	likedOutfits: { string },
	Outfits: { Outfit },
})
	return React.createElement("Frame", {
		Position = UDim2.fromScale(0.5, 0.8),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromScale(0.35, 0.18),
		BackgroundTransparency = 1,
		Name = "LikesFrame",
	}, {

		UIListLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		Holders = React.createElement("Frame", {
			Name = "Holders",
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.8, 0.9),
			AnchorPoint = Vector2.new(0.5, 0.5),
			LayoutOrder = 1,
		}, {
			React.createElement("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly,
				ItemLineAlignment = Enum.ItemLineAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
			}),

			PrevButton = React.createElement("ImageButton", {
				Name = "Previous",
				LayoutOrder = 1,
				Size = UDim2.fromScale(0.15, 0.45),
				Image = "rbxassetid://93627212233619",
				BackgroundColor3 = Colors.primaryColor,
				BorderSizePixel = 0,

				[React.Event.Activated] = function(rbx)
					props.onPrev()
				end,
			}, {
				React.createElement("UICorner", {
					CornerRadius = UDim.new(0.2, 0),
				}),
				React.createElement("UIStroke", {
					Thickness = 3,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Colors.secondaryColor,
				}),
			}),

			ButtonsFrame = React.createElement("Frame", {
				Name = "ButtonsFrame",
				LayoutOrder = 2,
				Size = UDim2.fromScale(0.3, 0.8),
				BackgroundTransparency = 0.9,
				BorderSizePixel = 0,
			}, {
				React.createElement("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly,
					ItemLineAlignment = Enum.ItemLineAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Vertical,
					VerticalFlex = Enum.UIFlexAlignment.SpaceAround,
				}),

				BuyButton = React.createElement("TextButton", {
					BackgroundColor3 = Color3.fromRGB(69, 190, 77),
					Text = "Buy",
					Font = Enum.Font.FredokaOne,
					Size = UDim2.fromScale(1, 0.25),
					TextScaled = true,
					LayoutOrder = 1,
					TextColor3 = Colors.textColor,

					[React.Event.Activated] = function(rbx)
						props.onBuy()
					end,
				}, {
					React.createElement("UICorner", {
						CornerRadius = UDim.new(0.2, 0),
					}),
					React.createElement("UIStroke", {
						Thickness = 3,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromRGB(69, 120, 77),
					}),
				}),

				WearButton = React.createElement("TextButton", {
					BackgroundColor3 = Color3.fromRGB(54, 161, 161),
					Text = "Wear",
					Font = Enum.Font.FredokaOne,
					Size = UDim2.fromScale(1, 0.25),
					TextScaled = true,
					LayoutOrder = 2,
					TextColor3 = Colors.textColor,

					[React.Event.Activated] = function(rbx)
						props.onWear()
					end,
				}, {
					React.createElement("UICorner", {
						CornerRadius = UDim.new(0.2, 0),
					}),
					React.createElement("UIStroke", {
						Thickness = 3,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromRGB(25, 77, 77),
					}),
				}),

				RemoveButton = React.createElement("TextButton", {
					BackgroundColor3 = Color3.fromRGB(221, 49, 37),
					Text = "Remove",
					Font = Enum.Font.FredokaOne,
					Size = UDim2.fromScale(1, 0.25),
					TextScaled = true,
					LayoutOrder = 3,
					TextColor3 = Colors.textColor,

					[React.Event.Activated] = function(rbx)
						props.onRemove()
					end,
				}, {
					React.createElement("UICorner", {
						CornerRadius = UDim.new(0.2, 0),
					}),
					React.createElement("UIStroke", {
						Thickness = 3,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromRGB(119, 33, 25),
					}),
				}),
			}),

			NextButton = React.createElement("ImageButton", {
				Name = "Next",
				LayoutOrder = 3,
				Size = UDim2.fromScale(0.15, 0.45),
				Image = "rbxassetid://104207148793261",
				BackgroundColor3 = Colors.primaryColor,
				BorderSizePixel = 0,

				[React.Event.Activated] = function(rbx)
					props.onNext()
				end,
			}, {
				React.createElement("UICorner", {
					CornerRadius = UDim.new(0.2, 0),
				}),
				React.createElement("UIStroke", {
					Thickness = 3,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Colors.secondaryColor,
				}),
			}),
		}),

		CloseButton = React.createElement("TextButton", {
			BackgroundColor3 = Colors.secondaryColor,
			Size = UDim2.fromScale(0.5, 0.25),
			Text = "Close View",
			TextScaled = true,
			Font = Enum.Font.FredokaOne,
			TextColor3 = Colors.textColor,
			LayoutOrder = 2,

			[React.Event.Activated] = function(rbx)
				props.onClose()
			end,
		}, {
			React.createElement("UICorner", {
				CornerRadius = UDim.new(0.2, 0),
			}),
			React.createElement("UIStroke", {
				Thickness = 3,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.new(
					math.clamp(Colors.secondaryColor.R * 0.5, 0, 1),
					math.clamp(Colors.secondaryColor.G * 0.5, 0, 1),
					math.clamp(Colors.secondaryColor.B * 0.5, 0, 1)
				),
			}),
		}),
	})
end

local function LikesApp()
	local ui = useUIContext()
	local current, setCurrent = React.useState(1)
	local likedOutfits = Net:Invoke("GetLikedOutfits")
	local likedOutfitsObj = Net:Invoke("GetLikedOuftiObject", likedOutfits)
	local tempModels, setTempModels = React.useState(nil)
	local APP_NAME = "Likes"

	local function tweenToGoal(goal: Part, model: Model)
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Scriptable

		local primary = model.PrimaryPart
		if not primary then
			warn("Model has no PrimaryPart")
			return
		end

		local lookDirection = -primary.CFrame.LookVector
		local targetCFrame = CFrame.new(goal.Position, goal.Position + lookDirection)

		local tween = TweenService:Create(
			cam,
			TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = targetCFrame }
		)

		tween:Play()
	end

	local function onStart()
		if #likedOutfits == 0 then
			Signals.Warn:FireServer("No liked outfits.")
			ui.closeApp()
			return
		end

		local outfit: Outfit = likedOutfitsObj[current]
		local folder = Workspace:FindFirstChild("tempModels")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "tempModels"
			folder.Parent = Workspace
			setTempModels(folder)
		else
			setTempModels(folder)
		end

		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Model") then
				child:Destroy()
			end
		end

		disableWalking()
		makeAllPlayersInvisible()

		local temp = outfit.Model:Clone()
		temp.Parent = folder
		tweenToGoal(outfit.CameraPart, outfit.Model)
		return
	end

	local function onNext()
		local total = #likedOutfitsObj
		print("Total outfits:", total)

		if total <= 1 then
			print("There is no next, only one outfit.")
			return
		end

		setCurrent(function(prev)
			local new = prev + 1
			if new > total then
				new = 1
				print("Wrapped to first outfit.")
			else
				print("Went to next outfit:", new)
			end
			return new
		end)
	end

	local function onPrev()
		local total = #likedOutfitsObj
		print("Total outfits:", total)

		if total <= 1 then
			print("There is no previous, only one outfit.")
			return
		end

		setCurrent(function(prev)
			local new = prev - 1
			if new < 1 then
				new = total
				print("Wrapped to last outfit.")
			else
				print("Went to previous outfit:", new)
			end
			return new
		end)
	end

	local function onBuy()
		local outfit: Outfit = likedOutfitsObj[current]
		local Humanoid = outfit.Model:FindFirstChildWhichIsA("Humanoid")

		if Humanoid then
			local ids = OutfitHelper.getIds(Humanoid:GetAppliedDescription())
			Signals.BuyOutfit:FireServer(ids)
		else
			warn("Model has no Humanoid on it.")
		end
	end

	local function onClose()
		ui.closeApp()
		Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom

		if tempModels then
			for _, model in ipairs(tempModels:GetChildren()) do
				if model:IsA("Model") then
					model:Destroy()
				end
			end
		end
		enableWalking()
		makeAllPlayersVisible()
	end

	local function onWear()
		local outfit: Outfit = likedOutfitsObj[current]

		if not outfit then
			return warn("Couldn't fetch the Outfit.")
		end

		local code = outfit.Model:GetAttribute("Code") :: string

		if not code then
			return warn("Could not fetch the code.")
		end

		Signals.WearOutfit:FireServer(code)
		onClose()
		return
	end

	local function onRemove()
		local total = #likedOutfitsObj
		local outfit: Outfit = likedOutfitsObj[current]
		local code = outfit.Model:GetAttribute("Code")

		if total <= 1 then
			Signals.RemoveOutfitLike:FireServer(code)
			table.clear(likedOutfits)
			table.clear(likedOutfitsObj)

			if tempModels then
				for _, child in ipairs(tempModels:GetChildren()) do
					if child:IsA("Model") then
						child:Destroy()
					end
				end
			end

			makeAllPlayersVisible()
			enableWalking()
			ui.closeApp()
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			return
		end

		Signals.RemoveOutfitLike:FireServer(code)
		table.remove(likedOutfitsObj, current)
		table.remove(likedOutfits, current)

		if current > #likedOutfitsObj then
			setCurrent(1)
			onNext()
		else
			setCurrent(current)
			onNext()
		end
	end

	React.useEffect(function()
		if ui.activeApp ~= APP_NAME then
			return
		end

		onStart()
	end, { ui.activeApp, current })

	return if ui.activeApp == APP_NAME and #likedOutfitsObj > 0
		then React.createElement(Likes, {
			onClose = onClose,
			onNext = onNext,
			onPrev = onPrev,
			current = current,
			onBuy = onBuy,
			onWear = onWear,
			onRemove = onRemove,
			setCurrent = setCurrent,
		})
		else nil
end

return LikesApp
