https = require "ssl.https"
require "json"

function messageReceived(message)
	for video in message.Body:gmatch(".*%.youtube%.com/watch.*v=([_%-%w]+)[^\t\n%s%z]*") do
		message.Chat:SendMessage(processVideo(video))
	end
	for video in message.Body:gmatch(".*/youtu%.be/([_%-%w]+)[^\t\n%s%z]*") do
		message.Chat:SendMessage(processVideo(video))
	end
end

function processVideo(id)
	print("info", "Processing data for video "..id)
	local result, err = https.request("https://www.googleapis.com/youtube/v3/videos?id="..id.."&part=snippet,contentDetails&key=AIzaSyAXfR2XY4s0W713HfXjTD3VDB-JejKsT3o")
	if not result then print("error", "Error while handling https request:\n"..err) end

	local videoDetails = json.decode(result)

	local time = formatISO(videoDetails.items[1].contentDetails.duration)
	
	return "["..time.."] "..videoDetails.items[1].snippet.localized.title.." by "..videoDetails.items[1].snippet.channelTitle
end

function formatISO(time)
	local seconds = 0
	seconds = string.match(time, "(%d*)S") or 0
	seconds = seconds + (string.match(time, "(%d*)M") or 0)*60
	seconds = seconds + (string.match(time, "(%d*)H") or 0)*3600

	if not string.match(time, "(%d*)H") then
		return string.format("%.1d:%.2d", seconds/60, seconds%60)
	else
		return string.format("%.1d:%.2d:%.2d", seconds/3600, (seconds/60)%60, seconds%60)
	end
end