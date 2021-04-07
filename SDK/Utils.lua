local utils =
{
	toString = function(v)
		if (v == nil) then
			return ""
		end

		local vType = type(v)

		if (vType == "string" or vType == "number") then
			return v
		end

		if (vType == "boolean") then
			if (v == true) then
				return "true"
			else
				return "false"
			end
		end

		error("toString called on unsupported type: " .. type(v))
	end,
	urlEncode = function(str)
		if (str) then
			str = string.gsub(str, "\n", "\r\n")
			str = string.gsub(str, "([^%w %-%_%.%~])", function (c) return string.format ("%%%02X", string.byte(c)) end)
			str = string.gsub(str, " ", "%%20")
		end
		return str
	end,
	urlDecode = function(str)
		str = string.gsub(str, "+", " ")
		str = string.gsub(str, "%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
		str = string.gsub(str, "\r\n", "\n")
		return str
	end,
	explode = function(sep, inputstr)
		local t = {}; local i = 1;
		for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
			t[i] = str
			i = i + 1
		end
		return t
	end,
	endsWith = function(text, match)
		return string.sub(text, -string.len(match)) == match
	end,
	startsWith = function(text, match)
		return string.sub(text, 1, string.len(match)) == match
	end,
	escapeMagicChars = function(text)
		-- Lua 'magic characters' ( ) . % + - * ? [ ^ $ that needs to be escaped with %
		text = text:gsub("%%", "%%%%")
		text = text:gsub("%(", "%%(")
		text = text:gsub("%)", "%%)")
		text = text:gsub("%.", "%%.")
		text = text:gsub("%+", "%%+")
		text = text:gsub("%-", "%%-")
		text = text:gsub("%*", "%%*")
		text = text:gsub("%?", "%%?")
		text = text:gsub("%[", "%%[")
		text = text:gsub("%]", "%%]")
		text = text:gsub("%^", "%%^")
		text = text:gsub("%$", "%%$")
		return text
	end,
	contains = function(self, text, match)
		match = self.escapeMagicChars(match)
		return string.find(text, match) ~= nil
	end,
	isTable = function(o)
		if (o == nil) then
			return false
		end
		return type(o) == "table"
	end,
	isNilOrEmpty = function(s)
		if(s == nil or string.len(s) == 0) then
			return true
		end
		return false
	end,
	tableLength = function (t)
		local count = 0
		for _ in pairs(t) do count = count + 1 end
		return count
	end
}

return utils