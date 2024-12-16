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
--]]

---@class TextComponentLib
local lib = {}
local style = {__type = "Style"}
---@class Style
---@field color string
---@field bold boolean
---@field italic boolean
---@field strikethrough boolean
---@field obfuscated boolean
---@field underlined boolean
---@field font string
styleIndex = {}
local component = {__type = "TextComponent"}
---@class TextComponent
---@field _text table
componentIndex = {}

style.__index = styleIndex
component.__index = componentIndex

local emptyComponent = {text=""}

---Returns a new component
---@param text string?
---@param starterStyle Style?
---@return TextComponent
function lib.newComponent(text, starterStyle)
   local new = {}

   if starterStyle then
      for k, v in pairs(starterStyle) do
         new[k] = v
      end
   end
   new.text = text or ""
   new.extra = {emptyComponent}

   return setmetatable({
      _text = new
   }, component)
end

---Creates a new style
---@return Style
function lib.newStyle()
   return setmetatable({
      color = "white",
      bold = false,
      italic = false,
      underlined = false,
      obfuscated = false,
      strikethrough = false,
      font = "minecraft:default"
   }, style)
end

---Sets the TextComponent's style
---@param styleToSet Style
---@return TextComponent
function componentIndex:setStyle(styleToSet)
   for k, v in pairs(styleToSet) do
      self._text[k] = v
   end

   return self
end
---Sets the TextComponent's text
---@param text string
---@return TextComponent
function componentIndex:setText(text)
   self._text.text = text
   return self
end
---Appends a TextComponent to the end of this one
---@param componentToAppend TextComponent
---@return TextComponent
function componentIndex:append(componentToAppend)
   table.insert(self._text.extra, componentToAppend._text)
   return self
end
function componentIndex:toJson()
   return toJson(self._text)
end

---Sets the style's font
---@param font string
---@return Style
function styleIndex:setFont(font)
   if type(font) ~= "string" then
      error("Font must be a string")
   end

   self.font = font
   return self
end
---Sets whether the style should be strikethrough
---@param bool boolean
---@return Style
function styleIndex:setStrikethrough(bool)
   self.obfuscated = bool and true
   return self
end
---Sets whether the style should be obfuscated
---@param bool boolean
---@return Style
function styleIndex:setObfuscated(bool)
   self.obfuscated = bool and true
   return self
end
---Sets whether the style should be underlined
---@param bool boolean
---@return Style
function styleIndex:setUnderlined(bool)
   self.underlined = bool and true
   return self
end
---Sets whether the style should be bold
---@param bool boolean
---@return Style
function styleIndex:setBold(bool)
   self.bold = bool and true
   return self
end
---Sets whether the style should be italic
---@param bool boolean
---@return Style
function styleIndex:setItalic(bool)
   self.italic = bool and true
   return self
end

---Sets the style's color
---@param color string|Vector3
---@return Style
function styleIndex:setColor(color)
   if type(color) == "string" then
      self.color = color
   elseif type(color) == "Vector3" then
      local maxVal = math.max(color:unpack())
      if maxVal > 255 then
         error("Color must be either RGB255, RGB1, HEX, or a built in minecraft color")
      elseif maxVal > 1 then
         self.color = "#" .. vectors.rgbToHex(color / 255)
      else
         self.color = "#" .. vectors.rgbToHex(color)
      end
   else
      error("Color must be either RGB255, RGB0, HEX, or a built in minecraft color")
   end
   return self
end

return lib

