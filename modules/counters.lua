require "json"
require "lfs"

local counters = {}
local globalCounterCooldown = 0
local hourlyMessageCounter = 0
local currentTimer

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

	currentTimer = timer.newTimer{type = "delay", time = 60}

	for _, counter in pairs(counters) do
		counter.hourlyCount = 0
	end
end

function newCounter(message, str)
	if not str or #str < 1 then
		return message.chat:sendMessage("Must specify what to count.")
	end

	counters[str] = {count = 0, hourlyCount = 0, cooldown = 0}
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
	hourlyMessageCounter = hourlyMessageCounter + 1
	print("Daily message counter: "..hourlyMessageCounter)

	for str, counter in pairs(counters) do
		if not counter.cooldown then counter.cooldown = 0 end
		if not counter.hourlyCount then counter.hourlyCount = 0 end
		if not counter.messageCooldown then counter.messageCooldown = 0 end
		
		strEscaped = str:gsub("([%%%.%*%(%)%^%$%+%-%[%]])", "%%%0")
		local increased = false
		for _ in message.body:gmatch("("..strEscaped..")") do
			counter.count = counter.count + 1
			counter.hourlyCount = counter.hourlyCount + 1
			increased = true
		end

		if  increased
			and os.time() > counter.cooldown + 600 
			and counter.messageCooldown <= 0
			and globalCounterCooldown <= 0
		then
			message.chat:sendMessage(str.." count: "..counter.count..
			"\nDaily "..str.." index: "..string.format("%1.1f", 100 * counter.hourlyCount/(hourlyMessageCounter == 0 and 1 or hourlyMessageCounter)))
			increased = false
			counter.cooldown = os.time()
			counter.messageCooldown = 10
			globalCounterCooldown = 10
		end

		counter.messageCooldown = counter.messageCooldown - 1
		globalCounterCooldown = globalCounterCooldown - 1
	end

	local file = io.open(".\\modules\\"..name.."\\counters.json", "w+")
	file:write(json.encode(counters))
	file:close()

	return true
end

function timerTriggered(t)
	if t == currentTimer then
		t:delete()
		currentTimer = timer.newTimer{type = "delay", time = 60}
		if os.date("%H%M", os.time()) == "0000" then
			hourlyMessageCounter = 0
			for _, counter in pairs(counters) do
				counter.hourlyCount = 0
			end
		end
	end
end