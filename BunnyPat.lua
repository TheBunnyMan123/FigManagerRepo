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

local eventLibExists, eventLib = pcall(require, ....."/BunnyEventLib")
local baseBoundingBox = vec(0.6, 1.8, 0.6)

if not eventLibExists then
   eventLib = {}
   eventLib.newEvent = function()
      return {
         _registered = {},
         register = function(self, func)
            table.insert(self._registered, func)
         end,
         invoke = function(self, ...)
            for _, v in pairs(self._registered) do
               v(...)
            end
         end
      }
   end
end

---@alias eventTable {ON_PAT: Event, ON_UNPAT: Event, TOGGLE_PAT: Event, WHILE_PAT: Event, ONCE_PAT: Event}

---@type eventTable
local patEvents = eventLibExists and eventLib.newEvents() or {}
patEvents.ON_PAT = eventLib.newEvent() -- Runs when you start being patted func()
patEvents.ON_UNPAT = eventLib.newEvent() -- Runs when you stop being patted func()
patEvents.TOGGLE_PAT = eventLib.newEvent() -- Runs when you start or stop being patted func(bool)
patEvents.WHILE_PAT = eventLib.newEvent() -- Runs every tick you are being patted func(patters)
patEvents.ONCE_PAT = eventLib.newEvent() -- Runs each time someone pats you func(entity)

---@type eventTable
local headPatEvents = eventLibExists and eventLib.newEvents() or {}
headPatEvents.ON_PAT = eventLib.newEvent() -- Runs when you start being patted func(pos)
headPatEvents.ON_UNPAT = eventLib.newEvent() -- Runs when you stop being patted func(pos)
headPatEvents.TOGGLE_PAT = eventLib.newEvent() -- Runs when you start or stop being patted func(bool, pos)
headPatEvents.WHILE_PAT = eventLib.newEvent() -- Runs every tick you are being patted func(patters, pos)
headPatEvents.ONCE_PAT = eventLib.newEvent() -- Runs each time someone pats you func(entity, pos)

local particlesexist, bunnyparticles = pcall(require, ....."/BunnyParticles")

local pats = 0
local config = {
   particle = "heart", -- If you have my particle lib check the below if statement
   velocity = vec(0, 3, 0),

   patpatHoldTime = 3, -- Amount of time before pats when holding down right click
   unsafeVariables = false, -- Vectors and other things inside avatar vars can be unsade
   holdTime = 10, -- The amount of time before you stop being patted
   noOffset = false, -- Don't offest by player pos. useful for laggy networks
   patRange = 10, -- Patpat range
}

if particlesexist then
   config.particle = bunnyparticles.newParticle({
      textures:fromVanilla("goldheart_2", "minecraft:textures/particle/goldheart_2.png"),
      textures:fromVanilla("goldheart_1", "minecraft:textures/particle/goldheart_1.png"),
      textures:fromVanilla("goldheart_0", "minecraft:textures/particle/goldheart_0.png")
   }, 25, vec(0, 3, 0), 0.85)
else
   config.velocity = config.velocity / 16
end
local lib = {}

local myPatters = {}
local myHeadPatters = {}

local function getVarsFromHead(block)
   if block.id == "minecraft:player_head" or block.id == "minecraft:player_wall_head" then
      local entityData = block:getEntityData()
      if entityData then
         local skullOwner = entityData.SkullOwner and entityData.SkullOwner.Id and client.intUUIDToString(table.unpack(entityData.SkullOwner.Id))
         if skullOwner then
            return world.avatarVars()[skullOwner] or {}
         end
      end
   end
end

