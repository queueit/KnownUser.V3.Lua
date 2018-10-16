local utils = require("Utils")

local model = {
	evaluate = function(opt, isNegative, isIgnoreCase, value, valueToCompare, valuesToCompare)
		-- Private functions
		local function contains(value, valueToCompare, isNegative, ignoreCase)
			if (valueToCompare == "*") then
				return true
			end

			if (ignoreCase) then
				value = string.upper(value)
				valueToCompare = string.upper(valueToCompare)
			end
        
			local evaluation = utils:contains(value, valueToCompare)
		
			if (isNegative) then
				return not evaluation
			else        
				return evaluation
			end
		end
		
		local function equals(value, valueToCompare, isNegative, ignoreCase)
			if (ignoreCase) then
				value = string.upper(value)
				valueToCompare = string.upper(valueToCompare)
			end

			local evaluation = value == valueToCompare

			if (isNegative) then
				return not evaluation
			else
				return evaluation
			end
		end
    
		local function equalsAny(value, valuesToCompare, isNegative, ignoreCase)
			for i, vToCompare in pairs(valuesToCompare) do		
				if(equals(value, vToCompare, false, ignoreCase)) then
					return not isNegative			
				end
			end
			return isNegative
		end

		local function containsAny(value, valuesToCompare, isNegative, ignoreCase)
			for i, vToCompare in pairs(valuesToCompare) do
				if(contains(value, vToCompare, false, ignoreCase)) then
					return not isNegative
				end
			end
        
			return isNegative
		end

		local function endsWith(value, valueToCompare, isNegative, ignoreCase) 
			if (ignoreCase) then
				value = string.upper(value)
				valueToCompare = string.upper(valueToCompare)
			end

			local evaluation = utils.endsWith(value, valueToCompare)

			if (isNegative) then
				return not evaluation
			else
				return evaluation
			end
		end

		local function startsWith(value, valueToCompare, isNegative, ignoreCase)
			if (ignoreCase) then
				value = string.upper(value)
				valueToCompare = string.upper(valueToCompare)
			end

			local evaluation = utils.startsWith(value, valueToCompare)

			if (isNegative) then
				return not evaluation
			else
				return evaluation
			end
		end	

		if (value == nil) then 
			value = "" 
		end
		if (valueToCompare == nil) then 
			valueToCompare = "" 
		end
		if (utils.isTable(valuesToCompare) == false) then 
			valuesToCompare = {}
		end

		if (opt == "Equals") then
			return equals(value, valueToCompare, isNegative, isIgnoreCase)
		end
		if (opt == "Contains") then
			return contains(value, valueToCompare, isNegative, isIgnoreCase)		
		end
		if (opt == "StartsWith") then
			return startsWith(value, valueToCompare, isNegative, isIgnoreCase)
		end
		if (opt == "EndsWith") then
			return endsWith(value, valueToCompare, isNegative, isIgnoreCase)
		end
		if (opt == "EqualsAny") then
			return equalsAny(value, valuesToCompare, isNegative, isIgnoreCase)
		end
		if (opt == "ContainsAny") then
			return containsAny(value, valuesToCompare, isNegative, isIgnoreCase)
		end

		return false
	end	    
}

return model