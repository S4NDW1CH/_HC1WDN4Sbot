ballResponses = {"No.", "Yes.", "Maybe.", "Not now.", "Ask your mother.", "Ask your father.", "I dunno.",
 				 "Umm... Maybe?", "Yes for sure!", "No for sure!", "I can't answer that.",
 				 "Probably not.", "Probably yes.", "Ask GabeN. He knows that for sure.",
 				 "Not now, I'm busy.", "If I'd answer that, it wouldn't be fun.",
 				 "Really? You are asking me about THIS?", "4", "42",
 				 "I think there's something in the Guide about this.", "EW!", "Let me think about this for a moment.",
 				 "You sure you want an answer to that?", "Even I don't know answer to that.", "Don't worry about that.",
 				 "Don't think about that.", "You shouldn't worry about that.", "Not anymore.",
 				 "I would give an answer, but I'm too tired right now.", "Nah", "Meh", "Yeah", "Nope", "Uhh..",
 				 "Go play some TF2 instead.", "Go play some CS:GO instead.", "Go play some games instead."}

function onLoad()
	bot.registerCommand{name = "test", func = test}
end

function test()
	-- body
end

function dice(amount, sides)
	print("info", "Rolling some die...")

	math.randomseed(os.clock()/math.random())
	math.random();math.random();math.random()

	local result = {}
	for d = 1, amount do
		table.insert(result, math.random(sides))
	end

	return table.concat(result, " + ")
end

function choice(options)
	print("info", "Choosing something...")
	math.randomseed(os.clock()/math.random())
	math.random();math.random();math.random()

	return options[math.random(#options)]
end

function messageReceived(message)
	for amount, sides in message.Body:gmatch("!(%d*)d(%d+)") do
		print("info", tostring(amount))
		message.Chat:SendMessage(message.FromDisplayName.." rolled "..dice((#amount > 0 and amount or 1), sides))
	end

	for str in message.Body:gmatch("!choice (.+)") do
		local options = {} 
		for option in str:gmatch(",?%s*([%w%s]*),?") do
			table.insert(options, option)
		end

		message.Chat:SendMessage("How about "..choice(options)..", "..message.FromDisplayName.."?")
	end

	for _ in message.Body:gmatch("!8ball .+") do
		print("info", "Answering the question...")
		math.randomseed(os.clock()/math.random())
		math.random();math.random();math.random()
		message.Chat:SendMessage(ballResponses[math.random(#ballResponses)])
	end
	return true
end