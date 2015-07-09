--Load modules
require "lfs"


--Global definitions variables and constants

bot = {} --Namespace

bot.version = "0.0.3a"

local modules = {}
local commandRegestry = {}


--Functions and methods
function bot.loadModule(filename, message)
	print("info", "Loading "..filename)
	if message then message.Chat:SendMessage("Loading "..filename) end

	local module = loadfile(filename)
	local env = getfenv(module)

	env.bot = bot
	env.name = string.match(filename, ".\\([%w%s_%.#]*)%.lua")
	setfenv(module, env)

	local succes, msg = pcall(module)

	if not succes then
		if message then message.Chat:SendMessage("Error on initializing "..filename..":\n"..(msg or "")) end
		return print("error", "Error on initializing "..filename..":\n"..(msg or ""))
	end

	succes, msg = pcall(env.onLoad)

	if not succes then print("Error handling OnLoad event in module "..env.name..":\n"..(msg or "")) end

	table.insert(modules, env)
end

function bot.loadModules(message)
	print("info", "Loading modules...")

	--First, clear array of modules
	modules = nil
	modules = {}

	--Also, clear command registry
	commandRegestry = nil
	commandRegestry = {}

	--Next, iterate through all .lua files in \modules directory and load each file
	lfs.mkdir("modules")
	for filename in lfs.dir(".\\modules\\") do
		if string.find(filename, "[%w%s]%.lua") then
			bot.loadModule(".\\modules\\"..filename, message)
		end
	end

	--And now we are ready to go!
	print("info", "All modules were loaded.")
	if message then message.Chat:SendMessage("All modules were successfully loaded.") end
end

function bot.parseConfig(filename)
	print("info", "Parsing "..filename.."...")

	local tConfig = {}
	local file = io.open("config.cfg", "r")
	if not file then print("warn", filename.." not found") return nil end

	for line in file:lines() do
		if (not string.match(line, "#.")) and #line > 0 then
			local var, val = string.match(line, "[%s\t]*(%w+)[%s\t]*=[%s\t]*([^\n]+)")

			if not ((not var) or (not val) or (#var < 1) or (#val < 1)) then
				val = (tonumber(val) and tonumber(val) or val)
				val = (val == "true" or val)
				if val == "false" then val = false end 
				tConfig[var] = val
			end
		end
	end
	file:close()

	return tConfig
end

function bot.registerCommand(...)
	local args = {...}
	if not args[1].name then error("Name must be specified") end

	print("info", "Registering command "..args[1].name..(args[1].force and " " or " non-").."forcibly.")
	if commandRegestry[args[1].name] and not args[1].force then return false end

	commandRegestry[args[1].name] = {pattern = args[1].pattern, func = args[1].func, admin = args[1].admin, description = args.description}

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

function bot.callEvent(e, ...)
	local args = {...}
	print("Parsing event "..e)
	print("Modules to go through: "..#modules)
	
	--TODO: figure out where to move this mess.
	if e == "messageReceived" then
		if string.find(args[1].Body, "!reload") then
			print("info", "Received command to reload modules. Reloading...")
			args[1].Chat:SendMessage("Reloading modules, please wait...")

			bot.loadModules(args[1])
		end

		if string.find(args[1].Body, "!status") then
			print("info", "Received status command.")

			args[1].Chat:SendMessage("Current statistics:\n".."Number of modules loaded: "..#modules)
		end

		if string.find(args[1].Body, "!about") then
			print("info", "Received about command.")

			args[1].Chat:SendMessage("Hey! My name is _HC1WDN4Sbot! I'm a Skype bot that does some useful and/or fun things.\n"..--[[
								   ]]"  My creator: xx_killer_xx_l (he hates his Skype login)\n"..--[[
								   ]]"  I'm on GitHub: https://github.com/S4NDW1CH/_HC1WDN4Sbot\n"..--[[
								   ]]"  Current version: "..bot.version)
		end
	end

	--I'M SO SORRY FOR THIS PLEASE DON'T KILL ME PLEASE I'LL REMOVE IT ASAP PLEASE NO DON'T KILL ME PLEASE ;_;
	if e == "messageReceived" then
		for command, properties in pairs(commandRegestry) do
			for cap, commandArgs in string.gmatch(args[1].Body, "(!"..command.."[\n%z%s]*"..")".."([^%.]*)") do

				print("info", "Received command "..command..".")
				commandRegestry[command].func(args[1], string.match(commandArgs, commandRegestry[command].pattern or "(.*)"))
			end
		end
	end

	for _, mod in ipairs(modules) do
		if mod[e] then print("Current module has event handler for current event.") end
		local succes, msg = pcall(mod[e], table.unpack(args))
		if not succes then print("warn", "Error while calling event handler "..e..": "..msg) end
	end
end

--EOF