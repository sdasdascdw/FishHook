local Scripts = {
    [192800] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FISHHOOKPIZZA",
    [95082159892680] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FISHHOOKPIZZA",
    [79546208627805] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FISHHOOK99",
}

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
