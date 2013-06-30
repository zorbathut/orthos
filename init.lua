
assert(loadfile("lib_art.lua"))()

local battle
local menu = Command.Environment.Create(_G, "Main menu", "menu.lua")
menu.Event.Init.Start:Attach(function ()
  Command.Environment.Destroy(menu)
  menu = nil
  battle = Command.Environment.Create(_G, "Battle", "battle.lua")
end)
