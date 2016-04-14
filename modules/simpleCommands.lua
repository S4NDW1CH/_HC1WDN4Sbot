--GLOBALS: onLoad. messageReceived, lfs, json, bot, string, print, io, pairs, name
require "json"
require "lfs"

local registeredCommands = {}

function onLoad()
	lfs.mkdir(".\\modules\\"..name)
	local file = io.open(".\\modules\\"..name.."\\commands.json", "r")
	if file then
		registeredCommands = json.decode(file:read("*a"))
		file:close()
	else
		local file = io.open(".\\modules\\"..name.."\\commands.json", "w")
		file:write("{}")
		file:close()
	end

	for command, text in pairs(registeredCommands) do
		bot.registerCommand{name = command, func = function(message) message.chat:sendMessage(text) end}
	end

	bot.registerCommand{name = "command", func = command, admin = true}
	bot.registerCommand{name = "c", func = command, admin = true}
	bot.registerCommand{name = "commandlist", func = commandList, admin = true}
	bot.registerCommand{name = "cl", func = commandList, admin = true}
	bot.registerCommand{name = "commanddelete", func = deleteCommand, admin = true}
	bot.registerCommand{name = "cd", func = deleteCommand, admin = true}
end

function command(chat, message, param)
	local commandName, text = string.match(param, "^(%S+)%s*(.*)")
	print("info", param, commandName, text)

	bot.registerCommand{name = commandName, func = function(message) message.chat:sendMessage(text) end}
	registeredCommands[commandName] = text

	message.chat:sendMessage("Registered "..commandName..".")

	local file = io.open(".\\modules\\"..name.."\\commands.json", "w")
	file:write(json.encode(registeredCommands))
	file:close()
end

function commandList(chat, message)
	local s = ""

	for command, _ in pairs(registeredCommands) do
		s = s.."\n"..command
	end

	message.chat:sendMessage(s)
end

function deleteCommand(chat, message, command)
	local success = bot.unregisterCommand(command)
	if not success then
		message.chat.sendMessage("Could not delete "..command..".")
	end

	registeredCommands[command] = nil
	message.chat:sendMessage("Deleted "..command..".")
end