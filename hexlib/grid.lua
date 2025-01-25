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

--- @param p hex.grid.coord position
--- @return table<hex.direction, hex.grid.coord>
function grid.adjacentCoordinates(p)
    --- @format disable
    return {
        [hex.DIRECTIONS.NORTH_WEST] = { p[1] - (1 - p[3]), p[2] - (1 - p[3]), (1 - p[3]) },
        [hex.DIRECTIONS.NORTH_EAST] = { p[1] + p[3]      , p[2] - (1 - p[3]), (1 - p[3]) },
        [hex.DIRECTIONS.EAST]       = { p[1] + 1         , p[2]             , p[3]       },
        [hex.DIRECTIONS.SOUTH_EAST] = { p[1] + p[3]      , p[2] + p[3]      , (1 - p[3]) },
        [hex.DIRECTIONS.SOUTH_WEST] = { p[1] - (1 - p[3]), p[2] + p[3]      , (1 - p[3]) },
        [hex.DIRECTIONS.WEST]       = { p[1] - 1         , p[2]             , p[3]       },
    }
end

--- @param pos hex.grid.coord
function grid.stringifyGridPos(pos)
    return "(" .. pos[1] .. ", " .. pos[2] .. ", " .. pos[3] .. ")"
end

--- @param a hex.grid.coord
--- @param b hex.grid.coord
function grid.isEqualGridPos(a, b)
    return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
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
        if candidate[1] == to[1] and candidate[2] == to[2] and candidate[3] == to[3] then
            return dir
        end
    end

    error("Could not infer direction from "
        .. grid.stringifyGridPos(from) .. " to "
        .. grid.stringifyGridPos(to) .. "!")
end

return grid
