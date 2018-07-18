-- include parent folder in package path (windows file system)
-- so all require calls to KUv3 files will work from Test folder
package.path = "..\\?.lua;" .. package.path

-- preconditions
-- INSTALL: https://luarocks.org/modules/luarocks/sha2

-- implement helpers for unit test usage
iHelpers = require("KnownUserImplementationHelpers")
iHelpers.hash.hmac_sha256_encode = function(message, key)
	local function bintohex(s)
	  return (s:gsub('(.)', function(c) 
		return string.format('%02x', string.byte(c))
	  end))
	end

	require "hmac.sha2"
	return bintohex(hmac.sha256(message, key))
end
iHelpers.json.parse = function(jsonStr)
	jsonHelper = require("JsonHelper")
	return jsonHelper.parse(jsonStr)
end

-- run tests
require("KnownUserImplementationHelpersTest")
require("QueueUrlParamsTest")
require("ComparisonOperatorHelperTest")
require("ValidationHelpersTest")
require("IntegrationEvaluatorTest")
require("UserInQueueStateCookieRepositoryTest")
require("UserInQueueServiceTest")
require("KnownUserTest")

-- this will execute if none of the above failed
print('... ALL TEST(S) PASSED ...')