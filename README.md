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

Currently an example (+ handler) for Apache on Windows is available (see below), so if you need something else please reach out to us and then we can help out with creating a new handler, e.g. implementing missing parts from KnownUserImplementationHelpers:
- JSON parsing
- HMAC SHA256 encoding
- Read request url and host (ip)
- Read request headers
- Read request cookies
- Write response cookies

### Apache web server
Example using KnownUserApacheHandler.lua on Apache.

Prerequirements: 
- Lua module enabled.
- HMAC Lua library installed (https://luarocks.org/modules/luarocks/sha2)
- Content of SDK folder, `Helpers/JsonHelper.lua` and `Handlers/KnownUserApacheHandler.lua` has been copied somewhere and added to lua path in Apache config. 

Create `resource.lua` an put in htdocs folder in Apache installation folder:
```
function initRequiredHelpers()
    iHelpers = require("KnownUserImplementationHelpers")
    jsonHelper = require("JsonHelper")

    iHelpers.json.parse = function(jsonStr)
      return jsonHelper.parse(jsonStr)
    end

    iHelpers.hash.hmac_sha256_encode = function(message, key)		
      local function bintohex(s)
        return (s:gsub('(.)', function(c) 
	  return string.format('%02x', string.byte(c)) 
	  end))
      end

      require "hmac.sha2"
      return bintohex(hmac.sha256(message, key))      
    end
end

function handle(request_rec)
  integrationConfigJson = 
  [[
    ... INSERT INTEGRATION CONFIG ...
  ]]
	
  initRequiredHelpers()

  kuHandler = require("KnownUserApacheHandler")
	
  return kuHandler.handleByIntegrationConfig(
    "... INSERT CUSTOMER ID ...", 
    "... INSERT SECRET KEY ...", 
    integrationConfigJson, 
    request_rec)
end
```
Note in the above example, you need to fill in your Customer ID, Secret key and provide the integration config JSON.

Visit `resource.lua` using a browser to see it works.

#### Using local queue configuration
As an alternative to the above, you can specify the configuration in code without using the Trigger/Action paradigm. 
In this case it is important *only to queue-up page requests* and not requests for resources or AJAX calls. 
This can be done by adding custom filtering logic before caling the `kuHandler.handleByLocalConfig()` method. 

The following is an example of how the handle function would look if the configuration is specified in code:

```
function handle(request_rec)
  local models = require("Models")
  eventconfig = models.QueueEventConfig.create()
  eventconfig.eventId = ""; -- ID of the queue to use
  eventconfig.queueDomain = "xxx.queue-it.net"; -- Domain name of the queue, usually in the format [CustomerId].queue-it.net
  -- eventconfig.cookieDomain = ".my-shop.com"; -- Optional, domain name where the Queue-it session cookie should be saved
  eventconfig.cookieValidityMinute = 15; -- Optional, validity of the Queue-it session cookie. Default is 10 minutes.
  eventconfig.extendCookieValidity = true; -- Optional, should the Queue-it session cookie validity time be extended each time the validation runs? Default is true.
  -- eventconfig.culture = "en-US"; -- Optional, culture of the queue ticket layout in the format specified here: https:-- msdn.microsoft.com/en-us/library/ee825488(v=cs.20).aspx Default is to use what is specified on Event
  -- eventconfig.layoutName = "NameOfYourCustomLayout"; -- Optional, name of the queue ticket layout e.g. "Default layout by Queue-it". Default is to take what is specified on the Event

  initRequiredHelpers()

  kuHandler = require("KnownUserApacheHandler")
	
  return kuHandler.handleByLocalConfig(
    "... INSERT CUSTOMER ID ...", 
    "... INSERT SECRET KEY ...", 
    eventconfig, 
    request_rec)
end
```
