local models = require("Models")
local utils = require("Utils")
local userInQueueService = require("UserInQueueService")
local iHelpers = require("KnownUserImplementationHelpers")

-- Mocks
local userInQueueStateCookieRepositoryMock = require("UserInQueueStateCookieRepository")

userInQueueStateCookieRepositoryMock.returnThisState = {}

userInQueueStateCookieRepositoryMock.getState = function(eventId, cookieValidityMinutes, secretKey, validateTime)
	userInQueueStateCookieRepositoryMock.getStateCall = {
        eventId=eventId, cookieValidityMinutes=cookieValidityMinutes, secretKey=secretKey, validateTime=validateTime
    }
	return userInQueueStateCookieRepositoryMock.returnThisState
end

userInQueueStateCookieRepositoryMock.store = function(
    eventId, queueId, fixedCookieValidityMinutes, cookieDomain, redirectType, secretKey)

    userInQueueStateCookieRepositoryMock.storeCall = {
        eventId=eventId, queueId=queueId, fixedCookieValidityMinutes=fixedCookieValidityMinutes,
        cookieDomain=cookieDomain, redirectType=redirectType, secretKey=secretKey
    }
end

userInQueueStateCookieRepositoryMock.cancelQueueCookie = function(eventId, cookieDomain)
	userInQueueStateCookieRepositoryMock.cancelQueueCookieCall = { eventId=eventId, cookieDomain=cookieDomain}
end

userInQueueStateCookieRepositoryMock.reset = function()
	userInQueueStateCookieRepositoryMock.getStateCall = {}
    userInQueueStateCookieRepositoryMock.storeCall = {}
    userInQueueStateCookieRepositoryMock.cancelQueueCookieCall = {}
end

iHelpers.response.setCookie = function(_, _, _, _)
end
iHelpers.system.getConnectorName = function()
    return "mock-connector"
end
-- END Mocks

