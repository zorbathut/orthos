
local gianttext = CreateFrame("Text")
gianttext:SetText("IMMORTALS")
gianttext:SetPoint("TOPCENTER", UIParent, "TOPCENTER", 0, 100)
gianttext:SetColor(1, 1, 1)
gianttext:SetSize(150)

ShowMouseCursor(true) -- keep this around so it's reset properly
LockMouseCursor(false) -- keep this around so it's reset properly

--disable_anchor()
--pause_on_nofocus = true

menu.ok_text:SetPoint("CENTER", UIParent, "CENTER", 0, 70)
menu.ok_text:SetText("Start")

menu.exit_text:SetPoint("CENTER", UIParent, "CENTER", 0, 250)
