# Nginx Lua Connector

## Implementation

# Nginx Lua Connector

## Implementation

Copy `KnownUserNginxHandler.lua` and folders (`SDK` and `Helpers`) incl. their content to your NGINX filesystem (in the following example we have added it to `usr/queueit`).

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
        -- You will need to decide where to store and load this file (caching layer, database ect.).
        -- Remember this will be done on all requests, so the selected option must be fast (not causing bottlenecks).
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
In this example `rewrite_by_lua_block` have been added to default location `\` but you must decide what makes sense in your case.

Please note the comments in the code below about providing `integrationconfig.json` and replace `CUSTOMER_ID` and `SECRET_KEY` with correct credentials found in GO Queue-it platform.

### Request body trigger (advanced)
Nginx handler (incl. Lua SDK) supports triggering on request body content. Example could be a POST call with specific item ID where you want end-users to queue up for.
You will need to contact queue-it support if this functionality is needed, so it can be enabled on your GO Queue-it platform account.
When enabled you also need to add extra settings to `location` in `conf.d/default.conf`:

```
location / {
  ...
  lua_need_request_body on; # enabling reading of request body
  client_body_buffer_size 64k; # ensure large buffer for requst body (PLEASE DECIDE WHAT BUFFER SIZE IS RELEVANT IN YOUR CASE)
  ...
}
```