local function pat(target, overrideBox, overridePos, id)
   if not player:isLoaded() then return end
   local targetInfo, noHearts
   if type(target) == "string" then
      target = world.getEntity(target)
      if not target then return end

      local targetPetpetFunc = target:getVariable("petpet")
      targetInfo = {
         pos = target:getPos(),
         box = (config.unsafeVariables and target:getVariable("patpat.boundingBox")) or target:getBoundingBox()
      }
      noHearts = target:getVariable("patpat.noHearts")

      if targetPetpetFunc then
         pcall(targetPetpetFunc, avatar:getUUID(), config.patpatHoldTime * 1.5)
      end
   elseif type(target) == "Vector3" then
      target = world.getBlockState(target + (config.noOffset and player:getPos() or 0))
      if target then
         targetInfo = {
            pos = target:getPos() + vec(0.5, 0, 0.5),
            box = vec(0.7, 0.7, 0.7)
         }
      else
         return
      end

      local vars = getVarsFromHead(target)
      if vars then
         pcall(vars["petpet.playerHead"], avatar:getUUID(), config.patpatHoldTime * 1.5, targetInfo.pos:unpack())

         if vars["patpat.noHearts"] then
            return
         end
      end
   elseif target == nil and overrideBox then
      targetInfo = {
         box = overrideBox,
         pos = overridePos + (config.noOffset and player:getPos() or 0)
      }
      avatar:store("bunnypat.id", id)
      if not id then
         avatar:store("bunnypat.id", "")
      end
   else
      return
   end

   local succ, err = pcall(figuraMetatables.Vector3.__index, targetInfo.box, "xyz")
   if succ then
      targetInfo.box = err
   else
      return
   end
   local halfBox = targetInfo.box / 2

   local box = targetInfo.box:copy():applyFunc(function(val) return val * math.random() end)
   local particlePos = targetInfo.pos + box.xyz - halfBox.x_z

   if not noHearts then
      if type(config.particle) == "string" then
         particles:newParticle(config.particle, particlePos, config.velocity):setVelocity(config.velocity)
      else
         config.particle:setPos(particlePos):setVelocity(config.velocity * ((math.random() / 5) + 0.9)):spawn()
      end
   end
end

function pings.pat(uuidint1, uuidint2, uuidint3, uuidint4)
   if type(uuidint1) == "number" then
      pat(client.intUUIDToString(uuidint1, uuidint2, uuidint3, uuidint4))
   else
      pat(uuidint1, uuidint2, uuidint3, uuidint4)
   end
end

local petpetFunc = function(uuid, timer)
   pats = pats + 1
   if not myPatters[uuid] then
      patEvents.ON_PAT:invoke()
      patEvents.TOGGLE_PAT:invoke(true)
   end
   myPatters[uuid] = math.clamp(timer, config.holdTime, 100)

   local entity = world.getEntity(uuid)
   if entity then
      patEvents.ONCE_PAT:invoke(entity)
   end
end
local headPatFunc = function(uuid, timer, x, y, z)
   if not x or not y or not z then
      return
   end
   local pos = vectors.vec3(x, y, z)
   local index = tostring(pos:copy():floor())
   
   myHeadPatters[index] = myHeadPatters[index] or {}
   local patters = myHeadPatters[index]

   if not patters[uuid] then
      headPatEvents.ON_PAT:invoke(pos:copy():floor())
      headPatEvents.TOGGLE_PAT:invoke(true, pos:copy():floor())
   end
   patters[uuid] = math.clamp(timer, config.holdTime, 100)
   
   local entity = world.getEntity(uuid)
   if entity then
      headPatEvents.ONCE_PAT:invoke(entity, pos:copy():floor())
   end
end

local lastPat = 0
local tick = 0

local right = keybinds:fromVanilla("key.use")

function pings.clearId()
   avatar:store("bunnypat.id", "")
end

local getTargetedEntity = function()
   local start = player:getPos():add(0, player:getEyeHeight()):add(renderer:getEyeOffset())

   local entity
   
   if config.patRange <= 20 then
      entity =  player:getTargetedEntity(config.patRange)
   else
      entity = raycast:entity(start, start + (player:getLookDir() * config.patRange), function(e) return e~=player end)
   end

   if not entity then
      if config.unsafeVariables then
         local pPos = player:getPos()
         local aabbs = {}
         local aabbMap = {}

         for _, v in pairs(world.getEntities(pPos - config.patRange, pPos + config.patRange)) do
            if (v ~= player) and v:getVariable("patpat.boundingBox") then
               local halfBox = v:getVariable("patpat.boundingBox")
               local pos = v:getPos()

               local aabb = {
                  pos - halfBox.x_z,
                  pos + halfBox
               }

               table.insert(aabbs, aabb)
               aabbMap[aabb] = v
            end
         end

         local hit = raycast:aabb(start, start + (player:getLookDir() * config.patRange), aabbs)

         if hit then
            return aabbMap[hit]
         end

      end
      return
   end
   
   if config.unsafeVariables and entity:getVariable("patpat.boundingBox") then
      local halfBox = entity:getVariable("patpat.boundingBox")
      local pos = entity:getPos()

      local aabb = {
         pos - halfBox.x_z,
         pos + halfBox
      }

      local hit = raycast:aabb(start, start + (player:getLookDir() * config.patRange), {aabb})

      if hit then
         return entity
      end
   else
      return entity
   end
