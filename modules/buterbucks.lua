--GLOBAL: onLoad

require "lfs"
require "json"

local users = {}
local ct

local function initUser(name, balance)
	table.insert(users, {
		name = name,
		balance = balance or 30
	})
	users[name]=#users

	local file = io.open(".\\modules\\"..name.."\\users.json", "w")
	file:write(json.encode(users))
	file:close()
end

local function setBalance(name, balance)
	users[users[name]].balance = balance
end

local function add(name, amount)
	users[users[name]].balance = users[users[name]].balance + amount
end

local function sub(name, amount)
	return add(name, -amount)
end

local function getBalance(name)
	return users[users[name]].balance
end

function tip(message, param)
	local nameTo, amount = string.match("^([^%s%z\t\n]+)(%d+)")
	local nameFrom = message.fromHandle

	if not users[nameFrom] then message.chat:sendMessage("You are not registered in BUTERBUCKS system. Please use !buckregister to be able to send tips."); return end
	if not nameTo          then message.chat:sendMessage("Please specify user to whom send tip."); return end
	if not users[nameTo]   then message.chat:sendMessage("User that you want to send tip to is not registered in the BUTERBUCKS system."); return end
	if not amount          then message.chat:sendMessage("Please specify amount to send to user."); return end

	local recStart = getBalance(nameTo)
	local senStart = getBalance(nameFrom)

	if senStart < 0 then message.chat:sendMessage("You don't have enough Buterbucks to complete transaction."); return end

	sub(nameFrom, amount)
	if getBalance(nameFrom) ~= senStart-amount then
		message.chat:sendMessage("Error completing transaction. Transaction not complete.")
		add(nameFrom, amount)
		return
	end

	add(nameTo, amount)

	message.chat:sendMessage("Successfully send "..amount.." Buterbuck(s) to "..skype.searchForUsers(nameTo).item(0).fullName..".")
	print("info", "Transaction: to="..nameTo.." from="..nameFrom.." amount="..amount)
end

function register(message)
	local user = message.fromHandle

	if not users[user] then
		initUser(user)
		message.chat:sendMessage("Successfully registered "..user..".")
	else
		message.chat:sendMessage(user.." already registered.")
	end
end

function reloadDB(m)
	local file = io.open(".\\modules\\"..name.."\\users.json", "r")
	users = json.decode(file:read("*a"))
	file:close()
	m.chat:sendMessage("Database has been reloaded.")
end

function onLoad()
	lfs.mkdir(".\\modules\\"..name)
	local file = io.open(".\\modules\\"..name.."\\users.json", "r")
	if file then
		users = json.decode(file:read("*a"))
		file:close()
	else
		local file = io.open(".\\modules\\"..name.."\\users.json", "w")
		file:write(json.encode(users))
		file:close()
	end

	bot.registerCommand{name="tip", func=tip}
	bot.registerCommand{name="buckregister", func=register}
	bot.registerCommand{name="reloadDB", func=reloadDB, admin=true}

	ct = timer.newTimer{type="delay", time=3600}
end

function timerTriggered(t)
	if t == ct then
		t:delete()
		ct = timer.newTimer{type="delay", time=3600}
		for id, user in ipairs(users) do
			user.balance=user.balance+1
		end
	end
end