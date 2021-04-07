local iHelpers = require("KnownUserImplementationHelpers")
local knownUser = require("KnownUser")
local utils = require("Utils")

local aHandler = {}

local function handle(customerId, secretKey, config, isIntegrationConfig, request_rec)
	assert(customerId ~= nil, "customerId invalid")
	assert(secretKey ~= nil, "secretKey invalid")
	assert(config ~= nil, "config invalid")
	assert(isIntegrationConfig ~= nil, "isIntegrationConfig invalid")
	assert(request_rec ~= nil, "request_rec invalid")

	-- Implement required helpers
	-- ********************************************************************************
	iHelpers.system.getConnectorName = function()
		return apache2.version
	end

	iHelpers.json.parse = function(jsonStr)
		local json = require("json")
		return json.parse(jsonStr)
	end

	iHelpers.hash.hmac_sha256_encode = function(message, key)
		local sha2 = require("sha2")
		return sha2.hmac(sha2.sha256, key, message)
	end

	iHelpers.request.getHeader = function(name)
		return request_rec.headers_in[name]
	end

	iHelpers.request.getBody = function()
		local reqBody = ""
		-- Out of memory error will be raised,
		-- when trying to read an empty request body. 
		-- Therefore wrap this in a pcall to ignore that scenario.
		pcall(
			function()
				reqBody = request_rec:requestbody()
			end
		)
		return reqBody
	end

	iHelpers.request.getUnescapedCookieValue = function(name)
		-- Alternative to request_rec:getcookie method,
		-- which fails if client sends a Cookie header with multiple entries with same name/key.
		local function getCookieValue(_name)
			local function split(inputstr, sep)
				sep=sep or '%s' local t={}
				for field,s in string.gmatch(inputstr, "([^"..sep.."]*)("..sep.."?)") do
					table.insert(t,field)
					if s=="" then
						return t
					end
				end
			end

			if (_name == nil) then
				return nil
			end

			local cookieHeader = request_rec.headers_in["Cookie"]

			if(cookieHeader == nil) then
				return nil
			end

			local cookieHeaderParts = split(cookieHeader, ";")

			if (cookieHeaderParts == nil) then
				return nil
			end

			-- Translate name to pattern so it will work correctly in string.find
			-- ex. translate 'QueueITAccepted-SDFrts345E-V3_event1' to 'QueueITAccepted--SDFrts345E--V3_event1='
			_name = _name:gsub("-", "--") .. "="

			for _, v in pairs(cookieHeaderParts) do
				local _, endIndex = string.find(v, _name)

				if(endIndex ~= nil) then
					return v:sub(endIndex + 1)
				end
			end
		end

		local cookieValue = getCookieValue(name)

		if (cookieValue ~= nil) then
			cookieValue = utils.urlDecode(cookieValue)
		end

		return cookieValue
	end

	iHelpers.request.getUserHostAddress = function()
		return request_rec.useragent_ip
	end

	-- Implementation is not using built in r:setcookie method
	-- because we want to support Apache version < 2.4.12
	-- where there is bug in that specific method
	iHelpers.response.setCookie = function(name, value, expire, domain)
		-- lua_mod only supports 1 Set-Cookie header (because 'err_headers_out' is a table).
		-- So calling this method (setCookie) multiple times will not work as expected.
		-- In this case final call will apply.

		if (domain == nil) then
			domain = ""
		end

		if (value == nil) then
			value = ""
		end

		value = utils.urlEncode(value)

		local expire_text = ''
		if expire ~= nil and type(expire) == "number" and expire > 0 then
			expire_text = '; Expires=' .. os.date("!%a, %d %b %Y %H:%M:%S GMT", expire)
		end

		request_rec.err_headers_out["Set-Cookie"] = name .. '=' .. value
			.. expire_text
			.. (domain ~= "" and '; Domain=' .. domain or '')
			.. (iHelpers.response.cookieOptions.httpOnly and '; HttpOnly' or '')
			.. (iHelpers.response.cookieOptions.secure and '; Secure' or '')
			.. '; Path=/;'

	end
	-- ********************************************************************************
	-- END Implement required helpers

	local queueitToken = request_rec:parseargs()["queueittoken"]
	local fullUrl = iHelpers.request.getAbsoluteUri()
	local currentUrlWithoutQueueitToken = fullUrl:gsub("([\\%?%&])(" .. knownUser.QUEUEIT_TOKEN_KEY .. "=[^&]*)", "")

	local validationResult
	if (isIntegrationConfig) then
		validationResult = knownUser.validateRequestByIntegrationConfig(currentUrlWithoutQueueitToken, queueitToken, config, customerId, secretKey)
	else
		validationResult = knownUser.resolveQueueRequestByLocalConfig(currentUrlWithoutQueueitToken, queueitToken, config, customerId, secretKey)
	end

	if (validationResult:doRedirect()) then
		-- Adding no cache headers to prevent browsers to cache requests
		request_rec.err_headers_out["Cache-Control"] = "no-cache, no-store, must-revalidate, max-age=0"
		request_rec.err_headers_out["Pragma"] = "no-cache"
		request_rec.err_headers_out["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
		-- end

		if (validationResult.isAjaxResult) then
			request_rec.err_headers_out[validationResult.getAjaxQueueRedirectHeaderKey()] = validationResult:getAjaxRedirectUrl()
		else
			request_rec.err_headers_out["Location"] = validationResult.redirectUrl
			return apache2.HTTP_MOVED_TEMPORARILY
		end
	else
		-- Request can continue - we remove queueittoken form querystring parameter to avoid sharing of user specific token
		if (fullUrl ~= currentUrlWithoutQueueitToken and validationResult.actionType == "Queue") then
			request_rec.err_headers_out["Location"] = currentUrlWithoutQueueitToken
			return apache2.HTTP_MOVED_TEMPORARILY
		end
	end

	return apache2.DECLINED
end

aHandler.handleByIntegrationConfig = function(customerId, secretKey, integrationConfigJson, request_rec)
	return handle(customerId, secretKey, integrationConfigJson, true, request_rec)
end

aHandler.handleByLocalConfig = function(customerId, secretKey, queueEventConfig, request_rec)
	return handle(customerId, secretKey, queueEventConfig, false, request_rec)
end

return aHandler