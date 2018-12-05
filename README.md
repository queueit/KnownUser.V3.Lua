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
To validate that the user has been through the queue, use the `KnownUser.ValidateRequestByIntegrationConfig()` method. 
This call will validate the timestamp and hash and if valid create a "QueueITAccepted-SDFrts345E-V3_[EventId]" cookie with a TTL as specified in the configuration.
If the timestamp or hash is invalid, the user is send back to the queue.

## Implementation

This Lua KnownUser option, should support many different enviroment setups.
Therefore as much code as possible is found within the SDK (https://github.com/queueit/KnownUser.V3.Lua/tree/master/SDK) and the rest is exposed in specific handlers. With this solution the SDK code stays unmodified and only a little work is needed to create or modify a existing handler (https://github.com/queueit/KnownUser.V3.Lua/tree/master/Handlers).

Currently an example (+ handler) for Apache on Windows is available (see below), so if you need something else please reach out to us and then we can help out with creating a new handler, e.g. implementing missing parts from KnownUserImplementationHelpers:
- json parsing
- hmac sha256 encoding
- read request url and host (ip)
- read request headers
- read request cookies
- write response cookies

#### Apache web server
Example using KnownUserApacheHandler.lua on Apache running on Windows.

Prerequirements: 
- Lua module enabled. 
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
      local n = os.tmpname()
		
      -- Calling external program to calculate hash and pipe it into temp file
      -- this exe must be in root folder of Apache
      -- replace this part with whatever you have available
      os.execute('Sha256Hmac.exe "' .. message ..'" "' .. key .. '" > ' .. n)

      local hash = nil
      for line in io.lines(n) do
	  hash = line
      end

      os.remove(n)

      if (hash == nil or hash == "") then
	  error("hmac_sha256_encode failed: Please verify your implementation code")		
      end
      return hash
    end
end

function handle(request_rec)
  integrationConfigJson = 
  [[
    ... INSERT INTEGRATION CONFIG ...
  ]]
	
  initRequiredHelpers()

  kuHandler = require("KnownUserApacheHandler")
	
  return kuHandler.handle(
    "... INSERT CUSTOMER ID ...", 
    "... INSERT SECRET KEY ...", 
    integrationConfigJson, 
    request_rec)
end
```
Note in the above example, you need to fill in your key, sha256 function and provide the integration config json.

Visit `resource.lua` using a browser to see it works.
