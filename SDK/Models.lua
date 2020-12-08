local utils = require("Utils")

local models = {
	QueueEventConfig = {
		create = function()
			local model = {
				eventId = nil,
				layoutName = nil,
				culture = nil,
				queueDomain = nil,
				extendCookieValidity = nil,
				cookieValidityMinute = nil,
				cookieDomain = nil,
				version = nil,
				actionName = "unspecified",
				getString = function(self)
					return
						"EventId:" .. utils.toString(self.eventId) ..
						"&Version:" .. utils.toString(self.version) ..
						"&QueueDomain:" .. utils.toString(self.queueDomain) ..
						"&CookieDomain:" .. utils.toString(self.cookieDomain) ..
						"&ExtendCookieValidity:" .. utils.toString(self.extendCookieValidity) ..
						"&CookieValidityMinute:" .. utils.toString(self.cookieValidityMinute) ..
						"&LayoutName:" .. utils.toString(self.layoutName) ..
						"&Culture:" .. utils.toString(self.culture) ..
						"&ActionName:" .. utils.toString(self.actionName)
				end
			}

			return model
		end
	},
	CancelEventConfig = {
		create = function()
			local model = {
				eventId = nil,
				queueDomain = nil,
				cookieDomain = nil,
				version = nil,
				actionName = "unspecified",
				getString = function(self)
					return
						"EventId:" .. utils.toString(self.eventId) ..
						"&Version:" .. utils.toString(self.version) ..
						"&QueueDomain:" .. utils.toString(self.queueDomain) ..
						"&CookieDomain:" .. utils.toString(self.cookieDomain) ..
						"&ActionName:" .. utils.toString(self.actionName)
				end
			}

			return model
		end
	},
	RequestValidationResult = {
		create = function(actionType, eventId, queueId, redirectUrl, redirectType, actionName)
			local model = {
				eventId = eventId,
				redirectUrl = redirectUrl,
				queueId = queueId,
				actionType = actionType,
				redirectType = redirectType,
				isAjaxResult = false,
				actionName = actionName,
				doRedirect = function(self)
					return utils.toString(self.redirectUrl) ~= ''
				end,
				getAjaxQueueRedirectHeaderKey = function()
					return "x-queueit-redirect"
				end,
				getAjaxRedirectUrl = function(self)
					return utils.urlEncode(utils.toString(self.redirectUrl))
				end
			}

			return model
		end
	},
	ActionTypes = {
		QueueAction = "Queue",
		CancelAction = "Cancel",
		IgnoreAction = "Ignore"
	}
}

return models