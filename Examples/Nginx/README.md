# Nginx Lua Connector

## Implementation

NOTE: The following implementation steps have been developed and tested using this [Docker image](https://github.com/fabiocicerchia/nginx-lua).

Copy [KnownUserNginxHandler.lua](https://github.com/queueit/KnownUser.V3.Lua/blob/master/Handlers/KnownUserNginxHandler.lua) and folders ([SDK](https://github.com/queueit/KnownUser.V3.Lua/tree/master/SDK) and [Helpers](https://github.com/queueit/KnownUser.V3.Lua/tree/master/Helpers)) incl. their content to your NGINX filesystem (in the following example we have added it to `usr/queueit`).

Then update/add `lua_package_path` in your `nginx.conf` to include the new path (keep `;;` in the end which means default path):

```
http {
  lua_package_path "./usr/queueit/?.lua;./usr/queueit/SDK/?.lua;./usr/queueit/Helpers/?/?.lua;;";
}
```

Then update `conf.d/default.conf`:
```
server {
  location / {
    rewrite_by_lua_block {
        local customerId = "{CUSTOMER_ID}"
        local secretKey = "{SECRET_KEY}"

        -- Basic example where integration configuration file is loaded from disk.
        -- Please use this for testing / PoC etc., e.g. not on production environment.
        -- For production / final integration you need to decide where to store and load this file. 
        -- Could be a caching layer, environment variable, database ect.
        -- It's important that the selected option is fast, 
        -- not causing any performance bottlenecks because the file would be loaded on each request.
        local integrationConfigFilePath = "./usr/queueit/integrationconfig.json"
        local integrationConfigFile = io.open(integrationConfigFilePath, "rb")
        local integrationConfigJson = integrationConfigFile:read("*all")
        integrationConfigFile:close()

        local qit = require("KnownUserNginxHandler")

        -- If you want to enable secure or http only cookie settings then change options below.
        -- httpOnly: Only enable if you use pure server-side integration e.g. not JS Hybrid.
        -- secure: Only enable if your website runs purely on https.
        qit.setOptions({ httpOnly = false, secure = false })

        qit.handleByIntegrationConfig(customerId, secretKey, integrationConfigJson)
    }
}
```
In this example `rewrite_by_lua_block` have been added to default location `/` but you must decide what makes sense in your case.
Especially excluding any static content you don't want queue-it protection triggering on. This could be images (.png, .jpg), style (.css) and pages (.html).  

Please note the comments in the code about providing `integrationconfig.json` ([read more](https://github.com/queueit/KnownUser.V3.Lua#1-providing-the-queue-configuration)) and replacing `CUSTOMER_ID` and `SECRET_KEY` with correct credentials located in GO Queue-it platform.

### Request body trigger (advanced)
Nginx handler (incl. Lua SDK) supports triggering on request body content. Example could be a POST call with specific item ID where you want end-users to queue up for.
You will need to contact queue-it support if this functionality is needed, so it can be enabled on your GO Queue-it platform account.
When enabled you also need to add extra settings to `location` in `conf.d/default.conf`:

```
location / {
  ...
  # enabling reading of request body
  lua_need_request_body on; 
  
  # ensure large buffer for requst body (PLEASE DECIDE WHAT BUFFER SIZE IS RELEVANT IN YOUR CASE)
  client_body_buffer_size 64k; 
  ...
}
```

