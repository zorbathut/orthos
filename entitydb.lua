
local lookupIcon = {
--  Player = "noncommercial/hero",
  Bandit = {"noncommercial/bandit", "Basic immobile turret. Fires directly forward."},
  Wall = {"noncommercial/wall", "Immovable obstruction."},
  BossFlame = {"noncommercial/boss_flame", "Flamethrower boss."},
  BossSlam = {"noncommercial/boss_slam", "Bodyslam boss."},
  BossRocket = {"noncommercial/boss_rocket", "Rocket boss."},
  BossMulti = {"noncommercial/boss", "Hybrid boss."},
}

Command.Environment.Insert(_G, "Inspect.Entity.Icons", function ()
  return lookupIcon
end)