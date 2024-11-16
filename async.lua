local forList = {{
  min = 0,
  max = 0,
  iter = 0,
  step = 1,
  func = function(i) end
}}
local forpairsList = {{
  table = {a="b"},
  key = "a",
  value = "b",
  func = function(key, value) end
}}

function events.WORLD_RENDER()
  if minimal then return end
  local start = client.getSystemTime()
  local max = ((player:isLoaded() and player:getVelocity():length() > 0) and 20) or (host:isHost() and 40 or 20)
  
  while (start > (client.getSystemTime() - max)) and (forList[1] or forpairsList[1]) do
    for i, v in pairs(forList) do
      v.iter = v.iter + v.step
      if v.iter > v.max then
        table.remove(forList, i)
        goto continue
      end
      v.func(v.iter)

      ::continue::
    end
    for i, v in pairs(forpairsList) do
      v.func(v.key, v.value)
      local key, value = next(v.table, v.key)
      if not value then
        table.remove(forpairsList, i)
      end
      v.key = key
      v.value = value
      ::continue::
    end
  end
end

local lib = {}

function lib.for_(min, max, step, func)
  if minimal then
    for i = min, max, step do
      func(i)
    end
    return
  end
  table.insert(forList, {
    min = min,
    max = max,
    iter = min,
    step = step,
    func = func,
  })
end

function lib.forpairs(tbl, func)
  if minimal then
    for k, v in pairs(tbl) do
      func(k, v)
    end
    return
  end
  local key, value = next(tbl)
  table.insert(forpairsList, {
    table = tbl,
    key = key,
    value = value,
    func = func
  })
end

return lib

