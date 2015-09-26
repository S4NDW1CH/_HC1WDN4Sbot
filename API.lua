--Load modules
require "lfs"
json = require "json"


--Global definitions variables and constants

bot = {} --Namespace

bot.version = "0.8"

local modules = {}
local modNames = {}
local commandRegestry = {}

local moduleLoaders = {}

local eventQueue = {}

local chats = {}


--Functions and methods
local function loadModule(filename, message)
	print("info", "Loading "..filename)
	if message then message.Chat:SendMessage("Loading "..filename) end

	local mod, err = loadfile(filename)
	if not mod then
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
	env.ipairs = ipairs
	env.next = next
	env.pairs = pairs
	env.pcall = pcall
	env.print = print
	env.select = select
	env.setmetatable = setmetatable
	env.tonumber = tonumber
	env.tostring = tostring
	env.type = type
	env.xpcall = xpcall

	env.module = module

	env.package = {
		preload = {},
		path = package.path,
		cpath = package.cpath,

		loaded = {}
	}

	for name, lib in pairs(package.loaded) do
		if not (name == "_G" or name == "debug" or name == "package") then
			env.package.loaded[name] = lib
		end
	end

	env.require = function (m)
		local env = getfenv(2)

		print(m, env, env[string.match(m, "%.*(%w+)$")])

		if package.loaded[m] and not env.package.loaded[m] then
			if moduleLoaders[m] then
				local global = _G
				setfenv(0, env)
				env.package.loaded[m] = moduleLoaders[m]() or true
				setfenv(0, global)

			else
				for i = 1, 4 do
					local moduleLoader = package.loaders[i](m)

					if type(moduleLoader) == "function" then
						setfenv(moduleLoader, env)
						local lib = moduleLoader()
						env.package.loaded[m] = lib or true
						break
					end
				end
			end
			
		end

		if not env.package.loaded[m] then
			local errorMessage = ""
			local success = false

			for i = 1, 4 do
				local moduleLoader = package.loaders[i](m)

				if type(moduleLoader) ~= "function" then
					errorMessage = errorMessage .. moduleLoader or ""
				else
					success = true
					moduleLoaders[m] = moduleLoader
					local global = _G
					print(getfenv(moduleLoader), _G)
					setfenv(0, env)
					env.package.loaded[m] = moduleLoader() or true
					setfenv(0, global)
					break
				end
			end

			if not success then error("module '"..m.."' not found:"..errorMessage) end
		end

		return env.package.loaded[m]
	end

	env.bot = bot
	env.timer = timer


	for moduleName, module in pairs(package.loaded) do
		if module ~= _G or module ~= package or module ~= debug then
			env[moduleName] = module
		end
	end

	env.filenamename = string.match(filename, ".\\([%w%s_%.#]*%.lua)")
	env.name = env.name or string.match(filename, ".\\([%w%s_%.#]*)%.lua")

	setfenv(mod, env)
	local success, msg = pcall(mod)

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

function loadModules(message)
	print("info", "Loading modules...")

	--First, clear array of modules
	modules = {}

	--Also, clear command registry
	commandRegestry = {}

	--Don't forget to load system commands
	print("info", "Registering system commands.")
	bot.registerCommand{name = "reload", func = system.reload, admin = true}
	bot.registerCommand{name = "status", func = system.status}
	bot.registerCommand{name = "about", func = system.about}
	bot.registerCommand{name = "help", func = system.help, pattern = "([^\n\t%z%s]*)", description = "this message", detailedDescription = "//HERE BE DRAGONS"}
	bot.registerCommand{name = "motd", func = system.motd}
	bot.registerCommand{name = "setmotd", func = system.setMOTD, admin = true}
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
	local moduleList = {}
	for _, mod in ipairs(modules) do
		moduleList[mod.name] = mod.enabled
	end
	return moduleList
end

function bot.availableCommands()
	local commandList = {}
	for command, _ in pairs(commandRegestry) do
		table.insert(commandList, command)
	end
	return commandList
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
	local env = getfenv(2)

	if env.name ~= commandRegestry[command].owner then
		print("error", "Could not unregister command: permission denied.")
		return false
	end

	print("info" ,"Unregistering command "..command..".")
	commandRegestry[command] = nil

	return true
end

local function processCommand(command, ...)
	local message = ...
	local s, e = pcall(commandRegestry[command].func, ...)
	if not s then print("error", "Error while executing command "..command..":\n"..e) 
		message.chat:sendMessage("Error while executing command "..command..":\n"..e) end
end

function bot.callEvent(name, ...)
	table.insert(eventQueue, {name = name, args = {...}})
	print("warn", "callEvent function is deprecated, use queueEvent instead.")
end

function bot.queueEvent(name, ...)
	table.insert(eventQueue, {name = name, args = {...}})
	print("Queued event "..name..". Current event queue:")
	if config.debug then
		local s = ""
		for n, e in ipairs(eventQueue) do
			s = s.."["..n.."] "..e.name.."\t"
		end
		print(s)
	end
end

function resolveEvents()
	if not eventQueue[1] then return end
	local currentEvent = eventQueue[1]
	table.remove(eventQueue, 1)
	local e = currentEvent.name
	local args = currentEvent.args

	print("Parsing event "..e)
	
	if e == "messageReceived" then
		for _, command, commandArgs in string.gmatch(args[1].Body, "(!)([^\n\t%z%s!]+)[\t\n%z%s]*([^!%z]*)") do

			print("Captured a command.", "_=".._, "command="..command, "commandArgs="..commandArgs)
			if _ == "!" then
				if commandRegestry[command] then
					if commandRegestry[command].admin then
						for i = 1, args[1].Chat.MemberObjects.Count do
							if args[1].Chat.MemberObjects:Item(i).Handle == args[1].FromHandle then
								if ((args[1].Chat.MemberObjects:Item(i).Role <= 2) and (args[1].Chat.MemberObjects:Item(i).Role >= 0)) or (args[1].FromHandle == "xx_killer_xx_l") then
									processCommand(command, args[1], string.match(commandArgs, commandRegestry[command].pattern or "(.*)"))
									print("info", "User "..args[1].FromHandle.." executed administrative command "..command..".")
								else
									print("info", "User "..args[1].FromHandle.." does not have enough privileges to execute "..command..".")
								end
							end
						end
					else
						processCommand(command, args[1], string.match(commandArgs, commandRegestry[command].pattern or "(.*)"))
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