local created = Command.Event.Create(_G, "Deck.Created")

local overlay = Frames.Text(Frames.Root)
overlay:SetText("DECKBUILD")
overlay:SetPoint("CENTER", Frames.Root, "CENTER")

Event.System.Key.Down:Attach(function (key)
  if key == "z" then
    created({})
  end
end)
