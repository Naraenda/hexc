local numgen = require("hexlib.numgen")

local function main(args)
    if #args < 1 then
        return
    end
    
    local number = tonumber(table.remove(args, 1))
    if not number then
        return
    end

    local path = numgen():find(number)
    print(path)
end

-- only execute 'main()' when script is called directly
if not debug.getinfo(3) then
    -- get args from program
    local args = { ... }
    -- pass args to main function
    main(args)
end
