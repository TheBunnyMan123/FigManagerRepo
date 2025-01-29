--[[
Copyright 2025 TheKillerBunny

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]

---@alias errorFunc fun(script: string, reason: string, stacktrace: {line: string, script: string, chunk: string}[], code: string?, username: string, line: number)
local lib = {func=function() end}

---@param func errorFunc
function lib.setFunc(func)
   lib.func = func
end

local function splitStr(str, on)
    on = on or " "
    local result = {}
    local delimiter = on:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    for match in (str .. on):gmatch("(.-)" .. delimiter) do
        result[#result+1] = match
    end
    return result
end

local function tracebackError(msg, username)
   username = username or avatar:getEntityName()

   local erroredScript, mainLine, reason = msg:match("^(.-):([0-9]-) (.-)\n")
   local code = msg:match("script:%s+(.-)$")
   local trace = {}

   if not reason then
      return
   end
   
   local newScript, newLine, syntax = reason:match('%[string "(.+)"%]:([0-9]-): (syntax error)')
   if syntax then
      erroredScript = newScript
      reason = "syntax error"
      trace[#trace + 1] = {
         script = newScript,
         line = newLine,
         chunk = "script string"
      }
      code = nil
   end

   local split = splitStr(msg:match("stack traceback:%s+(.+)"):gsub("script:.-$", ""), "\n")

   local longestLine = 1
   msg:gsub(":([0-9]+):", function(s)
      if #s > longestLine then
         longestLine = #s
      end
   end)

   for _, v in ipairs(split) do
      v = v:gsub("^[\t ]+", "")

      local script, line, chunk = v:match("^(.-):([0-9]-): (.+)")

      if not script then
         script = "java/?"
         line = "0"
         chunk = v:match("%[Java%]: (.-)$")
      end

      if #line < longestLine then
         line = ("0"):rep(longestLine - #line) .. line
      end

      if v ~= "" then
         trace[#trace + 1] = {
            script = script,
            line = line,
            chunk = chunk
         }
      end
   end
      
   return lib.func(erroredScript, reason, trace, code, username or avatar:getEntityName(), tonumber(mainLine))
end

local errored = false
local function newError(msg)
    if errored then return "" end
    errored = true
    local err = tracebackError(msg)

    if not err then err = msg end

    printJson(err)

    for _, v in pairs(events:getEvents()) do
      v:clear()
    end

    err = err

    ---@type TextJsonComponent
    local newNameplate = {
      {
        text = avatar:getEntityName() .. " ",
        color = "white"
      },
      {
        text = "❌",
        color = "#FF0000",
        bold = true,
        hoverEvent = {
          action = "show_text",
          value = parseJson(err)
        }
      },
      {
        text = "${badges}",
        color = "white"
      }
    }

    nameplate.ALL:setText(toJson(newNameplate))
    nameplate.ENTITY:setOutline(true)

    vanilla_model.ALL:setVisible(true)

    local function remove(model)
      for _, v in pairs(model:getChildren()) do
        remove(v)
      end
      model:remove()
    end
    for _, v in pairs(models:getChildren()) do
      remove(v)
    end

    sounds:stopSound()
    particles:removeParticles()
end

if goofy then 
  function events.ERROR(msg)
    local err = tracebackError(msg)
    if not err then err = msg end
    printJson(err)
    goofy:stopAvatar(err)
    return true
  end
else
  local _require = require
  
  function require(module)
    local successAndArgs = table.pack(pcall(_require, module))
    successAndArgs.n = nil
    if not successAndArgs[1] then
      newError(successAndArgs[2])
    else
      table.remove(successAndArgs, 1)
      return table.unpack(successAndArgs)
    end 
  end

  local _newindex = figuraMetatables.EventsAPI.__newindex
  local _register = figuraMetatables.Event.__index.register
  function figuraMetatables.EventsAPI.__newindex(self, event, func)
    _newindex(self, event, function(...)
      local success, error = pcall(func, ...)
      if not success then
        newError(error)
      else
        return error
      end
    end)
  end
  function figuraMetatables.Event.__index.register(self, func, name)
    _register(self, function(...)
      local success, error = pcall(func, ...)
      if not success then
        newError(error)
      else
        return error
      end
    end, name)
  end
end

function events.CHAT_RECEIVE_MESSAGE(msg)
   local username, error = msg:match("^%[error%] (%S-) : (.-)$")
   if error then
      return tracebackError(error, username)
   end
end

lib.tracebackError = tracebackError

return lib

