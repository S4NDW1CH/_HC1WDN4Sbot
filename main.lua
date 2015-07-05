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

rawPrint = print

logConsole = logging.console("%date\t[%level] %message\n")
logFile = logging.file("%s.log", "%Y-%m-%d-%H%M%S", "%date [%level] %message\n")
logConsole:setLevel("INFO")
logFile:setLevel("INFO")


--Functions and methods

function sleep(time)
	local t = os.clock()
	while os.clock()-t < time do end 
end

function print(level, ...)
	if level == "debug" or level == "info" or level == "warn" or level == "error" or level == "fatal" then
		logConsole:log(string.upper(level), table.concat({...}, "\t"))
		logFile:log(string.upper(level), table.concat({...}, "\t"))
	else
		logConsole:debug(tostring(level, table.unpack({...})))
	end
end


--Main chunk
function main()
	bot.loadModules()

	local skype = luacom.CreateObject("Skype4COM.Skype", "Skype_")
	luacom.Connect(skype, skypeEvents)
	skype:Attach(nil, false)

	--TODO: here goes stuff that does things
	
	luacom.StartMessageLoop(function() end)
end

main()

--EOF