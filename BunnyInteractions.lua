local config = {
  disableBlockInteractions = false, -- 
  enableUndefinedRegions = true, --
  hitboxComputationSpeed = 10 --
}

local line = require(.....".BunnyLineLib")

if false then
  ---@alias Interaction.Visibility "NONE"|"HITBOX"|"FULL"

  ---@class Interaction
  local interaction = {
    name = "",
    ---@type Interaction.Visibility
    visibility = "NONE",
    pos1 = vec(-1, -1, -1),
    pos2 = vec(1, 1, 1),
    pivot = vec(0, 0, 0),
    rot = vec(0, 0, 0)
  }
end

local vars = {
  version = "v1.3.0",
  pings = {
  },
  ---@type Interaction[]
  interactions = {}
}

local libs = {}

local interaction = {}

function interaction.isBeingTargeted(self, ray1, ray2)
  local ray1Final, ray2Final = self:getRotatedPoint(ray1), self:getRotatedPoint(ray2)
  
  local hit = raycast:aabb(ray1Final, ray2Final, {{
    self.pos1,
    self.pos2
  }})

  return hit and true or false
end

function libs.newInteraction(name)
  local new = setmetatable({}, {
    __index = function(self, k)
      if interaction[k] then
        return interaction[k]
      end

      if k:match("^set.") then
        local key = k:gsub("^set", ""):gsub("^.", string.lower)
        return function(slf, x, y, z)
          if y and z then x = vec(x, y, z) end
          slf[key] = x
          avatar:store("BunnyInteractions", vars)
          return slf
        end
      end
    end
  })

  for k, v in pairs(interaction) do
    new[k] = v
  end

  new.pivot = vec(0, 0, 0)
  new.pos1 = vec(-1, -1, -1)
  new.pos2 = vec(1, 1, 1)
  new.rot = vec(0, 0, 0)
  new:setName(name)

  table.insert(vars.interactions, new)

  return new
end

function interaction.getRotatedPoint(self, point)
  local off = point-self.pivot
  local final = off:copy()

  final = vectors.rotateAroundAxis(self.rot.z, off, vec(0, 0, 1))
  final = vectors.rotateAroundAxis(self.rot.y, final, vec(0, 1, 0))
  final = vectors.rotateAroundAxis(self.rot.x, final, vec(1, 0, 0))

  return final+self.pivot
end

avatar:store("BunnyInteractions.register", function(name, key, func)
  keybinds:of(name, key):setOnPress(func)
end)

---@param key Minecraft.keyCode
function interaction.setKey(self, key, func)
  local plr = client:getViewer()
  print(plr:getVariable())
  if plr:getVariable("BunnyInteractions.register") then
      print("testing")
    plr:getVariable("BunnyInteractions.register")(self.name, key, function()
      local start = player:getPos():add(0, plr:getEyeHeight(), 0):add(renderer:getEyeOffset())
      if self:isBeingTargeted(start, start+(5*plr:getLookDir())) then
        print("Pressed")
      end
    end)
  end
  return self
end

local vis = models:newPart("TKBunny$Interactions", "WORLD")

function events.RENDER()
  for _, var in pairs(world.avatarVars()) do
  for _, int in ipairs(var.BunnyInteractions and var.BunnyInteractions.interactions or {}) do
    if int.visibility == "HITBOX" then
      line.line(int:getRotatedPoint(int.pos1), int:getRotatedPoint(vec(int.pos1.x, int.pos1.y, int.pos2.z)), 3, vec(1, 1, 1), 12, 1)
      line.line(int:getRotatedPoint(int.pos1), int:getRotatedPoint(vec(int.pos1.x, int.pos2.y, int.pos1.z)), 3, vec(1, 1, 1), 12, 1)
      line.line(int:getRotatedPoint(int.pos1), int:getRotatedPoint(vec(int.pos2.x, int.pos1.y, int.pos1.z)), 3, vec(1, 1, 1), 12, 1)
      line.line(int:getRotatedPoint(int.pos2), int:getRotatedPoint(vec(int.pos2.x, int.pos2.y, int.pos1.z)), 3, vec(1, 1, 1), 12, 1)
      line.line(int:getRotatedPoint(int.pos2), int:getRotatedPoint(vec(int.pos2.x, int.pos1.y, int.pos2.z)), 3, vec(1, 1, 1), 12, 1)
      line.line(int:getRotatedPoint(int.pos2), int:getRotatedPoint(vec(int.pos1.x, int.pos2.y, int.pos2.z)), 3, vec(1, 1, 1), 12, 1)
      line.line(int:getRotatedPoint(vec(int.pos1.x, int.pos2.y, int.pos2.z)), int:getRotatedPoint(vec(int.pos1.x, int.pos1.y, int.pos2.z)), 3, vec(1, 1, 1), 12, 1)
      line.line(int:getRotatedPoint(vec(int.pos2.x, int.pos1.y, int.pos1.z)), int:getRotatedPoint(vec(int.pos2.x, int.pos2.y, int.pos1.z)), 3, vec(1, 1, 1), 12, 1)
      line.line(int:getRotatedPoint(vec(int.pos2.x, int.pos2.y, int.pos1.z)), int:getRotatedPoint(vec(int.pos1.x, int.pos2.y, int.pos1.z)), 3, vec(1, 1, 1), 12, 1)
      line.line(int:getRotatedPoint(vec(int.pos1.x, int.pos2.y, int.pos1.z)), int:getRotatedPoint(vec(int.pos1.x, int.pos2.y, int.pos2.z)), 3, vec(1, 1, 1), 12, 1)
      line.line(int:getRotatedPoint(vec(int.pos2.x, int.pos1.y, int.pos2.z)), int:getRotatedPoint(vec(int.pos1.x, int.pos1.y, int.pos2.z)), 3, vec(1, 1, 1), 12, 1)
      line.line(int:getRotatedPoint(vec(int.pos2.x, int.pos1.y, int.pos1.z)), int:getRotatedPoint(vec(int.pos2.x, int.pos1.y, int.pos2.z)), 3, vec(1, 1, 1), 12, 1) 
    end
  end
  end
end

return libs

