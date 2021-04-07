local validatorHelpers = require("ValidatorHelpers")
local iHelpers = require("KnownUserImplementationHelpers")

local function UrlValidatorHelperTest_evaluate()
	local triggerPart = {}

	triggerPart["UrlPart"] = "PageUrl"
	triggerPart["Operator"] = "Contains"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = false
	triggerPart["ValueToCompare"] = "http://test.tesdomain.com:8080/test?q=1"
	assert( validatorHelpers.UrlValidatorHelper.evaluate(
		triggerPart, "http://test.tesdomain.com:8080/test?q=2") == false )

	triggerPart["UrlPart"] = "PageUrl"
	triggerPart["Operator"] = "Contains"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = false
	triggerPart["ValueToCompare"] =
		"%http://test.tesdomain.com:8080/test/resource.lua?queue-event1-nodomain?q=%().+-*?[]^$"
	assert( validatorHelpers.UrlValidatorHelper.evaluate(
		triggerPart, "%http://test.tesdomain.com:8080/test/resource.lua?queue-event1-nodomain?q=%().+-*?[]^$") )

	triggerPart["UrlPart"] = "PageUrl"
	triggerPart["Operator"] = "Equals"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = false
	triggerPart["ValueToCompare"] =
		"%http://test.tesdomain.com:8080/test/resource.lua?queue-event1-nodomain?q=%().+-*?[]^$"
	assert( validatorHelpers.UrlValidatorHelper.evaluate(
		triggerPart, "%http://test.tesdomain.com:8080/test/resource.lua?queue-event1-nodomain?q=%().+-*?[]^$") )

	triggerPart["ValueToCompare"] = "/Test/t1"
	triggerPart["UrlPart"] = "PagePath"
	triggerPart["Operator"]= "Equals"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = false
	assert( validatorHelpers.UrlValidatorHelper.evaluate(
		triggerPart, "http://test.tesdomain.com:8080/test/t1?q=2&y02&v=%().+-*?[]^$") )

	triggerPart["ValueToCompare"] = "/Test/t1"
	triggerPart["UrlPart"] = "PagePath"
	triggerPart["Operator"]= "Equals"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = false
	assert( validatorHelpers.UrlValidatorHelper.evaluate(
		triggerPart, "http://test.tesdomain.com:8080/test/t1?q=2&y02&v=%().+-*[]^$") )

	triggerPart["ValueToCompare"] = "/Test/t1"
	triggerPart["UrlPart"] = "PagePath"
	triggerPart["Operator"]= "Equals"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = false
	assert( validatorHelpers.UrlValidatorHelper.evaluate(
		triggerPart, "http://test.tesdomain.com:8080/test/t1") )

	triggerPart["ValueToCompare"] = ""
	triggerPart["UrlPart"] = "PagePath"
	triggerPart["Operator"]= "Equals"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = false
	assert( validatorHelpers.UrlValidatorHelper.evaluate(
		triggerPart, "http://test.tesdomain.com:8080") )

	triggerPart["UrlPart"] = "HostName"
	triggerPart["ValueToCompare"] = "test.tesdomain.com:8080"
	triggerPart["Operator"]= "Contains"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = false
	assert( validatorHelpers.UrlValidatorHelper.evaluate(
		triggerPart, "http://m.test.tesdomain.com:8080/test?q=2") )

	triggerPart["UrlPart"] = "HostName"
	triggerPart["ValueToCompare"] = "test.tesdomain.com:8080"
	triggerPart["Operator"]= "Contains"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = true
	assert( validatorHelpers.UrlValidatorHelper.evaluate(
		triggerPart,"http://m.test.tesdomain.com:8080/test?q=2") == false )

	triggerPart["UrlPart"] = "HostName"
	triggerPart["ValuesToCompare"] = { "balablaba","test.tesdomain.com:8080" }
	triggerPart["Operator"]= "Contains"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = false
	assert( validatorHelpers.UrlValidatorHelper.evaluate(
		triggerPart,"http://m.test.tesdomain.com:8080/test?q=2") )

	triggerPart["ValuesToCompare"] = { "ssss_SSss", "/Test/t1" }
	triggerPart["UrlPart"] = "PagePath"
	triggerPart["Operator"]= "EqualsAny"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = false
	assert( validatorHelpers.UrlValidatorHelper.evaluate(
		triggerPart, "http://test.tesdomain.com:8080/test/t1?q=2&y02") )
end
UrlValidatorHelperTest_evaluate()

