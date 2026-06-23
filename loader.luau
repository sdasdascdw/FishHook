--======================================================================================
-- FILE: loader.luau
--======================================================================================

-- 1. Grab the key from the executor
local userKey = SCRIPT_KEY or _G.SCRIPT_KEY or ""

-- Standard fixed name so it never creates separate files if the executor name fluctuates
local LOCK_FILE_NAME = "FishHook-Service.SRVC"

-- Clean up any hidden formatting from strings
local function cleanString(str)
    if not str then return "" end
    return tostring(str):gsub("%s+", ""):gsub(";+$", ""):gsub("[\r\n]", "")
end

userKey = cleanString(userKey)

-- Cache-bypass: Forces GitHub to fetch the live text file instead of a cached copy
local cacheBypass = "?t=" .. tostring(math.random(100000, 999999))
local KEYS_URL = "https://raw.githubusercontent.com/sdasdascdw/FishHook/main/keys.txt" .. cacheBypass

local Scripts = {
    [7326934954] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FishHook99.luau",
    [9584852943] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FishHookSpeed.luau"
}

--======================================================================================
-- AUTHENTICATION & SINGLE-USE LOCK ENGINE
--======================================================================================
local function authenticateUser()
    local lp = game:GetService("Players").LocalPlayer
    
    if userKey == "" then
        lp:Kick("\n[Access Denied]\nNo script key was provided in your executor.")
        return false
    end

    -- Fetch master keys database from GitHub
    local fetchSuccess, rawContent = pcall(function()
        return game:HttpGet(KEYS_URL)
    end)

    if not fetchSuccess or not rawContent then
        lp:Kick("\n[Authentication Error]\nFailed to connect to verification server.")
        return false
    end

    local keyFound = false

    -- Verify the key exists on your GitHub lines
    for line in string.gmatch(rawContent, "[^\r\n]+") do
        local cleanLine = cleanString(line)
        if cleanLine ~= "" and cleanLine == userKey then
            keyFound = true
            break
        end
    end

    -- Strict master database verification
    if not keyFound then
        lp:Kick("\n[Access Denied]\nInvalid or Expired Script Key.")
        return false
    end

    --======================================================================================
    -- FILE-LOCKING INTEGRITY VERIFICATION
    --======================================================================================
    local fileExists = false
    local pcallFileSuccess, fileCheckResult = pcall(function()
        return isfile and isfile(LOCK_FILE_NAME)
    end)
    
    if pcallFileSuccess and fileCheckResult then
        fileExists = true
    end

    if not fileExists then
        -- Key used for the FIRST time on this machine: create the permanent lock profile
        local writeSuccess = pcall(function()
            if writefile then
                writefile(LOCK_FILE_NAME, userKey)
            end
        end)
        
        if not writeSuccess then
            warn("[Security Warning]: Executor does not support standard file handling operations.")
        else
            task.spawn(function()
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "License Key Linked",
                        Text = "Key successfully tied to this workspace profile.",
                        Duration = 6
                    })
                end)
            end)
        end
    else
        -- Key has already been initialized previously: load it and check if it matches
        local readSuccess, savedKeyContents = pcall(function()
            if readfile then
                return readfile(LOCK_FILE_NAME)
            end
        end)
        
        if readSuccess and savedKeyContents then
            local cleanSavedKey = cleanString(savedKeyContents)
            
            -- If the key stored locally inside workspace does not match the key being verified now
            if cleanSavedKey ~= userKey then
                lp:Kick("\nHWID Mismatched")
                return false
            end
        else
            -- If the file is unreadable or tampered with, deny execution safely
            lp:Kick("\nHWID Mismatched")
            return false
        end
    end

    return true
end

--======================================================================================
-- INITIALIZE GAME DETECTION
--======================================================================================
if authenticateUser() then
    local Script = Scripts[game.GameId]

    if Script then
        local runSuccess, runError = pcall(function()
            loadstring(game:HttpGet(Script))()
        end)
        if not runSuccess then
            warn("Error executing game script: " .. tostring(runError))
        end
    else
        warn("This game instance ID (" .. tostring(game.GameId) .. ") is not supported.")
    end
end
