
print("BAB")

local lookup = {
  Spike = function (initiator)
    local ix, iy = initiator.x, initiator.y
    local grid = Inspect.Battle.Grid()
    local entities = Inspect.Battle.Entities()
    
    local closelen = 1000
    local closeent = nil
    
    for entity in pairs(entities) do
      if entity.y == iy and entity.x > ix then
        if entity ~= initiator and math.abs(entity.x - ix) < closelen then
          closelen = math.abs(entity.x - ix)
          closeent = entity
        end
      end
    end
    
    if closeent then
      closeent:Hit()
    end
  end
}

local actives = {}

Command.Environment.Insert(_G, "Command.Battle.Cast", function (abilityId, initiatingEntity)
  print("Casting", abilityId, initiatingEntity)
  actives[coroutine.spawn(function (...) lookup[abilityId](...) while true do coroutine.yield(true) end end, initiatingEntity)] = true
end)

print("CBC", Command.Battle.Cast)
print(Command)

Event.System.Tick:Attach(function ()
  if not Inspect.Battle.Active() then return end

  local nactives = {}
  for k in pairs(actives) do
    if not k() then
      nactives[k] = true
    end
  end
  actives = nactives
end)
