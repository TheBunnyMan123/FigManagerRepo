local macros = {}
local lib = {}

function lib.add(macrosToAdd)
  for k, v in pairs(macrosToAdd) do
    macros[k] = v
  end
end

function lib.format(script)
  local metadata = script:match("^%#%[(.-)%]\n")
  if not metadata then
    return script
  end

  local mdata = {}

  (metadata .. ";"):gsub("(.-)[;,]", function(v)
    mdata[v] = true
  end)

  if not mdata.macros_v1 then
    return script
  end

  for k, v in pairs(macros) do
    script = script:gsub(k, v)
  end

  return script
end

return lib

