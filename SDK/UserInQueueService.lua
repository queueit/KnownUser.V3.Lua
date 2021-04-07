local models = require("Models")
local qitHelpers = require("QueueITHelpers")
local iHelpers = require("KnownUserImplementationHelpers")
local utils = require("Utils")
local userInQueueStateCookieRepository = require("UserInQueueStateCookieRepository")

local svc = {
	SDK_VERSION = "v3-lua-" .. "3.6.5",
	TokenValidationResult = {
		create = function(isValid, errorCode)
			local model = {
				isValid = isValid;
				errorCode = errorCode;
			}

			return model
		end
	}
}

-- Private functions
local function getQueryString(customerId, eventId, configVersion, actionName, culture, layoutName)
	local queryStringList = { }
	table.insert(queryStringList, "c=" .. utils.urlEncode(customerId))
	table.insert(queryStringList, "e=" .. utils.urlEncode(eventId))
	table.insert(queryStringList, "ver=" .. svc.SDK_VERSION)
	table.insert(queryStringList, "kupver=" .. utils.urlEncode(iHelpers.system.getConnectorName()))

	if (configVersion == nil) then
		configVersion = "-1"
	end
	table.insert(queryStringList, "cver=" .. configVersion)
	table.insert(queryStringList, "man=" .. utils.urlEncode(actionName))

	if (utils.toString(culture) ~= "") then
		table.insert(queryStringList, "cid=" .. utils.urlEncode(culture))
	end

	if (utils.toString(layoutName) ~= "") then
		table.insert(queryStringList, "l=" .. utils.urlEncode(layoutName))
	end

	return table.concat(queryStringList, "&")
end

local function generateRedirectUrl(queueDomain, uriPath, query)
	uriPath = uriPath or ""
	if(not utils.endsWith(queueDomain, "/")) then
		queueDomain = queueDomain .. "/"
	end
	return "https://" .. queueDomain .. uriPath .. "?" .. query
end

local function getQueueResult(targetUrl, config, customerId)
	local tparam = ""
	if (utils.toString(targetUrl) ~= "") then
		tparam = "&t=" .. utils.urlEncode(targetUrl)
	end

	local query = getQueryString(customerId, config.eventId, config.version,
		config.actionName, config.culture, config.layoutName) .. tparam

	local redirectUrl = generateRedirectUrl(config.queueDomain, "", query)

	return models.RequestValidationResult.create(
		models.ActionTypes.QueueAction, config.eventId, nil, redirectUrl, nil, config.actionName)
end

local function getErrorResult(customerId, targetUrl, config, qParams, errorCode)
	local tParam = ""
	if (utils.toString(targetUrl) ~= "") then
		tParam = "&t=" .. utils.urlEncode(targetUrl)
	end

	local query = getQueryString(
		customerId, config.eventId, config.version, config.actionName, config.culture, config.layoutName)
		.. "&queueittoken=" .. qParams.queueITToken
		.. "&ts=" .. os.time()
		.. tParam

	local redirectUrl = generateRedirectUrl(config.queueDomain, "error/" .. errorCode .. "/", query)

	return models.RequestValidationResult.create(
		models.ActionTypes.QueueAction, config.eventId, nil, redirectUrl, nil, config.actionName)
end

local function getValidTokenResult(config, queueParams, secretKey)
	userInQueueStateCookieRepository.store(
		config.eventId,
		queueParams.queueId,
		queueParams.cookieValidityMinutes,
		utils.toString(config.cookieDomain),
		queueParams.redirectType,
		secretKey)
	return models.RequestValidationResult.create(
		models.ActionTypes.QueueAction, config.eventId, queueParams.queueId,
		nil, queueParams.redirectType, config.actionName)
end

local function validateToken(config, queueParams, secretKey)
	local calculatedHash = iHelpers.hash.hmac_sha256_encode(queueParams.queueITTokenWithoutHash, secretKey)
	if (string.upper(calculatedHash) ~= string.upper(queueParams.hashCode)) then
		return svc.TokenValidationResult.create(false, "hash")
	end

	if (string.upper(queueParams.eventId) ~= string.upper(config.eventId)) then
		return svc.TokenValidationResult.create(false, "eventid")
	end

	if (queueParams.timeStamp < os.time()) then
		return svc.TokenValidationResult.create(false, "timestamp")
	end

	return svc.TokenValidationResult.create(true, "")
end

-- END Private functions

svc.validateQueueRequest = function(targetUrl, queueitToken, config, customerId, secretKey)
	local state = userInQueueStateCookieRepository.getState(config.eventId, config.cookieValidityMinute, secretKey, true)

	if (state.isValid) then
		if (state:isStateExtendable() and config.extendCookieValidity) then
			userInQueueStateCookieRepository.store(
				config.eventId,
				state.queueId,
				nil,
				utils.toString(config.cookieDomain),
				state.redirectType,
				secretKey)
		end
		local result = models.RequestValidationResult.create(
			models.ActionTypes.QueueAction, config.eventId, state.queueId, nil, state.redirectType, config.actionName)
		return result
	end

	local queueParams = qitHelpers.QueueUrlParams.extractQueueParams(queueitToken)

	local requestValidationResult
	local isTokenValid = false

	if (queueParams ~= nil) then
		local tokenValidationResult = validateToken(config, queueParams, secretKey)
		isTokenValid = tokenValidationResult.isValid

		if(isTokenValid) then
			requestValidationResult = getValidTokenResult(config, queueParams, secretKey)
		else
			requestValidationResult = getErrorResult(
				customerId, targetUrl, config, queueParams, tokenValidationResult.errorCode);
		end
	else
		requestValidationResult = getQueueResult(targetUrl, config, customerId);
	end

	if (state.isFound and not isTokenValid) then
		userInQueueStateCookieRepository.cancelQueueCookie(config.eventId, config.cookieDomain);
	end

	return requestValidationResult;
end

svc.validateCancelRequest = function(targetUrl, cancelConfig, customerId, secretKey)
	-- we do not care how long cookie is valid while canceling cookie
	local state = userInQueueStateCookieRepository.getState(cancelConfig.eventId, -1, secretKey, false)
	if (state.isValid) then
		local uriPath = "cancel/" .. customerId .. "/" .. cancelConfig.eventId .. "/"
		userInQueueStateCookieRepository.cancelQueueCookie(cancelConfig.eventId, cancelConfig.cookieDomain)

		local rParam = ""
		if (utils.toString(targetUrl) ~= "") then
			rParam = "&r=" .. utils.urlEncode(targetUrl)
		end
		local query = getQueryString(
			customerId, cancelConfig.eventId, cancelConfig.version, cancelConfig.actionName, nil, nil) .. rParam
		local redirectUrl = generateRedirectUrl(cancelConfig.queueDomain, uriPath, query)

		return models.RequestValidationResult.create(
			models.ActionTypes.CancelAction, cancelConfig.eventId,
			state.queueId, redirectUrl, state.redirectType, cancelConfig.actionName)
	else
		return models.RequestValidationResult.create(
		models.ActionTypes.CancelAction, cancelConfig.eventId, nil, nil, nil, cancelConfig.actionName)
	end
end

svc.extendQueueCookie = function(eventId, cookieValidityMinutes, cookieDomain, secretKey)
	userInQueueStateCookieRepository.reissueQueueCookie(eventId, cookieValidityMinutes, cookieDomain, secretKey)
end

svc.getIgnoreActionResult = function(actionName)
	return models.RequestValidationResult.create(models.ActionTypes.IgnoreAction, nil, nil, nil, nil, actionName)
end

return svc