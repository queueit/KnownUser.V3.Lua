local utils = require("Utils")
local comparisonOperatorHelper = require("ComparisonOperatorHelper")

local model = {
	UrlValidatorHelper = {
		evaluate = function(triggerPart, url)
			-- Private functions
			local function getUrlPart(_urlPart, _url)
				-- Private functions
				local function getHostNameFromUrl(__url)
					return utils.toString(__url:match('^%w+://([^/]+)'))
				end

				local function getPathFromUrl(__url)
					local pathAndQuery = utils.toString(__url:match('^%w+://[^/]+(.*)'))
					local query = utils.toString(__url:match('%?+.*'))
					local path = pathAndQuery:gsub(utils.escapeMagicChars(query), "")

					return path
				end
				-- END Private functions

				if (_urlPart == "PagePath") then
					return getPathFromUrl(_url)
				end
				if (_urlPart == "PageUrl") then
					return _url
				end
				if (_urlPart == "HostName") then
					return getHostNameFromUrl(_url)
				end

				return ""
			end
			-- END Private functions

			if (triggerPart == nil or
				triggerPart["Operator"] == nil or
				triggerPart["IsNegative"] == nil or
				triggerPart["IsIgnoreCase"] == nil or
				triggerPart["UrlPart"] == nil) then
				return false
			end

			return comparisonOperatorHelper.evaluate(
				triggerPart["Operator"],
				triggerPart["IsNegative"],
				triggerPart["IsIgnoreCase"],
				getUrlPart(triggerPart["UrlPart"], url),
				triggerPart["ValueToCompare"],
				triggerPart["ValuesToCompare"])
		end
	},
	CookieValidatorHelper = {
		evaluate = function(triggerPart, request)
			if (triggerPart == nil or
				triggerPart["Operator"] == nil or
				triggerPart["IsNegative"] == nil or
				triggerPart["IsIgnoreCase"] == nil or
				triggerPart["CookieName"] == nil) then
				return false
			end

			local cookieValue = ""
			local cookieName = triggerPart["CookieName"]
			if (cookieName ~= nil and request.getUnescapedCookieValue(cookieName) ~= nil) then
				cookieValue = request.getUnescapedCookieValue(cookieName)
			end

			return comparisonOperatorHelper.evaluate(
				triggerPart["Operator"],
				triggerPart["IsNegative"],
				triggerPart["IsIgnoreCase"],
				cookieValue,
				triggerPart["ValueToCompare"],
				triggerPart["ValuesToCompare"])
		end
	},
	UserAgentValidatorHelper  = {
		evaluate = function(triggerPart, request)
			if (triggerPart == nil or
				triggerPart["Operator"] == nil or
				triggerPart["IsNegative"] == nil or
				triggerPart["IsIgnoreCase"] == nil) then
				return false
			end

			local headerValue = request.getHeader("user-agent")
			if (headerValue == nil) then
				headerValue = ""
			end

			return comparisonOperatorHelper.evaluate(
				triggerPart["Operator"],
				triggerPart["IsNegative"],
				triggerPart["IsIgnoreCase"],
				headerValue,
				triggerPart["ValueToCompare"],
				triggerPart["ValuesToCompare"])
		end
	},
	HttpHeaderValidatorHelper = {
		evaluate = function(triggerPart, request)
			if (triggerPart == nil or
				triggerPart["Operator"] == nil or
				triggerPart["IsNegative"] == nil or
				triggerPart["IsIgnoreCase"] == nil or
				triggerPart["HttpHeaderName"] == nil) then
				return false
			end

			local headerValue = ""
			local headerName = triggerPart["HttpHeaderName"]
			if (headerName ~= nil and request.getHeader(string.lower(headerName)) ~= nil) then
				headerValue = request.getHeader(string.lower(headerName))
			end

			return comparisonOperatorHelper.evaluate(
				triggerPart["Operator"],
				triggerPart["IsNegative"],
				triggerPart["IsIgnoreCase"],
				headerValue,
				triggerPart["ValueToCompare"],
				triggerPart["ValuesToCompare"])
		end
	},
	RequestBodyValidatorHelper = {
		evaluate = function(triggerPart, request)
			if (triggerPart == nil or
				triggerPart["Operator"] == nil or
				triggerPart["IsNegative"] == nil or
				triggerPart["IsIgnoreCase"] == nil) then
				return false
			end

			local requestBody = request.getBody()

			return comparisonOperatorHelper.evaluate(
				triggerPart["Operator"],
				triggerPart["IsNegative"],
				triggerPart["IsIgnoreCase"],
				requestBody,
				triggerPart["ValueToCompare"],
				triggerPart["ValuesToCompare"])
		end
	}
}

return model