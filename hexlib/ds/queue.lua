--- Deque implementation by Pierre 'catwell' Chapuis
--- MIT licensed (see LICENSE.txt)
--- modified by nara

--- @class queue
--- @field private head number
--- @field private tail number
local queue = {}

--- @param x any
function queue:push_right(x)
    assert(x ~= nil)
    self.tail = self.tail + 1
    self[self.tail] = x
end

--- @param x any
function queue:push_left(x)
    assert(x ~= nil)
    self[self.head] = x
    self.head = self.head - 1
end

--- @return any
function queue:peek_right()
    return self[self.tail]
end

--- @return any
function queue:peek_left()
    return self[self.head + 1]
end

--- @return any
function queue:pop_right()
    if self:is_empty() then return nil end
    local r = self[self.tail]
    self[self.tail] = nil
    self.tail = self.tail - 1
    return r
end

--- @return any
function queue:pop_left()
    if self:is_empty() then return nil end
    local r = self[self.head + 1]
    self.head = self.head + 1
    local r = self[self.head]
    self[self.head] = nil
    return r
end

--- @param n number
function queue:rotate_right(n)
    n = n or 1
    if self:is_empty() then return nil end
    for i = 1, n do self:push_left(self:pop_right()) end
end

--- @param n number
function queue:rotate_left(n)
    n = n or 1
    if self:is_empty() then return nil end
    for i = 1, n do self:push_right(self:pop_left()) end
end

--- @protected
--- @param idx number
function queue:_remove_at_internal(idx)
    for i = idx, self.tail do self[i] = self[i + 1] end
    self.tail = self.tail - 1
end

--- @param x any
function queue:remove_right(x)
    for i = self.tail, self.head + 1, -1 do
        if self[i] == x then
            self:_remove_at_internal(i)
            return true
        end
    end
    return false
end

--- @param x any
function queue:remove_left(x)
    for i = self.head + 1, self.tail do
        if self[i] == x then
            self:_remove_at_internal(i)
            return true
        end
    end
    return false
end

--- @return number
function queue:length()
    return self.tail - self.head
end

--- @return boolean
function queue:is_empty()
    return self:length() == 0
end

function queue:contents()
    local r = {}
    for i = self.head + 1, self.tail do
        r[i - self.head] = self[i]
    end
    return r
end

--- @return fun(): any
function queue:iter_right()
    local i = self.tail + 1
    return function()
        if i > self.head + 1 then
            i = i - 1
            return self[i]
        end
    end
end

--- @return fun(): any
function queue:iter_left()
    local i = self.head
    return function()
        if i < self.tail then
            i = i + 1
            return self[i]
        end
    end
end

return {
    --- @return queue
    new = function()
        local data = { head = 0, tail = 0 }
        return setmetatable(data, { __index = queue })
    end
}
