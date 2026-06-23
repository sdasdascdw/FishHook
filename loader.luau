--======================================================================================
-- FILE: loader.luau
--======================================================================================

-- 1. Grab the key from the executor
local userKey = SCRIPT_KEY or _G.SCRIPT_KEY or ""

-- Strip everything except alphanumeric characters, hyphens, and underscores
local function cleanString(str)
    if not str then return "" end
    return tostring(str):gsub("%s+", ""):gsub(";+$", ""):gsub("[\r\n]", "")
end

userKey = cleanString(userKey)

-- Cache-bypass: Adds a random parameter so Roblox doesn't load an old version of your text file
local cacheBypass = "?t=" .. tostring(math.random(100000, 999999))
local KEYS_URL = "https://raw.githubusercontent.com/sdasdascdw/FishHook/main/keys.txt" .. cacheBypass

local Scripts = {
    [7326934954] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FishHook99.luau",
    [9584852943] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FishHookSpeed.luau"
}

--======================================================================================
-- AUTHENTICATION ENGINE
--======================================================================================
local function authenticateUser()
    local lp = game:GetService("Players").LocalPlayer
    
    if userKey == "" then
        lp:Kick("\n[Access Denied]\nNo script key was provided in your executor.")
        return false
    end

    -- Fetch latest text from keys.txt
    local fetchSuccess, rawContent = pcall(function()
        return game:HttpGet(KEYS_URL)
    end)

    if not fetchSuccess or not rawContent then
        lp:Kick("\n[Authentication Error]\nFailed to connect to verification server.")
        return false
    end

    local keyFound = false

    print("--- [FishHook Key Debugger] ---")
    print("Key entered in executor: '" .. userKey .. "'")

    -- Read line-by-line through your keys file
    for line in string.gmatch(rawContent, "[^\r\n]+") do
        local cleanLine = cleanString(line)
        
        if cleanLine ~= "" then
            print("Checking against file key: '" .. cleanLine .. "'")
            if cleanLine == userKey then
                keyFound = true
                break
            end
        end
    end
    print("-------------------------------")

    -- Strict verification guard
    if not keyFound then
        lp:Kick("\n[Access Denied]\nInvalid or Expired Script Key.\nCheck your Developer Console (F9) for details.")
        return false
    end

    return true
end

--======================================================================================
-- INITIALIZE GAME DETECTION
--======================================================================================
if authenticateUser() then
    local Script = Scripts[game.GameId]

    if Script then
        loadstring(game:HttpGet(Script))()
    else
        warn("This game instance ID (" .. tostring(game.GameId) .. ") is not supported.")
    end
end
