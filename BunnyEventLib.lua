local function mkReadOnly(tbl)
  return setmetatable(tbl, {
    __newindex = function()
      error("This table is read only")
    end
  })
end

local eventMetatable = {
  __registered = {},
  __newindex = function() return end,
  __index = {},
  __type = "Event"
}

function eventMetatable.__index.register(self, func, name)
  table.insert(self.__registered, {
    func = func,
    name = name
  })
end
function eventMetatable.__index.clear(self)
  self.__registered = {}
end
function eventMetatable.__index.remove(self, callback)
  for i = #self.__registered, 1, -1 do
    if self.__registered[i].func == callback or self.__registered[i].name == callback then
      table.remove(self.__registered, i)
    end
  end
end
function eventMetatable.__index.getRegisteredCount(self, name)
  if not callback then
    return #self.__registered
  end
  
  local count = 0
  for _, v in pairs(self.__registered) do
    if v.name == name then
      count = count + 1
    end
  end
  return count
end
eventMetatable.__len = eventMetatable.__index.getRegisteredCount
function eventMetatable.__index.invoke(self, ...)
  for _, v in pairs(self.__registered) do
    v.func(...)
  end
end
eventMetatable.__index.call = eventMetatable.__index.invoke
eventMetatable.__index.fire = eventMetatable.__index.invoke

eventMetatable = mkReadOnly(eventMetatable)

local eventsMetatable = mkReadOnly {
  __table = {},
  __index = function(self, index)
    return self.__table[index]
  end,
  __newindex = function(self, index, value)
    if type(index) == "string" and type(value) == "function" and self.__table[index:upper()] and type(self.__table[index:upper()] == "Event") then
      self.__table[index]:register(value)
    else
      self.__table[index] = value
    end
  end,
  __pairs = function(self)
    return pairs(self._table)
  end,
  __ipairs = function(self)
    return ipairs(self.__table)
  end,
  __len = function()
    return #self.__table
  end,
  __type = "EventsAPI"
}

local lib = {}

function lib.new()
  return setmetatable({}, eventMetatable)
end
lib.newEvent = lib.new

function lib.newEvents()
  return setmetatable({}, eventsMetatable)
end
lib.newEventsAPI = lib.newEvents

return lib

