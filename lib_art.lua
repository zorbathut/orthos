
local cardart = {
  Spike = "placeholder/card/spike",
  Shatter = "placeholder/card/shatter",
  Pierce = "placeholder/card/pierce",
  Blast = "placeholder/card/blast",
  Pull = "placeholder/card/pull",
  Repel = "placeholder/card/repel",
  Dash = "placeholder/card/dash",
}

Command.Environment.Insert(_G, "Command.Library.Art.Button.Card", function (root, card)
  local cardmini = Frame.Frame(root)
  local cardminitext
  local cardminitex
  
  if not cardart[card.name] then
    cardminitext = Frame.Text(cardmini)
    cardminitext:SetText(card.name)
    cardminitext:SetPoint("CENTER", cardmini, "CENTER")
    cardminitext:SetSize(12)
  else
    cardminitex = Frame.Texture(cardmini)
    cardminitex:SetTexture(cardart[card.name])
    cardminitex:SetPoint("TOPLEFT", cardmini, "TOPLEFT")
    cardminitex:SetPoint("BOTTOMRIGHT", cardmini, "BOTTOMRIGHT")
  end
  
  cardmini:SetWidth(40)
  cardmini:SetHeight(40)
  
  local dis = false
  function cardmini:SetDisable(disable)
    dis = disable
    
    if disable then
      cardmini:SetBackground(0, 0, 0.05)
      if cardminitext then cardminitext:SetColor(0.3, 0.3, 0.3) end
      if cardminitex then cardminitex:SetTint(0.3, 0.3, 0.3) end
    else
      cardmini:SetBackground(0, 0, 0.2)
      if cardminitext then cardminitext:SetColor(1.0, 1.0, 1.0) end
      if cardminitex then cardminitex:SetTint(1.0, 1.0, 1.0) end
    end
  end
  function cardmini:GetDisable()
    return dis
  end
  
  cardmini:SetDisable(false)
  
  return cardmini
end)

Command.Environment.Insert(_G, "Command.Library.Art.Button.Rechoose", function (root)
  local cardmini = Frame.Frame(root)
  local cardminitext = Frame.Text(cardmini)
  cardminitext:SetText("Rechoose")
  cardminitext:SetPoint("CENTER", cardmini, "CENTER")
  cardminitext:SetSize(12)
  cardmini:SetWidth(40)
  cardmini:SetHeight(40)
  
  local coold = Frame.Text(cardmini)
  coold:SetPoint("TOPCENTER", cardminitext, "BOTTOMCENTER", 0, 5)
  coold:SetSize(10)
  
  local dis = false
  function cardmini:SetDisable(disable)
    dis = disable
    
    if disable then
      cardmini:SetBackground(0, 0.05, 0)
      cardminitext:SetColor(0.3, 0.3, 0.3)
    else
      cardmini:SetBackground(0, 0.2, 0)
      cardminitext:SetColor(1.0, 1.0, 1.0)
    end
  end
  function cardmini:GetDisable()
    return dis
  end
  
  function cardmini:SetCooldown(val)
    if val < 1 then
      coold:SetVisible(true)
      coold:SetText(string.format("%.2f", val))
      self:SetDisable(true)
    else
      coold:SetVisible(false)
      self:SetDisable(false)
    end
  end
  
  cardmini:SetDisable(false)
  
  return cardmini
end)
  
Command.Environment.Insert(_G, "Command.Library.Art.Card.Big", function (root, card)
  local cardbig = Frame.Frame(root)
  cardbig:SetBackground(0, 0, 0.2)
  local cardbigtext = Frame.Text(cardbig)
  cardbigtext:SetText(card.name)
  cardbigtext:SetSize(30)
  cardbigtext:SetLayer(1)
  cardbig:SetWidth(200)
  cardbig:SetHeight(200)
  
  local cardbigtex
  if cardart[card.name] then
    cardbigtex = Frame.Texture(cardbig)
    cardbigtex:SetPoint("TOPLEFT", cardbig, "TOPLEFT")
    cardbigtex:SetPoint("BOTTOMRIGHT", cardbig, "BOTTOMRIGHT")
    cardbigtex:SetTexture(cardart[card.name])
    cardbigtext:SetPoint("CENTER", cardbig, 0.5, 0.9)
  else
    cardbigtext:SetPoint("CENTER", cardbig, "CENTER")
  end
  
  return cardbig
end)

Command.Environment.Insert(_G, "Command.Library.Art.Button.Accept", function (root)
  local cardmini = Frame.Frame(root)
  cardmini:SetBackground(0.2, 0, 0)
  local cardminitext = Frame.Text(cardmini)
  cardminitext:SetText("ACCEPT")
  cardminitext:SetPoint("CENTER", cardmini, "CENTER")
  cardminitext:SetSize(12)
  cardmini:SetWidth(40)
  cardmini:SetHeight(40)
  
  local dis = false
  function cardmini:SetDisable(disable)
    dis = disable
    
    if disable then
      cardmini:SetBackground(0.05, 0, 0)
      cardminitext:SetColor(0.3, 0.3, 0.3)
    else
      cardmini:SetBackground(0.2, 0, 0)
      cardminitext:SetColor(1.0, 1.0, 1.0)
    end
  end
  function cardmini:GetDisable()
    return dis
  end
  
  cardmini:SetDisable(false)
  
  return cardmini
end)

Command.Environment.Insert(_G, "Command.Library.Art.Button.Back", function (root)
  local cardmini = Frame.Frame(root)
  cardmini:SetBackground(0.2, 0, 0)
  local cardminitext = Frame.Text(cardmini)
  cardminitext:SetText("BACK")
  cardminitext:SetPoint("CENTER", cardmini, "CENTER")
  cardminitext:SetSize(12)
  cardmini:SetWidth(40)
  cardmini:SetHeight(40)
  
  local dis = false
  function cardmini:SetDisable(disable)
    dis = disable
    
    if disable then
      cardmini:SetBackground(0.05, 0, 0)
      cardminitext:SetColor(0.3, 0.3, 0.3)
    else
      cardmini:SetBackground(0.2, 0, 0)
      cardminitext:SetColor(1.0, 1.0, 1.0)
    end
  end
  function cardmini:GetDisable()
    return dis
  end
  
  cardmini:SetDisable(false)
  
  return cardmini
end)
