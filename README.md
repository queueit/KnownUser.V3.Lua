# KnownUser.V3.Lua
The Queue-it Security Framework is used to ensure that end users cannot bypass the queue by adding a server-side integration to your server. It was developed and verified with Lua v.5.1.

## Introduction
When a user is redirected back from the queue to your website, the queue engine can attach a query string parameter (`queueittoken`) containing some information about the user. 
The most important fields of the `queueittoken` are:

 - q - the users unique queue identifier
 - ts - a timestamp of how long this redirect is valid
 - h - a hash of the token


The high level logic is as follows:

![The KnownUser validation flow](https://github.com/queueit/KnownUser.V3.Lua/blob/master/Documentation/KnownUserFlow.png)

 1. User requests a page on your server
 2. The validation method sees that the has no Queue-it session cookie and no `queueittoken` and sends him to the correct queue based on the configuration
 3. User waits in the queue
 4. User is redirected back to your website, now with a `queueittoken`
 5. The validation method validates the `queueittoken` and creates a Queue-it session cookie
 6. The user browses to a new page and the Queue-it session cookie will let him go there without queuing again

## How to validate a user
To validate that the current user is allowed to enter your website (has been through the queue) these steps are needed:

 1. Providing the queue configuration to the KnownUser validation
 2. Validate the `queueittoken` and store a session cookie


### 1. Providing the queue configuration
The recommended way is to use the Go Queue-it self-service portal to setup the configuration. 
The configuration specifies a set of Triggers and Actions. A Trigger is an expression matching one, more or all URLs on your website. 
When a user enter your website and the URL matches a Trigger-expression the corresponding Action will be triggered. 
The Action specifies which queue the users should be sent to. 
In this way you can specify which queue(s) should protect which page(s) on the fly without changing the server-side integration.

This configuration can then be downloaded to your application server. 
Read more about how *[here](https://github.com/queueit/KnownUser.V3.Lua/tree/master/Documentation)*.  

### 2. Validate the `queueittoken` and store a session cookie
To validate that the user has been through the queue, use the `knownUser.validateRequestByIntegrationConfig` method. 
This call will validate the timestamp and hash and if valid create a "QueueITAccepted-SDFrts345E-V3_[EventId]" cookie with a TTL as specified in the configuration.
If the timestamp or hash is invalid, the user is send back to the queue.

## Implementation

This Lua KnownUser option, should support many different enviroment setups.
Therefore as much code as possible is found within the SDK (https://github.com/queueit/KnownUser.V3.Lua/tree/master/SDK) and the rest is exposed in specific handlers. With this solution the SDK code stays unmodified and only a little work is needed to create or modify a existing handler (https://github.com/queueit/KnownUser.V3.Lua/tree/master/Handlers).

Currently an example handler for Apache (v. 2.4.10+) is available (see below), so if you need something else please reach out to us and then we can help out with creating a new handler, e.g. implementing missing parts from KnownUserImplementationHelpers:
- Read request URL 
- Read request host (user agent IP address)
- Read request headers
- Read request cookies
- Write response cookies

### Apache web server
Example using KnownUserApacheHandler.lua on Apache.

- Edit http.config
```
LoadModule lua_module modules/mod_lua.so
LuaMapHandler "{URI_PATTERN}" "{APP_FOLDER}/handler.lua"
<IfModule lua_module>
 LuaPackagePath "{APP_FOLDER}/SDK/?.lua"
 LuaPackagePath "{APP_FOLDER}/Helpers/?/?.lua"
 LuaPackagePath "{APP_FOLDER}/Handlers/?.lua"
</IfModule>
```
{APP_FOLDER} = Apache www folder where your app/integration is located. Ex. 'C:/wamp64/www/lua'  
{URI_PATTERN} = Pattern used to match which URLs should go through the handler.   https://httpd.apache.org/docs/trunk/mod/mod_lua.html#luamaphandler

- Copy SDK, Handlers and Helpers folders (incl. content) to {APP_FOLDER}

- Create `handler.lua` in {APP_FOLDER}:
```
local function initRequiredHelpers(request_rec)
  iHelpers = require("KnownUserImplementationHelpers")

  iHelpers.request.getAbsoluteUri = function()	
    -- UPDATE BELOW TO MATCH YOUR USE CASE. EX. USE HTTPS AND REMOVE PORT
    return "http://" .. request_rec.hostname .. ":" .. request_rec.port .. request_rec.unparsed_uri
  end  
end

function handle(request_rec)
   local success, result = pcall
   (
      function()
        integrationConfigJson = 
        [[
          ... INSERT INTEGRATION CONFIG ...
        ]]
	
        initRequiredHelpers(request_rec)

        kuHandler = require("KnownUserApacheHandler")
	
        return kuHandler.handleByIntegrationConfig(
           "... INSERT CUSTOMER ID ...", 
           "... INSERT SECRET KEY ...", 
           integrationConfigJson, 
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
Note in the above example, you need to fill in your Customer ID, Secret key, provide the integration config JSON and optionally alter code in method getAbsoluteUri.

Visit `handler.lua` using a browser to see it works.

#### Using local queue configuration
As an alternative to the above, you can specify the configuration in code without using the Trigger/Action paradigm. 
In this case it is important *only to queue-up page requests* and not requests for resources or AJAX calls. 
This can be done by adding custom filtering logic before calling the `kuHandler.handleByLocalConfig()` method. 

The following is an example of how the handle function would look if the configuration is specified in code:

```
function handle(request_rec)
   local success, result = pcall
   (
     function()
       local models = require("Models")
       eventconfig = models.QueueEventConfig.create()
       eventconfig.eventId = ""; -- ID of the queue to use
       eventconfig.queueDomain = "xxx.queue-it.net"; -- Domain name of the queue, usually in the format [CustomerId].queue-it.net
       -- eventconfig.cookieDomain = ".my-shop.com"; -- Optional, domain name where the Queue-it session cookie should be saved
       eventconfig.cookieValidityMinute = 15; -- Optional, validity of the Queue-it session cookie. Default is 10 minutes.
       eventconfig.extendCookieValidity = true; -- Optional, should the Queue-it session cookie validity time be extended each time the validation runs? Default is true.
       -- eventconfig.culture = "en-US"; -- Optional, culture of the queue ticket layout in the format specified here: https:-- msdn.microsoft.com/en-us/library/ee825488(v=cs.20).aspx Default is to use what is specified on Event
       -- eventconfig.layoutName = "NameOfYourCustomLayout"; -- Optional, name of the queue ticket layout e.g. "Default layout by Queue-it". Default is to take what is specified on the Event

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

#### Quick start - using Apache config
A quick way to get started is to use the ready-made Apache httpd handler *[ApacheHandlerUsingConfigFromFile](Examples/ApacheHandlerUsingConfigFromFile.lua)*.
It ships with the SDK and allows for an easy setup without having to implement a custom Lua handler.
All the configuration is done in Apache httpd configuration (for example in `httpd.conf` or `apache2.conf`).

Download and store the integration configuration in `/var/www/lua/integration_config.json`.
When the integration configuration changes, this file needs to be updated.

Note that setting a custom error response code using `QUEUEIT_ERROR_CODE` is optional.
If no error code is set, the handler declines to act if an error occurs and the request is let through.

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
