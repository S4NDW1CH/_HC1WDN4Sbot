function onLoad()
	bot.registerCommand{name = "reply", func = reply, pattern = "([%w_]+)[\t%s]*(.*)", admin = true}
end

function reply(message, command, reply)
	if bot.registerCommand{name = command, func = function(msg) msg.Chat:SendMessage(reply) end} then
		message.Chat:SendMessage("Command "..command.." successfully registered.")
	else
		message.Chat:SendMessage("Could not register "..command..".")
	end
end