http = require "socket.http"
require "json"
xml = require "luaxml"

function onLoad()
	bot.registerCommand{name = "whatshouldiplay", func = selectGame}
	bot.registerCommand{name = "wsip", func = selectGame}
end

function selectGame(message, profile)
	profile = http.request("http://steamcommunity.com/id/"..profile.."/?xml=1")
	assert(profile, "Could not get XML data")

	profile = xml.eval(profile)
	assert(profile, "Could not process XML data")

	if prifile[1]:tag() == "error" then
		message.chat:sendMessage(profile[1][1])
	else

		local games = http.request("http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=AD09DAB8D35DB1BF3319083CF71C98B3&include_played_free_games=1&include_appinfo=1&steamid="..profile[1][1])
		assert(games, "Could not get JSON data")
		games = json.decode(games)
		assert(games, "Could not process JSON data")

		message.chat:sendMessage("How about you play "..games.response.games[math.random(#games.response.games)].name..", "..message.fromDisplayName.."?")
	end
end