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

---@class BunnyUI
---@field size Vector2
---@field elements unknown[]
---@field viewport ModelPart
local lib = {}

local instances = {}

local tasks = {}

local mouseDownKeybind = keybinds:of("mouseDown", "key.mouse.left", true)

---@alias BunnyUI.Anchor "topLeft"|"topRight"|"bottomLeft"|"bottomRight"
---@alias BunnyUI.Alignment "LEFT"|"CENTER"|"RIGHT"

---@class BunnyUI.Text
---@field color Vector3
---@field text string
---@field scale number
---@field fancy boolean
---@field position Vector2
---@field anchor BunnyUI.Anchor
---@field outline boolean
---@field outlineColor Vector3
---@field name string
---@field alignment BunnyUI.Alignment
---@field backgroundColor Vector3
---@field background boolean
---@field rotation number
local textFuncs = {}
textFuncs.__type = "BunnyUI.Text"
textFuncs.__index = function(t, i)
  return rawget(t, i) or textFuncs[i]
end

---Creates a new text
---@param name string
---@return BunnyUI.Text
function lib.newText(self, name)
  ---@class BunnyUI.Text
  local text = setmetatable({}, textFuncs)

  text.color = vec(1, 1, 1)
  text.text = "Lorem Ipsum"
  text.scale = 1
  text.fancy = false
  text.position = vec(0, 0)
  text.anchor = "topLeft"
  text.outline = false
  text.outlineColor = vec(0, 0, 0)
  text.name = name
  text.alignment = "LEFT"
  text.background = false
  text.rotation = 0
  text.parent = "NONE"
  
  self.elements[name] = text

  text.remove = function(self)
    tasks[self.name]:remove()
    tasks[self.name] = nil
    self.elements[self.name] = nil
  end
  local task = self.viewport:newText(name)
  tasks[name] = task:setLight(15)

  return text
end
function textFuncs:getSize()
  return vec(client.getTextWidth(self.text), client.getTextHeight(self.text)) * self.scale
end

---@class BunnyUI.TextButton
---@field color Vector3
---@field text string
---@field scale number
---@field fancy boolean
---@field position Vector2
---@field anchor BunnyUI.Anchor
---@field outline boolean
---@field outlineColor Vector3
---@field name string
---@field alignment BunnyUI.Alignment
---@field press function
local textButtonFuncs = {}
textButtonFuncs.__type = "BunnyUI.TextButton"
textButtonFuncs.__index = function(t, i)
  return rawget(t, i) or textButtonFuncs[i]
end

---Creates a text button
---@param name string
---@return BunnyUI.TextButton
function lib.newTextButton(self, name)
  ---@class BunnyUI.TextButton
  local textButton = setmetatable({}, textButtonFuncs)

  textButton.color = vec(1, 1, 1)
  textButton.text = "Lorem Ipsum"
  textButton.scale = 1
  textButton.fancy = false
  textButton.position = vec(0, 0)
  textButton.anchor = "topLeft"
  textButton.outline = false
  textButton.outlineColor = vec(0, 0, 0)
  textButton.name = name
  textButton.alignment = "LEFT"
  textButton.press = function()
  end
  textButton.pressed = false
  
  self.elements[name] = textButton

  textButton.remove = function(self)
    tasks[self.name]:remove()
    tasks[self.name] = nil
    self.elements[self.name] = nil
  end
  local task = self.viewport:newText(name)
     
  tasks[name] = task:setLight(15)
  return textButton
end
function textButtonFuncs:getSize()
  return vec(client.getTextWidth(self.text), client.getTextHeight(self.text)) * self.scale
end

---@class BunnyUI.TexturedButton
---@field texture Texture
---@field scale number
---@field position Vector2
---@field anchor BunnyUI.Anchor
---@field name string
---@field press function
---@field color Vector3|Vector4?
local texturedButtonFuncs = {}
texturedButtonFuncs.__type = "BunnyUI.TexturedButton"
texturedButtonFuncs.__index = function(t, i)
  return rawget(t, i) or texturedButtonFuncs[i]
end

---Create a new textured button
---@param name string
---@param texture Texture
---@return BunnyUI.TexturedButton
function lib.newTexturedButton(self, name, texture)
  ---@class BunnyUI.TexturedButton
  local texturedButton = setmetatable({}, texturedButtonFuncs)

  texturedButton.texture = texture
  texturedButton.scale = 1
  texturedButton.position = vec(0, 0)
  texturedButton.anchor = "topLeft"
  texturedButton.name = name
  texturedButton.press = function()
  end
  texturedButton.pressed = false

  texturedButton.remove = function(self)
    tasks[self.name]:remove()
    tasks[self.name] = nil
    self.elements[self.name] = nil
  end
  
  self.elements[name] = texturedButton

  tasks[name] = self.viewport:newSprite(name):setLight(15)

  return texturedButton
end
function texturedButtonFuncs:getSize()
  return (self.texture and self.texture:getDimensions() * self.scale) or vec(0, 0)
end

function lib.getSize(self)
  return self.size
end

---Calculate position 
---@param anchor BunnyUI.Anchor
---@param pos Vector2
local function calcPosition(anchor, pos, element, viewport)
  local offset = vec(0, 0, 0)
  pos = pos.xy_ + (viewport.pos or vec(0, 0, 0)).xyz
  
  if anchor == "topRight" then
    offset = offset + vec(viewport:getSize().x, 0, 0):sub(element:getSize().x)
    return offset + vec(pos.x * -1, pos.y, pos.z)
  elseif anchor == "bottomLeft" then
    offset = offset + vec(0, viewport:getSize().y, 0):sub(0, element:getSize().y)
    return offset + vec(pos.x, pos.y * -1, pos.z)
  elseif anchor == "bottomRight" then
    offset = offset + viewport:getSize().xy_:sub(element:getSize().xy_)
    return offset + (pos:mul(-1, -1, 1))
  else
    return offset + pos
  end
