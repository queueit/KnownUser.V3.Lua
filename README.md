# KnownUser.V3.Lua
Before getting started please read the [documentation](https://github.com/queueit/Documentation/tree/main/serverside-connectors) to get acquainted with server-side connectors.

The Lua connector can run on web platforms that support a LUA runtime. It was developed and verified with Lua v.5.1. 

**Using it with Lua versions higher than this (ex. v.5.3) will not work**.

The connector works by having all general code within the [SDK](https://github.com/queueit/KnownUser.V3.Lua/tree/master/SDK) and platform specific code in handlers. 
With this solution the SDK code stays unmodified and only a little work is needed to create or modify [handlers](https://github.com/queueit/KnownUser.V3.Lua/tree/master/Handlers).

Currently we offer handlers and tested example code for the following platforms: 

- [Apache](Examples/Apache)
- [Nginx](Examples/Nginx)

However if you have another platform it's straitforward to implement the missing parts in a new handler.

To create a platform handler you will need to implement the missing parts in `KnownUserImplementationHelpers.lua`:
- Read request URL 
- Read request host (user agent IP address)
- Read request headers
- Read request cookies
- Write response cookies

Look at existing [handlers](https://github.com/queueit/KnownUser.V3.Lua/tree/master/Handlers) for inspiration.
