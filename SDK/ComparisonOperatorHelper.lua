local utils = require("Utils")

local model = {
	evaluate = function(opt, isNegative, isIgnoreCase, value, valueToCompare, valuesToCompare)
		-- Private functions
		local function contains(_value, _valueToCompare, _isNegative, _isIgnoreCase)
			if (_valueToCompare == "*" and (not utils.isNilOrEmpty(_value))) then
				return true
			end

			if (_isIgnoreCase) then
				_value = string.upper(_value)
				_valueToCompare = string.upper(_valueToCompare)
			end

			local evaluation = utils:contains(_value, _valueToCompare)

			if (_isNegative) then
				return not evaluation
			else
				return evaluation
			end
		end

		local function equals(_value, _valueToCompare, _isNegative, _isIgnoreCase)
			if (_isIgnoreCase) then
				_value = string.upper(_value)
				_valueToCompare = string.upper(_valueToCompare)
			end

			local evaluation = _value == _valueToCompare

			if (_isNegative) then
				return not evaluation
			else
				return evaluation
			end
		end

		local function equalsAny(_value, _valuesToCompare, _isNegative, _isIgnoreCase)
			for _, vToCompare in pairs(_valuesToCompare) do
				if(equals(_value, vToCompare, false, _isIgnoreCase)) then
					return not _isNegative
				end
			end
			return _isNegative
		end

		local function containsAny(_value, _valuesToCompare, _isNegative, _isIgnoreCase)
			for _, vToCompare in pairs(_valuesToCompare) do
				if(contains(_value, vToCompare, false, _isIgnoreCase)) then
					return not _isNegative
				end
			end

			return _isNegative
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