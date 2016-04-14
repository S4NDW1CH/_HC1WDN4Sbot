require "json"
require "lfs"

local lastMidnight = 0

function onLoad()
	bot.registerCommand{name = "counter", func = newCounter, admin = true}
	bot.registerCommand{name = "count", func = newCounter, admin = true}
	bot.registerCommand{name = "c", func = newCounter, admin = true}
	bot.registerCommand{name = "deleteCounter", func = deleteCounter, admin = true}
	bot.registerCommand{name = "dc", func = deleteCounter, admin = true}
	bot.registerCommand{name = "setCount", func = setCount, admin = true, pattern="([^%s%z\t\n]+)(%d)*"}
	bot.registerCommand{name = "sc", func = setCount, admin = true, pattern="([^%s%z\t\n]+)(%d)*"}
	bot.registerCommand{name = "listCounters", func = listCounters}
	bot.registerCommand{name = "lc", func = listCounters}
end

local function initChatEnv(chat)
	chat.counters = {}
	chat._cMeta = {
		dailyMessageCounter = 0,
		chatCooldownMessages = 0,
		lastReset = 0
	}
end

function newCounter(chat, message, str)
	if not str or #str < 1 then
		return message.chat:sendMessage("Must specify what to count.")
	end

	chat.counters[str] = {
		count = 0,
		dailyCount = 0, 
		cooldownTimer = 0, 
		countdownMessages = 0,
	}

	message.chat:sendMessage("Counter has been created.")
end

function setCount(chat, message, counter, count)
	if not chat.counters[counter or ""] then
		return message.chat:sendMessage("Invalid counter specified.")
	end

	chat.counters[conter].count = count
	message.chat:sendMessage(counter.." count is now set to "..count)
end

function deleteCounter(chat, message, counter)
	if not chat.counters[counter or ""] then
		return message.chat:sendMessage("Invalid counter specified.")
	end
	chat.counters[counter] = nil
	message.chat:sendMessage("Counter has been deleted.")
end

function listCounters(chat, message)
	local list = ""
	for name, counter in pairs(chat.counters) do
		list = list.."\n"..name.." : "..counter.count
	end
	message.chat:sendMessage(list)
end



function messageReceived(chat, message)
	if not chat._cMeta then initChatEnv(chat) end

	if chat._cMeta.lastReset <= lastMidnight then
		chat._cMeta.lastReset = os.time()
		chat._cMeta.dailyMessageCounter = 0

		for _, counter in pairs(chat.counters) do
			counter.dailyCount = 0
		end
	end

	chat._cMeta.dailyMessageCounter = chat._cMeta.dailyMessageCounter + 1

	for str, counter in pairs(chat.counters) do

		strEscaped = str:gsub("([%%%.%*%(%)%^%$%+%-%[%]])", "%%%0")
		local increased = false
		for _ in message.body:gmatch("("..strEscaped..")") do
			counter.count = counter.count + 1
			counter.dailyCount = counter.dailyCount + 1
			increased = true
		end

		if  increased
			and (os.time() > counter.cooldownTimer + 600)
			and (counter.messageCooldown <= 0)
			and (chat._cMeta.chatCooldownMessages <= 0)
		then
			--How do format code pls answer fast
			message.chat:sendMessage(str.." count: "..counter.count..
			"\nDaily "..str.." index: "..
			string.format("%1.1f", 100 * counter.dailyCount/(chat._cMeta.dailyMessageCounter == 0 and 1 or chat._cMeta.dailyMessageCounter)))
			
			counter.cooldown = os.time()
			counter.messageCooldown = 11
			chat._cMeta.chatCooldownMessages = 11
		end

		counter.messageCooldown = counter.messageCooldown - 1
	end
	chat._cMeta.chatCooldownMessages = chat._cMeta.chatCooldownMessages - 1
end

function timerTriggered(t)
	if t == currentTimer then
		t:delete()
		currentTimer = timer.newTimer{type = "delay", time = 60}
		if os.date("%H%M", os.time()) == "0000" then
			lastMidnight = os.time()
		end
	end
end