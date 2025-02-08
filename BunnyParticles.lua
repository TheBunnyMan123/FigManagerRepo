local lib = {}

local function getParticleOffsetFromRotation(rot, pos, scale)
  pos = pos + (scale / vec(2, 2, 2))
  pos = vectors.rotateAroundAxis(rot.x, pos, vec(1, 0, 0))
  pos = vectors.rotateAroundAxis(rot.y, pos, vec(0, 1, 0))
  pos = vectors.rotateAroundAxis(rot.z, pos, vec(0, 0, 1))
  return pos
end

local mdl = models:newPart("TKBunny$Particles", "WORLD")
local particles = {}

function events.TICK()
   for k, v in pairs(particles) do
      particles[k].life = v.life + 1
      particles[k].oldPos = v.pos
      particles[k].pos = v.pos + v.vel
      particles[k].vel = v.vel * v.resistance

      for l, w in pairs(v.stages) do
         if v.life > (v.stageLifetime * (l-1)) then
            v.task:setTexture(w, w:getDimensions():unpack())
         end
      end

      if particles[k].life > v.lifetime then
         particles[k].task:remove()
         particles[k] = nil
      end
   end
end
function events.RENDER(delta)
   for _, v in pairs(particles) do
      local pos = math.lerp(v.oldPos, v.pos, delta)
      local rot = client.getCameraRot() - 180
      v.task:setLight(15):setPos((pos*16) + getParticleOffsetFromRotation(rot, vectors.vec3(), (v.task:getScale() or 1)*v.task:getSize().xy_))
      v.task:setRot(rot)
   end
end

local particleMetatable = {
   __index = {}
}

function particleMetatable.__index.setScale(self, num)
   self._scale = num

   return self
end

function particleMetatable.__index.setPos(self, x, y, z)
   local pos

   if type(x) == "number" then
      pos = vectors.vec3(x, y, z)
   else
      pos = x
   end

   self._pos = pos

   return self
end

function particleMetatable.__index.setAirResistance(self, resistance)
   self._resistance = resistance
end

function particleMetatable.__index.setLifetime(self, lifetime)
   self._lifetime = lifetime
end

function particleMetatable.__index.setVel(self, x, y, z)
   local vel

   if type(x) == "number" then
      vel = vectors.vec3(x, y, z)
   else
      vel = x
   end

   self._vel = vel/16

   return self
end
particleMetatable.__index.setVelocity = particleMetatable.__index.setVel

local particleIter = 0
function particleMetatable.__index.spawn(self)
   particleIter = particleIter + 1

   table.insert(particles, {
      oldPos = self._pos,
      pos = self._pos,
      task = mdl:newSprite("particle" .. particleIter):setScale(self._scale),
      lifetime = self._lifetime,
      life = 0,
      vel = self._vel,
      resistance = self._resistance,
      stages = self._stages,
      stageLifetime = self._lifetime / (#self._stages+1)
   })
end

function lib.newParticle(stages, lifetime, velocity, resistance)
   lifetime = lifetime or 10
   velocity = velocity or vec(0, 0, 0)
   resistance = resistance or 0.98

   return setmetatable({
      _stages = stages,
      _lifetime = lifetime,
      _pos = vectors.vec3(),
      _vel = velocity/16,
      _resistance = resistance,
   }, particleMetatable)
end

return lib

