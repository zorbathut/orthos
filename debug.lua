
local loseTrigger = Command.Event.Create(_G, "Debug.Lose")

function lose()
  loseTrigger()
end

local winTrigger = Command.Event.Create(_G, "Debug.Win")

function win()
  winTrigger()
end
