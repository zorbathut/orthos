
assert(loadfile("lib_art.lua"))()

--Command.Environment.Create(_G, "Main menu", "menu.lua")
Command.Environment.Create(_G, "Battle", "battle.lua")
