https = require "ssl.https"
json = require "json"

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

	local h, m, s = string.match(videoDetails.items[1].contentDetails.duration, "PT(%d*)H?(%d*)M?(%d*)S?")
	local time = (h..":" or "")..(h and (string.format("%.2d:", m) or "00:") or (m..":" or "0:"))..string.format("%.2d", s)

	return "["..time.."] "..videoDetails.items[1].snippet.localized.title.." by "..videoDetails.items[1].snippet.channelTitle
end