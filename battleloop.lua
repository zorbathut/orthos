
local enemypack = ...

local battleEnvironment
local arf

function RebuildBattle()
  if battleEnvironment then
    Command.Environment.Destroy(battleEnvironment)
    battleEnvironment = nil
  end
  if arf then
    Command.Environment.Destroy(arf)
    arf = nil
  end
  
  battleEnvironment = Command.Environment.Create(_G, "Battle", "battle.lua", nil, enemypack)

  battleEnvironment.Event.Battle.Lost:Attach(function ()
    -- uhoh
    arf = Command.Environment.Create(_G, "Arf", "battleloop_arf.lua", nil, "lose")
    arf.Frame.Root:SetLayer(1)
    AttachArfEvents()
  end)
  
  battleEnvironment.Event.Battle.Won:Attach(function ()
    -- yay
    arf = Command.Environment.Create(_G, "Arf", "battleloop_arf.lua", nil, "win")
    arf.Frame.Root:SetLayer(1)
    AttachArfEvents()
  end)
end

local abortEvent = Command.Event.Create(_G, "Battleloop.Abort")
local failEvent = Command.Event.Create(_G, "Battleloop.Fail")

function AttachArfEvents()
  arf.Event.Battleloop.Arf.Abort:Attach(function ()
    abortEvent()
  end)
  
  arf.Event.Battleloop.Arf.Retry:Attach(function ()
    RebuildBattle()
  end)

  arf.Event.Battleloop.Arf.Fail:Attach(function ()
    failEvent()
  end)
end

RebuildBattle()

