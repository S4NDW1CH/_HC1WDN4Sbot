timer = {}
local activeTimers = {}
local inactiveTimers = {}

function resolveTimers()
	for id, t in ipairs(activeTimers) do
		if t.id ~= id then t.id = id end --why would you even want to change the id?

		if t.type == "set" then
			if t.time >= os.time() then
				fireTimer(t)
			end
		elseif t.type == "delay" then
			if os.clock() >= t.time+t.startTime then
				fireTimer(t)
			end
		end
	end
end

function timer.newTimer(properties)
	assert(properties.type, "Timer must have type.")
	assert(properties.time, "Timer must have time.")

	local t = {type = properties.type, time = properties.time}

	if properties.type == "delay" then t.startTime = os.clock() end

	t.start = start
	t.stop = stop
	t.delete = delete
	t.isActive = isActive

	t:start()

	return t
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

local function fireTimer(t)
	table.remove(activeTimers, t.id)
	bot.queueEvent("timerTriggered", t)
end

function start(self)
	table.remove(inactiveTimers, self.id)
	insert(self, activeTimers)
	self.status = "active"
end

function stop(self)
	table.remove(activeTimers, self.id)
	insert(self, inactiveTimers)
	self.status = "inactive"
end

function delete(self)
	if self:isActive() then
		table.remove(activeTimers, self.id)
	elseif self.status ~= "fired" then
		table.remove(inactiveTimers, self.id)
	end
	self = nil
end

function isActive(self)
	return self.status == "active"
end