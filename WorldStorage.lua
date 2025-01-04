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

local one = "minecraft:stone" -- Bit 1
local zero = "minecraft:dirt" -- Bit 0

local fors = {}
local function for_(min, max, step, func)
   table.insert(fors, {
      max = max,
      step = step,
      func = func,
      curr = min
   })
end
function events.WORLD_TICK()
   for k, v in pairs(fors) do
      if v.curr > v.max then
         fors[k] = nil
      else
         v.func(v.curr)
         v.curr = v.curr + v.step
      end
   end
end

-- Example layout for width and height:
--
-- X: byte / bit
-- O: origin
-- byte: XXXXXXXX (along Z axis)
--
-- The byte array (2x2) above the origin is the width
-- The byte to the left is the height. Above that is
-- the amount of characters to shave off of the beginning.
-- This is necessary to allow for prime numbers
--
-- XX
-- XX
-- XX
-- XX
-- XO
--
-- Height byte array:
-- The numbers are the order in which they are read
-- When a byte is read in the byte array, the current integer is first
-- bit shifted left by 8, and then the byte is `bitwise or`ed in order
-- to add the value of the byte.
--
-- 42
-- 31

-- Reads a byte from the world
local function readByte(pos)
   local byte = 0

   for i = 7, 0, -1 do
      -- Shifts the byte left 1 and `bitwise or`s the read bit
      local block = world.getBlockState(pos + vec(0, 0, i))

      byte = bit32.lshift(byte, 1)
      byte = bit32.bor(byte, block:getID() == one and 1 or 0)
   end

   return byte
end

local function readNumberFromByteArray(pos, width, height)
   local int = 0

   width = width - 1
   height = height - 1

   -- Loops through all bytes in the array
   for x = 0, width do
      for y = 0, height do
         int = bit32.lshift(int, 8)
         int = bit32.bor(int, readByte(pos + vec(x, y, 0)))
      end
   end

   return int
end

local function readStringFromByteArray(pos, width, height, shave)
   local str = ""

   width = width - 1
   height = height - 1

   -- Loops through all bytes in the array
   for x = 0, width do
      for y = 0, height do
         str = string.char(readByte(pos + vec(x, y, 0))) .. str
      end
   end

   return str:sub(shave + 1, #str)
end

local function read(origin)
   local strShave = readNumberFromByteArray(origin + vec(0, 3, 0), 2, 2)
   local romWidth = readNumberFromByteArray(origin + vec(0, 1, 0), 2, 2)
   local romHeight = readByte(origin + vec(1, 0, 0))

   return readStringFromByteArray(origin + vec(2, 0, 0), romWidth, romHeight, strShave)
end

local function readToBufferOrStream(origin, buf)
   local shave = readNumberFromByteArray(origin + vec(0, 3, 0), 2, 2)
   local width = readNumberFromByteArray(origin + vec(0, 1, 0), 2, 2)
   local height = readByte(origin + vec(1, 0, 0))

   local bytes = (width * height) - shave

   width = width - 1
   height = height - 1

   local dtaOrigin = origin + vec(2, 0, 0)
   local iter = 0
   for x = 0, width do
      for y = 0, height do
         iter = iter + 1
         if iter > bytes then
            shave = shave - 1
         else
            buf:write(readByte(dtaOrigin + vec(x, y, 0)))
         end
      end
   end

   return buf
end

local function writeByte(pos, byte)
   byte = byte or 0

   for i = 0, 7 do
      local shifted = bit32.lshift(1, i)
      local banded = bit32.band(shifted, byte)

      host:sendChatCommand("setblock " .. tostring(pos + vec(0, 0, i)):gsub("[{},]", "") .. " " .. (banded ~= 0 and one or zero))
   end
end

local function writeNumberByteArray(pos, num, width, height)
   width = width - 1
   height = height - 1

   for x = width, 0, -1 do
      for y = height, 0, -1 do
         writeByte(pos + vec(x, y, 0), bit32.band(num, 255))

         num = bit32.rshift(num, 8)
      end
   end
end

local function write(origin, dta)
   local multMin, multMax = 1, #dta
   local shave = 0

   if #dta > 10000 then
      shave = (math.ceil(#dta / 1000) * 1000) - #dta
   elseif #dta > 1000 then
      shave = (math.ceil(#dta / 100) * 100) - #dta
   end

   local stack = 0
   while ((multMin == 1) and (multMin < 100) or (multMin < math.clamp(math.floor(#dta / 1000), 1, 100)) and stack < 100) do
      stack = stack + 1
      local numData = #dta + shave

      for i = 2, math.min(math.floor(math.sqrt(numData)), 150) do
         local div = numData / i

         if div == math.floor(div) then
            multMin = i
            multMax = div
         end
      end

      if multMin == 1 then
         shave = shave + 1
      end
   end

   if multMax < 30 then
      local temp = multMax
      multMax = multMin
      multMin = temp
   end

   dta = string.rep("\x00", shave) .. dta

   -- Write the string
   local iter = 0
   local strOrigin = origin + vec(2, 0, 0)
   for_(0, (multMax - 1), 1, function(x)
      for y = 0, (multMin - 1) do
         writeByte(strOrigin + vec(x, y, 0), string.byte(dta, #dta - iter))
         iter = iter + 1
      end
   end)

   host:sendChatCommand("setblock " .. tostring(origin):gsub("[{},]", "") .. " minecraft:gold_block")

   -- Write necessary metadata for reading the string
   writeByte(origin + vec(1, 0, 0), multMin)
   writeNumberByteArray(origin + vec(0, 1, 0), multMax, 2, 2)
   writeNumberByteArray(origin + vec(0, 3, 0), shave, 2, 2)
end

---Writes data from a buffer OR InputStream
---@param origin Vector3
---@param stream InputStream|Buffer
local function writeFromBufferOrStream(origin, stream)
   local available = stream:available()
   local multMin, multMax = 1, available
   local shave = 0

   if available > 10000 then
      shave = (math.ceil(available / 1000) * 1000) - available
   elseif available > 1000 then
      shave = (math.ceil(available / 100) * 100) - available
   end

   local stack = 0
   while ((multMin == 1) and (multMin < 100) or (multMin < math.clamp(math.floor(available / 1000), 1, 100)) and stack < 100) do
      stack = stack + 1
      local numData = available + shave

      for i = 2, math.min(math.floor(math.sqrt(numData)), 150) do
         local div = numData / i

         if div == math.floor(div) then
            multMin = i
            multMax = div
         end
      end

      if multMin == 1 then
         shave = shave + 1
      end
   end

   if multMax < 30 then
      local temp = multMax
      multMax = multMin
      multMin = temp
   end

   local dtaOrigin = origin + vec(2, 0, 0)
   local iter = 0
   for_(0, (multMax - 1), 1, function(x)
      for y = 0, (multMin - 1) do
         local byte = stream:read()
         writeByte(dtaOrigin + vec(x, y, 0), byte)

         iter = iter + 1
      end

      if x == (multMin - 1) then
         host:sendChatCommand("setblock " .. tostring(origin):gsub("[{},]", "") .. " minecraft:gold_block")
      end
   end)

   writeByte(origin + vec(1, 0, 0), multMin)
   writeNumberByteArray(origin + vec(0, 1, 0), multMax, 2, 2)
   writeNumberByteArray(origin + vec(0, 3, 0), shave, 2, 2)
end

return {
   write = write,
   writeFromBufferOrStream = writeFromBufferOrStream,
   read = read,
   readToBufferOrStream = readToBufferOrStream
}

