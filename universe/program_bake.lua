
local out = io.open("programs.out.csv", "w")
out:write("Name\tType\tDescription\n")

for k in io.lines("programs.csv") do
  local name, steel, sound, flow, home, unity, regret, description = k:match("([^;]+);[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;[^;]*;([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);([^;]*);[^;]*;([^;]*)")
  print(name, steel, sound, flow, home, unity, regret, description)
  
  local types = {}
  if steel ~= "" then types.Steel = true end
  if sound ~= "" then types.Sound = true end
  if flow ~= "" then types.Flow = true end
  if home ~= "" then types.Home = true end
  if unity ~= "" then types.Unity = true end
  if regret ~= "" then types.Regret = true end
  
  for k in pairs(types) do
    for c = 1, 4 do
      out:write(string.format("%s\t%s\t%s\n", name, k, description))
    end
  end
end
