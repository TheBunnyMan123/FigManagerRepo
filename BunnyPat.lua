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

if not eventLibExists then
   eventLib = {}
   eventLib.newEvent = function()
      return {
         _registered = {},
         register = function(self, func)
            table.insert(self._registered, func)
         end,
         invoke = function(self)
            for _, v in pairs(self._registered) do
               v()
            end
         end
      }
   end
end

local patEvents = eventLibExists and eventLib.newEvents() or {}
patEvents.ON_PAT = eventLib.newEvent() -- Runs when you start being patted
patEvents.ON_UNPAT = eventLib.newEvent() -- Runs when you stop being patted
patEvents.TOGGLE_PAT = eventLib.newEvent() -- Runs when you start or stop being patted
patEvents.WHILE_PAT = eventLib.newEvent() -- Runs every tick you are being patted
patEvents.ONCE_PAT = eventLib.newEvent() -- Runs each time someone pats you

local particlesexist, bunnyparticles = pcall(require, ....."/BunnyParticles")
print(particlesexist, bunnyparticles)
local pats = 0
local config = {
   particle = particles["heart"],
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
end
local lib = {}

local myPatters = {}

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

   targetInfo.box:applyFunc(function(val) return val * math.random() end)
   local particlePos = targetInfo.pos + targetInfo.box.xyz - halfBox.x_z

   if not noHearts then
      config.particle:setPos(particlePos):setVelocity(config.velocity * ((math.random() / 5) + 0.9)):spawn()
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
         
         for _, v in pairs(world.getEntities(pPos - config.patRange, pPos + config.patRange)) do
            if (v ~= player) and v:getVariable("patpat.boundingBox") then
               local halfBox = v:getVariable("patpat.boundingBox")
               local pos = v:getPos()

               local aabb = {
                  pos - halfBox.x_z,
                  pos + halfBox
               }

               local hit = raycast:aabb(start, start + (player:getLookDir() * config.patRange), {aabb})

               if hit then
                  return v
               end
            end
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

function events.TICK()
   if not player:isSwingingArm() and not host:isHost() then
      avatar:store("bunnypat.id", "")
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

   if (not right:isPressed() or not player:isSwingingArm()) and (player:getVariable("bunnypat.id") or "") ~= "" then
      pings.clearId()
   end

   tick = tick + 1
   if not right:isPressed() or not player:isSneaking() then
      lastPat = -10
      return
   end

   if not (lastPat + config.patpatHoldTime <= tick) then
      return
   end

   lastPat = tick
   local target = getTargetedEntity(1000)
   local blockTarget = getTargetedBlock(1000)

   if target and not target:getVariable("patpat.noPats") and target:getVariable("petpet.yesPats") ~= false then
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

avatar:store("petpet", petpetFunc)

return patEvents

