--Where to look up modules
package.cpath = ".\\?.dll;.\\lib\\?.dll"
package.path = ".\\?.lua;.\\lua\\?.lua"

--Load modules
require "compat53.init"

require "luacom"
require "logging"
require "logging.console"
require "logging.file"

require "COMevents"
require "API"
require "system"
require "timer"


--Global definitions variables and constants
rawPrint = print

config = bot.parseConfig("config.cfg")
if not config then
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

#If true, then debug output will be logged. (default: false)
debug = false

#If true, when log message is printed, print stack traceback along with it. Effective only when debug = true. (default: false)
debug_trace = false

#If false, stops creating logs each session. (default: true)
use_logs = true

#Rate at which program updates (event and timer processing). Measured in ticks per second. (default: 10)
tickrate = 10
]]

	file:write(content)
	file:close()

	config = bot.parseConfig("config.cfg")
end

logConsole = logging.console("%date\t[%level] %message\n")
if config.use_logs then logFile = logging.file("bot.log", "%Y-%m-%d-%H%M%S", "%date [%level] %message\n") end


--Functions and methods

function print(level, ...)
	if level == "info" or level == "warn" or level == "error" or level == "fatal" then
		logConsole:log(string.upper(level), table.unpack({...}))
		if config.use_logs then logFile:log(string.upper(level), table.unpack({...})) end
	else
		local res = ""
		for _, v in ipairs({...}) do
			res = res.."\t"..tostring(v)
		end
		logConsole:debug(tostring(level)..res)
		if config.use_logs then logFile:debug(tostring(level)..res) end
	end

	if config.debug and config.debug_trace then logConsole:debug(debug.traceback() or "") end
end

local function sleep(t)
	local t0 = os.clock()
	while os.clock() < t0+t do
	end
end


--Main chunk
function main()
	logConsole:setLevel(config.debug and "DEBUG" or "INFO")
	if config.use_logs then logFile:setLevel(config.debug and "DEBUG" or "INFO") end

	bot.loadModules()

	print("info", "Connecting to Skype...")
	local skype = luacom.CreateObject("Skype4COM.Skype", "Skype_")
	print("info", "Got Skype object.")
	luacom.Connect(skype, skypeEvents)
	skype:Attach(nil, false)
	print("info", "Attached to Skype.")
	print("info", "Current user: "..skype.CurrentUser.FullName.." ("..skype.CurrentUser.Handle..").")
	
	print("info", "Main loop is running.")
	--luacom.StartMessageLoop(function() end)
	while true do
		resolveTimers()
		skype:Attach(nil, false)
		resolveEvents()
		sleep(1/(config.tickrate or 10))
	end
end
main()


--EOF