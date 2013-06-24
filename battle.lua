
local deckDiscard = {}
for k = 1, 40 do
  table.insert(deckDiscard, {name = "Card" .. k, type = "Steel"})
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
  deckbuild.Frame.Root:SetLayer(100)
  
  deckbuild.Event.Deck.Created:Attach(function (deck)
    dump("Deck chosen:", deck)
    deckActive = deck
    
    Command.Environment.Destroy(deckbuild)
    deckbuild = nil -- let cleanup happen
    
    -- one-frame delay because otherwise we try to autofire
    -- todo: rig up better event control
    Command.Coro.Play(function ()
      coroutine.yield()
      decking = false
    end)
  end)
end
deckChoose()

local gridsize = 200
local border = 5
local outline = 5

local grid = Frame.Frame(Frame.Root)
grid:SetPoint("TOPLEFT", Frame.Root, "CENTER", -gridsize * 3, -gridsize * 1.5)
grid:SetPoint("BOTTOMRIGHT", Frame.Root, "CENTER", gridsize * 3, gridsize * 1.5)

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
    if enemy then
      inlay:SetBackground(0.5, 0.2, 0.2)
    else
      inlay:SetBackground(0.2, 0.2, 0.5)
    end
    
    local demph = Frame.Frame(inlay)
    demph:SetPoint("TOPLEFT", inlay, "TOPLEFT", border, border)
    demph:SetPoint("BOTTOMRIGHT", inlay, "BOTTOMRIGHT", -border, -border)
    demph:SetBackground(0.1, 0.1, 0.1)
  end
end

local entityLayer = Frame.Frame(Frame.Root)
entityLayer:SetLayer(1)

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
    return grid[x] and grid[x][y] and (not grid[x][y].enemy) == (not enemy)
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
  
  fram:Warp(x, y)
  
  entities[fram] = true
  
  return fram
end

function MakePlayer(x, y)
  local player = MakeEntity({x = x, y = y, pic = "noncommercial/hero"})
  
  function player:FirePrimary()
    if #deckActive > 0 then
      print("kazam! item:")
      dump(deckActive[1])
      table.remove(deckActive, 1)
    else
      deckChoose()
    end
  end

  -- currently not even using this
  function player:FireSecondary()
    Command.Coro.Play(function ()
      local blast = Frame.Texture(player)
      blast:SetTexture("placeholder/blaster.png")
      blast:SetPoint(0, 0.5, img, "CENTER")
      blast:SetLayer(-1)  -- behind the player
      
      Command.Coro.Wait(0.06)
      
      blast:Obliterate()
    end)
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
          print("DAMAGE")
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

Event.System.Key.Down:Attach(function (key)
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
  if decking then return end
  
  for entity in pairs(entities) do
    if entity.Think then
      entity.Think()
    end
  end
end)