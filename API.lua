--Load modules
require "lfs"
json = require "json"


--Global definitions variables and constants

bot = {} --Namespace

bot.version = "0.7"

local modules = {}
local modNames = {}
local commandRegestry = {}

--local chats = {}


--Functions and methods
local function loadModule(filename, message)
	print("info", "Loading "..filename)
	if message then message.Chat:SendMessage("Loading "..filename) end

	local module, err = loadfile(filename)
	if not module then
		if message then message.Chat:SendMessage("Error loading module "..filename..":\n"..err) end
		return print("error", "Error loading module "..filename..":\n"..err)
	end

	local env = {}

	env._G = env
	env._ENV = env
	env._VERSION = _VERSION
	env.assert = assert
	env.dofile = dofile
	env.error = error
	env.getmetatable = getmetatable
	env.getfenv = getfenv
	env.ipairs = ipairs
	env.load = load
	env.loadfile = loadfile
	env.loadstring = loadstring
	env.next = next
	env.pairs = pairs
	env.pcall = pcall
	env.print = print
	env.rawequal = rawequal
	env.rawget = rawget
	env.rawlen = rawlen
	env.rawset = rawset
	env.require = require
	env.select = select
	env.setmetatable = setmetatable
	env.setfenv = setfenv
	env.tonumber = tonumber
	env.tostring = tostring
	env.type = type
	env.xpcall = xpcall

	env.corouine = coroutine
	env.io = io
	env.math = math
	env.os = os
	env.package = package
	env.string = string
	env.table = table
	env.utf8 = utf8

	env.bot = bot
	env.filenamename = string.match(filename, ".\\([%w%s_%.#]*%.lua)")
	env.name = env.name or string.match(filename, ".\\([%w%s_%.#]*)%.lua")

	setfenv(module, env)
	local success, msg = pcall(module)

	if not success then
		if message then message.Chat:SendMessage("Error on initializing "..filename..":\n"..(msg or "")) end
		return print("error", "Error on initializing "..filename..":\n"..(msg or ""))
	end

	success, msg = pcall(env.onLoad)

	if not success and env.onLoad then print("error", "Error handling onLoad event in module "..env.name..":\n"..(msg or "no error message available")) end

	env.enabled = true

	table.insert(modules, env)
	modNames[env.name] = #modules
end

function toggleModule(module)
	modules[modNames[module]].enabled = not modules[modNames[module]].enabled
	return modules[modNames[module]].enabled
end

function bot.isLoaded(module)
	return modNames[module] and true or false
end

function bot.loadModules(message)
	print("info", "Loading modules...")

	--First, clear array of modules
	modules = nil
	modules = {}

	--Also, clear command registry
	commandRegestry = nil
	commandRegestry = {}

	--Don't forget to load system commands
	print("info", "Registering system commands.")
	bot.registerCommand{name = "reload", func = system.reload, admin = true}
	bot.registerCommand{name = "status", func = system.status}
	bot.registerCommand{name = "about", func = system.about}
	bot.registerCommand{name = "help", func = system.help, pattern = "([^\n\t%z%s]*)", description = "this message", detailedDescription = "//HERE BE DRAGONS"}
	bot.registerCommand{name = "motd", func = system.motd}
	bot.registerCommand{name = "setmotd", func = system.setMOTD, admin = true}
	--bot.registerCommand{name = "setChatVar", func = system.debugSetChatVar, admin = true, pattern = "([%d%w]+)%s*=%s*(.+)"}
	--bot.registerCommand{name = "getChatVar", func = system.debugGetChatVar, admin = true}
	bot.registerCommand{name = "loaded", func = system.loadedModules}
	bot.registerCommand{name = "disable", func = system.disableModule, admin = true}

	--Next, iterate through all .lua files in \modules directory and load each file
	lfs.mkdir("modules")
	for filename in lfs.dir(".\\modules\\") do
		if string.match(filename, "[_%-%w%s]*%.lua$") then
			loadModule(".\\modules\\"..filename, message)
		end
	end

	--And now we are ready to go!
	print("info", "All modules were loaded.")
	if message then message.Chat:SendMessage("All modules were successfully loaded.") end
end

function bot.loadedModules()
	local ret = {}
	for _, mod in ipairs(modules) do
		ret[mod.name] = mod.enabled
	end
	return ret
end

function bot.availableCommands()
	local res = {}
	for command, _ in pairs(commandRegestry) do
		table.insert(res, command)
	end
	return res
end

function bot.getDescription(command)
	return commandRegestry[command].description
end

function bot.getDetailedDescription(command)
	return commandRegestry[command].detailedDescription
end

