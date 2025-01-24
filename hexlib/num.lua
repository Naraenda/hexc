local hex               = require("hexlib.common")
local grid              = require("hexlib.grid")
local queue             = require("hexlib.ds.queue")
local pqueue            = require("hexlib.ds.pqueue")

--- @type table<hex.angle, fun(x: number): number>
local angleNumModifiers = {
    [hex.ANGLES.A] = function(x) return x * 2 end,
    [hex.ANGLES.Q] = function(x) return x + 5 end,
    [hex.ANGLES.W] = function(x) return x + 1 end,
    [hex.ANGLES.E] = function(x) return x + 10 end,
    [hex.ANGLES.D] = function(x) return x / 2 end,
}

--- @param node hex.num.node
--- @return hex.num.node[]
local function exploreNode(node, skipFunction)
    local parent = node.parent

    local neighbors = grid.adjacentCoordinates(node.position)
    local childDirs = nil
    if parent == nil then
        childDirs = hex.getPossibleDirections(hex.DIRECTIONS.EAST)
        childDirs[hex.ANGLES.A] = nil
        childDirs[hex.ANGLES.D] = nil
    else
        childDirs = hex.getPossibleDirections(grid.inferDirection(parent.position, node.position))
    end

    --- @type hex.num.node[]
    local children = {}
    for angle, childDir in pairs(childDirs) do
        --- @type hex.num.node
        local child = {
            position = neighbors[childDir],
            value    = angleNumModifiers[angle](node.value),
            depth    = node.depth + 1,
            parent   = nil,
            angle    = angle,
        }

        if skipFunction and skipFunction(child) then
            goto next_child
        end

        -- check ancestry (i.e. parent's parents) if path is already used
        local ancestry = parent
        if ancestry ~= nil and ancestry.parent ~= nil then
            repeat
                if grid.isEqualGridEdge(
                        ancestry.position,
                        ancestry.parent.position,
                        node.position,
                        child.position)
                then
                    goto next_child
                end

                ancestry = ancestry.parent
            until ancestry == nil or ancestry.parent == nil
        end

        child.parent = node
        table.insert(children, child)
        ::next_child::
    end
    return children
end

--- @param node hex.num.node
--- @return string
local function rebuildPath(node)
    local buffer = queue.new()

    while node ~= nil and node.angle ~= nil do
        buffer:push_right(node.angle)
        node = node.parent
    end

    local path = ""
    while not buffer:is_empty() do
        path = path .. hex.ANGLE_NAMES[buffer:pop_right()]
    end

    return path
end


--- @param goal number
--- @return fun(node: hex.num.node): boolean
local function getNodeFilter(goal)
    -- stronger filter for intergers
    if math.floor(goal) == goal then
        return function(node)
            return node.value > goal or node.angle == hex.ANGLES.D
        end
    else
        return function(node)
            return false
        end
    end
end

local precision = 50

--- @param goal number
--- @param table table<number, number>
--- @return fun(node: hex.num.node): number
local function getHeuristic(goal, table)
    return function(node)
        local value = node.value

        local cachedEstimate = table[math.floor(value * precision) / precision]
        if cachedEstimate then
            return cachedEstimate
        end
        -- fast but not short :(
        return math.abs(goal - value)
    end
end

local function buildHeuristicTable(goal, maxSteps)
    --- @type table<number, number>
    local heuristic = { [goal] = 0 }

    --- @type number[]
    local frontier = { goal }

    local inverseModifiers = {
        function(x) return x - 1 end,
        function(x) return x - 5 end,
        function(x) return x - 10 end,
        function(x) return x * 2 end,
        function(x) return x / 2 end,
    }

    for step = 1, maxSteps, 1 do
        local nextFrontier = {}
        for _, value in ipairs(frontier) do
            for _, modifier in ipairs(inverseModifiers) do
                -- local newValue = modifier(value)
                local newValue = math.floor(modifier(value) * precision) / precision
                if newValue >= 0 and not heuristic[newValue] then
                    heuristic[newValue] = step
                    table.insert(nextFrontier, newValue)
                end
            end
        end
        frontier = nextFrontier
    end
    return heuristic
end

--- comment
--- @param initial hex.num.node
--- @param goal number
--- @param skipFunction fun(node:hex.num.node): boolean
--- @param heuristic fun(node:hex.num.node): number
--- @return hex.num.node
local function astarSearch(initial, goal, skipFunction, heuristic)
    --- @type pqueue
    local haystack = pqueue()
    haystack:put(initial, heuristic(initial))

    local isInt = goal == math.floor(goal)

    local startTime = os.clock()
    local evals = 0
    repeat
        --- @type hex.num.node
        local hays = exploreNode(haystack:pop(), skipFunction)
        for _, hay in ipairs(hays) do
            evals = evals + 1
            if isInt then
                if goal == hay.value then
                    return hay
                end
            else
                if goal * 1.005 >= hay.value and hay.value >= goal * 0.995 then
                    return hay
                end
            end
            haystack:put(hay, hay.depth + heuristic(hay))
            if haystack:size() > 1024 then
                haystack:cull()
            end
        end
    until os.clock() - startTime > 10 or haystack:empty()
    error("Could not find!")
end

local module = {}

function module.findNumPattern(num)
    local startingPos  = { x = 0, y = 0, z = 0 }
    local startingArea = grid.adjacentCoordinates(startingPos)
    local target       = math.abs(num)

    local node         = nil
    --- @type hex.num.node
    node               = {
        position = startingArea[hex.DIRECTIONS.WEST],
        value = 0,
        depth = 0,
    }

    if num < 0 then
        node = {
            position = startingArea[hex.DIRECTIONS.NORTH_WEST],
            value    = 0,
            depth    = 0,
            parent   = node
        }
        node = {
            position = startingPos,
            angle    = hex.ANGLES.D,
            value    = 0,
            depth    = 0,
            parent   = node
        }
        node = {
            position = startingArea[hex.DIRECTIONS.SOUTH_WEST],
            angle    = hex.ANGLES.E,
            value    = 0,
            depth    = 0,
            parent   = node
        }
        node = {
            position = startingArea[hex.DIRECTIONS.WEST],
            angle    = hex.ANGLES.D,
            value    = 0,
            depth    = 0,
            parent   = node
        }
        node = {
            position = startingPos,
            angle    = hex.ANGLES.D,
            value    = 0,
            depth    = 0,
            parent   = node
        }
    else
        node = {
            position = startingArea[hex.DIRECTIONS.SOUTH_WEST],
            value    = 0,
            depth    = 0,
            parent   = node
        }
        node = {
            position = startingPos,
            angle    = hex.ANGLES.A,
            value    = 0,
            depth    = 0,
            parent   = node
        }
        node = {
            position = startingArea[hex.DIRECTIONS.NORTH_WEST],
            angle    = hex.ANGLES.Q,
            value    = 0,
            depth    = 0,
            parent   = node
        }
        node = {
            position = startingArea[hex.DIRECTIONS.WEST],
            angle    = hex.ANGLES.A,
            value    = 0,
            depth    = 0,
            parent   = node
        }
        node = {
            position = startingPos,
            angle    = hex.ANGLES.A,
            value    = 0,
            depth    = 0,
            parent   = node
        }
    end

    local cacheSteps = math.max(12, math.ceil(math.log(num, 2) + 2))

    local cache      = buildHeuristicTable(target, cacheSteps)
    local result     = astarSearch(node, num, getNodeFilter(target), getHeuristic(target, cache))
    local path       = rebuildPath(result)

    print("Found number " .. target .. " (" .. result.value .. ") with path:")
    print("  " .. path)

    --- @type pattern
    return {
        startDir = "EAST",
        angles   = path
    }
end

local function main(args)
    --- @type hex.num.node
    if #args < 1 then
        return
    end

    local num = tonumber(table.remove(args, 1))
    local result = module.findNumPattern(num)
    print(result.angles)
end

-- only execute 'main()' when script is called directly
if not debug.getinfo(3) then
    -- get args from program
    local args = { ... }
    -- pass args to main function
    main(args)
else
    return module
end
