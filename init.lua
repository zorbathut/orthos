-- basics test
local winframe = Frames.Frame(Frames.Root)

winframe:SetPoint("TOPLEFT", Frames.Root, "TOPLEFT", 40, 40)
winframe:SetWidth(300);
winframe:SetHeight(600);

winframe:SetBackground(0.3, 0.3, 0.3);

local title = Frames.Frame(winframe)

title:SetPoint("TOPLEFT", winframe, "TOPLEFT", 10, 10)
title:SetPoint("RIGHT", winframe, "RIGHT", -10, nil)
title:SetHeight(20)

title:SetBackground(1, 1, 0, 0.5)

local ok = Frames.Frame(winframe)

ok:SetPoint("BOTTOMRIGHT", winframe, "BOTTOMRIGHT", -10, -10)
ok:SetHeight(20)
ok:SetWidth(80)

ok:SetBackground(0, 1, 0, 0.5)

-- circular dependency test
local aframe = Frames.Frame(Frames.Root)
local bframe = Frames.Frame(Frames.Root)
local cframe = Frames.Frame(Frames.Root)

aframe:SetPoint("LEFT", bframe, "LEFT")
bframe:SetPoint("LEFT", cframe, "LEFT")
cframe:SetPoint("LEFT", aframe, "LEFT")

-- event test, tbi
-- aframe->EventMoveAttach(PrintWoopWoop);

-- obliterate test, tbi
local gcframe = Frames.Frame(Frames.Root)
gcframe:Obliterate()

-- mask/texture test
local mask = Frames.Mask(Frames.Root)
mask:SetPoint("TOPLEFT", Frames.Root, "CENTER")
mask:SetPoint("BOTTOMRIGHT", Frames.Root, "BOTTOMRIGHT")

local tex = Frames.Texture(mask)
tex:SetPoint("CENTER", Frames.Root, "CENTER")
tex:SetBackground(1, 1, 1, 0.1)
tex:SetTexture("awesome_med.png")

local tex2 = Frames.Texture(mask)
tex2:SetPoint("CENTER", Frames.Root, 0.8, 0.8)
tex2:SetBackground(1, 1, 1, 0.1)
tex2:SetTexture("mind-in-pictures-january-12_1_thumb.jpg")

-- text test
local texu = Frames.Text(Frames.Root)
texu:SetPoint("TOPLEFT", Frames.Root, "TOPLEFT", 60, 120)
texu:SetBackground(1, 0, 0, 0.1)
texu:SetText("AVAVAVAVAVAVAVAV")
texu:SetSize(30)
texu:SetLayer(3)

local texix = Frames.Text(Frames.Root)
texix:SetPoint("TOPLEFT", Frames.Root, "TOPLEFT", 400, 80)
texix:SetBackground(0, 1, 0, 0.1)
texix:SetText("lend me your arms,\nfast as thunderbolts,\nfor a pillow on my journey.")
texix:SetSize(50)
texix:SetLayer(3)

texix:SetWidth(texix:GetWidth() - 50);
texix:SetHeight(texix:GetHeight() - 20);

local texite = Frames.Text(Frames.Root)
texite:SetPoint("TOPLEFT", Frames.Root, "TOPLEFT", 100, 250)
texite:SetWidth(600)
texite:SetBackground(0, 0, 1, 0.1)
texite:SetColor(1, 0.8, 0.8, 0.8)
texite:SetText("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis urna libero, elementum id commodo et, mollis et neque. Sed suscipit ornare purus, sed pellentesque felis luctus eu. Maecenas gravida, odio quis fermentum pretium, libero metus lacinia justo, a fringilla neque nisl vel lacus. Praesent elementum mauris et ligula dictum porttitor. Pellentesque a risus quam. Aliquam tincidunt interdum viverra. Nam quis nisi neque. Nam non risus tellus, ac ullamcorper eros. Mauris vestibulum odio sit amet leo ullamcorper ultricies. Fusce eget imperdiet ante. Pellentesque dapibus dignissim elit, id rutrum magna ullamcorper vitae.\n\nIn elementum dolor in mi placerat sollicitudin. Sed in quam quam, suscipit dignissim nisi. Suspendisse potenti. Sed nec iaculis justo. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla dignissim elit augue, eget hendrerit sem. Donec vel arcu est, vel pellentesque lectus. Nunc congue eleifend egestas. Donec sit amet cursus velit. Vestibulum eget nulla a enim egestas luctus et ac velit.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam erat volutpat. In nulla lorem, consectetur in pharetra sit amet, sagittis a neque. Sed lacinia, dolor sit amet scelerisque tincidunt, quam eros convallis ipsum, sit amet rutrum ligula purus quis nulla. Nunc quis nibh massa. Praesent vel augue risus. Cras commodo eleifend felis, interdum pharetra orci mattis sit amet. Cras lobortis, odio vel semper tempor, magna nunc aliquet dui, eu molestie tellus ligula et orci. Vestibulum pulvinar massa nec erat tempus a tincidunt arcu rhoncus. Morbi dictum sapien vel turpis consectetur ut mollis eros feugiat. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Etiam eget libero eget metus aliquam lobortis. Praesent feugiat tortor vel mi auctor a vehicula dolor pulvinar. Maecenas ac tortor velit, sit amet facilisis justo.")
texite:SetWordwrap(true)
texite:SetSize(16)
texite:SetLayer(3)
texite:SetInteractive("edit")

texite:SetHeight(100)

texite:SetSelection(30, 240)
texite:SetColorSelection(1, 1, 1, 0.5)

texite:SetFocus(true)
texite:EventKeyTypeAttach(function (f, eh, typ)
  print("Type!", f, eh, typ)
  print(eh:CanFinalize())
  if typ == "\n" then
    eh:Finalize()
    texite:SetText("")
  end
end, -1)
 
print("txgn")
print(texite:GetName())
print(texite:GetNameFull())
print("txgn done")

--[[texite:EventKeyDownAttach(function (f, ev) print("Down!") dump(ev) end)
texite:EventKeyUpAttach(function (f, ev) print("Up!") dump(ev) end)
texite:EventKeyTypeAttach(function (f, ...) print("Type!", ...) end)
texite:EventKeyRepeatAttach(function (f, ev) print("Repeat!") dump(ev) end)]]

--local f = function (...) _G.dump("Movik!", ...) texite:Obliterate() end
--texite:EventMouseOverAttach(f)
--texite:EventMouseOutAttach(f)

--texite:EventMouseOverDetach(f)
--texite:EventMouseOutDetach(f)

--texite:Obliterate()

--[[texite:EventMouseLeftClickAttach(function (...) print("EMLC", select("#", ...), ...) end)
texite:EventMouseButtonClickAttach(function (...) print("EMBC", select("#", ...), ...) end)
texite:EventMouseMoveAttach(function (...) print("EMM", select("#", ...), ...) end)
texite:EventMouseMoveOutsideAttach(function (...) print("EMMO", select("#", ...), ...) end)]]

local v = 0
Event.System.Update.Begin:Attach(function ()
  texite:SetWidth(v % 300 + 100)
  v = v + 1
  --texite:SetSelection(v, v + 5)
  --v = (v + 1) % #texite:GetText()
end)

for k, v in pairs(getmetatable(texite).__index) do
  print(k, v)
end
