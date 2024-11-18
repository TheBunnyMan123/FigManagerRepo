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

local path = string.gsub(..., "/", ".")
local gnpath = string.gsub(path, "%..*$", ".") .. "GNamimates.GNUI"

local gnui = require(gnpath .. ".main")
local screen = gnui.getScreenCanvas()
local button = require(gnpath .. ".element.button")
local slider = require(gnpath .. ".element.slider")
local textField = require(gnpath .. ".element.textField")

---@alias ActionWheelPlusPlus.numberFunc fun(number: integer, self: Action)
---@alias ActionWheelPlusPlus.textFunc fun(text: string, self: Action)
---@alias ActionWheelPlusPlus.colorFunc fun(color: Vector3, self: ActionWheelPlusPlus.Page)
---@alias ActionWheelPlusPlus.radioFunc fun(option: any, self: ActionWheelPlusPlus.Page)

---@class ActionWheelPlusPlus.Page
local lib = {iter = 0, page = {}}
local pageHistory = {}
local currpage = {}

---Creates a new button on the action wheel page
---@param self ActionWheelPlusPlus.Page
---@param name string|table|table
---@param func Action.clickFunc
function lib.newButton(self, name, func)
  local succ, json = pcall(parseJson, name)
  name = (succ and json) or name

  if type(func) == "string" then error("syntax updated") end
  local new = button.new(screen)
    :setSize(100, 13)
    :setAnchor(1, 0)
    :setPos(-110, 10 + (13 * self.iter))
    :setText(name)
  new.PRESSED:register(func)
  self.page[toJson(name)] = new
  self.iter = self.iter + 1
  
  return new
end

---Creates a new button on the action wheel page
---@param self ActionWheelPlusPlus.Page
---@param name string|table
---@param func Action.toggleFunc
function lib.newToggle(self, name, func)
  local succ, json = pcall(parseJson, name)
  name = (succ and json) or name

  if type(func) == "string" then error("syntax updated") end
  
  local new = button.new(screen)
    :setAnchor(1, 0)
    :setSize(100, 13)
    :setPos(-110, 10 + (13 * self.iter))
    :setText(name)
    :setToggle(true)

  new.BUTTON_UP:register(function(state)
    func(false)
  end)
  new.BUTTON_DOWN:register(function()
    func(true)
  end)
  self.page[toJson(name)] = new

  self.iter = self.iter + 1

  return new
end

---Creates a new button on the action wheel page
---@param self ActionWheelPlusPlus.Page
---@param name string|table
---@param func ActionWheelPlusPlus.numberFunc
---@param min integer
---@param max integer
---@param step integer?
---@param default integer?
function lib.newNumber(self, name, func, min, max, step, default)
  local succ, json = pcall(parseJson, name)
  name = (succ and json) or name

  if type(func) == "string" then error("syntax updated") end

  local val = default or min
  self:newButton(name, function()
    func(val)
  end)
  local new = slider.new(false, min, max, step or 1, default or min, screen, true)
    :setAnchor(1, 0)
    :setSize(100, 13)
    :setPos(-110, 10 + (13 * self.iter))
  new.VALUE_CHANGED:register(func)
  new.VALUE_CHANGED:register(function(num) val=num end)
  self.page[toJson(name) .. "$$NUM$$"] = new
  
  self.iter = self.iter + 1
  
  return new
end
 
---Creates a new button on the action wheel page
---@param self ActionWheelPlusPlus.Page
---@param name string|table
---@param func ActionWheelPlusPlus.textFunc
---@param default string?
---@return ActionWheelPlusPlus.Page
function lib.newText(self, name, func, default)
  local succ, json = pcall(parseJson, name)
  name = (succ and json) or name

  local val = default or min
  self:newButton(name, function()
    func(val)
  end)
  local new = textField.new(screen)
    :setAnchor(1, 0)
    :setSize(100, 13)
    :setPos(-110, 10 + (13 * self.iter))
    :setText(default)
  new.TEXT_CHANGED:register(function(txt)
    val = txt
  end)
  self.page[toJson(name) .. "$$TEXT$$"] = new

  self.iter = self.iter + 1
  
  return new
end

---Creates a new button on the action wheel page
---@param self ActionWheelPlusPlus.Page
---@param name string|table
---@param func ActionWheelPlusPlus.radioFunc
---@param options any[]
---@param default any|nil
---@return ActionWheelPlusPlus.Page
function lib.newRadio(self, name, func, options, default)
  local succ, json = pcall(parseJson, name)
  name = (succ and json) or name

  local new = self:newPage(name)
  local option = default or options[1]

  for _, v in ipairs(options) do
    new:newButton(tostring(v), function()
      option = v
      func(option, new)
      currpage = pageHistory[#pageHistory-1]
    end)
  end

  return new
end

local pages = {}

---Creates a new page
---@param self ActionWheelPlusPlus.Page
---@param name string|table
function lib.newPage(self, name)
  local succ, json = pcall(parseJson, name)
  name = (succ and json) or name

  local npage = {}

  local new = setmetatable({iter = 0, page = npage}, {__index = lib})

  new:newButton("Return", function()
    currpage = pageHistory[#pageHistory - 1]
  end)

  self:newButton(name, function()
    pageHistory[#pageHistory+1] = currpage
    currpage = new
  end)

  table.insert(pages, new)

  return new
end

local mainPage = setmetatable({}, {
  __index = lib,
  page = {},
  iter = 0
})

table.insert(pages, mainPage)
pageHistory = {mainPage}

currpage = mainPage

function events.WORLD_RENDER()
  for _, v in pairs(pages) do
    for _, w in pairs(v.page) do
      w:setVisible(false)
    end
  end
  for _, v in pairs(currpage.page) do
    v:setVisible(true)
  end
end

return mainPage

