--GLOBAL: onLoad

require "lfs"
require "json"

local users = {}
local ct

local function initUser(username, balance)
	users[username] = {
		balance = balance or 30
	}

	local file = io.open("./modules/"..name.."/users.json", "w")
	file:write(json.encode(users))
	file:close()
end

local function setBalance(username, balance)
	users[username].balance = balance
end

local function add(username, amount)
	users[username].balance = users[username].balance + amount
end

local function sub(username, amount)
	return add(username, -amount)
end

local function getBalance(username)
	return users[username].balance
end

function tip(chat, message, param)
	local usernameTo, amount = string.match(param, "^([^%s%z\t\n]+)%s+(%d+)")
	local usernameFrom = message.fromHandle

	print("info", "'"..usernameTo.."' '".. amount.."'".."\t"..(tostring(users[usernameTo]) or ":("))

	if not users[usernameFrom] then message.chat:sendMessage("You are not registered in BUTERBUCKS system. Please use !buckregister to be able to send tips."); return end
	if not usernameTo          then message.chat:sendMessage("Please specify user to whom send tip."); return end
	if not users[usernameTo]   then message.chat:sendMessage("User that you want to send tip to is not registered in the BUTERBUCKS system."); return end
	if not amount              then message.chat:sendMessage("Please specify amount to send to user."); return end

	local recStart = getBalance(usernameTo)
	local senStart = getBalance(usernameFrom)

	if senStart < 0 then message.chat:sendMessage("You don't have enough Buterbucks to complete transaction."); return end

	sub(usernameFrom, amount)
	if getBalance(usernameFrom) ~= senStart-amount then
		message.chat:sendMessage("Error completing transaction. Transaction not complete.")
		add(usernameFrom, amount)
		return
	end

	add(usernameTo, amount)

	message.chat:sendMessage("Successfully send "..amount.." Buterbuck(s) to "..usernameTo..".")
	print("info", "Transaction: to="..usernameTo.." from="..usernameFrom.." amount="..amount)
end

function register(chat, message)
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

function checkBalance(chat, message)
	message.chat:sendMessage(message.fromDisplayName.."'s account balance is "..getBalance(message.fromHandle).." buterbuck(s).")
end

function onLoad()
	lfs.mkdir(".\\modules\\"..name)
	local file = io.open(".\\modules\\"..name.."\\users.json", "r")
	if file then
		users = json.decode(file:read("*a"))
		file:close()
	else
		file = io.open(".\\modules\\"..name.."\\users.json", "w")
		file:write(json.encode(users))
		file:close()
	end

	bot.registerCommand{name="check", func=checkBalance}
	bot.registerCommand{name="tip", func=tip}
	bot.registerCommand{name="registerb", func=register}
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