function bot.parseConfig(filename)
	print("info", "Parsing "..filename.."...")

	local tConfig = {}
	local file = io.open("config.cfg", "r")
	if not file then print("warn", filename.." not found"); return nil end

	for line in file:lines() do
		if (not string.match(line, "#.")) and #line > 0 then
			local var, val = string.match(line, "[%s\t]*([_%w]+)[%s\t]*=[%s\t]*([^\n]+)")

			if not ((not var) or (not val) or (#var < 1) or (#val < 1)) then
				val = (tonumber(val) or val)
				val = (val == "true" or val)
				if val == "false" then val = false end 
				tConfig[var] = val
			end
		end
	end
	file:close()

	return tConfig
end

--[[function bot.getChatEnvironment(blob)
	print("Getting chat environment.")
	local file = io.open(".\\chats\\"..blob..".json", "r")
	print(file)
	if file and not chat[blob] then
		local content = file.read("*a")
		print(content)
		rawset(chats, blob, json.decode(content or "{}")) --Is this considered as hack? If so then I'm sorry. :(
	end

	return chats[blob], print("Got chat environment.")
end

function bot.createChatEnvironment(blob)
	print("Setting chat environment.")
	if not chats[blob] then
		chats[blob] = {}
		setmetatable(chats[blob], {__newindex = function(table, key, value)
			rawset(table, key, value)
			lfs.mkdir("chats")
			local file = io.open(".\\chats\\"..blob..".json", "w")
			file:write(json.encode(chats[blob]))
			file:close()
		end})

		return true, print("Chat environment created.")
	end

	return false, print("Chat environment already exists.")
end]]

function bot.registerCommand(command)
	if not command.name then 
		return false, print("error", "Error registering command: name not specified (name = "..tostring(command.name)..").") 
	end
	if not command.func then 
		return false, print("error", "Error registering command: no function specified.")
	end

	local env = getfenv(command.func)
	if (not env.name) and (env ~= _G) then 
		return false, print("error", "Error registering command: module metadata not found (env.name is"..env.name..").") 
	end

	if commandRegestry[command.name] and (commandRegestry[command.name].owner ~= (env == _G and "system" or env.name)) then
		return false, print("error", "Error registering command: command already registered by another module (owner = "..commandRegestry[command.name].owner..").")
	end

	print("info", "Registering command "..command.name..".")
	commandRegestry[command.name] = {pattern = command.pattern, func = command.func, admin = command.admin, description = command.description, detailedDescription = command.detailedDescription, owner = (env == _G and "system" or env.name)}
	return true
end

function bot.isRegistered(command)
	if commandRegestry[command] then
		return true
	else
		return false
	end
end

function bot.unregisterCommand(command)
	print("info" ,"Unregistering command "..command..".")
	commandRegestry[command] = nil
end

local function callCommandFunction(command, ...)
	local s, e = pcall(commandRegestry[command].func, table.unpack({...}))
	if not s then print("error", "Error while executing command "..command..":\n"..e) end
end

function bot.callEvent(e, ...)
	local args = {...}
	print("Parsing event "..e)
	
	if e == "messageReceived" then
		--if not chats[args[1].Chat.Blob] then chats[args[1].Chat.Blob] = {} end

		for _, command, commandArgs in string.gmatch(args[1].Body, "(!)([^\n\t%z%s!]+)[\t\n%z%s]*([^!%z]*)") do

			print("Captured a command.", "_=".._, "command="..command, "commandArgs="..commandArgs)
			if _ == "!" then
				if commandRegestry[command] then
					if commandRegestry[command].admin then
						for i = 1, args[1].Chat.MemberObjects.Count do
							if args[1].Chat.MemberObjects:Item(i).Handle == args[1].FromHandle then
								if ((args[1].Chat.MemberObjects:Item(i).Role <= 2) and (args[1].Chat.MemberObjects:Item(i).Role >= 0)) or (args[1].FromHandle == "xx_killer_xx_l") then
									callCommandFunction(command, args[1], string.match(commandArgs, commandRegestry[command].pattern or "(.*)"))
									print("info", "User "..args[1].FromHandle.." executed administrative command "..command..".")
								else
									print("info", "User "..args[1].FromHandle.." does not have enough privileges to execute "..command..".")
								end
							end
						end
					else
						callCommandFunction(command, args[1], string.match(commandArgs, commandRegestry[command].pattern or "(.*)"))
						print("info", "User "..args[1].FromHandle.." executed "..command..".")
					end				
				end
			end
		end
	end

	for _, mod in ipairs(modules) do
		if mod[e] then print("Module "..mod.name.." has event handler for "..e..".") end
		if mod.enabled then
			local succes, msg = pcall(mod[e], table.unpack(args))
			if not succes and mod[e] then print("error", "Error while calling event handler "..e.." in module "..mod.name..": "..msg) end
		end
	end
end

--EOF