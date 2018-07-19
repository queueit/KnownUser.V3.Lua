local models = require("Models")
local integrationEvaluator = require("IntegrationEvaluator")
local qitHelpers = require("QueueITHelpers")
local userInQueueService = require("UserInQueueService")
local utils = require("Utils")
local iHelpers = require("KnownUserImplementationHelpers")

local ku = {
	QUEUEIT_TOKEN_KEY = "queueittoken"	
}

local QUEUEIT_DEBUG_KEY = "queueitdebug"
local QUEUEIT_AJAX_HEADER_KEY = "x-queueit-ajaxpageurl"

-- Private functions
local function isQueueAjaxCall() 
	return iHelpers.request.getHeader(QUEUEIT_AJAX_HEADER_KEY) ~= nil
end

local function logMoreRequestDetails(debugInfos)	
	debugInfos["ServerUtcTime"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
    debugInfos["RequestIP"] = iHelpers.request.getUserHostAddress()
    debugInfos["RequestHttpHeader_Via"] = utils.toString(iHelpers.request.getHeader('via'))
    debugInfos["RequestHttpHeader_Forwarded"] = utils.toString(iHelpers.request.getHeader('forwarded'))
    debugInfos["RequestHttpHeader_XForwardedFor"] = utils.toString(iHelpers.request.getHeader('x-forwarded-for'))
    debugInfos["RequestHttpHeader_XForwardedHost"] = utils.toString(iHelpers.request.getHeader('x-forwarded-host'))
    debugInfos["RequestHttpHeader_XForwardedProto"] = utils.toString(iHelpers.request.getHeader('x-forwarded-proto'))
end

local debugInfoArray = { }
local function doCookieLog(debugInfos, sendCookie)
    for key, value in pairs(debugInfos) do
		if (debugInfoArray[key] == nil) then
			debugInfoArray[key] = value
		end
	end

	if (sendCookie) then	
		local cookieValue = ""
		for key, value in pairs(debugInfoArray) do
			cookieValue = cookieValue .. (key .. "=" .. value .. "|")
		end
		cookieValue = cookieValue:sub(0, cookieValue:len()-1) -- remove trailing |
		iHelpers.response.setCookie(QUEUEIT_DEBUG_KEY, cookieValue, 0, nil)
	end
end

local function getIsDebug(queueitToken, secretKey)    
    if (utils.toString(queueitToken) ~= "") then
		local queueParams = qitHelpers.QueueUrlParams.extractQueueParams(queueitToken)
		if (string.lower(queueParams.redirectType) == "debug") then
			local calculatedHash = iHelpers.hash.hmac_sha256_encode(queueParams.queueITTokenWithoutHash, secretKey)
            return string.upper(calculatedHash) == string.upper(queueParams.hashCode)
		end
    end
    return false
end

local function generateTargetUrl(originalTargetUrl)
    if (isQueueAjaxCall()) then
		local headerValue = iHelpers.request.getHeader(QUEUEIT_AJAX_HEADER_KEY)
		return utils.urlDecode(headerValue)
	else
        return originalTargetUrl
	end
end

local function resolveRequestByLocalEventConfig(targetUrl, queueitToken, queueConfig, customerId, secretKey)
	if (getIsDebug(queueitToken, secretKey)) then		
		local queueConfigValue = "NULL"
		if (queueConfig ~= nil) then
			queueConfigValue = queueConfig:getString()
		end
			
		local dic = 
		{
			TargetUrl = targetUrl,
			QueueitToken = queueitToken,
			QueueConfig = queueConfigValue,
			OriginalUrl = iHelpers.request.getAbsoluteUri()
		}
		logMoreRequestDetails(dic)
		doCookieLog(dic, true)
	end		

	assert(utils.toString(customerId) ~= "", "customerId can not be nil or empty.")				
	assert(utils.toString(secretKey) ~= "", "secretKey can not be nil or empty.")
	assert(utils.toString(queueConfig.eventId) ~= "", "eventId from queueConfig can not be nil or empty.")			
	assert(utils.toString(queueConfig.queueDomain) ~= "", "queueDomain from queueConfig can not be nil or empty.")		
	assert(type(queueConfig.cookieValidityMinute) == "number" and queueConfig.cookieValidityMinute > 0, "cookieValidityMinute from queueConfig should be a number greater than 0.")		
	assert(type(queueConfig.extendCookieValidity) == "boolean", "extendCookieValidity from queueConfig should be valid boolean.")
		
	local result = userInQueueService.validateQueueRequest(targetUrl, queueitToken, queueConfig, customerId, secretKey)
	result.isAjaxResult = isQueueAjaxCall()
	return result		
end
-- END Private functions

ku.extendQueueCookie = function(eventId, cookieValidityMinute, cookieDomain, secretKey)
	assert(utils.toString(eventId) ~= "", "eventId can not be nil or empty.")
	assert(utils.toString(secretKey) ~= "", "secretKey can not be nil or empty.")
	
	cookieValidityMinute = tonumber(cookieValidityMinute)
	if (cookieValidityMinute == nil or cookieValidityMinute <= 0) then
		error("cookieValidityMinute should be a number greater than 0.")
	end

	userInQueueService.extendQueueCookie(eventId, cookieValidityMinute, cookieDomain, secretKey)
end

ku.cancelRequestByLocalConfig = function(targetUrl, queueitToken, cancelConfig, customerId, secretKey)
    targetUrl = generateTargetUrl(targetUrl)
	
	if (getIsDebug(queueitToken, secretKey)) then
        local cancelConfigValue = "NULL"
		if (cancelConfig ~= nil) then
			cancelConfigValue = cancelConfig:getString()
		end
		
		local dic = 
		{
			TargetUrl = targetUrl,
			QueueitToken = queueitToken,
			CancelConfig = cancelConfigValue,
			OriginalUrl = iHelpers.request.getAbsoluteUri() 
		}		
		logMoreRequestDetails(dic)
        doCookieLog(dic, true)
    end

	assert(utils.toString(targetUrl) ~= "", "targetUrl can not be nil or empty.")
	assert(utils.toString(customerId) ~= "", "customerId can not be nil or empty.")
	assert(utils.toString(secretKey) ~= "", "secretKey can not be nil or empty.")
	assert(utils.toString(cancelConfig.eventId) ~= "", "eventId from cancelConfig can not be nil or empty.")
	assert(utils.toString(cancelConfig.queueDomain) ~= "", "queueDomain from cancelConfig can not be nil or empty.")

    local result = userInQueueService.validateCancelRequest(targetUrl, cancelConfig, customerId, secretKey)
    result.isAjaxResult = isQueueAjaxCall()
    return result
end

ku.validateRequestByIntegrationConfig = function(currentUrlWithoutQueueITToken, queueitToken, integrationConfigJson, customerId, secretKey)
    -- Private functions
	local function handleQueueAction(currentUrlWithoutQueueITToken, queueitToken, customerIntegration, customerId, secretKey, matchedConfig)
        local eventConfig = models.QueueEventConfig.create()
        local targetUrl = ""
        eventConfig.eventId = matchedConfig["EventId"]
        eventConfig.queueDomain = matchedConfig["QueueDomain"]
        eventConfig.layoutName = matchedConfig["LayoutName"]
		eventConfig.culture = matchedConfig["Culture"]
        eventConfig.cookieDomain = matchedConfig["CookieDomain"]
        eventConfig.extendCookieValidity = matchedConfig["ExtendCookieValidity"]
        eventConfig.cookieValidityMinute = matchedConfig["CookieValidityMinute"]
        eventConfig.version = customerIntegration["Version"]

		if (matchedConfig["RedirectLogic"] == "ForcedTargetUrl" or matchedConfig["RedirectLogic"] == "ForecedTargetUrl") then
			targetUrl = matchedConfig["ForcedTargetUrl"]
		else
			if (matchedConfig["RedirectLogic"] == "EventTargetUrl") then
				targetUrl = ""
			else
                targetUrl = generateTargetUrl(currentUrlWithoutQueueITToken)
			end
		end

        return resolveRequestByLocalEventConfig(targetUrl, queueitToken, eventConfig, customerId, secretKey)
    end
	
	local function handleCancelAction(currentUrlWithoutQueueITToken, queueitToken, customerIntegration, customerId, secretKey, matchedConfig)    
        local cancelEventConfig = models.CancelEventConfig.create()
        cancelEventConfig.eventId = matchedConfig["EventId"]
        cancelEventConfig.queueDomain = matchedConfig["QueueDomain"]
        cancelEventConfig.cookieDomain = matchedConfig["CookieDomain"]
        cancelEventConfig.version = customerIntegration["Version"]
        return ku.cancelRequestByLocalConfig(currentUrlWithoutQueueITToken, queueitToken, cancelEventConfig, customerId, secretKey)
    end
	-- END Private functions
		
	local isDebug = getIsDebug(queueitToken, secretKey)
	if (isDebug) then
        local dic = 
		{
			QueueitToken = queueitToken,
			PureUrl = currentUrlWithoutQueueITToken,
			OriginalUrl = iHelpers.request.getAbsoluteUri()
		}
		logMoreRequestDetails(dic)
        doCookieLog(dic, false)
    end
	
	assert(utils.toString(currentUrlWithoutQueueITToken) ~= "", "currentUrlWithoutQueueITToken can not be nil or empty.")
	assert(utils.toString(integrationConfigJson) ~= "", "integrationConfigJson can not be nil or empty.")

	local customerIntegration = iHelpers.json.parse(integrationConfigJson)
    if (isDebug) then
        local dic = { ConfigVersion = customerIntegration["Version"] }
        doCookieLog(dic, false)
    end
	local matchedConfig = integrationEvaluator.getMatchedIntegrationConfig(customerIntegration, currentUrlWithoutQueueITToken, iHelpers.request)

    if (isDebug) then
		local matchedConfigValue = "NULL"
		if (matchedConfig ~= nil and matchedConfig["Name"] ~= nil) then
			matchedConfigValue = matchedConfig["Name"]
		end
        local dic = { MatchedConfig = matchedConfigValue }
        doCookieLog(dic, false)
    end

    if (matchedConfig == nil) then
		if (isDebug) then doCookieLog({ }, true) end
		return models.RequestValidationResult.create(nil, nil, nil, nil, nil)
    end

    if (matchedConfig["ActionType"] == models.ActionTypes.QueueAction) then
        return handleQueueAction(currentUrlWithoutQueueITToken, queueitToken, customerIntegration, customerId, secretKey, matchedConfig)   
    end
    
	if (matchedConfig["ActionType"] == models.ActionTypes.CancelAction) then
        return handleCancelAction(currentUrlWithoutQueueITToken, queueitToken, customerIntegration, customerId, secretKey, matchedConfig)
    end

	-- IgnoreAction
	if (isDebug) then doCookieLog({ }, true) end
	local result = userInQueueService.getIgnoreActionResult()
    result.isAjaxResult = isQueueAjaxCall()
    return result
end

ku.resolveRequestByLocalEventConfig = function(targetUrl, queueitToken, queueConfig, customerId, secretKey)	
	local targetUrl = generateTargetUrl(targetUrl)
	return resolveRequestByLocalEventConfig(targetUrl, queueitToken, queueConfig, customerId, secretKey)
end

return ku