end
local getTargetedBlock = function()
   if config.patRange <= 20 then
      return player:getTargetedBlock(true, config.patRange)
   end

   local start = player:getPos():add(0, player:getEyeHeight()):add(renderer:getEyeOffset())

   return raycast:block(start, start + (player:getLookDir() * config.patRange))
end

local function compileVec3(str)
   local x, y, z = str:match("^{(%-?[0-9.]+), (%-?[0-9.]+), (%-?[0-9.]+)}$")

   return vec(tonumber(x), tonumber(y), tonumber(z))
end

function events.WORLD_TICK()
   if (not player:isLoaded() or not player:isSwingingArm()) and not host:isHost() then
      avatar:store("bunnypat.id", "")
   end

   for index, headPatters in pairs(myHeadPatters) do
      local patted = false
      local pos = compileVec3(index)

      for uuid, time in pairs(headPatters) do
         if time <= 0 then
            headPatters[uuid] = nil
            headPatEvents.ON_UNPAT:invoke(pos:copy():floor())
            headPatEvents.TOGGLE_PAT:invoke(false, pos:copy():floor())
         else
            headPatters[uuid] = headPatters[uuid] - 1
            patted = true
         end
      end

      if patted then
         headPatEvents.WHILE_PAT:invoke(headPatters, pos:copy():floor())
      else
         headPatters[index] = nil
      end
   end

   local patted = false
   for uuid, time in pairs(myPatters) do
      if time <= 0 then
         patEvents.ON_UNPAT:invoke()
         patEvents.TOGGLE_PAT:invoke(false)
         myPatters[uuid] = nil
      else
         myPatters[uuid] = time - 1
         patted = true
      end
   end

   if patted then
      patEvents.WHILE_PAT:invoke(myPatters)
   end

   if (player:isLoaded() and not right:isPressed() or not player:isSwingingArm()) and (player:getVariable("bunnypat.id") or "") ~= "" then
      pings.clearId()
   end

   tick = tick + 1
   if not right:isPressed() or not (player:isLoaded() and player:isSneaking()) then
      lastPat = -10
      return
   end

   if not (lastPat + config.patpatHoldTime <= tick) then
      return
   end

   if player:isLoaded() and host:isHost() then
      lastPat = tick
      local target = getTargetedEntity()
      local blockTarget = getTargetedBlock()

      local playerPos = player:getPos()
      local blockCloser

      if not target or not blockTarget then
         blockCloser = false
      else
         blockCloser = (blockTarget:getPos() - playerPos):length() < (target:getPos() - playerPos):length()
      end

      if target and not target:getVariable("patpat.noPats") and target:getVariable("petpet.yesPats") ~= false and not blockCloser then
         pings.pat(client.uuidToIntArray(target:getUUID()))
         host:swingArm()
      elseif blockTarget and (blockTarget.id:match("head") or blockTarget.id:match("skull")) then
         pings.pat(blockTarget:getPos() - (config.noOffset and player:getPos() or 0))
         host:swingArm()
      else
         if config.unsafeVariables then
            for _, v in pairs(world.avatarVars()) do
               if not v then return end
               local boxes = v["bunnypat.boxes"] or {}
               for _, w in pairs(boxes) do
                  w = {box = w.box, pos = w.pos, id = w.id}
                  if not w.box or not w.pos then
                     error("Invalid custom bounding box" .. toJson(w))
                  end

                  local succ1, err1 = pcall(figuraMetatables.Vector3.__index, w.box, "xyz")
                  local succ2, err2 = pcall(figuraMetatables.Vector3.__index, w.pos, "xyz")

                  if not succ1 or not succ2 then
                     return
                  end
                  w.box = err1
                  w.pos = err2

                  local halfBox = w.box / 2
                  local aabb = {{w.pos - halfBox.x_z, w.pos + vec(halfBox.x, w.box.y, halfBox.z)}}
                  local start = player:getPos()+ vec(0, player:getEyeHeight(), 0) + (renderer:getEyeOffset() or vectors.vec3())

                  local hit = raycast:aabb(start, start + (host:getReachDistance() * player:getLookDir()), aabb)

                  if hit then
                     host:swingArm()
                     pings.pat(nil, w.box, w.pos - (config.noOffset and player:getPos() or 0), w.id)
                  end
               end
            end
         end
      end
   end
end

avatar:store("petpet", petpetFunc)
avatar:store("petpet.playerHead", headPatFunc)

return patEvents, headPatEvents

