-- Services
local HttpService = game:GetService("HttpService")

local function SendMessage(webhookURL: string, body: string, attempts: number?): nil
	local ok, response = pcall(function()
		return HttpService:PostAsync(webhookURL, body, Enum.HttpContentType.ApplicationJson)
	end)

	if not ok then
		if not attempts or attempts < 3 then
			return SendMessage(webhookURL, body, (attempts or 0) + 1)
		end

		return error(`Failed to send purchase webhook: {response}, giving up.`)
	end

	return nil
end

return SendMessage
