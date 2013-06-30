
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
      
      loseTrigger()
      
      Entity.Fall(self)
    end
    
    return player
  end,
  
  Bandit = function (x, y)
    local grid = Inspect.Battle.Grid.Table()
    local bandit = CreateEntity({x = x, y = y, pic = "noncommercial/bandit", faction = "enemy"})
  
    bandit.indicator = Frame.Texture(bandit)
    bandit.indicator:SetTexture("placeholder/reticle")
    bandit.indicator:SetVisible(false)
    
    function ai(self)
      for i = 1, 60 do
        coroutine.yield()
      end
      
      while true do
        local targets = Inspect.Battle.Grid.Hitscan(self:XGet(), self:YGet(), -1, true, false)
        if targets[1] then
          self.indicator:SetVisible(true)
          
          local dx = 1
          
          self.indicator:SetPoint("CENTER", grid[self:XGet() - dx][self:YGet()], "CENTER")
          
          local framespermove = 20
          for i = 1, framespermove / 2 do
            coroutine.yield()
          end
          
          local fire = false
          while true do
            for i = 1, framespermove do
              if grid[self:XGet() - dx][self:YGet()].entity and grid[self:XGet() - dx][self:YGet()].entity:FactionGet() ~= "enemy" then
                fire = true
                for i = 1, framespermove * 1.5 do
                  coroutine.yield()
                end
                break
              end
              coroutine.yield()
            end
            
            -- early out from the inner loop
            if fire then break end
            
            dx = dx + 1
            if not grid[self:XGet() - dx] then
              break
            end
            self.indicator:SetPoint("CENTER", grid[self:XGet() - dx][self:YGet()], "CENTER")
          end
          
          if fire then
            Command.Battle.Cast("EnemySpike", self)
          end
          
          self.indicator:SetVisible(false)
          
          for i = 1, 30 do
            coroutine.yield()
          end
        else
          coroutine.yield()
        end
      end
    end
    
    function bandit:Bump()
      bandit.Think = coroutine.spawn(ai, bandit)
      bandit.indicator:SetVisible(false)
    end
    bandit:Bump()
    
    return bandit
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
  
  BossFlame = function (x, y)
    local boss = CreateEntity({x = x, y = y, pic = "noncommercial/boss_flame", faction = "enemy"})
    local grid = Inspect.Battle.Grid.Table()
    
    local indicator = Frame.Texture(boss)
    indicator:SetTexture("noncommercial/fire")
    indicator:SetVisible(false)
    indicator:SetPoint(0.5, nil, boss.img, "LEFT")
    indicator:SetHeight(45)
    indicator:SetWidth(45)
    
    function ai(self)
      local prerollPause = 120
      local hopMin = 2
      local hopMax = 5
      local hopDelay = 25
      local flameDelay = 60
      
      while true do
        for i = 1, prerollPause do
          coroutine.yield()
        end
        
        local hops = math.random(hopMin, hopMax)
        for i = 1, hops do
          local finalhop = (i == hops)
          
          local dests = {}
          for nx in ipairs(grid) do
            for ny in ipairs(grid[nx]) do
              if self:CanTravel(nx, ny) and grid[nx][ny].entity ~= self then
                if not finalhop or nx ~= 6 then
                  table.insert(dests, {nx, ny})
                end
              end
            end
          end
          
          if #dests > 0 then
            local dest = dests[math.random(#dests)]
            
            self:Warp(dest[1], dest[2])
          else
            break
          end
          
          if not finalhop then
            for i = 1, hopDelay do
              coroutine.yield()
            end
          end
        end
        
        indicator:SetVisible(true)
        for i = 1, flameDelay do
          indicator:SetPoint(nil, 0.5, self, nil, 0.3 + math.random() * 0.4)
          coroutine.yield()
        end
        indicator:SetVisible(false)
        
        Command.Battle.Cast("EnemyBossFlame", self)
      end
    end
    
    function boss:Bump()
      boss.Think = coroutine.spawn(ai, boss)
      indicator:SetVisible(false)
    end
    boss:Bump()
    
    return boss
  end,
}

Command.Environment.Insert(_G, "Command.Battle.Spawn", function (entityId, ...)
  print("Spawning", entityId, ...)
  local ent = lookup[entityId](...)
  assert(ent)
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

