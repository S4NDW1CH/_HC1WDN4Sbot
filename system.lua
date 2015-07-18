--Global definitions variables and constants

system = {}

local motd = {}


--Functions and methods

function system.debugGetChatVar(message, varName)
	local chatEnv = bot.getChatEnvironment(message.Chat.Blob)
	message.Chat:SendMessage(varName.." = "..(chatEnv[varName] or "nil"))
end

function system.debugSetChatVar(message, varName, val)
	print(varName, val)
	val = tonumber(val) or val
	if val == "true" then val = true end
	if val == "false" then val = false end
	bot.getChatEnvironment(message.Chat.Blob)[varName] = val
	message.Chat:SendMessage(varName.." = "..bot.getChatEnvironment(message.Chat.Blob)[varName] or "nil")
end

function system.motd(message)
	message.Chat:SendMessage(motd[message.Chat.Blob] or "No MOTD available for this chat.\nTo set MOTD for this chat user with helper, master or creator status must run !setmotd in this chat.")
end

function system.setMOTD(message, text)
	motd[message.Chat.Blob] = text
	message.Chat:SendMessage("MOTD has been set to "..(motd[message.Chat.Blob] or "... Actually it hasn't been set to anything. I suspect something went wrong. You should check logs to confirm that."))
end

function system.reload(message)
	print("info", "Received command to reload modules. Reloading...")
	message.Chat:SendMessage("Reloading modules, please wait...")

	bot.loadModules(message)
end

function system.status(message)
	print("info", "Received status command.")

	message.Chat:SendMessage("Current statistics:\n".."  Number of modules loaded: "..#bot.loadedModules().."\n  Uptime: "..string.format("%d day(s) %.2d:%.2d:%.2d", os.clock()/(60*60*24), (os.clock()/(60*60))%24, os.clock()/60%60, os.clock()%60))
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