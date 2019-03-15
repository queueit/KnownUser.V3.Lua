local models = require("Models")
local utils = require("Utils")
local knownUser = require("KnownUser")

-- Mocks
iHelpers = require("KnownUserImplementationHelpers")
iHelpers.reset = function()
	iHelpers.request.getHeader = function(name) 
		return nil 
	end
	iHelpers.request.getAbsoluteUri = function() 
		return nil 
	end
	iHelpers.request.getUserHostAddress = function() 
		return nil 
	end
	iHelpers.response.setCookie = function(name, value, expire, domain)
		if(name=="queueitdebug") then
			iHelpers.response.debugCookieSet = value
		end
	end
	iHelpers.response.debugCookieSet = nil
end

userInQueueServiceMock = require("UserInQueueService")
userInQueueServiceMock.validateQueueRequestResult = { }
userInQueueServiceMock.validateQueueRequest = function(targetUrl, queueitToken, queueConfig, customerId, secretKey)
	userInQueueServiceMock.methodInvokations = { method="validateQueueRequest", targetUrl=targetUrl, queueitToken=queueitToken, queueConfig=queueConfig, customerId=customerId, secretKey=secretKey }
	return userInQueueServiceMock.validateQueueRequestResult
end
userInQueueServiceMock.validateCancelRequestResult = { }
userInQueueServiceMock.validateCancelRequest = function(targetUrl, cancelConfig, customerId, secretKey)
    userInQueueServiceMock.methodInvokations = { method="validateCancelRequest", targetUrl=targetUrl, cancelConfig=cancelConfig, customerId=customerId, secretKey=secretKey }
	return userInQueueServiceMock.validateCancelRequestResult
end
userInQueueServiceMock.extendQueueCookieResult = { }
userInQueueServiceMock.extendQueueCookie = function(eventId, cookieValidityMinute, cookieDomain, secretKey)
    userInQueueServiceMock.methodInvokations = { method="extendQueueCookie", eventId=eventId, cookieValidityMinute=cookieValidityMinute, cookieDomain=cookieDomain, secretKey=secretKey }
    return userInQueueServiceMock.validateQueueRequestResult
end
userInQueueServiceMock.getIgnoreActionResult = function ()
	userInQueueServiceMock.methodInvokations = { method="getIgnoreActionResult" }
	return models.RequestValidationResult.create("Ignore", nil, nil, nil, nil)
end

userInQueueServiceMock.reset = function()
	userInQueueServiceMock.methodInvokations = { }
	userInQueueServiceMock.validateQueueRequestResult = { }
	userInQueueServiceMock.validateCancelRequestResult = { }
	userInQueueServiceMock.extendQueueCookieResult = { }
end

function resetAllMocks()
	iHelpers.reset()
	userInQueueServiceMock.reset()
end
-- END Mocks

function generateHashDebugValidHash(secretKey)
	local t = 'e_eventId' .. '~rt_debug'
	local h = iHelpers.hash.hmac_sha256_encode(t, secretKey)
	
	return t .. '~h_' .. h
end

