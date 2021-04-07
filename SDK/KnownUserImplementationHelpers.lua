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
		-- arguments: name -> name of header
		-- returns: string | nil
		getHeader = function(_)
			error("Not implemented : request.getHeader(name)")
		end,
		-- returns: string | nil
		getBody = function(_)
			error("Not implemented : request.getBody()")
		end,
		-- arguments: name -> name of cookie
		-- returns: the unescaped (url decoded) value ( string | nil ) in the cookie found by name
		getUnescapedCookieValue = function(_)
			error("Not implemented : request.getUnescapedCookieValue(name)")
		end,
		-- returns the url (string) user requested
		getAbsoluteUri = function()
			error("Not implemented : request.getAbsoluteUri()")
		end,
		-- returns the IP (string) of the user (host)
		getUserHostAddress = function()
			error("Not implemented : request.getUserHostAddress()")
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
		-- arguments: name, value, expire, domain
		-- returns: void
		setCookie = function(_, _, _, _)
			error("Not implemented : response.setCookie(name, value, expire, domain)")
		end
	},
	hash =
	{
		-- arguments: value, key
		-- returns: string
		hmac_sha256_encode = function(_, _)
			error("Not implemented : hash.hmac_sha256_encode(value, key")
		end
	},
	json =
	{
		-- arguments: jsonStr
		-- returns: string
		parse = function(_)
			error("Not implemented : json.encode(jsonStr)")
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