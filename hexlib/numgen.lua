local hex     = require("hexlib.common")
local pqueue  = require("hexlib.ds.pqueue")
local grid    = require("hexlib.grid")

--- @class hex.numgen
--- # Target
--- @field valueTarget     number
--- @field isFloating      boolean
--- @field epsilon         number
--- # Graph structure
--- @field nodeParent      number[]         index of parent node
--- @field nodeValue       number[]         value of node
--- @field nodeAngle       hex.angle[]      angle of node
--- @field nodePos         hex.grid.coord[] absolute position of node
--- @field nodeDepth       number[]         length of described path
--- @field nodeNumChilds   number[]         number of child nodes
--- # A* data
--- @field numberOfNodes   number           total number of nodes
--- @field maxFrontierSize number
--- @field heuristicTable  table<number, number>
---
local numgen  = {}
numgen.__index = numgen

--- initializes numgen
--- @return hex.numgen
local function numgen_init()
    local instance = {}
    --- @type hex.numgen
    setmetatable(instance, numgen)
    instance:reset()
    return instance
end

--- resets the state of this numgen instance
function numgen:reset()
    self.nodeAngle       = {}
    self.nodeDepth       = {}
    self.nodeParent      = {}
    self.nodePos         = {}
    self.nodeValue       = {}
    self.nodeNumChilds   = {}
    self.nodeNumChilds   = {}
    self.heuristicTable  = {}
    self.maxFrontierSize = 8192 * 128
end

--- sets a node
--- @param nodeId    number
--- @param parentId  number?
--- @param pos       hex.grid.coord?
--- @param angle     hex.angle?
--- @param value     number?
--- @param depth     number?
--- @param numChilds number?
function numgen:_setNode(nodeId, parentId, pos, angle, value, depth, numChilds)
    --- @format disable
    self.nodeAngle    [nodeId] = angle
    self.nodeDepth    [nodeId] = depth
    self.nodeNumChilds[nodeId] = numChilds
    self.nodeParent   [nodeId] = parentId
    self.nodePos      [nodeId] = pos
    self.nodeValue    [nodeId] = value
end

--- checks if a node intersects with its parents
--- @param nodeId number
function numgen:_noSelfIntersect(nodeId, childPos)
    -- localize frequently accessed fields ands functions
    local isCollision = grid.isEqualGridEdge -- localize this because it is a library function
    local nodePosList = self.nodePos
    local nodeParList = self.nodeParent

    local nodePos       = nodePosList[nodeId]
    local ancestorId    = nodeId
    local ancestorParId = nodeId and nodeParList[ancestorId] or nil

    -- traverse path to root to check for self intersection
    while ancestorId ~= nil and nodeParList[ancestorId] ~= nil do
        if isCollision(
                nodePosList[ancestorId],
                nodePosList[ancestorParId],
                nodePos,
                childPos)
        then
            return false
        end
        ancestorId    = ancestorParId
        ancestorParId = nodeParList[ancestorParId]
    end
    return true
end

--- @type table<hex.angle, fun(x: number): number>
local _angleNumModifiers = {
    --[[ (1) hex.ANGLES.A ]] function(x) return x * 2 end,
    --[[ (2) hex.ANGLES.Q ]] function(x) return x + 5 end,
    --[[ (3) hex.ANGLES.W ]] function(x) return x + 1 end,
    --[[ (4) hex.ANGLES.E ]] function(x) return x + 10 end,
    --[[ (5) hex.ANGLES.D ]] function(x) return x / 2 end,
}

--- explores a node and adds new nodes to internal node list
--- @protected
--- @param nodeId number
--- @return number[]
function numgen:_explore(nodeId)
    local nodeValue   = self.nodeValue[nodeId]
    local nodePos     = self.nodePos[nodeId]
    local parentId    = self.nodeParent[nodeId]
    local childDepth  = self.nodeDepth[nodeId] + 1
    local parentPos   = self.nodePos[parentId]
    local childDirs   = hex.getPossibleDirections(grid.inferDirection(parentPos, nodePos))
    local adjacentPos = grid.adjacentCoordinates(nodePos)

    -- find new children
    local childIds    = {}
    local childIdsPos = 1 -- 'childIds' insertion position, saves having to recount it
    for childAngle, childDir in pairs(childDirs) do
        local childPos = adjacentPos[childDir]
        if self:_noSelfIntersect(nodeId, childPos) then
            local childId    = self.numberOfNodes + 1
            local childValue = _angleNumModifiers[childAngle](nodeValue)

            if not self.isFloating and childValue > self.valueTarget * 2 then
                goto next_child
            end

            self:_setNode(childId, nodeId, childPos, childAngle, childValue, childDepth, 0)
            childIds[childIdsPos] = childId
            childIdsPos = childIdsPos + 1

            self.numberOfNodes = childId
            self.nodeNumChilds[nodeId] = self.nodeNumChilds[nodeId] + 1
        end
        ::next_child::
    end
    return childIds
end

--- remove 'nodeId' and any ancestor with no children
--- @protected
--- @param nodeId number
function numgen:_cull(nodeId)
    while self.nodeNumChilds[nodeId] <= 0 do
        local parentId = self.nodeParent[nodeId]
        self.nodeNumChilds[parentId] = self.nodeNumChilds[parentId] - 1
        self:_setNode(nodeId, nil, nil, nil, nil, nil, nil)
        nodeId = parentId
    end
end

--- check if a goal is reached
--- @protected
--- @param nodeId number
--- @return boolean
function numgen:_judge(nodeId)
    local value = self.nodeValue[nodeId]
    if self.isFloating then
        if (self.heuristicTable[value] and self.heuristicTable[value] == 0) then
            return true
        end
        return
            value <= self.valueTarget * (1 + self.epsilon) and
            value >= self.valueTarget * (1 - self.epsilon)
    else
        return value == self.valueTarget
    end
