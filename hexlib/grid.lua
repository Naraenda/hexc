local hex  = require("hexlib.common")
local grid = {}

-- Hexagonal Efficient Coordinate System
-- ```
--       {y-(1-z), x-(1-z), 1-z}   {y-(1-z), x+z, 1-z}
-- {y, x-1, z}               {y, x, z}           {y, x + 1, z}
--       {y+z    , x-(1-z), 1-z}   {y+z    , x+z, 1-z}
-- ```
--- @class hex.grid.coord
--- @field x number
--- @field y number
--- @field z number

--- @class hex.num.node
--- @field position  hex.grid.coord
--- @field value     number
--- @field depth     number
--- @field parent    hex.num.node?
--- @field angle     hex.direction?

--- @param p hex.grid.coord position
--- @return table<hex.direction, hex.grid.coord>
function grid.adjacentCoordinates(p)
    return {
        [hex.DIRECTIONS.NORTH_WEST] = { x = p.x - (1 - p.z), y = p.y - (1 - p.z), z = (1 - p.z) },
        [hex.DIRECTIONS.NORTH_EAST] = { x = p.x + p.z, y = p.y - (1 - p.z), z = (1 - p.z) },
        [hex.DIRECTIONS.EAST]       = { x = p.x + 1, y = p.y, z = p.z },
        [hex.DIRECTIONS.SOUTH_EAST] = { x = p.x + p.z, y = p.y + p.z, z = (1 - p.z) },
        [hex.DIRECTIONS.SOUTH_WEST] = { x = p.x - (1 - p.z), y = p.y + p.z, z = (1 - p.z) },
        [hex.DIRECTIONS.WEST]       = { x = p.x - 1, y = p.y, z = p.z },
    }
end

--- @param pos hex.grid.coord
function grid.stringifyGridPos(pos)
    return "(" .. pos.x .. ", " .. pos.y .. ", " .. pos.z .. ")"
end

--- @param a hex.grid.coord
--- @param b hex.grid.coord
function grid.isEqualGridPos(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end

--- @param a1 hex.grid.coord
--- @param a2 hex.grid.coord
--- @param b1 hex.grid.coord
--- @param b2 hex.grid.coord
--- @return boolean
function grid.isEqualGridEdge(a1, a2, b1, b2)
    local isEqualGridPos = grid.isEqualGridPos
    return (isEqualGridPos(a1, b1) or isEqualGridPos(a1, b2)) and
        (isEqualGridPos(a2, b1) or isEqualGridPos(a2, b2))
end

--- @param from hex.grid.coord
--- @param to   hex.grid.coord
--- @return hex.direction
function grid.inferDirection(from, to)
    local heighbors = grid.adjacentCoordinates(from)
    for dir, candidate in pairs(heighbors) do
        if candidate.x == to.x and candidate.y == to.y and candidate.z == to.z then
            return dir
        end
    end

    error("Could not infer direction from "
        .. grid.stringifyGridPos(from) .. "to"
        .. grid.stringifyGridPos(to) .. "!")
end

return grid
