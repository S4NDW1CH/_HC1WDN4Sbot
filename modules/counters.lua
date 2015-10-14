require "json"
require "lfs"

local counters = {}

function onLoad()
	lfs.mkdir(".\\modules\\"..name)
	local file = io.open(".\\modules\\"..name.."\\counters.json", "r")
	if file then
		counters = json.decode(file:read("*a"))
		file:close()
	else
		local file = io.open(".\\modules\\"..name.."\\counters.json", "w")
		file:write(json.encode(counters))
		file:close()
	end

	bot.registerCommand{name = "counter", func = newCounter, admin = true}
	bot.registerCommand{name = "count", func = newCounter, admin = true}
	bot.registerCommand{name = "deleteCounter", func = deleteCounter, admin = true}
	bot.registerCommand{name = "counterList", func = listCounters}
end

function newCounter(message, str)
	if not str or #str < 1 then
		return message.chat:sendMessage("Must specify what to count.")
	end

	counters[str] = {count = 0, cooldown = 0}
	message.chat:sendMessage("Counter has been created.")
end

function deleteCounter(message, counter)
	counters[counter or ""] = nil
	message.chat:sendMessage("Counter has been deleted.")
end

function listCounters(message)
	local list = ""
	for name, counter in pairs(counters) do
		list = list.."\n"..name.." : "..counter.count
	end
	message.chat:sendMessage(list)
end

function messageReceived(message)
	for str, counter in pairs(counters) do
		if not counter.cooldown then counter.cooldown = 0 end
		
		strEscaped = str:gsub("([%%%.%*%(%)%^%$%+%-%[%]])", "%%%0")
		local increased = false
		for _ in message.body:gmatch("("..strEscaped..")") do
			counter.count = counter.count + 1
			increased = true
		end

		if increased and os.time() > counter.cooldown + 120 then
			message.chat:sendMessage(str.." count: "..counter.count)
			increased = false
			counter.cooldown = os.time()
		end
	end

	local file = io.open(".\\modules\\"..name.."\\counters.json", "w+")
	file:write(json.encode(counters))
	file:close()

	return true
end