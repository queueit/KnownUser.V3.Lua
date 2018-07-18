# KnownUser.V3.Lua
The Queue-it Security Framework is used to ensure that end users cannot bypass the queue by adding a server-side integration to your server. Tested and verified using Lua v.5.1.

#### Example usage on Apache web server with Lua module installed
```
function handle(r)
  local integrationConfigJson =
  [[
    PUT YOUR INTEGRATION CONFIGURATION HERE	
  ]]
	
  handler = require("KnownUserApacheHandler")

  return handler.handle(
    "{YOUR CUSTOMER ID}", 
    "{YOUR SECRET KEY}",
    integrationConfigJson,
    r)
end
```
