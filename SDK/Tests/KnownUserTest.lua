local models = require("Models")
local utils = require("Utils")
local knownUser = require("KnownUser")

-- Mocks
local iHelpers = require("KnownUserImplementationHelpers")
iHelpers.reset = function()
	iHelpers.system.getConnectorName = function()
		return "mock-connector"
	end
	iHelpers.request.getHeader = function(_)
		return nil
	end
	iHelpers.request.getAbsoluteUri = function()
		return nil
	end
	iHelpers.request.getUserHostAddress = function()
		return nil
	end
	iHelpers.response.setCookie = function(name, value, _, _)
		if(name=="queueitdebug") then
			iHelpers.response.debugCookieSet = value
		end
	end
	iHelpers.response.debugCookieSet = nil
end

local userInQueueServiceMock = require("UserInQueueService")
userInQueueServiceMock.validateQueueRequestResult = { }
userInQueueServiceMock.validateQueueRequestRaiseException = false
userInQueueServiceMock.validateQueueRequest = function(targetUrl, queueitToken, queueConfig, customerId, secretKey)
	userInQueueServiceMock.methodInvokations = {
		method="validateQueueRequest", targetUrl=targetUrl, queueitToken=queueitToken,
		queueConfig=queueConfig, customerId=customerId, secretKey=secretKey
	}
	if(userInQueueServiceMock.validateQueueRequestRaiseException) then
		assert(false,"exception")
	else
		return userInQueueServiceMock.validateQueueRequestResult
	end
end
userInQueueServiceMock.validateCancelRequestResult = { }
userInQueueServiceMock.validateCancelRequestRaiseException = false
userInQueueServiceMock.validateCancelRequest = function(targetUrl, cancelConfig, customerId, secretKey)
	userInQueueServiceMock.methodInvokations = {
		method="validateCancelRequest", targetUrl=targetUrl,
		cancelConfig=cancelConfig, customerId=customerId, secretKey=secretKey
	}
	if(userInQueueServiceMock.validateCancelRequestRaiseException) then
		assert(false,"exception")
	else
		return userInQueueServiceMock.validateCancelRequestResult
	end
end
userInQueueServiceMock.extendQueueCookieResult = { }
userInQueueServiceMock.extendQueueCookie = function(eventId, cookieValidityMinute, cookieDomain, secretKey)
    userInQueueServiceMock.methodInvokations = {
		method="extendQueueCookie", eventId=eventId, cookieValidityMinute=cookieValidityMinute,
		cookieDomain=cookieDomain, secretKey=secretKey
	}
    return userInQueueServiceMock.validateQueueRequestResult
end
userInQueueServiceMock.getIgnoreActionResult = function (actionName)
	userInQueueServiceMock.methodInvokations = { method="getIgnoreActionResult" }
	return models.RequestValidationResult.create("Ignore", nil, nil, nil, nil, actionName)
end

userInQueueServiceMock.reset = function()
	userInQueueServiceMock.methodInvokations = { }
	userInQueueServiceMock.validateQueueRequestResult = { }
	userInQueueServiceMock.validateCancelRequestResult = { }
	userInQueueServiceMock.extendQueueCookieResult = { }
	userInQueueServiceMock.validateCancelRequestRaiseException = false
	userInQueueServiceMock.validateQueueRequestRaiseException = false
end

local function resetAllMocks()
	iHelpers.reset()
	userInQueueServiceMock.reset()
end
-- END Mocks

local function generateHashDebugValidHash(secretKey, expiredToken)
	local ts = os.time() + 1000
	if (expiredToken) then
		ts = os.time() - 1000
	end
	local t = 'e_eventId' .. '~rt_debug' .. '~ts_' .. ts
	local h = iHelpers.hash.hmac_sha256_encode(t, secretKey)

	return t .. '~h_' .. h
end

