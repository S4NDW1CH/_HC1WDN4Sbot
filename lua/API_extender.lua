--[[
	_HC1WDN4Sbot API extension mechanism.

	API extension mechanism designed to allow each modules to add API functions that will be accessible in other modules.
	This mechanism allows every module to add its own methods (functions) to globally accessible bot API.
	Only addition and modifications of own method is available; modification of native methods or methods added
	by other modules is unavailable.
]]

function bot.registerExtention(method_set)
	local env = getfenv(2)
	bot[env.name] = {}
	setmetatable(bot[env.name], {__index = method_set})
end

--TODO: more stuff???