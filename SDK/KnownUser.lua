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

local function logMoreRequestDetails(debugEntries)
	debugEntries["ServerUtcTime"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
	debugEntries["RequestIP"] = iHelpers.request.getUserHostAddress()
	debugEntries["RequestHttpHeader_Via"] = utils.toString(iHelpers.request.getHeader('via'))
	debugEntries["RequestHttpHeader_Forwarded"] = utils.toString(iHelpers.request.getHeader('forwarded'))
	debugEntries["RequestHttpHeader_XForwardedFor"] = utils.toString(iHelpers.request.getHeader('x-forwarded-for'))
	debugEntries["RequestHttpHeader_XForwardedHost"] = utils.toString(iHelpers.request.getHeader('x-forwarded-host'))
	debugEntries["RequestHttpHeader_XForwardedProto"] = utils.toString(iHelpers.request.getHeader('x-forwarded-proto'))
end

local function setDebugCookie(debugEntries)
	if(utils.tableLength(debugEntries) == 0) then
		return
	end

	local cookieValue = ""
	for key, value in pairs(debugEntries) do
		cookieValue = cookieValue .. (key .. "=" .. value .. "|")
	end
	cookieValue = cookieValue:sub(0, cookieValue:len()-1) -- remove trailing |
	iHelpers.response.setCookie(QUEUEIT_DEBUG_KEY, cookieValue, 0, nil)
end

local function generateTargetUrl(originalTargetUrl)
    if (isQueueAjaxCall()) then
		local headerValue = iHelpers.request.getHeader(QUEUEIT_AJAX_HEADER_KEY)
		return utils.urlDecode(headerValue)
	else
		return originalTargetUrl
	end
end

local function getRuntime()
	return _VERSION
end

local function resolveQueueRequestByLocalConfig(
	targetUrl, queueitToken, queueConfig,customerId, secretKey, debugEntries, isDebug)

	if (isDebug) then
		local queueConfigValue = "NULL"
		if (queueConfig ~= nil) then
			queueConfigValue = queueConfig:getString()
		end

		debugEntries["SdkVersion"] = userInQueueService.SDK_VERSION
		debugEntries["Connector"] = iHelpers.system.getConnectorName()
		debugEntries["Runtime"] = getRuntime()
		debugEntries["TargetUrl"] = targetUrl
		debugEntries["QueueitToken"] = queueitToken
		debugEntries["QueueConfig"] = queueConfigValue
		debugEntries["OriginalUrl"] = iHelpers.request.getAbsoluteUri()

		logMoreRequestDetails(debugEntries)
	end

	assert(utils.toString(customerId) ~= "", "customerId can not be nil or empty.")
	assert(utils.toString(secretKey) ~= "", "secretKey can not be nil or empty.")
	assert(queueConfig ~= nil, "queueConfig can not be nil.")
	assert(utils.toString(queueConfig.eventId) ~= "", "eventId from queueConfig can not be nil or empty.")
	assert(utils.toString(queueConfig.queueDomain) ~= "", "queueDomain from queueConfig can not be nil or empty.")
	assert(
		type(queueConfig.cookieValidityMinute) == "number"
		and queueConfig.cookieValidityMinute > 0, "cookieValidityMinute from queueConfig should be a number greater than 0.")
	assert(
		type(queueConfig.extendCookieValidity) == "boolean", "extendCookieValidity from queueConfig should be valid boolean.")

	local result = userInQueueService.validateQueueRequest(targetUrl, queueitToken, queueConfig, customerId, secretKey)
	result.isAjaxResult = isQueueAjaxCall()
	return result
end

local function cancelRequestByLocalConfig(
	targetUrl, queueitToken, cancelConfig, customerId, secretKey, debugEntries, isDebug)

	targetUrl = generateTargetUrl(targetUrl)

	if (isDebug) then
		local cancelConfigValue = "NULL"
		if (cancelConfig ~= nil) then
			cancelConfigValue = cancelConfig:getString()
		end

		debugEntries["SdkVersion"] = userInQueueService.SDK_VERSION
		debugEntries["Connector"] = iHelpers.system.getConnectorName()
		debugEntries["Runtime"] = getRuntime()
		debugEntries["TargetUrl"] = targetUrl
		debugEntries["QueueitToken"] = queueitToken
		debugEntries["OriginalUrl"] = iHelpers.request.getAbsoluteUri()
		debugEntries["CancelConfig"] = cancelConfigValue

		logMoreRequestDetails(debugEntries)
	end

	assert(utils.toString(targetUrl) ~= "", "targetUrl can not be nil or empty.")
	assert(utils.toString(customerId) ~= "", "customerId can not be nil or empty.")
	assert(utils.toString(secretKey) ~= "", "secretKey can not be nil or empty.")
	assert(cancelConfig ~= nil, "cancelConfig can not be nil.")
	assert(utils.toString(cancelConfig.eventId) ~= "", "eventId from cancelConfig can not be nil or empty.")
	assert(utils.toString(cancelConfig.queueDomain) ~= "", "queueDomain from cancelConfig can not be nil or empty.")

	local result = userInQueueService.validateCancelRequest(targetUrl, cancelConfig, customerId, secretKey)
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
	local debugEntries = { }
	local connectorDiagnostics = qitHelpers.ConnectorDiagnostics.verify(customerId, secretKey, queueitToken)

	if (connectorDiagnostics.hasError) then
		return connectorDiagnostics.validationResult;
	end
	local pcall_status, pcall_result = pcall(function()
		return cancelRequestByLocalConfig(
			targetUrl, queueitToken, cancelConfig, customerId, secretKey, debugEntries, connectorDiagnostics.isEnabled)
	end)

	if (pcall_status == false and connectorDiagnostics.isEnabled) then
		debugEntries["Exception"] = pcall_result
	end

	setDebugCookie(debugEntries)

	if (pcall_status) then
		return pcall_result
	else
		error(pcall_result)
	end
end

ku.validateRequestByIntegrationConfig = function(
	currentUrlWithoutQueueITToken, queueitToken, integrationConfigJson, customerId, secretKey)
	-- Private functions
	local function handleQueueAction(
		_currentUrlWithoutQueueITToken, _queueitToken, _customerIntegration,
		_customerId, _secretKey, _matchedConfig, _debugEntries, _isDebug)

		local eventConfig = models.QueueEventConfig.create()
		local targetUrl
		eventConfig.eventId = _matchedConfig["EventId"]
		eventConfig.queueDomain = _matchedConfig["QueueDomain"]
		eventConfig.layoutName = _matchedConfig["LayoutName"]
		eventConfig.culture = _matchedConfig["Culture"]
		eventConfig.cookieDomain = _matchedConfig["CookieDomain"]
		eventConfig.extendCookieValidity = _matchedConfig["ExtendCookieValidity"]
		eventConfig.cookieValidityMinute = _matchedConfig["CookieValidityMinute"]
		eventConfig.version = _customerIntegration["Version"]
		eventConfig.actionName = _matchedConfig["Name"]

		if (_matchedConfig["RedirectLogic"] == "ForcedTargetUrl"
			or _matchedConfig["RedirectLogic"] == "ForecedTargetUrl") then
			targetUrl = _matchedConfig["ForcedTargetUrl"]
		else
			if (_matchedConfig["RedirectLogic"] == "EventTargetUrl") then
				targetUrl = ""
			else
				targetUrl = generateTargetUrl(_currentUrlWithoutQueueITToken)
			end
		end

		return resolveQueueRequestByLocalConfig(
			targetUrl, _queueitToken, eventConfig, _customerId, _secretKey, _debugEntries, _isDebug)
	end

	local function handleCancelAction(
		_currentUrlWithoutQueueITToken, _queueitToken, _customerIntegration,
		_customerId, _secretKey, _matchedConfig, _debugEntries, _isDebug)

		local cancelEventConfig = models.CancelEventConfig.create()
		cancelEventConfig.eventId = _matchedConfig["EventId"]
		cancelEventConfig.queueDomain = _matchedConfig["QueueDomain"]
		cancelEventConfig.cookieDomain = _matchedConfig["CookieDomain"]
		cancelEventConfig.version = _customerIntegration["Version"]
		cancelEventConfig.actionName = _matchedConfig["Name"]

		return cancelRequestByLocalConfig(
			_currentUrlWithoutQueueITToken, _queueitToken, cancelEventConfig, _customerId, _secretKey, _debugEntries, _isDebug)
	end
	-- END Private functions

	local debugEntries = {}
	local connectorDiagnostics = qitHelpers.ConnectorDiagnostics.verify(customerId, secretKey, queueitToken)

	if (connectorDiagnostics.hasError) then
		return connectorDiagnostics.validationResult;
	end

	local customerIntegration = nil

	local pcall_status, pcall_result = pcall(function()

		if (connectorDiagnostics.isEnabled) then
			debugEntries["SdkVersion"] = userInQueueService.SDK_VERSION
			debugEntries["Connector"] =  iHelpers.system.getConnectorName()
			debugEntries["Runtime"] = getRuntime()

			debugEntries["PureUrl"] = currentUrlWithoutQueueITToken
			debugEntries["QueueitToken"] = queueitToken
			debugEntries["OriginalUrl"] = iHelpers.request.getAbsoluteUri()

			logMoreRequestDetails(debugEntries)
		end

		customerIntegration = iHelpers.json.parse(integrationConfigJson)

		if (connectorDiagnostics.isEnabled) then
			if (customerIntegration ~= nil and customerIntegration["Version"] ~= nil) then
				debugEntries["ConfigVersion"] = customerIntegration["Version"]
			else
				debugEntries["ConfigVersion"] = "NULL"
			end
		end

		if (utils.toString(currentUrlWithoutQueueITToken) == "") then
			error("currentUrlWithoutQueueITToken can not be nil or empty.")
		end

		if (utils.tableLength(customerIntegration) == 0 or customerIntegration == nil or
				customerIntegration["Version"] == nil) then
			error("integrationConfigJson was not valid json.")
		end

		local matchedConfig = integrationEvaluator.getMatchedIntegrationConfig(
			customerIntegration, currentUrlWithoutQueueITToken, iHelpers.request)

		if (connectorDiagnostics.isEnabled) then
			local matchedConfigValue = "NULL"
			if (matchedConfig ~= nil and matchedConfig["Name"] ~= nil) then
				matchedConfigValue = matchedConfig["Name"]
			end
			debugEntries["MatchedConfig"] = matchedConfigValue
		end

		if (matchedConfig == nil) then
			return models.RequestValidationResult.create(nil, nil, nil, nil, nil)
		end

		if (matchedConfig["ActionType"] == models.ActionTypes.QueueAction) then
			return handleQueueAction(currentUrlWithoutQueueITToken, queueitToken, customerIntegration,
						customerId, secretKey, matchedConfig, debugEntries, connectorDiagnostics.isEnabled)
		end

		if (matchedConfig["ActionType"] == models.ActionTypes.CancelAction) then
			return handleCancelAction(currentUrlWithoutQueueITToken, queueitToken, customerIntegration,
							customerId, secretKey, matchedConfig, debugEntries, connectorDiagnostics.isEnabled)
		end

		-- IgnoreAction
		local result = userInQueueService.getIgnoreActionResult(matchedConfig["Name"])
		result.isAjaxResult = isQueueAjaxCall()
		return result
	end)

	if (pcall_status == false and connectorDiagnostics.isEnabled) then
		debugEntries["Exception"] = pcall_result
	end

	setDebugCookie(debugEntries)

	if (pcall_status) then
		return pcall_result
	else
		error(pcall_result)
	end
end

ku.resolveQueueRequestByLocalConfig = function(targetUrl, queueitToken, queueConfig, customerId, secretKey)
	local debugEntries = {}
	local connectorDiagnostics = qitHelpers.ConnectorDiagnostics.verify(customerId, secretKey, queueitToken)

	if (connectorDiagnostics.hasError) then
		return connectorDiagnostics.validationResult;
	end
	local pcall_status, pcall_result = pcall(function()
		local generatedTargetUrl = generateTargetUrl(targetUrl)
		return resolveQueueRequestByLocalConfig(
			generatedTargetUrl, queueitToken, queueConfig, customerId, secretKey, debugEntries, connectorDiagnostics.isEnabled)
	end)

	if (pcall_status == false and connectorDiagnostics.isEnabled) then
		debugEntries["Exception"] = pcall_result
	end

	setDebugCookie(debugEntries)

	if (pcall_status) then
		return pcall_result
	else
		error(pcall_result)
	end
end

return ku