local json = require("cjson")
module("json")
_M.decode = json.decode
_M.encode = json.encode

return _M