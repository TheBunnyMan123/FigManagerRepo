--[[
              _   _         __          ___               _             
    /\       | | (_)        \ \        / / |             | |  _     _   
   /  \   ___| |_ _  ___  _ _\ \  /\  / /| |__   ___  ___| |_| |_ _| |_ 
  / /\ \ / __| __| |/ _ \| '_ \ \/  \/ / | '_ \ / _ \/ _ \ |_   _|_   _|
 / ____ \ (__| |_| | (_) | | | \  /\  /  | | | |  __/  __/ | |_|   |_|  
/_/    \_\___|\__|_|\___/|_| |_|\/  \/   |_| |_|\___|\___|_|            
by TheKillerBunny

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
--]]

---@alias ActionWheelPlusPlus.numberFunc fun(number: integer, self: Action)
---@alias ActionWheelPlusPlus.textFunc fun(text: string, self: Action)
---@alias ActionWheelPlusPlus.colorFunc fun(color: Vector3, self: ActionWheelPlusPlus.Page)
---@alias ActionWheelPlusPlus.radioFunc fun(option: any, self: ActionWheelPlusPlus.Page)

local mainPage = action_wheel:newPage("main")
---@class ActionWheelPlusPlus.Page
local lib = {page = mainPage}
local pageHistory = {}

---Creates a new button on the action wheel page
---@param self ActionWheelPlusPlus.Page
---@param name string
---@param item ItemStack|Minecraft.itemID
---@param func Action.clickFunc
---@return Action
function lib.newButton(self, name, item, func)
  local new = self.page:newAction()
    :setTitle(name)
    :setItem(item)
    :setOnLeftClick(func)
    :setColor(1, 0.5, 0.2)

  return new
end

---Creates a new button on the action wheel page
---@param self ActionWheelPlusPlus.Page
---@param name string
---@param item ItemStack|Minecraft.itemID
---@param func Action.toggleFunc
---@return Action
function lib.newToggle(self, name, item, func)
  local new = self.page:newAction()
    :setTitle(name)
    :setItem(item)
    :setOnToggle(func)
    :setColor(vec(1, 0.2, 0.2))
    :setToggleColor(vec(0.2, 1, 0.2))

  return new
end

---Creates a new button on the action wheel page
---@param self ActionWheelPlusPlus.Page
---@param name string
---@param item ItemStack|Minecraft.itemID
---@param func ActionWheelPlusPlus.numberFunc
---@param min integer
---@param max integer
---@param step integer?
---@param default integer?
---@return Action
function lib.newNumber(self, name, item, func, min, max, step, default)
  step = step or 1
  default = default or min
  local num = default

  local isJson, nameJson = pcall(parseJson, name)
  if not isJson then
    nameJson = {{text = name}}
  elseif not nameJson[1] then
    nameJson = {nameJson}
  end
  table.insert(nameJson, {
    text = " [" .. num .. "]",
    color = "white"
  })

  local new = self.page:newAction()
    :setTitle(toJson(nameJson))
    :setItem(item)
    :setColor(vec(0.2, 1, 1))
    :setOnScroll(function(dir, slf)
      if dir > 0 then
        num = math.clamp(num + step, min, max)
      else
        num = math.clamp(num - step, min, max)
      end

      nameJson[#nameJson].text = " [" .. num .. "]"

      slf:setTitle(toJson(nameJson))

      func(num, slf)
    end)
    :setOnLeftClick(function(slf)
      func(num, slf)
    end)

  return new
end

---Creates a new button on the action wheel page
---@param self ActionWheelPlusPlus.Page
---@param name string
---@param item ItemStack|Minecraft.itemID
---@param func ActionWheelPlusPlus.colorFunc
---@return ActionWheelPlusPlus.Page
function lib.newColor(self, name, item, func, default)
  local new = self:newPage(name, item)
  new.page:setAction(1, nil)

  local color = default * 255
  local colorTemp = color:copy()

  local function updateColor() end

  local r = new:newNumber("Red", "minecraft:red_dye", function(num, slf)
    colorTemp.x = num
    updateColor()
    slf:setColor(colorTemp.x__ / 255)
  end, 0, 255, 5, color.x):setColor(color.x__)
  local g = new:newNumber("Green", "minecraft:green_dye", function(num, slf)
    colorTemp.y = num
    updateColor()
    slf:setColor(colorTemp._y_ / 255)
  end, 0, 255, 5, color.y):setColor(color._y_)
  local b = new:newNumber("Blue", "minecraft:blue_dye", function(num, slf)
    colorTemp.z = num
    updateColor()
    slf:setColor(colorTemp.__z / 255)
  end, 0, 255, 5, color.z):setColor(color.__z)

  local cancel = new:newButton("Cancel", "minecraft:barrier", function()
    colorTemp = color:copy()
    updateColor()
    r:setColor(color.x__ / 255)
    g:setColor(color._y_ / 255)
    b:setColor(color.__z / 255)
    action_wheel:setPage(pageHistory[#pageHistory])
  end):setColor(color)
  local submit = new:newButton("Submit", "minecraft:white_dye", function()
    color = colorTemp:copy()
    cancel:setColor(color / 255)
    func(color / 255, new)
    new.action:setColor(color / 255)
    action_wheel:setPage(pageHistory[#pageHistory])
  end):setColor(colorTemp)

  updateColor = function()
    submit:setColor(colorTemp / 255)
  end

  new.action:setColor(color / 255)
  return new
end

 
---Creates a new button on the action wheel page
---@param self ActionWheelPlusPlus.Page
---@param name string
---@param item ItemStack|Minecraft.itemID
---@param func ActionWheelPlusPlus.textFunc
---@param default string?
---@return ActionWheelPlusPlus.Page
function lib.newText(self, name, item, func, default)
  local isJson, nameJson = pcall(parseJson, name)
  if not isJson then
    nameJson = {{text = name}}
  elseif not nameJson[1] then
    nameJson = {nameJson}
  end
  local str = default or ""
  table.insert(nameJson, {
    text = " [" .. str .. "]",
    color = "white"
  })

  local new = self.page:newAction()
    :setTitle(toJson(nameJson))
    :setItem(item)
    :setColor(0.2, 0.2, 1)
    :setOnRightClick(function(slf)
      func(str, slf)
    end)
    :setOnLeftClick(function(slf)
      printJson(toJson({
        {
          text = "[ActionWheelPlusPlus] ",
          color = "gray"
        },
        {
          text = "Your next message in chat will be the new value",
          color = "white"
        }
      }))
      events.CHAT_SEND_MESSAGE:register(function(msg)
        str = msg
        func(str, slf)
        nameJson[#nameJson].text = " [" .. str .. "]"
        slf:setTitle(toJson(nameJson))
        events.CHAT_SEND_MESSAGE:remove("ActionWheelPlusPlus.SET_TEXT")
        return nil
      end, "ActionWheelPlusPlus.SET_TEXT")
    end)

  return new
end

---Creates a new button on the action wheel page
---@param self ActionWheelPlusPlus.Page
---@param name string
---@param item ItemStack|Minecraft.itemID
---@param func ActionWheelPlusPlus.radioFunc
---@param options any[]
---@param default any|nil
---@return ActionWheelPlusPlus.Page
function lib.newRadio(self, name, item, func, options, default)
  local new = self:newPage(name, item)
  new.page:setAction(1, nil)
  new.action:setColor(1, 1, 0.2)

  local option = default or options[1]

  local isJson, nameJson = pcall(parseJson, name)
  if not isJson then
    nameJson = {{text = name}}
  elseif not nameJson[1] then
    nameJson = {nameJson}
  end
  table.insert(nameJson, {
    text = " [" .. tostring(option) .. "]",
    color = "white"
  })

  new.action:setTitle(toJson(nameJson))

  for _, v in ipairs(options) do
    new:newButton(tostring(v), "minecraft:slime_ball", function()
      option = v
      func(option, new)
      action_wheel:setPage(pageHistory[#pageHistory])
      nameJson[#nameJson].text = " [" .. option .. "]"
      new.action:setTitle(toJson(nameJson))
    end)
  end
  new.action:setOnRightClick(function()
    func(option, new)
  end)

  return new
end

---Creates a new page
---@param self ActionWheelPlusPlus.Page
---@param name string
---@param item ItemStack|Minecraft.itemID
function lib.newPage(self, name, item)
  local new = action_wheel:newPage(name)

  new:newAction()
    :setItem("minecraft:arrow")
    :setColor(1, 0.2, 0.2)
    :setTitle(toJson({
      text = "← Return",
      color = "#FF3636"
    }))
    :setOnLeftClick(function()
      action_wheel:setPage(pageHistory[#pageHistory - 1])
    end)

  local action = self.page:newAction()
    :setTitle(name)
    :setItem(item)
    :setColor(1, 0.2, 1)
    :setOnLeftClick(function()
      table.insert(pageHistory, self.page)
      action_wheel:setPage(new)
    end)

  return setmetatable({action = action, page = new}, {__index = lib})
end

table.insert(pageHistory, mainPage)
action_wheel:setPage(mainPage)

return setmetatable({}, {
  __index = lib,
  page = mainPage
})

