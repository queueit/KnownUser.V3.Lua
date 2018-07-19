local models = require("Models")
local utils = require("Utils")
local userInQueueService = require("UserInQueueService")
local iHelpers = require("KnownUserImplementationHelpers")

-- Mocks
local userInQueueStateCookieRepositoryMock = require("UserInQueueStateCookieRepository")

userInQueueStateCookieRepositoryMock.returnThisState = {}

userInQueueStateCookieRepositoryMock.getState = function(eventId, cookieValidityMinutes, secretKey, validateTime)
	userInQueueStateCookieRepositoryMock.getStateCall = { eventId=eventId, cookieValidityMinutes=cookieValidityMinutes, secretKey=secretKey, validateTime=validateTime }
	return userInQueueStateCookieRepositoryMock.returnThisState
end

userInQueueStateCookieRepositoryMock.store = function(eventId, queueId, fixedCookieValidityMinutes, cookieDomain, redirectType, secretKey)
	userInQueueStateCookieRepositoryMock.storeCall = { eventId=eventId, queueId=queueId, fixedCookieValidityMinutes=fixedCookieValidityMinutes, cookieDomain=cookieDomain, redirectType=redirectType, secretKey=secretKey} 	
end

userInQueueStateCookieRepositoryMock.reset = function()
	userInQueueStateCookieRepositoryMock.getStateCall = {}
	userInQueueStateCookieRepositoryMock.storeCall = {}
end

iHelpers.response.setCookie = function(name, value, expire, domain)	
end
-- END Mocks

