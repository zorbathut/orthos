
local enemypack, mode = ...

local battleEnvironment
local arf

local function RebuildBattle()
  if battleEnvironment then
    Command.Environment.Destroy(battleEnvironment)
    battleEnvironment = nil
  end
  if arf then
    Command.Environment.Destroy(arf)
    arf = nil
  end
  
  battleEnvironment = Command.Environment.Create(_G, "Battle", "battle.lua", enemypack)

  battleEnvironment.Event.Battle.Lost:Attach(function ()
    -- uhoh
    arf = Command.Environment.Create(_G, "Arf", "battleloop_arf.lua", "lose")
    arf.Frame.Root:SetLayer(1)
  end)
  
  battleEnvironment.Event.Battle.Won:Attach(function ()
    -- yay
    arf = Command.Environment.Create(_G, "Arf", "battleloop_arf.lua", "win")
    arf.Frame.Root:SetLayer(1)
  end)
end
RebuildBattle()

Command.Environment.Insert(_G, "Command.War.Retry", function ()
  RebuildBattle()
end)

if not mode then
  Command.Environment.Insert(_G, "Command.War.Abort", function ()
    Command.Battle.Abort() -- same thing right now
  end)

  Command.Environment.Insert(_G, "Command.War.Fail", function ()
    Command.Init.Return()
  end)
elseif mode == "forge" then
  Command.Environment.Insert(_G, "Command.War.Abort", function ()
    Command.Forge.Test.End()
  end)

  Command.Environment.Insert(_G, "Command.War.Fail", function ()
    Command.Forge.Test.End()
  end)
else
  assert(false)
end