local function CookieValidatorHelperTest_evaluate()
    iHelpers.request.getUnescapedCookieValue = function(name)
		if (name=="c1") then
			return "hhh"
		end
	end
	local triggerPart = {}
    triggerPart["CookieName"] = "c1"
    triggerPart["Operator"] = "Contains"
    triggerPart["IsIgnoreCase"] = true
    triggerPart["IsNegative"] = false
    triggerPart["ValueToCompare"] = "1"
    assert( validatorHelpers.CookieValidatorHelper.evaluate(triggerPart, iHelpers.request) == false )

	iHelpers.request.getUnescapedCookieValue = function(name)
		if (name=="c2") then
			return "ddd"
		end
		if (name=="c1") then
			return "1"
		end
	end
    triggerPart = {}
    triggerPart["CookieName"] = "c1"
    triggerPart["Operator"] = "Contains"
    triggerPart["ValueToCompare"] = "1"
	assert( validatorHelpers.CookieValidatorHelper.evaluate(triggerPart, iHelpers.request) == false )

	iHelpers.request.getUnescapedCookieValue = function(name)
		if (name=="c2") then
			return "ddd"
		end
		if (name=="c1") then
			return "1"
		end
	end
    triggerPart = {}
    triggerPart["CookieName"] = "c1"
    triggerPart["Operator"] = "Contains"
    triggerPart["ValueToCompare"] = "1"
    triggerPart["IsNegative"] = false
    triggerPart["IsIgnoreCase"] = true
	assert( validatorHelpers.CookieValidatorHelper.evaluate(triggerPart, iHelpers.request) )

	iHelpers.request.getUnescapedCookieValue = function(name)
		if (name=="c2") then
			return "ddd"
		end
		if (name=="c1") then
			return "1"
		end
	end
    triggerPart = {}
    triggerPart["CookieName"] = "c1"
    triggerPart["Operator"] = "Contains"
    triggerPart["ValueToCompare"] = "1"
    triggerPart["IsNegative"] = true
    triggerPart["IsIgnoreCase"] = true
	assert( validatorHelpers.CookieValidatorHelper.evaluate(triggerPart, iHelpers.request) == false )

	iHelpers.request.getUnescapedCookieValue = function(name)
		if (name=="c2") then
			return "ddd"
		end
		if (name=="c1") then
			return "cookie value value value"
		end
	end
    triggerPart = {}
    triggerPart["CookieName"] = "c1"
    triggerPart["Operator"] = "ContainsAny"
    triggerPart["ValuesToCompare"] = { "cookievalue", "value" }
    triggerPart["IsIgnoreCase"] = true
    triggerPart["IsNegative"] = false
	assert( validatorHelpers.CookieValidatorHelper.evaluate(triggerPart, iHelpers.request) )

	iHelpers.request.getUnescapedCookieValue = function(name)
		if (name=="c2") then
			return "ddd"
		end
		if (name=="c1") then
			return "1"
		end
	end
    triggerPart = {}
    triggerPart["CookieName"] = "c1"
    triggerPart["Operator"] = "EqualsAny"
    triggerPart["ValuesToCompare"] = { "cookievalue", "1" }
    triggerPart["IsIgnoreCase"] = true
    triggerPart["IsNegative"] = true
	assert( validatorHelpers.CookieValidatorHelper.evaluate(triggerPart, iHelpers.request) == false )
end
CookieValidatorHelperTest_evaluate()

local function UserAgentValidatorHelperTest_evaluate()
	local triggerPart = {}
	triggerPart["Operator"] = "Contains"
	triggerPart["IsIgnoreCase"] = false
	triggerPart["IsNegative"] = false
	triggerPart["ValueToCompare"] = "googlebot"
	iHelpers.request.getHeader = function(name)
		if (name == "user-agent") then return "Googlebot sample useraagent" end
	end
	assert( validatorHelpers.UserAgentValidatorHelper.evaluate(triggerPart, iHelpers.request) == false )

	triggerPart = {}
	triggerPart["Operator"] = "Equals"
	triggerPart["ValueToCompare"] = "googlebot"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = true
	iHelpers.request.getHeader = function(name)
		if (name == "user-agent") then return "oglebot sample useraagent" end
	end
	assert( validatorHelpers.UserAgentValidatorHelper.evaluate(triggerPart, iHelpers.request) )

	triggerPart = {}
	triggerPart["Operator"] = "Contains"
	triggerPart["ValueToCompare"] = "googlebot"
	triggerPart["IsIgnoreCase"] = false
	triggerPart["IsNegative"] = true
	iHelpers.request.getHeader = function(name) if (name == "user-agent") then return "googlebot" end end
	assert( validatorHelpers.UserAgentValidatorHelper.evaluate(triggerPart, iHelpers.request) == false )

	triggerPart = {}
	triggerPart["Operator"] = "Contains"
	triggerPart["ValueToCompare"] = "googlebot"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = false
	iHelpers.request.getHeader = function(name) if (name == "user-agent") then return "Googlebot" end end
	assert( validatorHelpers.UserAgentValidatorHelper.evaluate(triggerPart, iHelpers.request) )

	triggerPart = {}
	triggerPart["Operator"] = "ContainsAny"
	triggerPart["ValuesToCompare"] = { "googlebot" }
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = false
	iHelpers.request.getHeader = function(name) if (name == "user-agent") then return "Googlebot" end end
	assert( validatorHelpers.UserAgentValidatorHelper.evaluate(triggerPart, iHelpers.request) )

	triggerPart = {}
	triggerPart["Operator"] = "EqualsAny"
	triggerPart["ValuesToCompare"] = { "googlebot" }
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = true
	iHelpers.request.getHeader = function(name)
		if (name == "user-agent") then return "oglebot sample useraagent" end
	end
	assert( validatorHelpers.UserAgentValidatorHelper.evaluate(triggerPart, iHelpers.request) )