local function KnownUserTest()

	local function test_cancelRequestByLocalConfig()
		resetAllMocks()

		userInQueueServiceMock.validateCancelRequestResult = models.RequestValidationResult.create(
			"Cancel", "eventid", "queueid", "http://q.queue-it.net", nil, "CancelAction")

		local cancelEventconfig = models.CancelEventConfig.create()
		cancelEventconfig.cookieDomain = "cookiedomain"
		cancelEventconfig.eventId = "eventid"
		cancelEventconfig.queueDomain = "queuedomain"
		cancelEventconfig.version = 1
		cancelEventconfig.actionName = "CancelAction"

		local result = knownUser.cancelRequestByLocalConfig(
			"url", "queueittoken", cancelEventconfig, "customerid", "secretkey")

		assert( userInQueueServiceMock.methodInvokations.method == "validateCancelRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "url" )
		assert( userInQueueServiceMock.methodInvokations.customerId == "customerid" )
		assert( userInQueueServiceMock.methodInvokations.secretKey == "secretkey" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["eventId"] == "eventid" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["queueDomain"] == "queuedomain" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["cookieDomain"] == "cookiedomain" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["version"] == 1 )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["actionName"] == cancelEventconfig.actionName )
		assert( result.isAjaxResult == false )
	end
	test_cancelRequestByLocalConfig()

	local function test_cancelRequestByLocalConfig_AjaxCall()
		resetAllMocks()

		userInQueueServiceMock.validateCancelRequestResult = models.RequestValidationResult.create(
			"Cancel", "eventid", "queueid", "http://q.queue-it.net", nil, "CancelAction")

		iHelpers.request.getHeader = function(name)
			if (name == "x-queueit-ajaxpageurl") then
				return "http%3a%2f%2furl"
			else
				return nil
			end
		end

		local cancelEventconfig = models.CancelEventConfig.create()
		cancelEventconfig.cookieDomain = "cookiedomain"
		cancelEventconfig.eventId = "eventid"
		cancelEventconfig.queueDomain = "queuedomain"
		cancelEventconfig.version = 1
		cancelEventconfig.actionName = "CancelAction"

		local result = knownUser.cancelRequestByLocalConfig(
			"url", "queueittoken", cancelEventconfig, "customerid", "secretkey")

		assert( userInQueueServiceMock.methodInvokations.method == "validateCancelRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "http://url" )
		assert( userInQueueServiceMock.methodInvokations.customerId == "customerid" )
		assert( userInQueueServiceMock.methodInvokations.secretKey == "secretkey" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["eventId"] == "eventid" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["queueDomain"] == "queuedomain" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["cookieDomain"] == "cookiedomain" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["version"] == 1 )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["actionName"] == cancelEventconfig.actionName )
		assert( result.isAjaxResult == true )
		assert( result:getAjaxRedirectUrl() == "http%3A%2F%2Fq.queue-it.net" )
	end
	test_cancelRequestByLocalConfig_AjaxCall()

	local function test_cancelRequestByLocalConfig_empty_eventId()
		resetAllMocks()

		local cancelconfig = models.CancelEventConfig.create()
		cancelconfig.cookieDomain = "cookieDomain"
		cancelconfig.queueDomain = "queueDomain"
		cancelconfig.version = 12

		local errorMsg
		local status = xpcall(
			function()
				knownUser.cancelRequestByLocalConfig(
					"targeturl", "queueittoken", cancelconfig, "customerid", "secretkey")
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( status == false )
		assert( utils.endsWith(errorMsg, "eventId from cancelConfig can not be nil or empty.") )
	end
	test_cancelRequestByLocalConfig_empty_eventId()

	local function test_cancelRequestByLocalConfig_empty_secreteKey()
		resetAllMocks()

		local cancelconfig = models.CancelEventConfig.create()
		cancelconfig.cookieDomain = "cookieDomain"
		cancelconfig.eventId = "eventId"
		cancelconfig.queueDomain = "queueDomain"
		cancelconfig.version = 12

		local errorMsg
		local status = xpcall(
			function()
				knownUser.cancelRequestByLocalConfig("targeturl", "queueittoken", cancelconfig, "customerid", nil)
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( status == false )
		assert( utils.endsWith(errorMsg, "secretKey can not be nil or empty.") )
	end
	test_cancelRequestByLocalConfig_empty_secreteKey()

	local function test_cancelRequestByLocalConfig_empty_queueDomain()
		resetAllMocks()

		local cancelconfig = models.CancelEventConfig.create()
		cancelconfig.cookieDomain = "cookieDomain"
		cancelconfig.eventId = "eventId"
		cancelconfig.version = 12

		local errorMsg
		local status = xpcall(
			function()
				knownUser.cancelRequestByLocalConfig(
					"targeturl", "queueittoken", cancelconfig, "customerid", "secretkey")
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( status == false )
		assert( utils.endsWith(errorMsg, "queueDomain from cancelConfig can not be nil or empty.") )
	end
	test_cancelRequestByLocalConfig_empty_queueDomain()

	local function test_cancelRequestByLocalConfig_empty_customerId()
		resetAllMocks()

		local cancelconfig = models.CancelEventConfig.create()
		cancelconfig.cookieDomain = "cookieDomain"
		cancelconfig.eventId = "eventId"
		cancelconfig.queueDomain = "queueDomain"
		cancelconfig.version = 12

		local errorMsg
		local status = xpcall(
			function()
				knownUser.cancelRequestByLocalConfig("targeturl", "queueittoken", cancelconfig, nil, "secretkey")
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( status == false )
		assert( utils.endsWith(errorMsg, "customerId can not be nil or empty.") )
	end
	test_cancelRequestByLocalConfig_empty_customerId()

	local function test_cancelRequestByLocalConfig_empty_targeturl()
	    resetAllMocks()

	    local cancelconfig = models.CancelEventConfig.create()
		cancelconfig.cookieDomain = "cookieDomain"
		cancelconfig.eventId = "eventId"
		cancelconfig.queueDomain = "queueDomain"
		cancelconfig.version = 12

		local errorMsg
		local status = xpcall(
			function()
				knownUser.cancelRequestByLocalConfig(nil, "queueittoken", cancelconfig, "customerId", "secretkey")
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( status == false )
		assert( utils.endsWith(errorMsg, "targetUrl can not be nil or empty.") )
	end
	test_cancelRequestByLocalConfig_empty_targeturl()

	local function test_extendQueueCookie_null_EventId()
	    resetAllMocks()

		local errorMsg
		local status = xpcall(
			function()
				knownUser.extendQueueCookie(nil, 10, "cookieDomain", "secretkey")
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( status == false )
		assert( utils.endsWith(errorMsg, "eventId can not be nil or empty.") )
	end
	test_extendQueueCookie_null_EventId()

	local function test_extendQueueCookie_null_SecretKey()
	  resetAllMocks()

	  local errorMsg
	  local status = xpcall(
		function()
			knownUser.extendQueueCookie("event1", 10, "cookieDomain", nil)
		end,
		function(err)
			errorMsg = err
		end
	  )

	  assert( status == false )
	  assert( utils.endsWith(errorMsg, "secretKey can not be nil or empty.") )
	end
	test_extendQueueCookie_null_SecretKey()

	local function test_extendQueueCookie_Invalid_CookieValidityMinute()
	  resetAllMocks()

	  local errorMsg
	  local status = xpcall(
		function()
			knownUser.extendQueueCookie("event1", "notnumber", "cookieDomain", "secretKey")
		end,
		function(err)
			errorMsg = err
		end
	  )

	  assert( status == false )
	  assert( utils.endsWith(errorMsg, "cookieValidityMinute should be a number greater than 0.") )
	end
	test_extendQueueCookie_Invalid_CookieValidityMinute()

	local function test_extendQueueCookie_Negative_CookieValidityMinute()
	  resetAllMocks()

	  local errorMsg
	  local status = xpcall(
		function()
			knownUser.extendQueueCookie("event1", -1, "cookieDomain", "secretKey")
		end,
		function(err)
			errorMsg = err
		end
	  )

	  assert( status == false )
	  assert( utils.endsWith(errorMsg, "cookieValidityMinute should be a number greater than 0.") )
	end
	test_extendQueueCookie_Negative_CookieValidityMinute()

	local function test_extendQueueCookie()
		resetAllMocks()

		knownUser.extendQueueCookie("eventid", 10, "cookieDomain", "secretkey")

		assert( userInQueueServiceMock.methodInvokations.method == "extendQueueCookie" )
		assert( userInQueueServiceMock.methodInvokations.eventId == "eventid" )
		assert( userInQueueServiceMock.methodInvokations.cookieValidityMinute == 10 )
		assert( userInQueueServiceMock.methodInvokations.cookieDomain == "cookieDomain" )
		assert( userInQueueServiceMock.methodInvokations.secretKey == "secretkey" )
	end
	test_extendQueueCookie()

	local function test_resolveQueueRequestByLocalConfig_empty_eventId()
		resetAllMocks()

		local eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		local errorMsg
		local status = xpcall(
			function()
				knownUser.resolveQueueRequestByLocalConfig(
					"targeturl", "queueIttoken", eventconfig, "customerid", "secretkey")
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( status == false )
		assert( utils.endsWith(errorMsg, "eventId from queueConfig can not be nil or empty.") )
	end
	test_resolveQueueRequestByLocalConfig_empty_eventId()

	local function test_resolveQueueRequestByLocalConfig_empty_secretKey()
		resetAllMocks()

		local eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		local errorMsg
		local status = xpcall(
			function()
				knownUser.resolveQueueRequestByLocalConfig("targeturl", "queueIttoken", eventconfig, "customerid", nil)
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( status == false )
		assert( utils.endsWith(errorMsg, "secretKey can not be nil or empty.") )
	end
	test_resolveQueueRequestByLocalConfig_empty_secretKey()

	local function test_resolveQueueRequestByLocalConfig_empty_queueDomain()
		resetAllMocks()

		local eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		local errorMsg
		local status = xpcall(
			function()
				knownUser.resolveQueueRequestByLocalConfig(
					"targeturl", "queueIttoken", eventconfig, "customerid", "secretkey")
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( status == false )
		assert( utils.endsWith(errorMsg, "queueDomain from queueConfig can not be nil or empty.") )
	end
	test_resolveQueueRequestByLocalConfig_empty_queueDomain()

	local function test_resolveQueueRequestByLocalConfig_empty_customerId()
		resetAllMocks()

		local eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		local errorMsg
		local status = xpcall(
			function()
				knownUser.resolveQueueRequestByLocalConfig("targeturl", "queueIttoken", eventconfig, nil, "secretkey")
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( status == false )
		assert( utils.endsWith(errorMsg, "customerId can not be nil or empty.") )
	end
	test_resolveQueueRequestByLocalConfig_empty_customerId()

	local function test_resolveQueueRequestByLocalConfig_Invalid_extendCookieValidity()
		resetAllMocks()

		local eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = nil
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		local errorMsg
		local status = xpcall(
			function()
				knownUser.resolveQueueRequestByLocalConfig(
					"targeturl", "queueIttoken", eventconfig, "customerId", "secretkey")
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( status == false )
		assert( utils.endsWith(errorMsg, "extendCookieValidity from queueConfig should be valid boolean.") )
	end
	test_resolveQueueRequestByLocalConfig_Invalid_extendCookieValidity()

	local function test_resolveQueueRequestByLocalConfig_Invalid_cookieValidityMinute()
		resetAllMocks()

		local eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = nil
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		local errorMsg
		local status = xpcall(
			function()
				knownUser.resolveQueueRequestByLocalConfig(
					"targeturl", "queueIttoken", eventconfig, "customerId", "secretkey")
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( status == false )
		assert( utils.endsWith(errorMsg, "extendCookieValidity from queueConfig should be valid boolean.") )
	end
	test_resolveQueueRequestByLocalConfig_Invalid_cookieValidityMinute()

	local function test_resolveQueueRequestByLocalConfig_zero_cookieValidityMinute()
		resetAllMocks()

		local eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = "test"
		eventconfig.version = 12

		local errorMsg
		local status = xpcall(
			function()
				knownUser.resolveQueueRequestByLocalConfig(
					"targeturl", "queueIttoken", eventconfig, "customerId", "secretkey")
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( status == false )
		assert( utils.endsWith(errorMsg, "cookieValidityMinute from queueConfig should be a number greater than 0.") )
	end
	test_resolveQueueRequestByLocalConfig_zero_cookieValidityMinute()

	local function test_resolveQueueRequestByLocalConfig()
		resetAllMocks()

		local eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12
		eventconfig.actionName = "QueueAction"

		local result = knownUser.resolveQueueRequestByLocalConfig(
			"targeturl", "queueIttoken", eventconfig, "customerid", "secretkey")

		assert( userInQueueServiceMock.methodInvokations.method == "validateQueueRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "targeturl" )
		assert( userInQueueServiceMock.methodInvokations.queueitToken == "queueIttoken" )
		assert( userInQueueServiceMock.methodInvokations.queueConfig == eventconfig )
		assert( userInQueueServiceMock.methodInvokations.customerId == "customerid" )
		assert( userInQueueServiceMock.methodInvokations.secretKey == "secretkey" )

		assert( result.isAjaxResult == false )
	end
	test_resolveQueueRequestByLocalConfig()

	local function test_resolveQueueRequestByLocalConfig_AjaxCall()
	    resetAllMocks()

		iHelpers.request.getHeader = function(name)
			if (name == "x-queueit-ajaxpageurl") then
				return "http%3a%2f%2furl"
			else
				return nil
			end
		end

		local eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12
		eventconfig.actionName = "QueueAction"

		userInQueueServiceMock.validateQueueRequestResult = models.RequestValidationResult.create(
			"Queue","eventid","","http://q.queue-it.net","", eventconfig.actionName );

		local result = knownUser.resolveQueueRequestByLocalConfig(
			"targeturl", "queueIttoken", eventconfig, "customerid", "secretkey")

		assert( userInQueueServiceMock.methodInvokations.method == "validateQueueRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "http://url" )
		assert( userInQueueServiceMock.methodInvokations.queueitToken == "queueIttoken" )
		assert( userInQueueServiceMock.methodInvokations.queueConfig == eventconfig )
		assert( userInQueueServiceMock.methodInvokations.customerId == "customerid" )
		assert( userInQueueServiceMock.methodInvokations.secretKey == "secretkey" )

		assert( result.isAjaxResult == true )
		assert( result:getAjaxRedirectUrl() == "http%3A%2F%2Fq.queue-it.net" )
		assert( result.actionName == eventconfig.actionName )
	end
	test_resolveQueueRequestByLocalConfig_AjaxCall()

	local function test_validateRequestByIntegrationConfig()
	  resetAllMocks()

		userInQueueServiceMock.validateQueueRequestResult = models.RequestValidationResult.create(
			"Queue", "eventid", "", "http://q.queue-it.net", "", "event1action")

		iHelpers.request.getHeader = function(name)
			if (name == "user-agent") then
				return "googlebot"
			else
				return nil
			end
		end

        local integrationConfigString =
		[[
            {
              "Description": "test",
              "Integrations": [
                {
                  "Name": "event1action",
                  "ActionType": "Queue",
                  "EventId": "event1",
                  "CookieDomain": ".test.com",
                  "LayoutName": "Christmas Layout by Queue-it",
                  "Culture": "",
                  "ExtendCookieValidity": true,
                  "CookieValidityMinute": 20,
                  "Triggers": [
                    {
                      "TriggerParts": [
                        {
							"Operator": "Contains",
							"ValueToCompare": "event1",
							"UrlPart": "PageUrl",
							"ValidatorType": "UrlValidator",
							"IsNegative": false,
							"IsIgnoreCase": true
                        },
                        {
							"Operator": "Contains",
							"ValueToCompare": "googlebot",
							"ValidatorType": "UserAgentValidator",
							"IsNegative": false,
							"IsIgnoreCase": false
                        }
                      ],
                      "LogicalOperator": "And"
                    }
                  ],
                  "QueueDomain": "knownusertest.queue-it.net",
                  "RedirectLogic": "AllowTParameter",
                  "ForcedTargetUrl": ""
                }
              ],
              "CustomerId": "knownusertest",
              "AccountId": "knownusertest",
              "Version": 3,
              "PublishDate": "2017-05-15T21:39:12.0076806Z",
              "ConfigDataVersion": "1.0.0.1"
            }
		]]

		local result =  knownUser.validateRequestByIntegrationConfig(
			"http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")

		assert( userInQueueServiceMock.methodInvokations.method == "validateQueueRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "http://test.com?event1=true" )
		assert( userInQueueServiceMock.methodInvokations.queueitToken == "queueIttoken" )
		assert( userInQueueServiceMock.methodInvokations.queueConfig["queueDomain"] == "knownusertest.queue-it.net" )
		assert( userInQueueServiceMock.methodInvokations.queueConfig["eventId"] == "event1" )
        assert( userInQueueServiceMock.methodInvokations.queueConfig["culture"] == "" )
        assert( userInQueueServiceMock.methodInvokations.queueConfig["layoutName"] == "Christmas Layout by Queue-it" )
        assert( userInQueueServiceMock.methodInvokations.queueConfig["extendCookieValidity"] )
        assert( userInQueueServiceMock.methodInvokations.queueConfig["cookieValidityMinute"] == 20 )
        assert( userInQueueServiceMock.methodInvokations.queueConfig["cookieDomain"] == ".test.com" )
        assert( userInQueueServiceMock.methodInvokations.queueConfig["version"] == 3 )
		assert( userInQueueServiceMock.methodInvokations.customerId == "customerid" )
		assert( userInQueueServiceMock.methodInvokations.secretKey == "secretkey" )
		assert( result.isAjaxResult == false )
		assert( userInQueueServiceMock.methodInvokations.queueConfig["actionName"] ==  "event1action")
	end
	test_validateRequestByIntegrationConfig()

	local function test_validateRequestByIntegrationConfig_AjaxCall()
	end
	test_validateRequestByIntegrationConfig_AjaxCall()

	local function test_validateRequestByIntegrationConfig_NotMatch()
		resetAllMocks()

		local integrationConfigString =
		[[
			{
			  "Description": "test",
			  "Integrations": [
			  ],
			  "CustomerId": "knownusertest",
			  "AccountId": "knownusertest",
			  "Version": 3,
			  "PublishDate": "2017-05-15T21:39:12.0076806Z",
			  "ConfigDataVersion": "1.0.0.1"
			}
		]]

		local result = knownUser.validateRequestByIntegrationConfig(
			"http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")

		assert( next(userInQueueServiceMock.methodInvokations) == nil )
        assert( result:doRedirect() == false )
	end
	test_validateRequestByIntegrationConfig_NotMatch()

	local function test_validateRequestByIntegrationConfig_ForcedTargeturl()
		resetAllMocks()

		local integrationConfigString =
		[[
            {
              "Description": "test",
              "Integrations": [
                {
                  "Name": "event1action",
                  "ActionType": "Queue",
                  "EventId": "event1",
                  "CookieDomain": ".test.com",
                  "LayoutName": "Christmas Layout by Queue-it",
                  "Culture": "",
                  "ExtendCookieValidity": true,
                  "CookieValidityMinute": 20,
                  "Triggers": [
                    {
                      "TriggerParts": [
                        {
							"Operator": "Contains",
							"ValueToCompare": "event1",
							"UrlPart": "PageUrl",
							"ValidatorType": "UrlValidator",
							"IsNegative": false,
							"IsIgnoreCase": true
                        }
                      ],
                      "LogicalOperator": "And"
                    }
                  ],
                  "QueueDomain": "knownusertest.queue-it.net",
                  "RedirectLogic": "ForcedTargetUrl",
                  "ForcedTargetUrl": "http://test.com"
                }
              ],
              "CustomerId": "knownusertest",
              "AccountId": "knownusertest",
              "Version": 3,
              "PublishDate": "2017-05-15T21:39:12.0076806Z",
              "ConfigDataVersion": "1.0.0.1"
            }
		]]

		knownUser.validateRequestByIntegrationConfig(
			"http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")

		assert( userInQueueServiceMock.methodInvokations.method == "validateQueueRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "http://test.com" )
		assert( userInQueueServiceMock.methodInvokations.queueConfig["actionName"] ==  "event1action")
	end
	test_validateRequestByIntegrationConfig_ForcedTargeturl()

	local function test_validateRequestByIntegrationConfig_ForcedTargeturl_AjaxCall()
		resetAllMocks()

		userInQueueServiceMock.validateQueueRequestResult = models.RequestValidationResult.create(
			"Queue", "eventid", "", "http://q.queue-it.net", "")

		iHelpers.request.getHeader = function(name)
			if (name == "x-queueit-ajaxpageurl") then
				return "http%3a%2f%2furl"
			else
				return nil
			end
		end

		local integrationConfigString =
		[[
            {
              "Description": "test",
              "Integrations": [
                {
                  "Name": "event1action",
                  "ActionType": "Queue",
                  "EventId": "event1",
                  "CookieDomain": ".test.com",
                  "LayoutName": "Christmas Layout by Queue-it",
                  "Culture": "",
                  "ExtendCookieValidity": true,
                  "CookieValidityMinute": 20,
                  "Triggers": [
                    {
                      "TriggerParts": [
                        {
							"Operator": "Contains",
							"ValueToCompare": "event1",
							"UrlPart": "PageUrl",
							"ValidatorType": "UrlValidator",
							"IsNegative": false,
							"IsIgnoreCase": true
                        }
                      ],
                      "LogicalOperator": "And"
                    }
                  ],
                  "QueueDomain": "knownusertest.queue-it.net",
                  "RedirectLogic": "ForcedTargetUrl",
                  "ForcedTargetUrl": "http://test.com"
                }
              ],
              "CustomerId": "knownusertest",
              "AccountId": "knownusertest",
              "Version": 3,
              "PublishDate": "2017-05-15T21:39:12.0076806Z",
              "ConfigDataVersion": "1.0.0.1"
            }
		]]

		local result = knownUser.validateRequestByIntegrationConfig(
			"http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")

		assert( userInQueueServiceMock.methodInvokations.method == "validateQueueRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "http://test.com" )
		assert( userInQueueServiceMock.methodInvokations.queueConfig["actionName"] ==  "event1action")
		assert( result.isAjaxResult == true )
		assert( result:getAjaxRedirectUrl() == "http%3A%2F%2Fq.queue-it.net" )
	end
	test_validateRequestByIntegrationConfig_ForcedTargeturl_AjaxCall()

	local function test_validateRequestByIntegrationConfig_EventTargetUrl()
		resetAllMocks()

		local integrationConfigString =
		[[
            {
              "Description": "test",
              "Integrations": [
                {
                  "Name": "event1action",
                  "ActionType": "Queue",
                  "EventId": "event1",
                  "CookieDomain": ".test.com",
                  "LayoutName": "Christmas Layout by Queue-it",
                  "Culture": "",
                  "ExtendCookieValidity": true,
                  "CookieValidityMinute": 20,
                  "Triggers": [
                    {
                      "TriggerParts": [
                        {
							"Operator": "Contains",
							"ValueToCompare": "event1",
							"UrlPart": "PageUrl",
							"ValidatorType": "UrlValidator",
							"IsNegative": false,
							"IsIgnoreCase": true
                        }
                      ],
                      "LogicalOperator": "And"
                    }
                  ],
                  "QueueDomain": "knownusertest.queue-it.net",
                  "RedirectLogic": "EventTargetUrl",
                  "ForcedTargetUrl": "http://test.com"
                }
              ],
              "CustomerId": "knownusertest",
              "AccountId": "knownusertest",
              "Version": 3,
              "PublishDate": "2017-05-15T21:39:12.0076806Z",
              "ConfigDataVersion": "1.0.0.1"
            }
		]]

		knownUser.validateRequestByIntegrationConfig(
			"http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")

		assert( userInQueueServiceMock.methodInvokations.method == "validateQueueRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "" )
		assert( userInQueueServiceMock.methodInvokations.queueConfig["actionName"] ==  "event1action")
	end
	test_validateRequestByIntegrationConfig_EventTargetUrl()

	local function test_validateRequestByIntegrationConfig_EventTargetUrl_AjaxCall()
		resetAllMocks()

		iHelpers.request.getHeader = function(name)
			if (name == "x-queueit-ajaxpageurl") then
				return "http%3a%2f%2furl"
			else
				return nil
			end
		end

		local integrationConfigString =
		[[
            {
              "Description": "test",
              "Integrations": [
                {
                  "Name": "event1action",
                  "ActionType": "Queue",
                  "EventId": "event1",
                  "CookieDomain": ".test.com",
                  "LayoutName": "Christmas Layout by Queue-it",
                  "Culture": "",
                  "ExtendCookieValidity": true,
                  "CookieValidityMinute": 20,
                  "Triggers": [
                    {
                      "TriggerParts": [
                        {
							"Operator": "Contains",
							"ValueToCompare": "event1",
							"UrlPart": "PageUrl",
							"ValidatorType": "UrlValidator",
							"IsNegative": false,
							"IsIgnoreCase": true
                        }
                      ],
                      "LogicalOperator": "And"
                    }
                  ],
                  "QueueDomain": "knownusertest.queue-it.net",
                  "RedirectLogic": "EventTargetUrl",
                  "ForcedTargetUrl": "http://test.com"
                }
              ],
              "CustomerId": "knownusertest",
              "AccountId": "knownusertest",
              "Version": 3,
              "PublishDate": "2017-05-15T21:39:12.0076806Z",
              "ConfigDataVersion": "1.0.0.1"
            }
		]]

		local result = knownUser.validateRequestByIntegrationConfig(
			"http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")

		assert( userInQueueServiceMock.methodInvokations.method == "validateQueueRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "" )
		assert( userInQueueServiceMock.methodInvokations.queueConfig["actionName"] ==  "event1action")
		assert( result.isAjaxResult == true )
	end
	test_validateRequestByIntegrationConfig_EventTargetUrl_AjaxCall()

	local function test_validateRequestByIntegrationConfig_CancelAction()
		resetAllMocks()

		local integrationConfigString =
		[[
            {
              "Description": "test",
              "Integrations": [
                {
                  "Name": "event1action",
                  "EventId": "event1",
                  "CookieDomain": ".test.com",
                  "ActionType": "Cancel",
                  "Triggers": [
                    {
                      "TriggerParts": [
                        {
							"Operator": "Contains",
							"ValueToCompare": "event1",
							"UrlPart": "PageUrl",
							"ValidatorType": "UrlValidator",
							"IsNegative": false,
							"IsIgnoreCase": true
                        }
                      ],
                      "LogicalOperator": "And"
                    }
                  ],
                  "QueueDomain": "knownusertest.queue-it.net"
                }
              ],
              "CustomerId": "knownusertest",
              "AccountId": "knownusertest",
              "Version": 3,
              "PublishDate": "2017-05-15T21:39:12.0076806Z",
              "ConfigDataVersion": "1.0.0.1"
            }
		]]

		userInQueueServiceMock.validateCancelRequestResult = models.RequestValidationResult.create(
			"Cancel", "event1", "queueid", "redirectUrl", nil, "event1action")

		local result = knownUser.validateRequestByIntegrationConfig(
			"http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")
		assert( result.redirectUrl == "redirectUrl" )

		assert( userInQueueServiceMock.methodInvokations.method == "validateCancelRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "http://test.com?event1=true" )
		assert( userInQueueServiceMock.methodInvokations.customerId == "customerid" )
		assert( userInQueueServiceMock.methodInvokations.secretKey == "secretkey" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["eventId"] == "event1" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["queueDomain"] == "knownusertest.queue-it.net" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["cookieDomain"] == ".test.com" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["version"] == 3 )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["actionName"] ==  "event1action")
		assert( result.isAjaxResult == false )
	end
	test_validateRequestByIntegrationConfig_CancelAction()

	local function test_validateRequestByIntegrationConfig_CancelAction_AjaxCall()
		resetAllMocks()

		iHelpers.request.getHeader = function(name)
			if (name == "x-queueit-ajaxpageurl") then
				return "http%3a%2f%2furl"
			else
				return nil
			end
		end

		local integrationConfigString =
		[[
            {
              "Description": "test",
              "Integrations": [
                {
                  "Name": "event1action",
                  "EventId": "event1",
                  "CookieDomain": ".test.com",
                  "ActionType": "Cancel",
                  "Triggers": [
                    {
                      "TriggerParts": [
                        {
							"Operator": "Contains",
							"ValueToCompare": "event1",
							"UrlPart": "PageUrl",
							"ValidatorType": "UrlValidator",
							"IsNegative": false,
							"IsIgnoreCase": true
                        }
                      ],
                      "LogicalOperator": "And"
                    }
                  ],
                  "QueueDomain": "knownusertest.queue-it.net"
                }
              ],
              "CustomerId": "knownusertest",
              "AccountId": "knownusertest",
              "Version": 3,
              "PublishDate": "2017-05-15T21:39:12.0076806Z",
              "ConfigDataVersion": "1.0.0.1"
            }
		]]

		userInQueueServiceMock.validateCancelRequestResult = models.RequestValidationResult.create(
			"Cancel", "event1", "queueid", "redirectUrl", nil)

		local result = knownUser.validateRequestByIntegrationConfig(
			"http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")
		assert( result.redirectUrl == "redirectUrl" )

		assert( userInQueueServiceMock.methodInvokations.method == "validateCancelRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "http://url" )
		assert( userInQueueServiceMock.methodInvokations.customerId == "customerid" )
		assert( userInQueueServiceMock.methodInvokations.secretKey == "secretkey" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["eventId"] == "event1" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["queueDomain"] == "knownusertest.queue-it.net" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["cookieDomain"] == ".test.com" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["version"] == 3 )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["actionName"] ==  "event1action")
		assert( result.isAjaxResult == true )
	end
	test_validateRequestByIntegrationConfig_CancelAction_AjaxCall()

	local function test_validateRequestByIntegrationConfig_IgnoreAction()
		resetAllMocks()

		local integrationConfigString =
		[[
            {
              "Description": "test",
              "Integrations": [
                {
                  "Name": "event1action",
                  "EventId": "event1",
                  "CookieDomain": ".test.com",
                  "ActionType": "Ignore",
                  "Triggers": [
                    {
                      "TriggerParts": [
                        {
							"Operator": "Contains",
							"ValueToCompare": "event1",
							"UrlPart": "PageUrl",
							"ValidatorType": "UrlValidator",
							"IsNegative": false,
							"IsIgnoreCase": true
                        }
                      ],
                      "LogicalOperator": "And"
                    }
                  ],
                  "QueueDomain": "knownusertest.queue-it.net"
                }
              ],
              "CustomerId": "knownusertest",
              "AccountId": "knownusertest",
              "Version": 3,
              "PublishDate": "2017-05-15T21:39:12.0076806Z",
              "ConfigDataVersion": "1.0.0.1"
            }
		]]

		local result = knownUser.validateRequestByIntegrationConfig(
			"http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")
		assert( userInQueueServiceMock.methodInvokations.method == "getIgnoreActionResult" )
		assert( result.actionType == "Ignore" )
		assert( result.isAjaxResult == false )
		assert( result.actionName ==  "event1action")
	end
	test_validateRequestByIntegrationConfig_IgnoreAction()

	local function test_validateRequestByIntegrationConfig_IgnoreAction_AjaxCall()
		resetAllMocks()

		iHelpers.request.getHeader = function(name)
			if (name == "x-queueit-ajaxpageurl") then
				return "http%3a%2f%2furl"
			else
				return nil
			end
		end

		local integrationConfigString =
		[[
            {
              "Description": "test",
              "Integrations": [
                {
                  "Name": "event1action",
                  "EventId": "event1",
                  "CookieDomain": ".test.com",
                  "ActionType": "Ignore",
                  "Triggers": [
                    {
                      "TriggerParts": [
                        {
							"Operator": "Contains",
							"ValueToCompare": "event1",
							"UrlPart": "PageUrl",
							"ValidatorType": "UrlValidator",
							"IsNegative": false,
							"IsIgnoreCase": true
                        }
                      ],
                      "LogicalOperator": "And"
                    }
                  ],
                  "QueueDomain": "knownusertest.queue-it.net"
                }
              ],
              "CustomerId": "knownusertest",
              "AccountId": "knownusertest",
              "Version": 3,
              "PublishDate": "2017-05-15T21:39:12.0076806Z",
              "ConfigDataVersion": "1.0.0.1"
            }
		]]

		local result = knownUser.validateRequestByIntegrationConfig(
			"http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")
		assert( userInQueueServiceMock.methodInvokations.method == "getIgnoreActionResult" )
		assert( result.actionType == "Ignore" )
		assert( result.isAjaxResult == true )
		assert( result.actionName ==  "event1action")
	end
	test_validateRequestByIntegrationConfig_IgnoreAction_AjaxCall()

	local function test_validateRequestByIntegrationConfig_debug()
		resetAllMocks()

		iHelpers.request.getHeader = function(name)
			if(name == "via") then return "v" end
			if(name == "forwarded") then return "f" end
			if(name == "x-forwarded-for") then return "xff" end
			if(name == "x-forwarded-host") then return "xfh" end
			if(name == "x-forwarded-proto") then return "xfp" end
			return nil
		end
		iHelpers.request.getAbsoluteUri = function() return "OriginalURL" end
		iHelpers.request.getUserHostAddress = function() return "userIP" end

		local integrationConfigString =
		[[
            {
              "Description": "test",
              "Integrations": [
                {
                  "Name": "event1action",
                  "EventId": "event1",
                  "CookieDomain": ".test.com",
                  "ActionType": "Cancel",
                  "Triggers": [
                    {
                      "TriggerParts": [
                        {
							"Operator": "Contains",
							"ValueToCompare": "event1",
							"UrlPart": "PageUrl",
							"ValidatorType": "UrlValidator",
							"IsNegative": false,
							"IsIgnoreCase": true
                        }
                      ],
                      "LogicalOperator": "And"
                    }
                  ],
                  "QueueDomain": "knownusertest.queue-it.net"
                }
              ],
              "CustomerId": "knownusertest",
              "AccountId": "knownusertest",
              "Version": 3,
              "PublishDate": "2017-05-15T21:39:12.0076806Z",
              "ConfigDataVersion": "1.0.0.1"
            }
		]]

		local token = generateHashDebugValidHash("secretkey")
		local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
		local url = "http://test.com?event1=true&queueittoken=" .. generateHashDebugValidHash("secretkey")
		knownUser.validateRequestByIntegrationConfig(url, token, integrationConfigString, "customerid", "secretkey")

		local expectedCookie =
			"|SdkVersion=" .. userInQueueServiceMock.SDK_VERSION ..
			"|Connector=mock-connector" ..
			"|Runtime=" .. _VERSION ..
			"|RequestHttpHeader_XForwardedFor=xff" ..
			"|PureUrl=http://test.com?event1=true&queueittoken=" .. token ..
			"|TargetUrl=http://test.com?event1=true&queueittoken=" .. token ..
			"|RequestHttpHeader_Forwarded=f" ..
			"|OriginalUrl=OriginalURL" ..
			"|RequestHttpHeader_XForwardedHost=xfh" ..
			"|RequestIP=userIP" ..
			"|RequestHttpHeader_Via=v" ..
			"|MatchedConfig=event1action" ..
			"|ConfigVersion=3" ..
			"|RequestHttpHeader_XForwardedProto=xfp" ..
			"|ServerUtcTime=" .. timestamp ..
			"|QueueitToken=" .. token ..
			"|CancelConfig=EventId:event1&Version:3" ..
			"&QueueDomain:knownusertest.queue-it.net&CookieDomain:.test.com&ActionName:event1action"

		local cookieArray = utils.explode("|", iHelpers.response.debugCookieSet )
		for _, value in pairs(cookieArray) do
			assert(utils:contains(expectedCookie, value), value .. " not found in: " .. expectedCookie)
		end
	end
	test_validateRequestByIntegrationConfig_debug()

	local function test_validateRequestByIntegrationConfig_debug_withoutmatch()
		resetAllMocks()

		iHelpers.request.getHeader = function(name)
			if(name == "via") then return "v" end
			if(name == "forwarded") then return "f" end
			if(name == "x-forwarded-for") then return "xff" end
			if(name == "x-forwarded-host") then return "xfh" end
			if(name == "x-forwarded-proto") then return "xfp" end
			return nil
		end
		iHelpers.request.getAbsoluteUri = function() return "OriginalURL" end
		iHelpers.request.getUserHostAddress = function() return "userIP" end

		local integrationConfigString =
		[[
            {
              "Description": "test",
              "Integrations": [
                {
                  "Name": "event1action",
                  "EventId": "event1",
                  "CookieDomain": ".test.com",
                  "ActionType": "Cancel",
                  "Triggers": [
                    {
                      "TriggerParts": [
                        {
							"Operator": "Contains",
							"ValueToCompare": "notmatch",
							"UrlPart": "PageUrl",
							"ValidatorType": "UrlValidator",
							"IsNegative": false,
							"IsIgnoreCase": true
                        }
                      ],
                      "LogicalOperator": "And"
                    }
                  ],
                  "QueueDomain": "knownusertest.queue-it.net"
                }
              ],
              "CustomerId": "knownusertest",
              "AccountId": "knownusertest",
              "Version": 3,
              "PublishDate": "2017-05-15T21:39:12.0076806Z",
              "ConfigDataVersion": "1.0.0.1"
            }
		]]

		local token = generateHashDebugValidHash("secretkey")
		local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
		local url = "http://test.com?event1=true&queueittoken=" .. token

		knownUser.validateRequestByIntegrationConfig(url, token, integrationConfigString, "customerid", "secretkey")

		local expectedCookie =
			"|SdkVersion=" .. userInQueueServiceMock.SDK_VERSION ..
			"|Connector=mock-connector" ..
			"|Runtime=" .. _VERSION ..
			"|MatchedConfig=NULL" ..
			"|ConfigVersion=3" ..
			"|PureUrl=http://test.com?event1=true&queueittoken=" .. token ..
			"|ServerUtcTime=" .. timestamp ..
			"|RequestHttpHeader_XForwardedProto=xfp" ..
			"|RequestHttpHeader_Via=v" ..
			"|RequestHttpHeader_XForwardedHost=xfh" ..
			"|OriginalUrl=OriginalURL" ..
			"|RequestHttpHeader_XForwardedFor=xff" ..
			"|RequestHttpHeader_Forwarded=f" ..
			"|RequestIP=userIP" ..
			"|QueueitToken=" .. token

		local cookieArray = utils.explode("|", iHelpers.response.debugCookieSet )
		for _, value in pairs(cookieArray) do
			assert( utils:contains(expectedCookie, value))
		end
	end
	test_validateRequestByIntegrationConfig_debug_withoutmatch()

	local function test_validateRequestByIntegrationConfig_debug_invalid_config_json()
		resetAllMocks()

		iHelpers.request.getHeader = function(name)
			if(name == "via") then return "v" end
			if(name == "forwarded") then return "f" end
			if(name == "x-forwarded-for") then return "xff" end
			if(name == "x-forwarded-host") then return "xfh" end
			if(name == "x-forwarded-proto") then return "xfp" end
			return nil
		end
		iHelpers.request.getAbsoluteUri = function() return "OriginalURL" end
		iHelpers.request.getUserHostAddress = function() return "userIP" end

		local integrationConfigJson = "{}"
		local token = generateHashDebugValidHash("secretkey")
		local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
		local url = "http://test.com?event1=true&queueittoken=" .. generateHashDebugValidHash("secretkey")

		local errorMsg = "unspecified"
		xpcall(
			function()
				knownUser.validateRequestByIntegrationConfig(
					url, token, integrationConfigJson, "customerid", "secretkey")
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( utils.endsWith(errorMsg, "integrationConfigJson was not valid json.") )

		local expectedCookie =
			"|SdkVersion=" .. userInQueueServiceMock.SDK_VERSION ..
			"|Connector=mock-connector" ..
			"|Runtime=" .. _VERSION ..
			"|RequestHttpHeader_XForwardedFor=xff" ..
			"|PureUrl=http://test.com?event1=true&queueittoken=" .. token ..
			"|RequestHttpHeader_Forwarded=f" ..
			"|OriginalUrl=OriginalURL" ..
			"|RequestHttpHeader_XForwardedHost=xfh" ..
			"|RequestIP=userIP" ..
			"|RequestHttpHeader_Via=v" ..
			"|ConfigVersion=NULL" ..
			"|integrationConfigJson was not valid json." ..
			"|RequestHttpHeader_XForwardedProto=xfp" ..
			"|ServerUtcTime=" .. timestamp ..
			"|QueueitToken=" .. token

		local cookieArray = utils.explode("|",  expectedCookie)
		for _, value in pairs(cookieArray) do
			assert( utils:contains(iHelpers.response.debugCookieSet, value))
		end
	end
	test_validateRequestByIntegrationConfig_debug_invalid_config_json()

	local function test_validateRequestByIntegrationConfig_debug_missing_customerid()
		resetAllMocks()

		local integrationConfigString = [[{}]]
		local token = generateHashDebugValidHash("secretkey")

		local result = knownUser.validateRequestByIntegrationConfig(
			"http://test.com?event1=true", token, integrationConfigString, nil, "secretkey")

		assert( result.redirectUrl == "https://api2.queue-it.net/diagnostics/connector/error/?code=setup" )
		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_validateRequestByIntegrationConfig_debug_missing_customerid()

	local function test_validateRequestByIntegrationConfig_debug_missing_secretkey()
		resetAllMocks()

		local integrationConfigString = [[{}]]
		local token = generateHashDebugValidHash("secretkey")

		local result = knownUser.validateRequestByIntegrationConfig(
			"http://test.com?event1=true", token, integrationConfigString, "customerid", nil)

		assert( result.redirectUrl == "https://api2.queue-it.net/diagnostics/connector/error/?code=setup" )
		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_validateRequestByIntegrationConfig_debug_missing_secretkey()

	local function test_validateRequestByIntegrationConfig_debug_expiredtoken()
		resetAllMocks()

		local integrationConfigString = [[{}]]
		local invalidDebugToken = generateHashDebugValidHash("secretkey", true)

		local result = knownUser.validateRequestByIntegrationConfig(
			"http://test.com?event1=true", invalidDebugToken, integrationConfigString, "customerid", "secretkey")

		assert( result.redirectUrl ==
			"https://customerid.api2.queue-it.net/customerid/diagnostics/connector/error/?code=timestamp" )
		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_validateRequestByIntegrationConfig_debug_expiredtoken()

	local function test_validateRequestByIntegrationConfig_debug_modifiedtoken()
		resetAllMocks()

		local integrationConfigString = [[{}]]
		local invalidDebugToken = generateHashDebugValidHash("secretkey") .. "invalid-hash"

		local result = knownUser.validateRequestByIntegrationConfig(
			"http://test.com?event1=true", invalidDebugToken, integrationConfigString, "customerid", "secretkey")

		assert( result.redirectUrl ==
			"https://customerid.api2.queue-it.net/customerid/diagnostics/connector/error/?code=hash" )
		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_validateRequestByIntegrationConfig_debug_modifiedtoken()

	local function test_validateRequestByIntegrationConfig__NoDebugToken_Exception_NoCookie()
		resetAllMocks()

		local integrationConfigString =
		[[
            {
              "Description": "test",
              "Integrations": [
                {
                  "Name": "event1action",
                  "EventId": "event1",
                  "CookieDomain": ".test.com",
                  "ActionType": "Cancel",
                  "Triggers": [
                    {
                      "TriggerParts": [
                        {
							"Operator": "Contains",
							"ValueToCompare": "event1",
							"UrlPart": "PageUrl",
							"ValidatorType": "UrlValidator",
							"IsNegative": false,
							"IsIgnoreCase": true
                        }
                      ],
                      "LogicalOperator": "And"
                    }
                  ],
                  "QueueDomain": "knownusertest.queue-it.net"
                }
              ],
              "CustomerId": "knownusertest",
              "AccountId": "knownusertest",
              "Version": 3,
              "PublishDate": "2017-05-15T21:39:12.0076806Z",
              "ConfigDataVersion": "1.0.0.1"
            }
		]]

		userInQueueServiceMock.validateCancelRequestRaiseException = true

		pcall(function()
			knownUser.validateRequestByIntegrationConfig(
				"http://test.com?event1=true", "queueitToken", integrationConfigString, "customerId", "secretKey")
		end)

		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_validateRequestByIntegrationConfig__NoDebugToken_Exception_NoCookie()

	local function test_resolveQueueRequestByLocalConfig_debug()
		resetAllMocks()

		iHelpers.request.getHeader = function(name)
			if(name == "via") then return "v" end
			if(name == "forwarded") then return "f" end
			if(name == "x-forwarded-for") then return "xff" end
			if(name == "x-forwarded-host") then return "xfh" end
			if(name == "x-forwarded-proto") then return "xfp" end
			return nil
		end
		iHelpers.request.getAbsoluteUri = function() return "OriginalURL" end
		iHelpers.request.getUserHostAddress = function() return "userIP" end

		local eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12
		eventconfig.actionName = "event1action"

		local token = generateHashDebugValidHash("secretkey")
		local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
		knownUser.resolveQueueRequestByLocalConfig("targeturl", token, eventconfig, "customerid", "secretkey")

		local expectedCookie =
			"|SdkVersion=" .. userInQueueServiceMock.SDK_VERSION ..
			"|Connector=mock-connector" ..
			"|Runtime=" .. _VERSION ..
			"|RequestHttpHeader_Forwarded=f" ..
			"|ServerUtcTime=" .. timestamp ..
			"|RequestHttpHeader_XForwardedProto=xfp" ..
			"|RequestHttpHeader_Via=v" ..
			"|TargetUrl=targeturl" ..
			"|RequestHttpHeader_XForwardedHost=xfh" ..
			"|OriginalUrl=OriginalURL" ..
			"|RequestHttpHeader_XForwardedFor=xff" ..
			"|QueueitToken=" .. token ..
			"|RequestIP=userIP" ..
			"|QueueConfig=EventId:eventId&Version:12" ..
			"&QueueDomain:queueDomain&CookieDomain:cookieDomain&ExtendCookieValidity" ..
			":true&CookieValidityMinute:10&LayoutName:layoutName&Culture:culture&ActionName:event1action"

		local cookieArray = utils.explode("|", iHelpers.response.debugCookieSet )
		for _, value in pairs(cookieArray) do
			assert( utils:contains(expectedCookie, value))
		end
	end
	test_resolveQueueRequestByLocalConfig_debug()

	local function test_ResolveQueueRequestByLocalConfig_debug_nullconfig()
		resetAllMocks()

		iHelpers.request.getHeader = function(name)
			if(name == "via") then return "v" end
			if(name == "forwarded") then return "f" end
			if(name == "x-forwarded-for") then return "xff" end
			if(name == "x-forwarded-host") then return "xfh" end
			if(name == "x-forwarded-proto") then return "xfp" end
			return nil
		end
		iHelpers.request.getAbsoluteUri = function() return "OriginalURL" end
		iHelpers.request.getUserHostAddress = function() return "userIP" end

		local token = generateHashDebugValidHash("secretkey")
		local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

		local errorMsg = "unspecified"
		xpcall(
			function()
				knownUser.resolveQueueRequestByLocalConfig("targeturl", token, nil, "customerid", "secretkey")
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( utils.endsWith(errorMsg, "queueConfig can not be nil.") )

		local expectedCookie =
			"|SdkVersion=" .. userInQueueServiceMock.SDK_VERSION ..
			"|Connector=mock-connector" ..
			"|Runtime=" .. _VERSION ..
			"|RequestHttpHeader_Forwarded=f" ..
			"|ServerUtcTime=" .. timestamp ..
			"|RequestHttpHeader_XForwardedProto=xfp" ..
			"|RequestHttpHeader_Via=v" ..
			"|TargetUrl=targeturl" ..
			"|RequestHttpHeader_XForwardedHost=xfh" ..
			"|OriginalUrl=OriginalURL" ..
			"|RequestHttpHeader_XForwardedFor=xff" ..
			"|QueueitToken=" .. token ..
			"|RequestIP=userIP" ..
			"|QueueConfig=NULL" ..
			"|queueConfig can not be nil."

		local cookieArray = utils.explode("|", expectedCookie)
		for _, value in pairs(cookieArray) do
			assert( utils:contains(iHelpers.response.debugCookieSet, value))
		end
	end
	test_ResolveQueueRequestByLocalConfig_debug_nullconfig()

	local function test_ResolveQueueRequestByLocalConfig_debug_missing_customerid()
		resetAllMocks()

		local eventconfig = models.QueueEventConfig.create()
		local token = generateHashDebugValidHash("secretkey", true)

		local result = knownUser.resolveQueueRequestByLocalConfig("targeturl", token, eventconfig, nil, "secretkey")

		assert( result.redirectUrl == "https://api2.queue-it.net/diagnostics/connector/error/?code=setup" )
		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_ResolveQueueRequestByLocalConfig_debug_missing_customerid()

	local function test_ResolveQueueRequestByLocalConfig_debug_missing_secretkey()
		resetAllMocks()

		local eventconfig = models.QueueEventConfig.create()
		local token = generateHashDebugValidHash("secretkey", true)

		local result = knownUser.resolveQueueRequestByLocalConfig("targeturl", token, eventconfig, "customerid", nil)

		assert( result.redirectUrl == "https://api2.queue-it.net/diagnostics/connector/error/?code=setup" )
		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_ResolveQueueRequestByLocalConfig_debug_missing_secretkey()

	local function test_ResolveQueueRequestByLocalConfig_debug_expiredtoken()
		resetAllMocks()

		local eventconfig = models.QueueEventConfig.create()
		local token = generateHashDebugValidHash("secretkey", true)

		local result = knownUser.resolveQueueRequestByLocalConfig(
			"targeturl", token, eventconfig, "customerid", "secretkey")

		assert( result.redirectUrl ==
			"https://customerid.api2.queue-it.net/customerid/diagnostics/connector/error/?code=timestamp" )
		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_ResolveQueueRequestByLocalConfig_debug_expiredtoken()

	local function test_ResolveQueueRequestByLocalConfig_debug_modifiedtoken()
		resetAllMocks()

		local eventconfig = models.QueueEventConfig.create()
		local token = generateHashDebugValidHash("secretkey") .. "invalid-hash"

		local result = knownUser.resolveQueueRequestByLocalConfig(
			"targeturl", token, eventconfig, "customerid", "secretkey")

		assert( result.redirectUrl ==
			"https://customerid.api2.queue-it.net/customerid/diagnostics/connector/error/?code=hash" )
		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_ResolveQueueRequestByLocalConfig_debug_modifiedtoken()

	local function test_ResolveQueueRequestByLocalConfig_NoDebugToken_Exception_NoCookie()
		resetAllMocks()

		local eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12
		eventconfig.actionName = "event1action"

		userInQueueServiceMock.validateQueueRequestRaiseException = true

		pcall(function()
			knownUser.resolveQueueRequestByLocalConfig(
				"targeturl", "queueittoken", eventconfig, "customerid", "secretkey")
		end)

		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_ResolveQueueRequestByLocalConfig_NoDebugToken_Exception_NoCookie()

	local function test_cancelRequestByLocalConfig_debug()
		resetAllMocks()

		iHelpers.request.getHeader = function(name)
			if(name == "via") then return "v" end
			if(name == "forwarded") then return "f" end
			if(name == "x-forwarded-for") then return "xff" end
			if(name == "x-forwarded-host") then return "xfh" end
			if(name == "x-forwarded-proto") then return "xfp" end
			return nil
		end
		iHelpers.request.getAbsoluteUri = function() return "OriginalURL" end
		iHelpers.request.getUserHostAddress = function() return "userIP" end

		local cancelEventconfig = models.CancelEventConfig.create()
		cancelEventconfig.cookieDomain = "cookieDomain"
		cancelEventconfig.eventId = "eventId"
		cancelEventconfig.queueDomain = "queueDomain"
		cancelEventconfig.version = 1
		cancelEventconfig.actionName = "event1action"

		local token = generateHashDebugValidHash("secretkey")
		local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
		knownUser.cancelRequestByLocalConfig("targeturl", token, cancelEventconfig, "customerid", "secretkey")

		local expectedCookie =
			"|SdkVersion=" .. userInQueueServiceMock.SDK_VERSION ..
			"|Connector=mock-connector" ..
			"|Runtime=" .. _VERSION ..
			"|RequestHttpHeader_Forwarded=f" ..
			"|ServerUtcTime=" .. timestamp ..
			"|RequestHttpHeader_XForwardedProto=xfp" ..
			"|RequestHttpHeader_Via=v" ..
			"|TargetUrl=targeturl" ..
			"|CancelConfig=EventId:eventId&Version:1&QueueDomain:queueDomain&" ..
			"CookieDomain:cookieDomain&ActionName:event1action" ..
			"|OriginalUrl=OriginalURL" ..
			"|RequestHttpHeader_XForwardedHost=xfh" ..
			"|RequestHttpHeader_XForwardedFor=xff" ..
			"|QueueitToken=" .. token ..
			"|RequestIP=userIP"

		local cookieArray = utils.explode("|", iHelpers.response.debugCookieSet )
		for _, value in pairs(cookieArray) do
			assert( utils:contains(expectedCookie, value))
		end
	end
	test_cancelRequestByLocalConfig_debug()

	local function test_CancelRequestByLocalConfig_debug_nullconfig()
		resetAllMocks()

		iHelpers.request.getHeader = function(name)
			if(name == "via") then return "v" end
			if(name == "forwarded") then return "f" end
			if(name == "x-forwarded-for") then return "xff" end
			if(name == "x-forwarded-host") then return "xfh" end
			if(name == "x-forwarded-proto") then return "xfp" end
			return nil
		end
		iHelpers.request.getAbsoluteUri = function() return "OriginalURL" end
		iHelpers.request.getUserHostAddress = function() return "userIP" end

		local token = generateHashDebugValidHash("secretkey")
		local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

		local errorMsg = "unspecified"
		xpcall(
			function()
				knownUser.cancelRequestByLocalConfig("targeturl", token, nil, "customerid", "secretkey")
			end,
			function(err)
				errorMsg = err
			end
		)

		assert( utils.endsWith(errorMsg, "cancelConfig can not be nil.") )

		local expectedCookie =
			"|SdkVersion=" .. userInQueueServiceMock.SDK_VERSION ..
			"|Connector=mock-connector" ..
			"|Runtime=" .. _VERSION ..
			"|RequestHttpHeader_Forwarded=f" ..
			"|ServerUtcTime=" .. timestamp ..
			"|RequestHttpHeader_XForwardedProto=xfp" ..
			"|RequestHttpHeader_Via=v" ..
			"|TargetUrl=targeturl" ..
			"|RequestHttpHeader_XForwardedHost=xfh" ..
			"|OriginalUrl=OriginalURL" ..
			"|RequestHttpHeader_XForwardedFor=xff" ..
			"|QueueitToken=" .. token ..
			"|RequestIP=userIP" ..
			"|CancelConfig=NULL" ..
			"|cancelConfig can not be nil."

		local cookieArray = utils.explode("|", expectedCookie)
		for _, value in pairs(cookieArray) do
			assert( utils:contains(iHelpers.response.debugCookieSet, value))
		end
	end
	test_CancelRequestByLocalConfig_debug_nullconfig()

	local function test_CancelRequestByLocalConfig_debug_missing_customerid()
		resetAllMocks()

		local cancelEventconfig = models.CancelEventConfig.create()
		local token = generateHashDebugValidHash("secretkey", true)

		local result = knownUser.cancelRequestByLocalConfig("targeturl", token, cancelEventconfig, nil, "secretkey")

		assert( result.redirectUrl == "https://api2.queue-it.net/diagnostics/connector/error/?code=setup" )
		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_CancelRequestByLocalConfig_debug_missing_customerid()

	local function test_CancelRequestByLocalConfig_debug_missing_secretkey()
		resetAllMocks()

		local cancelEventconfig = models.CancelEventConfig.create()
		local token = generateHashDebugValidHash("secretkey", true)

		local result = knownUser.cancelRequestByLocalConfig("targeturl", token, cancelEventconfig, "customerid", nil)

		assert( result.redirectUrl == "https://api2.queue-it.net/diagnostics/connector/error/?code=setup" )
		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_CancelRequestByLocalConfig_debug_missing_secretkey()

	local function test_CancelRequestByLocalConfig_debug_expiredtoken()
		resetAllMocks()

		local cancelEventconfig = models.CancelEventConfig.create()
		local token = generateHashDebugValidHash("secretkey", true)

		local result = knownUser.cancelRequestByLocalConfig(
			"targeturl", token, cancelEventconfig, "customerid", "secretkey")

		assert( result.redirectUrl ==
			"https://customerid.api2.queue-it.net/customerid/diagnostics/connector/error/?code=timestamp" )
		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_CancelRequestByLocalConfig_debug_expiredtoken()

	local function test_CancelRequestByLocalConfig_debug_modifiedtoken()
		resetAllMocks()

		local cancelEventconfig = models.CancelEventConfig.create()
		local token = generateHashDebugValidHash("secretkey") .. "invalid-hash"

		local result = knownUser.cancelRequestByLocalConfig(
			"targeturl", token, cancelEventconfig, "customerid", "secretkey")

		assert( result.redirectUrl ==
			"https://customerid.api2.queue-it.net/customerid/diagnostics/connector/error/?code=hash" )
		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_CancelRequestByLocalConfig_debug_modifiedtoken()

	local function test_cancelRequestByLocalConfig_NoDebugToken_Exception_NoCookie()
		resetAllMocks()

		local cancelEventconfig = models.CancelEventConfig.create()
		cancelEventconfig.cookieDomain = "cookieDomain"
		cancelEventconfig.eventId = "eventId"
		cancelEventconfig.queueDomain = "queueDomain"
		cancelEventconfig.version = 1
		cancelEventconfig.actionName = "event1action"

		userInQueueServiceMock.validateCancelRequestRaiseException = true

		pcall(function()
			knownUser.cancelRequestByLocalConfig("targeturl", "token", cancelEventconfig, "customerid", "secretkey")
		end)

		assert( iHelpers.response.debugCookieSet == nil )
	end
	test_cancelRequestByLocalConfig_NoDebugToken_Exception_NoCookie()
end
KnownUserTest()