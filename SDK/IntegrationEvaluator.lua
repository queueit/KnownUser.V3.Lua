local utils = require("Utils")
local validatorHelpers = require("ValidatorHelpers")

local model = {
	getMatchedIntegrationConfig = function(customerIntegration, currentPageUrl, request)	
		-- Private functions
		local function evaluateTriggerPart(triggerPart, currentPageUrl, request)
			if (triggerPart["ValidatorType"] == nil) then 
				return false
			end

			if (triggerPart["ValidatorType"] == "UrlValidator") then		
				return validatorHelpers.UrlValidatorHelper.evaluate(triggerPart, currentPageUrl)			
			end
			if (triggerPart["ValidatorType"] == "CookieValidator") then
				return validatorHelpers.CookieValidatorHelper.evaluate(triggerPart, request)
			end
			if (triggerPart["ValidatorType"] == "UserAgentValidator") then
				return validatorHelpers.UserAgentValidatorHelper.evaluate(triggerPart, request)
			end
			if (triggerPart["ValidatorType"] == "HttpHeaderValidator") then
				return validatorHelpers.HttpHeaderValidatorHelper.evaluate(triggerPart, request)
			end

			return false
		end
	
		local function evaluateTrigger(trigger, currentPageUrl, request)
			if (trigger["LogicalOperator"] == nil or 
				trigger["TriggerParts"] == nil or
				trigger["TriggerParts"] == nil) then 
				return false
			end

			if (trigger["LogicalOperator"] == 'Or') then
				for i, triggerPart in pairs(trigger["TriggerParts"]) do
					if (utils.isTable(triggerPart) == false) then
						return false
					end
					if (evaluateTriggerPart(triggerPart, currentPageUrl, request)) then
						return true
					end
				end
				return false
			else
				for i, triggerPart in pairs(trigger["TriggerParts"]) do
					if (utils.isTable(triggerPart) == false) then
						return false
					end
					if (evaluateTriggerPart(triggerPart, currentPageUrl, request) == false) then
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

		for i, integrationConfig in pairs(customerIntegration["Integrations"]) do
			if (utils.isTable(integrationConfig)) then
				if (utils.isTable(integrationConfig["Triggers"])) then
					for y, trigger in pairs(integrationConfig["Triggers"]) do
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