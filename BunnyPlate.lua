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
  local nameTask = nameHolder:newText("TEXT")
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
      perm = false
      oldTick = nameTick
    end
  end

  function events.WORLD_TICK()
    local compose = {{text = "${badges}"}}
    nameTick = ((nameTick + 1) % (#genGradient - 1)) + 1
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

    if ((perm or 0) < tick - 2) then
      table.insert(compose, {text = "\n", font = "default"})
    else
      table.insert(compose, {text = " ", font = "default"})
    end

    if not perm or (#permissionText == 0) then
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
    else
      table.insert(compose, {text = permissionText, color = "#FFFFFF", font = "default"})
    end

    nameplate.ALL:setText(toJson(compose))
    nameplate.ENTITY:setVisible(false)
   
    local isJson, extraJson = pcall(parseJson, extraText)

    if extraText and isJson and extraJson and extraText:match("^[%[{]") and extraJson.text ~= "" then
      table.insert(compose, {text="\n",font="default"})
      if extraJson[1] then
        for _, v in pairs(extraJson) do
          table.insert(compose, v)
        end
      else
        table.insert(compose, extraJson)
      end
    elseif extraText and extraText ~= "" and not isJson then
      table.insert(compose, {
        text = "\n" .. extraText,
        font = "default",
        color = "#888888"
      })
    end

    table.remove(compose, 1)
    if badgeIter == 0 then
      local txt = compose[1].text
      while txt ~= "\n" and not perm do
        txt = compose[1] and compose[1].text or "\n"
        table.remove(compose, 1)
      end
    end

    local scale = ((nameplate.ENTITY:getScale() or 1) * 0.4)
    if type(scale) == "number" then scale = vec(scale, scale, scale) end

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

    nameHolder:setPivot(((nameplate.ENTITY:getPivot() or vec(0, 2, 0))*16):copy():sub(0, (client.getTextHeight(toJson(compose))/2)*scale.y))
    nameTask
    :setScale(scale)
    :setPos(0, client.getTextHeight(toJson(compose)) / 2)
    :setLight(nameplate.ENTITY:getLight())
    :setBackgroundColor(nameplate.ENTITY:getBackgroundColor())
    :setText(toJson(compose))
    :setAlignment("CENTER")
    :setOutline(true)
  end

  return {
    setText = function(txt) text = txt end,
    setNameplateHolder = function(part) nameHolder=part;nameTask=part:newText("NAMEPLATE") end,
    setCustomBadge = function(name, badge, font, hover) customBadges[name] = {text = badge, font = font, hover = hover} end,
    setExtra = function(txt) extraText = txt end,
    setPermissionText = function(txt) permissionText = txt end,
    setGradient = function(tbl) genGradient = tbl end,
    getGradient = function() return genGradient end,
    setHoverJson = function(tbl) hoverJson = tbl end,
  }
end

