# Nginx Lua Connector

## Implementation

NOTES:
- The following implementation steps have been developed and tested using this [Docker image](https://github.com/fabiocicerchia/nginx-lua).
- The following example uses `./usr/queueit` as the base path for storing all the Queue-it related files. Review and modify it to your needs.


### 1. Copy the necessary files to your NGINX filesystem

Copy the following two folders from this repository to your NGINX filesystem:
- [SDK](../../SDK) -> `./usr/queueit/SDK`
- [Helpers](../../Helpers) -> `./usr/queueit/Helpers`

Copy the main handler script:

- [Handlers/KnownUserNginxHandler.lua](../../Handlers/KnownUserNginxHandler.lua) -> `./usr/queueit/KnownUserNginxHandler.lua`


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

Replace the following two placeholders in the above code `{CUSTOMER_ID}` and `{SECRET_KEY}` with respective values located in GO Queue-it platform.

NOTE: In this example `rewrite_by_lua_block` directive was added to default location `/` but you must decide what makes sense in your case. In the specific, excluding any static content you don't want queue-it protection triggering on. This could be images (.png, .jpg), style sheets (.css) and pages (.html).


### 4. Provide the configuration file

The above code requires you to provide the `integrationconfig.json` file which contains the configuration you created on the Queue-it GO platform ([more info here](../../README.md#1-providing-the-queue-configuration)). There are various ways to provide this file. Please read the [specific documentation here](../../Documentation/README.md).


## Request body trigger (advanced)
The Nginx handler (incl. Lua SDK) supports triggering on request body content. An example could be a POST call with specific item ID where you want end-users to queue up for.
For this to work, you will need to contact queue-it support, so it can be enabled on your GO Queue-it platform account.
Once enabled, you will need to add these extra settings to your configuration:

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
