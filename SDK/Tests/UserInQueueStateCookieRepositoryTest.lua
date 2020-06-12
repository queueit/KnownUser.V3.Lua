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

function UserInQueueStateCookieRepositoryTest()
	local function generateHash(eventId, queueId, fixedCookieValidityMinutes, redirectType, issueTime, secretKey)
		return iHelpers.hash.hmac_sha256_encode(eventId .. queueId .. utils.toString(fixedCookieValidityMinutes) .. redirectType .. issueTime, secretKey)
	end
		
	local function test_store_hasValidState_ExtendableCookie_CookieIsSaved()
        mockCookies = { } -- reset

		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
        cookieValidity = 10
	
        userInQueueStateCookieRepository.store(eventId, queueId, nil, cookieDomain, "Queue", secretKey)
        state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
	
        assert( state.isValid )
        assert( state.queueId == queueId )
        assert( state:isStateExtendable() )
		assert( state.redirectType == "Queue" )
        
		cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
        assert( mockCookies[cookieKey] ~= nil )
		assert( tonumber(mockCookies[cookieKey].expire) - os.time() - 24 * 60 * 60 < 100 )
		assert( mockCookies[cookieKey].domain == cookieDomain )
    end
	test_store_hasValidState_ExtendableCookie_CookieIsSaved()

	local function test_store_hasValidState_nonExtendableCookie_CookieIsSaved()
		mockCookies = { } -- reset

		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
        cookieValidity = 3
        
        userInQueueStateCookieRepository.store(eventId, queueId, cookieValidity, cookieDomain, "Idle", secretKey)
        state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
	
        assert( state.isValid )
        assert( state.queueId == queueId )
        assert( state:isStateExtendable() == false )
		assert( state.redirectType == "Idle" )
		assert( state.fixedCookieValidityMinutes == 3 )
		
		cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
        assert( mockCookies[cookieKey] ~= nil )
        assert( tonumber(mockCookies[cookieKey].expire) - os.time() - 24 * 60 * 60 < 100 )
		assert( mockCookies[cookieKey].domain == cookieDomain )
	end
	test_store_hasValidState_nonExtendableCookie_CookieIsSaved()

	local function test_store_hasValidState_tamperedCookie_stateIsNotValid_isCookieExtendable()
        mockCookies = { } -- reset

		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
        cookieValidity = 10
        
        userInQueueStateCookieRepository.store(eventId, queueId, 3, cookieDomain, "Idle", secretKey)
        state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state.isValid )
	
        cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
		oldCookieValue = mockCookies[cookieKey].value
		mockCookies[cookieKey].value = oldCookieValue:gsub("FixedValidityMins=3", "FixedValidityMins=10")
		state2 = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state2.isValid == false )
		assert( state:isStateExtendable() == false )
    end
	test_store_hasValidState_tamperedCookie_stateIsNotValid_isCookieExtendable()

	local function test_store_hasValidState_tamperedCookie_stateIsNotValid_eventId()
		mockCookies = { } -- reset
		
		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
        cookieValidity = 10
        
        userInQueueStateCookieRepository.store(eventId, queueId, 3, cookieDomain, "Idle", secretKey)
        state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state.isValid )
	
		cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
		oldCookieValue = mockCookies[cookieKey].value
		mockCookies[cookieKey].value = oldCookieValue:gsub("EventId=event1", "EventId=event2")

        state2 = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
		assert( state2.isValid == false )
		assert( state:isStateExtendable() == false )
	end
	test_store_hasValidState_tamperedCookie_stateIsNotValid_eventId()
	
    local function test_store_hasValidState_expiredCookie_stateIsNotValid()
        mockCookies = { } -- reset
		
		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
		cookieValidity = -1
        
        userInQueueStateCookieRepository.store(eventId, queueId, nil, cookieDomain, "Idle", secretKey)
        state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state.isValid == false )
    end
	test_store_hasValidState_expiredCookie_stateIsNotValid()

	local function test_store_hasValidState_differentEventId_stateIsNotValid()
        mockCookies = { } -- reset
		
		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
		cookieValidity = 10	

		userInQueueStateCookieRepository.store(eventId, queueId, nil, cookieDomain, "Queue", secretKey)
        state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state.isValid )
	
        state2 = userInQueueStateCookieRepository.getState("event2", cookieValidity, secretKey, true)
        assert( state2.isValid == false )
    end
	test_store_hasValidState_differentEventId_stateIsNotValid()
	
	local function test_hasValidState_noCookie_stateIsNotValid()
		mockCookies = { } -- reset
		
		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
        cookieKey = "key"
		cookieValidity = 10

        state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state.isValid == false )	
	end
	test_hasValidState_noCookie_stateIsNotValid()

    local function test_hasValidState_invalidCookie_stateIsNotValid()
        mockCookies = { } -- reset
		
		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
        cookieValidity = 10

        userInQueueStateCookieRepository.store(eventId, queueId, 20, cookieDomain, "Queue", secretKey)
        state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state.isValid )
	
		cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)		
		mockCookies[cookieKey].value = "IsCookieExtendable=ooOOO&Expires=|||&QueueId=000&Hash=23232"
        assert( state2.isValid == false )
    end
	test_hasValidState_invalidCookie_stateIsNotValid()

	local function test_cancelQueueCookie()
        mockCookies = { } -- reset
		
		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
		cookieValidity = 20
               
        userInQueueStateCookieRepository.store(eventId, queueId, 20, cookieDomain, "Queue", secretKey)
        state = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state.isValid )
	
        userInQueueStateCookieRepository.cancelQueueCookie(eventId, cookieDomain)
        state2 = userInQueueStateCookieRepository.getState(eventId, cookieValidity, secretKey, true)
        assert( state2.isValid == false )
	
		cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
        assert( mockCookies[cookieKey] ~= nil )
		assert( tonumber(mockCookies[cookieKey].expire) == 1 )
		assert( mockCookies[cookieKey].domain == cookieDomain )
		assert( mockCookies[cookieKey].value == "deleted" )
    end
	test_cancelQueueCookie()
	
    local function test_extendQueueCookie_cookieExist()
        mockCookies = { } -- reset
		
		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
        cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
	
        userInQueueStateCookieRepository.store(eventId, queueId, nil, cookieDomain, "Queue", secretKey)
        userInQueueStateCookieRepository.reissueQueueCookie(eventId, 12, cookieDomain, secretKey)
	
        state = userInQueueStateCookieRepository.getState(eventId, 5, secretKey, true)
        assert( state.isValid )
        assert( state.queueId == queueId )
        assert( state:isStateExtendable() )
		assert( tonumber(mockCookies[cookieKey].expire) - os.time() - 24 * 60 * 60 < 100 )
		assert( mockCookies[cookieKey].domain == cookieDomain )
    end
	test_extendQueueCookie_cookieExist()

	local function test_extendQueueCookie_cookieDoesNotExist()
        mockCookies = { } -- reset
		
		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
	
        userInQueueStateCookieRepository.store("event2", queueId, 20, cookieDomain, "Queue", secretKey)
        userInQueueStateCookieRepository.reissueQueueCookie(eventId, 12, cookieDomain, secretKey)
        
		cookieKey = userInQueueStateCookieRepository.getCookieKey("event2")
		assert( mockCookies[cookieKey] ~= nil )
    end
	test_extendQueueCookie_cookieDoesNotExist()
	
	local function test_getState_validCookieFormat_extendable()
		mockCookies = { } -- reset

		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
		issueTime = os.time()
		hash = generateHash(eventId, queueId, nil, "queue", issueTime, secretKey)

        cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
		iHelpers.response.setCookie(cookieKey, "EventId=" .. eventId .. "&QueueId=" .. queueId .. "&RedirectType=queue&IssueTime=" .. issueTime .. "&Hash=" .. hash, os.time() + (24*60*60), cookieDomain)
		state = userInQueueStateCookieRepository.getState(eventId, 10, secretKey, true)

        assert( state:isStateExtendable() )
        assert( state.isValid )
        assert( state.isFound )        
        assert( state.queueId == queueId )
		assert( state.redirectType == "queue" )
	end
	test_getState_validCookieFormat_extendable()
	
	local function test_getState_oldCookie_invalid_expiredCookie_extendable()
		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
        cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
		issueTime = os.time() - (11*60)
		hash = generateHash(eventId, queueId, nil, "queue", issueTime, secretKey)

		iHelpers.response.setCookie(cookieKey, "EventId=" .. eventId .. "&QueueId=" .. queueId .. "&RedirectType=queue&IssueTime=" .. issueTime .. "&Hash=" .. hash, os.time() + (24*60*60), cookieDomain)
		state = userInQueueStateCookieRepository.getState(eventId, 10, secretKey, true)

        assert(state.isValid == false )
        assert(state.isFound )
	end
	test_getState_oldCookie_invalid_expiredCookie_extendable()
	
	local function test_getState_oldCookie_invalid_expiredCookie_nonExtendable()
		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
		issueTime = os.time() - (4*60)
		hash = generateHash(eventId, queueId, 3, "idle", issueTime, secretKey)

        cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
		iHelpers.response.setCookie(cookieKey, "EventId=" .. eventId .. "&QueueId=" .. queueId .. "&FixedValidityMins=3&RedirectType=idle&IssueTime=" .. issueTime .. "&Hash=" .. hash, os.time() + (24*60*60), cookieDomain)
		state = userInQueueStateCookieRepository.getState(eventId, 10, secretKey, true)

        assert( state.isValid == false )
        assert( state.isFound )
	end
	test_getState_oldCookie_invalid_expiredCookie_nonExtendable()

	local function test_getState_validCookieFormat_nonExtendable()
		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        cookieDomain = ".test.com"
        queueId = "queueId"
		issueTime = os.time()
		hash = generateHash(eventId, queueId, 3, "idle", issueTime, secretKey)
		
        cookieKey = userInQueueStateCookieRepository.getCookieKey(eventId)
		iHelpers.response.setCookie(cookieKey, "EventId=" .. eventId .. "&QueueId=" .. queueId .. "&FixedValidityMins=3&RedirectType=idle&IssueTime=" .. issueTime .. "&Hash=" .. hash, os.time() + (24*60*60), cookieDomain)
		state = userInQueueStateCookieRepository.getState(eventId, 10, secretKey, true)

		assert( state:isStateExtendable() == false )
        assert( state.isValid )
        assert( state.isFound )
        assert( state.queueId == queueId )
		assert( state.redirectType == "idle" )
	end
    test_getState_validCookieFormat_nonExtendable()	

    local function test_getState_noCookie()
        mockCookies = { } -- reset

		eventId = "event1"
        secretKey = "4e1deweb821-a82ew5-49da-acdqq0-5d3476f2068db"
        
		state = userInQueueStateCookieRepository.getState(eventId, 10, secretKey, true)

        assert( state.isFound == false )
		assert( state.isValid  == false )
	end
	test_getState_noCookie()	
end
UserInQueueStateCookieRepositoryTest()