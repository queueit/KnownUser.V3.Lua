local utils = require("Utils")
local iHelpers = require("KnownUserImplementationHelpers")

-- Private functions
local function generateHash(eventId, queueId, fixedCookieValidityMinutes, redirectType, issueTime, secretKey)
	local message = eventId .. queueId .. fixedCookieValidityMinutes .. redirectType .. issueTime
	return iHelpers.hash.hmac_sha256_encode(message, secretKey)
end

local function createCookieValue(eventId, queueId, fixedCookieValidityMinutes, redirectType, secretKey)
	local issueTime = os.time()
	local hashValue = generateHash(eventId, queueId, fixedCookieValidityMinutes, redirectType, issueTime, secretKey)

	local fixedCookieValidityMinutesPart = ""
	if (fixedCookieValidityMinutes ~= "") then
		fixedCookieValidityMinutesPart = "&FixedValidityMins=" .. fixedCookieValidityMinutes
	end

	local cookieValue = "EventId=" .. eventId ..
		"&QueueId=" .. queueId .. fixedCookieValidityMinutesPart ..
		"&RedirectType=" .. redirectType .. "&IssueTime=" .. issueTime .. "&Hash=" .. hashValue
	return cookieValue
end

local function getCookieNameValueMap(cookieValue)
	local result = { }

	local cookieNameValues = utils.explode("&", cookieValue)

	for _, cookieNameValue in pairs(cookieNameValues) do
		local arr = utils.explode("=", cookieNameValue)
		if(arr[1] ~= nil and arr[2] ~= nil) then
			result[arr[1]] = arr[2]
		end
	end

	return result
end

local function isCookieValid(secretKey, cookieNameValueMap, eventId, cookieValidityMinutes, validateTime)
	if (cookieNameValueMap["EventId"] == nil) then
		return false
	end
	if (cookieNameValueMap["QueueId"] == nil) then
		return false
	end
	if (cookieNameValueMap["RedirectType"] == nil) then
		return false
	end
	if (cookieNameValueMap["IssueTime"] == nil) then
		return false
	end
	if (cookieNameValueMap["Hash"] == nil) then
		return false
	end

	local fixedCookieValidityMinutes = ""
	if (cookieNameValueMap["FixedValidityMins"] ~= nil) then
		fixedCookieValidityMinutes = cookieNameValueMap["FixedValidityMins"]
	end

	local hashValue = generateHash(
		cookieNameValueMap["EventId"],
		cookieNameValueMap["QueueId"],
		fixedCookieValidityMinutes,
		cookieNameValueMap["RedirectType"],
		cookieNameValueMap["IssueTime"],
		secretKey)

	if (hashValue ~= cookieNameValueMap["Hash"]) then
		return false
	end

	if (string.lower(eventId) ~= string.lower(cookieNameValueMap["EventId"])) then
		return false
	end

	if (validateTime) then
		local validity = cookieValidityMinutes
		if (utils.toString(fixedCookieValidityMinutes) ~= "") then
			validity = tonumber(fixedCookieValidityMinutes)
		end

		local expirationTime = cookieNameValueMap["IssueTime"] + (validity*60)
		if (expirationTime < os.time()) then
			return false
		end
	end

	return true
end
-- END Private functions

local repo = {
	StateInfo = {
		create = function(isFound, isValid, queueId, fixedCookieValidityMinutes, redirectType)
			local model = {
				isFound = isFound,
				isValid = isValid,
				queueId = queueId,
				fixedCookieValidityMinutes = fixedCookieValidityMinutes,
				redirectType = redirectType,
				isStateExtendable = function(self)
					return self.isValid and self.fixedCookieValidityMinutes == nil
				end
			}
			return model
		end
	}
}

repo.getCookieKey = function(eventId)
	return "QueueITAccepted-SDFrts345E-V3_" .. eventId
end

repo.cancelQueueCookie = function(eventId, cookieDomain)
	local cookieKey = repo.getCookieKey(eventId)
	iHelpers.response.setCookie(cookieKey, "deleted", 1, cookieDomain)
end

repo.getState = function(eventId, cookieValidityMinutes, secretKey, validateTime)
	local pcall_status, pcall_result = pcall(function()
		local cookieKey = repo.getCookieKey(eventId)
		if (iHelpers.request.getUnescapedCookieValue(cookieKey) == nil) then
			return repo.StateInfo.create(false, false, nil, nil, nil)
		end
		local cookieNameValueMap = getCookieNameValueMap(iHelpers.request.getUnescapedCookieValue(cookieKey))

		if (isCookieValid(secretKey, cookieNameValueMap, eventId, cookieValidityMinutes, validateTime) == false) then
			return repo.StateInfo.create(true, false, nil, nil, nil)
		end

		local fixedCookieValidityMinutes = nil
		if (cookieNameValueMap["FixedValidityMins"] ~= nil) then
			fixedCookieValidityMinutes = tonumber(cookieNameValueMap["FixedValidityMins"])
		end

		return repo.StateInfo.create(
			true,
			true,
			cookieNameValueMap["QueueId"],
			fixedCookieValidityMinutes,
			cookieNameValueMap["RedirectType"]
		)
	end)

	if (pcall_status) then
		return pcall_result
	end

	return repo.StateInfo.create(true, false, nil, nil, nil)
end

repo.reissueQueueCookie = function(eventId, cookieValidityMinutes, cookieDomain, secretKey)
	local cookieKey = repo.getCookieKey(eventId)
	if (iHelpers.request.getUnescapedCookieValue(cookieKey) == nil) then
		return
	end
	local cookieNameValueMap = getCookieNameValueMap(iHelpers.request.getUnescapedCookieValue(cookieKey))

	if (isCookieValid(secretKey, cookieNameValueMap, eventId, cookieValidityMinutes, true) == false) then
		return
	end
	local fixedCookieValidityMinutes = ""
	if (cookieNameValueMap["FixedValidityMins"] ~= nil) then
		fixedCookieValidityMinutes = cookieNameValueMap["FixedValidityMins"]
	end

	local cookieValue = createCookieValue(
		eventId,
		cookieNameValueMap["QueueId"],
		fixedCookieValidityMinutes,
		cookieNameValueMap["RedirectType"],
		secretKey)

	iHelpers.response.setCookie(cookieKey, cookieValue, os.time() + (24 * 60 * 60), cookieDomain)
end

repo.store = function(eventId, queueId, fixedCookieValidityMinutes, cookieDomain, redirectType, secretKey)
	local cookieKey = repo.getCookieKey(eventId)
	local cookieValue = createCookieValue(
		eventId, queueId, utils.toString(fixedCookieValidityMinutes), redirectType, secretKey)
	iHelpers.response.setCookie(cookieKey, cookieValue, os.time() + (24 * 60 * 60), cookieDomain)
end

return repo
