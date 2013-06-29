
local sfx = Frame.Frame(Frame.Root)
sfx:SetLayer(layer.sfx)

local function DamageAoe(tx, ty, dx, dy)
  assert(tx)
  assert(ty)
  assert(#dx == #dy)
  
  local entitiesToDamage = {} -- don't want to bump things around and damage them twice - TODO make this standard functionality?
  
  local entities = Inspect.Battle.Entities()
  for entity in pairs(entities) do
    local match = false
    for i = 1, #dx do
      if entity.x == tx + dx[i] and entity.y == ty + dy[i] then
        table.insert(entitiesToDamage, entity)
        break
      end
    end
  end
  
  for _, v in ipairs(entitiesToDamage) do
    v:Hit()
  end
end

local function SearchScanline(sx, sy, direction, missEnemy, missFriendly)
  assert(direction ~= 0)
  if direction == 0 then return {} end
  
  local found = {}
  
  sx = sx + direction * 0.1 -- close enough
  
  print(sx, sy, direction)
  for entity in pairs(Inspect.Battle.Entities()) do
    print(entity.x, entity.y, sx, sy, direction, (sx - entity.x) * direction)
    if entity.y == sy and not (entity:FactionGet() == "enemy" and missEnemy) and not (entity:FactionGet() == "friendly" and missFriendly) and (entity.x - sx) * direction > 0 then
      table.insert(found, {ent = entity, dist = math.abs(sx - entity.x)})
    end
  end
  
  table.sort(found, function (a, b) return a.dist < b.dist end)
  
  local rv = {}
  for _, v in ipairs(found) do
    table.insert(rv, v.ent)
  end
  return rv
end

local lookup = {

--[[ ============================
      PLAYER SPELLS
      ============================ ]]
      
  Spike = function (initiator)
    local ix, iy = initiator.x, initiator.y
    local grid = Inspect.Battle.Grid()
    local entities = Inspect.Battle.Entities()
    
    Command.Battle.Cast("SFXFire", ix, iy)
    
    local targets = SearchScanline(ix, iy, 1, false, false)
    
    if targets[1] then
      Command.Battle.Cast("SFXExplosion", targets[1])
      targets[1]:Hit()
    end
  end,
  
  Shatter = function (initiator)
    local ix, iy = initiator.x, initiator.y
    local targetx, targety = ix + 3, iy
    
    local target = Frame.Texture(sfx)
    local grid = Inspect.Battle.Grid()
    
    target:SetTexture("noncommercial/ice")
    target:SetWidth(grid[1][1]:GetWidth() * 3)
    target:SetHeight(grid[1][1]:GetHeight() * 3)
    
    target:SetPoint("CENTER", grid[targetx][targety], "CENTER")
    
    target:SetAlpha(0.2)
    
    local chargeup = 30
    local cooldown = 30
    
    for i = 1, chargeup do
      target:SetAlpha(0.2 + math.pow(i / chargeup, 5) * 0.8)
      coroutine.yield()
    end
    
    DamageAoe(targetx, targety, {-1, -1, 0, 1, 1}, {-1, 1, 0, -1, 1})
    
    for i = 1, cooldown do
      target:SetAlpha(1.0 - math.pow(i / cooldown, 2))
      coroutine.yield()
    end
    
    target:Obliterate()
  end,
  
  Blast = function (initiator)
    local x, y = initiator.x, initiator.y
    DamageAoe(x, y, {1, 1, 1, 2}, {-1, 0, 1, 0})
    
    Command.Battle.Cast("SFXBlast", x, y, 1, -1)
    Command.Battle.Cast("SFXBlast", x, y, 1, 0)
    Command.Battle.Cast("SFXBlast", x, y, 1, 1)
    Command.Battle.Cast("SFXBlast", x, y, 2, 0)
  end,
  
  Pierce = function (initiator)
    local ix, iy = initiator.x, initiator.y
    local grid = Inspect.Battle.Grid()
    local entities = Inspect.Battle.Entities()
    
    Command.Battle.Cast("SFXFire", ix, iy)
    
    local targets = SearchScanline(ix, iy, 1, false, false)
    
    if targets[1] then
      Command.Battle.Cast("SFXPierce", targets[1])
    end
    
    if targets[2] then
      Command.Battle.Cast("SFXExplosion", targets[2])
      targets[2]:Hit()
    end
  end,
  
--[[ ============================
      ENEMY SPELLS
      ============================ ]]

  EnemySpike = function (initiator)
    local ix, iy = initiator.x, initiator.y
    local grid = Inspect.Battle.Grid()
    local entities = Inspect.Battle.Entities()
    
    Command.Battle.Cast("SFXFire", ix, iy, -1)
    
    local targets = SearchScanline(ix, iy, -1, true, false)
    
    if targets[1] then
      Command.Battle.Cast("SFXExplosion", targets[1])
      targets[1]:Hit()
    end
  end,
      
--[[ ============================
      VISUAL EFFECTS
      ============================ ]]
      
  SFXFire = function (x, y, direction)
    local grid = Inspect.Battle.Grid()
    local blaster = Frame.Texture(sfx)
    if direction ~= -1 then
      blaster:SetTexture("placeholder/blaster")
      blaster:SetPoint("CENTERLEFT", grid[x][y], "CENTER", 20, -20)
    else
      blaster:SetTexture("placeholder/blaster_mirror")
      blaster:SetPoint("CENTERRIGHT", grid[x][y], "CENTER", -20, -20)
    end
    
    local cooldown = 6
    for i = 1, cooldown do
      blaster:SetAlpha(1.0 - math.pow(i / cooldown, 2))
      coroutine.yield()
    end
    
    blaster:Obliterate()
  end,
  
  SFXBlast = function (x, y, dx, dy)
    local grid = Inspect.Battle.Grid()
    local flame = Frame.Texture(sfx)
    local gridx = grid[x][y]:GetWidth()
    local gridy = grid[x][y]:GetHeight()
    flame:SetTexture("noncommercial/fire")
    flame:SetPoint("CENTER", grid[x][y], "CENTER", gridx * dx, gridy * dy)
    flame:SetWidth(grid[x][y]:GetWidth())
    flame:SetHeight(grid[x][y]:GetHeight())
    
    local cooldown = 15
    for i = 1, cooldown do
      flame:SetAlpha(1.0 - math.pow(i / cooldown, 2))
      coroutine.yield()
    end
    
    flame:Obliterate()
  end,
  
  SFXExplosion = function (target)
    local grid = Inspect.Battle.Grid()
    local explosion = Frame.Texture(sfx)
    explosion:SetTexture("copyright_infringement/Explosion")
    explosion:SetPoint("CENTER", grid[target.x][target.y], "CENTER", 0, 0)
    
    local dur = 60 * 0.3
    for k = 1, dur do
      coroutine.yield()
      explosion:SetTint(1, 1, 1, 1 - k / dur)
    end
    
    explosion:Obliterate()
  end,
  
  SFXPierce = function (target)
    local grid = Inspect.Battle.Grid()
    local pierce = Frame.Texture(sfx)
    pierce:SetTexture("placeholder/pierce")
    pierce:SetPoint("CENTER", grid[target.x][target.y], "CENTER", 0, 0)
    
    local cooldown = 10
    for i = 1, cooldown do
      pierce:SetAlpha(1.0 - math.pow(i / cooldown, 2))
      coroutine.yield()
    end
    
    pierce:Obliterate()
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
