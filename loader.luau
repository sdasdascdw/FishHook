--======================================================================================
-- FILE: loader.luau
--======================================================================================

-- Look for the key in both global and local variables
local userKey = SCRIPT_KEY or _G.SCRIPT_KEY or ""

-- Clean up whatever the user entered (remove spaces or semicolons they might copy/paste)
userKey = string.gsub(userKey, "%s+", ""):gsub(";+$", "")

-- Your raw keys file URL
local KEYS_URL = "https://raw.githubusercontent.com/sdasdascdw/FishHook/main/keys.txt"

local Scripts = {
    [7326934954] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FishHook99.luau",
    [9584852943] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FishHookSpeed.luau"
}

--======================================================================================
-- AUTHENTICATION ENGINE (STRICT MATCHING)
--======================================================================================
local function authenticateUser()
    local lp = game:GetService("Players").LocalPlayer
    
    if userKey == "" then
        lp:Kick("\n[Access Denied]\nNo script key was provided.")
        return false
    end

    -- Fetch data from keys.txt
    local fetchSuccess, rawContent = pcall(function()
        return game:HttpGet(KEYS_URL)
    end)

    if not fetchSuccess or not rawContent then
        lp:Kick("\n[Authentication Error]\nFailed to connect to verification server.")
        return false
    end

    local keyFound = false

    -- Read line-by-line through your keys file
    for line in string.gmatch(rawContent, "[^\r\n]+") do
        -- Clean the file line completely (strip spaces, strip trailing semicolons)
        local cleanLine = string.gsub(line, "%s+", ""):gsub(";+$", "")
        
        -- Since your file ONLY contains keys without a colon separator, match directly!
        if cleanLine ~= "" and cleanLine == userKey then
            keyFound = true
            break
        end
    end

    -- Strict verification guard
    if not keyFound then
        lp:Kick("\n[Access Denied]\nInvalid or Expired Script Key.")
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