end
UserAgentValidatorHelperTest_evaluate()

local function HttpHeaderValidatorHelperTest_evaluate()
    local triggerPart = {}
    triggerPart["Operator"] = "Contains"
    triggerPart["IsIgnoreCase"] = false
    triggerPart["IsNegative"] = false
    triggerPart["ValueToCompare"] = "googlebot"
    assert( validatorHelpers.HttpHeaderValidatorHelper.evaluate(triggerPart, iHelpers.request) == false )

    triggerPart = {}
    triggerPart["Operator"] = "Contains"
    triggerPart["IsIgnoreCase"] = false
    triggerPart["IsNegative"] = false
	iHelpers.request.getHeader = function(name)
		if (name=="c2") then return "t1" end  if (name=="c3") then return "t1" end
	end
    assert( validatorHelpers.HttpHeaderValidatorHelper.evaluate(triggerPart, iHelpers.request) == false )

    triggerPart = {}
    triggerPart["Operator"] = "Equals"
    triggerPart["IsIgnoreCase"] = true
    triggerPart["IsNegative"] = true
    triggerPart["ValueToCompare"] = "t1"
    triggerPart["HttpHeaderName"] = "c1"
	iHelpers.request.getHeader = function(name)
		if (name=="c2") then return "t1" end if (name=="c3") then return "t1" end
	end
    assert( validatorHelpers.HttpHeaderValidatorHelper.evaluate(triggerPart, iHelpers.request) )

    triggerPart = {}
    triggerPart["Operator"] = "Contains"
    triggerPart["IsIgnoreCase"] = false
    triggerPart["IsNegative"] = true
    triggerPart["ValueToCompare"] = "t1"
    triggerPart["HttpHeaderName"] = "C1"
	iHelpers.request.getHeader = function(name)
		if (name=="c2") then return "t1" end
		if (name=="c3") then return "t1" end
		if (name=="c1") then return "test t1 test " end
	end
    assert( validatorHelpers.HttpHeaderValidatorHelper.evaluate(triggerPart, iHelpers.request) == false )

    triggerPart = {}
    triggerPart["Operator"] = "Contains"
    triggerPart["IsIgnoreCase"] = true
    triggerPart["IsNegative"] = false
    triggerPart["ValueToCompare"] = "t1"
    triggerPart["HttpHeaderName"] = "C1"
	iHelpers.request.getHeader = function(name)
		if (name=="c2") then return "t1" end
		if (name=="c3") then return "t1" end
		if (name=="c1") then return "test T1 test " end
	end
    assert( validatorHelpers.HttpHeaderValidatorHelper.evaluate(triggerPart, iHelpers.request) )

    triggerPart = {}
    triggerPart["Operator"] = "ContainsAny"
    triggerPart["IsIgnoreCase"] = true
    triggerPart["IsNegative"] = false
    triggerPart["ValuesToCompare"] = { "blabalabala","t1","t2" }
    triggerPart["HttpHeaderName"] = "C1"
	iHelpers.request.getHeader = function(name)
		if (name=="c2") then return "t1" end
		if (name=="c3") then return "t1" end
		if (name=="c1") then return "test T1 test " end
	end
    assert( validatorHelpers.HttpHeaderValidatorHelper.evaluate(triggerPart, iHelpers.request) )

    triggerPart = {}
    triggerPart["Operator"] = "EqualsAny"
    triggerPart["IsIgnoreCase"] = false
    triggerPart["IsNegative"] = true
    triggerPart["ValuesToCompare"] = { "bla","bla", "t1" }
    triggerPart["HttpHeaderName"] = "c1"
	iHelpers.request.getHeader = function(name)
		if (name=="c2") then return "t1" end
		if (name=="c3") then return "t1" end
		if (name=="c1") then return "t1" end
	end
    assert( validatorHelpers.HttpHeaderValidatorHelper.evaluate(triggerPart, iHelpers.request) == false)
end
HttpHeaderValidatorHelperTest_evaluate()

local function RequestBodyValidatorHelperTest_evaluate()
	local triggerPart = {}
	triggerPart["Operator"] = "Contains"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = false
	triggerPart["ValueToCompare"] = "t1"
	iHelpers.request.getBody = function()
		return "post with t1"
	end
	assert( validatorHelpers.RequestBodyValidatorHelper.evaluate(triggerPart, iHelpers.request) )

	triggerPart = {}
	triggerPart["Operator"] = "Contains"
	triggerPart["IsIgnoreCase"] = true
	triggerPart["IsNegative"] = false
	triggerPart["ValueToCompare"] = "t2"
	iHelpers.request.getBody = function()
		return "post with t1"
	end
	assert( validatorHelpers.RequestBodyValidatorHelper.evaluate(triggerPart, iHelpers.request) == false)
end
RequestBodyValidatorHelperTest_evaluate()