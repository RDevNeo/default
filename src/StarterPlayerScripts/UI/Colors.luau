local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
	primaryColor = ReplicatedStorage.Colors:WaitForChild("PrimaryUI").Value :: Color3Value,
	secondaryColor = ReplicatedStorage.Colors:WaitForChild("SecondaryUI").Value :: Color3Value,
	backgroundColor = ReplicatedStorage.Colors:WaitForChild("BackgroundUI").Value :: Color3Value,
	foregroundColor = ReplicatedStorage.Colors:WaitForChild("ForegroundUI").Value :: Color3Value,
	accentColor = ReplicatedStorage.Colors:WaitForChild("AccentUI").Value :: Color3Value,
	destructiveColor = ReplicatedStorage.Colors:WaitForChild("DestructiveUI").Value :: Color3Value,
	textColor = ReplicatedStorage.Colors:WaitForChild("TextUI").Value :: Color3Value,
	imageColor = ReplicatedStorage.Colors:WaitForChild("ImageUI").Value :: Color3Value,
}
