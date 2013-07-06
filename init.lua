
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
    battle = Command.Environment.Create(_G, "BattleLoop", "battleloop.lua", {{type = "Bandit", x = 4, y = 2}, {type = "Bandit", x = 5, y = 2}, {type = "Bandit", x = 6, y = 2}})
  end)
end
ReturnToMenu()

Command.Environment.Insert(_G, "Command.Init.Return", function ()
  ReturnToMenu()
end)
