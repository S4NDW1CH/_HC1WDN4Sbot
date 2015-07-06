--Where to look up modules
package.cpath = ".\\?.dll;.\\?51.dll;.\\lib\\?.dll;.\\lib\\?51.dll;"
package.path = ".\\?.lua;.\\lua\\?.lua"

--Load modules
require "compat53.init"

require "luacom"
require "logging"
require "logging.console"
require "logging.file"

require "COMevents"
require "API"


--Global definitions variables and constants
config = {}

rawPrint = print

logConsole = logging.console("%date\t[%level] %message\n")
logFile = logging.file("%s.log", "%Y-%m-%d-%H%M%S", "%date [%level] %message\n")


--Functions and methods

function sleep(time)
	local t = os.clock()
	while os.clock()-t < time do end 
end

function print(level, ...)
	if level == "info" or level == "warn" or level == "error" or level == "fatal" then
		logConsole:log(string.upper(level), table.unpack({...}))
		logFile:log(string.upper(level), table.unpack({...}))
	else
		logConsole:debug(tostring(level)..table.concat({...}, "\t")..(config.debug_trace and "\n"..debug.traceback() or ""))
		logFile:debug(tostring(level)..table.concat({...}, "\t")..(config.debug_trace and "\n"..debug.traceback() or ""))
	end
end

function createConfig()
	local file = io.open("config.cfg", "w")

	local content = 
[[#This is configuration file for _HC1WDN4Sbot.
#In this file are definitions of some variables used internally.
#The format of this file is simple:
#	if line starts with "#" then it's ignored
#	each variable is defined globally
#	to define a variable, put its name first, then put "=" and then value of the variable
#	name must contain only alphanumeric characters and underscores
#	values can contain anything
#	spaces and tabs in the beginning of the line, before and after "=" are ignored.

#If true, then debug output will be logged (default: false)
debug = false

#If true, when debug level message is printed, print stack traceback along with it. Effective only when debug = true. (default: false)
debug_trace = false
]]

	file:write(content)
	file:close()
end

function loadConfig()
	print("info", "Loading config...")
	local file = io.open("config.cfg", "r")
	if not file then
		print("info", "No config detected. Creating new config...")
		createConfig()
		return loadConfig()
	end

	for line in file:lines() do
		if (not string.match(line, "#.")) and #line > 0 then
			local var, val = string.match(line, "[%s\t]*(%w+)[%s\t]*=[%s\t]*([^\n]+)")

			if not (not var) or (not val) or (#var < 1) or (#val < 1) then
				val = (tonumber(val) and tonumber(val) or val)
				val = (val == "true" or val)
				if val == "false" then val = false end 
				config[var] = val
			end
		end
	end
	file:close()

	print("info", "Config has been loaded.")
end


--Main chunk
function main()
	logConsole:setLevel("DEBUG")
	logFile:setLevel("DEBUG")

	loadConfig()

	logConsole:setLevel(config.debug and "DEBUG" or "INFO")
	logFile:setLevel(config.debug and "DEBUG" or "INFO")

	bot.loadModules()

	print("info", "Connecting to Skype...")
	local skype = luacom.CreateObject("Skype4COM.Skype", "Skype_")
	print("info", "Got Skype object.")
	luacom.Connect(skype, skypeEvents)
	skype:Attach(nil, false)
	print("info", "Attached to Skype.")
	print("info", "Current user: "..skype.CurrentUser.FullName.." ("..skype.CurrentUser.Handle..").")
	
	print("info", "Event loop is running.")
	luacom.StartMessageLoop(function() end)
end

main()

--EOF