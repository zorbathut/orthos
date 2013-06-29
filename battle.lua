
local layer = {
  grid = -1,
  entities = 0,
  fx = 1,
  hud = 2,
  deckbuilder = 3
}

local hud = Frame.Frame(Frame.Root)
hud:SetLayer(layer.hud)

assert(loadfile("battle_ability.lua"))()

local deckDiscard = {}
for k = 1, 40 do
  table.insert(deckDiscard, {name = "Spike", type = "Steel"})
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

local decking = false
local function deckChoose()
  while #deckActive > 0 do
    Command.Deck.Discard(table.remove(deckActive))
  end
  
  decking = true
  
  local deckbuild = Command.Environment.Create(_G, "Deck", "battle_deckbuild.lua")
  deckbuild.Frame.Root:SetLayer(layer.deckbuilder)
  
  deckbuild.Event.Deck.Created:Attach(function (deck)
    dump("Deck chosen:", deck)
    deckActive = deck
    
    Command.Environment.Destroy(deckbuild)
    deckbuild = nil -- let cleanup happen
    
    -- one-frame delay because otherwise we try to autofire
    -- todo: rig up better event control
    decking = "aborting"
    
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
  local enemy = params.enemy
  
  assert(x)
  assert(y)
  assert(pic)
  
  local fram = Frame.Frame(entityLayer)
  local img = Frame.Texture(fram)
  img:SetPoint(0.5, 0.7, fram, "CENTER")
  img:SetTexture(pic)
  
  fram.img = img
  
  function fram:CanTravel(x, y)
    return grid[x] and grid[x][y] and (not grid[x][y].enemy) == (not enemy) and grid[x][y]:AliveGet()
  end
  
  function fram:Shift(dx, dy)
    self:Warp(self.x + dx, self.y + dy)
  end
  
  function fram:Warp(nx, ny)
    assert(self:CanTravel(nx, ny))
    if self:CanTravel(nx, ny) then
      self.x = nx
      self.y = ny
      self:SetPoint("CENTER", grid[nx][ny], "CENTER")
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
    Command.Battle.Damage(grid[x][y].enemy)
  end
  
  fram:Warp(x, y)
  
  entities[fram] = true
  
  return fram
end

function MakePlayer(x, y)
  local player = MakeEntity({x = x, y = y, pic = "noncommercial/hero"})
  
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
  
  return player
end

function MakeBandit(x, y)
  local bandit = MakeEntity({x = x, y = y, pic = "noncommercial/bandit", enemy = true})
  
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
        
        if player.y == bandit.y then
          player:Hit()
        end
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
local monster = MakeBandit(6, 3)

hud:SetPoint("BOTTOMRIGHT", player, "TOPCENTER")

Command.Environment.Insert(_G, "Command.Battle.Display.Card.Resync", function ()
  if hud.carddisplay then
    hud.carddisplay:Obliterate()
  end
  
  hud.carddisplay = Frame.Frame(hud)
  
  local bottom = hud
  for k = #deckActive, 1, -1 do
    local tf = Command.Art.Button.Card(hud.carddisplay, deckActive[k])
    tf:SetPoint("BOTTOMRIGHT", bottom, "BOTTOMRIGHT", -10, -10)
    tf:SetLayer(-k)
    bottom = tf
  end
end)

Command.Environment.Insert(_G, "Command.Battle.Bump", function (x, y)
  for entity, _ in pairs(entities) do
    if entity.x == x and entity.y == y then
      -- yes, bump
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
        if grid[x][y].enemy then
          print("U WIN")
        else
          print("U LOSE")
        end
      else
        local ncor = avail[math.random(#avail)]
        entity:Warp(ncor[1], ncor[2])
      end
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
  return not decking
end)

Event.System.Key.Down:Attach(function (key)
  if decking == "aborting" then decking = false return end  -- eugh
  if decking then return end
  
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
  if not Inspect.Battle.Active() then return end
  
  for entity in pairs(entities) do
    if entity.Think then
      entity.Think()
    end
  end
end)
