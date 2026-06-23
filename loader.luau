--======================================================================================
-- FILE: FishHook_Secure_Launcher.lua
--======================================================================================

-- Ensure this variable matches what you tell users to input!
SCRIPT_KEY = SCRIPT_KEY or "YOUR_KEY_HERE" 

-- Raw GitHub URL for parsing plain text lines
local KEYS_URL = "https://raw.githubusercontent.com/sdasdascdw/FishHook/main/keys.txt"

local Scripts = {
    [7326934954] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FishHook99.luau",
    [9584852943] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FishHookSpeed.luau"
}

--======================================================================================
-- SYSTEM HARDWARE IDENTITY (HWID) DETECTOR
--======================================================================================
local function getHWID()
    local success, result = pcall(function()
        -- Robust checking for executors (Luau / Exploits) identity properties
        return cloneref(game:GetService("RbxAnalyticsService")):GetClientId() 
            or game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    
    if success and result then 
        return tostring(result):gsub("%W", ""):lower() 
    end
    
    -- Fallback profile generation identifier if RbxAnalytics is restricted
    return tostring(game:GetService("Players").LocalPlayer.UserId)
end

local userHWID = getHWID()

--======================================================================================
-- SERVER AUTHENTICATION SYSTEM
--======================================================================================
local function authenticateUser()
    local lp = game:GetService("Players").LocalPlayer
    
    -- 1. Fetch text stream
    local fetchSuccess, rawContent = pcall(function()
        return game:HttpGet(KEYS_URL)
    end)

    if not fetchSuccess or not rawContent then
        lp:Kick("\n[Authentication Error]\nFailed to communicate with authorization server.")
        return false
    end

    local keyFound = false
    local hwidMatched = false

    -- 2. Line-by-Line Tokenizer Split Layer
    for line in string.gmatch(rawContent, "[^\r\n]+") do
        -- Remove spaces and strip any trailing semicolons (;) safely
        local cleanLine = string.gsub(line, "%s+", ""):gsub(";+$", "")
        
        if cleanLine ~= "" then
            -- Splits database format configurations like: "KeyName:HWID_Value"
            local entryKey, entryHWID = string.match(cleanLine, "([^:]+):?([^:]*)")
            
            if entryKey and entryKey == SCRIPT_KEY then
                keyFound = true
                
                -- Check if this database key entry has an HWID linked yet
                if entryHWID == "" then
                    lp:Kick("\n[HWID Initialization Required]\nPlease link your HWID configuration to this license key.")
                    return false
                elseif entryHWID:gsub("%W", ""):lower() == userHWID then
                    hwidMatched = true
                    break
                end
            end
        end
    end

    -- 3. Strict Execution Validation Guardrails
    if not keyFound then
        lp:Kick("\n[Access Denied]\nInvalid or Expired Script Key.")
        return false
    elseif not hwidMatched then
        lp:Kick("\nHWID Incorrect")
        return false
    end

    return true
end

--======================================================================================
-- RUNTIME DISTRIBUTION
--======================================================================================
if authenticateUser() then
    local Script = Scripts[game.GameId]

    if Script then
        loadstring(game:HttpGet(Script))()
    else
        warn("This game environment is not currently supported.")
    end
end
