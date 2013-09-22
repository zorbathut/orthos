
local params = ...

assert(params)
assert(params.gridsize)
assert(params.worldsize)

local gridsize = params.gridsize
local worldsize = params.worldsize
local border = 5
local outline = 5

local parent = params.parent or Frame.Root

local grid = Frame.Frame(parent)
grid:SetPoint("TOPLEFT", parent, "CENTER", -gridsize * worldsize, -gridsize * worldsize / 2)
grid:SetPoint("BOTTOMRIGHT", parent, "CENTER", gridsize * worldsize, gridsize * worldsize / 2)
grid:SetLayer(layer and layer.grid or -1) -- grid defaults to being "behind"

for row = 1, worldsize * 2 do
  grid[row] = {}
  
  local enemy = false
  if row > worldsize then enemy = true end
  
  for col = 1, worldsize do
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
      
      brick:SetVisible(alive)
      
      if enemy then
        inlay:SetBackground(0.5, 0.2, 0.2)
      else
        inlay:SetBackground(0.2, 0.2, 0.5)
      end
      
      demph:SetBackground(0.1, 0.1, 0.1)
    end
    function brick:AliveGet()
      return alive
    end
    brick:AliveSet(true)
  end
end

Command.Environment.Insert(_G, "Inspect.Battle.Grid.Table", function ()
  return grid
end)

Command.Environment.Insert(_G, "Inspect.Battle.Grid.Hitscan", function (sx, sy, direction, missEnemy, missFriendly)
  assert(direction ~= 0)
  if direction == 0 then return {} end
  
  local found = {}
  
  sx = sx + direction * 0.1 -- close enough
  
  for entity in pairs(Inspect.Battle.Entities()) do
    if entity:PositionYGetGrid() == sy and not (entity:FactionGet() == "enemy" and missEnemy) and not (entity:FactionGet() == "friendly" and missFriendly) and (entity:PositionXGetGrid() - sx) * direction > 0 then
      table.insert(found, {ent = entity, dist = math.abs(sx - entity:PositionXGetGrid())})
    end
  end
  
  table.sort(found, function (a, b) return a.dist < b.dist end)
  
  local rv = {}
  for _, v in ipairs(found) do
    table.insert(rv, v.ent)
  end
  return rv
end)

Command.Environment.Insert(_G, "Command.Battle.Grid.Position", function (self, x, y)
  self:SetWidth(gridsize)
  self:SetHeight(gridsize)
  self:SetPoint("TOPLEFT", grid, "TOPLEFT", (x - 1) * gridsize, (y - 1) * gridsize)
end)
