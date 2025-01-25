local module = {}

--- @class pattern
--- @field startDir string the start direction of the pattern
--- @field angles   string the angle of the pattern
--- @alias hex  pattern[]
--- @alias iota pattern | hex

--- @enum hex.direction
module.DIRECTIONS = {
    NORTH_WEST = 1,
    NORTH_EAST = 2,
    EAST       = 3,
    SOUTH_EAST = 4,
    SOUTH_WEST = 5,
    WEST       = 6,
}

--- @type table<hex.direction, string>
module.DIRECTION_NAMES = {
    [1] = "NORTH_WEST",
    [2] = "NORTH_EAST",
    [3] = "EAST",
    [4] = "SOUTH_EAST",
    [5] = "SOUTH_WEST",
    [6] = "WEST",
}

--- @enum hex.angle
module.ANGLES = {
    A = 1,
    Q = 2,
    W = 3,
    E = 4,
    D = 5,
}

--- @type table<hex.angle, string>
module.ANGLE_NAMES = {
    [1] = "a",
    [2] = "q",
    [3] = "w",
    [4] = "e",
    [5] = "d",
}

--- @param direction hex.direction
--- @return table<hex.angle, hex.direction>
function module.getPossibleDirections(direction)
    -- dir_offset converts 'EAST' to 0
    local dir_offset = (direction - 3) % 6

    local possibleDirections = {}
    for angle_idx = 1, 5, 1 do
        possibleDirections[angle_idx]
        = ((angle_idx + dir_offset - 1) % 6) + 1
    end
    return possibleDirections
end

return module
