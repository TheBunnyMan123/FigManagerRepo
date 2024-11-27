---@class BunnyPlate
local libs = {}
local colorCache = {}

local function colorToHex(col)
  if tostring(col):match("^#") then return col end

  if not colorCache[tostring(col)] then
    colorCache[tostring(col)] = ("#" .. vectors.rgbToHex(col))
  end
  
  return colorCache[tostring(col)]
end

local function stepGradient(color1, color2, steps)
  local colorDelta = (color2 - color1) / steps
  local generatedSteps = {}

  for i = 0, steps do
    table.insert(generatedSteps, color1 + (colorDelta * i))
  end

  return generatedSteps
end

local function gradient(steps, col1, col2, ...)
  local cols = {
    col1,
    col2,
    ...
  }

  local compose = {}
  local generated = {}

  local prevCol = cols[#cols]
  for k, v in pairs(cols) do
    for _, w in pairs(stepGradient(prevCol, v, steps)) do
      table.insert(generated, w)
    end
    prevCol = v
  end

  for k in pairs(generated) do
    generated[k] = generated[k] / 255
  end

  return generated
end

return function(steps, col1, col2, ...)
  local nameHolder = models:newPart("TKBunny$NameplateTask"):newPart("HOLDER", "CAMERA")
  local nameTask = nameHolder:newText("TEXT"):setLight(15)
  local plateCache = {}

  local hoverJson = {}

  local text = ""
  local permissionText = ""
  local extraText = ""
  local customBadges = {}

  col1 = col1 or vec(255, 255, 255)
  col2 = col2 or vec(128, 128, 128)

  local genGradient = gradient(steps, col1, col2, ...)

  local tick = 0
  function events.WORLD_TICK() tick = tick + 1 end

  local perm
  function events.RENDER(_, ctx)
    if ctx == "FIGURA_GUI" then perm = tick end
  end

  local nameTick = 0
  local oldTick = 0

  function events.WORLD_RENDER()
    if oldTick ~= nameTick then
      oldTick = nameTick
    end
  end

  function events.WORLD_TICK()
    nameTick = ((nameTick + 1) % (#genGradient - 1)) + 1
    local scale = ((nameplate.ENTITY:getScale() or 1) * 0.4)
    if type(scale) == "number" then scale = vec(scale, scale, scale) end

    local cacheIndex = toJson(customBadges)..toJson(extraText)
    plateCache[cacheIndex] = plateCache[cacheIndex] or {}
    plateCache[cacheIndex][nameTick] = plateCache[cacheIndex][nameTick] or {}

    if plateCache[cacheIndex][nameTick].plate then
      nameplate.ALL:setText(plateCache[cacheIndex][nameTick].plate)
      
      avatar:setColor(genGradient[nameTick])
      avatar:setColor(genGradient[nameTick], "dev")
      avatar:setColor(genGradient[nameTick], "donator")
      avatar:setColor(genGradient[nameTick], "contest")
      avatar:setColor(genGradient[nameTick], "translator")
      avatar:setColor(genGradient[nameTick], "immortalized")
      avatar:setColor(genGradient[nameTick], "discord_staff")
      avatar:setColor(genGradient[nameTick], "texture_artist")
      avatar:store("color", "#" .. vectors.rgbToHex(genGradient[nameTick]))
      avatar:store("ears_color", "#" .. vectors.rgbToHex(genGradient[nameTick]))
      avatar:store("horn_color", "#" .. vectors.rgbToHex(genGradient[nameTick]))
      avatar:store("halo_color", "#" .. vectors.rgbToHex(genGradient[nameTick]))

      local pivot = ((nameplate.ENTITY:getPivot() or vec(0, 2, 0))*16):copy()
      local height = scale.y*client.getTextHeight(plateCache[cacheIndex][nameTick].entity)

      nameHolder:setPivot(pivot:add(0, height+2))
      nameTask
      :setScale(scale)
      :setLight(nameplate.ENTITY:getLight())
      :setBackgroundColor(nameplate.ENTITY:getBackgroundColor())
      :setText(plateCache[cacheIndex][nameTick].entity)
      :setAlignment("CENTER")
      :setOutline(true)
      return
    end

    local compose = {{text = "${badges}"}}
    local badgeIter = 0
    for _, v in pairs(customBadges) do
      if v.text ~= "" then
        badgeIter = badgeIter + 1
      end
      table.insert(compose, {
        text = v.text,
        font = v.font,
        hoverEvent = {
          action = "show_text",
          value = v.hover
        }
      })
    end

    if badgeIter > 0 then
      table.insert(compose, {text="\n",font="default"})
    end
    table.insert(compose, " ")

    local iter = 0
    text:gsub("[\0-\x7F\xC2-\xFD][\x80-\xBF]*", function(s)
      table.insert(compose, {
        text = s,
        color = colorToHex(genGradient[((nameTick + iter) % (#genGradient - 1)) + 1]),
        font = "default",
        hoverEvent = {
          action = "show_text",
          value = hoverJson
        }
      })

      iter = iter + 1
    end)

    plateCache[cacheIndex][nameTick].plate = toJson(compose)
    nameplate.ALL:setText(toJson(compose))
    nameplate.ENTITY:setVisible(false)
   
    local isJson, extraJson = pcall(parseJson, extraText)
    extraJson = (type(extraJson) == "table" and extraJson) or {}

    if extraText and isJson and extraJson and extraText:match("^[%[{]") and extraJson.text ~= "" and (extraJson[1] or {}).text ~= "" then
      table.insert(compose, {text="\n",font="default"})
      if extraJson[1] then
        for _, v in pairs(extraJson) do
          table.insert(compose, v)
        end
      else
        table.insert(compose, extraJson)
      end
    elseif extraText and extraText ~= "" and extraJson.text ~= "" and (extraJson[1] or {}).text ~= "" and not isJson then
      table.insert(compose, {
        text = "\n" .. extraText,
        font = "default",
        color = "#888888"
      })
    end

    for i = 1, #compose do
      if compose[i].text == string.sub(text, 1, 1) then
        table.remove(compose, i-1)
        break
      end
    end

    avatar:setColor(genGradient[nameTick])
    avatar:setColor(genGradient[nameTick], "dev")
    avatar:setColor(genGradient[nameTick], "donator")
    avatar:setColor(genGradient[nameTick], "contest")
    avatar:setColor(genGradient[nameTick], "translator")
    avatar:setColor(genGradient[nameTick], "immortalized")
    avatar:setColor(genGradient[nameTick], "discord_staff")
    avatar:setColor(genGradient[nameTick], "texture_artist")
    avatar:store("color", "#" .. vectors.rgbToHex(genGradient[nameTick]))
    avatar:store("ears_color", "#" .. vectors.rgbToHex(genGradient[nameTick]))
    avatar:store("horn_color", "#" .. vectors.rgbToHex(genGradient[nameTick]))
    avatar:store("halo_color", "#" .. vectors.rgbToHex(genGradient[nameTick]))

    local pivot = ((nameplate.ENTITY:getPivot() or vec(0, 2, 0))*16):copy()
    local height = scale.y*client.getTextHeight(toJson(compose))

    plateCache[cacheIndex][nameTick].entity = toJson(compose):gsub("${badges}", "")
    nameHolder:setPivot(pivot:add(0, height+2))
    nameTask
    :setScale(scale)
    :setLight(nameplate.ENTITY:getLight())
    :setBackgroundColor(nameplate.ENTITY:getBackgroundColor())
    :setText(toJson(compose):gsub("${badges}", ""))
    :setAlignment("CENTER")
    :setOutline(true)
  end

  return {
    setText = function(txt) text = txt end,
    setNameplateHolder = function(part) nameHolder=part;nameTask=part:newText("NAMEPLATE"):setLight(15) end,
    setCustomBadge = function(name, badge, font, hover) customBadges[name] = {text = badge, font = font, hover = hover} end,
    setExtra = function(txt) extraText = txt end,
    setPermissionText = function(txt) permissionText = txt end,
    getGradient = function() return genGradient end,
    setHoverJson = function(tbl) hoverJson = tbl end,
  }
end

