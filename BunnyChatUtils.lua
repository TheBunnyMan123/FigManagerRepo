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
  local msg = ""

  if type(s) == "string" then
    msg = s:gsub("%\\%*", "§asterisk§"):gsub("%\\%~", "§tilde§"):gsub("%\\%_", "§underscore§")
  else
    msg = s

    local function iter(internalStr)
      for k, v in pairs(internalStr) do
        if type(v) == "string" then
          v = BunnyChatUtils.formatMarkdown(v)
        elseif type(v) == "table" then
          v = iter(v)
        end

        msg[k] = v
      end

      return internalStr
    end

    if msg.extra then
      msg = iter(msg.extra)
    else
      msg = iter(msg)
    end

    return msg
  end

  local iter = 0
  local astercount = 0
  local undercount = 0
  local tildecount = 0

  for match in string.gmatch(msg, ".?%*") do
    if not match:find("^%\\") then
      astercount = astercount + 1
    end
  end

  for match in string.gmatch(msg, ".?%_%_") do
    if not match:find("^%\\") then
      undercount = undercount + 1
    end
  end

  for match in string.gmatch(msg, ".?%~%~") do
    if not match:find("^%\\") then
      tildecount = tildecount + 1
    end
  end

  local boldInitialized = false
  local function boldMarkdown(str)
    if not boldInitialized then
      iter = 0
      boldInitialized = true
    end

    iter = iter + 1

    if iter % 2 ~= 0 then
      return "§+bold§"
    else
      return "§-bold§"
    end
  end

  local italicInitialized = false
  local function italicMarkdown(str)
    if not italicInitialized then
      iter = 0
      italicInitialized = true
    end

    iter = iter + 1

    if iter % 2 ~= 0 then
      return "§+italic§"
    else
      return "§-italic§"
    end
  end

  local ulineInitialized = false
  local function ulineMarkdown(str)
    if not ulineInitialized then
      iter = 0
      ulineInitialized = true
    end

    iter = iter + 1

    if iter % 2 ~= 0 then
      return "§+uline§"
    else
      return "§-uline§"
    end
  end

  local sthroughInitialized = false
  local function sthroughMarkdown(str)
    if not sthroughInitialized then
      iter = 0
      sthroughInitialized = true
    end

    iter = iter + 1

    if iter % 2 ~= 0 then
      return "§+sthrough§"
    else
      return "§-sthrough§"
    end
  end


  ---@diagnostic disable-next-line: param-type-mismatch
  if astercount % 2 == 0 then
    msg = string.gsub(msg, "%*%*", boldMarkdown)
    msg = string.gsub(msg, "%*", italicMarkdown)
  end

  if tildecount % 2 == 0 then
    msg = string.gsub(msg, "%_%_", ulineMarkdown)
  end

  if undercount % 2 == 0 then
    msg = string.gsub(msg, "%~%~", sthroughMarkdown)
  end

  local bold, italic, uline, sthrough = false, false, false, false

  local function markdownStuff(s1, s2)
    local formatKey = s2:gsub("§", "")
    local add = s2:match("%+")
    formatKey = formatKey:gsub("[+-]", "")

    local toPrepend = ""

    if formatKey == "bold" then
      if add then
        bold = true
      else
        bold = false
      end

      if add then
        if italic then toPrepend = toPrepend .. "§o" end
        if uline then toPrepend = toPrepend .. "§n" end
        if sthrough then toPrepend = toPrepend .. "§m" end
        msg = msg:gsub("§%+bold§", "§l" .. toPrepend, 1)
      else
        if italic then toPrepend = toPrepend .. "§o" end
        if uline then toPrepend = toPrepend .. "§n" end
        if sthrough then toPrepend = toPrepend .. "§m" end
        msg = msg:gsub("§%-bold§", "§r" .. toPrepend, 1)
      end
    elseif formatKey == "italic" then
      if add then
        italic = true
      else
        italic = false
      end

      if add then
        if bold then toPrepend = toPrepend .. "§l" end

        if uline then toPrepend = toPrepend .. "§n" end
        if sthrough then toPrepend = toPrepend .. "§m" end
        msg = msg:gsub("§%+italic§", "§o" .. toPrepend, 1)
      else
        if bold then toPrepend = toPrepend .. "§l" end
        if uline then toPrepend = toPrepend .. "§n" end
        if sthrough then toPrepend = toPrepend .. "§m" end
        msg = msg:gsub("§%-italic§", "§r" .. toPrepend, 1)
      end
    elseif formatKey == "uline" then
      if add then
        uline = true
      else
        uline = false
      end

      if add then
        if bold then toPrepend = toPrepend .. "§l" end
        if italic then toPrepend = toPrepend .. "§o" end
        if sthrough then toPrepend = toPrepend .. "§m" end
        msg = msg:gsub("§%+uline§", "§n" .. toPrepend, 1)
      else
        if bold then toPrepend = toPrepend .. "§l" end
        if italic then toPrepend = toPrepend .. "§o" end
        if sthrough then toPrepend = toPrepend .. "§m" end
        msg = msg:gsub("§%-uline§", "§r" .. toPrepend, 1)
      end
    elseif formatKey == "sthrough" then
      if add then
        sthrough = true
      else
        sthrough = false
      end

      if add then
        if bold then toPrepend = toPrepend .. "§l" end
        if italic then toPrepend = toPrepend .. "§o" end
        if uline then toPrepend = toPrepend .. "§n" end
        msg = msg:gsub("§%+sthrough§", "§m" .. toPrepend, 1)
      else
        if bold then toPrepend = toPrepend .. "§l" end
        if italic then toPrepend = toPrepend .. "§o" end
        if uline then toPrepend = toPrepend .. "§n" end
        msg = msg:gsub("§%-sthrough§", "§r" .. toPrepend, 1)
      end
    end
  end

  for st in string.gmatch(msg, "§[%+%-][a-z]-§") do
    markdownStuff(msg, st)
  end

  return msg:gsub("§asterisk§", "*"):gsub("§tilde§", "~"):gsub("§underscore§", "_")
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
    -- print(jsonText.with)
    host:setChatMessage(1, nil)
    -- if jsonText.extra then
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

  self.__VARS["prevText"] = rawText
  self.__VARS["messageCount"] = 1
  return jsonText, rawText
