local models = require("Models")
local utils = require("Utils")
local knownUser = require("KnownUser")

-- Mocks
iHelpers = require("KnownUserImplementationHelpers")
iHelpers.request.getHeader = function(name) 
	return nil 
end

userInQueueServiceMock = require("UserInQueueService")
userInQueueServiceMock.validateQueueRequestResult = { }
userInQueueServiceMock.validateQueueRequest = function(targetUrl, queueitToken, queueConfig, customerId, secretKey)
	userInQueueServiceMock.validateQueueRequestCall = { method="validateQueueRequest", targetUrl=targetUrl, queueitToken=queueitToken, queueConfig=queueConfig, customerId=customerId, secretKey=secretKey }
	return userInQueueServiceMock.validateQueueRequestResult	
end
userInQueueServiceMock.reset = function()
	userInQueueServiceMock.validateQueueRequestResult = { }
	userInQueueServiceMock.validateQueueRequestCall = { }
end
-- END Mocks

function KnownUserTest()
	
	-- TODO Finish unit tests (all the empty local functions)
	
	local function test_cancelRequestByLocalConfig()
	end
	test_cancelRequestByLocalConfig()

	local function test_cancelRequestByLocalConfig_AjaxCall()
	end
	test_cancelRequestByLocalConfig_AjaxCall()

	local function test_cancelRequestByLocalConfig_empty_eventId()
	end
	test_cancelRequestByLocalConfig_empty_eventId()

	local function test_cancelRequestByLocalConfig_empty_secreteKey()
	end
	test_cancelRequestByLocalConfig_empty_secreteKey()

	local function test_cancelRequestByLocalConfig_empty_queueDomain()
	end
	test_cancelRequestByLocalConfig_empty_queueDomain()

	local function test_cancelRequestByLocalConfig_empty_customerId()
	end
	test_cancelRequestByLocalConfig_empty_customerId()

	local function test_cancelRequestByLocalConfig_empty_targeturl()
	end
	test_cancelRequestByLocalConfig_empty_targeturl()

	local function test_extendQueueCookie_null_EventId()
	end
	test_extendQueueCookie_null_EventId()

	local function test_extendQueueCookie_null_SecretKey()
	end
	test_extendQueueCookie_null_SecretKey()

	local function test_extendQueueCookie_Invalid_CookieValidityMinute()
	end
	test_extendQueueCookie_Invalid_CookieValidityMinute()

	local function test_extendQueueCookie_Negative_CookieValidityMinute()
	end
	test_extendQueueCookie_Negative_CookieValidityMinute()

	local function test_extendQueueCookie()
	end
	test_extendQueueCookie()

	local function test_resolveRequestByLocalEventConfig_empty_eventId()
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
				knownUser.resolveRequestByLocalEventConfig("targeturl", "queueIttoken", eventconfig, "customerid", "secretkey")
			end,
			function(err) 
				errorMsg = err 
			end
		)
		
		assert( status == false )
		assert( utils.endsWith(errorMsg, "eventId from queueConfig can not be nil or empty.") )
    end
	test_resolveRequestByLocalEventConfig_empty_eventId()

	local function test_resolveRequestByLocalEventConfig_empty_secretKey()
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
				knownUser.resolveRequestByLocalEventConfig("targeturl", "queueIttoken", eventconfig, "customerid", nil)
			end,
			function(err) 
				errorMsg = err 
			end
		)
		
		assert( status == false )
		assert( utils.endsWith(errorMsg, "secretKey can not be nil or empty.") )
    end
	test_resolveRequestByLocalEventConfig_empty_secretKey()

	local function test_resolveRequestByLocalEventConfig_empty_queueDomain()
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
				knownUser.resolveRequestByLocalEventConfig("targeturl", "queueIttoken", eventconfig, "customerid", "secretkey")
			end,
			function(err) 
				errorMsg = err 
			end
		)
		
		assert( status == false )
		assert( utils.endsWith(errorMsg, "queueDomain from queueConfig can not be nil or empty.") )
    end
	test_resolveRequestByLocalEventConfig_empty_queueDomain()

	local function test_resolveRequestByLocalEventConfig_empty_customerId()
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
				knownUser.resolveRequestByLocalEventConfig("targeturl", "queueIttoken", eventconfig, nil, "secretkey")
			end,
			function(err) 
				errorMsg = err 
			end
		)
		
		assert( status == false )
		assert( utils.endsWith(errorMsg, "customerId can not be nil or empty.") )
    end
	test_resolveRequestByLocalEventConfig_empty_customerId()

	local function test_resolveRequestByLocalEventConfig_Invalid_extendCookieValidity()
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
				knownUser.resolveRequestByLocalEventConfig("targeturl", "queueIttoken", eventconfig, "customerId", "secretkey")
			end,
			function(err) 
				errorMsg = err 
			end
		)
		
		assert( status == false )
		assert( utils.endsWith(errorMsg, "extendCookieValidity from queueConfig should be valid boolean.") )
	end
	test_resolveRequestByLocalEventConfig_Invalid_extendCookieValidity()

	local function test_resolveRequestByLocalEventConfig_Invalid_cookieValidityMinute()
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
				knownUser.resolveRequestByLocalEventConfig("targeturl", "queueIttoken", eventconfig, "customerId", "secretkey")
			end,
			function(err) 
				errorMsg = err 
			end
		)
		
		assert( status == false )
		assert( utils.endsWith(errorMsg, "extendCookieValidity from queueConfig should be valid boolean.") )
	end
	test_resolveRequestByLocalEventConfig_Invalid_cookieValidityMinute()

	local function test_resolveRequestByLocalEventConfig_zero_cookieValidityMinute()
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
				knownUser.resolveRequestByLocalEventConfig("targeturl", "queueIttoken", eventconfig, "customerId", "secretkey")
			end,
			function(err) 
				errorMsg = err 
			end
		)
		
		assert( status == false )
		assert( utils.endsWith(errorMsg, "cookieValidityMinute from queueConfig should be a number greater than 0.") )
	end
	test_resolveRequestByLocalEventConfig_zero_cookieValidityMinute()

	local function test_resolveRequestByLocalEventConfig()
		userInQueueServiceMock.reset()
		
		eventconfig = models.QueueEventConfig.create()
		eventconfig.cookieDomain = "cookieDomain"
		eventconfig.layoutName = "layoutName"
		eventconfig.culture = "culture"
		eventconfig.eventId = "eventId"
		eventconfig.queueDomain = "queueDomain"
		eventconfig.extendCookieValidity = true
		eventconfig.cookieValidityMinute = 10
		eventconfig.version = 12

		result = knownUser.resolveRequestByLocalEventConfig("targeturl", "queueIttoken", eventconfig, "customerid", "secretkey")

		assert( userInQueueServiceMock.validateQueueRequestCall.method == "validateQueueRequest" )
		assert( userInQueueServiceMock.validateQueueRequestCall.targetUrl == "targeturl" )
		assert( userInQueueServiceMock.validateQueueRequestCall.queueitToken == "queueIttoken" )
		assert( userInQueueServiceMock.validateQueueRequestCall.queueConfig == eventconfig )
		assert( userInQueueServiceMock.validateQueueRequestCall.customerId == "customerid" )
		assert( userInQueueServiceMock.validateQueueRequestCall.secretKey == "secretkey" )
	
		assert( result.isAjaxResult == false )
	end
	test_resolveRequestByLocalEventConfig()

	local function test_resolveRequestByLocalEventConfig_AjaxCall()
	end
	test_resolveRequestByLocalEventConfig_AjaxCall()

	local function test_validateRequestByIntegrationConfig_empty_currentUrl()
	end
	test_validateRequestByIntegrationConfig_empty_currentUrl()

	local function test_validateRequestByIntegrationConfig_empty_integrationsConfigString()
	end
	test_validateRequestByIntegrationConfig_empty_integrationsConfigString()

	local function test_validateRequestByIntegrationConfig()
		userInQueueServiceMock.reset()
		userInQueueServiceMock.validateQueueRequestResult = models.RequestValidationResult.create("Queue", "eventid", "", "http://q.qeuue-it.com", "")

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

		assert( userInQueueServiceMock.validateQueueRequestCall.method == "validateQueueRequest" )
		assert( userInQueueServiceMock.validateQueueRequestCall.targetUrl == "http://test.com?event1=true" )
		assert( userInQueueServiceMock.validateQueueRequestCall.queueitToken == "queueIttoken" )
		assert( userInQueueServiceMock.validateQueueRequestCall.queueConfig["queueDomain"] == "knownusertest.queue-it.net" )
		assert( userInQueueServiceMock.validateQueueRequestCall.queueConfig["eventId"] == "event1" )
        assert( userInQueueServiceMock.validateQueueRequestCall.queueConfig["culture"] == "" )
        assert( userInQueueServiceMock.validateQueueRequestCall.queueConfig["layoutName"] == "Christmas Layout by Queue-it" )
        assert( userInQueueServiceMock.validateQueueRequestCall.queueConfig["extendCookieValidity"] )
        assert( userInQueueServiceMock.validateQueueRequestCall.queueConfig["cookieValidityMinute"] == 20 )
        assert( userInQueueServiceMock.validateQueueRequestCall.queueConfig["cookieDomain"] == ".test.com" )
        assert( userInQueueServiceMock.validateQueueRequestCall.queueConfig["version"] == 3 )
		assert( userInQueueServiceMock.validateQueueRequestCall.customerId == "customerid" )
		assert( userInQueueServiceMock.validateQueueRequestCall.secretKey == "secretkey" )
		assert( result.isAjaxResult == false )        
	end
	test_validateRequestByIntegrationConfig()

	local function test_validateRequestByIntegrationConfig_AjaxCall()
	end
	test_validateRequestByIntegrationConfig_AjaxCall()

	local function test_validateRequestByIntegrationConfig_NotMatch()
		userInQueueServiceMock.reset()

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
		
		assert( next(userInQueueServiceMock.validateQueueRequestCall) == nil )        
        assert( result:doRedirect() == false )	
	end
	test_validateRequestByIntegrationConfig_NotMatch()

	local function test_validateRequestByIntegrationConfig_ForcedTargeturl()
	end
	test_validateRequestByIntegrationConfig_ForcedTargeturl()

	local function test_validateRequestByIntegrationConfig_ForcedTargeturl_AjaxCall()
	end
	test_validateRequestByIntegrationConfig_ForcedTargeturl_AjaxCall()

	local function test_validateRequestByIntegrationConfig_ForecedTargeturl()
	end
	test_validateRequestByIntegrationConfig_ForecedTargeturl()

	local function test_validateRequestByIntegrationConfig_EventTargetUrl()
	end
	test_validateRequestByIntegrationConfig_EventTargetUrl()

	local function test_validateRequestByIntegrationConfig_EventTargetUrl_AjaxCall()
	end
	test_validateRequestByIntegrationConfig_EventTargetUrl_AjaxCall()

	local function test_validateRequestByIntegrationConfig_CancelAction()
	end
	test_validateRequestByIntegrationConfig_CancelAction()

	local function test_validateRequestByIntegrationConfig_CancelAction_AjaxCall()
	end
	test_validateRequestByIntegrationConfig_CancelAction_AjaxCall()

	local function test_validateRequestByIntegrationConfig_IgnoreAction()
	end
	test_validateRequestByIntegrationConfig_IgnoreAction()

	local function test_validateRequestByIntegrationConfig_IgnoreAction_AjaxCall()
	end
	test_validateRequestByIntegrationConfig_IgnoreAction_AjaxCall()

	local function test_validateRequestByIntegrationConfig_debug()
	end
	test_validateRequestByIntegrationConfig_debug()

	local function test_validateRequestByIntegrationConfig_withoutmatch_debug()
	end
	test_validateRequestByIntegrationConfig_withoutmatch_debug()

	local function test_validateRequestByIntegrationConfig_notvalidhash_debug()
	end
	test_validateRequestByIntegrationConfig_notvalidhash_debug()

	local function test_resolveRequestByLocalEventConfig_debug()
	end
	test_resolveRequestByLocalEventConfig_debug()

	local function test_cancelRequestByLocalConfig_debug()
	end
	test_cancelRequestByLocalConfig_debug()
end
KnownUserTest()