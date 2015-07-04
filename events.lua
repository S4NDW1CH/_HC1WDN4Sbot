--Global definitions variables and constants

TAttachmentStatus = {
	[-1] = "AttachUnknown",
	[0] = "Client is successfully attached",
	[1] = "Waiting for user authorization",
	[2] = "User has explicitly denied access to the client",
	[3] = "Skype API is not available",
	[4] = "Skype API is available"	
}

TConnectionStatus = {
	[-1] = "conUnknown",
	[0] = "Connection does not exist",
	[1] = "Establishing connection",
	[2] = "Connection is pausing",
	[3] = "Made connection"
}

TChatMessageStatus = {
	[-1] = "Err",
	[0] = "Sending",
	[1] = "Sent",
	[2] = "Received",
	[3] = "Read"
}

events = {}


--Functions and methods

function events:MessageStatus(msg, status)
	print(msg.FromHandle, msg.Body, status, TChatMessageStatus[status])

	if (status == 2) or (status == 1) then
		for amount, sides in msg.Body:gmatch(".*!(%d+)d(%d+).*") do
			print("Rolling "..amount.." dice with "..sides.." sides")
			local message = {}
			math.randomseed(os.time()%math.random(os.time()))
			for i = 1, amount do
				math.random()
				for j = 1, math.random(10) do
					math.random()
				end
				table.insert(message, math.random(sides))
			end

			if #message > 0 then msg.Chat:SendMessage(msg.Sender.FullName.." rolled "..table.concat(message, " + ")) end
		end

		for _ in msg.Body:gmatch(".*!about.*") do
			msg.Chat:SendMessage("Hi! I'm _HC1WDN4Sbot.\n//TODO: put some links here\n//TODO: and here")
		end

		for _ in msg.Body:gmatch(".*!help.*") do
			msg.Chat:SendMessage("//TODO:here be dragons!")
		end

	end
end

function events:AttachmentStatus(status)
	print("Status: "..TAttachmentStatus[status])
end

function events:Command(command)
	print("Send"..(command.Blocking and "" or "non-").."blocking command: ["..comand.Id.."]"..command.Command.." (Expect:"..command.Expected)
end

function events:Reply(reply)
	print("Got reply: ["..reply.Id.."]"..reply.Reply)
end


--EOF