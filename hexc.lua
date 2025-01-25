local hex    = require("hexlib.common")
local numgen = require("hexlib.numgen")

--- @alias symbolRegistry table<string,table<string, string>>
--- reads a symbol registry (JSON) and returns a table
---
--- @param  path string
--- @return symbolRegistry
local function readSymbolRegistry(path)
    local handle = fs.open(path, "r")
    if not handle then
        error("Could not open file: " .. path)
    end
    local json = handle.readAll()
    handle.close()
    if not json then
        error("Cannot read empty file: " .. path)
    end

    local data = textutils.unserializeJSON(json)
    if not data then
        error("Cannot parse JSON: " .. path)
    end
    return data
end

--- tokenizes a piece of string
---
--- @param  text string
--- @return [string]
local function tokenizeHexPattern(text)
    local tokenSeperators = { "\r", "\n", "\t", ":" }
    local tokens          = {}
    local token           = ""

    local isToken         = false
    local isSpace         = false

    local isLineComment   = false
    local isRegionComment = false

    local position        = 1
    while position <= #text do
        local oneChar = string.sub(text, position, position)
        local twoChar = string.sub(text, position, position + 1)
        local isSeperator = false

        -- line comment handling
        if twoChar == "//" and not isRegionComment then
            isLineComment = true
            isSeperator = true
            goto finalize_token
        end
        if isLineComment then
            if oneChar == "\n" then
                isLineComment = false
                isSpace = false
            else
                goto next_char
            end
        end

        -- region comment handling
        if twoChar == "/*" and not isLineComment then
            isRegionComment = true
            goto next_char
        end
        if isRegionComment then
            if twoChar == "*/" then
                isRegionComment = false
                position = position + 1
            end
            goto next_char
        end

        -- token seperation handling
        for _, seperator in pairs(tokenSeperators) do
            if oneChar == seperator then
                isSeperator = true
                break
            end
        end

        -- char handling
        if not isSeperator then
            -- space handling
            if oneChar == " " then
                if isToken and not isSpace then
                    isSpace = true
                end
            else
                if isSpace then
                    token = token .. " "
                end
                token   = token .. oneChar
                isToken = true
                isSpace = false
            end
        end

        -- finalize token
        ::finalize_token::
        if isToken and (isSeperator or position == #text) then
            -- print("token: '" .. token .. "'")
            table.insert(tokens, token)
            token = ""
            isToken = false
        end

        ::next_char::
        position = position + 1
    end
    return tokens
end

local function generateMaskPattern(mask)
    local char = string.sub(mask, 1, 1)
    local prev = char
    local pattern = nil
    local direction = nil

    if char == "-" then
        direction = "EAST"
        pattern = ""
    else
        direction = "SOUTH_EAST"
        pattern = "a"
    end

    local maskLookup = {
        ["-"] = { ["-"] = "w", ["v"] = "e" },
        ["v"] = { ["-"] = "ea", ["v"] = "da" },
    }

    local position = 1
    while position <= #mask do
        local char = string.sub(mask, position, position)
        pattern = pattern .. maskLookup[char][prev]
        prev = char
        position = position + 1
    end

    return {
        pattern = pattern,
        direction = direction
    }
end

local function compileHexFromTokens(tokens, registry)
    local hex = {}
    local hexLength = 0

    local position = 1
    while position <= #tokens do
        local token = tokens[position]

        -- handle macros
        if token == "#include" then
            error("Macro not supported: #include")
        elseif token == "#define" then
            error("Macro not supported: #define")
        end

        -- literal pattern alias
        if token == "{" then
            token = "Introspection"
        end
        if token == "}" then
            token = "Retrospection"
        end

        if (token == "Zone Distillation" or
                token == "Entity Purification" or
                token == "Zone Exaltation" or
                token == "Length Distillation")
        then
            position = position + 1
            token = token .. ": " .. tokens[position]
        end

        local definition = registry[token]
        local pattern    = nil
        local name       = nil

        if definition == nil then
            print("Could not find '" .. token .. "' in registry!")
            goto next_token
        end

        pattern = definition["pattern"]
        name    = definition["name"]

        -- handle argument of 'mask'
        if name == "mask" then
            pattern = "???"
            position = position + 1

            local maskPattern = generateMaskPattern(tokens[position])
            pattern = maskPattern["pattern"]
        end

        -- handle argument of 'number'
        if name == "number" then
            position = position + 1
            local number = tonumber(tokens[position])
            if number == nil then
                error("Invalid number: " .. tokens[position])
            end
            pattern  = numgen():find(number)
        end

        if pattern == nil then
            print("Could not find pattern for " .. token)
        end

        hexLength = hexLength + 1
        hex[hexLength] = {
            startDir = "EAST",
            angles = pattern,
        }

        ::next_token::
        position = position + 1
    end

    return hex
end

--- builds a hex iota from a list of strings describing
--- angles.
---
--- @param  rawAnglesList string[]
--- @return hex
local function compileHexFromAngles(rawAnglesList)
    -- build a hex which is a table of patterns
    local hex = {}
    -- convert a list of angles to pattern iotas
    for _, rawPattern in pairs(rawAnglesList) do
        -- build a singular pattern
        -- assumption: start direction does not matter
        local pattern       = {}
        pattern["startDir"] = "EAST"
        pattern["angles"]   = rawPattern
        table.insert(hex, pattern)
    end

    return hex
end

--- writes an iota to an attached peripheral port
---
--- @param iota iota
local function writeIotaToFocus(iota)
    --- @type any
    --- @diagnostic disable-next-line: param-type-mismatch
    local focalPort = peripheral.find("focal_port")
    if not focalPort then
        error("No focal port found!")
    elseif not focalPort.hasFocus() then
        error("Focal port contains no focus!")
    elseif not focalPort.canWriteIota() then
        error("Cannot write iota to focus!")
    else
        focalPort.writeIota(iota)
    end
end

--- read lines from a file
---
--- @param  path string
--- @return string[]
local function readLinesFromFile(path)
    local lines = {}
    local handle = fs.open(path, "r")
    if not handle then
        error("Could not open file: " .. path)
    end
    repeat
        local line = handle.readLine()
        if line == nil then
            break
        elseif line ~= "" then
            table.insert(lines, line)
        end
    until false
    handle.close()

    return lines
end

--- read everything from a file
---
--- @param  path string
--- @return string
local function readAllFromFile(path)
    local handle = fs.open(path, "r")
    if not handle then
        error("Could not open file: " .. path)
    end
    local text = handle.readAll()
    handle.close()
    if not text then
        error("Cannot read empty file: " .. path)
    end

    return text
end

--- main entrypoint for calling this file
---
--- @param args string[]
local function main(args)
    if #args < 1 then
        print("hexc - hex casting compiler by nara")
        return
    end

    --- @type string path to executable
    local hexc_exe = shell.getRunningProgram()
    --- @type string path to the directory of the executable
    local hexc_dir = hexc_exe:sub(1, #hexc_exe - #fs.getName(hexc_exe))

    -- TODO: parse args
    local buildFromAngles = false
    local symRegistryFile = hexc_dir .. "symbol-registry.json"

    -- parse argument for file
    local path = shell.resolve(table.remove(args, 1))
    if not fs.exists(path) then
        print("FAIL: Cannot find file: " .. path)
        return
    end

    local iota = nil
    if buildFromAngles then
        -- read source from a path
        local ok, result = pcall(readLinesFromFile, path)
        if not ok then
            print("FAIL: " .. result)
            return
        end
        local rawAngles = result

        -- make
        local ok, result = pcall(compileHexFromAngles, rawAngles)
        if not ok then
            print("FAIL: " .. result)
            return
        end
        iota = result
    else
        -- read symbol registry
        local ok, result = pcall(readSymbolRegistry, symRegistryFile)
        if not ok then
            print("FAIL: " .. result)
            return
        end
        local registry = result

        -- read source from a path
        local ok, result = pcall(readAllFromFile, path)
        if not ok then
            print("FAIL: " .. result)
            return
        end
        local source = result

        -- tokenize source
        local ok, result = pcall(tokenizeHexPattern, source)
        if not ok then
            print("FAIL: " .. result)
            return
        end
        local tokens = result

        -- compile tokens into hex
        local ok, result = pcall(compileHexFromTokens, tokens, registry)
        if not ok then
            print("FAIL: " .. result)
            return
        end
        iota = result
    end

    -- write iota to focus
    local ok, result = pcall(writeIotaToFocus, iota)
    if not ok then
        print("FAIL: " .. result)
        return
    end

    print("Done!")
end

-- only execute 'main()' when script is called directly
if not debug.getinfo(3) then
    -- get args from program
    local args = { ... }
    -- pass args to main function
    main(args)
end
