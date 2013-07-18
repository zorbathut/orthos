
-- params
local width = 0.7
local starpos = (1 - width) / 2

local step = width / 5

local descale = 0.9
local solid_intensity = 1

local idx = 0
local gadgetwidth
for c in ("ORTHOS"):gmatch(".") do
  local char
  if idx == 4 then
    local rwidth = gadgetwidth * descale
    
    char = Frame.Raw(Frame.Root)
    char:SetWidth(gadgetwidth)
    char:SetHeight(gadgetwidth)
    local timera = math.random() * 360
    local timerb = math.random() * 360
    local timerc = math.random() * 360
    local timeraa = math.random() * 1 + .1
    local timerba = math.random() * 1 + .1
    local timerca = math.random() * 1 + .1
    local lasttime = Inspect.System.Time.Real()
    char:EventAttach(Frame.Event.Render, function ()
      gl.Disable("DEPTH_TEST")
      gl.DepthFunc("LEQUAL")
      gl.DepthMask(true)
      gl.BlendFunc("ONE", "ONE")
      gl.MatrixMode("MODELVIEW")
      gl.Translate((char:GetLeft() + char:GetRight()) / 2, (char:GetTop() + char:GetBottom()) / 2, 0)
      gl.Scale(rwidth / 2, rwidth / 2, 0.5)
      gl.Rotate(timera, 1, 0, 0)
      gl.Rotate(timerb, 0, 1, 0)
      gl.Rotate(timerc, 0, 0, 1)
      gl.Rotate(35.264, 1, 0, 0)
      gl.Rotate(45, 0, 1, 0)
      
      timera = timera + (Inspect.System.Time.Real() - lasttime) * timeraa
      timerb = timerb + (Inspect.System.Time.Real() - lasttime) * timerba
      timerc = timerc + (Inspect.System.Time.Real() - lasttime) * timerca
      lasttime = Inspect.System.Time.Real()
      
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
    char = Frame.Text(Frame.Root)
    char:SetText(c)
    char:SetFont("font/FundamentalBrigade.ttf")
    char:SetSize(300)
    
    if idx == 0 then
      gadgetwidth = char:GetWidth()
    end
  end
  
  char:SetPoint("CENTER", Frame.Root, starpos + step * idx, 0.25)
  idx = idx + 1
end

local function MakeRandomBg(restrict)
  local tex = Frame.Texture(Frame.Root)
  tex:SetLayer(-1)
  
  local opts = {"astral", "city", "cyber"}
  local chose
  while not chose do
    chose = opts[math.random(#opts)]
    if chose == restrict then chose = nil end
  end
  local texit = string.format("copyright_infringement/%s%02d.jpg", chose, math.random(3))
  tex:SetTexture(texit)
  
  local cols = {
    astral = {1, 0, 0},
    city = {0, 1, 0},
    cyber = {0, 0, 1}
  }
  tex:SetTint(unpack(cols[chose]))
  
  tex:SetPoint("CENTER", Frame.Root, "CENTER")
  local scal = math.min(Frame.Root:GetHeight() / tex:GetHeight(), Frame.Root:GetWidth() / tex:GetWidth())
  tex:SetHeight(tex:GetHeight() * scal)
  tex:SetWidth(tex:GetWidth() * scal)
  
  return tex, chose
end

local delay = 2
local fade = 3
Event.System.Update.Begin:Attach(
  coroutine.wrap(
    function ()
      local bga, cat = MakeRandomBg("")
      local creation = Inspect.System.Time.Real()
      
      while true do
        while Inspect.System.Time.Real() < creation + delay do
          coroutine.yield()
        end
        
        local nbga, ncat = MakeRandomBg(cat)
        bga:SetLayer(-1)
        nbga:SetAlpha(0)
        
        while Inspect.System.Time.Real() < creation + delay + fade do
          local shift = (Inspect.System.Time.Real() - creation - delay) / fade
          bga:SetAlpha(1 - shift)
          nbga:SetAlpha(shift)
          coroutine.yield()
        end
        
        bga:Obliterate()
        
        bga, cat = nbga, ncat
        creation = creation + delay + fade
        bga:SetAlpha(1)
      end
    end
  )
)

local starttext = Frame.Text(Frame.Root)
starttext:SetSize(60)
starttext:SetPoint("CENTER", Frame.Root, "CENTER", 0, 250)
starttext:SetText("( START )")

local descr = Frame.Text(Frame.Root)
descr:SetSize(40)
descr:SetText("Arrows to move - Z to continue, choose, or fire")
descr:SetPoint("CENTER", Frame.Root, "CENTER", 0, 400)

local descr2 = Frame.Text(Frame.Root)
descr2:SetSize(20)
descr2:SetText("This is a bare-bones combat prototype. Visit www.mandible.net or www.twitch.tv/zorbathut for more information.")
descr2:SetPoint("BOTTOMCENTER", Frame.Root, "BOTTOMCENTER", 0, -10)

local init = Command.Event.Create(_G, "Init.Start")

Event.System.Key.Down:Attach(function (key)
  if key == "z" or key == "Return" or key == "Space" then
    print("go")
    init()
  end
end)
