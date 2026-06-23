--======================================================================================
-- FILE: FishHook_Secure_Launcher.lua
--======================================================================================

-- Ensure the script checks both global and local environments for the player's key
local userKey = SCRIPT_KEY or _G.SCRIPT_KEY or ""
-- Clean up the key entered by the user (remove trailing semicolon or spaces just in case)
userKey = string.gsub(userKey, "%s+", ""):gsub(";+$", "")

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
        return cloneref(game:GetService("RbxAnalyticsService")):GetClientId() 
            or game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    
    if success and result then 
        return tostring(result):gsub("%W", ""):lower() 
    end
    
    return tostring(game:GetService("Players").LocalPlayer.UserId)
end

local userHWID = getHWID()

--======================================================================================
-- SERVER AUTHENTICATION SYSTEM
--======================================================================================
local function authenticateUser()
    local lp = game:GetService("Players").LocalPlayer
    
    if userKey == "" then
        lp:Kick("\n[Access Denied]\nNo script key was provided.")
        return false
    end

    -- Fetch text stream from keys.txt
    local fetchSuccess, rawContent = pcall(function()
        return game:HttpGet(KEYS_URL)
    end)

    if not fetchSuccess or not rawContent then
        lp:Kick("\n[Authentication Error]\nFailed to connect to authorization server.")
        return false
    end

    local keyFound = false
    local hwidMatched = false
    local needHwidWhitelisting = false

    -- Line-by-Line Split Layer
    for line in string.gmatch(rawContent, "[^\r\n]+") do
        -- Strip spaces and trailing semicolons safely from the file line
        local cleanLine = string.gsub(line, "%s+", ""):gsub(";+$", "")
        
        if cleanLine ~= "" then
            -- Check if line has a colon separating Key and HWID
            local entryKey, entryHWID = string.match(cleanLine, "([^:]+):?([^:]*)")
            entryKey = entryKey or cleanLine
            entryHWID = entryHWID or ""

            if entryKey == userKey then
                keyFound = true
                
                -- If there's no colon or no HWID attached yet, whitelist this current machine
                if entryHWID == "" then
                    needHwidWhitelisting = true
                    hwidMatched = true
                    break
                elseif entryHWID:gsub("%W", ""):lower() == userHWID then
                    hwidMatched = true
                    break
                end
            end
        end
    end

    -- Strict Execution Validation Guards
    if not keyFound then
        lp:Kick("\n[Access Denied]\nInvalid or Expired Script Key.")
        return false
    elseif not hwidMatched then
        lp:Kick("\nHWID Incorrect")
        return false
    end

    -- Informational alert letting them know their key is now locked to their device
    if needHwidWhitelisting then
        task.spawn(function()
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "HWID Linked!",
                    Text = "Your hardware ID has been locked to this key.",
                    Duration = 8
                })
            end)
        end)
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
