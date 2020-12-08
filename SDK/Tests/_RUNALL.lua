-- Update path with parent folders so test run can find all needed lua files
package.path = "SDK/?.lua;" .. package.path
package.path = "Helpers/?/?.lua;" .. package.path
package.path = "SDK/Tests/?.lua;" .. package.path

-- implement helpers for unit test usage
local iHelpers = require("KnownUserImplementationHelpers")
iHelpers.hash.hmac_sha256_encode = function(message, key)
	local sha2 = require("sha2")
    return sha2.hmac(sha2.sha256, key, message)
end
iHelpers.json.parse = function(jsonStr)
	local json = require("json")
	return json.parse(jsonStr)
end

print("[LUA]: Running with " .. _VERSION)

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
print("[LUA]: All tests passed")