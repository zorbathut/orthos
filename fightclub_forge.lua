
do
  local bg = Frame.Texture(Frame.Root)
  bg:SetLayer(-10)
  bg:SetTexture("noncommercial/forge")
  bg:SetPoint("TOPLEFT", Frame.Root, "TOPLEFT")
  bg:SetPoint("BOTTOMRIGHT", Frame.Root, "BOTTOMRIGHT")
end

local grid = Frame.Frame(Frame.Root)

local gridsize = 180

assert(loadfile("battle_grid.lua"))({gridsize = gridsize, parent = grid})
assert(loadfile("entitydb.lua"))()

grid:SetWidth(gridsize * 6)
grid:SetHeight(gridsize * 3)
grid:SetPoint("CENTER", Frame.Root, "CENTER", 0, 200)

local items = 2 -- nothing, start

for k, v in pairs(Inspect.Entity.Icons()) do
  items = items + 1
end

local iconsize = math.min(200, 1920 / items)
local iconsizeimage = iconsize * .9

local chooser = Frame.Frame(Frame.Root)
chooser:SetPoint("TOPRIGHT", Frame.Root, "TOPCENTER", -iconsize * items / 2, 100)
chooser:SetWidth(iconsize)
chooser:SetHeight(iconsize)

local choices = {}

local createid = 1
local function InsertIcon(descriptor, icon, tab)
  if icon.SetText then
    icon:SetSize(iconsizeimage / 3)
  else
    local aspect = icon:GetWidth() / icon:GetHeight()
    if aspect > 1 then
      icon:SetWidth(iconsizeimage)
      icon:SetHeight(iconsizeimage / aspect)
    else
      icon:SetWidth(iconsizeimage * aspect)
      icon:SetHeight(iconsizeimage)
    end
  end
  
  icon:SetPoint("CENTER", chooser, "CENTER", iconsize * createid, 0)
  createid = createid + 1
  
  local dat = {icon = icon, descriptor = descriptor}
  if tab then
    for k, v in pairs(tab) do
      dat[k] = v
    end
  end
  table.insert(choices, dat)
end

do
  local empty = Frame.Text(chooser)
  empty:SetText("Empty")
  InsertIcon("Remove from grid", empty)
end

for k, v in pairs(Inspect.Entity.Icons()) do
  local tex = Frame.Texture(chooser)
  tex:SetTexture(v[1])
  InsertIcon(v[2], tex, {item = k})
end

do
  local empty = Frame.Text(chooser)
  empty:SetText("Play")
  InsertIcon("Try your level", empty)
end

local descrtext = Frame.Text(Frame.Root)
descrtext:SetSize(40)
descrtext:SetPoint("BOTTOMCENTER", grid, "TOPCENTER", 0, -80)

local optid = 2
local pointer = Frame.Frame(chooser)
pointer:SetWidth(iconsize)
pointer:SetHeight(iconsize)
pointer:SetBackground(1, 1, 1, 0.4)
pointer:SetLayer(-1)
local function ResyncPointer()
  pointer:SetPoint("CENTER", choices[optid].icon, "CENTER", 0, 0)
  descrtext:SetText(choices[optid].descriptor)
end
ResyncPointer()

local choosemode = "type"
local choice = nil
local battle = nil

local px = 5
local py = 2

local gridcreate = {}
for x = 1, 6 do
  table.insert(gridcreate, {})
end

local cursor = Frame.Texture(grid)
cursor:SetTexture("placeholder/reticle.png")
local function RefreshCursor()
  Command.Battle.Grid.Position(cursor, px, py)
  cursor:SetVisible(choosemode == "place")
end
RefreshCursor()

local griditems = nil
local function RefreshGrid()
  if griditems then griditems:Obliterate() end
  griditems = Frame.Frame(grid)
  for x, v in pairs(gridcreate) do
    for y, ite in pairs(v) do
      local ix = Frame.Texture(griditems)
      ix:SetTexture(Inspect.Entity.Icons()[ite][1])
      Command.Battle.Grid.Position(ix, x, y)
    end
  end
end

Event.System.Key.Down:Attach(function (key)
  if choosemode == "type" then
    if key == "Left" then
      optid = optid - 1
      if optid < 1 then optid = 1 end
      ResyncPointer()
    elseif key == "Right" then
      optid = optid + 1
      if optid > #choices then optid = #choices end
      ResyncPointer()
    elseif key == "z" or key == "Return" or key == "Space" then
      if optid == #choices then
        local gamepackage = {}
        for x, v in pairs(gridcreate) do
          for y, ite in pairs(v) do
            table.insert(gamepackage, {x = x, y = y, type = ite})
          end
        end
        battle = Command.Environment.Create(_G, "Battleloop", "battleloop.lua", nil, gamepackage)
        battle.Event.Battleloop.Abort:Attach(TestEnd)
        battle.Event.Battleloop.Fail:Attach(TestEnd)
        battle.Frame.Root:SetLayer(2)
        choosemode = "play"
      else
        choosemode = "place"
        choice = choices[optid].item
        px = 5
        py = 2
        RefreshCursor()
      end
    end
  elseif choosemode == "place" then
    if key == "Left" then
      px = math.max(4, px - 1)
    elseif key == "Right" then
      px = math.min(6, px + 1)
    elseif key == "Up" then
      py = math.max(1, py - 1)
    elseif key == "Down" then
      py = math.min(3, py + 1)
    elseif key == "z" or key == "Return" or key == "Space" then
      gridcreate[px][py] = choice
      choosemode = "type"
      RefreshGrid()
    end
    RefreshCursor()
  elseif choosemode == "play" then
    -- don't do anything >:(
  end
end)

function TestEnd()
  Command.Environment.Destroy(battle)
  battle = nil
  choosemode = "type"
end

local descr = Frame.Text(Frame.Root)
descr:SetSize(40)
descr:SetText("Arrows to select - Z to choose an enemy")
descr:SetPoint("CENTER", Frame.Root, "CENTERBOTTOM", 0, -30)
