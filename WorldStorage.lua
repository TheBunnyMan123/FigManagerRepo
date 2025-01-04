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
-- to add the value of the byte. To avoid confusion strings are read in
-- reverse, essentially bit shifting what would be the end of a number
-- byte array to the beginning, second to last to the second, etc.
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
   for x = width, 0, -1 do
      for y = height, 0, -1 do
         str = str .. string.char(readByte(pos + vec(x, y, 0)))
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

local function writeByte(pos, byte)
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

   while (multMin == 1) and (multMin < 100) do
      local numData = #dta + shave

      for i = 2, (numData / 4) do
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
   for x = 0, (multMax - 1) do
      for y = 0, (multMin - 1) do
         writeByte(strOrigin + vec(x, y, 0), string.byte(dta, #dta - iter))

         iter = iter + 1
      end
   end

   host:sendChatCommand("setblock " .. tostring(origin):gsub("[{},]", "") .. " minecraft:gold_block")

   -- Write necessary metadata for reading the string
   writeByte(origin + vec(1, 0, 0), multMin)
   writeNumberByteArray(origin + vec(0, 1, 0), multMax, 2, 2)
   writeNumberByteArray(origin + vec(0, 3, 0), shave, 2, 2)
end

return {
   write = write,
   read = read
}

