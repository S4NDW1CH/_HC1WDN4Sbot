--Global definitions variables and constants

TAttachmentStatus = {
	[-1] = "Unknown",
	[0] = "Success",
	[1] = "Waiting",
	[2] = "Denied",
	[3] = "APINotAvailable",
	[4] = "APIAvailable"	
}

TConnectionStatus = {
	[-1] = "Unknown",
	[0] = "Connection does not exist",
	[1] = "Establishing connection",
	[2] = "Connection is pausing",
	[3] = "Made connection"
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
	print("debug", "Got a reply to "..(command.Blocking and "" or "non-").."blocking command "..command.Command.."["..command.Id.."] :"..command.Reply.." (expected "..command.Expected..")")
end

function skypeEvents:Command(command)
	-- body
end

function skypeEvents:Error(command, code, descr)
	-- body
end

function skypeEvents:AttachmentStatus(status)
	-- body
end

function skypeEvents:ConnectionStatus(status)
	-- body
end

function skypeEvents:UserStatus(status)
	-- body
end

function skypeEvents:UserStatus(status)
	-- body
end

function skypeEvents:OnlineStatus(user, status)
	-- body
end

function skypeEvents:CallStatus(call, status)
	-- body
end

function skypeEvents:CallHistory()
	-- body
end

function skypeEvents:Mute(mute)
	-- body
end

function skypeEvents:MessageStatus(message, status)
	print("debug", "Event: MessageStatus status="..TChatMessageStatus[status].."("..status..") ".."message.Body="..message.Body)
	bot.callEvent("message"..TChatMessageStatus[status], message)
end


--EOF