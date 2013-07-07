
assert(loadfile("debug.lua"))()

assert(loadfile("lib_art.lua"))()

local battle
local menu

--local combatblob = {{type = "Bandit", x = 6, y = 1}}
local combatblob = {{type = "Bandit", x = 6, y = 3}, {type = "Bandit", x = 5, y = 1}}
--local combatblob = {{type = "BossFlame", x = 5, y = 2}}
--local combatblob = {{type = "BossSlam", x = 5, y = 2}}
--local combatblob = {{type = "BossRocket", x = 5, y = 2}}
--local combatblob = {{type = "BossMulti", x = 5, y = 2}}

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
    battle = Command.Environment.Create(_G, "BattleLoop", "battleloop.lua", combatblob)
  end)
end
ReturnToMenu()

Command.Environment.Insert(_G, "Command.Init.Return", function ()
  ReturnToMenu()
end)
