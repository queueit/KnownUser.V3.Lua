local models = require("Models")
local qitHelpers = require("QueueITHelpers")
local iHelpers = require("KnownUserImplementationHelpers")
local utils = require("Utils")
local userInQueueStateCookieRepository = require("UserInQueueStateCookieRepository")

local svc = {
	SDK_VERSION = "3.5.1-beta3"
}

-- Private functions
local function getQueryString(customerId, eventId, configVersion, culture, layoutName)
	local queryStringList = { }
    table.insert(queryStringList, "c=" .. utils.urlEncode(customerId))
    table.insert(queryStringList, "e=" .. utils.urlEncode(eventId))
    table.insert(queryStringList, "ver=v3-lua-" .. svc.SDK_VERSION) 

	if (configVersion == nil) then
		configVersion = "-1"
	end
    table.insert(queryStringList, "cver=" .. configVersion)

    if (utils.toString(culture) ~= "") then
        table.insert(queryStringList, "cid=" .. utils.urlEncode(culture))
    end
	
    if (utils.toString(layoutName) ~= "") then
        table.insert(queryStringList, "l=" .. utils.urlEncode(layoutName))
    end

	return table.concat(queryStringList, "&")
end

local function getInQueueRedirectResult(customerId, targetUrl, config)
    local tparam = ""
	if (utils.toString(targetUrl) ~= "") then
		tparam = "&t=" .. utils.urlEncode(targetUrl)
	end

	local redirectUrl = 
		"https://" .. config.queueDomain .. "/?" .. 
		getQueryString(customerId, config.eventId, config.version, config.culture, config.layoutName) .. 
		tparam
		
    return models.RequestValidationResult.create(models.ActionTypes.QueueAction, config.eventId, nil, redirectUrl, nil)
end

local function getVaidationErrorResult(customerId, targetUrl, config, qParams, errorCode)
    local tParam = ""
	if (utils.toString(targetUrl) ~= "") then
		tParam = "&t=" .. utils.urlEncode(targetUrl)
	end
	
	local query = getQueryString(customerId, config.eventId, config.version, config.culture, config.layoutName)
        .. "&queueittoken=" .. qParams.queueITToken
        .. "&ts=" .. os.time()
        .. tParam
    
	local domainAlias = config.queueDomain
    if (utils.endsWith(domainAlias, "/") == false) then
        domainAlias = domainAlias .. "/"
    end
    local redirectUrl = "https://" .. domainAlias .. "error/" .. errorCode .. "/?" .. query
    return models.RequestValidationResult.create(models.ActionTypes.QueueAction, config.eventId, nil, redirectUrl, nil)
end

local function getQueueITTokenValidationResult(customerId, targetUrl, eventId, secretKey, config, queueParams)
    local calculatedHash = iHelpers.hash.hmac_sha256_encode(queueParams.queueITTokenWithoutHash, secretKey)
    if (string.upper(calculatedHash) ~= string.upper(queueParams.hashCode)) then
        return getVaidationErrorResult(customerId, targetUrl, config, queueParams, "hash")
    end

    if (string.upper(queueParams.eventId) ~= string.upper(eventId)) then
        return getVaidationErrorResult(customerId, targetUrl, config, queueParams, "eventid")
    end

	if (queueParams.timeStamp < os.time()) then
       return getVaidationErrorResult(customerId, targetUrl, config, queueParams, "timestamp")
    end
	
	userInQueueStateCookieRepository.store(
        config.eventId,
        queueParams.queueId,
        queueParams.cookieValidityMinutes,
        utils.toString(config.cookieDomain),
        queueParams.redirectType,
        secretKey)

	return models.RequestValidationResult.create(models.ActionTypes.QueueAction, config.eventId, queueParams.queueId, nil, queueParams.redirectType)
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
		local result = models.RequestValidationResult.create(models.ActionTypes.QueueAction, config.eventId, state.queueId, nil, state.redirectType)
        return result
    end

    if (utils.toString(queueitToken) ~= "") then
        local queueParams = qitHelpers.QueueUrlParams.extractQueueParams(queueitToken)
        return getQueueITTokenValidationResult(customerId, targetUrl, config.eventId, secretKey, config, queueParams)
    else
        return getInQueueRedirectResult(customerId, targetUrl, config)
    end
end

svc.validateCancelRequest = function(targetUrl, cancelConfig, customerId, secretKey)
	--we do not care how long cookie is valid while canceling cookie
	local state = userInQueueStateCookieRepository.getState(cancelConfig.eventId, -1, secretKey, false)
    if (state.isValid) then        
        userInQueueStateCookieRepository.cancelQueueCookie(cancelConfig.eventId, cancelConfig.cookieDomain)
        
		local rParam = ""
		if (utils.toString(targetUrl) ~= "") then
			rParam = "&r=" .. utils.urlEncode(targetUrl)
		end

		local query = getQueryString(customerId, cancelConfig.eventId, cancelConfig.version, nil, nil) .. rParam
		
        local domainAlias = cancelConfig.queueDomain
		if (utils.endsWith(domainAlias, "/") == false) then
			domainAlias = domainAlias .. "/"
		end
        local redirectUrl = "https://" .. domainAlias .. "cancel/" .. customerId .. "/" .. cancelConfig.eventId .. "/?" .. query
        return models.RequestValidationResult.create(models.ActionTypes.CancelAction, cancelConfig.eventId, state.queueId, redirectUrl, state.redirectType)        
    else
        return models.RequestValidationResult.create(models.ActionTypes.CancelAction, cancelConfig.eventId, nil, nil, nil)
    end
end

svc.extendQueueCookie = function(eventId, cookieValidityMinutes, cookieDomain, secretKey)
	userInQueueStateCookieRepository.reissueQueueCookie(eventId, cookieValidityMinutes, cookieDomain, secretKey)
end

svc.getIgnoreActionResult = function() 
	return models.RequestValidationResult.create(models.ActionTypes.IgnoreAction, nil, nil, nil, nil)
end

return svc