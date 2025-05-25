-- Custom circular buffer that fits my browsing history needs

local M = {}
M.__index = M

function M.new(size)
	return setmetatable({
		data = {},
		size = size,
		id_last_saved = 0,
		id_last_shown = 0,
	}, M)
end

-- Returns true if we hare browsing the history
-- (i.e. get_prev/get_next called "recently")
function M:ongonig_browse()
	return self.id_last_shown ~= 0
end

-- Reset the "browsing" mode
-- (i.e. ongonig_browse will return false after this)
function M:reset_show()
	self.id_last_shown = 0
end

-- Push a new value, override if data is full
-- reset last shown element
function M:push(value)
	self.id_last_saved = self.id_last_saved + 1
	if self.id_last_saved > self.size then
		self.id_last_saved = 1
	end
	self.data[self.id_last_saved] = value
	self.id_last_shown = 0
end

-- Always returns last pushed
-- returns nil if no data
function M:peek_last()
	return self.data[self.id_last_saved]
end

-- get the previous element.
-- each call gets an older. Wraps.
-- count is reset when new element is :push
-- return nil if no data in buffer
function M:get_prev()
	if self.id_last_shown == 0 then
		self.id_last_shown = self.id_last_saved
	else
		self.id_last_shown = self.id_last_shown - 1
		if self.id_last_shown == 0 then
			self.id_last_shown = #self.data
		end
	end
	return self.data[self.id_last_shown]
end

-- get the next element.
-- each call gets a newer. Wraps
-- count is reset when new element is :push
-- return nil if no data in buffer
function M:get_next()
	if self.id_last_shown == 0 then
		self.id_last_shown = self.id_last_saved + 1
		if self.id_last_shown > #self.data then
			self.id_last_shown = 1
		end
	else
		self.id_last_shown = self.id_last_shown + 1
		if self.id_last_shown > #self.data then
			self.id_last_shown = 1
		end
	end
	return self.data[self.id_last_shown]
end

return M
