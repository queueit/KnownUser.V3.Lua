# KnownUser.V3.Lua
The Queue-it Security Framework is used to ensure that end users cannot bypass the queue by adding a server-side integration to your server. It was developed and verified with Lua v.5.1. **Running this SDK on Lua versions higher than this (ex. v.5.3) will not work**.   

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
To validate that the user has been through the queue, use the `knownUser.validateRequestByIntegrationConfig` method. 
This call will validate the timestamp and hash and if valid create a "QueueITAccepted-SDFrts345E-V3_[EventId]" cookie with a TTL as specified in the configuration.
If the timestamp or hash is invalid, the user is send back to the queue.

## Implementation

The Lua connector SDK can run on web platforms that support a LUA runtime.
It works by having all general code within the SDK (https://github.com/queueit/KnownUser.V3.Lua/tree/master/SDK) and platform specific code in handlers. 
With this solution the SDK code stays unmodified and only a little work is needed to create or modify handlers (https://github.com/queueit/KnownUser.V3.Lua/tree/master/Handlers).

Currently we offer handlers and tested example code for the following platforms: 

- [Apache](Examples/Apache)
- [Nginx](Examples/Nginx)

However if you have another platform it's straitforward to implement the missing parts in a new handler.

To create a platform handler you will need to implement the missing parts in KnownUserImplementationHelpers.lua:
- Read request URL 
- Read request host (user agent IP address)
- Read request headers
- Read request cookies
- Write response cookies

Look at existing handlers for inspiration.

### Protecting ajax calls
If you need to protect AJAX calls beside page loads you need to add the below JavaScript tags to your pages:

```
<script type="text/javascript" src="//static.queue-it.net/script/queueclient.min.js"></script>
<script
 data-queueit-intercept-domain="{YOUR_CURRENT_DOMAIN}"
   data-queueit-intercept="true"
  data-queueit-c="{YOUR_CUSTOMER_ID}"
  type="text/javascript"
  src="//static.queue-it.net/script/queueconfigloader.min.js">
</script>
```
