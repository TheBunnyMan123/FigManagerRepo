local utils = {}

local function isType(var, expectedType, index)
   if type(var) ~= expectedType then
      return false, "Expected type " .. expectedType .. ", but got " .. type(var) .. " (argument " .. index .. ")"
   else
      return true
   end
end

function utils.urlFormat(str)
   str = tostring(str)

   return string.gsub(str, "([^%w])", function(c)
      return string.format("%%%02X", string.byte(c))
   end)
end

function utils.trimUUID(uuid)
   assert(isType(uuid, "string", 1))
   if #uuid ~= 36 then
      error("Invalid UUID")
   end

   return uuid:gsub("%-", "")
end
function utils.untrimUUID(uuid)
   assert(isType(uuid, "string", 1))
   if #uuid ~= 32 then
      error("Invalid UUID")
   end

   return uuid:sub(1, 8) .. "-" ..
   uuid:sub(9, 12) .. "-" ..
   uuid:sub(13, 16) .. "-" ..
   uuid:sub(17, 20) .. "-" .. uuid:sub(21, 32)
end

function utils.formatMarkdown(s)
   s = type(s) == "string" and s or ""
   local msg = string.gsub(s, "\\(.)", function(str)
      return "§" .. string.byte(str) .. "§"
   end)

   msg = msg .. " "

   local compose = {}

   local italic = false
   local bold = false
   local link = false
   local strikethrough = false
   local underlined = false

   local temp = ""
   local ptr = 1

   local function insert(tbl)
      if link then
         tbl.color = "aqua"
         tbl.underlined = true

         local text = tbl.text

         local match1, match2 = text:match("^%[(.-)%]%((.-)%)")

         if match2 then
            tbl.text = match1
         end

         if not match2 then match2 = text end

         tbl.clickEvent = {
            action = "open_url",
            value = match2
         }
         tbl.hoverEvent = {
            action = "show_text",
            value = {
               text = match2,
               color = "aqua",
               underlined = true
            }
         }

         table.insert(compose, tbl)
      else
         table.insert(compose, tbl)
      end
   end

   while #msg >= 1 do
      local char = string.sub(msg, 1, 1)
      local nextChar = string.sub(msg, 2, 2)

      local linkTxt

      if char == "*" then
         insert({
            text = temp:gsub("§(%d-)§", function(s) return (not string.char(s):match("[%*%[%]%(%)%~%_]") and "\\" or "") .. string.char(tonumber(s)) end),
            italic = italic,
            bold = bold,
            strikethrough = strikethrough,
            underlined = underlined,
            color = "white"
         })
         temp = ""
         char = ""
         if nextChar == "*" then
            msg = msg:gsub("^..", "")
            bold = not bold
         else
            msg = msg:gsub("^.", "")
            italic = not italic
         end
      end

      if char == "_" and nextChar == "_" then
         msg = msg:gsub("^..", "")
         insert({
            text = temp:gsub("§(%d-)§", function(s) return (not string.char(s):match("[%*%[%]%(%)%~%_]") and "\\" or "") .. string.char(tonumber(s)) end),
            italic = italic,
            bold = bold,
            strikethrough = strikethrough,
            underlined = underlined,
            color = "white"
         })
         char = ""
         temp = ""
         underlined = not underlined
      end

      if char == "~" and nextChar == "~" then
         msg = msg:gsub("^..", "")
         insert({
            text = temp:gsub("§(%d-)§", function(s) return (not string.char(s):match("[%*%[%]%(%)%~%_]") and "\\" or "") .. string.char(tonumber(s)) end),
            italic = italic,
            bold = bold,
            strikethrough = strikethrough,
            underlined = underlined,
            color = "white"
         })
         char = ""
         temp = ""
         strikethrough = not strikethrough
      end

      linkTxt = msg:match("^%[.-%]%(.-%)")
      if not linkTxt then linkTxt = msg:match("^(https?://.-) ") end
      if linkTxt then
         insert({
            text = temp:gsub("§(%d-)§", function(s) return (not string.char(s):match("[%*%[%]%(%)%~%_]") and "\\" or "") .. string.char(tonumber(s)) end),
            italic = italic,
            bold = bold,
            strikethrough = strikethrough,
            underlined = underlined,
            color = "white"
         })
         temp = ""
         link = true
         insert({
            text = linkTxt:gsub("§(%d-)§", function(s) return (not string.char(s):match("[%*%[%]%(%)%~%_]") and "\\" or "") .. string.char(tonumber(s)) end),
            italic = italic,
            bold = bold,
            strikethrough = strikethrough,
            underlined = underlined,
            color = "white"
         })

         link = false
         char = ""
      end

      ptr = ptr + 1
      if char == "" then ptr = ptr - 1 end

      temp = temp .. char
      if char ~= "" then
         msg = msg:gsub("^.", "")
      end

      if linkTxt and msg:match("^%[.-%]%(.-%)") then
         msg = msg:gsub("^%[.-%]%(.-%)", "")
      elseif linkTxt then
         msg = msg:gsub("^https?://.- ", " ")
      end
   end

   insert({
      text = temp:gsub("§(%d-)§", function(s) return (not string.char(s):match("[%*%[%]%(%)%~%_]") and "\\" or "") .. string.char(tonumber(s)) end),
      italic = italic,
      bold = bold,
      strikethrough = strikethrough,
      underlined = underlined,
      color = "white"
   })

   return compose
end

return utils

