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

	message.Chat:SendMessage(
[[Hey! My name is _HC1WDN4Sbot! I'm a Skype bot that does some useful and/or fun things.
  My creator: xx_killer_xx_l (he hates his Skype login)
  I'm on GitHub: https://github.com/S4NDW1CH/_HC1WDN4Sbot
  Current version: ]]..bot.version)
end

function system.help(message, help)
	local commands = bot.availableCommands()
	local pageNo = tonumber(help)
	if pageNo then
		if (pageNo > math.ceil(#commands/5)) or (pageNo < 1) then
			message.Chat:SendMessage("Help: page "..pageNo.."/"..math.ceil(#commands/5).." ("..#commands.." total commands).\n"..--[[
								   ]]"Use !help pageNo to display desired page or use !help command to display info about specific command.\n"..--[[
								   ]]"There doesn't seem to be anything here. (worry)")
		else
			local res = ""
			for i=1 + (5*(pageNo - 1)), 5 + (5*(pageNo - 1)) do
				if not commands[i] then break end
				res = res.."\n!"..commands[i].."\t"..(bot.getDescription(commands[i]) or "")
			end
			message.Chat:SendMessage("Help: page "..pageNo.."/"..math.ceil(#commands/5).." ("..#commands.." total commands).\n"..--[[
								   ]]"Use !help pageNo to display desired page or use !help command to display info about specific command.\n"..--[[
								   ]]"Available commands:"..res)
		end

	elseif #help > 0 then
		if bot.isRegistered(help) then
			local info = bot.getDetailedDescription(help)
			if info then
				message.Chat:SendMessage(help..": "..info)
			else
				message.Chat:SendMessage(help..": no detailed information available.")
			end
		else
			message.Chat:SendMessage("Help: command "..help.." is not available.")
		end
	else
		local res = ""
		for i=1, 5 do
			if not commands[i] then break end
			res = res.."\n!"..commands[i].."\t"..(bot.getDescription(commands[i]) or "") 
		end
		message.Chat:SendMessage("Help: page 1/"..math.ceil(#commands/5).." ("..#commands.." total commands).\n"..--[[
							   ]]"Use !help pageNo to display desired page or use !help command to display info about specific command.\n"..--[[
							   ]]"Available commands:"..res)
	end
end


--EOF