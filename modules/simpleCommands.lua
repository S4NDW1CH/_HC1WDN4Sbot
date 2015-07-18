replys = {}
justRegistered = false

function onLoad()
	bot.registerCommand{name = "reply", func = reply, pattern = "([^~]+)[\t%s]*~[\t%s]*(.+)", admin = true}
end

local function save()
	local file = io.open("chat_replys.json", "w")
	file:write("{")
	local t = {}
	for chat, words in pairs(replys) do
		local c = "\""..chat.."\":{"
		for word, reply in pairs(words) do
			local t1 = {}
			table.insert(t1, "\""..word.."\":\""..reply.."\"")
			c = c..table.concat(t1, ",")
		end
		table.insert(t, c.."}")
	end
	file:write(table.concat(t, ","))
	file:write("}")
	file:close()
end

function reply(message, word, rep)
	justRegistered = true
	oWord = word
	word = string.gsub(word, "([%(%)%.%^%$%%%-%+%*%?])", "%%%0")
	word = string.gsub(word, "(%%%*)", "%.%*")
	replys[message.Chat.Blob] = {}
	replys[message.Chat.Blob][word] = rep
	
	message.Chat:SendMessage("Now replying to "..oWord.." with "..replys[message.Chat.Blob][word]..".")
	save()
end

function messageReceived(message)
	if justRegistered then justRegistered = false; return end
	if not replys[message.Chat.Blob] then return print("Ain't got no replys son.") end
	for word, rep in pairs(replys[message.Chat.Blob]) do
		for _ in message.Body:gmatch("("..word..")") do
			message.Chat:SendMessage(rep)
		end
	end
end