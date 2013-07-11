
assert(loadfile("debug.lua"))()

assert(loadfile("lib_art.lua"))()

local battle
local menu

local function ReturnToMenu()
  if menu then
    Command.Environment.Destroy(menu)
    menu = nil
  end
  
  if battle then
    Command.Environment.Destroy(battle)
    battle = nil
  end
  
  menu = Command.Environment.Create(_G, "Main menu", "menu.lua")
  menu.Event.Init.Start:Attach(function ()
    Command.Environment.Destroy(menu)
    menu = nil
    battle = Command.Environment.Create(_G, "Fight Club", "fightclub.lua")
  end)
end
ReturnToMenu()

Command.Environment.Insert(_G, "Command.Init.Return", function ()
  ReturnToMenu()
end)
