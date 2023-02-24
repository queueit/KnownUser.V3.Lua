# Apache Lua Connector

## Implementation

A quick way to get started with the implementation of this connecotr is to use the ready-made example *[ApacheHandlerUsingConfigFromFile](ApacheHandlerUsingConfigFromFile.lua)* using Apache httpd handler. It ships with the SDK and allows for an easy setup without having to implement a custom Lua handler. All the configuration can be done in the Apache httpd configuration (for example in `httpd.conf` or `apache2.conf`).

Download and store the integration configuration in `/var/www/lua/integration_config.json`.
When the integration configuration changes, this file needs to be updated.

Note that setting a custom error response code using `QUEUEIT_ERROR_CODE` is optional.
If no error code is set, the handler declines to act if an error occurs and the request is let through.

*[ApacheHandlerUsingConfigFromFile](ApacheHandlerUsingConfigFromFile.lua)* also supports cookie flags like `HttpOnly` and `Secure`. 
Please refer to details inside the lua file on how to enable this (and when NOT to). Mentioned flags are as default disabled.

Then, add the following lines to your Apache httpd configuration, filling in the placeholders denoted by braces (e.g. `{CUSTOMER_ID}`):

```apache2
LoadModule lua_module modules/mod_lua.so
[...]
SetEnv  QUEUEIT_CUSTOMER_ID     "{CUSTOMER_ID}"
SetEnv  QUEUEIT_SECRET_KEY      "{SECRET_KEY}"
SetEnv  QUEUEIT_INT_CONF_FILE   "{APP_FOLDER}/integration_config.json"
SetEnv  QUEUEIT_ERROR_CODE      "400"
LuaMapHandler  "{URI_PATTERN}"  "{APP_FOLDER}/ApacheHandlerUsingConfigFromFile.lua"
LuaPackagePath "{APP_FOLDER}/SDK/?.lua"
LuaPackagePath "{APP_FOLDER}/Helpers/?/?.lua"
LuaPackagePath "{APP_FOLDER}/Handlers/?.lua"
```

- {CUSTOMER_ID} = Your customer ID found via GO Queue-it platform.
- {SECRET_KEY} = Your secret key found via GO Queue-it platform.
- {APP_FOLDER} = Apache www folder where your app/integration is located. Ex. 'C:/wamp64/www/lua'. Make sure SDK, Handlers and Helpers folders (incl. content) are copied here. 
- {URI_PATTERN} = Pattern used to match which URLs should go through the handler. https://httpd.apache.org/docs/trunk/mod/mod_lua.html#luamaphandler

#### Resolving current request URL
The SDK needs to be able to resolve the current request URL. It does it by calling the function `getAbsoluteUri` located in *[ApacheHandlerUsingConfigFromFile](ApacheHandlerUsingConfigFromFile.lua)*.

Sometimes this function needs be be adjusted depending on what is available in your infrastructure. Could be that `r.is_https` and/or `r.hostname` are unavailable and then the function call would fail. In these cases you would need to replace with hardcoded values (or settings read from environment variables) ex.:

```
iHelpers.request.getAbsoluteUri = function()   
   local fullUrl = string.format("https://%s%s",
      "my-domain.example",
      r.unparsed_uri)   
   r:debug(string.format("[%s] Rebuilt request URL as: %s", DEBUG_TAG, fullUrl)) 
   return fullUrl
end
```
You will quickly notice if this function fails because its called on each request. Check you Apache logs for any warnings/errors.
The example above (and default implementation) also contains `r:debug` so you can see what URLs are being built. It's important to note that these URLs should be public ones (e.g. use real domain, no internal IPs). You can test this by opening up a browser and visiting that generated URL.

## Alternative Implementation

### Queue configuration
As an alternative to the above, you can specify the configuration in code without using the Trigger/Action paradigm. 
In this case it is important *only to queue-up page requests* and not requests for resources. 
This can be done by adding custom filtering logic before calling the `kuHandler.handleByLocalConfig()` method. 

The following is an example of how the handle function would look if the configuration is specified in code (using ApacheHandler):

```
function handle(request_rec)
   local success, result = pcall
   (
     function()
       local models = require("Models")
       eventconfig = models.QueueEventConfig.create()
       eventconfig.eventId = ""; -- ID of the queue to use
       eventconfig.queueDomain = "xxx.queue-it.net"; -- Domain name of the queue.
       -- eventconfig.cookieDomain = ".my-shop.com"; -- Optional, domain name where the Queue-it session cookie should be saved
       eventconfig.cookieValidityMinute = 15; -- validity of the Queue-it session cookie should be positive number.
       eventconfig.extendCookieValidity = true; -- Should the Queue-it session cookie validity time be extended each time the validation runs?
       -- eventconfig.culture = "en-US"; -- Optional, culture of the queue layout in the format specified here: https:-- msdn.microsoft.com/en-us/library/ee825488(v=cs.20).aspx. If unspecified then settings from Event will be used.
       -- eventconfig.layoutName = "NameOfYourCustomLayout"; -- Optional, name of the queue layout. If unspecified then settings from Event will be used.

       initRequiredHelpers(request_rec)

       kuHandler = require("KnownUserApacheHandler")
	
       return kuHandler.handleByLocalConfig(
         "... INSERT CUSTOMER ID ...", 
         "... INSERT SECRET KEY ...", 
         eventconfig, 
         request_rec)
     end
   )
   
   if (success) then
     return result
   else
     -- There was an error validating the request
     -- Use your own logging framework to log the error
     -- This was a configuration error, so we let the user continue
     return apache2.DECLINED
   end
end
```
