--Global definitions variables and constants

system = {}


--Functions and methods

function system.reload(message)
	print("info", "Received command to reload modules. Reloading...")
	message.Chat:SendMessage("Reloading modules, please wait...")

	bot.loadModules(message)
end

function system.status(message)
	print("info", "Received status command.")

	message.Chat:SendMessage("Current statistics:\n".."  Number of modules loaded: "..#bot.loadedModules().."\n  Uptime: "..string.format("%.2d:%.2d:%.2d", os.clock()/(60*60), os.clock()/60%60, os.clock()%60))
end

function system.about(message)
	print("info", "Received about command.")

	message.Chat:SendMessage("Hey! My name is _HC1WDN4Sbot! I'm a Skype bot that does some useful and/or fun things.\n"..--[[
						   ]]"  My creator: xx_killer_xx_l (he hates his Skype login)\n"..--[[
						   ]]"  I'm on GitHub: https://github.com/S4NDW1CH/_HC1WDN4Sbot\n"..--[[
						   ]]"  Current version: "..bot.version)
end


--EOF