function UserInQueueServiceTest()
	local function generateHash(eventId, queueId, timestamp, extendableCookie, cookieValidityMinutes, redirectType, secretKey)
		local token = 'e_' .. eventId .. '~ts_' .. timestamp .. '~ce_' .. extendableCookie .. '~q_' .. queueId
        if (cookieValidityMinutes ~= nil) then
            token = token .. '~cv_' .. cookieValidityMinutes
		end
        if (redirectType ~= nil) then
            token = token .. '~rt_' .. redirectType
		end

		return token .. '~h_' .. iHelpers.hash.hmac_sha256_encode(token, secretKey)
	end
	
	local function test_validateQueueRequest_ValidState_ExtendableCookie_NoCookieExtensionFromConfig_DoNotRedirectDoNotStoreCookieWithExtension()
		userInQueueStateCookieRepositoryMock.reset()
		userInQueueStateCookieRepositoryMock.returnThisState = userInQueueStateCookieRepositoryMock.StateInfo.create(true, "queueId", nil, "idle")

		local eventConfig = models.QueueEventConfig.create()
		eventConfig.eventId = "e1"
		eventConfig.queueDomain = "testDomain"
		eventConfig.cookieDomain = "testDomain"
		eventConfig.cookieValidityMinute = 10
		eventConfig.extendCookieValidity = false
		        		
		local result = userInQueueService.validateQueueRequest("url", "token", eventConfig, "customerid", "key")
                
		assert( result:doRedirect() == false )
        assert( result.queueId == "queueId" )
		
		assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
		assert( userInQueueStateCookieRepositoryMock.getStateCall.eventId == "e1" )
		assert( userInQueueStateCookieRepositoryMock.getStateCall.cookieValidityMinutes == 10 )
		assert( userInQueueStateCookieRepositoryMock.getStateCall.secretKey == "key" )
		assert( userInQueueStateCookieRepositoryMock.getStateCall.validateTime == true )
    end
	test_validateQueueRequest_ValidState_ExtendableCookie_NoCookieExtensionFromConfig_DoNotRedirectDoNotStoreCookieWithExtension()

	local function test_validateQueueRequest_ValidState_ExtendableCookie_CookieExtensionFromConfig_DoNotRedirectDoStoreCookieWithExtension()
        userInQueueStateCookieRepositoryMock.reset()
		userInQueueStateCookieRepositoryMock.returnThisState = userInQueueStateCookieRepositoryMock.StateInfo.create(true, "queueId", nil, "disabled")
		
		local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieDomain = "testDomain"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = true
        
		local result = userInQueueService.validateQueueRequest("url", "token", eventConfig, "customerid", "key")
        
		assert( result:doRedirect() == false )
		assert( result.eventId == 'e1' )
        assert( result.queueId == "queueId" )     
		
		assert( next(userInQueueStateCookieRepositoryMock.storeCall) ~= nil )
		assert( userInQueueStateCookieRepositoryMock.storeCall.eventId == "e1" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.queueId == "queueId" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.fixedCookieValidityMinutes == nil )
		assert( userInQueueStateCookieRepositoryMock.storeCall.cookieDomain == "testDomain" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.redirectType == "disabled" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.secretKey == "key" )
    end
	test_validateQueueRequest_ValidState_ExtendableCookie_CookieExtensionFromConfig_DoNotRedirectDoStoreCookieWithExtension()
	
    local function test_validateQueueRequest_ValidState_NoExtendableCookie_DoNotRedirectDoNotStoreCookieWithExtension()
        userInQueueStateCookieRepositoryMock.reset()
		userInQueueStateCookieRepositoryMock.returnThisState = userInQueueStateCookieRepositoryMock.StateInfo.create(true, "queueId", 3, "idle")
		
		local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = true
	    	
        local result = userInQueueService.validateQueueRequest("url", "token", eventConfig, "customerid", "key")
        
		assert( result:doRedirect() == false )
        assert( result.eventId == 'e1' )
        assert( result.queueId == "queueId" )		
		
		assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
    end
	test_validateQueueRequest_ValidState_NoExtendableCookie_DoNotRedirectDoNotStoreCookieWithExtension()
	
	local function test_validateQueueRequest_NoCookie_TampredToken_RedirectToErrorPageWithHashError_DoNotStoreCookie()
        userInQueueStateCookieRepositoryMock.reset()
		userInQueueStateCookieRepositoryMock.returnThisState = userInQueueStateCookieRepositoryMock.StateInfo.create(false, nil, nil, nil)
		
		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = true
        eventConfig.version = 11
        local url = "http://test.test.com?b=h"
		
        local token = generateHash('e1','queueId', os.time() + (3 * 60), 'False', nil, 'idle', key)
		token = token:gsub("False", "True")

        local expectedErrorUrl = "https://testDomain.com/error/hash/?c=testCustomer&e=e1" 
				.. "&ver=v3-lua-" .. userInQueueService.SDK_VERSION
                .. "&cver=11"
                .. "&queueittoken=" .. token
                .. "&t=" .. utils.urlEncode(url)

		local result = userInQueueService.validateQueueRequest(url, token, eventConfig, "testCustomer", key)
	
		assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
		assert( result:doRedirect() )
        assert( result.eventId == 'e1' )
        
		local tsPart = result.redirectUrl:gmatch("&ts=[^&]*")()
        local timestamp = tsPart:gsub("&ts=", "")
		assert( os.time() - timestamp < 100 )
		local urlWithoutTimeStamp = result.redirectUrl:gsub(tsPart, "")
		assert( urlWithoutTimeStamp == expectedErrorUrl )		
    end
	test_validateQueueRequest_NoCookie_TampredToken_RedirectToErrorPageWithHashError_DoNotStoreCookie()

    local function test_validateQueueRequest_NoCookie_ExpiredTimeStampInToken_RedirectToErrorPageWithTimeStampError_DoNotStoreCookie()
        userInQueueStateCookieRepositoryMock.reset()
		userInQueueStateCookieRepositoryMock.returnThisState = userInQueueStateCookieRepositoryMock.StateInfo.create(false, nil, nil, nil)
		
		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = false
        eventConfig.version = 11
        local url = "http://test.test.com?b=h"
        
		local token = generateHash('e1','queueId', os.time() - (3 * 60), 'False', nil, 'queue', key)
	
		local expectedErrorUrl = "https://testDomain.com/error/timestamp/?c=testCustomer&e=e1" 
				.. "&ver=v3-lua-" .. userInQueueService.SDK_VERSION
                .. "&cver=11"
                .. "&queueittoken=" .. token
                .. "&t=" .. utils.urlEncode(url)

        local result = userInQueueService.validateQueueRequest(url, token, eventConfig, "testCustomer", key)
	
        assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
        assert( result:doRedirect() )
        assert( result.eventId == 'e1' )
        
		local tsPart = result.redirectUrl:gmatch("&ts=[^&]*")()
        local timestamp = tsPart:gsub("&ts=", "")
		assert( os.time() - timestamp < 100 )
		local urlWithoutTimeStamp = result.redirectUrl:gsub(tsPart, "")
		assert( urlWithoutTimeStamp == expectedErrorUrl )
    end
	test_validateQueueRequest_NoCookie_ExpiredTimeStampInToken_RedirectToErrorPageWithTimeStampError_DoNotStoreCookie()
	
    local function test_validateQueueRequest_NoCookie_EventIdMismatch_RedirectToErrorPageWithEventIdMissMatchError_DoNotStoreCookie()
        userInQueueStateCookieRepositoryMock.reset()
		userInQueueStateCookieRepositoryMock.returnThisState = userInQueueStateCookieRepositoryMock.StateInfo.create(false, nil, nil, nil)
		
		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e2"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = true
        eventConfig.version = 11
        local url = "http://test.test.com?b=h"
        		
		local token = generateHash('e1', 'queueId', os.time() - (3 * 60), 'False', nil, 'queue', key)
	
		local expectedErrorUrl = "https://testDomain.com/error/eventid/?c=testCustomer&e=e2" 
				.. "&ver=v3-lua-" .. userInQueueService.SDK_VERSION
                .. "&cver=11"
                .. "&queueittoken=" .. token
                .. "&t=" .. utils.urlEncode(url)
        
        local result = userInQueueService.validateQueueRequest(url, token, eventConfig, "testCustomer", key)
	
        assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
        assert( result:doRedirect() )
        assert( result.eventId == 'e2' )
        
		local tsPart = result.redirectUrl:gmatch("&ts=[^&]*")()
        local timestamp = tsPart:gsub("&ts=", "")
		assert( os.time() - timestamp < 100 )
		local urlWithoutTimeStamp = result.redirectUrl:gsub(tsPart, "")
		assert( urlWithoutTimeStamp == expectedErrorUrl )
    end
	test_validateQueueRequest_NoCookie_EventIdMismatch_RedirectToErrorPageWithEventIdMissMatchError_DoNotStoreCookie()
	
    local function test_validateQueueRequest_NoCookie_ValidToken_ExtendableCookie_DoNotRedirect_StoreExtendableCookie()
        userInQueueStateCookieRepositoryMock.reset()
		userInQueueStateCookieRepositoryMock.returnThisState = userInQueueStateCookieRepositoryMock.StateInfo.create(false, nil, nil, nil)
		
		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.cookieDomain = "testDomain"	
        eventConfig.extendCookieValidity = true	
        eventConfig.version = 11
        local url = "http://test.test.com?b=h"
               
        local token = generateHash('e1', 'queueId', os.time() + (3 * 60), 'true', nil, 'queue', key)
        
        local result = userInQueueService.validateQueueRequest(url, token, eventConfig, "testCustomer", key)
        assert( result:doRedirect() == false )
        assert( result.eventId == 'e1' )
        assert( result.queueId == 'queueId' )
		assert( result.redirectType == 'queue' )

		assert( next(userInQueueStateCookieRepositoryMock.storeCall) ~= nil )
		assert( userInQueueStateCookieRepositoryMock.storeCall.eventId == "e1" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.queueId == "queueId" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.fixedCookieValidityMinutes == nil )
		assert( userInQueueStateCookieRepositoryMock.storeCall.cookieDomain == "testDomain" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.redirectType == "queue" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.secretKey == key )
    end
	test_validateQueueRequest_NoCookie_ValidToken_ExtendableCookie_DoNotRedirect_StoreExtendableCookie()

    local function test_validateQueueRequest_NoCookie_ValidToken_CookieValidityMinuteFromToken_DoNotRedirect_StoreNonExtendableCookie()
        userInQueueStateCookieRepositoryMock.reset()
		userInQueueStateCookieRepositoryMock.returnThisState = userInQueueStateCookieRepositoryMock.StateInfo.create(false, nil, nil, nil)
		
		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 30
        eventConfig.cookieDomain = "testDomain"	
        eventConfig.extendCookieValidity = true	
        eventConfig.version = 11
        local url = "http://test.test.com?b=h"

        local token = generateHash('e1', 'queueId', os.time() + (3 * 60), 'false', 3, 'DirectLink', key)
	        
        local result = userInQueueService.validateQueueRequest(url, token, eventConfig, "testCustomer", key)
        assert( result:doRedirect() == false )
        assert( result.eventId == 'e1' )
        assert( result.queueId == 'queueId' )
		assert( result.redirectType == 'DirectLink' )

		assert( next(userInQueueStateCookieRepositoryMock.storeCall) ~= nil )
		assert( userInQueueStateCookieRepositoryMock.storeCall.eventId == "e1" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.queueId == "queueId" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.fixedCookieValidityMinutes == 3 )
		assert( userInQueueStateCookieRepositoryMock.storeCall.cookieDomain == "testDomain" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.redirectType == "DirectLink" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.secretKey == key )
    end
	test_validateQueueRequest_NoCookie_ValidToken_CookieValidityMinuteFromToken_DoNotRedirect_StoreNonExtendableCookie()

    local function test_NoCookie_NoValidToken_WithoutToken_RedirectToQueue()
        userInQueueStateCookieRepositoryMock.reset()
		userInQueueStateCookieRepositoryMock.returnThisState = userInQueueStateCookieRepositoryMock.StateInfo.create(false, nil, nil, nil)
		
		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = true
        eventConfig.version = 11
        eventConfig.culture = 'en-US'
        eventConfig.layoutName = 'testlayout'
        local url = "http://test.test.com?b=h"
	        
        local token = ""
	
        local expectedRedirectUrl = "https://testDomain.com/?c=testCustomer&e=e1" 
				.. "&ver=v3-lua-" .. userInQueueService.SDK_VERSION
                .. "&cver=11"
                .. "&cid=en-US"
                .. "&l=testlayout"
                .. "&t=" .. utils.urlEncode(url)
	        
        local result = userInQueueService.validateQueueRequest(url, token, eventConfig, "testCustomer", key)
        		
		assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
        assert( result:doRedirect() )
        assert( result.eventId == 'e1' )
        assert( result.queueId == nil )
		assert( result.redirectUrl == expectedRedirectUrl )
    end
	test_NoCookie_NoValidToken_WithoutToken_RedirectToQueue()

	local function test_ValidateRequest_NoCookie_WithoutToken_RedirectToQueue_NotargetUrl()
		userInQueueStateCookieRepositoryMock.reset()
		userInQueueStateCookieRepositoryMock.returnThisState = userInQueueStateCookieRepositoryMock.StateInfo.create(false, nil, nil, nil)

		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = false
        eventConfig.version = 10
        eventConfig.culture = null
        eventConfig.layoutName = 'testlayout'	
        local url = "http://test.test.com?b=h"   
        
		local token = ""
	
        local expectedRedirectUrl = "https://testDomain.com/?c=testCustomer&e=e1"
                .. "&ver=v3-lua-" .. userInQueueService.SDK_VERSION
                .. "&cver=10"
                .. "&l=testlayout"	
        
        local result = userInQueueService.validateQueueRequest(null, token, eventConfig, "testCustomer", key)
        
		assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
        assert( result:doRedirect() )
        assert( result.eventId == 'e1' )
        assert( result.queueId == nil )
		assert( result.redirectUrl == expectedRedirectUrl )
	end
	test_ValidateRequest_NoCookie_WithoutToken_RedirectToQueue_NotargetUrl()

    local function test_validateQueueRequest_NoCookie_InValidToken()
        userInQueueStateCookieRepositoryMock.reset()
		userInQueueStateCookieRepositoryMock.returnThisState = userInQueueStateCookieRepositoryMock.StateInfo.create(false, nil, nil, nil)
		
		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = true
        eventConfig.version = 11
        eventConfig.culture = 'en-US'
        eventConfig.layoutName = 'testlayout'
        local url = "http://test.test.com?b=h"
		        
        local token = ""
	        
        local result = userInQueueService.validateQueueRequest(url, "ts_sasa~cv_adsasa~ce_falwwwse~q_944c1f44-60dd-4e37-aabc-f3e4bb1c8895", eventConfig, "testCustomer", key)
        
		assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
        assert( result:doRedirect() )
        assert( result.eventId == 'e1' )
        assert( result.queueId == nil )
		assert( utils.startsWith(result.redirectUrl, "https://testDomain.com/error/hash/?c=testCustomer&e=e1") )
    end
	test_validateQueueRequest_NoCookie_InValidToken()

    local function test_validateCancelRequest()
		userInQueueStateCookieRepositoryMock.reset()
		userInQueueStateCookieRepositoryMock.returnThisState = userInQueueStateCookieRepositoryMock.StateInfo.create(true, "queueid", 3, "idle")

        local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.CancelEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieDomain = "testdomain"
        eventConfig.version = 10      
        local url = "http://test.test.com?b=h"
        
		local token = ""
	        
        local expectedUrl = "https://testDomain.com/cancel/testCustomer/e1/?c=testCustomer&e=e1"
			.. "&ver=v3-lua-" .. userInQueueService.SDK_VERSION
			.. "&cver=10&r=" .. utils.urlEncode(url)
        
		local result = userInQueueService.validateCancelRequest(url, eventConfig, "testCustomer", key)
		
		assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
		assert( result:doRedirect() )
        assert( result.eventId == 'e1' )
        assert( result.queueId == "queueid" )
		assert( result.redirectUrl == expectedUrl )        
    end
	test_validateCancelRequest()

	local function test_getIgnoreActionResult()
        userInQueueStateCookieRepositoryMock.reset()
        local result = userInQueueService.getIgnoreActionResult()
	
        assert( result:doRedirect() == false )
        assert( result.eventId == nil )
        assert( result.queueId == nil )
        assert( result.redirectUrl == nil )
        assert( result.actionType == "Ignore" )        
    end
	test_getIgnoreActionResult()	
end
UserInQueueServiceTest()