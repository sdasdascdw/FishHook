local Scripts = {
    [7326934954] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FishHook99.luau",
    [9584852943] = "https://raw.githubusercontent.com/sdasdascdw/FishHook/refs/heads/main/FishHookSpeed.luau"
}

local Script = Scripts[game.GameId]

if Script then
    loadstring(game:HttpGet(Script))()
else
    warn("This game is not supported.")
end
