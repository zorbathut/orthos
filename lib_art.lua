Command.Environment.Insert(_G, "Command.Library.Art.Button.Card", function (root, card)
  local cardmini = Frame.Frame(root)
  local cardminitext = Frame.Text(cardmini)
  cardminitext:SetText(card.name)
  cardminitext:SetPoint("CENTER", cardmini, "CENTER")
  cardminitext:SetSize(12)
  cardmini:SetWidth(40)
  cardmini:SetHeight(40)
  
  local dis = false
  function cardmini:SetDisable(disable)
    dis = disable
    
    if disable then
      cardmini:SetBackground(0, 0, 0.05)
      cardminitext:SetColor(0.3, 0.3, 0.3)
    else
      cardmini:SetBackground(0, 0, 0.2)
      cardminitext:SetColor(1.0, 1.0, 1.0)
    end
  end
  function cardmini:GetDisable()
    return dis
  end
  
  cardmini:SetDisable(false)
  
  return cardmini
end)
  
Command.Environment.Insert(_G, "Command.Library.Art.Card.Big", function (root, card)
  local cardbig = Frame.Frame(root)
  cardbig:SetBackground(0, 0, 0.2)
  local cardbigtext = Frame.Text(cardbig)
  cardbigtext:SetText(card.name)
  cardbigtext:SetPoint("CENTER", cardbig, "CENTER")
  cardbigtext:SetSize(30)
  cardbig:SetWidth(200)
  cardbig:SetHeight(200)
  
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
