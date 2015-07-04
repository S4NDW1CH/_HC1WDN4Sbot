--Load modules
require "lfs"


--Global definitions variables and constants

bot = {} --Namespace

local eventQueue = {}

local event = {
	sampleEvent = {
		collection = {}},

	messageReceived = {
		collection = {}},

	messageSent = {
		collection = {}}
}
local events = event --Syntactic sugar, dammit!


--Functions and methods
function bot.loadModule(filename)
	local m = loadfile(filename)
	local env = getfenv(m)
	env.bot = bot

	m() --Gotta trust the module for now. Have to figure out a way to get environment of a chunk without execution. :( 

	for e, _ in pairs(events) do
		if env[e] and (type(env[e]) == "function") then
			table.insert(events[e].collection, env[e])
			setfenv(events[e].collection[#events[e].collection], env)
		end
	end
end

function bot.loadModules()
	print("info", "Loading modules...")

	--First, clear all collections
	for e in ipairs(events) do
		e.collection = nil
		e.collection = {}
	end

	--Next, iterate through all .lua files in \modules directory and load each file
	lfs.mkdir("modules")
	for filename in lfs.dir(".\\modules\\") do
		if string.find(filename, "[%w%s]%.lua") then
			print("info", "Loading "..filename)
			bot.loadModule(".\\modules\\"..filename)
		end
	end

	--And now we are ready to go!
	print("info", "All modules are loaded.")
end

function bot.callEvent(e, ...)
	local args = {...}
	print("Parsing event "..e.." with "..#args.." arguments")
	for k, f in pairs(events[e].collection) do
		local ret, err = pcall(f, table.unpack({...}))

		if not ret then print("error", err) end
	end
end

--EOF