https = require "ssl.https"
require "json"

function onLoad()
	bot.registerCommand{name = "isSteamDown", func = check}
end

function check(message, param)
	param = string.match(param, "^(%w*)")

	local APIresponse, err = https.request("https://www.steamgaug.es/api/v2")
	assert(APIresponse, "Error while making https request: "..err)

	local steamData = json.decode(APIresponse)

	if param == "steam" then
		message.chat:sendMessage("Steam client is "..(steamData.ISteamClient.online == 1 and "up" or "down").."!")
	elseif param == "store" then
		message.chat:sendMessage("Steam store is "..(steamData.SteamStore.online == 1 and "up" or "down").."!")
	elseif param == "community" then
		message.chat:sendMessage("Steam community is "..(steamData.SteamCommunity.online == 1 and "up" or "down").."!")
	else
		message.chat:sendMessage([[
Current steam status as provided by www.steamgauge.es/:
  Steam client is ]]..(steamData.ISteamClient.online == 1 and "up!\n" or "down!\n")..[[
  Steam store is ]]..(steamData.SteamStore.online == 1 and "up!\n" or "down!\n")..[[
  Steam community is ]]..(steamData.SteamCommunity.online == 1 and "up!" or "down!"))
	end
end