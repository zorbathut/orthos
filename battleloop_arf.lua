local lw = ...

local r, g, b, a
local stattext
local aborttext
local retrytext
local failtext

if lw == "lose" then
  r, g, b, a = 0.2, 0, 0, 0.7
  stattext = "Read error; remote program missing"
  aborttext = "Cancel the battle entirely"
  retrytext = "Attempt the battle again"
  failtext = "Return to the main menu"
else
  r, g, b, a = 0, 0, 0.2, 0.7
  stattext = "Program complete, returning to OS"
  aborttext = "Return to battle configuration"
  retrytext = "Attempt the battle again"
  failtext = "Return to the main menu"
end

local ded = Frame.Frame(Frame.Root)
ded:SetLayer(1)
ded:SetPoint("TOPLEFT", Frame.Root, "TOPLEFT")
ded:SetPoint("BOTTOMRIGHT", Frame.Root, "BOTTOMRIGHT")
ded:SetBackground(r, g, b, a)

local dedtext = Frame.Text(ded)
dedtext:SetText(stattext)
dedtext:SetPoint("CENTER", ded, "CENTER", 0, -100)
dedtext:SetSize(40)

local abort = Frame.Text(ded)
abort:SetText("Abort")
abort:SetPoint("CENTER", ded, "CENTER", -200, 100)
abort:SetSize(40)

local retry = Frame.Text(ded)
retry:SetText("Retry")
retry:SetPoint("CENTER", ded, "CENTER", 0, 100)
retry:SetSize(40)

local fail = Frame.Text(ded)
fail:SetText("Fail")
fail:SetPoint("CENTER", ded, "CENTER", 200, 100)
fail:SetSize(40)

abort.descr = Frame.Text(ded)
abort.descr:SetText(aborttext)
abort.descr:SetPoint("CENTER", ded, "CENTER", 0, 300)
abort.descr:SetVisible(false)
abort.descr:SetSize(30)

retry.descr = Frame.Text(ded)
retry.descr:SetText(retrytext)
retry.descr:SetPoint("CENTER", ded, "CENTER", 0, 300)
retry.descr:SetVisible(false)
retry.descr:SetSize(30)

fail.descr = Frame.Text(ded)
fail.descr:SetText(failtext)
fail.descr:SetPoint("CENTER", ded, "CENTER", 0, 300)
fail.descr:SetVisible(false)
fail.descr:SetSize(30)

local opts = {abort, retry, fail}
local optpos = 1

local indicator = Frame.Frame(ded)

local function SetIndicator(npos)
  opts[optpos].descr:SetVisible(false)
  optpos = npos
  opts[optpos].descr:SetVisible(true)
  indicator:SetWidth(20)
  indicator:SetHeight(20)
  indicator:SetBackground(1, 1, 1)
  indicator:SetPoint("TOPCENTER", opts[optpos], "BOTTOMCENTER", 0, 10)
end
SetIndicator(2)

Event.System.Key.Down:Attach(function (key)
  if key == "Left" then
    local pos = optpos - 1
    if pos == 0 then pos = #opts end
    SetIndicator(pos)
  elseif key == "Right" then
    local pos = optpos + 1
    if pos > #opts then pos = 1 end
    SetIndicator(pos)
  elseif key == "z" or key == "Enter" then
    if opts[optpos] == abort then
      Command.War.Abort()
    elseif opts[optpos] == retry then
      Command.War.Retry()
    elseif opts[optpos] == fail then
      Command.War.Fail()
    end
  end
end)
