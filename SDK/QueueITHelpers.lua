local utils = require("Utils")
local models = require("Models")
local iHelpers = require("KnownUserImplementationHelpers")

local queueUrlParams = {
	extractQueueParams = function(queueitToken)

		if (utils.toString(queueitToken) == "") then
			return nil
		end
		local TimeStampKey = "ts"
		local ExtendableCookieKey = "ce"
		local CookieValidityMinutesKey = "cv"
		local HashCodeKey = "h"
		local EventIdKey = "e"
		local QueueIdKey = "q"
		local RedirectTypeKey = "rt"
		local KeyValueSeparatorChar = "_"
		local KeyValueSeparatorGroupChar = "~"

		-- Private functions
		local function updateResult(paramNameValueArr, result)
			if(paramNameValueArr[1] == TimeStampKey) then
				local tsn = tonumber(paramNameValueArr[2])
				if(tsn ~= nil) then
					result.timeStamp = tsn
				end
				return
			end
			if(paramNameValueArr[1] == CookieValidityMinutesKey) then
				local cvn = tonumber(paramNameValueArr[2])
				if(cvn ~= nil) then
					result.cookieValidityMinutes = cvn
				end
				return
			end
			if(paramNameValueArr[1] == EventIdKey) then
				result.eventId = paramNameValueArr[2]
				return
			end
			if(paramNameValueArr[1] == ExtendableCookieKey) then
				if(paramNameValueArr[2] ~= nil) then
					result.extendableCookie = string.lower(paramNameValueArr[2]) == "true"
				else
					result.extendableCookie = false
				end
				return
			end
			if(paramNameValueArr[1] == HashCodeKey) then
				result.hashCode = paramNameValueArr[2]
				return
			end
			if(paramNameValueArr[1] == QueueIdKey) then
				result.queueId = paramNameValueArr[2]
				return
			end
			if(paramNameValueArr[1] == RedirectTypeKey) then
				result.redirectType = paramNameValueArr[2]
				return
			end
		end
		-- END Private functions

		local result = {
			timeStamp = 0,
			eventId = "",
			hashCode = "",
			extendableCookie = false,
			cookieValidityMinutes = nil,
			queueITToken = queueitToken,
			queueITTokenWithoutHash = "",
			queueId = "",
			redirectType = ""
		}

		local paramsNameValueList = utils.explode(KeyValueSeparatorGroupChar, result.queueITToken)

		for _,pNameValue in pairs(paramsNameValueList) do
			local paramNameValueArr = utils.explode(KeyValueSeparatorChar, pNameValue)
			local c = utils.tableLength(paramNameValueArr)
			if (c == 2) then
				updateResult(paramNameValueArr, result)
			end
		end
		local replacingHash =
			KeyValueSeparatorGroupChar .. HashCodeKey ..
			KeyValueSeparatorChar .. utils.escapeMagicChars(result.hashCode)
		result.queueITTokenWithoutHash = result.queueITToken:gsub(replacingHash, "")
		return result
	end
}

local connectorDiagnostics = {
	verify = function(customerId, secretKey, queueitToken)
		local function setStateWithTokenError(_diagnostics, _customerId, _errorCode)
			_diagnostics.hasError = true
			_diagnostics.validationResult = models.RequestValidationResult.create(
				"ConnectorDiagnosticsRedirect",
				nil, nil,
				"https://" .. _customerId ..
				".api2.queue-it.net/" .. _customerId ..
				"/diagnostics/connector/error/?code=" .. _errorCode,
				nil, nil)
		end

		local function setStateWithSetupError(_diagnostics)
			_diagnostics.hasError = true
			_diagnostics.validationResult = models.RequestValidationResult.create(
				"ConnectorDiagnosticsRedirect",
				nil, nil,
				"https://api2.queue-it.net/diagnostics/connector/error/?code=setup",
				nil, nil)
		end

		local diagnostics = {
			isEnabled = false,
			hasError = false,
			validationResult = nil
		}

		local qParams = queueUrlParams.extractQueueParams(queueitToken)

		if (qParams == nil) then
			return diagnostics
		end

		if (qParams.redirectType == nil) then
			return diagnostics
		end

		if (string.lower(qParams.redirectType) ~= "debug") then
			return diagnostics
		end

		if (utils.toString(customerId) == "" or utils.toString(secretKey) == "") then
			setStateWithSetupError(diagnostics)
			return diagnostics
		end

		local calculatedHash = iHelpers.hash.hmac_sha256_encode(qParams.queueITTokenWithoutHash, secretKey)
		if (string.upper(calculatedHash) ~= string.upper(qParams.hashCode)) then
			setStateWithTokenError(diagnostics, customerId, "hash")
			return diagnostics
		end

		if (qParams.timeStamp < os.time()) then
			setStateWithTokenError(diagnostics, customerId, "timestamp")
			return diagnostics
		end

		diagnostics.isEnabled = true

		return diagnostics
	end
}

local qitHelpers = {
	QueueUrlParams = queueUrlParams,
	ConnectorDiagnostics = connectorDiagnostics
}

return qitHelpers