#!/usr/bin/env lua
-- Stack Table
-- Uses a table as stack, use <table>:push(value) and <table>:pop()
-- Lua 5.1 compatible

-- GLOBAL


-- Create a Table with stack functions


  -- stack table
  local t = {}
  -- entry table
  t._et = {}

  -- push a value on to the stack
  function t:push(...)
    if ... then
      local targs = {...}
      -- add values
      for _,v in ipairs(targs) do
        table.insert(self._et, v)
      end
    end
  end

  -- pop a value from the stack
  function t:pop(num)

    -- get num values from stack
    local num = num or 1

    -- return table
    local entries = {}

    -- get values into entries
    for i = 1, num do
      -- get last entry
      if #self._et ~= 0 then
        table.insert(entries, self._et[#self._et])
        -- remove last value
        table.remove(self._et)
      else
        break
      end
    end
    -- return unpacked entries
    return unpack(entries)
  end
  
  function t:remove(idx)
    if not idx or idx>#self._et or idx==0 then
      return t:pop()
    end
    if idx<0 then
      idx = #self._et+idx+1
    end
    local v = self._et[idx]
    table.remove(self._et,idx)
    return v
  end

  -- get entries
  function t:getn()
    return #self._et
  end
  
  function t:at(idx)
    if idx<0 then
      idx = #self._et+idx+1
    elseif idx==0 then
      idx = #self._et
    end    
    return self._et[idx] or nil
  end
  
  function t:pos(key)
    local pos 
    for i,v in ipairs(self._et) do
      if key==v then
        pos = i
        break
      end
    end  
    return pos
  end

  -- list values
  function t:list()
    for i,v in pairs(self._et) do
      print(i, v)
    end
  end
  
  return t


