# KnownUser.V3.Lua
Before getting started please read the [documentation](https://github.com/queueit/Documentation/tree/main/serverside-connectors) to get acquainted with server-side connectors.

The Lua connector can run on web platforms that support a Lua runtime. The connector and its test suite are exercised on each build against Lua 5.3 and Lua 5.5, and have been verified on Apache linked against Lua 5.3 in production.

**Note for Lua 5.5:** the bundled `Helpers/sha2/sha2.lua` has been patched for Lua 5.5's stricter numeric-`for` semantics (loop control variables are now implicit `<const>`). If you replace it with an unpatched upstream copy you will hit a parse error on Lua 5.5.

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
