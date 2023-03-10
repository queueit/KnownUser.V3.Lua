# Apache Lua Connector


## Requirements
- The minimum working version of Apache is v.2.3. This is the lowest version on which the Lua module can be enabled.
- Lua module v.5.1. enabled in the Apache configuration. **Using a Lua module with a version number higher than this (ex. v.5.3) will not work.**


## Implementation
A quick way to get started with the implementation of this connecotr is to use the ready-made example *[ApacheHandlerUsingConfigFromFile](ApacheHandlerUsingConfigFromFile.lua)* which uses the Apache httpd handler. It ships with the SDK and allows for an easy setup without having to implement a custom Lua handler. All the configuration can be done in the Apache httpd configuration (for example in `httpd.conf` or `apache2.conf`).


### 1. Download the Queue-it Lua connector to the {LIB_FOLDER}
A good best-practice is to store it in the `/usr/local/lib/` folder. Go to that folder, download the latest release from this repository and extract it:

```bash
cd /usr/local/lib
curl https://github.com/queueit/KnownUser.V3.Lua/archive/refs/tags/3.7.tar.gz -o lua.tar.gz
tar -xf lua.tar.gz
rm lua.tar.gz
```

This way the library is now extracted to `/usr/local/lib/KnownUser.V3.Lua-3.7`. So, in the below configuration where you see `{LIB_FOLDER}` you will need to replace it with the above path.


### 2. Download the Queue-it integration configuration file to the {CFG_FILE}
A good best-practice is to store it in the `/usr/local/etc/` folder. Go to that folder and download the latest integration configuration file from the Queue-it API. To do so, you will need to grab your [API key from the GO plaform](https://go.queue-it.net/app/account/api-keys). 

```bash
curl --request GET https://[your-customer-id].queue-it.net/status/integrationconfig/secure/[your-customer-id] --header "api-key: [your-API-key]" --header "Host: queue-it.net" > /usr/local/etc/qit_integration_configuration.json
```

This way the configuration file is now stored as `/usr/local/etc/qit_integration_configuration.json`. So, in the below configuration where you see `{CFG_FILE}` you will need to replace it with the above path.


Note that whenever you change and publish a new configuration on the GO platform, this file needs to be updated. You can just re-issue the above curl command to pull the configuration again. For more advanced/automated metods please refer to the [Downloading the Integration Configuration](https://github.com/queueit/Documentation/tree/main/serverside-connectors/integration-config) guide.


### 3. Place the implementation code to the Apache web server configuration
The following code snippet needs to be added to the relevant section of the Apache configuration file.

```apacheconf 
SetEnv          QUEUEIT_CUSTOMER_ID     "{CUSTOMER_ID}"
SetEnv          QUEUEIT_SECRET_KEY      "{SECRET_KEY}"
SetEnv          QUEUEIT_INT_CONF_FILE   "{CFG_FILE}"
SetEnv          QUEUEIT_ERROR_CODE      "400"
LuaMapHandler   "{URI_PATTERN}"         "{LIB_FOLDER}/ApacheHandlerUsingConfigFromFile.lua"
LuaPackagePath  "{LIB_FOLDER}/SDK/?.lua"
LuaPackagePath  "{LIB_FOLDER}/Helpers/?/?.lua"
LuaPackagePath  "{LIB_FOLDER}/Handlers/?.lua"
```

All the placeholders in the above configuration snippet need to be replaced with the correct values:

- {CUSTOMER_ID} = Your Customer ID can be found on the [Company Profile](https://go.queue-it.net/companyprofile) section of the GO platform.
- {SECRET_KEY} = Your KnownUser secret key can be found on the Integration tab of the [Account Settings](https://barcelona.go.queue-it.net/account/settings) section of the GO platform.
- {LIB_FOLDER} = The path to the folder used in Step 1. where the connector library was downloaded.
- {CFG_FILE} = The path to the folder used in Step 1. where the connector library was downloaded. 
- {URI_PATTERN} = Pattern used to match which requests should go through the handler. The default configuration is `/` (forward slash) which will trigger the handler on all requests. The trigger will then use the integration configuration to decide what wil be redirected or ignored. For fine tuning this configuration please refer to the [LuaMapHandler](https://httpd.apache.org/docs/trunk/mod/mod_lua.html#luamaphandler) documentation.

Note that setting a custom error response code using `QUEUEIT_ERROR_CODE` is optional.
If no error code is set, the handler declines to act if an error occurs and the request is let through.

### 4. Reload the Apache configuration
With the modified configuration in place you need to reload the Apache service (tipically with `systemctl reload apache2` or `/etc/init.d/apache2 reload`). Now, you can test by requesting a protected URL.


## Customizing the Handler
There might be specific circumstances in which you need to review and change the default behaviour of the handler file or the included functions. 

One of these circumstances is when the `getAbsoluteUri` located in [ApacheHandlerUsingConfigFromFile](ApacheHandlerUsingConfigFromFile.lua) needs be be adjusted because the `r.is_https` and/or `r.hostname` variables are unavailable on your specific infrastructure. In these cases you would need to replace with hardcoded values (or settings read from environment variables) to mach that of your environment. For example:

```lua
iHelpers.request.getAbsoluteUri = function()   
   local fullUrl = string.format("https://%s%s",
      "my-domain.example",
      r.unparsed_uri)   
   r:debug(string.format("[%s] Rebuilt request URL as: %s", DEBUG_TAG, fullUrl)) 
   return fullUrl
end
```

The example above (and default implementation) also contains `r:debug` so you can see what URLs are being built. It's important to note that these URLs should be public ones (e.g. use real domain, no internal IPs). You can test this by opening up a browser and visiting that generated URL.


## Alternative implementation using inline configuration
As an alternative to the above, you can specify the configuration in code without using the Trigger/Action paradigm and therefore without using the integration configuratin json file. In this case it is important *only to queue-up page requests* and not requests for other resources (assets). 
This can be done by adding custom filtering logic before calling the `kuHandler.handleByLocalConfig()` method. 

The following is an example of how the handle function would look if the configuration is specified in code (using ApacheHandler):

```lua
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
