local function test_hash_hmac_sha256_encode_correct()
	local stringToHash = "event1f8757c2d-34c2-4639-bef2-1736cdd30bbb3idle1530257694"
	local secretKey = "4e1db821-a825-49da-acd0-5d376f2068db"
	local expectedResult = "e6913f0e5dd63a266a52542e5df30ec18ee9f259153c55ea30db217e20798e85"

	local iHelpers = require("KnownUserImplementationHelpers")
	local actualResult = iHelpers.hash.hmac_sha256_encode(stringToHash, secretKey)

	assert( actualResult == expectedResult )
end
test_hash_hmac_sha256_encode_correct()

local function test_jsonHelper_correctNullHandling()
	local integrationConfigJson =
	[[
		{
			"Description": "changed not extend cookie action and trigger to use event disabled",
			"Integrations": [
			  {
				"Name": "event1 ignore action (default)",
				"ActionType": "Ignore",
				"EventId": null,
				"CookieDomain": null,
				"LayoutName": null,
				"Culture": null,
				"ExtendCookieValidity": null,
				"CookieValidityMinute": 0,
				"Triggers": [
				  {
					"TriggerParts": [
					  {
						"Operator": "Contains",
						"ValueToCompare": "ignore-queue-event1-nodomain",
						"ValuesToCompare": null,
						"UrlPart": "PageUrl",
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UrlValidator",
						"IsNegative": false,
						"IsIgnoreCase": true
					  },
					  {
						"Operator": "ContainsAny",
						"ValueToCompare": "",
						"ValuesToCompare": [ "ignore-that-queue-event1-nodomain", "ignore-this-queue-event1-nodomain" ],
						"UrlPart": "PageUrl",
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UrlValidator",
						"IsNegative": false,
						"IsIgnoreCase": true
					  }
					],
					"LogicalOperator": "Or"
				  }
				],
				"QueueDomain": null,
				"RedirectLogic": null,
				"ForcedTargetUrl": null
			  },
			  {
				"Name": "event1 queue action (default)",
				"ActionType": "Queue",
				"EventId": "event1",
				"CookieDomain": "",
				"LayoutName": null,
				"Culture": "",
				"ExtendCookieValidity": true,
				"CookieValidityMinute": 20,
				"Triggers": [
				  {
					"TriggerParts": [
					  {
						"Operator": "Contains",
						"ValueToCompare": "queue-event1-nodomain",
						"ValuesToCompare": null,
						"UrlPart": "PageUrl",
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UrlValidator",
						"IsNegative": false,
						"IsIgnoreCase": true
					  },
					  {
						"Operator": "Contains",
						"ValueToCompare": "bot",
						"ValuesToCompare": null,
						"UrlPart": null,
						"VariableName": null,
						"CookieName": "Akamai-bot",
						"HttpHeaderName": null,
						"ValidatorType": "CookieValidator",
						"IsNegative": true,
						"IsIgnoreCase": true
					  },
					  {
						"Operator": "Contains",
						"ValueToCompare": "bot",
						"ValuesToCompare": null,
						"UrlPart": null,
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UserAgentValidator",
						"IsNegative": true,
						"IsIgnoreCase": true
					  },
					  {
						"Operator": "Contains",
						"ValueToCompare": "bot",
						"ValuesToCompare": null,
						"UrlPart": null,
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": "Akamai-bot",
						"ValidatorType": "HttpHeaderValidator",
						"IsNegative": true,
						"IsIgnoreCase": true
					  }
					],
					"LogicalOperator": "And"
				  }
				],
				"QueueDomain": "queueitknownusertst.test.queue-it.net",
				"RedirectLogic": "AllowTParameter",
				"ForcedTargetUrl": ""
			  },
			  {
				"Name": "event1 cancel action (default)",
				"ActionType": "Cancel",
				"EventId": "event1",
				"CookieDomain": "",
				"LayoutName": null,
				"Culture": null,
				"ExtendCookieValidity": null,
				"CookieValidityMinute": 0,
				"Triggers": [
				  {
					"TriggerParts": [
					  {
						"Operator": "Contains",
						"ValueToCompare": "cancel-event1-nodomain",
						"ValuesToCompare": null,
						"UrlPart": "PageUrl",
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UrlValidator",
						"IsNegative": false,
						"IsIgnoreCase": true
					  }
					],
					"LogicalOperator": "And"
				  }
				],
				"QueueDomain": "queueitknownusertst.test.queue-it.net",
				"RedirectLogic": null,
				"ForcedTargetUrl": null
			  },
			  {
				"Name": "event1 ignore action (ticketania)",
				"ActionType": "Ignore",
				"EventId": null,
				"CookieDomain": null,
				"LayoutName": null,
				"Culture": null,
				"ExtendCookieValidity": null,
				"CookieValidityMinute": 0,
				"Triggers": [
				  {
					"TriggerParts": [
					  {
						"Operator": "Contains",
						"ValueToCompare": "ignore-queue-event1",
						"ValuesToCompare": null,
						"UrlPart": "PageUrl",
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UrlValidator",
						"IsNegative": false,
						"IsIgnoreCase": true
					  },
					  {
						"Operator": "ContainsAny",
						"ValueToCompare": "",
						"ValuesToCompare": [ "ignore-this-queue-event1", "ignore-that-queue-event1" ],
						"UrlPart": "PageUrl",
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UrlValidator",
						"IsNegative": false,
						"IsIgnoreCase": true
					  }
					],
					"LogicalOperator": "Or"
				  }
				],
				"QueueDomain": null,
				"RedirectLogic": null,
				"ForcedTargetUrl": null
			  },
			  {
				"Name": "event1 queue action (ticketania)",
				"ActionType": "Queue",
				"EventId": "event1",
				"CookieDomain": ".ticketania.com",
				"LayoutName": "Christmas Layout by Queue-it",
				"Culture": "",
				"ExtendCookieValidity": true,
				"CookieValidityMinute": 20,
				"Triggers": [
				  {
					"TriggerParts": [
					  {
						"Operator": "Contains",
						"ValueToCompare": "queue-event1",
						"ValuesToCompare": null,
						"UrlPart": "PageUrl",
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UrlValidator",
						"IsNegative": false,
						"IsIgnoreCase": true
					  },
					  {
						"Operator": "Contains",
						"ValueToCompare": "bot",
						"ValuesToCompare": null,
						"UrlPart": null,
						"VariableName": null,
						"CookieName": "Akamai-bot",
						"HttpHeaderName": null,
						"ValidatorType": "CookieValidator",
						"IsNegative": true,
						"IsIgnoreCase": true
					  },
					  {
						"Operator": "Contains",
						"ValueToCompare": "bot",
						"ValuesToCompare": null,
						"UrlPart": null,
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UserAgentValidator",
						"IsNegative": true,
						"IsIgnoreCase": true
					  },
					  {
						"Operator": "Contains",
						"ValueToCompare": "bot",
						"ValuesToCompare": null,
						"UrlPart": null,
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": "Akamai-bot",
						"ValidatorType": "HttpHeaderValidator",
						"IsNegative": true,
						"IsIgnoreCase": true
					  }
					],
					"LogicalOperator": "And"
				  }
				],
				"QueueDomain": "queueitknownusertst.test.queue-it.net",
				"RedirectLogic": "AllowTParameter",
				"ForcedTargetUrl": ""
			  },
			  {
				"Name": "event1 cancel action (ticketania)",
				"ActionType": "Cancel",
				"EventId": "event1",
				"CookieDomain": ".ticketania.com",
				"LayoutName": null,
				"Culture": null,
				"ExtendCookieValidity": null,
				"CookieValidityMinute": 0,
				"Triggers": [
				  {
					"TriggerParts": [
					  {
						"Operator": "Contains",
						"ValueToCompare": "cancel-event1",
						"ValuesToCompare": null,
						"UrlPart": "PageUrl",
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UrlValidator",
						"IsNegative": false,
						"IsIgnoreCase": true
					  }
					],
					"LogicalOperator": "And"
				  }
				],
				"QueueDomain": "queueitknownusertst.test.queue-it.net",
				"RedirectLogic": null,
				"ForcedTargetUrl": null
			  },
			  {
				"Name": "future queue action (default)",
				"ActionType": "Queue",
				"EventId": "future",
				"CookieDomain": "",
				"LayoutName": null,
				"Culture": "",
				"ExtendCookieValidity": true,
				"CookieValidityMinute": 20,
				"Triggers": [
				  {
					"TriggerParts": [
					  {
						"Operator": "Contains",
						"ValueToCompare": "idle-future-nodomain",
						"ValuesToCompare": null,
						"UrlPart": "PageUrl",
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UrlValidator",
						"IsNegative": false,
						"IsIgnoreCase": true
					  }
					],
					"LogicalOperator": "And"
				  }
				],
				"QueueDomain": "queueitknownusertst.test.queue-it.net",
				"RedirectLogic": "AllowTParameter",
				"ForcedTargetUrl": ""
			  },
			  {
				"Name": "future queue action (ticketania)",
				"ActionType": "Queue",
				"EventId": "future",
				"CookieDomain": ".ticketania.com",
				"LayoutName": null,
				"Culture": "",
				"ExtendCookieValidity": true,
				"CookieValidityMinute": 20,
				"Triggers": [
				  {
					"TriggerParts": [
					  {
						"Operator": "Contains",
						"ValueToCompare": "idle-future",
						"ValuesToCompare": null,
						"UrlPart": "PageUrl",
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UrlValidator",
						"IsNegative": false,
						"IsIgnoreCase": true
					  }
					],
					"LogicalOperator": "And"
				  }
				],
				"QueueDomain": "queueitknownusertst.test.queue-it.net",
				"RedirectLogic": "AllowTParameter",
				"ForcedTargetUrl": ""
			  },
			  {
				"Name": "disabled queue action (default)",
				"ActionType": "Queue",
				"EventId": "disabled",
				"CookieDomain": "",
				"LayoutName": null,
				"Culture": "",
				"ExtendCookieValidity": true,
				"CookieValidityMinute": 20,
				"Triggers": [
				  {
					"TriggerParts": [
					  {
						"Operator": "Contains",
						"ValueToCompare": "queue-disabled-nodomain",
						"ValuesToCompare": null,
						"UrlPart": "PageUrl",
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UrlValidator",
						"IsNegative": false,
						"IsIgnoreCase": true
					  }
					],
					"LogicalOperator": "And"
				  }
				],
				"QueueDomain": "queueitknownusertst.test.queue-it.net",
				"RedirectLogic": "AllowTParameter",
				"ForcedTargetUrl": ""
			  },
			  {
				"Name": "disabled [not extend cookie] queue action (default)",
				"ActionType": "Queue",
				"EventId": "disabled",
				"CookieDomain": "",
				"LayoutName": null,
				"Culture": "",
				"ExtendCookieValidity": false,
				"CookieValidityMinute": 20,
				"Triggers": [
				  {
					"TriggerParts": [
					  {
						"Operator": "Contains",
						"ValueToCompare": "queue-disabled-notextendcookie-nodomain",
						"ValuesToCompare": null,
						"UrlPart": "PageUrl",
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UrlValidator",
						"IsNegative": false,
						"IsIgnoreCase": true
					  }
					],
					"LogicalOperator": "And"
				  }
				],
				"QueueDomain": "queueitknownusertst.test.queue-it.net",
				"RedirectLogic": "AllowTParameter",
				"ForcedTargetUrl": ""
			  },
			  {
				"Name": "disabled queue action (ticketania)",
				"ActionType": "Queue",
				"EventId": "disabled",
				"CookieDomain": ".ticketania.com",
				"LayoutName": null,
				"Culture": "",
				"ExtendCookieValidity": true,
				"CookieValidityMinute": 20,
				"Triggers": [
				  {
					"TriggerParts": [
					  {
						"Operator": "Contains",
						"ValueToCompare": "queue-disabled",
						"ValuesToCompare": null,
						"UrlPart": "PageUrl",
						"VariableName": null,
						"CookieName": null,
						"HttpHeaderName": null,
						"ValidatorType": "UrlValidator",
						"IsNegative": false,
						"IsIgnoreCase": true
					  }
					],
					"LogicalOperator": "And"
				  }
				],
				"QueueDomain": "queueitknownusertst.test.queue-it.net",
				"RedirectLogic": "AllowTParameter",
				"ForcedTargetUrl": ""
			  }
			],
			"CustomerId": "queueitknownusertst",
			"AccountId": "queueitknownusertst",
			"Version": 11,
			"PublishDate": "2018-01-25T10:08:33.2825373Z",
			"ConfigDataVersion": "1.0.0.3"
		  }
	]]

	local json = require("json")
	local cfg = json.parse(integrationConfigJson)

	for _, v in pairs(cfg.Integrations) do
		assert( "should be a valid string -> " .. v.LayoutName ) -- this should not raise exception
	end
end
test_jsonHelper_correctNullHandling()