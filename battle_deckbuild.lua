
local created = Command.Event.Create(_G, "Deck.Created")

local function MakeBorder(target)
  local cminibg = Frames.Frame(Frames.Root)
  cminibg:SetPoint("TOPLEFT", target, "TOPLEFT", -3, -3)
  cminibg:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 3, 3)
  cminibg:SetLayer(-1)
  
  return cminibg
end

local selects = {}
local cards = {}
for k = 1, 5 do
  local card = Command.Deck.Draw()
  
  local cardmini = Command.Art.Button.Card(Frames.Root, card)
  cardmini:SetPoint("CENTER", Frames.Root, "CENTER", (k - 3) * 60, 200)
      
  local cardbig = Command.Art.Card.Big(Frames.Root, card)
  cardbig:SetPoint("CENTER", Frames.Root, "CENTER")
  cardbig:SetVisible(false)
  
  table.insert(selects, {card = card, mini = cardmini, bg = MakeBorder(cardmini), big = cardbig})
end

do
  local accept = Command.Art.Button.Accept(Frames.Root)
  accept:SetPoint("CENTER", Frames.Root, "CENTER", 200, 200)
  table.insert(selects, {big = Frames.Frame(Frames.Root), bg = MakeBorder(accept)})
end

local selected = nil

Command.Environment.Insert(_G, "Command.Deckbuilder.Select", function (item)
  if selected then
    selects[selected].bg:SetBackground(0, 0, 0, 0)
    selects[selected].big:SetVisible(false)
  end
  
  if item then
    selects[item].bg:SetBackground(1, 1, 1, 1)
    selects[item].big:SetVisible(true)
  end
  
  selected = item
end)
Command.Deckbuilder.Select(1)

Event.System.Key.Down:Attach(function (key)
  if key == "Right" then
    Command.Deckbuilder.Select(math.min(selected + 1, #selects))
  elseif key == "Left" then
    Command.Deckbuilder.Select(math.max(selected - 1, 1))
  end
end)
