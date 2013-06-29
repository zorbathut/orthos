
layer = {
  bg = -10,
  grid = -1,
  entities = 0,
  sfx = 1,
  hud = 2,
  ded = 5,
  deckbuilder = 10
}

do
  local bg = Frame.Texture(Frame.Root)
  bg:SetLayer(layer.bg)
  bg:SetTexture("copyright_infringement/cyberspace_bg")
  bg:SetPoint("TOPLEFT", Frame.Root, "TOPLEFT")
  bg:SetPoint("BOTTOMRIGHT", Frame.Root, "BOTTOMRIGHT")
end

local state = "playing"

local hud = Frame.Frame(Frame.Root)
hud:SetLayer(layer.hud)

assert(loadfile("battle_ability.lua"))()

local deckDiscard = {}
do
  local types = {"Spike", "Shatter", "Blast", "Pierce"}
  for k = 1, 40 do
    table.insert(deckDiscard, {name = types[math.random(#types)], type = "Steel"})
  end
end

local deckStack = {}
Command.Environment.Insert(_G, "Command.Deck.Draw", function ()
  if #deckStack > 0 then
    return table.remove(deckStack)
  end
  
  deckStack = {}
  for k, v in pairs(deckDiscard) do
    table.insert(deckStack, v)
  end
  
  -- shuffle
  for k in ipairs(deckStack) do
    local srcidx = math.random(#deckStack - k + 1) + k - 1
    local sitem = deckStack[srcidx]
    deckStack[srcidx] = deckStack[k]
    deckStack[k] = sitem
  end
  
  deckDiscard = {}
  
  assert(#deckStack > 0)
  return table.remove(deckStack) -- explodes if for some reason we have all cards being held
end)

Command.Environment.Insert(_G, "Command.Deck.Discard", function (card)
  table.insert(deckDiscard, card)
end)

local deckActive = {}

local function deckChoose()
  while #deckActive > 0 do
    Command.Deck.Discard(table.remove(deckActive))
  end
  
  state = "decking"
  
  local deckbuild = Command.Environment.Create(_G, "Deck", "battle_deckbuild.lua")
  deckbuild.Frame.Root:SetLayer(layer.deckbuilder)
  
  deckbuild.Event.Deck.Created:Attach(function (deck)
    dump("Deck chosen:", deck)
    deckActive = deck
    
    Command.Environment.Destroy(deckbuild)
    deckbuild = nil -- let cleanup happen
    
    -- one-frame delay because otherwise we try to autofire
    -- todo: rig up better event control
    state = "deck_aborting"
    
    Command.Battle.Display.Card.Resync()
  end)
end
deckChoose()

local gridsize = 200
local border = 5
local outline = 5

local grid = Frame.Frame(Frame.Root)
grid:SetPoint("TOPLEFT", Frame.Root, "CENTER", -gridsize * 3, -gridsize * 1.5)
grid:SetPoint("BOTTOMRIGHT", Frame.Root, "CENTER", gridsize * 3, gridsize * 1.5)
grid:SetLayer(layer.grid)

for row = 1, 6 do
  grid[row] = {}
  
  local enemy = false
  if row >= 4 then enemy = true end
  
  for col = 1, 3 do
    local brick = Frame.Frame(grid)
    brick.enemy = enemy
    grid[row][col] = brick
    
    brick:SetPoint("TOPLEFT", grid, "TOPLEFT", row * gridsize - gridsize, col * gridsize - gridsize)
    brick:SetWidth(gridsize)
    brick:SetHeight(gridsize)
    
    local inlay = Frame.Frame(brick)
    inlay:SetPoint("TOPLEFT", brick, "TOPLEFT", border, border)
    inlay:SetPoint("BOTTOMRIGHT", brick, "BOTTOMRIGHT", -border, -border)
    
    
    local demph = Frame.Frame(inlay)
    demph:SetPoint("TOPLEFT", inlay, "TOPLEFT", border, border)
    demph:SetPoint("BOTTOMRIGHT", inlay, "BOTTOMRIGHT", -border, -border)
    
    local alive = true
    function brick:AliveSet(in_alive)
      alive = in_alive
      
      if enemy then
        if alive then
          inlay:SetBackground(0.5, 0.2, 0.2)
        else
          inlay:SetBackground(0.2, 0.0, 0.0)
        end
      else
        if alive then
          inlay:SetBackground(0.2, 0.2, 0.5)
        else
          inlay:SetBackground(0.0, 0.0, 0.2)
        end
      end
      
      if alive then
        demph:SetBackground(0.1, 0.1, 0.1)
      else
        demph:SetBackground(0.02, 0.02, 0.02)
      end
    end
    function brick:AliveGet()
      return alive
    end
    brick:AliveSet(true)
  end
end

local entityLayer = Frame.Frame(Frame.Root)
entityLayer:SetLayer(layer.entities)

local entities = {}
local player = nil -- filled with actual player

local function MakeEntity(params)
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
  
  function fram:CanTravel(x, y)
    if not (grid[x] and grid[x][y] and grid[x][y]:AliveGet()) then
      return false
    end
    
    if grid[x][y].entity and grid[x][y].entity ~= self then
      return false
    end
    
    if faction == "enemy" and grid[x][y].enemy == false then return false end
    if faction == "friendly" and grid[x][y].enemy == true then return false end
    
    return true
  end
  
  function fram:Shift(dx, dy)
    self:Warp(self.x + dx, self.y + dy)
  end
  
  function fram:Warp(nx, ny)
    assert(self:CanTravel(nx, ny))
    if self:CanTravel(nx, ny) then
    
      if self.x or self.y then
        grid[self.x][self.y].entity = nil
      end
      
      self.x = nx
      self.y = ny
      self:SetPoint("CENTER", grid[nx][ny], "CENTER")
      
      if self.x or self.y then
        grid[self.x][self.y].entity = self
      end
      
    end
  end
  
  function fram:ShiftTry(dx, dy)
    if self:CanTravel(self.x + dx, self.y + dy) then
      self:Shift(dx, dy)
    end
  end
  
  function fram:WarpTry(dx, dy)
    if self:CanTravel(self.x + dx, self.y + dy) then
      self:Warp(dx, dy)
    end
  end
  
  function fram:Hit()
    -- take damage if possible
    -- this is super hacky
    if faction == "enemy" then
      Command.Battle.Damage(true)
    elseif faction == "friendly" then
      Command.Battle.Damage(false)
    else
      print("Damage to unknown unit!")
    end
  end
  
  function fram:FactionGet()
    return faction
  end
  
  function fram:Fall()
    -- For now . . .
    self:Obliterate()
    entities[self] = nil
  end
  
  fram:Warp(x, y)
  
  entities[fram] = true
  
  return fram
end

function MakePlayer(x, y)
  local player = MakeEntity({x = x, y = y, pic = "noncommercial/hero", faction = "friendly"})
  
  function player:FirePrimary()
    if #deckActive > 0 then
      dump(deckActive[1])
      Command.Battle.Cast(deckActive[1].name, self)
      table.remove(deckActive, 1)
      
      Command.Battle.Display.Card.Resync()
    else
      deckChoose()
    end
  end
  
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
    
    state = "loss"
    
    self:Obliterate()
    entities[self] = nil
  end
  
  return player
end

function MakeBandit(x, y)
  local bandit = MakeEntity({x = x, y = y, pic = "noncommercial/bandit", faction = "enemy"})
  
  local indicator = Frame.Text(bandit)
  indicator:SetPoint("RIGHTCENTER", bandit.img, "LEFTCENTER")
  indicator:SetVisible(false)
  indicator:SetSize(20)
  
  bandit.Think = coroutine.wrap(function ()
    while true do
      if player.y == bandit.y then
        print("On level")
        
        indicator:SetVisible(true)
        local ct = 90
        for i = 1, ct do
          indicator:SetText(tostring(ct - i))
          coroutine.yield()
        end
        
        Command.Battle.Cast("EnemySpike", bandit)
        
        indicator:SetVisible(false)
        
        for i = 1, 30 do
          coroutine.yield()
        end
      end
      
      coroutine.yield()
    end
  end)
  
  return bandit
end
  
player = MakePlayer(1, 2)

MakeBandit(6, 3)
MakeBandit(5, 1)

hud:SetPoint("BOTTOMRIGHT", player, "TOPCENTER")

Command.Environment.Insert(_G, "Command.Battle.Display.Card.Resync", function ()
  if hud.carddisplay then
    hud.carddisplay:Obliterate()
  end
  
  hud.carddisplay = Frame.Frame(hud)
  
  local bottom = hud
  for k = 1, #deckActive do
    local tf = Command.Art.Button.Card(hud.carddisplay, deckActive[k])
    tf:SetPoint("BOTTOMRIGHT", bottom, "BOTTOMRIGHT", -10, -10)
    tf:SetLayer(-k)
    bottom = tf
  end
end)

Command.Environment.Insert(_G, "Command.Battle.Bump", function (x, y)
  if grid[x][y].entity then
    local entity = grid[x][y].entity

    local dx = {0, 0, 1, -1}
    local dy = {1, -1, 0, 0}
    local avail = {}
    for id in ipairs(dx) do
      if entity:CanTravel(x + dx[id], y + dy[id]) then
        table.insert(avail, {x + dx[id], y + dy[id]})
      end
    end
    
    if #avail == 0 then
      for nx in ipairs(grid) do
        for ny in ipairs(grid[nx]) do
          if entity:CanTravel(nx, ny) then
            table.insert(avail, {nx, ny})
          end
        end
      end
    end
    
    if #avail == 0 then
      -- Destroy entity!
      entity:Fall()
    else
      local ncor = avail[math.random(#avail)]
      entity:Warp(ncor[1], ncor[2])
    end
  end
end)

Command.Environment.Insert(_G, "Command.Battle.Damage", function (enemy)
  local order
  if enemy then
    order = {6, 5, 4}
  else
    order = {1, 2, 3}
  end
  
  for _, kx in ipairs(order) do
    local available = {}
    for ky, tab in pairs(grid[kx]) do
      if tab:AliveGet() then
        table.insert(available, ky)
      end
    end
    
    if #available > 0 then
      local chosen = available[math.random(#available)]
      grid[kx][chosen]:AliveSet(false)
      Command.Battle.Bump(kx, chosen)
      break
    end
  end
end)

Command.Environment.Insert(_G, "Inspect.Battle.Grid", function ()
  return grid
end)

Command.Environment.Insert(_G, "Inspect.Battle.Entities", function ()
  return entities
end)

Command.Environment.Insert(_G, "Inspect.Battle.Active", function ()
  return state == "playing"
end)

Event.System.Key.Down:Attach(function (key)
  if state ~= "playing" then return end
  
  if key == "Up" then
    player:ShiftTry(0, -1)
  elseif key == "Down" then
    player:ShiftTry(0, 1)
  elseif key == "Left" then
    player:ShiftTry(-1, 0)
  elseif key == "Right" then
    player:ShiftTry(1, 0)
  elseif key == "z" then
    player:FirePrimary()
  end
end)

Event.System.Tick:Attach(function ()
  if state == "deck_aborting" then state = "playing" return end  -- eugh
  if not Inspect.Battle.Active() then return end
  
  for entity in pairs(entities) do
    if entity.Think then
      entity.Think()
    end
  end
end)
