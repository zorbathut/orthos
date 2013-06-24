
local sfx = Frame.Frame(Frame.Root)
sfx:SetLayer(100)

print("BAB")

local lookup = {
  Spike = function (initiator)
    local ix, iy = initiator.x, initiator.y
    local grid = Inspect.Battle.Grid()
    local entities = Inspect.Battle.Entities()
    
    Command.Battle.Cast("SFXBlast", ix, iy);
    
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
      Command.Battle.Cast("SFXExplosion", closeent);
    end
  end,
  
  SFXBlast = function (x, y)
    local grid = Inspect.Battle.Grid()
    local blaster = Frame.Texture(sfx)
    blaster:SetTexture("placeholder/blaster.png")
    blaster:SetPoint("CENTERLEFT", grid[x][y], "CENTER", 20, -20)
    
    Command.Coro.Wait(0.1)
    
    blaster:Obliterate()
  end,
  
  SFXExplosion = function (target)
    local grid = Inspect.Battle.Grid()
    local explosion = Frame.Texture(sfx)
    explosion:SetTexture("copyright_infringement/Explosion.png")
    explosion:SetPoint("CENTER", grid[target.x][target.y], "CENTER", 0, 0)
    
    local dur = 60 * 0.3
    for k = 1, dur do
      coroutine.yield()
      explosion:SetTint(1, 1, 1, 1 - k / dur)
    end
    
    explosion:Obliterate()
  end,
}

local actives = {}

Command.Environment.Insert(_G, "Command.Battle.Cast", function (abilityId, ...)
  print("Casting", abilityId, ...)
  actives[coroutine.spawn(function (...) lookup[abilityId](...) while true do coroutine.yield(true) end end, ...)] = true
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
