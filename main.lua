--GLOBALS: skype, print, string, table, os, luacom, loadModules
--GLOBALS: tostring, ipairs, config, setShutdown, math, debug, skypeEvents
--GLOBALS: resolveTimers, resolveEvents

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
require "API_extender"
require "system"
require "timer"


--Global definitions variables and constants
local rawPrint = print

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

#Skype username to which send crash reports if main thread crashes.
admin = 
]]

	file:write(content)
	file:close()

	config = bot.parseConfig("config.cfg")
end

local logConsole = logging.console("%date\t[%level] %message\n")
local logFile
if config.use_logs then logFile = logging.file("bot.log", "%Y-%m-%d-%H%M%S", "%date [%level] %message\n") end

local shutdown = false


--Functions and methods

function setShutdown()
	shutdown = true
end

function print(level, ...)
	if level == "info" or level == "warn" or level == "error" or level == "fatal" then
		logConsole:log(string.upper(level), tostring(table.unpack({...}))--[[..((level == "error") and "\n"..debug.traceback() or "")]])
		if config.use_logs then logFile:log(string.upper(level), table.unpack({...})) end
	else
		local str = ""
		for _, v in ipairs({...}) do
			str = str.."\t"..tostring(v)
		end
		logConsole:debug(tostring(level)..str)
		if config.use_logs then logFile:debug(tostring(level)..str) end
	end

	if config.debug and config.debug_trace then logConsole:debug(debug.traceback() or "") end
end

local function sleep(t)
	local t0 = os.clock()
	while os.clock() < t0+t do
	end
end


--Main chunk
local function main()
	math.randomseed(os.clock())
	math.random();math.random()
	
	logConsole:setLevel(config.debug and "DEBUG" or "INFO")
	if config.use_logs then logFile:setLevel(config.debug and "DEBUG" or "INFO") end

	print("info", "Connecting to Skype...")
	skype = luacom.CreateObject("Skype4COM.Skype", "Skype_")
	print("info", "Got Skype object.")
	luacom.Connect(skype, skypeEvents)
	skype:Attach(nil, false)
	print("info", "Attached to Skype.")
	print("info", "Current user: "..skype.CurrentUser.FullName.." ("..skype.CurrentUser.Handle..").")

	--loadTimers()

	loadModules()

	print("info", "Main loop is running.")
	--luacom.StartMessageLoop(function() end)
	local resolveTimers = resolveTimers
	local resolveEvents = resolveEvents

	--StartMessageLoop() is not used because it does not work as I
	--need. Instead to receive COM events Attach() method is used.
	while true do
		resolveTimers()
		skype:Attach(nil, false)
		resolveEvents()
		if shutdown then break end
		sleep(1/(config.tickrate or 10))
	end
	print("info", "Shutting down...")
end

local errcount = 0
repeat
	local traceback
	local success, msg = xpcall(main, function (obj) traceback = debug.traceback(obj, "", 2) end)

	if not success then
		print("error", "Error in main thread:\n"..(msg or "???")..":\n"..traceback)
		if config.admin then skype.sendMessage(config.admin, "Error in main thread:\n"..msg..":\n"..traceback) end
	end
until success
--EOF