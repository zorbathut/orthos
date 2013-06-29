
local entityLayer = Frame.Frame(Frame.Root)
entityLayer:SetLayer(layer.entities)

local loseTrigger = Command.Event.Create(_G, "Battle.Lost")

-- repository of all active entities
local entities = {}

--[[ ========== BASE ENTITY CLASS ========== ]]
local Entity = {}
do
  function Entity:CanTravel(x, y)
    local grid = Inspect.Battle.Grid.Table()
    
    if not (grid[x] and grid[x][y] and grid[x][y]:AliveGet()) then
      return false
    end
    
    if grid[x][y].entity and grid[x][y].entity ~= self then
      return false
    end
    
    if self:FactionGet() == "enemy" and grid[x][y].enemy == false then return false end
    if self:FactionGet() == "friendly" and grid[x][y].enemy == true then return false end
    
    return true
  end
  
  function Entity:XGet()
    return self.x
  end
  
  function Entity:YGet()
    return self.y
  end

  function Entity:Shift(dx, dy)
    self:Warp(self.x + dx, self.y + dy)
  end

  function Entity:Warp(nx, ny)
    assert(self:CanTravel(nx, ny))
    if self:CanTravel(nx, ny) then
      self:WarpForce(nx, ny)
    end
  end
  
  function Entity:ShiftTry(dx, dy)
    if self:CanTravel(self.x + dx, self.y + dy) then
      self:Shift(dx, dy)
    end
  end
  
  function Entity:WarpTry(nx, ny)
    if self:CanTravel(nx, ny) then
      self:Warp(nx, ny)
    end
  end
  
  function Entity:WarpForce(nx, ny)  
    local grid = Inspect.Battle.Grid.Table()
  
    if self.x or self.y then
      assert(grid[self.x][self.y].entity == self)
      grid[self.x][self.y].entity = nil
    end
    
    self.x = nx
    self.y = ny
    self:SetPoint("CENTER", grid[nx][ny], "CENTER")
    
    if self.x or self.y then
      grid[self.x][self.y].entity = self
    end
  end
  
  function Entity:Hit()
    -- take damage if possible
    -- this is super hacky
    if self:FactionGet() == "enemy" then
      Command.Battle.Damage(true)
    elseif self:FactionGet() == "friendly" then
      Command.Battle.Damage(false)
    else
      print("Damage to unknown unit!")
      assert(false)
    end
  end
  
  function Entity:FactionGet()
    return self.faction
  end
  
  function Entity:Fall()
    -- For now . . .
    self:Obliterate()
    entities[self] = nil
    local grid = Inspect.Battle.Grid.Table()
    if self.x or self.y then
      assert(grid[self.x][self.y].entity == self)
      grid[self.x][self.y].entity = nil
    end
  end
end

function CreateEntity(params)
  local x = params.x
  local y = params.y
  local pic = params.pic
  local faction = params.faction
  assert(faction == "enemy" or faction == "friendly" or faction == "neutral" or faction == "ghost")
  
  assert(x)
  assert(y)
  assert(pic)
  
  local fram = Frame.Frame(entityLayer)
  local img = Frame.Texture(fram)
  img:SetPoint(0.5, 0.7, fram, "CENTER")
  img:SetTexture(pic)
  
  fram.img = img
  fram.faction = faction
  
  for k, v in pairs(Entity) do
    fram[k] = v
  end
  
  if params.canSpawnInVoid then
    fram:WarpForce(x, y)
  else
    fram:Warp(x, y)
  end
  
  return fram
end

--[[ ========== ENTITY INFO LOOKUP ========== ]]
local lookup = {
  Player = function (x, y)
    local player = CreateEntity({x = x, y = y, pic = "noncommercial/hero", faction = "friendly"})
    
    function player:Fall()
      -- uhoh
      local ded = Frame.Frame(Frame.Root)
      ded:SetLayer(layer.ded)
      ded:SetPoint("TOPLEFT", Frame.Root, "TOPLEFT")
      ded:SetPoint("BOTTOMRIGHT", Frame.Root, "BOTTOMRIGHT")
      ded:SetBackground(0.2, 0, 0, 0.7)
      
      local dedtext = Frame.Text(ded)
      dedtext:SetText("U DED")
      dedtext:SetPoint("CENTER", ded, "CENTER")
      dedtext:SetSize(40)
      
      battleLost()
      
      Entity.Fall(self)
    end
    
    return player
  end,
  
  Bandit = function (x, y)
    local bandit = CreateEntity({x = x, y = y, pic = "noncommercial/bandit", faction = "enemy"})
  
    bandit.indicator = Frame.Text(bandit)
    bandit.indicator:SetPoint("RIGHTCENTER", bandit.img, "LEFTCENTER")
    bandit.indicator:SetVisible(false)
    bandit.indicator:SetSize(20)
    
    return bandit
  end,
  
  BanditAI = function(self)
    while true do
      local targets = Inspect.Battle.Grid.Hitscan(self:XGet(), self:YGet(), -1, true, false)
      if targets[1] then
        self.indicator:SetVisible(true)
        local ct = 90
        for i = 1, ct do
          self.indicator:SetText(tostring(ct - i))
          coroutine.yield()
        end
        
        Command.Battle.Cast("EnemySpike", self)
        
        self.indicator:SetVisible(false)
        
        for i = 1, 30 do
          coroutine.yield()
        end
      end
      
      coroutine.yield()
    end
  end,
  
  Wall = function (x, y)
    local wall = CreateEntity({x = x, y = y, pic = "noncommercial/wall", faction = "neutral", canSpawnInVoid = true})
    
    local hpindicator = Frame.Text(wall)
    hpindicator:SetPoint("CENTER", wall, "CENTER")
    hpindicator:SetBackground(0, 0, 0, 0.8)
    hpindicator:SetSize(30)
    
    local hp = 3
    
    hpindicator:SetText(tostring(hp))
    
    function wall:Hit()
      hp = hp - 1
      hpindicator:SetText(tostring(hp))
      if hp == 0 then
        self:Fall()
      end
    end
    
    return wall
  end,
}

Command.Environment.Insert(_G, "Command.Battle.Spawn", function (entityId, ...)
  print("Spawning", entityId, ...)
  local ent = lookup[entityId](...)
  assert(ent)
  if lookup[entityId .. "AI"] then
    ent.Think = coroutine.spawn(lookup[entityId .. "AI"], ent)
  end
  entities[ent] = true
  return ent
end)


Command.Environment.Insert(_G, "Inspect.Battle.Entities", function ()
  return entities
end)

Event.System.Tick:Attach(function ()
  if not Inspect.Battle.Active() then return end
  
  for entity in pairs(entities) do
    if entity.Think then
      entity.Think()
    end
  end
end)

