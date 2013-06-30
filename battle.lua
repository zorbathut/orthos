
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

assert(loadfile("battle_grid.lua"))()
assert(loadfile("battle_ability.lua"))()
assert(loadfile("battle_entity.lua"))()

local deckDiscard = {}
do
  local types = {"Spike", "Spike", "Shatter", "Shatter", "Blast", "Blast", "Pierce", "Pierce", "Dash", "Pull", "Repel", "Fortify", "Wall"}
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

local player = nil -- filled with actual player
  
player = Command.Battle.Spawn("Player", 1, 2)

--Command.Battle.Spawn("Bandit", 6, 3)
--Command.Battle.Spawn("Bandit", 5, 1)
--Command.Battle.Spawn("BossFlame", 5, 2)
--Command.Battle.Spawn("BossSlam", 5, 2)
--Command.Battle.Spawn("BossRocket", 5, 2)
Command.Battle.Spawn("BossMulti", 5, 2)

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
  local grid = Inspect.Battle.Grid.Table()
  
  if grid[x][y].entity then
    local entity = grid[x][y].entity

    
    local dx = {0, 0, 1, -1}
    local dy = {1, -1, 0, 0}
    local avail = {}
    
    --[[  -- TWEAK: Bumping is 100% random, not trying the cardinal directions first
    for id in ipairs(dx) do
      if entity:AnchorWarpValid(x + dx[id], y + dy[id]) then
        table.insert(avail, {x + dx[id], y + dy[id]})
      end
    end]]
    
    if #avail == 0 then
      for nx in ipairs(grid) do
        for ny in ipairs(grid[nx]) do
          if entity:AnchorWarpValid(nx, ny) then
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
      entity:AnchorWarp(ncor[1], ncor[2])
      if entity.Bump then entity:Bump() end
    end
  end
end)

Command.Environment.Insert(_G, "Command.Battle.Damage", function (enemy)
  local grid = Inspect.Battle.Grid.Table()
  
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

Command.Environment.Insert(_G, "Inspect.Battle.Active", function ()
  return state == "playing"
end)

Event.Battle.Lost:Attach(function ()
  state = "loss"
  
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
end)

Event.Battle.Won:Attach(function ()
  state = "won"
  
  -- yay
  local ded = Frame.Frame(Frame.Root)
  ded:SetLayer(layer.ded)
  ded:SetPoint("TOPLEFT", Frame.Root, "TOPLEFT")
  ded:SetPoint("BOTTOMRIGHT", Frame.Root, "BOTTOMRIGHT")
  ded:SetBackground(0, 0, 0.2, 0.7)
  
  local dedtext = Frame.Text(ded)
  dedtext:SetText("U WON")
  dedtext:SetPoint("CENTER", ded, "CENTER")
  dedtext:SetSize(40)
end)

Event.System.Key.Down:Attach(function (key)
  if state ~= "playing" then return end
  
  if key == "Up" then
    if player:AnchorWarpValid(player:AnchorXGet(), player:AnchorYGet() - 1) then
      player:AnchorWarp(player:AnchorXGet(), player:AnchorYGet() - 1)
    end
  elseif key == "Down" then
    if player:AnchorWarpValid(player:AnchorXGet(), player:AnchorYGet() + 1) then
      player:AnchorWarp(player:AnchorXGet(), player:AnchorYGet() + 1)
    end
  elseif key == "Left" then
    if player:AnchorWarpValid(player:AnchorXGet() - 1, player:AnchorYGet()) then
      player:AnchorWarp(player:AnchorXGet() - 1, player:AnchorYGet())
    end
  elseif key == "Right" then
    if player:AnchorWarpValid(player:AnchorXGet() + 1, player:AnchorYGet()) then
      player:AnchorWarp(player:AnchorXGet() + 1, player:AnchorYGet())
    end
  elseif key == "z" then
    if #deckActive > 0 then
      dump(deckActive[1])
      Command.Battle.Cast(deckActive[1].name, player)
      table.remove(deckActive, 1)
      
      Command.Battle.Display.Card.Resync()
    else
      deckChoose()
    end
  end
end)

Event.System.Tick:Attach(function ()
  if state == "deck_aborting" then state = "playing" return end  -- eugh
  if not Inspect.Battle.Active() then return end
end)
