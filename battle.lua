
local gridsize = 200
local border = 5
local outline = 5

local grid = Frames.Frame(Frames.Root)
grid:SetPoint("TOPLEFT", Frames.Root, "CENTER", -gridsize * 3, -gridsize * 1.5)
grid:SetPoint("BOTTOMRIGHT", Frames.Root, "CENTER", gridsize * 3, gridsize * 1.5)

for row = 1, 6 do
  grid[row] = {}
  
  local enemy = false
  if row >= 4 then enemy = true end
  
  for col = 1, 3 do
    local brick = Frames.Frame(grid)
    brick.enemy = enemy
    grid[row][col] = brick
    
    brick:SetPoint("TOPLEFT", grid, "TOPLEFT", row * gridsize - gridsize, col * gridsize - gridsize)
    brick:SetWidth(gridsize)
    brick:SetHeight(gridsize)
    
    local inlay = Frames.Frame(brick)
    inlay:SetPoint("TOPLEFT", brick, "TOPLEFT", border, border)
    inlay:SetPoint("BOTTOMRIGHT", brick, "BOTTOMRIGHT", -border, -border)
    if enemy then
      inlay:SetBackground(0.5, 0.2, 0.2)
    else
      inlay:SetBackground(0.2, 0.2, 0.5)
    end
    
    local demph = Frames.Frame(inlay)
    demph:SetPoint("TOPLEFT", inlay, "TOPLEFT", border, border)
    demph:SetPoint("BOTTOMRIGHT", inlay, "BOTTOMRIGHT", -border, -border)
    demph:SetBackground(0.1, 0.1, 0.1)
  end
end

local entities = Frames.Frame(Frames.Root)
entities:SetLayer(1)

local function MakeEntity(x, y)
  local fram = Frames.Frame(entities)
  local img = Frames.Texture(fram)
  img:SetPoint("CENTER", fram, "CENTER")
  img:SetTexture("copyright_infringement/hero_kid")
  
  function fram:CanTravel(x, y)
    return grid[x] and grid[x][y] and not grid[x][y].enemy
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
  
  return fram
end

local player = MakeEntity(1, 2)

Event.System.Key.Down:Attach(function (key)
  if key == "Up" then
    player:ShiftTry(0, -1)
  elseif key == "Down" then
    player:ShiftTry(0, 1)
  elseif key == "Left" then
    player:ShiftTry(-1, 0)
  elseif key == "Right" then
    player:ShiftTry(1, 0)
  end
end)
