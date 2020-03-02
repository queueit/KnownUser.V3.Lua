--[[ 
	The KnownUser lib is implemented using only Lua base functionality; compatible with v.5.1.
	All those non-standard Lua function calls, needed by KnownUser, are exposed as helper methods below.
	So, to make KnownUser functionality work correctly, these methods would need to implemented 
	using whatever libs are available on the executing environment.
]]--
local iHelpers = 
{
	request = 
	{
		-- returns: string | nil
		getHeader = function(name)
			error("request.getHeader - not implemented")
		end,
		-- returns: the unescaped (url decoded) value ( string | nil ) in the cookie found by name
		getUnescapedCookieValue = function(name)
			error("request.getUnescapedCookieValue - not implemented")
		end,
		-- returns the url (string) user requested
		getAbsoluteUri = function()
			error("request.getAbsoluteUri - not implemented")
		end,
		-- returns the IP (string) of the user (host)
		getUserHostAddress = function()
			error("request.getUserHostAddress - not implemented")
		end
	},
	response = 
	{
		cookieOptions = 
		{
			-- true if response cookies should have httponly flag set
			-- only enable if you use pure server-side integration e.g. not JS Hybrid
			httpOnly = false,
			-- true if response cookies should have secure flag set
			-- only enable if your website runs on https
			secure = false,
			-- set to any string value (none, strict, lax) if response cookies should have samesite flag set
			-- only use 'strict' if your queue protected site stays on same domain (no navigation to subdomains)
			sameSite = nil
		},
		-- returns: void
		setCookie = function(name, value, expire, domain)
			error("response.setCookie - not implemented")
		end
	},
	hash = 
	{
		-- returns: string
		hmac_sha256_encode = function(value, key)
			error("hash.hmac_sha256_encode - not implemented")
		end
	},
	json =
	{
		-- returns: string
		parse = function(jsonStr)
			error("json.encode - not implemented")
		end
	},
	system = 
	{
		getConnectorName = function()
			return "unspecified"
		end
	}
}

return iHelpers