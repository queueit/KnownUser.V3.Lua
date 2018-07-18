iHelpers = require("KnownUserImplementationHelpers")
jsonHelper = require("JsonHelper")
knownUser = require("KnownUser")
utils = require("Utils")

local aHandler = {}

aHandler.handle = function(customerId, secretKey, req, odn, resp, originalReq)	
	assert(customerId ~= nil, "customerId invalid")
	assert(secretKey ~= nil, "secretKey invalid")
	assert(req ~= nil, "req invalid")
	assert(odn ~= nil, "odn invalid")
	assert(resp ~= nil, "resp invalid")
	assert(originalReq ~= nil, "originalReq invalid")
	
	-- TODO: integration config should be available. Some cron job etc should ensure its there and updated at relevant intervals.
	local config = odn.get("knownuserconfiguration") 
	assert(config ~= nil and type(config) == "string", "integration config is missing or is invalid type")
	
	-- Implement required helpers
	-- ********************************************************************************
	iHelpers.request.getHeader = function(name)
		return req.header(name) 
	end
	
	iHelpers.request.getUnescapedCookieValue = function(name) 
		local cookieValue = req.cookie(name)

		if (cookieValue ~= nil) then
			cookieValue = utils.urlDecode(cookieValue)
		end

		return cookieValue
	end

	-- TODO: Implement
	iHelpers.response.setCookie = function(name, value, expire, domain)
		if (domain == nil) then
			domain = ""
		end
		
		resp.addCookie( .. ) -- http only?  secure? (both should be false, so its properly OK). path should be "/"
		resp.setHeader( .. ) -- from docs:  If you need to set a domain with a leading dot (ex .somedomain.com) use the addHeader function instead		
	end
	
	-- TODO: Implement
	iHelpers.hash.hmac_sha256_encode = function(message, key)
		error("hash.hmac_sha256_encode - not implemented")
	end

	iHelpers.json.parse = function(jsonStr)
		return jsonHelper.parse(jsonStr)
	end
	-- ********************************************************************************
	-- END Implement required helpers
	
	--Adding no cache headers to prevent browsers to cache requests
	resp.setHeader("Cache-Control", "no-cache, no-store, must-revalidate")
	resp.setHeader("Pragma", "no-cache")
	resp.setHeader("Expires", "Fri, 01 Jan 1990 00:00:00 GMT")
	--end

	local queueitToken = req.query()["queueittoken"]
	local fullUrl = originalReq.scheme() .. originalReq.host() .. originalReq.path() -- no support for port number? is it a problem?
	local currentUrlWithoutQueueitToken = fullUrl:gsub("([\\%?%&])(" .. knownUser.QUEUEIT_TOKEN_KEY .. "=[^&]*)", "")
	
	local validationResult = knownUser.validateRequestByIntegrationConfig(currentUrlWithoutQueueitToken, queueitToken, integrationConfigJson, customerId, secretKey)

	if (validationResult:doRedirect()) then
		if (validationResult.isAjaxResult == false) then
			resp.setHeader("Location", result.redirectUrl)
			resp.setStatusCode(302)
		else
			resp.setHeader(validationResult.getAjaxQueueRedirectHeaderKey(), validationResult:getAjaxRedirectUrl())
			resp.setStatusCode(200)
		end
	else
		-- Request can continue - we remove queueittoken form querystring parameter to avoid sharing of user specific token	if did not match
		if (fullUrl ~= currentUrlWithoutQueueitToken and validationResult.actionType ~= nil) then
			resp.setHeader("Location", currentUrlWithoutQueueitToken)
			resp.setStatusCode(302)
		end
	end
end

return aHandler
