
local entityLayer = Frame.Frame(Frame.Root)
entityLayer:SetLayer(layer.entities)

local loseTrigger = Command.Event.Create(_G, "Battle.Lost")

-- repository of all active entities
local entities = {}

--[[ ========== BASE ENTITY CLASS ========== ]]
local Entity = {}
do
  -- Position attach flag
  --  if set, position is moved when anchor is
  

  function Entity:AnchorXGet()
    return self.anchor_x
  end
  
  function Entity:AnchorYGet()
    return self.anchor_y
  end
  
  function Entity:AnchorWarp(nx, ny)
    local grid = Inspect.Battle.Grid.Table()
    
    if nx or ny then
      assert(nx and ny)
      assert(nx == math.floor(nx))
      assert(ny == math.floor(ny))
    end
    
    if self.anchor_x or self.anchor_y then
      assert(grid[self.anchor_x][self.anchor_y].entity == self)
      grid[self.anchor_x][self.anchor_y].entity = nil
    end
    
    self.anchor_x = nx
    self.anchor_y = ny
    
    if self.anchor_x or self.anchor_y then
      assert(grid[self.anchor_x][self.anchor_y].entity == nil)
      grid[self.anchor_x][self.anchor_y].entity = self
    end
    
    if self:PositionAttachGet() and nx and ny then
      self:PositionWarp(nx, ny)
    end
  end
  
  function Entity:AnchorWarpValid(nx, ny)
    assert(nx == math.floor(nx))
    assert(ny == math.floor(ny))
    
    local grid = Inspect.Battle.Grid.Table()
    
    if not (grid[nx] and grid[nx][ny] and grid[nx][ny]:AliveGet()) then
      return false
    end
    
    if grid[nx][ny].entity and grid[nx][ny].entity ~= self then
      return false
    end
    
    if self:FactionGet() == "enemy" and grid[nx][ny].enemy == false then return false end
    if self:FactionGet() == "friendly" and grid[nx][ny].enemy == true then return false end
    
    return true
  end
  
  function Entity:PositionXGet()
    return self.position_x
  end
  
  function Entity:PositionYGet()
    return self.position_y
  end
  
  function Entity:PositionXGetGrid()
    return math.floor(self.position_x + 0.5)
  end
  
  function Entity:PositionYGetGrid()
    return math.floor(self.position_y + 0.5)
  end
  
  function Entity:PositionWarp(nx, ny)
    self.position_x = nx
    self.position_y = ny
    
    Command.Battle.Grid.Position(self, nx, ny)
  end
  
  function Entity:PositionAttachGet()
    return self.positionAttach
  end
  
  function Entity:PositionAttachSet(pa)
    self.positionAttach = pa
    if pa and self:AnchorXGet() and self:AnchorYGet() then
      self:PositionWarp(self:AnchorXGet(), self:AnchorYGet())
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

  function Entity:FactionSet(faction)
    self.faction = faction
  end
  
  function Entity:FactionGet()
    return self.faction
  end
  
  function Entity:Fall()
    -- For now . . .
    self:AnchorWarp(nil, nil)
    entities[self] = nil
    self:Obliterate()
  end  
end

function CreateEntity(params)
  local x = params.x
  local y = params.y
  local pic = params.pic
  local faction = params.faction
  local attached = params.attached
  if attached == nil then
    attached = true
  end
  assert(faction == "enemy" or faction == "friendly" or faction == "neutral")
  
  assert((x and y) or (not x and not y))
  assert(pic)
    
  local fram = Frame.Frame(entityLayer)
  for k, v in pairs(Entity) do
    fram[k] = v
  end
  
  local img = Frame.Texture(fram)
  img:SetPoint(0.5, 0.7, fram, "CENTER")
  img:SetTexture(pic)
  fram.img = img
  
  fram:FactionSet(faction)
  fram:PositionAttachSet(attached)
  if attached then
    fram:AnchorWarp(x, y)
  else
    fram:PositionWarp(x, y)
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
      for i = 1, Utility.TicksFromSeconds(1) do
        coroutine.yield()
      end
      
      while true do
        local targets = Inspect.Battle.Grid.Hitscan(self:PositionXGetGrid(), self:PositionYGetGrid(), -1, true, false)
        if targets[1] then
          self.indicator:SetVisible(true)
          
          local dx = 1
          
          Command.Battle.Grid.Position(self.indicator, self:PositionXGetGrid() - dx, self:PositionYGetGrid())
          
          -- tuning factors
          local framespermove = Utility.TicksFromSeconds(0.3)
          local firedelay = Utility.TicksFromSeconds(0.5)
          local reset = Utility.TicksFromSeconds(0.5)
          
          -- move targeting reticle ahead gradually
          local fire = false
          while true do
            for i = 1, framespermove do
              local tentity = grid[self:PositionXGetGrid() - dx] and grid[self:PositionXGetGrid() - dx][self:PositionYGetGrid()].entity
              if tentity and tentity:FactionGet() ~= "enemy" then
                fire = true
                for i = 1, firedelay * 1.5 do
                  coroutine.yield()
                end
                break
              end
              coroutine.yield()
            end
            
            -- early out from the inner loop, we have a target
            if fire then break end
            
            -- move a notch forward
            dx = dx + 1
            if not grid[self:PositionXGetGrid() - dx] then
              break
            end
            Command.Battle.Grid.Position(self.indicator, self:PositionXGetGrid() - dx, self:PositionYGetGrid())
          end
          
          -- shoot
          if fire then
            Command.Battle.Cast("EnemySpike", self)
          end
          
          -- cleanup
          self.indicator:SetVisible(false)
          
          -- reset
          for i = 1, reset do
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
    hpindicator:SetLayer(2) -- above the pic
    
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

assert(loadfile("battle_entity_boss.lua"))(lookup)

Command.Environment.Insert(_G, "Command.Battle.Spawn", function (entityId, ...)
  print("Spawning", entityId, ...)
  local ent = lookup[entityId](...)
  assert(ent, "Didn't return anything from entity spawn function")
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