local function UserInQueueServiceTest()
	local function generateHash(
        eventId, queueId, timestamp, extendableCookie, cookieValidityMinutes, redirectType, secretKey)

        local token = 'e_' .. eventId .. '~ts_' .. timestamp .. '~ce_' .. extendableCookie .. '~q_' .. queueId
        if (cookieValidityMinutes ~= nil) then
            token = token .. '~cv_' .. cookieValidityMinutes
		end
        if (redirectType ~= nil) then
            token = token .. '~rt_' .. redirectType
		end

		return token .. '~h_' .. iHelpers.hash.hmac_sha256_encode(token, secretKey)
	end

	local function test_validateQueueRequest_ValidState_ExtCookie_NoCookieExtFromCfg_NoRedirectNotStoreCookieWithExt()
		userInQueueStateCookieRepositoryMock.reset()
        userInQueueStateCookieRepositoryMock.returnThisState =
            userInQueueStateCookieRepositoryMock.StateInfo.create(true, true, "queueId", nil, "idle")

		local eventConfig = models.QueueEventConfig.create()
		eventConfig.eventId = "e1"
		eventConfig.queueDomain = "testDomain"
		eventConfig.cookieDomain = "testDomain"
		eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = false
        eventConfig.actionName = "QueueAction"

		local result = userInQueueService.validateQueueRequest("url", "token", eventConfig, "customerid", "key")

		assert( result:doRedirect() == false )
        assert( result.queueId == "queueId" )

		assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
		assert( userInQueueStateCookieRepositoryMock.getStateCall.eventId == "e1" )
		assert( userInQueueStateCookieRepositoryMock.getStateCall.cookieValidityMinutes == 10 )
		assert( userInQueueStateCookieRepositoryMock.getStateCall.secretKey == "key" )
        assert( userInQueueStateCookieRepositoryMock.getStateCall.validateTime == true )
        assert( next(userInQueueStateCookieRepositoryMock.cancelQueueCookieCall) == nil )
        assert( result.actionName == eventConfig.actionName )
    end
	test_validateQueueRequest_ValidState_ExtCookie_NoCookieExtFromCfg_NoRedirectNotStoreCookieWithExt()

	local function test_validateQueueRequest_ValidState_ExtCookie_CookieExtFromCfg_NoRedirectStoreCookieWithExtension()
        userInQueueStateCookieRepositoryMock.reset()
        userInQueueStateCookieRepositoryMock.returnThisState =
            userInQueueStateCookieRepositoryMock.StateInfo.create(true, true, "queueId", nil, "disabled")

		local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieDomain = "testDomain"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = true
        eventConfig.actionName = "QueueAction"

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
        assert( next(userInQueueStateCookieRepositoryMock.cancelQueueCookieCall) == nil )
        assert( result.actionName == eventConfig.actionName )
    end
	test_validateQueueRequest_ValidState_ExtCookie_CookieExtFromCfg_NoRedirectStoreCookieWithExtension()

    local function test_validateQueueRequest_ValidState_NoExtendableCookie_DoNotRedirectDoNotStoreCookieWithExtension()
        userInQueueStateCookieRepositoryMock.reset()
        userInQueueStateCookieRepositoryMock.returnThisState =
            userInQueueStateCookieRepositoryMock.StateInfo.create(true, true, "queueId", 3, "idle")

		local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = true
        eventConfig.actionName = "QueueAction"

        local result = userInQueueService.validateQueueRequest("url", "token", eventConfig, "customerid", "key")

		assert( result:doRedirect() == false )
        assert( result.eventId == 'e1' )
        assert( result.queueId == "queueId" )
		assert( result.actionName == eventConfig.actionName )
        assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
        assert( next(userInQueueStateCookieRepositoryMock.cancelQueueCookieCall) == nil )
    end
	test_validateQueueRequest_ValidState_NoExtendableCookie_DoNotRedirectDoNotStoreCookieWithExtension()

	local function test_validateQueueRequest_NoCookie_TampredToken_RedirectToErrorPageWithHashError_DoNotStoreCookie()
        userInQueueStateCookieRepositoryMock.reset()
        userInQueueStateCookieRepositoryMock.returnThisState =
            userInQueueStateCookieRepositoryMock.StateInfo.create(false, false, nil, nil, nil)

		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = true
        eventConfig.version = 11
        eventConfig.actionName = "QueueAction"
        local url = "http://test.test.com?b=h"

        local token = generateHash('e1','queueId', os.time() + (3 * 60), 'False', nil, 'idle', key)
		token = token:gsub("False", "True")

        local expectedErrorUrl = "https://testDomain.com/error/hash/?c=testCustomer&e=e1"
                .. "&ver=" .. userInQueueService.SDK_VERSION
                .. "&kupver=mock-connector"
                .. "&cver=11"
                .. "&man=" .. eventConfig.actionName
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
        assert( next(userInQueueStateCookieRepositoryMock.cancelQueueCookieCall) == nil )
    end
	test_validateQueueRequest_NoCookie_TampredToken_RedirectToErrorPageWithHashError_DoNotStoreCookie()

    local function test_validateQueueRequest_NoCookie_ExpiredTSInToken_RedirectToErrorPageWithTSError_DoNotStoreCookie()
        userInQueueStateCookieRepositoryMock.reset()
        userInQueueStateCookieRepositoryMock.returnThisState =
            userInQueueStateCookieRepositoryMock.StateInfo.create(false, false, nil, nil, nil)

		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = false
        eventConfig.version = 11
        eventConfig.actionName = "QueueAction"
        local url = "http://test.test.com?b=h"

		local token = generateHash('e1','queueId', os.time() - (3 * 60), 'False', nil, 'queue', key)

		local expectedErrorUrl = "https://testDomain.com/error/timestamp/?c=testCustomer&e=e1"
                .. "&ver=" .. userInQueueService.SDK_VERSION
                .. "&kupver=mock-connector"
                .. "&cver=11"
                .. "&man=" .. eventConfig.actionName
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
        assert( next(userInQueueStateCookieRepositoryMock.cancelQueueCookieCall) == nil )
    end
	test_validateQueueRequest_NoCookie_ExpiredTSInToken_RedirectToErrorPageWithTSError_DoNotStoreCookie()

    local function test_validateQueueRequest_NoCookie_EventMismatch_RedirectToErrorPageWithEventError_DontStoreCookie()
        userInQueueStateCookieRepositoryMock.reset()
        userInQueueStateCookieRepositoryMock.returnThisState =
            userInQueueStateCookieRepositoryMock.StateInfo.create(false, false, nil, nil, nil)

		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e2"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = true
        eventConfig.version = 11
        eventConfig.actionName = "QueueAction"
        local url = "http://test.test.com?b=h"

		local token = generateHash('e1', 'queueId', os.time() - (3 * 60), 'False', nil, 'queue', key)

		local expectedErrorUrl = "https://testDomain.com/error/eventid/?c=testCustomer&e=e2"
                .. "&ver=" .. userInQueueService.SDK_VERSION
                .. "&kupver=mock-connector"
                .. "&cver=11"
                .. "&man=" .. eventConfig.actionName
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
        assert( next(userInQueueStateCookieRepositoryMock.cancelQueueCookieCall) == nil )
    end
	test_validateQueueRequest_NoCookie_EventMismatch_RedirectToErrorPageWithEventError_DontStoreCookie()

    local function test_validateQueueRequest_NoCookie_ValidToken_ExtendableCookie_DoNotRedirect_StoreExtendableCookie()
        userInQueueStateCookieRepositoryMock.reset()
        userInQueueStateCookieRepositoryMock.returnThisState =
            userInQueueStateCookieRepositoryMock.StateInfo.create(false, false, nil, nil, nil)

		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.cookieDomain = "testDomain"
        eventConfig.extendCookieValidity = true
        eventConfig.version = 11
        eventConfig.actionName = "QueueAction"

        local url = "http://test.test.com?b=h"

        local token = generateHash('e1', 'queueId', os.time() + (3 * 60), 'true', nil, 'queue', key)

        local result = userInQueueService.validateQueueRequest(url, token, eventConfig, "testCustomer", key)
        assert( result:doRedirect() == false )
        assert( result.eventId == 'e1' )
        assert( result.queueId == 'queueId' )
		assert( result.redirectType == 'queue' )
        assert( result.actionName == eventConfig.actionName )
		assert( next(userInQueueStateCookieRepositoryMock.storeCall) ~= nil )
		assert( userInQueueStateCookieRepositoryMock.storeCall.eventId == "e1" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.queueId == "queueId" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.fixedCookieValidityMinutes == nil )
		assert( userInQueueStateCookieRepositoryMock.storeCall.cookieDomain == "testDomain" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.redirectType == "queue" )
        assert( userInQueueStateCookieRepositoryMock.storeCall.secretKey == key )
        assert( next(userInQueueStateCookieRepositoryMock.cancelQueueCookieCall) == nil )
    end
	test_validateQueueRequest_NoCookie_ValidToken_ExtendableCookie_DoNotRedirect_StoreExtendableCookie()

    local function test_validateQueueRequest_NoCookie_ValidToken_CookieValMinToken_NoRedirect_StoreNonExtendableCookie()
        userInQueueStateCookieRepositoryMock.reset()
        userInQueueStateCookieRepositoryMock.returnThisState =
            userInQueueStateCookieRepositoryMock.StateInfo.create(false, false, nil, nil, nil)

		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 30
        eventConfig.cookieDomain = "testDomain"
        eventConfig.extendCookieValidity = true
        eventConfig.version = 11
        eventConfig.actionName = "QueueAction"
        local url = "http://test.test.com?b=h"

        local token = generateHash('e1', 'queueId', os.time() + (3 * 60), 'false', 3, 'DirectLink', key)

        local result = userInQueueService.validateQueueRequest(url, token, eventConfig, "testCustomer", key)
        assert( result:doRedirect() == false )
        assert( result.eventId == 'e1' )
        assert( result.queueId == 'queueId' )
        assert( result.redirectType == 'DirectLink' )
        assert( result.actionName == eventConfig.actionName )

		assert( next(userInQueueStateCookieRepositoryMock.storeCall) ~= nil )
		assert( userInQueueStateCookieRepositoryMock.storeCall.eventId == "e1" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.queueId == "queueId" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.fixedCookieValidityMinutes == 3 )
		assert( userInQueueStateCookieRepositoryMock.storeCall.cookieDomain == "testDomain" )
		assert( userInQueueStateCookieRepositoryMock.storeCall.redirectType == "DirectLink" )
        assert( userInQueueStateCookieRepositoryMock.storeCall.secretKey == key )
        assert( next(userInQueueStateCookieRepositoryMock.cancelQueueCookieCall) == nil )
    end
	test_validateQueueRequest_NoCookie_ValidToken_CookieValMinToken_NoRedirect_StoreNonExtendableCookie()

    local function test_NoCookie_NoValidToken_WithoutToken_RedirectToQueue()
        userInQueueStateCookieRepositoryMock.reset()
        userInQueueStateCookieRepositoryMock.returnThisState =
            userInQueueStateCookieRepositoryMock.StateInfo.create(false, false, nil, nil, nil)

		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = true
        eventConfig.version = 11
        eventConfig.culture = 'en-US'
        eventConfig.layoutName = 'testlayout'
        eventConfig.actionName = "Queue Action (._~-) !*|'\""
        local url = "http://test.test.com?b=h"

        local token = ""

        local expectedRedirectUrl = "https://testDomain.com/?c=testCustomer&e=e1"
                .. "&ver=" .. userInQueueService.SDK_VERSION
                .. "&kupver=mock-connector"
                .. "&cver=11"
                .. "&man=Queue%20Action%20%28._~-%29%20%21%2A%7C%27%22"
                .. "&cid=en-US"
                .. "&l=testlayout"
                .. "&t=" .. utils.urlEncode(url)

        local result = userInQueueService.validateQueueRequest(url, token, eventConfig, "testCustomer", key)

		assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
        assert( result:doRedirect() )
        assert( result.eventId == 'e1' )
        assert( result.queueId == nil )
        assert( result.redirectUrl == expectedRedirectUrl )
        assert( next(userInQueueStateCookieRepositoryMock.cancelQueueCookieCall) == nil )
    end
	test_NoCookie_NoValidToken_WithoutToken_RedirectToQueue()

	local function test_ValidateRequest_NoCookie_WithoutToken_RedirectToQueue_NotargetUrl()
		userInQueueStateCookieRepositoryMock.reset()
        userInQueueStateCookieRepositoryMock.returnThisState =
            userInQueueStateCookieRepositoryMock.StateInfo.create(false, false, nil, nil, nil)

		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = false
        eventConfig.version = 10
        eventConfig.culture = nil
        eventConfig.layoutName = 'testlayout'
        eventConfig.actionName = "QueueAction"

		local token = ""

        local expectedRedirectUrl = "https://testDomain.com/?c=testCustomer&e=e1"
                .. "&ver=" .. userInQueueService.SDK_VERSION
                .. "&kupver=mock-connector"
                .. "&cver=10"
                .. "&man=" .. eventConfig.actionName
                .. "&l=testlayout"

        local result = userInQueueService.validateQueueRequest(nil, token, eventConfig, "testCustomer", key)

		assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
        assert( result:doRedirect() )
        assert( result.eventId == 'e1' )
        assert( result.queueId == nil )
        assert( result.redirectUrl == expectedRedirectUrl )
        assert( next(userInQueueStateCookieRepositoryMock.cancelQueueCookieCall) == nil )
	end
    test_ValidateRequest_NoCookie_WithoutToken_RedirectToQueue_NotargetUrl()

    local function test_validateQueueRequest_InvalidCookie_InvalidToken_CancelCookie()
        userInQueueStateCookieRepositoryMock.reset()
        userInQueueStateCookieRepositoryMock.returnThisState =
            userInQueueStateCookieRepositoryMock.StateInfo.create(true, false, nil, nil, nil)

		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = true
        eventConfig.version = 11
        eventConfig.culture = 'en-US'
        eventConfig.layoutName = 'testlayout'
        eventConfig.actionName = "QueueAction"
        local url = "http://test.test.com?b=h"

        local result = userInQueueService.validateQueueRequest(
            url, "ts_sasa~cv_adsasa~ce_falwwwse~q_944c1f44-60dd-4e37-aabc-f3e4bb1c8895",
            eventConfig, "testCustomer", key)

		assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
        assert( result:doRedirect() )
        assert( result.eventId == 'e1' )
        assert( result.queueId == nil )
        assert( result.actionName == eventConfig.actionName )
        assert( utils.startsWith(result.redirectUrl, "https://testDomain.com/error/hash/?c=testCustomer&e=e1") )
        assert( next(userInQueueStateCookieRepositoryMock.cancelQueueCookieCall) ~= nil )
    end
	test_validateQueueRequest_InvalidCookie_InvalidToken_CancelCookie()

    local function test_validateQueueRequest_NoCookie_InvalidToken()
        userInQueueStateCookieRepositoryMock.reset()
        userInQueueStateCookieRepositoryMock.returnThisState =
            userInQueueStateCookieRepositoryMock.StateInfo.create(false, false, nil, nil, nil)

		local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.QueueEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieValidityMinute = 10
        eventConfig.extendCookieValidity = true
        eventConfig.version = 11
        eventConfig.culture = 'en-US'
        eventConfig.layoutName = 'testlayout'
        eventConfig.actionName = "QueueAction"
        local url = "http://test.test.com?b=h"

        local result = userInQueueService.validateQueueRequest(
            url, "ts_sasa~cv_adsasa~ce_falwwwse~q_944c1f44-60dd-4e37-aabc-f3e4bb1c8895",
            eventConfig, "testCustomer", key)

		assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
        assert( result:doRedirect() )
        assert( result.eventId == 'e1' )
        assert( result.queueId == nil )
        assert( result.actionName == eventConfig.actionName )
        assert( utils.startsWith(result.redirectUrl, "https://testDomain.com/error/hash/?c=testCustomer&e=e1") )
        assert( next(userInQueueStateCookieRepositoryMock.cancelQueueCookieCall) == nil )
    end
    test_validateQueueRequest_NoCookie_InvalidToken()

    local function test_validateCancelRequest()
		userInQueueStateCookieRepositoryMock.reset()
        userInQueueStateCookieRepositoryMock.returnThisState =
            userInQueueStateCookieRepositoryMock.StateInfo.create(true, true, "queueid", 3, "idle")

        local key = "4e1db821-a825-49da-acd0-5d376f2068db"
        local eventConfig = models.CancelEventConfig.create()
        eventConfig.eventId = "e1"
        eventConfig.queueDomain = "testDomain.com"
        eventConfig.cookieDomain = "testdomain"
        eventConfig.version = 10
        eventConfig.actionName = "CancelAction"
        local url = "http://test.test.com?b=h"

		local expectedUrl = "https://testDomain.com/cancel/testCustomer/e1/?c=testCustomer&e=e1"
            .. "&ver=" .. userInQueueService.SDK_VERSION
            .. "&kupver=mock-connector"
            .. "&cver=10&man=" .. eventConfig.actionName
            .. "&r=" .. utils.urlEncode(url)

		local result = userInQueueService.validateCancelRequest(url, eventConfig, "testCustomer", key)

		assert( next(userInQueueStateCookieRepositoryMock.storeCall) == nil )
		assert( result:doRedirect() )
        assert( result.eventId == 'e1' )
        assert( result.queueId == "queueid" )
        assert( result.actionName == eventConfig.actionName )
        assert( result.redirectUrl == expectedUrl )
        assert( next(userInQueueStateCookieRepositoryMock.cancelQueueCookieCall) ~= nil )
    end
	test_validateCancelRequest()

	local function test_getIgnoreActionResult()
        userInQueueStateCookieRepositoryMock.reset()
        local result = userInQueueService.getIgnoreActionResult("IgnoreAction")

        assert( result:doRedirect() == false )
        assert( result.eventId == nil )
        assert( result.queueId == nil )
        assert( result.redirectUrl == nil )
        assert( result.actionType == "Ignore" )
        assert( result.actionName == "IgnoreAction" )
    end
	test_getIgnoreActionResult()
end
UserInQueueServiceTest()