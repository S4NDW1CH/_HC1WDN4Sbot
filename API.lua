--Load modules
require "lfs"
json = require "json"


--Global definitions variables and constants

bot = {} --Namespace

bot.version = "0.9"

local modules = {}
local modNames = {}
local commandRegestry = {}

local eventQueue = {}

local chats = {}


-----------------------
--Functions and methods
-----------------------

--Non API functions

--This function is backbone of the whole program
--Be careful when editing this or else everything might break
local function loadModule(filename, message)
	print("info", "Loading "..filename)
	if message then message.Chat:SendMessage("Loading "..filename) end

	--Load module file and check if it was done successfully
	local mod, err = loadfile(filename)
	if not mod then
		if message then message.Chat:SendMessage("Error loading module "..filename..":\n"..err) end
		return print("error", "Error loading module "..filename..":\n"..err)
	end

	--Define module environment
	local env = {}

	env._G = env
	env._ENV = env 		--This allows writing in 5.2 and 5.3 style
	env._VERSION = _VERSION
	env.assert = assert
	env.dofile = dofile
	env.error = error
	env.getmetatable = getmetatable		--Is it really that dangerous?
	env.ipairs = ipairs
	env.next = next
	env.pairs = pairs
	env.pcall = pcall
	env.print = print
	env.select = select
	env.setmetatable = setmetatable		--^
	env.tonumber = tonumber
	env.tostring = tostring
	env.type = type
	env.xpcall = xpcall

	env.skype = skype 		--Not sure if this is safe

	--Sandbox compatible implementation of module()
	env.module = function (name, ...)
		--Closures won't work here and at the same time they might
		--actually take effect here so to be safe environment of
		--the module is fetched each time
		local env = getfenv(2)
		local module = {}		--New environment that will be applied later

		--Checking if there is a table defined for module()
		--If there is, then it is used as new environment to be
		if env[name] and type(env[name]) == "table" then
			module = env[name]
		end

		--Checking if there is a table defined by a library that can be used as new environment
		--Since this is checked after previous check, if this check succeeds then it overrides previous one
		if env.package.loaded[name] and type(env.package.loaded[name]) == "table" then
			module = env.package.loaded[name]
		end

		--Apply any specified option to the new environment
		for _, param in pairs({...}) do
			param(module)
		end

		--Add environment variables that are supposed to be added by 
		module._NAME = name
		module._M = module

		--Make sure require() will return environment table instead of "true"
		env.package.loaded[name] = module

		--Finally apply new environment to the thread
		setfenv(2, module)
	end

	--Sandbox compatible implementation of require()
	env.require = function (name)
		--Assert and type-check argument
		if type(name) ~= "string" then error("bad argument #1 to 'require' (string expected, got "..type(name)..")") end
		
		--Get environment in which library will be loaded
		local env = getfenv(2)

		print("Loading module "..name.." within "..tostring(env).." ("..(env.name or "global")..")")

		--Check if library was already loaded
		if not env.package.loaded[name] then
			--If library wasn't loaded
			
			local errorMessage = "" 	--Error message that will be displayed if loading fail
			local success = false 		--Loading success flag

			local loaders = package.loaders 	--Local version of loaders table because in module environment there isn't one
			local _G = _G

			--Set environment of main (current) thread to module's
			--It is required because loader function makes changes to the environment
			--of current thread and it is impossible to change environment of loader
			--function via setfenv()
			setfenv(0, env)

			--Iterate through loaders to see which one works
			for i = 1, 4 do
				--Attempt to load library via one of the loaders
				local moduleLoader = loaders[i](name)
				
				if type(moduleLoader) ~= "function" then
					errorMessage = errorMessage .. moduleLoader or ""
				else
					success = true
					local loaderReturn = moduleLoader()
					if not env.package.loaded[name] then
						env.package.loaded[name] = loaderReturn or true
					end
					break
				end
			end

			setfenv(0, _G)

			if not success then 
				error("module '"..name.."' not found:"..errorMessage)
			else
				print("Successfully loaded "..name.." to "..tostring(env).." ("..env.name..")")
			end
		end

		return env.package.loaded[name]
	end

	local function seeall(module)
		setmetatable(module, {__index = getfenv(2)})
	end

	env.package = {
		preload = {},
		path = package.path,
		cpath = package.cpath,

		seeall = seeall,

		loaded = {}
	}

	for name, lib in pairs(package.loaded) do
		if (not (name == "_G" or name == "debug" or name == "package")) then
			print("Adding "..name.." to loaded modules")
			env.package.loaded[name] = lib
			if type(lib) ~= "boolean" then env[name] = lib end
		end
	end

	env.bot = bot
	env.timer = timer

	env.filename = string.match(filename, ".\\([%w%s_%.#]*%.lua)")
	env.name = string.match(filename, ".\\([%w%s_%.#]*)%.lua")
	env._M = env.filename		--These two allow writing program modules like Lua modules
	env._NAME = env.name

	setfenv(mod, env)
	local traceback
	local success, msg = xpcall(mod, function (obj) traceback = debug.traceback(obj, "", 1) end)

	if not success then
		if message then message.Chat:SendMessage("Error on initializing "..filename..":\n"..(msg or "")..traceback) end
		return print("error", "Error on initializing "..filename..":\n"..(msg or "")..traceback)
	end

	success, msg = pcall(env.onLoad)

	if not success and env.onLoad then print("error", "Error handling onLoad event in module "..env.name..":\n"..(msg or "no error message available")) end

	env.enabled = true

	table.insert(modules, env)
	modNames[env.name] = #modules
end

function loadModules(message)
	print("info", "Loading modules...")

	--First, clear array of modules
	modules = {len = 0}

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
	if message then message.Chat:SendMessage("All modules were loaded.") end
end

function toggleModule(module)
	modules[modNames[module]].enabled = not modules[modNames[module]].enabled
	return modules[modNames[module]].enabled
end

---------------
--API functions
---------------

function bot.isLoaded(module)
	return modNames[module] and true or false
end

function bot.loadedModules()
	local moduleList = {len = 0}
	for _, mod in ipairs(modules) do
		moduleList[mod.name] = mod.enabled
		moduleList.len = moduleList.len + 1
	end
	return moduleList
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
	return commandRegestry[command] ~= nil
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

-----------------
--Event processor
-----------------

local function processCommand(command, ...)
	print(...)
	local message = ...
	local s, e = pcall(commandRegestry[command].func, ...)
	if not s then
		print("error", "Error while executing command "..command..":\n"..e) 
		message.chat:sendMessage("Error while executing command "..command..":\n"..e)
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

			print("Captured a command.", "command="..command, "commandArgs="..commandArgs)
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

	for _, mod in ipairs(modules) do
		if mod[e] then print("Module "..mod.name.." has event handler for "..e..".") end
		if mod.enabled then
			local succes, msg = pcall(mod[e], table.unpack(args))
			if not succes and mod[e] then print("error", "Error while calling event handler "..e.." in module "..mod.name..": "..msg) end
		end
	end
end

--EOF