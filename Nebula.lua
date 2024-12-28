---@alias Nebula.Reason {name: string, error: string}

---@class Nebula
---TheKillerBunny's Unit Testing Library
local lib = {}

---@type function[]
local tests = {}

---Adds a test to run
---The varargs should contain any values you want to pass into the test function
---@param name string
---@param func function
---@param args unknown[]
function lib.add(name, func, args)
   table.insert(tests, function()
      local success, error = pcall(func, table.unpack(args))

      if not success then
         return false, {name=name, error=error}
      else
         return true, {name=name, error="Test Succeeded"}
      end
   end)
end

---Runs all added tests
---Return values: failed, succeeded
---@return Nebula.Reason[]
---@return Nebula.Reason[]
function lib.run()
   local failed = {}
   local succeeded = {}

   for _, v in pairs(tests) do
      local success, reason = v()

      if not success then
         table.insert(failed, reason)
      else
         table.insert(succeeded, reason)
      end
   end

   return failed, succeeded
end

return lib

