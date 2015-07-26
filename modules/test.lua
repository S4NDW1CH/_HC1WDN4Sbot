require "bit"

function onLoad()
	bot.registerCommand{name = "choice", func = choice, pattern = "(.+)"}
	bot.registerCommand{name = "8ball", func = ball, pattern = "(.+)"}
end

function hash(str)
	local remainder
	local hash = 0
	if #str%2 ~= 0 then
		remainder = string.byte(str, #str, #str)
		str = string.sub(str, 1, #str-1)
	end

	for i = 1, #str, 2 do
		hash = bit.bxor(hash, bit.bxor(string.byte(str, i, i+1)))
	end

	return bit.bxor(hash, remainder or 0)
end

function getBallResponse(hash)
	local file = io.open(".\\modules\\ballResponses.txt", "r")

	local responseList = {}
	for line in file:lines() do
		table.insert(responseList, line)
	end

	math.randomseed(hash)
	math.random();math.random();math.random()

	return responseList[math.random(#responseList)]
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

function choice(message, args)
	local options = {} 
	for option in args:gmatch(",?%s*([^%,%.\n\t%z]*),?") do
		table.insert(options, option)
	end
	print("info", "Choosing something...")
	math.randomseed(os.clock()/math.random())
	math.random();math.random();math.random()

	message.Chat:SendMessage("How about "..options[math.random(#options)]..", "..message.FromDisplayName.."?")
end

function ball(message, question)
	math.randomseed(os.clock()/math.random())
	math.random();math.random();math.random()

	message.Chat:SendMessage(getBallResponse(hash(question)))
end

function messageReceived(message)
	for amount, sides in message.Body:gmatch("!(%d*)d(%d+)") do
		print("info", tostring(amount))
		message.Chat:SendMessage(message.FromDisplayName.." rolled "..dice((#amount > 0 and amount or 1), sides))
	end

	return true
end