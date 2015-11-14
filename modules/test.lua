--GLOBALS: onLoad, bot. bit, string, math, table, io, os, choice, ball, roll
require "bit"

function onLoad()
	bot.registerCommand{name = "choice", func = choice, pattern = "(.+)"}
	bot.registerCommand{name = "8ball", func = ball, pattern = "(.+)"}
	bot.registerCommand{name = "8", func = ball, pattern = "(.+)"}
	bot.registerCommand{name = "roll", func = roll}
	bot.registerCommand{name = "r", func = roll}
end

local function hash(str)
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

local function getBallResponse()
	local file = io.open(".\\modules\\ballResponses.txt", "r")

	local responseList = {}
	for line in file:lines() do
		table.insert(responseList, line)
	end

	return responseList[math.random(#responseList)]
end

local function dice(amount, sides)

	local result = {}
	for d = 1, amount do
		table.insert(result, math.random(sides))
	end

	return table.concat(result, " + ")
end

function choice(message, args)
	if not args then
		return message.Chat:SendMessage("I CHOSE NOTHING!")
	end

	local options = {} 
	for option in args:gmatch(",?%s*([^%,%.\n\t%z]*),?") do
		table.insert(options, option)
	end

	--This construct here needed because sometimes choice
	--ends up being zero-length string and I have absolutely
	--no idea why. :(
	local choice
	repeat 
		choice = options[math.random(1, #options)]
	until (choice and #choice > 0)

	message.Chat:SendMessage("How about "..choice..", "..message.FromDisplayName.."?")
end

function ball(message, question)
	message.Chat:SendMessage(getBallResponse(hash(question)))
end

function roll(message, roll)
	local amount, sides = string.match(roll or "1d20", "(%d*)d(%d+)")
	message.chat:sendMessage(message.FromDisplayName.." rolled "..dice((amount and amount > 0) and amount or 1, sides or 20))
end

--[[function messageReceived(message)
	for amount, sides in message.Body:gmatch("!(%d*)d(%d+)") do
		print("info", tostring(amount))
		message.Chat:SendMessage(message.FromDisplayName.." rolled "..dice((amount > 0 and amount or 1), sides))
	end

	return true
end]]