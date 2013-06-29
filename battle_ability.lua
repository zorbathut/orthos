
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
      if entity:XGet() == tx + dx[i] and entity:YGet() == ty + dy[i] then
        table.insert(entitiesToDamage, entity)
        break
      end
    end
  end
  
  for _, v in ipairs(entitiesToDamage) do
    v:Hit()
  end
end

local lookup = {

--[[ ============================
      PLAYER SPELLS
      ============================ ]]
      
  Spike = function (initiator)
    local ix, iy = initiator:XGet(), initiator:YGet()
    local grid = Inspect.Battle.Grid.Table()
    local entities = Inspect.Battle.Entities()
    
    Command.Battle.Cast("SFXFire", ix, iy)
    
    local targets = Inspect.Battle.Grid.Hitscan(ix, iy, 1, false, false)
    
    if targets[1] then
      Command.Battle.Cast("SFXExplosion", targets[1])
      targets[1]:Hit()
    end
  end,
  
  Shatter = function (initiator)
    local ix, iy = initiator:XGet(), initiator:YGet()
    local targetx, targety = ix + 3, iy
    
    local target = Frame.Texture(sfx)
    local grid = Inspect.Battle.Grid.Table()
    
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
    local x, y = initiator:XGet(), initiator:YGet()
    DamageAoe(x, y, {1, 1, 1, 2}, {-1, 0, 1, 0})
    
    Command.Battle.Cast("SFXBlast", x, y, 1, -1)
    Command.Battle.Cast("SFXBlast", x, y, 1, 0)
    Command.Battle.Cast("SFXBlast", x, y, 1, 1)
    Command.Battle.Cast("SFXBlast", x, y, 2, 0)
  end,
  
  Pierce = function (initiator)
    local ix, iy = initiator:XGet(), initiator:YGet()
    local grid = Inspect.Battle.Grid.Table()
    local entities = Inspect.Battle.Entities()
    
    Command.Battle.Cast("SFXFire", ix, iy)
    
    local targets = Inspect.Battle.Grid.Hitscan(ix, iy, 1, false, false)
    
    if targets[1] then
      Command.Battle.Cast("SFXPierce", targets[1])
    end
    
    if targets[2] then
      Command.Battle.Cast("SFXExplosion", targets[2])
      targets[2]:Hit()
    end
  end,
  
  Dash = function (initiator)
    initiator:WarpTry(3, initiator.y)
    if initiator:XGet() ~= 3 then
      initiator:WarpTry(2, initiator.y)
    end
    
    DamageAoe(initiator:XGet(), initiator:YGet(), {1}, {0})
    
    Command.Battle.Cast("SFXBlast", initiator:XGet(), initiator:YGet(), 1, 0)
  end,
  
  Pull = function (initiator)
    local entities = Inspect.Battle.Entities()
    local targs = {}
    for entity in pairs(entities) do
      if entity:FactionGet() ~= "friendly" then
        table.insert(targs, entity)
      end
    end
    table.sort(targs, function (a, b) return a:XGet() < b:XGet() end)
    
    for _, entity in ipairs(targs) do
      entity:WarpTry(entity:XGet() - 1, entity:YGet())
    end
  end,
  
  Repel = function (initiator)
    local hs = Inspect.Battle.Grid.Hitscan(initiator:XGet(), initiator:YGet(), 1)
    if hs[2] then
      hs[2]:WarpTry(hs[2]:XGet() + 1, hs[2]:YGet())
    end
    
    if hs[1] then
      hs[1]:WarpTry(hs[1]:XGet() + 1, hs[1]:YGet())
      hs[1]:WarpTry(hs[1]:XGet() + 1, hs[1]:YGet())
    end
  end,
  
  Fortify = function (initiator)
    local grid = Inspect.Battle.Grid.Table()
    for y = 1, 3 do
      for x = 3, 1, -1 do
        if not grid[x][y]:AliveGet() then
          grid[x][y]:AliveSet(true)
          break
        end
      end
    end
  end,
  
  Wall = function (initiator)
    local grid = Inspect.Battle.Grid.Table()
    local destx, desty = initiator:XGet() + 1, initiator:YGet()
    
    if grid[destx][desty].entity then
      Command.Battle.Bump(destx, desty)
    end
    
    if not grid[destx][desty].entity then
      local wall = Command.Battle.Spawn("Wall", destx, desty)
      if not grid[destx][desty]:AliveGet() then
        wall:Fall()
      end
    end
  end,
  
--[[ ============================
      ENEMY SPELLS
      ============================ ]]

  EnemySpike = function (initiator)
    local ix, iy = initiator:XGet(), initiator:YGet()
    local grid = Inspect.Battle.Grid.Table()
    local entities = Inspect.Battle.Entities()
    
    Command.Battle.Cast("SFXFire", ix, iy, -1)
    
    local targets = Inspect.Battle.Grid.Hitscan(ix, iy, -1, true, false)
    
    if targets[1] then
      Command.Battle.Cast("SFXExplosion", targets[1])
      targets[1]:Hit()
    end
  end,
      
--[[ ============================
      VISUAL EFFECTS
      ============================ ]]
      
  SFXFire = function (x, y, direction)
    local grid = Inspect.Battle.Grid.Table()
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
    local grid = Inspect.Battle.Grid.Table()
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
    local grid = Inspect.Battle.Grid.Table()
    local explosion = Frame.Texture(sfx)
    explosion:SetTexture("copyright_infringement/Explosion")
    explosion:SetPoint("CENTER", grid[target:XGet()][target:YGet()], "CENTER", 0, 0)
    
    local dur = 60 * 0.3
    for k = 1, dur do
      coroutine.yield()
      explosion:SetTint(1, 1, 1, 1 - k / dur)
    end
    
    explosion:Obliterate()
  end,
  
  SFXPierce = function (target)
    local grid = Inspect.Battle.Grid.Table()
    local pierce = Frame.Texture(sfx)
    pierce:SetTexture("placeholder/pierce")
    pierce:SetPoint("CENTER", grid[target:XGet()][target:YGet()], "CENTER", 0, 0)
    
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
