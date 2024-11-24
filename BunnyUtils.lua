local utils = {}

local function isType(var, expectedType, index)
  if type(var) ~= expectedType then
    return false, "Expected type " .. expectedType .. ", but got " .. type(var) .. " (argument " .. index .. ")"
  else
    return true
  end
end

function utils.urlFormat(str)
  str = tostring(str)

  return string.gsub(str, "([^%w])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
end

function utils.trimUUID(uuid)
  assert(isType(uuid, "string", 1))
  if #uuid ~= 36 then
    error("Invalid UUID")
  end

  return uuid:gsub("%-", "")
end
function utils.untrimUUID(uuid)
  assert(isType(uuid, "string", 1))
  if #uuid ~= 32 then
    error("Invalid UUID")
  end

  return uuid:sub(1, 8) .. "-" ..
    uuid:sub(9, 12) .. "-" ..
    uuid:sub(13, 16) .. "-" ..
    uuid:sub(17, 20) .. "-" .. uuid:sub(21, 32)
end

return utils

