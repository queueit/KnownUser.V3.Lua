# KnownUser.V3.Lua
The Queue-it Security Framework is used to ensure that end users cannot bypass the queue by adding a server-side integration to your server. It was developed and verified with Lua v.5.1.

## Example usage

#### Apache web server
Prerequirements: 
- Lua module enabled. 
- Content of SDK folder, Helpers/JsonHelper.lua and Handlers/KnownUserApacheHandler.lua has been copied somewhere and added to lua path in Apache config. 

Create **resource.lua** an put in htdocs folder in Apache installation folder:
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
**( ! ) Please note the above code cant be used as it, you will need to update the missing parts like keys, sha256 function and provide integration config json**

Visit **resource.lua** using a browser to see it works.