end

function events.WORLD_RENDER()
  for _, instance in pairs(instances) do
    instance.viewport:setPos(instance.pos)
    for _, v in pairs(instance.elements) do
      if type(v) == "BunnyUI.Text" then
        local textJson = {}
        if v.fancy then
          textJson = parseJson(v.text)
        else
          textJson = {
            text = v.text,
            color = "#" .. vectors.rgbToHex(v.color)
          }
        end

        local pos = calcPosition(v.anchor, v.position, v, instance)
        tasks[v.name]
        :setOutlineColor(v.outlineColor)
        :setOutline(v.outline)
        :setText(toJson(textJson))
        :setScale(v.scale)
        :setPos(-1 * pos:add(instance.pos))
        :setAlignment(v.alignment)
        :setBackgroundColor(v.background and v.backgroundColor or vec(0, 0, 0, 0))
        :setRot(type(v.rotation)=="number" and vec(0, 0, v.rotation) or v.rotation)
      elseif type(v) == "BunnyUI.TextButton" then
        local textJson = {}
        if v.fancy then
          textJson = parseJson(v.text)
        else
          textJson = {
            text = v.text,
            color = "#" .. vectors.rgbToHex(v.color)
          }
        end

        local pos = calcPosition(v.anchor, v.position, v, instance)

        tasks[v.name]
        :setOutlineColor(v.outlineColor)
        :setOutline(v.outline)
        :setText(toJson(textJson))
        :setScale(v.scale)
        :setPos(-1 * pos:add(instance.pos))
        :setAlignment(v.alignment)

        table.insert(tasks, task)
        
        if (client:getViewer():isSwingingArm() or mouseDownKeybind:isPressed()) and not v.pressed then
          v.pressed = true
          local mouseX, mouseY = client.getMousePos():unpack()
          local size = v:getSize() * client.getGuiScale()
          if string.upper(instance.viewport:getParentType()) ~= "HUD" and client:getViewer():isLoaded() then
            local viewportPos = instance.viewport:getPos() / 16
            size = v:getSize()
            pos = pos / 16
            pos = pos * -1
            local startPos = client:getViewer():getPos():add(0, client:getViewer():getEyeHeight())

            local aabb = {{viewportPos + pos.xy_, viewportPos + pos.xy_ + (v:getSize()/-16).xy_}}

            local hit = raycast:aabb(startPos, startPos + (client:getViewer():getLookDir() * 20), aabb)

            if hit then
              v.press()
            end
            return
          end
          local spos = (instance.pos*-1 + pos) * client:getGuiScale()

          local xCorrect = (mouseX >= spos.x) and (mouseX <= (spos.x + size.x))
          local yCorrect = (mouseY >= spos.y) and (mouseY <= (spos.y + size.y))
          if xCorrect and yCorrect then
            v.press()
          end
        elseif not (client:getViewer():isSwingingArm() or mouseDownKeybind:isPressed()) and v.pressed then
          v.pressed = false
        end
      elseif type(v) == "BunnyUI.TexturedButton" then
        local pos = calcPosition(v.anchor, v.position, v, instance)

        if v.texture then
        tasks[v.name]
          :setTexture(v.texture, v.texture:getDimensions():unpack())
          :setPos(-1 * (pos):add(0, 0, instance.pos.z))
          :setVisible(true)
          :setSize(v:getSize())
        end

        if (client:getViewer():isSwingingArm() or mouseDownKeybind:isPressed()) and not v.pressed then
          v.pressed = true
          local mouseX, mouseY = client.getMousePos():unpack()
          local size = v:getSize() * client.getGuiScale()
          if string.upper(instance.viewport:getParentType()) ~= "HUD" and client:getViewer():isLoaded() then
            local viewportPos = instance.viewport:getPos() / 16
            size = v:getSize()
            pos = pos / 16
            pos = pos * -1
            local startPos = client:getViewer():getPos():add(0, client:getViewer():getEyeHeight())

            local aabb = {{viewportPos + pos.xy_, viewportPos + pos.xy_ + (v:getSize()/-16).xy_}}

            local hit = raycast:aabb(startPos, startPos + (client:getViewer():getLookDir() * 20), aabb)

            if hit then
              v.press()
            end
            return
          end
          local spos = (instance.pos*-1 + pos) * client:getGuiScale()

          local xCorrect = (mouseX >= spos.x) and (mouseX <= (spos.x + size.x))
          local yCorrect = (mouseY >= spos.y) and (mouseY <= (spos.y + size.y))
          if xCorrect and yCorrect then
            v.press()
          end
        elseif not (client:getViewer():isSwingingArm() or mouseDownKeybind:isPressed()) and v.pressed then
          v.pressed = false
        end

        table.insert(tasks, task)
      end
    end
  end
end

---@class BunnyUIMaker
local finalLib = {}

local iter = 0
function finalLib.newViewport(parent, pos, size)
  iter = iter + 1
  size = size or client.getScaledWindowSize()
  local new = setmetatable({}, {
    __index = lib
  })
  new.size = size
  new.elements = {}
  new.pos = pos
  new.viewport = models:newPart("TKBunny$Viewport" .. iter, parent):setPos(pos)
  table.insert(instances, new)
  return new
end

return finalLib

