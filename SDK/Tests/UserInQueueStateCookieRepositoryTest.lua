local utils = require("Utils")
local userInQueueStateCookieRepository = require("UserInQueueStateCookieRepository")

-- Mocks
local iHelpers = require("KnownUserImplementationHelpers")
local mockCookies = { }
iHelpers.request.getUnescapedCookieValue = function(name)
	if (mockCookies[name] ~= nil) then
		return mockCookies[name].value
	else
		return nil
	end
end

iHelpers.response.setCookie = function(name, value, expire, domain)
	mockCookies[name] = { name=name, value=value, expire=expire, domain=domain }
end
-- END Mocks

local function UserInQueueStateCookieRepositoryTest()
	local function generateHash(eventId, queueId, fixedCookieValidityMinutes, redirectType, issueTime, secretKey)
		return iHelpers.hash.hmac_sha256_encode(
            eventId .. queueId .. utils.toString(fixedCookieValidityMinutes) .. redirectType .. issueTime, secretKey)
	end

	local function test_store_hasValidState_ExtendableCookie_CookieIsSaved()
        mockCookies = { } -- reset

		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieDomain = ".test.com"
        local queueId = "queueId"
        local cookieValidity = 10

        userInQueueStateCookieRepository.store(eventId, queueId, nil, cookieDomain, "Queue", secretKey)
        local state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)

        assert( state.isValid )
        assert( state.queueId == queueId )
        assert( state:isStateExtendable() )
		assert( state.redirectType == "Queue" )

		local cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
        assert( mockCookies[cookieKey] ~= nil )
		assert( tonumber(mockCookies[cookieKey].expire) - os.time() - 24 * 60 * 60 < 100 )
		assert( mockCookies[cookieKey].domain == cookieDomain )
    end
	test_store_hasValidState_ExtendableCookie_CookieIsSaved()

	local function test_store_hasValidState_nonExtendableCookie_CookieIsSaved()
		mockCookies = { } -- reset

		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieDomain = ".test.com"
        local queueId = "queueId"
        local cookieValidity = 3

        userInQueueStateCookieRepository.store(eventId, queueId, cookieValidity, cookieDomain, "Idle", secretKey)
        local state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)

        assert( state.isValid )
        assert( state.queueId == queueId )
        assert( state:isStateExtendable() == false )
		assert( state.redirectType == "Idle" )
		assert( state.fixedCookieValidityMinutes == 3 )

		local cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
        assert( mockCookies[cookieKey] ~= nil )
        assert( tonumber(mockCookies[cookieKey].expire) - os.time() - 24 * 60 * 60 < 100 )
		assert( mockCookies[cookieKey].domain == cookieDomain )
	end
	test_store_hasValidState_nonExtendableCookie_CookieIsSaved()

	local function test_store_hasValidState_tamperedCookie_stateIsNotValid_isCookieExtendable()
        mockCookies = { } -- reset

		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieDomain = ".test.com"
        local queueId = "queueId"
        local cookieValidity = 10

        userInQueueStateCookieRepository.store(eventId, queueId, 3, cookieDomain, "Idle", secretKey)
        local state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state.isValid )

        local cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
		local oldCookieValue = mockCookies[cookieKey].value
		mockCookies[cookieKey].value = oldCookieValue:gsub("FixedValidityMins=3", "FixedValidityMins=10")
		local state2 = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state2.isValid == false )
		assert( state:isStateExtendable() == false )
    end
	test_store_hasValidState_tamperedCookie_stateIsNotValid_isCookieExtendable()

	local function test_store_hasValidState_tamperedCookie_stateIsNotValid_eventId()
		mockCookies = { } -- reset

		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieDomain = ".test.com"
        local queueId = "queueId"
        local cookieValidity = 10

        userInQueueStateCookieRepository.store(eventId, queueId, 3, cookieDomain, "Idle", secretKey)
        local state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state.isValid )

		local cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
		local oldCookieValue = mockCookies[cookieKey].value
		mockCookies[cookieKey].value = oldCookieValue:gsub("EventId=event1", "EventId=event2")

        local state2 = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
		assert( state2.isValid == false )
		assert( state:isStateExtendable() == false )
	end
	test_store_hasValidState_tamperedCookie_stateIsNotValid_eventId()

    local function test_store_hasValidState_expiredCookie_stateIsNotValid()
        mockCookies = { } -- reset

		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieDomain = ".test.com"
        local queueId = "queueId"
		local cookieValidity = -1

        userInQueueStateCookieRepository.store(eventId, queueId, nil, cookieDomain, "Idle", secretKey)
        local state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state.isValid == false )
    end
	test_store_hasValidState_expiredCookie_stateIsNotValid()

	local function test_store_hasValidState_differentEventId_stateIsNotValid()
        mockCookies = { } -- reset

		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieDomain = ".test.com"
        local queueId = "queueId"
		local cookieValidity = 10

		userInQueueStateCookieRepository.store(eventId, queueId, nil, cookieDomain, "Queue", secretKey)
        local state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state.isValid )

        local state2 = userInQueueStateCookieRepository.getState("event2", cookieValidity, secretKey, true)
        assert( state2.isValid == false )
    end
	test_store_hasValidState_differentEventId_stateIsNotValid()

	local function test_hasValidState_noCookie_stateIsNotValid()
		mockCookies = { } -- reset

        local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieValidity = 10

        local state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state.isValid == false )
	end
	test_hasValidState_noCookie_stateIsNotValid()

    local function test_hasValidState_invalidCookie_stateIsNotValid()
        mockCookies = { } -- reset

		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieDomain = ".test.com"
        local queueId = "queueId"
        local cookieValidity = 10

        userInQueueStateCookieRepository.store(eventId, queueId, 20, cookieDomain, "Queue", secretKey)
        local state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state.isValid )

		local cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
		mockCookies[cookieKey].value = "IsCookieExtendable=ooOOO&Expires=|||&QueueId=000&Hash=23232"
        local state2 = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state2.isValid == false )
    end
	test_hasValidState_invalidCookie_stateIsNotValid()

	local function test_cancelQueueCookie()
        mockCookies = { } -- reset

		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieDomain = ".test.com"
        local queueId = "queueId"
		local cookieValidity = 20

        userInQueueStateCookieRepository.store(eventId, queueId, 20, cookieDomain, "Queue", secretKey)
        local state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state.isValid )

        userInQueueStateCookieRepository.cancelQueueCookie(eventId, cookieDomain)
        local state2 = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state2.isValid == false )

		local cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
        assert( mockCookies[cookieKey] ~= nil )
		assert( tonumber(mockCookies[cookieKey].expire) == 1 )
		assert( mockCookies[cookieKey].domain == cookieDomain )
		assert( mockCookies[cookieKey].value == "deleted" )
    end
	test_cancelQueueCookie()

    local function test_extendQueueCookie_cookieExist()
        mockCookies = { } -- reset

		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieDomain = ".test.com"
        local queueId = "queueId"
        local cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)

        userInQueueStateCookieRepository.store(eventId, queueId, nil, cookieDomain, "Queue", secretKey)
        userInQueueStateCookieRepository.reissueQueueCookie(eventId, 12, cookieDomain, secretKey)

        local state = userInQueueStateCookieRepository.getState(eventId, 5, secretKey, true)
        assert( state.isValid )
        assert( state.queueId == queueId )
        assert( state:isStateExtendable() )
		assert( tonumber(mockCookies[cookieKey].expire) - os.time() - 24 * 60 * 60 < 100 )
		assert( mockCookies[cookieKey].domain == cookieDomain )
    end
	test_extendQueueCookie_cookieExist()

	local function test_extendQueueCookie_cookieDoesNotExist()
        mockCookies = { } -- reset

		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieDomain = ".test.com"
        local queueId = "queueId"

        userInQueueStateCookieRepository.store("event2", queueId, 20, cookieDomain, "Queue", secretKey)
        userInQueueStateCookieRepository.reissueQueueCookie(eventId, 12, cookieDomain, secretKey)

		local cookieKey = userInQueueStateCookieRepository.getCookieKey("event2")
		assert( mockCookies[cookieKey] ~= nil )
    end
	test_extendQueueCookie_cookieDoesNotExist()

	local function test_getState_validCookieFormat_extendable()
		mockCookies = { } -- reset

		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieDomain = ".test.com"
        local queueId = "queueId"
		local issueTime = os.time()
		local hash = generateHash(eventId, queueId, nil, "queue", issueTime, secretKey)

        local cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
		iHelpers.response.setCookie(
            cookieKey, "EventId=" .. eventId .. "&QueueId=" .. queueId .. "&RedirectType=queue&IssueTime=" ..
            issueTime .. "&Hash=" .. hash, os.time() + (24*60*60), cookieDomain)
		local state = userInQueueStateCookieRepository.getState(eventId, 10, secretKey, true)

        assert( state:isStateExtendable() )
        assert( state.isValid )
        assert( state.isFound )
        assert( state.queueId == queueId )
		assert( state.redirectType == "queue" )
	end
	test_getState_validCookieFormat_extendable()

	local function test_getState_oldCookie_invalid_expiredCookie_extendable()
		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieDomain = ".test.com"
        local queueId = "queueId"
        local cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
		local issueTime = os.time() - (11*60)
		local hash = generateHash(eventId, queueId, nil, "queue", issueTime, secretKey)

		iHelpers.response.setCookie(
            cookieKey, "EventId=" .. eventId .. "&QueueId=" .. queueId .. "&RedirectType=queue&IssueTime=" ..
            issueTime .. "&Hash=" .. hash, os.time() + (24*60*60), cookieDomain)
		local state = userInQueueStateCookieRepository.getState(eventId, 10, secretKey, true)

        assert(state.isValid == false )
        assert(state.isFound )
	end
	test_getState_oldCookie_invalid_expiredCookie_extendable()

	local function test_getState_oldCookie_invalid_expiredCookie_nonExtendable()
		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieDomain = ".test.com"
        local queueId = "queueId"
		local issueTime = os.time() - (4*60)
		local hash = generateHash(eventId, queueId, 3, "idle", issueTime, secretKey)

        local cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
		iHelpers.response.setCookie(
            cookieKey, "EventId=" .. eventId .. "&QueueId=" .. queueId ..
            "&FixedValidityMins=3&RedirectType=idle&IssueTime=" .. issueTime ..
            "&Hash=" .. hash, os.time() + (24*60*60), cookieDomain)
		local state = userInQueueStateCookieRepository.getState(eventId, 10, secretKey, true)

        assert( state.isValid == false )
        assert( state.isFound )
	end
	test_getState_oldCookie_invalid_expiredCookie_nonExtendable()

	local function test_getState_validCookieFormat_nonExtendable()
		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        local cookieDomain = ".test.com"
        local queueId = "queueId"
		local issueTime = os.time()
		local hash = generateHash(eventId, queueId, 3, "idle", issueTime, secretKey)

        local cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
		iHelpers.response.setCookie(
            cookieKey, "EventId=" .. eventId .. "&QueueId=" .. queueId ..
            "&FixedValidityMins=3&RedirectType=idle&IssueTime=" .. issueTime ..
            "&Hash=" .. hash, os.time() + (24*60*60), cookieDomain)
		local state = userInQueueStateCookieRepository.getState(eventId, 10, secretKey, true)

		assert( state:isStateExtendable() == false )
        assert( state.isValid )
        assert( state.isFound )
        assert( state.queueId == queueId )
		assert( state.redirectType == "idle" )
	end
    test_getState_validCookieFormat_nonExtendable()

    local function test_getState_noCookie()
        mockCookies = { } -- reset

		local eventId = "event1"
        local secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"

		local state = userInQueueStateCookieRepository.getState(eventId, 10, secretKey, true)

        assert( state.isFound == false )
		assert( state.isValid  == false )
	end
	test_getState_noCookie()
end
UserInQueueStateCookieRepositoryTest()