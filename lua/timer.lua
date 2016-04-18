require "json"

timer = {}
local activeTimers = {}
local inactiveTimers = {}

function resolveTimers()
	for id, t in ipairs(activeTimers) do
		if t.id ~= id then t.id = id end --why would you even want to change the id?

		if t.type == "set" then
			if t.time >= os.time() then
				fireTimer(t)
				saveTimers()
			end
		elseif t.type == "delay" then
			if os.clock() >= t.time+t.startTime then
				fireTimer(t)
				saveTimers()
			end
		end
	end
end

local function insert(ti, ta)
	local i = 1
	while true do
		if ta[i] == nil then
			ti.id = i
			ta[i] = ti
			break
		end
		i = i + 1
	end
end

function timer.newTimer(property)
	assert(property.type, "Timer must have type.")
	assert(property.time, "Timer must have time.")

	local t = {type = property.type, time = property.time}

	if property.type == "delay" then t.startTime = os.clock() end

	function t:start()
		table.remove(inactiveTimers, self.id)
		insert(self, activeTimers)
		self.status = "active"
	end

	function t:stop()
		table.remove(activeTimers, self.id)
		insert(self, inactiveTimers)
		self.status = "inactive"
	end

	function t:delete()
		if self:isActive() then
			table.remove(activeTimers, self.id)
		elseif self.status ~= "fired" then
			table.remove(inactiveTimers, self.id)
		end
		self = nil
	end
	

	function t:isActive()
		return self.status == "active"
	end

	t:start()

	saveTimers()

	return t
end

function fireTimer(t)
	table.remove(activeTimers, t.id)
	print("Firing timer "..t.id)
	if t.type == "set" then t.func() else bot.queueEvent("timerTriggered", t) end
end

function loadTimers()
	local file = io.open("./data/active_timers.json", "r")
	if file then activeTimers = json.decode(file:read("*a")) end

	file = io.open("./data/inactive_timers.json", "r")
	if file then inactiveTimers = json.decode(file:read("*a")) end
end

function saveTimers()
	local file = io.open("./data/active_timers.json", "w")
	local set_timers = {}

	for _, timer in pairs(activeTimers) do
		if timer.type == "set" then
			table.insert(set_timers, timer)
		end
	end
	file:write(json.encode(set_timers))
	file:close()

	file = io.open("./data/inactive_timers.json", "w")
	set_timers = {}

	for _, timer in pairs(inactiveTimers) do
		if timer.type == "set" then
			table.insert(set_timers, timer)
		end
	end
	file:write(json.encode(set_timers))
	file:close()
end