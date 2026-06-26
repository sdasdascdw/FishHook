local Scripts = {
    [7326934954] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FishHook99.luau",
    [9584852943] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FishHookSpeed.luau"
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
