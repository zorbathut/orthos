do
  -- params
  local width = 0.7
  local starpos = (1 - width) / 2
  
  local step = width / 5
  
  local descale = 0.9
  local solid_intensity = 1
  
  local timer = math.random() * 360
  local idx = 0
  local gadgetwidth
  for c in ("ORTHOS"):gmatch(".") do
    local char
    if idx == 4 then
      local rwidth = gadgetwidth * descale
      
      char = Frames.Raw(Frames.Root)
      char:SetWidth(gadgetwidth)
      char:SetHeight(gadgetwidth)
      char:EventRenderAttach(function ()
        gl.Disable("DEPTH_TEST")
        gl.DepthFunc("LEQUAL")
        gl.DepthMask(true)
        gl.BlendFunc("ONE", "ONE")
        gl.MatrixMode("MODELVIEW")
        gl.Translate((char:GetLeft() + char:GetRight()) / 2, (char:GetTop() + char:GetBottom()) / 2, 0)
        gl.Scale(rwidth / 2, rwidth / 2, 0.5)
        gl.Rotate(math.sin(timer) * 10, 1, 0, 0)
        gl.Rotate(timer * 4, 0, 0, 1)
        gl.Rotate(35.264, 1, 0, 0)
        gl.Rotate(45, 0, 1, 0)
        
        timer = timer + 0.005
        
        gl.Begin("QUADS")
        gl.Color(solid_intensity, 0, 0)
        gl.Vertex(-1, -1, 0)
        gl.Vertex(-1, 1, 0)
        gl.Vertex(1, 1, 0)
        gl.Vertex(1, -1, 0)
        gl.Color(0, solid_intensity, 0)
        gl.Vertex(-1, 0, -1)
        gl.Vertex(-1, 0, 1)
        gl.Vertex(1, 0, 1)
        gl.Vertex(1, 0, -1)
        gl.Color(0, 0, solid_intensity)
        gl.Vertex(0, -1, -1)
        gl.Vertex(0, -1, 1)
        gl.Vertex(0, 1, 1)
        gl.Vertex(0, 1, -1)
        gl.End()
      end)
    else
      char = Frames.Text(Frames.Root)
      char:SetText(c)
      char:SetFont("font/FundamentalBrigade.ttf")
      char:SetSize(300)
      
      if idx == 0 then
        gadgetwidth = char:GetWidth()
      end
    end
    
    char:SetPoint("CENTER", Frames.Root, starpos + step * idx, 0.25)
    idx = idx + 1
  end
  
  local bg = Frames.Texture(Frames.Root)
  bg:SetLayer(-1)
  bg:SetTexture("copyright_infringement/astral01.jpg")
  bg:SetPoint("CENTER", Frames.Root, "CENTER")
  bg:SetTint(0, 1, 0)
  
end


