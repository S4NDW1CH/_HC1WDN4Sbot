function onLoad()
	bot.registerCommand{name = "reply", func = reply, pattern = "([^\t%s]+)[\t%s]*(.+)", admin = true}
end

function reply(message, command, r)
	if bot.registerCommand{name = command, func = function(msg) msg.Chat:SendMessage(""..r) end} then
		message.Chat:SendMessage("Command "..command.." successfully registered.")
	else
		message.Chat:SendMessage("Could not register "..command..".")
	end
end