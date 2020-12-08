----------------------------------------------------------------------------------------------------
-- ApacheHandlerUsingConfigFromFile.lua
----------------------------------------------------------------------------------------------------
-- HANDLER: ApacheHandlerUsingConfigFromFile
--
-- DESCRIPTION:
--    This Apache httpd Lua handler verifies that HTTP requests are allowed to be passed to the
--    backend. If a request does not contain proof that a queue traversal has already taken place
--    a redirect to the queue is issued.
--    This handler in an Apache httpd configuration file. The following environment variables
--    must be set in order for the handler to be able to handle requests:
--...   * QUEUEIT_CUSTOMER_ID: The Queue-it customer id
--...   * QUEUEIT_SECRET_KEY: The Queue-it secret key to access the queue API
--...   * QUEUEIT_INT_CONF_FILE: The local JSON file containing the integration configuration
--      * QUEUEIT_ERROR_CODE: (optional) The response code to use instead of declining to act
--                            if request handling fails
--      * QUEUEIT_COOKIE_OPTIONS_HTTPONLY: (optional) Set to "true" if you want cookies with httponly
--                            flag set. Only enable if this you use pure server-side integration
--                            e.g. not JS Hybrid.
--      * QUEUEIT_COOKIE_OPTIONS_SECURE: (optional) Set to "true" if you want cookies with secure
--                            flag set. Only enable if your website runs purely on https.
--    Note that the integration configuration is read on every request. The JSON file containing
--    The integration configuration should, for performance reasons, be available locally.
--
-- USAGE:
--    Add the following configuration to httpd.conf (or apache2.conf):
--      LoadModule lua_module modules/mod_lua.so
--      [...]
--      SetEnv  QUEUEIT_CUSTOMER_ID                 "{CUSTOMER_ID}"
--      SetEnv  QUEUEIT_SECRET_KEY                  "{SECRET_KEY}"
--      SetEnv  QUEUEIT_INT_CONF_FILE               "{APP_FOLDER}/integration_config.json"
--      SetEnv  QUEUEIT_ERROR_CODE                  "400"
--      SetEnv  QUEUEIT_COOKIE_OPTIONS_HTTPONLY     "false"
--      SetEnv  QUEUEIT_COOKIE_OPTIONS_SECURE       "false"
--      LuaMapHandler  "{URI_PATTERN}"  "{APP_FOLDER}/Handlers/ApacheHandlerUsingConfigFromFile.lua"
--      LuaPackagePath "{APP_FOLDER}/SDK/?.lua"
--      LuaPackagePath "{APP_FOLDER}/Helpers/?/?.lua"
--      LuaPackagePath "{APP_FOLDER}/Handlers/?.lua"
--
-- AUTHOR: Simon Studer (mail@studer.si)
--
-- LICENSE: Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
--
-- VERSION: 1 (2020-01-10)
----------------------------------------------------------------------------------------------------


local DEBUG_TAG = "ApacheHandlerUsingConfigFromFile.lua"

local kuHandler = require("KnownUserApacheHandler")
local file = require("file")

local function initRequiredHelpers(r, cookieOptions)
    local iHelpers = require("KnownUserImplementationHelpers")

    iHelpers.request.getAbsoluteUri = function()
        local fullUrl = string.format("%s://%s%s",
            r.is_https and "https" or "http",
            r.hostname,
            r.unparsed_uri)
        r:debug(string.format("[%s] Rebuilt request URL as: %s", DEBUG_TAG, fullUrl))
        return fullUrl
    end

    iHelpers.response.cookieOptions = cookieOptions
end

function handle(r)

    -- default error behaviour
    local errorResult = apache2.DECLINED

    -- catch errors if any occur
    local success, result = pcall(function()

        -- get configuration from environment variables
        local customerId = r.subprocess_env["QUEUEIT_CUSTOMER_ID"]
        local secretKey = r.subprocess_env["QUEUEIT_SECRET_KEY"]
        local intConfFile = r.subprocess_env["QUEUEIT_INT_CONF_FILE"]
        local errorCode = r.subprocess_env["QUEUEIT_ERROR_CODE"]
        local co_httpOnly = r.subprocess_env["QUEUEIT_COOKIE_OPTIONS_HTTPONLY"]
        local co_secure = r.subprocess_env["QUEUEIT_COOKIE_OPTIONS_SECURE"]

        r:debug(string.format("[%s] Environment variable QUEUEIT_CUSTOMER_ID: %s", DEBUG_TAG, customerId))
        r:debug(string.format("[%s] Environment variable QUEUEIT_SECRET_KEY: %s", DEBUG_TAG, secretKey))
        r:debug(string.format("[%s] Environment variable QUEUEIT_INT_CONF_FILE: %s", DEBUG_TAG, intConfFile))
        r:debug(string.format("[%s] Environment variable QUEUEIT_ERROR_CODE: %s", DEBUG_TAG, errorCode))
        r:debug(string.format("[%s] Environment variable QUEUEIT_COOKIE_OPTIONS_HTTPONLY: %s", DEBUG_TAG, co_httpOnly))
        r:debug(string.format("[%s] Environment variable QUEUEIT_COOKIE_OPTIONS_SECURE: %s", DEBUG_TAG, co_secure))

        assert(customerId ~= nil, "customerId invalid")
        assert(secretKey ~= nil, "secretKey invalid")
        assert(intConfFile ~= nil, "config invalid")

        -- check if valid value
        if (errorCode ~= nil) then
            errorCode = tonumber(errorCode)
            if (errorCode == nil) then
                r:warn(string.format(
                    "[%s] Value of QUEUEIT_ERROR_CODE is not a valid HTTP status code: %s",
                    DEBUG_TAG, r.subprocess_env["QUEUEIT_ERROR_CODE"]))
            elseif (errorCode >= 100) and (errorCode < 600) then
                errorResult = errorCode
            end
        end
        r:debug(string.format("[%s] Value of variable errorCode: %s", DEBUG_TAG, errorCode))

        -- configure cookie options
        local cookieOptions =
        {
            httpOnly = false,
            secure = false
        }

        if (co_httpOnly ~= nil and co_httpOnly == 'true') then cookieOptions.httpOnly = true end
        if (co_secure ~= nil and co_secure == 'true') then cookieOptions.secure = true end

        -- initialize helper functions
        initRequiredHelpers(r, cookieOptions)

        -- read integration configuration from file
        local intConfJson = file.readAll(intConfFile)
        r:debug(string.format("[%s] Content of file %s: %s", DEBUG_TAG, intConfFile, intConfJson))

        -- return the result from handling the request by the SDK
        return kuHandler.handleByIntegrationConfig(customerId, secretKey, intConfJson, r)
    end)

    -- check if error occurred during request handling
    if (success) then
        r:debug(string.format("[%s] Request handling successful: result => %s", DEBUG_TAG, result))
        return result
    else
        r:err(string.format("[%s] Request handling not successful (denying access): error => %s", DEBUG_TAG, result))
        return errorResult
    end
end
