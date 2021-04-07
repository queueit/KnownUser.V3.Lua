local integrationEvaluator = require("IntegrationEvaluator")
local iHelpers = require("KnownUserImplementationHelpers")

local function IntegrationEvaluatorTest()
	local function test_getMatchedIntegrationConfig_OneTrigger_And_NotMatched()
		local integrationConfig =
		{
			Integrations =
			{
				{
					Triggers =
					{
						{
							LogicalOperator = "And",
							TriggerParts =
							{
								{
									CookieName = "c1",
									Operator = "Equals",
									ValueToCompare = "value1",
									ValidatorType = "CookieValidator",
									IsIgnoreCase = false,
									IsNegative = false
								},
								{
									UrlPart = "PageUrl",
									ValidatorType = "UrlValidator",
									ValueToCompare = "test",
									Operator = "Contains",
									IsIgnoreCase = false,
									IsNegative = false
								}
							}
						}
					}
				}
			}
		}

		local url = "http://test.tesdomain.com:8080/test?q=2"
		assert( integrationEvaluator.getMatchedIntegrationConfig(integrationConfig, url, iHelpers.request) == nil )
	end
	test_getMatchedIntegrationConfig_OneTrigger_And_NotMatched()

	local function test_getMatchedIntegrationConfig_OneTrigger_And_Matched()
        iHelpers.request.getUnescapedCookieValue = function(name)
			if (name=="c2") then
				return "ddd"
			end
			if (name=="c1") then
				return "Value1"
			end
		end

		local integrationConfig =
		{
			Integrations =
			{
				{
					Name = "integration1",
					Triggers =
					{
						{
							LogicalOperator = "And",
							TriggerParts =
							{
								{
									CookieName = "c1",
									Operator = "Equals",
									ValueToCompare = "value1",
									ValidatorType = "CookieValidator",
									IsIgnoreCase = true,
									IsNegative = false
								},
								{
									UrlPart = "PageUrl",
									ValidatorType = "UrlValidator",
									ValueToCompare = "test",
									Operator = "Contains",
									IsIgnoreCase = false,
									IsNegative = false
								}
							}
						}
					}
				}
			}
		}

        local url = "http://test.tesdomain.com:8080/test?q=2"
        assert( integrationEvaluator.getMatchedIntegrationConfig(
			integrationConfig, url, iHelpers.request)["Name"] == "integration1" )
    end
	test_getMatchedIntegrationConfig_OneTrigger_And_Matched()

	local function test_getMatchedIntegrationConfig_OneTrigger_And_NotMatched_UserAgent()
        iHelpers.request.getUnescapedCookieValue = function(name)
			if (name=="c2") then
				return "ddd"
			end
			if (name=="c1") then
				return "Value1"
			end
		end
		iHelpers.request.getHeader = function(name)
			if (name == "user-agent") then return "bot.html google.com googlebot test" end
		end

		local integrationConfig =
		{
			Integrations =
			{
				{
					Name = "integration1",
					Triggers =
					{
						{
							LogicalOperator = "And",
							TriggerParts =
							{
								{
									CookieName = "c1",
									Operator = "Equals",
									ValueToCompare = "value1",
									ValidatorType = "CookieValidator",
									IsIgnoreCase = true,
									IsNegative = false
								},
								{
									UrlPart = "PageUrl",
									ValidatorType = "UrlValidator",
									ValueToCompare = "test",
									Operator = "Contains",
									IsIgnoreCase = false,
									IsNegative = false
								},
								{
									ValidatorType = "UserAgentValidator",
									ValueToCompare = "googlebot",
									Operator = "Contains",
									IsIgnoreCase = true,
									IsNegative = true
								}
							}
						}
					}
				}
			}
		}

        local url = "http://test.tesdomain.com:8080/test?q=2"
        assert( integrationEvaluator.getMatchedIntegrationConfig(integrationConfig, url, iHelpers.request) == nil )
    end
	test_getMatchedIntegrationConfig_OneTrigger_And_NotMatched_UserAgent()

	local function test_getMatchedIntegrationConfig_OneTrigger_And_NotMatched_HttpHeader()
        iHelpers.request.getUnescapedCookieValue = function(name)
			if (name=="c2") then
				return "ddd"
			end
			if (name=="c1") then
				return "Value1"
			end
		end
		iHelpers.request.getHeader = function(name) if (name == "headertest") then return "abcd efg test gklm" end end

		local integrationConfig =
		{
			Integrations =
			{
				{
					Name = "integration1",
					Triggers =
					{
						{
							LogicalOperator = "And",
							TriggerParts =
							{
								{
									CookieName = "c1",
									Operator = "Equals",
									ValueToCompare = "value1",
									ValidatorType = "CookieValidator",
									IsIgnoreCase = true,
									IsNegative = false
								},
								{
									UrlPart = "PageUrl",
									ValidatorType = "UrlValidator",
									ValueToCompare = "test",
									Operator = "Contains",
									IsIgnoreCase = false,
									IsNegative = false
								},
								{
									ValidatorType = "HttpHeaderValidator",
									ValueToCompare = "test",
									HttpHeaderName="HeaderTest",
									Operator = "Contains",
									IsIgnoreCase = true,
									IsNegative = true
								}
							}
						}
					}
				}
			}
		}

        local url = "http://test.tesdomain.com:8080/test?q=2"
        assert(integrationEvaluator.getMatchedIntegrationConfig(integrationConfig, url, iHelpers.request) == nil )
    end
	test_getMatchedIntegrationConfig_OneTrigger_And_NotMatched_HttpHeader()

	local function test_getMatchedIntegrationConfig_OneTrigger_And_Matched_RequestBody()
        iHelpers.request.getBody = function()
			return "test body test request"
		end

		local integrationConfig =
		{
			Integrations =
			{
				{
					Name = "integration1",
					Triggers =
					{
						{
							LogicalOperator = "And",
							TriggerParts =
							{
								{
									CookieName = "c1",
									Operator = "Equals",
									ValueToCompare = "value1",
									ValidatorType = "CookieValidator",
									IsIgnoreCase = true,
									IsNegative = false
								},
								{
									UrlPart = "PageUrl",
									ValidatorType = "UrlValidator",
									ValueToCompare = "test",
									Operator = "Contains",
									IsIgnoreCase = false,
									IsNegative = false
								},
								{
									ValidatorType = "RequestBodyValidator",
									ValueToCompare = "test body",
									Operator = "Contains",
									IsIgnoreCase = true,
									IsNegative = false
								}
							}
						}
					}
				}
			}
		}

        local url = "http://test.tesdomain.com:8080/test?q=2"
        assert(integrationEvaluator.getMatchedIntegrationConfig(
			integrationConfig, url, iHelpers.request).Name == "integration1")
    end
	test_getMatchedIntegrationConfig_OneTrigger_And_Matched_RequestBody()

	local function test_getMatchedIntegrationConfig_OneTrigger_Or_NotMatched()
        iHelpers.request.getUnescapedCookieValue = function(_) return nil end

		local integrationConfig =
		{
			Integrations =
			{
				{
					Name = "integration1",
					Triggers =
					{
						{
							LogicalOperator = "Or",
							TriggerParts =
							{
								{
									CookieName = "c1",
									Operator = "Equals",
									ValueToCompare = "value1",
									ValidatorType = "CookieValidator",
									IsIgnoreCase = true,
									IsNegative = false
								},
								{
									UrlPart = "PageUrl",
									ValidatorType = "UrlValidator",
									ValueToCompare = "test",
									Operator = "Equals",
									IsIgnoreCase = false,
									IsNegative = false
								}
							}
						}
					}
				}
			}
		}

        local url = "http://test.tesdomain.com:8080/test?q=2"
        assert(integrationEvaluator.getMatchedIntegrationConfig(integrationConfig, url, iHelpers.request) == nil )
    end
	test_getMatchedIntegrationConfig_OneTrigger_Or_NotMatched()

	local function test_getMatchedIntegrationConfig_OneTrigger_Or_Matched()
        iHelpers.request.getUnescapedCookieValue = function(_) return nil end

		local integrationConfig =
		{
			Integrations =
			{
				{
					Name = "integration1",
					Triggers =
					{
						{
							LogicalOperator = "Or",
							TriggerParts =
							{
								{
									CookieName = "c1",
									Operator = "Equals",
									ValueToCompare = "value1",
									ValidatorType = "CookieValidator",
									IsIgnoreCase = true,
									IsNegative = true
								},
								{
									UrlPart = "PageUrl",
									ValidatorType = "UrlValidator",
									ValueToCompare = "test",
									Operator = "Equals",
									IsIgnoreCase = false,
									IsNegative = false
								}
							}
						}
					}
				}
			}
		}

        local url = "http://test.tesdomain.com:8080/test?q=2"
        assert( integrationEvaluator.getMatchedIntegrationConfig(
			integrationConfig, url, iHelpers.request)["Name"] == "integration1" )
    end
	test_getMatchedIntegrationConfig_OneTrigger_Or_Matched()

	local function test_getMatchedIntegrationConfig_TwoTriggers_Matched()
        iHelpers.request.getUnescapedCookieValue = function(_) return nil end

		local integrationConfig =
		{
			Integrations =
			{
				{
					Name = "integration1",
					Triggers =
					{
						{
							LogicalOperator = "And",
							TriggerParts =
							{
								{
									CookieName = "c1",
									Operator = "Equals",
									ValueToCompare = "value1",
									ValidatorType = "CookieValidator",
									IsIgnoreCase = true,
									IsNegative = true
								}
							}
						},
						{
							LogicalOperator = "And",
							TriggerParts =
							{
								{
									CookieName = "c1",
									Operator = "Equals",
									ValueToCompare = "value1",
									ValidatorType = "CookieValidator",
									IsIgnoreCase = false,
									IsNegative = false
								},
								{
									UrlPart = "PageUrl",
									ValidatorType = "UrlValidator",
									ValueToCompare = "test",
									Operator = "Contains",
									IsIgnoreCase = false,
									IsNegative = false
								}
							}
						}
					}
				}
			}
		}

        local url = "http://test.tesdomain.com:8080/test?q=2"
        assert( integrationEvaluator.getMatchedIntegrationConfig(
			integrationConfig, url, iHelpers.request)["Name"] == "integration1" )
    end
	test_getMatchedIntegrationConfig_TwoTriggers_Matched()

	local function test_getMatchedIntegrationConfig_ThreeIntegrationsInOrder_SecondMatched()
        iHelpers.request.getUnescapedCookieValue = function(_) return nil end

		local integrationConfig =
		{
			Integrations =
			{
				{
					Name = "integration0",
					Triggers =
					{
						{
							LogicalOperator = "And",
							TriggerParts =
							{
								{
									UrlPart = "PageUrl",
									ValidatorType = "UrlValidator",
									ValueToCompare = "Test",
									Operator = "Contains",
									IsIgnoreCase = false,
									IsNegative = false
								}
							}
						}
					}
				},
				{
					Name = "integration1",
					Triggers =
					{
						{
							LogicalOperator = "And",
							TriggerParts =
							{
								{
									UrlPart = "PageUrl",
									ValidatorType = "UrlValidator",
									ValueToCompare = "test",
									Operator = "Contains",
									IsIgnoreCase = false,
									IsNegative = false
								}
							}
						}
					}
				},
				{
					Name = "integration2",
					Triggers =
					{
						{
							LogicalOperator = "And",
							TriggerParts =
							{
								{
									CookieName = "c1",
									Operator = "Equals",
									ValueToCompare = "value1",
									ValidatorType = "CookieValidator",
									IsIgnoreCase = true,
									IsNegative = false
								}
							}
						}
					}
				}
			}
		}

        local url = "http://test.tesdomain.com:8080/test?q=2"
        assert( integrationEvaluator.getMatchedIntegrationConfig(
			integrationConfig, url,iHelpers.request)["Name"] == "integration1" )
    end
	test_getMatchedIntegrationConfig_ThreeIntegrationsInOrder_SecondMatched()
end
IntegrationEvaluatorTest()