end, "BUILTIN.FILTER_SPAM", 5)

BunnyChatUtils:register(function(self, jsonText, rawText)
  if jsonText[#jsonText] and jsonText[#jsonText].text and tostring(jsonText[#jsonText].text):match("^https?://%S+$") then
    local link = jsonText[#jsonText].text
    jsonText[#jsonText].clickEvent = {
      action = "open_url",
      value = link
    }
    jsonText[#jsonText].color = "aqua"
  end
  return jsonText, rawText
end, "BUILTIN.LINKS", 2)

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

  table.insert(newTxt, jsonText)

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

BunnyChatUtils:register(function(self, chatJson, rawText)
  if chatJson.translate then
    if chatJson.translate == "chat.type.text" then
      local plr = chatJson.with[1]

      local msg = self.formatMarkdown(chatJson.with[2])

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
            text = " >> ",
            color = "gray",
            bold = true,
          },
          ((type(msg) == "table" and msg) or 
          {
            text = msg,
            color = "white",
            bold = false,
          } or msg)
        } --[[@as TextJsonComponent]]
      else
        chatJson = {
          {
            text = plr,
            color = "white",
            bold = false,
          },
          {
            text = " >> ",
            color = "gray",
            bold = true,
          },
          ((type(msg) == "table" and msg) or 
          {
            text = msg,
            color = "white",
            bold = false,
          } or msg)
        } --[[@as TextJsonComponent]]
      end
    end

    goto done
  end

  ::done::

  return chatJson, rawText
end, "BUILTIN.USERNAMEFORMAT", 1)

BunnyChatUtils:register(function(self, chatJson, rawText)
  if chatJson.translate then
    if chatJson.translate == "chat.type.team.sent" then
      local dispName = chatJson.with[1].with

      local plr = chatJson.with[2]

      local msg = self.formatMarkdown(chatJson.with[3])

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
            text = " >> ",
            color = "gray",
            bold = true,
          },
          plr,
          {
            text = " >> ",
            color = "gray",
            bold = true,
          },
          {
            text = msg,
            color = "white",
            bold = false,
          },
        } --[[@as TextJsonComponent]]
      else
        chatJson = {
          {
            text = plr,
            color = "white",
            bold = false,
          },
          {
            text = " >> ",
            color = "gray",
            bold = true,
          },
          {
            text = msg,
            color = "white",
            bold = false,
          },
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
            text = " >> ",
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
            text = " >> ",
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

local modelWorld = models:newPart("TKBunnyChatUtilsWorld", "WORLD")
function events.world_render(delta)
  players = world:getPlayers()

  for k, v in pairs(chatMessageList) do
    if not players[k] then
      chatMessageList[k] = nil
      ---@diagnostic disable-next-line: discard-returns
      modelWorld:newText((type(k) == "table" and k.text) or k)
      goto continue
    end

    if not (v.timestamp + (4*1000) <= client:getSystemTime()) then
      modelWorld:newText(k):text(v.message):setPos((players[k]:getPos(delta) + vec(0, 2.5, 0)) * 16):setAlignment("CENTER"):scale(0.3):setRot(client:getCameraRot() - 180):setBackgroundColor()
    else
      ---@diagnostic disable-next-line: discard-returns
      modelWorld:newText(k)
    end
    ::continue::
  end
end

return BunnyChatUtils
