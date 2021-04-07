local utils = require("Utils")
local validatorHelpers = require("ValidatorHelpers")

local model = {
	getMatchedIntegrationConfig = function(customerIntegration, currentPageUrl, request)
		-- Private functions
		local function evaluateTriggerPart(_triggerPart, _currentPageUrl, _request)
			if (_triggerPart["ValidatorType"] == nil) then
				return false
			end

			if (_triggerPart["ValidatorType"] == "UrlValidator") then
				return validatorHelpers.UrlValidatorHelper.evaluate(_triggerPart, _currentPageUrl)
			end
			if (_triggerPart["ValidatorType"] == "CookieValidator") then
				return validatorHelpers.CookieValidatorHelper.evaluate(_triggerPart, _request)
			end
			if (_triggerPart["ValidatorType"] == "UserAgentValidator") then
				return validatorHelpers.UserAgentValidatorHelper.evaluate(_triggerPart, _request)
			end
			if (_triggerPart["ValidatorType"] == "HttpHeaderValidator") then
				return validatorHelpers.HttpHeaderValidatorHelper.evaluate(_triggerPart, _request)
			end
			if (_triggerPart["ValidatorType"] == "RequestBodyValidator") then
				return validatorHelpers.RequestBodyValidatorHelper.evaluate(_triggerPart, _request)
			end

			return false
		end

		local function evaluateTrigger(_trigger, _currentPageUrl, _request)
			if (_trigger["LogicalOperator"] == nil or
				_trigger["TriggerParts"] == nil or
				_trigger["TriggerParts"] == nil) then
				return false
			end

			if (_trigger["LogicalOperator"] == 'Or') then
				for _, triggerPart in pairs(_trigger["TriggerParts"]) do
					if (utils.isTable(triggerPart) == false) then
						return false
					end
					if (evaluateTriggerPart(triggerPart, _currentPageUrl, _request)) then
						return true
					end
				end
				return false
			else
				for _, triggerPart in pairs(_trigger["TriggerParts"]) do
					if (utils.isTable(triggerPart) == false) then
						return false
					end
					if (evaluateTriggerPart(triggerPart, _currentPageUrl, _request) == false) then
						return false
					end
				end
				return true
			end
		end
		-- END Private functions

		if (utils.isTable(customerIntegration["Integrations"]) == false) then
			return nil
		end

		for _, integrationConfig in pairs(customerIntegration["Integrations"]) do
			if (utils.isTable(integrationConfig)) then
				if (utils.isTable(integrationConfig["Triggers"])) then
					for _, trigger in pairs(integrationConfig["Triggers"]) do
						if (utils.isTable(trigger) == false) then
							return false
						end
						if (evaluateTrigger(trigger, currentPageUrl, request)) then
							return integrationConfig
						end
					end
				end
			end
		end
		return nil
	end
}

return model