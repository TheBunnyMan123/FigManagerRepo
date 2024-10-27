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

---@class BunnyLineLib
local funcs = {}

---Creates a particle line
---@param start Vector3
---@param endPos Vector3
---@param steps integer
---@param color Vector3
---@param lifetime number
---@param size? number
---@return Particle[]
function funcs.line(start, endPos, steps, color, lifetime, size)
  local genParticles = {}
  local len = (endPos - start):length()

  local stepSize = len / steps
  local stepVec = (endPos - start) / ((steps > 0 and steps) or 1)

  for i = 0, steps + 0.000001, stepSize do
    table.insert(genParticles, 
      particles:newParticle("minecraft:totem_of_undying", start + stepVec * i)
        :setGravity(0)
        :setColor(color)
        :setVelocity(0)
        :setScale(size or 0.5)
        :setLifetime(lifetime))
  end
  return genParticles
end

---Creates a box out of particle lines. Without a color it has r/g/b axes
---@param c1 Vector3
---@param c2 Vector3
---@param lifetime number
---@param color? Vector3
---@return Particle[][]
function funcs.box(c1, c2, lifetime, color)
  local x1, y1, z1 = math.min(c1.x, c2.x), math.min(c1.y, c2.y), math.min(c1.z, c2.z)
  local x2, y2, z2 = math.max(c1.x, c2.x), math.max(c1.y, c2.y), math.max(c1.z, c2.z)

  local genParticles = {}

  local function ln(start, target, clr)
    clr = clr or vec(1, 1, 1)
    return funcs.line(start, target, math.floor((start - target):length()) * 2, clr, lifetime)
  end
 
  table.insert(genParticles, ln(vec(x1, y1, z1), vec(x2, y1, z1), color or vec(1, 0.2, 0.2)))
  table.insert(genParticles, ln(vec(x1, y1, z2), vec(x2, y1, z2), color))
  table.insert(genParticles, ln(vec(x1, y1, z1), vec(x1, y1, z2), color or vec(0.2, 0.2, 1)))
  table.insert(genParticles, ln(vec(x2, y1, z1), vec(x2, y1, z2), color))
  table.insert(genParticles, ln(vec(x1, y2, z1), vec(x2, y2, z1), color))
  table.insert(genParticles, ln(vec(x1, y2, z2), vec(x2, y2, z2), color))
  table.insert(genParticles, ln(vec(x1, y2, z1), vec(x1, y2, z2), color))
  table.insert(genParticles, ln(vec(x2, y2, z1), vec(x2, y2, z2), color))
  table.insert(genParticles, ln(vec(x1, y1, z1), vec(x1, y2, z1), color or vec(0.2, 1, 0.2)))
  table.insert(genParticles, ln(vec(x1, y1, z2), vec(x1, y2, z2), color))
  table.insert(genParticles, ln(vec(x2, y1, z1), vec(x2, y2, z1), color))
  table.insert(genParticles, ln(vec(x2, y1, z2), vec(x2, y2, z2), color))

  return particles
end

return setmetatable({}, {
  __index = funcs,
  __type = "BunnyLineLib"
})