function KnownUserTest()
	
	local function test_cancelRequestByLocalConfig()
	  resetAllMocks()
		
		userInQueueServiceMock.validateCancelRequestResult = models.RequestValidationResult.create("Cancel", "eventid", "queueid", "http://q.queue-it.net", nil)

		cancelEventconfig = models.CancelEventConfig.create()
		cancelEventconfig.cookieDomain = "cookiedomain"
		cancelEventconfig.eventId = "eventid"
		cancelEventconfig.queueDomain = "queuedomain"
		cancelEventconfig.version = 1

		result = knownUser.cancelRequestByLocalConfig("url", "queueittoken", cancelEventconfig, "customerid", "secretkey")

		assert( userInQueueServiceMock.methodInvokations.method == "validateCancelRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "url" )
		assert( userInQueueServiceMock.methodInvokations.customerId == "customerid" )
		assert( userInQueueServiceMock.methodInvokations.secretKey == "secretkey" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["eventId"] == "eventid" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["queueDomain"] == "queuedomain" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["cookieDomain"] == "cookiedomain" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["version"] == 1 )
		assert( result.isAjaxResult == false )
	end
	test_cancelRequestByLocalConfig()

	local function test_cancelRequestByLocalConfig_AjaxCall()
		resetAllMocks()
		
		userInQueueServiceMock.validateCancelRequestResult = models.RequestValidationResult.create("Cancel", "eventid", "queueid", "http://q.queue-it.net", nil)

		iHelpers.request.getHeader = function(name)
			if (name == "x-queueit-ajaxpageurl") then
				return "http%3a%2f%2furl"
			else
				return nil
			end
		end

		cancelEventconfig = models.CancelEventConfig.create()
		cancelEventconfig.cookieDomain = "cookiedomain"
		cancelEventconfig.eventId = "eventid"
		cancelEventconfig.queueDomain = "queuedomain"
		cancelEventconfig.version = 1

		result = knownUser.cancelRequestByLocalConfig("url", "queueittoken", cancelEventconfig, "customerid", "secretkey")

		assert( userInQueueServiceMock.methodInvokations.method == "validateCancelRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "http://url" )
		assert( userInQueueServiceMock.methodInvokations.customerId == "customerid" )
		assert( userInQueueServiceMock.methodInvokations.secretKey == "secretkey" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["eventId"] == "eventid" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["queueDomain"] == "queuedomain" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["cookieDomain"] == "cookiedomain" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["version"] == 1 )
		assert( result.isAjaxResult == true )
		assert( result:getAjaxRedirectUrl() == "http%3A%2F%2Fq.queue-it.net" )		
	end
	test_cancelRequestByLocalConfig_AjaxCall()

	local function test_cancelRequestByLocalConfig_empty_eventId()
		resetAllMocks()	
		
		cancelconfig = models.CancelEventConfig.create()
		cancelconfig.cookieDomain = "cookieDomain"
		cancelconfig.queueDomain = "queueDomain"
		cancelconfig.version = 12
		
		status = xpcall(
			function()
				knownUser.cancelRequestByLocalConfig("targeturl", "queueittoken", cancelconfig, "customerid", "secretkey")
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
		
		cancelconfig = models.CancelEventConfig.create()
		cancelconfig.cookieDomain = "cookieDomain"
		cancelconfig.eventId = "eventId"
		cancelconfig.queueDomain = "queueDomain"
		cancelconfig.version = 12
		
		status = xpcall(
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
		
		cancelconfig = models.CancelEventConfig.create()
		cancelconfig.cookieDomain = "cookieDomain"
		cancelconfig.eventId = "eventId"
		--cancelconfig.queueDomain = "queueDomain"
		cancelconfig.version = 12
		
		status = xpcall(
			function()
				knownUser.cancelRequestByLocalConfig("targeturl", "queueittoken", cancelconfig, "customerid", "secretkey")
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
		
		cancelconfig = models.CancelEventConfig.create()
		cancelconfig.cookieDomain = "cookieDomain"
		cancelconfig.eventId = "eventId"
		cancelconfig.queueDomain = "queueDomain"
		cancelconfig.version = 12
		
		status = xpcall(
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

	    cancelconfig = models.CancelEventConfig.create()
		cancelconfig.cookieDomain = "cookieDomain"
		cancelconfig.eventId = "eventId"
		cancelconfig.queueDomain = "queueDomain"
		cancelconfig.version = 12
		
		status = xpcall(
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

		status = xpcall(
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

	  status = xpcall(
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

	  status = xpcall(
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

	  status = xpcall(
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
			
		eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		--eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		status = xpcall(
			function()
				knownUser.resolveQueueRequestByLocalConfig("targeturl", "queueIttoken", eventconfig, "customerid", "secretkey")
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
		
		eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		status = xpcall(
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
			
		eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		--eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		status = xpcall(
			function()
				knownUser.resolveQueueRequestByLocalConfig("targeturl", "queueIttoken", eventconfig, "customerid", "secretkey")
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
			
		eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		status = xpcall(
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
			
		eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = nil
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		status = xpcall(
			function()
				knownUser.resolveQueueRequestByLocalConfig("targeturl", "queueIttoken", eventconfig, "customerId", "secretkey")
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
		
		eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = nil
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		status = xpcall(
			function()
				knownUser.resolveQueueRequestByLocalConfig("targeturl", "queueIttoken", eventconfig, "customerId", "secretkey")
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
		
		eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = "test"
		eventconfig.version = 12

		status = xpcall(
			function()
				knownUser.resolveQueueRequestByLocalConfig("targeturl", "queueIttoken", eventconfig, "customerId", "secretkey")
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
	
		eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		result = knownUser.resolveQueueRequestByLocalConfig("targeturl", "queueIttoken", eventconfig, "customerid", "secretkey")

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

		eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		userInQueueServiceMock.validateQueueRequestResult = models.RequestValidationResult.create("Queue","eventid","","http://q.queue-it.net","");

		result = knownUser.resolveQueueRequestByLocalConfig("targeturl", "queueIttoken", eventconfig, "customerid", "secretkey")

		assert( userInQueueServiceMock.methodInvokations.method == "validateQueueRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "http://url" )
		assert( userInQueueServiceMock.methodInvokations.queueitToken == "queueIttoken" )
		assert( userInQueueServiceMock.methodInvokations.queueConfig == eventconfig )
		assert( userInQueueServiceMock.methodInvokations.customerId == "customerid" )
		assert( userInQueueServiceMock.methodInvokations.secretKey == "secretkey" )
	
		assert( result.isAjaxResult == true )
		assert( result:getAjaxRedirectUrl() == "http%3A%2F%2Fq.queue-it.net" )
	end
	test_resolveQueueRequestByLocalConfig_AjaxCall()

	local function test_validateRequestByIntegrationConfig_empty_currentUrl()
	end
	test_validateRequestByIntegrationConfig_empty_currentUrl()

	local function test_validateRequestByIntegrationConfig_empty_integrationsConfigString()
	end
	test_validateRequestByIntegrationConfig_empty_integrationsConfigString()

	local function test_validateRequestByIntegrationConfig()
	  resetAllMocks()
		
		userInQueueServiceMock.validateQueueRequestResult = models.RequestValidationResult.create("Queue", "eventid", "", "http://q.queue-it.net", "")

		iHelpers.request.getHeader = function(name)
			if (name == "user-agent") then
				return "googlebot"
			else
				return nil
			end
		end
		
        integrationConfigString = 
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

		result =  knownUser.validateRequestByIntegrationConfig("http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")

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
	end
	test_validateRequestByIntegrationConfig()

	local function test_validateRequestByIntegrationConfig_AjaxCall()
	end
	test_validateRequestByIntegrationConfig_AjaxCall()

	local function test_validateRequestByIntegrationConfig_NotMatch()
		resetAllMocks()

		integrationConfigString = 
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

		result = knownUser.validateRequestByIntegrationConfig("http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")
		
		assert( next(userInQueueServiceMock.methodInvokations) == nil )
        assert( result:doRedirect() == false )	
	end
	test_validateRequestByIntegrationConfig_NotMatch()

	local function test_validateRequestByIntegrationConfig_ForcedTargeturl()
		resetAllMocks()
		
		integrationConfigString = 
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
		
		result = knownUser.validateRequestByIntegrationConfig("http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")
		
		assert( userInQueueServiceMock.methodInvokations.method == "validateQueueRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "http://test.com" )	
	end
	test_validateRequestByIntegrationConfig_ForcedTargeturl()

	local function test_validateRequestByIntegrationConfig_ForcedTargeturl_AjaxCall()
		resetAllMocks()
		
		userInQueueServiceMock.validateQueueRequestResult = models.RequestValidationResult.create("Queue", "eventid", "", "http://q.queue-it.net", "")

		iHelpers.request.getHeader = function(name)
			if (name == "x-queueit-ajaxpageurl") then
				return "http%3a%2f%2furl"
			else
				return nil
			end
		end

		integrationConfigString = 
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
		
		result = knownUser.validateRequestByIntegrationConfig("http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")
		
		assert( userInQueueServiceMock.methodInvokations.method == "validateQueueRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "http://test.com" )	

		assert( result.isAjaxResult == true )
		assert( result:getAjaxRedirectUrl() == "http%3A%2F%2Fq.queue-it.net" )		
	end
	test_validateRequestByIntegrationConfig_ForcedTargeturl_AjaxCall()
	
	local function test_validateRequestByIntegrationConfig_EventTargetUrl()
		resetAllMocks()
		
		integrationConfigString = 
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
		
		result = knownUser.validateRequestByIntegrationConfig("http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")
		
		assert( userInQueueServiceMock.methodInvokations.method == "validateQueueRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "" )	
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

		integrationConfigString = 
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
		
		result = knownUser.validateRequestByIntegrationConfig("http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")
		
		assert( userInQueueServiceMock.methodInvokations.method == "validateQueueRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "" )
		assert( result.isAjaxResult == true )
	end
	test_validateRequestByIntegrationConfig_EventTargetUrl_AjaxCall()

	local function test_validateRequestByIntegrationConfig_CancelAction()
		resetAllMocks()
		
		integrationConfigString = 
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

		userInQueueServiceMock.validateCancelRequestResult = models.RequestValidationResult.create("Cancel", "event1", "queueid", "redirectUrl", nil)

		result = knownUser.validateRequestByIntegrationConfig("http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")
		assert( result.redirectUrl == "redirectUrl" )

		assert( userInQueueServiceMock.methodInvokations.method == "validateCancelRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "http://test.com?event1=true" )
		assert( userInQueueServiceMock.methodInvokations.customerId == "customerid" )
		assert( userInQueueServiceMock.methodInvokations.secretKey == "secretkey" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["eventId"] == "event1" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["queueDomain"] == "knownusertest.queue-it.net" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["cookieDomain"] == ".test.com" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["version"] == 3 )
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

		integrationConfigString = 
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

		userInQueueServiceMock.validateCancelRequestResult = models.RequestValidationResult.create("Cancel", "event1", "queueid", "redirectUrl", nil)

		result = knownUser.validateRequestByIntegrationConfig("http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")
		assert( result.redirectUrl == "redirectUrl" )

		assert( userInQueueServiceMock.methodInvokations.method == "validateCancelRequest" )
		assert( userInQueueServiceMock.methodInvokations.targetUrl == "http://url" )
		assert( userInQueueServiceMock.methodInvokations.customerId == "customerid" )
		assert( userInQueueServiceMock.methodInvokations.secretKey == "secretkey" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["eventId"] == "event1" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["queueDomain"] == "knownusertest.queue-it.net" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["cookieDomain"] == ".test.com" )
		assert( userInQueueServiceMock.methodInvokations.cancelConfig["version"] == 3 )
		assert( result.isAjaxResult == true )
	end
	test_validateRequestByIntegrationConfig_CancelAction_AjaxCall()

	local function test_validateRequestByIntegrationConfig_IgnoreAction()
		resetAllMocks()
		
		integrationConfigString = 
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

		result = knownUser.validateRequestByIntegrationConfig("http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")
		assert( userInQueueServiceMock.methodInvokations.method == "getIgnoreActionResult" )
		assert( result.actionType == "Ignore" )
		assert( result.isAjaxResult == false )
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

		integrationConfigString = 
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

		result = knownUser.validateRequestByIntegrationConfig("http://test.com?event1=true", "queueIttoken", integrationConfigString, "customerid", "secretkey")
		assert( userInQueueServiceMock.methodInvokations.method == "getIgnoreActionResult" )
		assert( result.actionType == "Ignore" )
		assert( result.isAjaxResult == true )
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
		
		integrationConfigString = 
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
	
		token = generateHashDebugValidHash("secretkey")
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
		url = "http://test.com?event1=true&queueittoken=" .. generateHashDebugValidHash("secretkey")
		result = knownUser.validateRequestByIntegrationConfig(url, token, integrationConfigString, "customerid", "secretkey")

		expectedCookie=
		"MatchedConfig=event1action" ..
		"|ConfigVersion=3" ..
		"|PureUrl=http://test.com?event1=true&queueittoken=e_eventId~rt_debug~h_0aa4b0e41d4cceae77d8fa63890a778f2b5c9cf962239f2862150517844bc0ce" ..
		"|ServerUtcTime=" .. timestamp .. 
		"|RequestHttpHeader_XForwardedProto=xfp" ..
		"|RequestHttpHeader_Via=v" ..
		"|TargetUrl=http://test.com?event1=true&queueittoken=e_eventId~rt_debug~h_0aa4b0e41d4cceae77d8fa63890a778f2b5c9cf962239f2862150517844bc0ce" ..
		"|CancelConfig=EventId:event1&Version:3&QueueDomain:knownusertest.queue-it.net&CookieDomain:.test.com" ..
		"|RequestHttpHeader_XForwardedHost=xfh" ..
		"|OriginalUrl=OriginalURL" ..
		"|RequestHttpHeader_XForwardedFor=xff" ..
		"|RequestHttpHeader_Forwarded=f" ..
		"|RequestIP=userIP" ..
		"|QueueitToken=e_eventId~rt_debug~h_0aa4b0e41d4cceae77d8fa63890a778f2b5c9cf962239f2862150517844bc0ce"

		assert( expectedCookie==iHelpers.response.debugCookieSet )
	end
	test_validateRequestByIntegrationConfig_debug()

	local function test_validateRequestByIntegrationConfig_withoutmatch_debug()
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
		
		integrationConfigString = 
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
	
		token = generateHashDebugValidHash("secretkey")
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
		url = "http://test.com?event1=true&queueittoken=" .. generateHashDebugValidHash("secretkey")
		
		result = knownUser.validateRequestByIntegrationConfig(url, token, integrationConfigString, "customerid", "secretkey")

		expectedCookie=
		"MatchedConfig=NULL" ..
		"|ConfigVersion=3" ..
		"|PureUrl=http://test.com?event1=true&queueittoken=e_eventId~rt_debug~h_0aa4b0e41d4cceae77d8fa63890a778f2b5c9cf962239f2862150517844bc0ce" ..
		"|ServerUtcTime=" .. timestamp .. 
		"|RequestHttpHeader_XForwardedProto=xfp" ..
		"|RequestHttpHeader_Via=v" ..
		"|RequestHttpHeader_XForwardedHost=xfh" ..
		"|OriginalUrl=OriginalURL" ..
		"|RequestHttpHeader_XForwardedFor=xff" ..
		"|RequestHttpHeader_Forwarded=f" ..
		"|RequestIP=userIP" ..
		"|QueueitToken=e_eventId~rt_debug~h_0aa4b0e41d4cceae77d8fa63890a778f2b5c9cf962239f2862150517844bc0ce"
		
		assert( expectedCookie==iHelpers.response.debugCookieSet )
	end
	test_validateRequestByIntegrationConfig_withoutmatch_debug()

	local function test_validateRequestByIntegrationConfig_notvalidhash_debug()
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
		
		integrationConfigString = 
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
	
		token = generateHashDebugValidHash("secretkey") .. "invalid"
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
		url = "http://test.com?event1=true&queueittoken=" .. generateHashDebugValidHash("secretkey")
		
		result = knownUser.validateRequestByIntegrationConfig(url, token, integrationConfigString, "customerid", "secretkey")

		expectedCookie= 
		"MatchedConfig=NULL" ..
		"|ConfigVersion=3" .. 
		"|PureUrl=http://test.com?event1=true&queueittoken=e_eventId~rt_debug~h_0aa4b0e41d4cceae77d8fa63890a778f2b5c9cf962239f2862150517844bc0ce" .. 
		"|ServerUtcTime=" .. timestamp .. 
		"|RequestHttpHeader_XForwardedProto=xfp" .. 
		"|RequestHttpHeader_Via=v" .. 
		"|QueueitToken=e_eventId~rt_debug~h_0aa4b0e41d4cceae77d8fa63890a778f2b5c9cf962239f2862150517844bc0ce" .. 
		"|OriginalUrl=OriginalURL" .. 
		"|RequestIP=userIP" .. 
		"|RequestHttpHeader_Forwarded=f" .. 
		"|RequestHttpHeader_XForwardedHost=xfh" .. 
		"|RequestHttpHeader_XForwardedFor=xff"

		assert( iHelpers.response.debugCookieSet == nil )	
	end
	test_validateRequestByIntegrationConfig_notvalidhash_debug()

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
		
		integrationConfigString = 
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
	
		eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		token = generateHashDebugValidHash("secretkey")
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
		result = knownUser.resolveQueueRequestByLocalConfig("targeturl", token, eventconfig, "customerid", "secretkey")

		expectedCookie=
		"RequestHttpHeader_Forwarded=f" ..
		"|ServerUtcTime=" .. timestamp .. 
		"|RequestHttpHeader_XForwardedProto=xfp" ..
		"|RequestHttpHeader_Via=v" ..
		"|TargetUrl=targeturl" ..
		"|RequestHttpHeader_XForwardedHost=xfh" ..
		"|OriginalUrl=OriginalURL" ..
		"|RequestHttpHeader_XForwardedFor=xff" ..
		"|QueueitToken=e_eventId~rt_debug~h_0aa4b0e41d4cceae77d8fa63890a778f2b5c9cf962239f2862150517844bc0ce" ..
		"|RequestIP=userIP" ..
		"|QueueConfig=EventId:eventId&Version:12&QueueDomain:queueDomain&CookieDomain:cookieDomain&ExtendCookieValidity:true&CookieValidityMinute:10&LayoutName:layoutName&Culture:culture"

		assert( expectedCookie==iHelpers.response.debugCookieSet )	
	end
	test_resolveQueueRequestByLocalConfig_debug()

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
		
		integrationConfigString = 
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
	
		cancelEventconfig = models.CancelEventConfig.create()
		cancelEventconfig.cookieDomain = "cookieDomain"
		cancelEventconfig.eventId = "eventId"
		cancelEventconfig.queueDomain = "queueDomain"
		cancelEventconfig.version = 1

		token = generateHashDebugValidHash("secretkey")
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
		result = knownUser.cancelRequestByLocalConfig("targeturl", token, cancelEventconfig, "customerid", "secretkey")

		expectedCookie=
		"RequestHttpHeader_Forwarded=f" .. 
		"|ServerUtcTime=" .. timestamp .. 
		"|RequestHttpHeader_XForwardedProto=xfp" .. 
		"|RequestHttpHeader_Via=v" .. 
		"|TargetUrl=targeturl" .. 
		"|CancelConfig=EventId:eventId&Version:1&QueueDomain:queueDomain&CookieDomain:cookieDomain" .. 
		"|OriginalUrl=OriginalURL" .. 
		"|RequestHttpHeader_XForwardedHost=xfh" .. 
		"|RequestHttpHeader_XForwardedFor=xff" .. 
		"|QueueitToken=e_eventId~rt_debug~h_0aa4b0e41d4cceae77d8fa63890a778f2b5c9cf962239f2862150517844bc0ce" .. 
		"|RequestIP=userIP"

		assert( expectedCookie==iHelpers.response.debugCookieSet )
	end
	test_cancelRequestByLocalConfig_debug()
end
KnownUserTest()