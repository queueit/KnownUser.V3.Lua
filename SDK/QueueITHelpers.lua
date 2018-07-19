local utils = require("Utils")
local iHelpers = require("KnownUserImplementationHelpers")

local qitHelpers = {
	QueueUrlParams = {
		extractQueueParams = function(queueitToken)
			local TimeStampKey = "ts"
			local ExtendableCookieKey = "ce"
			local CookieValidityMinutesKey = "cv"
			local HashCodeKey = "h"
			local EventIdKey = "e"
			local QueueIdKey = "q"
			local RedirectTypeKey = "rt"
			local KeyValueSeparatorChar = "_"
			local KeyValueSeparatorGroupChar = "~"
						
			-- Private functions
			local function updateResult(paramNameValueArr, result)
				if(paramNameValueArr[1] == TimeStampKey) then
					local tsn = tonumber(paramNameValueArr[2])
					if(tsn ~= nil) then 
						result.timeStamp = tsn 
					end
					return
				end
				if(paramNameValueArr[1] == CookieValidityMinutesKey) then
					local cvn = tonumber(paramNameValueArr[2])
					if(cvn ~= nil) then 
						result.cookieValidityMinutes = cvn 
					end
					return
				end
				if(paramNameValueArr[1] == EventIdKey) then
					result.eventId = paramNameValueArr[2]
					return
				end
				if(paramNameValueArr[1] == ExtendableCookieKey) then
					if(paramNameValueArr[2] ~= nil) then
						result.extendableCookie = string.lower(paramNameValueArr[2]) == "true"	
					else
						result.extendableCookie = false
					end
					return
				end
				if(paramNameValueArr[1] == HashCodeKey) then
					result.hashCode = paramNameValueArr[2]
					return
				end
				if(paramNameValueArr[1] == QueueIdKey) then
					result.queueId = paramNameValueArr[2]
					return
				end
				if(paramNameValueArr[1] == RedirectTypeKey) then
					result.redirectType = paramNameValueArr[2]
					return
				end
			end
			-- END Private functions
	
			local result = {
				timeStamp = 0,
				eventId = "",
				hashCode = "",
				extendableCookie = false,
				cookieValidityMinutes = nil,
				queueITToken = queueitToken,
				queueITTokenWithoutHash = "",
				queueId = "",
				redirectType = ""
			}

			local paramsNameValueList = utils.explode(KeyValueSeparatorGroupChar, result.queueITToken)

			for i,pNameValue in pairs(paramsNameValueList) do
				local paramNameValueArr = utils.explode(KeyValueSeparatorChar, pNameValue)
				updateResult(paramNameValueArr, result)
			end

			result.queueITTokenWithoutHash = 
				result.queueITToken:gsub(KeyValueSeparatorGroupChar .. HashCodeKey .. KeyValueSeparatorChar .. result.hashCode, "")
	
			return result	
		end
	}
}

return qitHelpers