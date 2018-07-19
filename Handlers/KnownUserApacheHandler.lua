iHelpers = require("KnownUserImplementationHelpers")
knownUser = require("KnownUser")
utils = require("Utils")

local aHandler = {}

aHandler.handle = function(customerId, secretKey, integrationConfigJson, request_rec)	
	assert(customerId ~= nil, "customerId invalid")
	assert(secretKey ~= nil, "secretKey invalid")
	assert(integrationConfigJson ~= nil, "integrationConfigJson invalid")
	assert(request_rec ~= nil, "request_rec invalid")
	
	-- Implement required helpers
	-- ********************************************************************************		
	iHelpers.request.getHeader = function(name)
		return request_rec.headers_in[name]
	end
	iHelpers.request.getUnescapedCookieValue = function(name) 
		local cookieValue = request_rec:getcookie(name)
		
		if (cookieValue ~= nil) then
			cookieValue = utils.urlDecode(cookieValue)
		end

		return cookieValue
	end
	iHelpers.response.setCookie = function(name, value, expire, domain)
		if (domain == nil) then
			domain = ""
		end
		
		request_rec:setcookie{
			key = name,
			value = value,
			expires = expire,
			secure = false,
			httponly = false,
			path = "/",
			domain = domain
		}
	end
		
	-- ********************************************************************************
	-- END Implement required helpers

	--Adding no cache headers to prevent browsers to cache requests
	request_rec.headers_out["Cache-Control"] = "no-cache, no-store, must-revalidate"
	request_rec.headers_out["Pragma"] = "no-cache"
	request_rec.headers_out["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
	--end

	local queueitToken = request_rec:parseargs()["queueittoken"]
	local fullUrl = "http://" .. request_rec.hostname .. ":" .. request_rec.port .. request_rec.unparsed_uri 
	local currentUrlWithoutQueueitToken = fullUrl:gsub("([\\%?%&])(" .. knownUser.QUEUEIT_TOKEN_KEY .. "=[^&]*)", "")
	
	local validationResult = knownUser.validateRequestByIntegrationConfig(currentUrlWithoutQueueitToken, queueitToken, integrationConfigJson, customerId, secretKey)

	if (validationResult:doRedirect()) then
		if (validationResult.isAjaxResult == false) then
			request_rec.headers_out["Location"] = validationResult.redirectUrl			
			return apache2.HTTP_MOVED_TEMPORARILY		
		else
			request_rec.headers_out[validationResult.getAjaxQueueRedirectHeaderKey()] = validationResult:getAjaxRedirectUrl()
			return apache2.OK
		end
	else
		-- Request can continue - we remove queueittoken form querystring parameter to avoid sharing of user specific token	if did not match
		if (fullUrl ~= currentUrlWithoutQueueitToken and validationResult.actionType ~= nil) then
			request_rec.headers_out["Location"] = currentUrlWithoutQueueitToken
			return apache2.HTTP_MOVED_TEMPORARILY
		end
	end
end

return aHandler