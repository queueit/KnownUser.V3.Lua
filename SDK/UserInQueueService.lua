local models = require("Models")
local qitHelpers = require("QueueITHelpers")
local iHelpers = require("KnownUserImplementationHelpers")
local utils = require("Utils")
local userInQueueStateCookieRepository = require("UserInQueueStateCookieRepository")

local svc = {
	SDK_VERSION = "v3-lua-" .. "3.6.1"
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

local function cancelQueueCookieReturnQueueResult(customerId, targetUrl, config)
    userInQueueStateCookieRepository.cancelQueueCookie(config.eventId, config.cookieDomain)
   
    local tparam = ""
	if (utils.toString(targetUrl) ~= "") then
		tparam = "&t=" .. utils.urlEncode(targetUrl)
	end

    local query = getQueryString(customerId, config.eventId, config.version, 
                                    config.actionName, config.culture, config.layoutName) .. tparam

    local redirectUrl = generateRedirectUrl(config.queueDomain, "", query)
		
    return models.RequestValidationResult.create(models.ActionTypes.QueueAction, config.eventId, nil, redirectUrl, nil, config.actionName)
end

local function cancelQueueCookieReturnErrorResult(customerId, targetUrl, config, qParams, errorCode)
    userInQueueStateCookieRepository.cancelQueueCookie(config.eventId, config.cookieDomain)
    
    local tParam = ""
	if (utils.toString(targetUrl) ~= "") then
		tParam = "&t=" .. utils.urlEncode(targetUrl)
	end
	
	local query = getQueryString(customerId, config.eventId, config.version, config.actionName, config.culture, config.layoutName)
        .. "&queueittoken=" .. qParams.queueITToken
        .. "&ts=" .. os.time()
        .. tParam

    local redirectUrl = generateRedirectUrl(config.queueDomain, "error/" .. errorCode .. "/", query)

    return models.RequestValidationResult.create(models.ActionTypes.QueueAction, config.eventId, nil, redirectUrl, nil, config.actionName)
end

local function getQueueITTokenValidationResult(customerId, targetUrl, secretKey, config, queueParams)
    local calculatedHash = iHelpers.hash.hmac_sha256_encode(queueParams.queueITTokenWithoutHash, secretKey)
    if (string.upper(calculatedHash) ~= string.upper(queueParams.hashCode)) then
        return cancelQueueCookieReturnErrorResult(customerId, targetUrl, config, queueParams, "hash")
    end

    if (string.upper(queueParams.eventId) ~= string.upper(config.eventId)) then
        return cancelQueueCookieReturnErrorResult(customerId, targetUrl, config, queueParams, "eventid")
    end

	if (queueParams.timeStamp < os.time()) then
       return cancelQueueCookieReturnErrorResult(customerId, targetUrl, config, queueParams, "timestamp")
    end
	
	userInQueueStateCookieRepository.store(
        config.eventId,
        queueParams.queueId,
        queueParams.cookieValidityMinutes,
        utils.toString(config.cookieDomain),
        queueParams.redirectType,
        secretKey)

	return models.RequestValidationResult.create(models.ActionTypes.QueueAction, config.eventId, queueParams.queueId, nil, queueParams.redirectType, config.actionName)
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
		local result = models.RequestValidationResult.create(models.ActionTypes.QueueAction, config.eventId, state.queueId, nil, state.redirectType, config.actionName)
        return result
    end
    
    local queueParams = qitHelpers.QueueUrlParams.extractQueueParams(queueitToken)
    if (queueParams ~= nil) then
        return getQueueITTokenValidationResult(customerId, targetUrl, secretKey, config, queueParams)
    else
        return cancelQueueCookieReturnQueueResult(customerId, targetUrl, config)
    end
end

svc.validateCancelRequest = function(targetUrl, cancelConfig, customerId, secretKey)
	--we do not care how long cookie is valid while canceling cookie
	local state = userInQueueStateCookieRepository.getState(cancelConfig.eventId, -1, secretKey, false)
    if (state.isValid) then      
        local uriPath = "cancel/" .. customerId .. "/" .. cancelConfig.eventId .. "/"
        userInQueueStateCookieRepository.cancelQueueCookie(cancelConfig.eventId, cancelConfig.cookieDomain)
        
        local rParam = ""
		if (utils.toString(targetUrl) ~= "") then
			rParam = "&r=" .. utils.urlEncode(targetUrl)
		end
        local query = getQueryString(customerId, cancelConfig.eventId, cancelConfig.version, cancelConfig.actionName, nil, nil) .. rParam
        local redirectUrl = generateRedirectUrl(cancelConfig.queueDomain, uriPath, query)
       		
        return models.RequestValidationResult.create(models.ActionTypes.CancelAction, cancelConfig.eventId, 
                                                    state.queueId, redirectUrl, state.redirectType, cancelConfig.actionName)        
    else
        return models.RequestValidationResult.create(models.ActionTypes.CancelAction, cancelConfig.eventId, nil, nil, nil, cancelConfig.actionName)
    end
end

svc.extendQueueCookie = function(eventId, cookieValidityMinutes, cookieDomain, secretKey)
	userInQueueStateCookieRepository.reissueQueueCookie(eventId, cookieValidityMinutes, cookieDomain, secretKey)
end

svc.getIgnoreActionResult = function(actionName) 
	return models.RequestValidationResult.create(models.ActionTypes.IgnoreAction, nil, nil, nil, nil, actionName)
end

return svc