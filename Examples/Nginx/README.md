# Nginx Lua Connector

## Implementation

NOTES: 
  - The following implementation steps have been developed and tested using this [Docker image](https://github.com/fabiocicerchia/nginx-lua).
  - The following example uses `./usr/queueit` as the base path for storing all the Queue-it related files. Review and modify it to your needs.


### 1. Copy the necessary files to your NGINX filesystem

Copy the following two folders from this repository to your NGINX filesystem:
- [SDK](https://github.com/queueit/KnownUser.V3.Lua/tree/master/SDK) -> `./usr/queueit/SDK`
- [Helpers](https://github.com/queueit/KnownUser.V3.Lua/tree/master/Helpers) -> `./usr/queueit/Helpers`

Copy the main handler script: 

- [Handlers/KnownUserNginxHandler.lua](https://github.com/queueit/KnownUser.V3.Lua/blob/master/Handlers/KnownUserNginxHandler.lua) -> `./usr/queueit/KnownUserNginxHandler.lua`
   
 
### 2. Update the package paths

Update or add the `lua_package_path` configuration option in the `http` section of your main configuration file (typically `nginx.conf`) to include the new paths you created in Step 1. Make sure to keep `;;` in the end which means default path:

```
http {
  lua_package_path "./usr/queueit/?.lua;./usr/queueit/SDK/?.lua;./usr/queueit/Helpers/?/?.lua;;";
}
```


### 3. Add the Queue-it handler to a specific location 

Update the configuration file relative to the location you want to be protected by Queue-it (`conf.d/default.conf` or similar):
   
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
            local integrationConfigFile = io.open(integrationConfigFilePath, "r")
            local integrationConfigJson = integrationConfigFile:read("*a")
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
   
- Replace the following two placeholders in the above code `{CUSTOMER_ID}` and `{SECRET_KEY}` with respective values located in GO Queue-it platform.
- NOTE: In this example `rewrite_by_lua_block` directive was added to default location `/` but you must decide what makes sense in your case.
    

### 4) Provide the `integrationconfig.json`...



## Request body trigger (advanced)
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

