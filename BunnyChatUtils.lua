--[[
Copyright 2024 TheKillerBunny

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]

---@alias TextComponentHoverEventAction ('show_text'|'show_item'|'show_entity')
---@alias TextComponentHoverEvent { action: TextComponentHoverEventAction, contents: string|TextJsonComponent }
---@alias TextComponentClickEventAction ('open_url'|'open_file'|'run_command'|'suggest_command')
---@alias TextComponentClickEvent { action_wheel: TextComponentClickEventAction, value: string }
---@alias color ('#<HEX>'|'black'|'dark_blue'|'dark_green'|'dark_aqua'|'dark_red'|'dark_purple'|'gold'|'gray'|'dark_gray'|'blue'|'green'|'aqua'|'red'|'light_purple'|'yellow'|'white')
---@alias TextJsonComponent { with?: TextJsonComponent[], text?: string, translate?: string, extra?: TextJsonComponent[], color?: color, font?: string, bold?: boolean, italic?: boolean, underlined?: boolean, strikethrough?: boolean, obfuscated?: boolean, insertion?: string, clickEvent?: TextComponentClickEvent, hoverEvent?: TextComponentHoverEvent }
---@alias BunnyChatUtils.RegistryFunction fun(self: BunnyChatUtils, chatJson: TextJsonComponent, rawText: string): TextJsonComponent, string

local chatMessageList = {}

---@class BunnyChatUtils
local BunnyChatUtils = {
  ---@type BunnyChatUtils.RegistryFunction[][]
  __REGISTRY = { {}, {}, {}, {}, {} },
  __VARS = {},
}

---@param self BunnyChatUtils
---@param func BunnyChatUtils.RegistryFunction
---@param name string
function BunnyChatUtils.register(self, func, name, priority)
  if not priority then priority = 3 end

  self.__REGISTRY[math.clamp(priority, 1, 5)][name] = func
end

function BunnyChatUtils.formatMarkdown(s)
  s = type(s) == "string" and s or ""
  local msg = string.gsub(s, "\\(.)", function(str)
    return "§" .. string.byte(str) .. "§"
  end)

  msg = msg .. " "

  local compose = {}

  local italic = false
  local bold = false
  local link = false
  local strikethrough = false
  local underlined = false

  local temp = ""
  local ptr = 1

  local function insert(tbl)
    if link then
      tbl.color = "aqua"
      tbl.underlined = true

      local text = tbl.text

      local match1, match2 = text:match("^%[(.-)%]%((.-)%)")

      if match2 then
        tbl.text = match1
      end

      if not match2 then match2 = text end

      tbl.clickEvent = {
        action = "open_url",
        value = match2
      }
      tbl.hoverEvent = {
        action = "show_text",
        value = {
          text = match2,
          color = "aqua",
          underlined = true
        }
      }

      table.insert(compose, tbl)
    else
      table.insert(compose, tbl)
    end
  end

  while #msg >= 1 do
    local char = string.sub(msg, 1, 1)
    local nextChar = string.sub(msg, 2, 2)

    local linkTxt

    if char == "*" then
      insert({
        text = temp:gsub("§(%d-)§", function(s) return (not string.char(s):match("[%*%[%]%(%)%~%_]") and "\\" or "") .. string.char(tonumber(s)) end),
        italic = italic,
        bold = bold,
        strikethrough = strikethrough,
        underlined = underlined,
        color = "white"
      })
      temp = ""
      char = ""
      if nextChar == "*" then
        msg = msg:gsub("^..", "")
        bold = not bold
      else
        msg = msg:gsub("^.", "")
        italic = not italic
      end
    end

    if char == "_" and nextChar == "_" then
      msg = msg:gsub("^..", "")
      insert({
        text = temp:gsub("§(%d-)§", function(s) return (not string.char(s):match("[%*%[%]%(%)%~%_]") and "\\" or "") .. string.char(tonumber(s)) end),
        italic = italic,
        bold = bold,
        strikethrough = strikethrough,
        underlined = underlined,
        color = "white"
      })
      char = ""
      temp = ""
      underlined = not underlined
    end

    if char == "~" and nextChar == "~" then
      msg = msg:gsub("^..", "")
      insert({
        text = temp:gsub("§(%d-)§", function(s) return (not string.char(s):match("[%*%[%]%(%)%~%_]") and "\\" or "") .. string.char(tonumber(s)) end),
        italic = italic,
        bold = bold,
        strikethrough = strikethrough,
        underlined = underlined,
        color = "white"
      })
      char = ""
      temp = ""
      strikethrough = not strikethrough
    end

    linkTxt = msg:match("^%[.-%]%(.-%)")
    if not linkTxt then linkTxt = msg:match("^(https?://.-) ") end
    if linkTxt then
      insert({
        text = temp:gsub("§(%d-)§", function(s) return (not string.char(s):match("[%*%[%]%(%)%~%_]") and "\\" or "") .. string.char(tonumber(s)) end),
        italic = italic,
        bold = bold,
        strikethrough = strikethrough,
        underlined = underlined,
        color = "white"
      })
      temp = ""
      link = true
      insert({
        text = linkTxt:gsub("§(%d-)§", function(s) return (not string.char(s):match("[%*%[%]%(%)%~%_]") and "\\" or "") .. string.char(tonumber(s)) end),
        italic = italic,
        bold = bold,
        strikethrough = strikethrough,
        underlined = underlined,
        color = "white"
      })

      link = false
      char = ""
    end

    ptr = ptr + 1
    if char == "" then ptr = ptr - 1 end

    temp = temp .. char
    if char ~= "" then
      msg = msg:gsub("^.", "")
    end

    if linkTxt and msg:match("^%[.-%]%(.-%)") then
      msg = msg:gsub("^%[.-%]%(.-%)", "")
    elseif linkTxt then
      msg = msg:gsub("^https?://.- ", " ")
    end
  end

  insert({
    text = temp:gsub("§(%d-)§", function(s) return (not string.char(s):match("[%*%[%]%(%)%~%_]") and "\\" or "") .. string.char(tonumber(s)) end),
    italic = italic,
    bold = bold,
    strikethrough = strikethrough,
    underlined = underlined,
    color = "white"
  })

  return compose
end

---@param self BunnyChatUtils
---@param rawText string
---@param jsonText TextJsonComponent
function BunnyChatUtils.process(self, rawText, jsonText)
  local newJsonText
  local newRawText

  for _, v in ipairs(self.__REGISTRY) do
    for _, w in pairs(v) do
      if not newJsonText then
        newJsonText, newRawText = w(self, jsonText, rawText)
      else
        newJsonText, newRawText = w(self, newJsonText, newRawText)
      end
      if newRawText == "" then return nil end
    end
  end

  return newJsonText
end

---@param self BunnyChatUtils
---@param var string
function BunnyChatUtils.getCustomVar(self, var)
  return self.__VARS[var]
end

---@param self BunnyChatUtils
---@param var string
---@param val any
function BunnyChatUtils.setCustomVar(self, var, val)
  self.__VARS[var] = val
end

BunnyChatUtils:register(function(self, jsonText, rawText)
  if self:getCustomVar("prevText") == nil then
    self.__VARS["prevText"] = rawText
    self.__VARS["messageCount"] = 1
    return jsonText, rawText
  end

  if rawText:gsub("%s*$", "") == self.__VARS["prevText"]:gsub("%s*$", "") then
    self.__VARS["messageCount"] = self.__VARS["messageCount"] + 1
    host:setChatMessage(1, nil)
    if jsonText.extra then
      table.insert(jsonText.extra, { text = " (", color = "dark_gray" })
      table.insert(jsonText.extra, { text = "x", color = "gray" })
      table.insert(jsonText.extra,
      { text = tostring(self.__VARS["messageCount"]), color = "#A0FFA0" })
      table.insert(jsonText.extra, { text = ")", color = "dark_gray" })

      return jsonText, rawText
    elseif jsonText.with then
      jsonText.extra = {}

      table.insert(jsonText.extra, { text = " (", color = "dark_gray" })
      table.insert(jsonText.extra, { text = "x", color = "gray" })
      table.insert(jsonText.extra,
      { text = tostring(self.__VARS["messageCount"]), color = "#A0FFA0" })
      table.insert(jsonText.extra, { text = ")", color = "dark_gray" })
      return jsonText, rawText
    else
      table.insert(jsonText, { text = " (", color = "dark_gray" })
      table.insert(jsonText, { text = "x", color = "gray" })
      table.insert(jsonText,
      { text = tostring(self.__VARS["messageCount"]), color = "#A0FFA0" })
      table.insert(jsonText, { text = ")", color = "dark_gray" })

      return jsonText, rawText
    end
  end

  local _, count = rawText:gsub("\n", "\n")

  if count > 50 then
    return {{text = "Message with more than 50 newlines (" .. count .. ") filtered.", color = "red"}}, "Message with more than 20 new lines filtered."
  end

  self.__VARS["prevText"] = rawText
  self.__VARS["messageCount"] = 1
  return jsonText, rawText
end, "BUILTIN.FILTER_SPAM", 5)

BunnyChatUtils:register(function(self, jsonText, rawText)
  if jsonText[#jsonText] and jsonText[#jsonText].text then
    if jsonText[#jsonText].text.text then
      jsonText[#jsonText].text = jsonText[#jsonText].text.text
    end
  end
  if jsonText[#jsonText] and jsonText[#jsonText].text and tostring(jsonText[#jsonText].text):match("^#%x%x%x$") then
    local clr = tostring(jsonText[#jsonText].text)
    jsonText[#jsonText].color = "#" .. clr:sub(2, 2):rep(2) .. clr:sub(3, 3):rep(2) .. clr:sub(4, 4):rep(2)
  elseif jsonText[#jsonText] and tostring(jsonText[#jsonText].text and jsonText[#jsonText].text):match("^#%x%x%x%x%x%x$") then
    jsonText[#jsonText].color = tostring(jsonText[#jsonText].text)
  end
  return jsonText, rawText
end, "BUILTIN.COLORS", 2)

BunnyChatUtils:register(function(self, jsonText, rawText)
  local time = client.getDate()
  minutes = time.minute
  hours = time.hour

  if tostring(minutes):len() < 2 then
    minutes = "0" .. minutes
  end

  local pm = false

  while hours > 12 do
    hours = hours - 12
    pm = true
  end

  local tmstmp = {
    {
      text = "",
      color = "white",
      bold = false,
      italic = false,
      underlined = false,
    },
    {
      text = "[",
      color = "gray",
      bold = false,
      italic = false,
      underlined = false,
    },
    {
      text = tostring(hours),
      color = "yellow",
      bold = false,
      italic = false,
      underlined = false,
    },
    {
      text = ":",
      color = "white",
      bold = false,
      italic = false,
      underlined = false,
    },
    {
      text = tostring(minutes),
      color = "yellow",
      bold = false,
      italic = false,
      underlined = false,
    },
    {
      text = " " .. ((pm and "PM") or "AM"),
      color = "light_purple",
      bold = false,
      italic = false,
      underlined = false,
    },
    {
      text = "] ",
      color = "gray",
      bold = false,
      italic = false,
      underlined = false,
    },
  }

  local newTxt = {}

  for _, v in ipairs(tmstmp) do
    table.insert(newTxt, v)
  end
  for _, v in ipairs(jsonText[1] and jsonText or {jsonText}) do
    table.insert(newTxt, v)
  end

  return newTxt, rawText
end, "BUILTIN.TIMESTAMPS")

BunnyChatUtils:register(function(self, chatJson, rawText)
  local function filterObfuscation(jsonTable)
    for k, v in pairs(jsonTable) do
      if type(v) == "table" then
        if v.text or v.translate then
          if v.obfuscated then
            if v.text then
              v.text = "<OBF>" .. v.text .. "</OBF>"
            end
          end

          v.obfuscated = false
        end
        v = filterObfuscation(v)
      elseif (k == "text" or type(k) == "number") and type(v) == "string" then
        v = v:gsub("§k.-§r", function(s)
          return s:gsub("§k", "<OBF>"):gsub("§r", "</OBF>§r")
        end)
      end

      jsonTable[k] = v
    end

    return jsonTable
  end

  chatJson = filterObfuscation(chatJson)

  rawText = rawText:gsub("§k.-§r", function(s)
    return s:gsub("§k", "<OBF>"):gsub("§r", "</OBF>§r")
  end)

  return chatJson, rawText
end, "BUILTIN.OBFUSCATIONFILTER")

BunnyChatUtils:register(function(_, chatJson, rawText)
  if chatJson.translate then
    if chatJson.translate == "multiplayer.player.left" then
      local plr = chatJson.with[1].insertion
      if not plr then
        plr = chatJson.with[1]
      end

      chatJson = {
        {
          text = plr,
          color = "aqua",
        },
        {
          text = " left the game!",
          color = "gray",
        },
      } --[[@as TextJsonComponent]]
    end

    goto done
  end

  ::done::

  return chatJson, rawText
end, "BUILTIN.LEAVE", 1)

BunnyChatUtils:register(function(_, chatJson, rawText)
  if chatJson.translate then
    if chatJson.translate == "multiplayer.player.joined" then
      local plr = chatJson.with[1].insertion
      if not plr then
        plr = chatJson.with[1]
      end

      chatJson = {
        {
          text = plr,
          color = "aqua",
        },
        {
          text = " joined the game!",
          color = "gray",
        },
      } --[[@as TextJsonComponent]]
    end

    goto done
  end

  ::done::

  return chatJson, rawText
end, "BUILTIN.JOIN", 1)

BunnyChatUtils:register(function(_, chatJson, rawText)
  local sender, content = rawText:match("^%[Discord%] (.-) » (.*)$")
  if not sender or not content then return chatJson, rawText end

  sender = sender:gsub("»", ""):gsub("%s*$", "")

  chatJson = {
    translate = "chat.type.text",
    with = {
      {
        {
          text = "[",
          color = "gray"
        },
        {
          text = "DISCORD",
          color = "#7289DA"
        },
        {
          text = "] ",
          color = "gray"
        },
        {
          text = sender,
          color = "white"
        }
      },
      {
        text = content,
        color = "white"
      }
    }
  }
  rawText = string.format("<%s> %s", sender, content)

  return chatJson, rawText
end, "BUILTIN.PLAZA_DISCORD_TRANSLATION", 1)

BunnyChatUtils:register(function(self, chatJson, rawText)
  if chatJson.extra and chatJson.extra[1] and chatJson.extra[1].translate == "chat.type.text" then
    cJson = chatJson
    chatJson = {
      translate = "chat.type.text",
      with = {
        cJson.extra[1].with,
        {
          text = table.concat({
            cJson.extra[2].text,
            table.unpack(cJson.extra[2].extra or {})
          }, "")
        }
      }
    }
  end

  if chatJson.translate then
    if chatJson.translate == "chat.type.text" then
      local plr = chatJson.with[1]

      local toAppend = ""
      for _, v in pairs(chatJson.with[2].extra or {}) do
        toAppend = toAppend .. (v.text or v) .. " "
      end
      local msg = self.formatMarkdown((chatJson.with[2].text or chatJson.with[2]) .. toAppend)

      if plr.insertion then
        chatMessageList[plr.insertion] = {
          message = rawText:gsub("^%<[%w%_% ]-%> ", ""),
          timestamp = client:getSystemTime()
        }
      else
        chatMessageList[plr] = {
          message = rawText:gsub("^%<[%w%_% ]-%> ", ""),
          timestamp = client:getSystemTime()
        }
      end

      if type(plr) == "table" then
        chatJson = {
          plr,
          {
            text = " » ",
            color = "gray",
            bold = true,
          },
          table.unpack(msg)
        } --[[@as TextJsonComponent]]
      else
        chatJson = {
          {
            text = plr,
            color = "white",
            bold = false,
          },
          {
            text = " » ",
            color = "gray",
            bold = true,
          },
          table.unpack(msg)
        } --[[@as TextJsonComponent]]
      end
    end

    goto done
  end

  ::done::

  return chatJson, rawText
end, "BUILTIN.USERNAMEFORMAT", 2)

BunnyChatUtils:register(function(self, chatJson, rawText)
  if chatJson.translate then
    if chatJson.translate == "chat.type.team.sent" then
      local dispName = chatJson.with[1].with

      local plr = chatJson.with[2]

      local toAppend = ""
      for _, v in pairs(chatJson.with[3].extra or {}) do
        toAppend = toAppend .. (v.text or v) .. " "
      end
      local msg = self.formatMarkdown((chatJson.with[3].text or chatJson.with[3]) .. toAppend)

      dispName[1].hoverEvent = {
        action = "show_text",
        value = {
          {
            text = "Message ",
            color = "gray",
          },
          {
            text = "team",
            color = "aqua",
          },
          {
            text = "?",
            color = "gray",
          },
        },
      }

      dispName[1].clickEvent = {
        action = "suggest_command",
        value = "/teammsg ",
      }

      if type(plr) == "table" then
        chatJson = {
          {
            text = "",
            color = "white",
            bold = false,
          },
          {
            text = "[",
            color = "gray",
            bold = false,
          },
          dispName,
          {
            text = "]",
            color = "gray",
            bold = false,
          },
          {
            text = " » ",
            color = "gray",
            bold = true,
          },
          plr,
          {
            text = " » ",
            color = "gray",
            bold = true,
          },
          table.unpack(msg)
        } --[[@as TextJsonComponent]]
      else
        chatJson = {
          {
            text = plr,
            color = "white",
            bold = false,
          },
          {
            text = " » ",
            color = "gray",
            bold = true,
          },
          table.unpack(msg)
        } --[[@as TextJsonComponent]]
      end
    end

    goto done
  end

  ::done::

  return chatJson, rawText
end, "BUILTIN.TEAMUSERNAMEFORMAT", 1)

BunnyChatUtils:register(function(_, chatJson, rawText)
  if chatJson.translate then
    if chatJson.translate == "commands.message.display.outgoing" then
      pcall(function()
        local plrName = chatJson.with[1]
        local plr = ""

        if plrName.extra then
          for _, v in ipairs(plrName.extra) do
            plr = plr .. v
          end
        else
          plr = plrName.insertion
        end

        local msg = chatJson.with[2]

        if plrName.color == "white" then plrName.color = nil end

        chatJson = {
          {
            text = "You",
            color = "aqua",
            bold = false,
          },
          {
            text = " --> ",
            color = "gray",
            bold = true,
          },
          {
            text = plr,
            color = (not plrName.color and "yellow" or plrName.color),
            bold = false,
          },
          {
            text = " » ",
            color = "gray",
            bold = true,
          },
          {
            text = msg,
            color = "white",
            bold = false,
          },
        } --[[@as TextJsonComponent]]
      end)
    end

    goto done
  end

  ::done::

  return chatJson, rawText
end, "BUILTIN.MESSAGE.OUTGOING", 1)

BunnyChatUtils:register(function(_, chatJson, rawText)
  if chatJson.translate then
    if chatJson.translate == "commands.message.display.incoming" then
      pcall(function()
        local plrName = chatJson.with[1]
        local plr = ""

        if plrName.extra then
          for _, v in ipairs(plrName.extra) do
            plr = plr .. v
          end
        else
          plr = plrName.insertion
        end

        local msg = chatJson.with[2]

        if plrName.color == "white" then plrName.color = nil end

        chatJson = {
          {
            text = plr,
            color = (not plrName.color and "yellow" or plrName.color),
            bold = false,
          },
          {
            text = " --> ",
            color = "gray",
            bold = true,
          },
          {
            text = "You",
            color = "aqua",
            bold = false,
          },
          {
            text = " » ",
            color = "gray",
            bold = true,
          },
          {
            text = msg,
            color = "white",
            bold = false,
          },
        } --[[@as TextJsonComponent]]
      end)
    end

    goto done
  end

  ::done::

  return chatJson, rawText
end, "BUILTIN.MESSAGE.INCOMING", 1)

BunnyChatUtils:register(function(_, chatJson, rawText)
  if chatJson.translate then
    if chatJson.translate == "chat.type.advancement.task" then
      pcall(function()
        local plrName = chatJson.with[1]
        local plr = ""

        if plrName.extra then
          for _, v in ipairs(plrName.extra) do
            plr = plr .. v
          end
        else
          plr = plrName.insertion
        end

        local task = chatJson.with[2].with[1]
        task.color = "aqua"
        task.bold = false

        if plrName.color == "white" then plrName.color = nil end

        chatJson = {
          {
            text = plr,
            color = (not plrName.color and "yellow" or plrName.color),
            bold = false,
          },
          {
            text = " has made the advancement ",
            color = "gray",
            bold = false,
          },
          task,
        } --[[@as TextJsonComponent]]
      end)
    end

    goto done
  end

  ::done::

  return chatJson, rawText
end, "BUILTIN.ADVANCEMENT.TASK", 1)

BunnyChatUtils:register(function(_, chatJson, rawText)
  if chatJson.translate then
    if chatJson.translate == "chat.type.advancement.goal" then
      local plrName = chatJson.with[1]
      local plr = ""

      if plrName.extra then
        for _, v in ipairs(plrName.extra) do
          plr = plr .. v
        end
      else
        plr = plrName.insertion
      end

      local task = chatJson.with[2].with[1]
      task.color = "aqua"
      task.bold = false

      if plrName.color == "white" then plrName.color = nil end

      chatJson = {
        {
          text = plr,
          color = (not plrName.color and "yellow" or plrName.color),
          bold = false,
        },
        {
          text = " has reached the goal ",
          color = "gray",
          bold = false,
        },
        task,
      } --[[@as TextJsonComponent]]
    end

    goto done
  end

  ::done::

  return chatJson, rawText
end, "BUILTIN.ADVANCEMENT.GOAL", 1)

BunnyChatUtils:register(function(_, chatJson, rawText)
  if chatJson.translate then
    if chatJson.translate == "chat.type.advancement.challenge" then
      local plrName = chatJson.with[1]
      local plr = ""

      if plrName.extra then
        for _, v in ipairs(plrName.extra) do
          plr = plr .. v
        end
      else
        plr = plrName.insertion
      end

      local task = chatJson.with[2].with[1]
      task.color = "aqua"
      task.bold = false

      if plrName.color == "white" then plrName.color = nil end

      chatJson = {
        {
          text = plr,
          color = (not plrName.color and "yellow" or plrName.color),
          bold = false,
        },
        {
          text = " has completed the challenge ",
          color = "gray",
          bold = false,
        },
        task,
      } --[[@as TextJsonComponent]]
    end

    goto done
  end

  ::done::

  return chatJson, rawText
end, "BUILTIN.ADVANCEMENT.CHALLENGE", 1)

events.CHAT_RECEIVE_MESSAGE:register(function(rawText, jsonText)
  -- if not rawText:find("DEBUG") then
  --     log(jsonText)
  -- end

  local result = BunnyChatUtils:process(rawText, parseJson(jsonText) --[[@as TextJsonComponent]])
  if not result then return false end
  local final = {}

  for k, v in pairs(result) do
    if v[1] and type(v) == "table" then
      final = {
        table.unpack(final),
        table.unpack(v)
      }
    else
      table.insert(final, v)
    end
  end

  return toJson(final)
end)

return BunnyChatUtils
