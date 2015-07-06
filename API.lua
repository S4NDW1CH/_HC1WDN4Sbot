--Load modules
require "lfs"


--Global definitions variables and constants

bot = {} --Namespace

local modules = {}


--Functions and methods
function bot.loadModule(filename, message)
	local module = loadfile(filename)
	local env = getfenv(module)

	env.bot = bot
	setfenv(module, env)

	local succes, msg = pcall(module)

	if not succes then
		if message then message.Chat:SendMessage("Error on initializing "..filename..":\n"..(msg or "")) end
		return print("error", "Error on initializing "..filename..":\n"..(msg or ""))
	end

	table.insert(modules, env)
end

function bot.loadModules(message)
	print("info", "Loading modules...")

	--First, clear array of modules
	modules = nil
	modules = {}

	--Next, iterate through all .lua files in \modules directory and load each file
	lfs.mkdir("modules")
	for filename in lfs.dir(".\\modules\\") do
		if string.find(filename, "[%w%s]%.lua") then
			print("info", "Loading "..filename)
			bot.loadModule(".\\modules\\"..filename, message)
		end
	end

	--And now we are ready to go!
	print("info", "All modules were loaded.")
end

function bot.callEvent(e, ...)
	local args = {...}
	print("Parsing event "..e)
	print("Modules to go through: "..#modules)
	
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
								   ]]"  Current version: 0.0.2b hotfix 1")
		end
	end

	for _, mod in ipairs(modules) do
		if mod[e] then print("Current module has event handler for current event.") end
		local succes, msg = pcall(mod[e], table.unpack(args))
		if not succes then print("Error while calling event handler "..e..": "..msg) end
	end
end

--EOF