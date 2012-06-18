do
  -- params
  local width = 0.7
  local starpos = (1 - width) / 2
  
  local step = width / 5
  
  local idx = 0
  local gadgetwidth
  for c in ("ORTHOS"):gmatch(".") do
      local char = Frames.Text(Frames.Root)
      char:SetText(c)
      char:SetFont("font/FundamentalBrigade.ttf")
      char:SetSize(300)
      char:SetPoint("CENTER", Frames.Root, starpos + step * idx, 0.25)
      
      if idx == 0 then
        gadgetwidth = char:GetWidth()
      end
      idx = idx + 1
  end
  print(gadgetwidth)
end
