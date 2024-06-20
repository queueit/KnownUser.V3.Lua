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
        local integrationConfigFile = io.open(integrationConfigFilePath, "r")
        local integrationConfigJson = integrationConfigFile:read("*a")
        integrationConfigFile:close()

        local qit = require("KnownUserNginxHandler")

        qit.handleByIntegrationConfig(customerId, secretKey, integrationConfigJson)
    }
}
```

Replace the following two placeholders in the above code `{CUSTOMER_ID}` and `{SECRET_KEY}` with respective values located in GO Queue-it platform.

NOTE: In this example `rewrite_by_lua_block` directive was added to default location `/` but you must decide what makes sense in your case. In the specific, excluding any static content you don't want queue-it protection triggering on. This could be images (.png, .jpg), style sheets (.css) and pages (.html).


### 4. Provide the configuration file

The above code requires you to provide the `integrationconfig.json` file which contains the configuration you created on the Queue-it GO platform. Please refer to [this page](https://github.com/queueit/Documentation/tree/main/serverside-connectors/integration-config) for more details.


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
## To handle and ignore OPTIONS requests using Kong

To handle and ignore OPTIONS requests using Kong, you need to create a custom plugin. Kong uses Lua and the OpenResty platform, so the process is quite similar to the OpenResty example. Here’s how you can create a Kong plugin to ignore OPTIONS requests.

### Step 1: Create the Plugin Directory Structure

Create the necessary directories for your custom plugin. Assume the plugin is named `ignore-options`.

```sh
mkdir -p /path/to/kong/plugins/ignore-options
```

### Step 2: Create the Plugin Files

Create the following files in your plugin directory:

1. **handler.lua**
2. **schema.lua**
3. **kong.yml**

#### handler.lua

This file contains the logic to handle the OPTIONS requests.

```lua
local BasePlugin = require "kong.plugins.base_plugin"
local IgnoreOptionsHandler = BasePlugin:extend()

function IgnoreOptionsHandler:new()
  IgnoreOptionsHandler.super.new(self, "ignore-options")
end

function IgnoreOptionsHandler:access(conf)
  IgnoreOptionsHandler.super.access(self)
  
  local method = kong.request.get_method()
  
  if method == "OPTIONS" then
    return kong.response.exit(204, "", {
      ["Access-Control-Allow-Origin"] = "*",
      ["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS",
      ["Access-Control-Allow-Headers"] = "Authorization, Content-Type"
    })
  end
end

IgnoreOptionsHandler.PRIORITY = 1000
IgnoreOptionsHandler.VERSION = "1.0.0"

return IgnoreOptionsHandler
```

#### schema.lua

This file defines the schema for your plugin. For this simple plugin, the schema can be minimal.

```lua
return {
  name = "ignore-options",
  fields = {}
}
```

#### kong.yml

This file registers your plugin with Kong.

```yaml
name: ignore-options
version: 1.0.0

-- Plugin handler
lua: |-
  local handler = require "kong.plugins.ignore-options.handler"
  return handler

-- Plugin schema
schema: |-
  local schema = require "kong.plugins.ignore-options.schema"
  return schema
```

### Step 3: Configure Kong to Use the Plugin

1. **Set the `KONG_PLUGINS` environment variable to include your plugin.**

```sh
export KONG_PLUGINS=bundled,ignore-options
```

2. **Add the plugin to your service or route.**

You can add the plugin to a specific service or route using the Kong Admin API.

```sh
curl -X POST http://localhost:8001/services/{service}/plugins \
    --data "name=ignore-options"
```

Replace `{service}` with the actual service ID or name.

### Step 4: Restart Kong

After configuring the plugin, restart Kong to load the new plugin.

```sh
kong restart
```

### Explanation:

1. **handler.lua**:
   - `IgnoreOptionsHandler` extends the base plugin.
   - The `access` method is overridden to check for the OPTIONS method.
   - If the method is OPTIONS, it responds with a 204 No Content status and appropriate CORS headers.

2. **schema.lua**:
   - Defines the plugin schema. In this case, it’s minimal since there are no configurations needed.

3. **kong.yml**:
   - Registers the plugin handler and schema with Kong.

By following these steps, you can create and use a Kong plugin to ignore OPTIONS requests, returning a 204 No Content response with the necessary CORS headers.
