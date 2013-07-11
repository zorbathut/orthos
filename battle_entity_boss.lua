local Lookup = ...

--[[ BOSS TUNING FACTORS ]]

local prerollPause = Utility.TicksFromSeconds(1.3)
local hopMin = 1
local hopMax = 3
local hopDelay = Utility.TicksFromSeconds(0.45)
local flameDelay = Utility.TicksFromSeconds(1)
local slamDelay = Utility.TicksFromSeconds(0.6)
local slamSpeed = 10 / Utility.TicksFromSeconds(1)
local slamXEnd = -3
local slamXSpawn = 9
local rocketDelay = Utility.TicksFromSeconds(1.2)
local rocketLaunchSpeed = 0.9 / Utility.TicksFromSeconds(1)
local rocketTravelSpeed = 15 / Utility.TicksFromSeconds(1)

--[[ BOSS SHARED FUNCTIONALITY ]]

local function BossHop(self, typ)
  local grid = Inspect.Battle.Grid.Table()
  
  for i = 1, prerollPause do
    coroutine.yield()
  end
  
  local hops = math.random(hopMin, hopMax)
  for i = 1, hops do
    local finalhop = (i == hops)
    
    -- make one hop
    local dests = {}
    for nx in ipairs(grid) do
      for ny in ipairs(grid[nx]) do
        if self:AnchorWarpValid(nx, ny) and grid[nx][ny].entity ~= self then
          local allow = true
          if typ == "flame" and finalhop and nx == 6 then -- if we're on our final hop, hop to one of the front two rows so our flamethrower won't be useless
            allow = false
          end
          
          if allow then 
            table.insert(dests, {nx, ny})
          end
        end
      end
    end
    
    -- warp if we can. if we can't, exit immediately so we can turboflame
    if #dests > 0 then
      local dest = dests[math.random(#dests)]
      
      self:AnchorWarp(dest[1], dest[2])
    else
      break
    end
    
    -- don't want an extra hop delay on flamethrowing
    if not finalhop then
      for i = 1, hopDelay do
        coroutine.yield()
      end
    end
  end
end

--[[ FLAME BOSS ]]

function BossFlameRoutine(self, indicator)
  indicator:SetPoint(0.5, nil, self.img, "LEFT")
  
  BossHop(self, "flame")

  -- flamethrower hint
  indicator:SetVisible(true)
  for i = 1, flameDelay do
    indicator:SetPoint(nil, 0.5, self, nil, 0.3 + math.random() * 0.4)
    coroutine.yield()
  end
  indicator:SetVisible(false)

  -- fwoosh
  Command.Battle.Cast("EnemyBossFlame", self)
end

function Lookup.BossFlame(x, y)
  local boss = CreateEntity({x = x, y = y, pic = "noncommercial/boss_flame", faction = "enemy"})
  local grid = Inspect.Battle.Grid.Table()
  
  local indicator = Frame.Texture(boss)
  indicator:SetTexture("noncommercial/fire")
  indicator:SetVisible(false)
  indicator:SetHeight(45)
  indicator:SetWidth(45)
  
  function ai(self)
    while true do
      BossFlameRoutine(self, indicator)
    end
  end
  
  function boss:Bump()
    -- reset AI if the boss is bumped. TODO, do so only during flamethrower chargeup?
    self.Think = coroutine.spawn(ai, boss)
    indicator:SetVisible(false)
  end
  boss:Bump()
  
  return boss
end

--[[ SLAM BOSS ]]

local function TestImpact(self, impacts)
  local grid = Inspect.Battle.Grid.Table()
  if grid[self:PositionXGetGrid()] and grid[self:PositionXGetGrid()][self:PositionYGetGrid()] then
    local ent = grid[self:PositionXGetGrid()][self:PositionYGetGrid()].entity
    if ent and ent:FactionGet() ~= "enemy" and not impacts[ent] then
      impacts[ent] = true
      ent:Hit()
    end
  end
end

function BossSlamRoutine(self, indicator)
  indicator:SetPoint(0.5, nil, self.img, "RIGHT")
  
  BossHop(self, "slam")
  
  -- flamethrower hint
  indicator:SetVisible(true)
  for i = 1, slamDelay do
    indicator:SetPoint(nil, 0.5, self, nil, 0.3 + math.random() * 0.4)
    coroutine.yield()
  end
  
  -- fwoosh
  self:PositionAttachSet(false)
  
  local impacts = {}
  
  while self:PositionXGet() > slamXEnd do
    indicator:SetPoint(nil, 0.5, self, nil, 0.3 + math.random() * 0.4)
    coroutine.yield()
    self:PositionWarp(self:PositionXGet() - slamSpeed, self:PositionYGet())
    TestImpact(self, impacts)
  end
  
  self:PositionWarp(slamXSpawn, self:AnchorYGet())
  
  while self:PositionXGet() > self:AnchorXGet() do
    indicator:SetPoint(nil, 0.5, self, nil, 0.3 + math.random() * 0.4)
    coroutine.yield()
    self:PositionWarp(self:PositionXGet() - slamSpeed, self:PositionYGet())
    TestImpact(self, impacts)
  end
  
  self:PositionAttachSet(true)
  indicator:SetVisible(false)
end

function Lookup.BossSlam(x, y)
  local boss = CreateEntity({x = x, y = y, pic = "noncommercial/boss_slam", faction = "enemy"})
  local grid = Inspect.Battle.Grid.Table()
  
  local indicator = Frame.Texture(boss)
  indicator:SetTexture("noncommercial/fire")
  indicator:SetVisible(false)
  indicator:SetHeight(45)
  indicator:SetWidth(45)
  
  function ai(self)
    while true do
      BossSlamRoutine(self, indicator)
    end
  end
  
  function boss:Bump()
    -- reset AI if the boss is bumped. TODO, do so only during flamethrower chargeup?
    self.Think = coroutine.spawn(ai, boss)
    indicator:SetVisible(false)
    self:PositionAttachSet(true)
  end
  boss:Bump()
  
  return boss
end

--[[ ROCKET BOSS ]]

function BossRocketRoutine(self)
  BossHop(self, "rocket")
  
  -- launch ze missiles
  Command.Battle.Spawn("BossRocket_Sub", self:AnchorXGet(), self:AnchorYGet(), 1)
  Command.Battle.Spawn("BossRocket_Sub", self:AnchorXGet(), self:AnchorYGet(), -1)
  
  for k = 1, rocketDelay do
    coroutine.yield()
  end
end

function Lookup.BossRocket(x, y)
  local boss = CreateEntity({x = x, y = y, pic = "noncommercial/boss_rocket", faction = "enemy"})
  local grid = Inspect.Battle.Grid.Table()
  
  function ai(self)
    while true do
      BossRocketRoutine(self)
    end
  end
  
  -- this boss doesn't need to reset AI when bumped
  boss.Think = coroutine.spawn(ai, boss)
  
  return boss
end

function Lookup.BossRocket_Sub(x, y, dir)
  local rocket = CreateEntity({x = x, y = y, pic = "noncommercial/rocket", faction = "enemy", attached = false})
  local grid = Inspect.Battle.Grid.Table()
  
  function ai(self)
    while (self:PositionYGet() - (y + dir)) * dir < 0 do
      self:PositionWarp(self:PositionXGet(), self:PositionYGet() + dir * rocketLaunchSpeed)
      coroutine.yield()
    end
    
    while self:PositionXGet() > slamXEnd do
      if grid[self:PositionXGetGrid()] and grid[self:PositionXGetGrid()][self:PositionYGetGrid()] then
        local ent = grid[self:PositionXGetGrid()][self:PositionYGetGrid()].entity
        if ent and ent:FactionGet() ~= "enemy" then
          Command.Battle.Cast("SFXBlast", self:PositionXGet(), self:PositionYGet())
          ent:Hit()
          self:Fall()
          return
        end
      end
      
      self:PositionWarp(self:PositionXGet() - rocketTravelSpeed, self:PositionYGet())
      coroutine.yield()
    end
    
    self:Fall()
  end
  
  -- this boss doesn't need to reset AI when bumped
  rocket.Think = coroutine.spawn(ai, rocket)
  
  function rocket:Hit()
    rocket:Fall() -- kaboom
  end
  
  return rocket
end

--[[ MULTI BOSS ]]

function Lookup.BossMulti(x, y)
  local boss = CreateEntity({x = x, y = y, pic = "noncommercial/boss", faction = "enemy"})
  local grid = Inspect.Battle.Grid.Table()
  
  local indicator = Frame.Texture(boss)
  indicator:SetTexture("noncommercial/fire")
  indicator:SetVisible(false)
  indicator:SetHeight(45)
  indicator:SetWidth(45)
  
  function ai(self)
    local last = nil
    while true do
      local options = {BossFlameRoutine, BossSlamRoutine, BossRocketRoutine}
      local routine = nil
      while not routine do
        routine = options[math.random(#options)]
        if routine == last then
          routine = nil
        end
      end
      last = routine
      routine(self, indicator)
    end
  end
  
  function boss:Bump()
    -- reset AI if the boss is bumped. TODO, do so only during flamethrower chargeup?
    self.Think = coroutine.spawn(ai, boss)
    indicator:SetVisible(false)
    self:PositionAttachSet(true)
  end
  boss:Bump()
  
  return boss
end