--- @module "hexlib.common"

-- we can encode a vertex in a triangular lattice
-- using (x, y) coordinates. an edge in this lattice
-- can be identified by using an extra variable, i.e.
-- (x, y, z). This 'z' value indicates in which
-- y-direction this edge is pointing to, given that
-- outgoing edges from that vertex are east-ish.
--
--   O
--  /   z =  1 => (0, 0,  1)
-- O--O z =  0 => (0, 0,  0)
--  \   z = -1 => (0, 0, -1)
--   O

--- @alias hex.lattice.edge   number[] edge coordinate in (x, y, z)
--- @alias hex.lattice.vertex number[] vertex coordinate in (x, y)

--- @class lattice
local lattice = {}

function lattice.isEq(a, b)
    return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end

--- given a partial edge coordinate (x, y, _) and a direction,
--- construct the vertex position of the endpoint
--- @param direction any
--- @param x any
--- @param y any
--- @return number, number
function lattice.vertexFromEdge(direction, x, y)
    if direction == 2 then
        -- NORTH_EAST
        return x, y + 1
    elseif direction == 3 then
        -- EAST
        return x + 1, y
    elseif direction == 4 then
        -- SOUTH_EAST
        return x + 1, y - 1
    end
    return x, y
end

--- gets a table of directions and the resulting edge corodinates
--- @param direction hex.direction the direction of how we got to the vertex
--- @param x         number        x-coordinate of vertex
--- @param y         number        y-coordinate of vertex
--- @return table<hex.direction, hex.lattice.edge>
function lattice.adjecentEdges(direction, x, y)
    -- get the vertex position
    x, y = lattice.vertexFromEdge(direction, x, y)
    --- encode neighboring edges
    --- @type table<hex.direction, hex.lattice.edge>
    local directions = {
        { -1, 1,  -1 }, -- NORTH_WEST
        { 0,  0,  1 },  -- NORTH_EAST
        { 0,  0,  0 },  -- EAST
        { 0,  0,  -1 }, -- SOUTH_EAST
        { 0,  -1, 1 },  -- SOUTH_WEST
        { -1, 0,  0 },  -- WEST
    }
    -- derive new edges from vertex
    for i = 1, 6 do
        local dir = directions[i]
        dir[1] = dir[1] + x
        dir[2] = dir[2] + y
    end
    return directions
end

return lattice
