local iHelpers = require("KnownUserImplementationHelpers")
local knownUser = require("KnownUser")
local utils = require("Utils")

iHelpers.system.getConnectorName = function()
	return "nginx-" .. ngx.config.nginx_version
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
	return ngx.req.get_headers()[name]
end

iHelpers.request.getBody = function()
	ngx.req.read_body()
	return ngx.req.get_body_data()
end

iHelpers.request.getUnescapedCookieValue = function(name)
	local key = "cookie_" .. name
	local value = ngx.var[key]
	
	if (value ~= nil) then
		return utils.urlDecode(value)
	end
	return value
end

iHelpers.request.getUserHostAddress = function()
	return ngx.var.remote_addr
end

iHelpers.response.setCookie = function(name, value, expire, domain)
	-- lua_mod only supports 1 Set-Cookie header (because 'header' is a table).
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

	ngx.header["Set-Cookie"] = name .. '=' .. value
		.. expire_text
		.. (domain ~= "" and '; Domain=' .. domain or '')
		.. (iHelpers.response.cookieOptions.httpOnly and '; HttpOnly' or '')
		.. (iHelpers.response.cookieOptions.secure and '; Secure' or '')
		.. '; Path=/;'
end

iHelpers.request.getAbsoluteUri = function()
	return ngx.var.scheme .. "://" .. ngx.var.http_host .. ngx.var.request_uri
end

local aHandler = {}

aHandler.setOptions = function(options)
	if (options == nil) then
		error('invalid options')
	end
	
	if (options.secure) then
		iHelpers.response.cookieOptions.secure = true
	else
		iHelpers.response.cookieOptions.secure = false
	end
	
	if (options.httpOnly) then
		iHelpers.response.cookieOptions.httpOnly = true
	else
		iHelpers.response.cookieOptions.httpOnly = false
	end	
end

aHandler.handleByIntegrationConfig = function(customerId, secretKey, integrationConfigJson)
	local queueitToken = ''
	if (ngx.var.arg_queueittoken ~= nil) then
		queueitToken = ngx.var.arg_queueittoken
	end

	local fullUrl = iHelpers.request.getAbsoluteUri()
	local currentUrlWithoutQueueitToken = fullUrl:gsub("([\\%?%&])(" .. knownUser.QUEUEIT_TOKEN_KEY .. "=[^&]*)", "")

	local validationResult = knownUser.validateRequestByIntegrationConfig(
		currentUrlWithoutQueueitToken, queueitToken, integrationConfigJson, customerId, secretKey)

	if (validationResult:doRedirect()) then
		-- Adding no cache headers to prevent browsers to cache requests
		ngx.header["Cache-Control"] = "no-cache, no-store, must-revalidate, max-age=0"
		ngx.header["Pragma"] = "no-cache"
		ngx.header["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
		-- end
		
		if (validationResult.isAjaxResult) then
			ngx.header[validationResult.getAjaxQueueRedirectHeaderKey()] = validationResult:getAjaxRedirectUrl()
		else
			ngx.redirect(validationResult.redirectUrl)
			ngx.exit(ngx.HTTP_MOVED_TEMPORARILY)
		end
	else
		-- Request can continue 
		-- - we remove queueittoken form querystring parameter to avoid sharing of user specific token
		if (fullUrl ~= currentUrlWithoutQueueitToken and validationResult.actionType == "Queue") then
			ngx.redirect(currentUrlWithoutQueueitToken)
			ngx.exit(ngx.HTTP_MOVED_TEMPORARILY)
		end
	end

	ngx.exit(ngx.OK)
end

return aHandler