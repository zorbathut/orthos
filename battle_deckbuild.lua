-- externally facing events
local created = Command.Event.Create(_G, "Deck.Created")

-- everything else
local greyout = Frames.Frame(Frames.Root)
greyout:SetBackground(0, 0, 0, 0.5)
greyout:SetLayer(-1)
greyout:SetPoint("TOPLEFT", Frames.Root, "TOPLEFT")
greyout:SetPoint("BOTTOMRIGHT", Frames.Root, "BOTTOMRIGHT")

local function MakeBorder(target)
  local cminibg = Frames.Frame(Frames.Root)
  cminibg:SetPoint("TOPLEFT", target, "TOPLEFT", -3, -3)
  cminibg:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 3, 3)
  cminibg:SetLayer(-1)
  
  return cminibg
end

-- keys and key handlers
local selects = {}
local cards = {}
local cardIndicators = {}
for k = 1, 5 do
  local card = Command.Deck.Draw()
  
  local cardmini = Command.Art.Button.Card(Frames.Root, card)
  cardmini:SetPoint("CENTER", Frames.Root, "CENTER", (k - 3) * 60, 200)
      
  local cardbig = Command.Art.Card.Big(Frames.Root, card)
  cardbig:SetPoint("CENTER", Frames.Root, "CENTER")
  cardbig:SetVisible(false)
  
  local menuitem -- we will stash our menu here
  
  local function Choose()
    Command.Deckbuilder.Push(menuitem)
  end
  
  menuitem = {card = card, selectable = cardmini, bg = MakeBorder(cardmini), big = cardbig, Trigger = Choose}
  
  table.insert(selects, menuitem)
end

local backButton = Command.Art.Button.Back(Frames.Root)
backButton:SetPoint("CENTER", Frames.Root, "CENTER", 200, 200)
local function Back()
  Command.Deckbuilder.Pop()
end
table.insert(selects, {selectable = backButton, big = Frames.Frame(Frames.Root), bg = MakeBorder(backButton), Trigger = Back})

local acceptButton = Command.Art.Button.Accept(Frames.Root)
acceptButton:SetPoint("CENTER", Frames.Root, "CENTER", 250, 200)
local function Accept()
  if #cards > 0 then
    -- need to discard unused cards, so we're bruteforcing it again
    local remaining = {}
    for _, v in ipairs(selects) do
      if v.card then
        remaining[v.card] = true
      end
    end
    for _, v in ipairs(cards) do
      remaining[v.card] = nil
    end
    for k in pairs(remaining) do
      Command.Deck.Discard(k)
    end
    
    -- need to assemble real cards
    local realcards = {}
    for _, v in ipairs(cards) do
      table.insert(realcards, v.card)
    end
    created(realcards)
  end
end
table.insert(selects, {selectable = backButton, big = Frames.Frame(Frames.Root), bg = MakeBorder(acceptButton), Trigger = Accept})

local function resyncDisplay()
  for _, v in ipairs(selects) do
    v.selectable:SetDisable(false)
  end
  
  for _, v in ipairs(cards) do
    v.selectable:SetDisable(true)
  end
  
  if not next(cards) then
    backButton:SetDisable(true)
  end
  
  while #cardIndicators > #cards do
    cardIndicators[#cardIndicators]:Obliterate()
    cardIndicators[#cardIndicators] = nil
  end
  
  while #cardIndicators < #cards do
    local card = Command.Art.Button.Card(Frames.Root, cards[#cardIndicators + 1].card)
    
    if #cardIndicators > 0 then
      card:SetPoint("TOPLEFT", cardIndicators[#cardIndicators], "BOTTOMLEFT", 0, 10)
    else
      card:SetPoint("TOPLEFT", Frames.Root, "CENTER", 175, -130)
    end
    
    table.insert(cardIndicators, card)
  end
end
resyncDisplay()

Command.Environment.Insert(_G, "Command.Deckbuilder.Push", function (item)
  local found = false
  for _, v in ipairs(cards) do
    if v == item then found = true end
  end
  
  if found then return end
   
  table.insert(cards, item)
   
  -- show the icon for it
   
  resyncDisplay()
end)

Command.Environment.Insert(_G, "Command.Deckbuilder.Pop", function ()
  table.remove(cards)
   
  -- show the icon for it
   
  resyncDisplay()
end)

-- selection
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
  elseif key == "z" then
    if selects[selected].Trigger then
      selects[selected]:Trigger()
    end
  end
end)
