local utils = require("Utils")
local iHelpers = require("KnownUserImplementationHelpers")
local comparisonOperatorHelper = require("ComparisonOperatorHelper")

local model = {
	UrlValidatorHelper = {
		evaluate = function(triggerPart, url)
			-- Private functions
			local function getUrlPart(urlPart, url)        
				-- Private functions
				local function getHostNameFromUrl(url)
					return utils.toString(url:match('^%w+://([^/]+)'))
				end
		
				local function getPathFromUrl(url)
					pathAndQuery = utils.toString(url:match('^%w+://[^/]+(.*)'))
					query = utils.toString(url:match('%?+.*'))
					path = pathAndQuery:gsub(utils.escapeMagicChars(query), "")
			
					return path
				end
				-- END Private functions

				if (urlPart == "PagePath") then 
					return getPathFromUrl(url)
				end
				if (urlPart == "PageUrl") then	
					return url
				end
				if (urlPart == "HostName") then 
					return getHostNameFromUrl(url)
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
	}
}

return model