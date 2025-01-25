-- Priority Queue implemented in lua, based on a binary heap.
-- Copyright (C) 2017 Lucas de Morais Siqueira <lucas.morais.siqueira@gmail.com>
-- License: zlib
--   This software is provided 'as-is', without any express or implied
--   warranty. In no event will the authors be held liable for any damages
--   arising from the use of this software.
--   Permission is granted to anyone to use this software for any purpose,
--   including commercial applications, and to alter it and redistribute it
--   freely, subject to the following restrictions:
--   1. The origin of this software must not be misrepresented; you must not
--      claim that you wrote the original software. If you use this software
--      in a product, an acknowledgement in the product documentation would be
--      appreciated but is not required.
--   2. Altered source versions must be plainly marked as such, and must not be
--      misrepresented as being the original software.
--   3. This notice may not be removed or altered from any source distribution.
-- modified by xxopxe@gmail.com
-- modified by nara

local floor = math.floor

--- @class pqueue
local pqueue = {}
pqueue.__index = pqueue

setmetatable(
  pqueue,
  {
    --- @return pqueue
    __call = function ()
      local new = {}
      setmetatable(new, pqueue)
      new:initialize()
      return new
    end
  }
)

--- initialization, e.g.
--- ```lua
--- PriorityQueue = require("priority_queue")
--- pq = PriorityQueue()
--- ```
function pqueue:initialize()
  self.heap_val = {}
  self.heap_pri = {}
  self.current_size = 0
end

function pqueue:empty()
  return self.current_size == 0
end

function pqueue:size()
  return self.current_size
end

--- swim up on the tree and fix the order heap property.
function pqueue:swim()
  local heap_val = self.heap_val
  local heap_pri = self.heap_pri
  local floor = floor
  local i = self.current_size

  while floor(i / 2) > 0 do
    local half = floor(i / 2)
    if heap_pri[i] < heap_pri[half] then
      heap_val[i], heap_val[half] = heap_val[half], heap_val[i]
      heap_pri[i], heap_pri[half] = heap_pri[half], heap_pri[i]
    end
    i = half
  end
end

--- put an item on the queue.
--- @param v any the item to be stored
--- @param p number the priority of the item
function pqueue:put(v, p)
  self.current_size = self.current_size + 1
  self.heap_val[self.current_size] = v
  self.heap_pri[self.current_size] = p
  self:swim()
end

--- sink down on the tree and fix the order heap property.
function pqueue:sink()
  local size = self.current_size
  local heap_val = self.heap_val
  local heap_pri = self.heap_pri
  local i = 1

  while (i * 2) <= size do
    local mc = self:min_child(i)
    if heap_pri[i] > heap_pri[mc] then
      heap_val[i], heap_val[mc] = heap_val[mc], heap_val[i]
      heap_pri[i], heap_pri[mc] = heap_pri[mc], heap_pri[i]
    end
    i = mc
  end
end

function pqueue:min_child(i)
  if (i * 2) + 1 > self.current_size then
    return i * 2
  else
    if self.heap_pri[i * 2] < self.heap_pri[i * 2 + 1] then
      return i * 2
    else
      return i * 2 + 1
    end
  end
end

--- remove and return the bottom priority item
--- @return any, number
function pqueue:cull()
    local heap_val = self.heap_val
    local heap_pri = self.heap_pri
    local retval, retprio = heap_val[self.current_size], heap_pri[self.current_size]
    -- Remove the last priority item
    heap_val[self.current_size], heap_pri[self.current_size] = nil, nil
    self.current_size = self.current_size - 1
    return retval, retprio
end

--- remove and return the top priority item
--- @return any, number
function pqueue:pop()
  local heap_val = self.heap_val
  local heap_pri = self.heap_pri
  local retval, retprio = heap_val[1], heap_pri[1]
  heap_val[1], heap_pri[1] = heap_val[self.current_size], heap_pri[self.current_size]
  heap_val[self.current_size], heap_pri[self.current_size] = nil, nil
  self.current_size = self.current_size - 1
  self:sink()
  return retval, retprio
end

--- return the top priority item
--- @return any, number
function pqueue:peek()
  return self.heap_val[1], self.heap_pri[1]
end

return pqueue