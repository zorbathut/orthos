
do
  local bg = Frame.Texture(Frame.Root)
  bg:SetLayer(-10)
  bg:SetTexture("noncommercial/construction")
  bg:SetPoint("TOPLEFT", Frame.Root, "TOPLEFT")
  bg:SetPoint("BOTTOMRIGHT", Frame.Root, "BOTTOMRIGHT")
end

local canned = {
  {name = "Bandit Solo", {type = "Bandit", x = 6, y = 1}},
  {name = "Bandit Pack", {type = "Bandit", x = 6, y = 3}, {type = "Bandit", x = 5, y = 1}},
  {name = "Flame Boss", {type = "BossFlame", x = 5, y = 2}},
  {name = "Slam Boss", {type = "BossSlam", x = 5, y = 2}},
  {name = "Rocket Boss", {type = "BossRocket", x = 5, y = 2}},
  {name = "Ultimate Boss", {type = "BossMulti", x = 5, y = 2}},
}

local options = Frame.Frame(Frame.Root)
options:SetPoint("BOTTOMLEFT", Frame.Root, "TOPLEFT", 70, 30)

local optanchor = options
for k, v in ipairs(canned) do
  local ft = Frame.Text(options)
  ft:SetText(v.name)
  ft:SetSize(50)
  ft:SetPoint("TOPLEFT", optanchor, "BOTTOMLEFT", 0, 10)
  optanchor = ft
  
  v.ui = ft
end

do
  local ft = Frame.Text(options)
  ft:SetText("Build your Own")
  ft:SetSize(50)
  ft:SetPoint("TOPLEFT", optanchor, "BOTTOMLEFT", 0, 60)
  optanchor = ft
  
  table.insert(canned, {ui = ft, buildyourown = true})
end

local optid = 1
local pointer = Frame.Text(options)
pointer:SetText(">")
pointer:SetSize(50)
local function ResyncPointer()
  pointer:SetPoint("CENTERRIGHT", canned[optid].ui, "CENTERLEFT", -10, 0)
end
ResyncPointer()

local battle

local function AbortBattle()
  Command.Environment.Destroy(battle)
  options:SetVisible(true)
  battle = nil
end

Event.System.Key.Down:Attach(function (key)
  if battle then return end
  if key == "Up" then
    optid = optid - 1
    if optid < 1 then optid = 1 end
    ResyncPointer()
  elseif key == "Down" then
    optid = optid + 1
    if optid > #canned then optid = #canned end
    ResyncPointer()
  elseif key == "z" or key == "Return" or key == "Space" then
    if not canned[optid].buildyourown then
      battle = Command.Environment.Create(_G, "Battleloop", "battleloop.lua", nil, canned[optid])
      battle.Frame.Root:SetLayer(2)
      battle.Event.Battleloop.Abort:Attach(AbortBattle)
      battle.Event.Battleloop.Fail:Attach(Command.Init.Return)
      options:SetVisible(false)
    else
      battle = Command.Environment.Create(_G, "Fightclub forge", "fightclub_forge.lua")
      battle.Frame.Root:SetLayer(2)
      options:SetVisible(false)
    end
  end
end)

local descr = Frame.Text(Frame.Root)
descr:SetSize(40)
descr:SetText("Arrows to move - Z to continue, choose, or fire")
descr:SetPoint("CENTER", Frame.Root, "CENTER", 0, 400)
