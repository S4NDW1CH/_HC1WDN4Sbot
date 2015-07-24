--Global definitions variables and constants

TAttachmentStatus = {
	[-1] = "Unknown",
	[0] = "Success",
	[1] = "Waiting",
	[2] = "Denied",
	[3] = "APINotAvailable",
	[4] = "APIAvailable"	
}

TChatMessageStatus = {
	[-1] = "Unknown",
	[0] = "Sending",
	[1] = "Sent",
	[2] = "Received",
	[3] = "Read"
}

TUserStatus = {
	[-1] = "Unknown",
	[0] = "Offline",
	[1] = "Online",
	[2] = "Away",
	[3] = "NotAvailable",
	[4] = "DoNotDisturb",
	[5] = "Invisible",
	[6] = "Logged out",
	[7] = "SkypeMe"
}

TOnlineStatus = {
	[-1] = "Unknown",
	[0] = "Offline",
	[1] = "Online",
	[2] = "Away",
	[3] = "NotAvailable",
	[4] = "DoNotDisturb",
	[5] = "SkypeOut",
	[6] = "SkypeMe"
}

skypeEvents = {}


--Functions and methods
setmetatable(skypeEvents, {__index = function(_, key) print("Unhandled event: "..key) end})

function skypeEvents:Reply(command)
	--print("Got a reply to "..(command.Blocking and "" or "non-").."blocking command "..command.Command.."["..command.Id.."] :"..command.Reply.." (expected "..command.Expected..")")
	--bot.callEvent("commandReply", command)
end

function skypeEvents:Command(command)
	--bot.callEvent("command", command)
end

function skypeEvents:Error(command, code, descr)
	--bot.callEvent("commandError", command, code, descr)
end

function skypeEvents:AttachmentStatus(status)
	bot.callEvent("attachment"..TAttachmentStatus[status])
end

function skypeEvents:UserStatus(status)
	bot.callEvent("client"..TUserStatus[status])
end

function skypeEvents:OnlineStatus(user, status)
	bot.callEvent("userStatus", user, status)
end

function skypeEvents:CallStatus(call, status)
	call:Finish()
end

function skypeEvents:MessageStatus(message, status)
	--[[if not bot.getChatEnvironment(message.Chat.Blob) then
		print(pcall(bot.createChatEnvironment, message.Chat.Blob))
		local chat = bot.getChatEnvironment(message.Chat.Blob)
		chat.chat = message.Chat
	end]]
	print("Event: MessageStatus status="..TChatMessageStatus[status].."("..status..") message.Body="..message.Body)
	bot.callEvent("message"..TChatMessageStatus[status], message)
end

function skypeEvents:UserMood(user, moodText)
	bot.callEvent("moodChanged", user, moodText)
end


--EOF