end

--- @type (fun(x: number): number)[]
local _invModifiers = {
    function(x) return x - 1 end,
    function(x) return x - 5 end,
    function(x) return x - 10 end,
    function(x) return x * 2 end,
    function(x) return x / 2 end,
}

--- builds a lookup table to find a fast and accurate heuristic
--- @param iterations number number of iterations
function numgen:_buildHeuristic(iterations)
    if self.isFloating then
        self.valueTarget = math.ceil(self.valueTarget * self.precision) / self.precision
        print("Targeting " .. self.valueTarget .. " instead")
    end

    local floor     = math.floor -- localize library function
    local heuristic = { [self.valueTarget] = 0 }
    local frontier  = { self.valueTarget }
    for i = 1, iterations do
        local explorePos = 1
        local explored = {}
        for j = 1, #frontier do
            local value = frontier[j]
            for k = 1, #_invModifiers do
                local newValue = _invModifiers[k](value)
                local isValid = newValue >= 0 and not heuristic[newValue]
                if self.isFloating then
                    isValid = isValid and (self.valueTarget < 1 or newValue >= 1)
                else
                    isValid = isValid and newValue == floor(newValue) and newValue <= self.valueTarget * 2
                end

                if isValid then
                    heuristic[newValue]  = i
                    explored[explorePos] = newValue
                    explorePos = explorePos + 1
                end
            end
        end
        frontier = explored
    end
    self.heuristicTable = heuristic
end

--- apply the heuristic to the node
--- @protected
--- @param nodeId number
--- @return number
function numgen:_estimate(nodeId)
    local value = self.nodeValue[nodeId]
    if self.isFloating then
        value = math.ceil(value * self.precision) / self.precision
    end
    local heuristic = self.heuristicTable[value]
    if heuristic ~= nil then
        return heuristic
    end
    -- fallback heuristic
    if value > self.valueTarget then
        -- value it bigger than target
        local steps = 0
        while value > self.valueTarget do
            steps = steps + 1
            value = value / 2
        end
        return steps
    end
    return math.abs(value - self.valueTarget)
end

--- use a* to search possible numbers
--- @protected
--- @param startId number
--- @return number
function numgen:_astar(startId)
    --- @type pqueue
    local frontier = pqueue()
    frontier:put(startId, 0)
    repeat
        --- @type number[]
        local nodeIds = self:_explore(frontier:pop())
        for i = 1, #nodeIds do
            local nodeId = nodeIds[i]
            -- check if node is goal state
            local value = self.nodeValue[nodeId]
            if self.isFloating then
                if (self.heuristicTable[value] and self.heuristicTable[value] == 0) then
                    return nodeId
                elseif
                    value <= self.valueTarget * (1 + self.epsilon) and
                    value >= self.valueTarget * (1 - self.epsilon) 
                then
                    return nodeId
                end
            elseif value == self.valueTarget then
                return nodeId
            end

            frontier:put(nodeId, self.nodeDepth[nodeId] + self:_estimate(nodeId))

            -- if frontier:size() > self.maxFrontierSize then
            --     self:_cull(frontier:cull())
            -- end
        end
    until frontier:empty()
    error("Could not find path to resolve number!")
end

--- sets up the positive or negative zero-value path
--- @return number
function numgen:_zeroPath()
    local clock  = { hex.ANGLES.A, hex.ANGLES.Q }
    local coords = {
        { -1, 0,  0 }, -- WEST
        { -1, 0,  1 }, -- SOUTH_WEST
        { 0,  0,  0 }, -- ORIGIN
        { -1, -1, 1 }, -- NORTH_WEST
        { -1, 0,  1 }, -- WEST
        { 0,  0,  0 }, -- ORIGIN
    }
    if self.valueTarget < 0 then
        clock = { hex.ANGLES.D, hex.ANGLES.E }
        coords[2], coords[4] = coords[4], coords[2]
        self.valueTarget = -self.valueTarget
    end
    local angles   = { nil, nil, clock[1], clock[2], clock[1], clock[1], }
    local parentId = nil
    for i = 1, 6, 1 do
        self:_setNode(i, parentId, coords[i], angles[i], 0, i, 1)
        parentId = i
    end
    self.nodeNumChilds[6] = 0
    self.numberOfNodes = 6
    return 6
end

--- reconstructs a path from a node
--- @param nodeId number
--- @return string
function numgen:_buildPath(nodeId)
    local chars = {}
    while nodeId > 2 do
        chars[self.nodeDepth[nodeId] - 2] = hex.ANGLE_NAMES[self.nodeAngle[nodeId]]
        nodeId = self.nodeParent[nodeId]
    end
    return table.concat(chars)
end

--- finds a number pattern using a*
--- @param number number
--- @return string
function numgen:find(number)
    self.valueTarget = number
    self.isFloating  = math.floor(number) ~= number
    self.precision   = 1
    if self.isFloating then
        self.epsilon   = 0.0
        self.precision = 32
        if math.abs(number) < 1 then
            self.epsilon   = 0.01
            self.precision = 128
        end
        self:_buildHeuristic(24)
    else 
        self:_buildHeuristic(128)
    end

    print("Building heuristic")
    print("Starting search")
    local startId = self:_zeroPath()
    local finalId = self:_astar(startId)
    print("Got value: " .. self.nodeValue[finalId])
    local path    = self:_buildPath(finalId)
    print("Path length:" .. #path)
    return path
end

return numgen_init
