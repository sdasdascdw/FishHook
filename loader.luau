--======================================================================================
-- FILE: loader.luau
--======================================================================================

-- 1. Grab the key from the executor
local userKey = SCRIPT_KEY or _G.SCRIPT_KEY or ""

-- Identify the executing software name safely and format with .SRVC extension
local executorName = identifyexecutor and identifyexecutor() or "Unknown"
local safeExecutorName = string.gsub(tostring(executorName), "%W", "")
local LOCK_FILE_NAME = safeExecutorName .. "-Service.SRVC"

-- Strip everything except alphanumeric characters, hyphens, and underscores
local function cleanString(str)
    if not str then return "" end
    return tostring(str):gsub("%s+", ""):gsub(";+$", ""):gsub("[\r\n]", "")
end

userKey = cleanString(userKey)

-- Cache-bypass: Adds a random parameter so Roblox doesn't load cached versions of your text file
local cacheBypass = "?t=" .. tostring(math.random(100000, 999999))
local KEYS_URL = "https://raw.githubusercontent.com/sdasdascdw/FishHook/main/keys.txt" .. cacheBypass

local Scripts = {
    [7326934954] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FishHook99.luau",
    [9584852943] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FishHookSpeed.luau"
}

--======================================================================================
-- AUTHENTICATION & EXECUTOR WORKSPACE LOCK ENGINE
--======================================================================================
local function authenticateUser()
    local lp = game:GetService("Players").LocalPlayer
    
    if userKey == "" then
        lp:Kick("\n[Access Denied]\nNo script key was provided in your executor.")
        return false
    end

    -- Fetch latest text from central keys.txt
    local fetchSuccess, rawContent = pcall(function()
        return game:HttpGet(KEYS_URL)
    end)

    if not fetchSuccess or not rawContent then
        lp:Kick("\n[Authentication Error]\nFailed to connect to verification server.")
        return false
    end

    local keyFound = false

    -- Read line-by-line through your master database keys file
    for line in string.gmatch(rawContent, "[^\r\n]+") do
        local cleanLine = cleanString(line)
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

    --======================================================================================
    -- EXECUTOR WORKSPACE INTERACTION SECURITY LAYER (.SRVC FILE)
    --======================================================================================
    local fileExists = false
    local pcallFileSuccess, fileCheckResult = pcall(function()
        return isfile and isfile(LOCK_FILE_NAME)
    end)
    
    if pcallFileSuccess and fileCheckResult then
        fileExists = true
    end

    if not fileExists then
        -- File doesn't exist yet: Create the .SRVC lock file and write the key inside
        local writeSuccess = pcall(function()
            if writefile then
                writefile(LOCK_FILE_NAME, userKey)
            end
        end)
        
        if not writeSuccess then
            warn("[Security Warning]: Executor does not support file operations fallback active.")
        else
            task.spawn(function()
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "Service Registered",
                        Text = "Created service profile: " .. LOCK_FILE_NAME,
                        Duration = 6
                    })
                end)
            end)
        end
    else
        -- File exists: Read the internal contents to verify it matches the active key string
        local readSuccess, savedKeyContents = pcall(function()
            if readfile then
                return readfile(LOCK_FILE_NAME)
            end
        end)
        
        if readSuccess and savedKeyContents then
            local cleanSavedKey = cleanString(savedKeyContents)
            
            -- If the key in the local executor file doesn't match the one being verified
            if cleanSavedKey ~= userKey then
                lp:Kick("\nHWID Mismatched")
                return false
            end
        else
            -- If the file is present but unreadable/corrupted, reject access to be safe
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
