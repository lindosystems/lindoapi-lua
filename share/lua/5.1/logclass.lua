#!/usr/bin/env lua
--
-- logclass.lua
--
-- Copyright (c) 2016 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local class = require ('middleclass')

local logclass = class('logclass')
local paths = require('paths')
assert(paths)
local round = function(x, increment)
  increment = increment or 1
  x = x / increment
  return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end

local _tostring = tostring

local tostring = function(...)
  local t = {}
  for i = 1, select('#', ...) do
    local x = select(i, ...)
    if type(x) == "number" then
      x = round(x, .01)
    end
    t[#t + 1] = _tostring(x)
  end
  return table.concat(t, " ")
end



local modes = {
  { name = "trace", color = "\27[34m", },       --blue
  { name = "debug3", color = "\27[38;5;79m", }, --cyanish3
  { name = "debug2", color = "\27[38;5;87m", }, --cyanish2
  { name = "debug", color = "\27[36m", },       --cyan
  { name = "info3",  color = "\27[38;5;44m", }, --greenish3
  { name = "info2",  color = "\27[38;5;40m", }, --greenish2
  { name = "info",  color = "\27[32m", },       --green
  { name = "capi", color = "\27[38;5;225m", },
  { name = "warn",  color = "\27[33m", },  
  { name = "error", color = "\27[31m", },
  { name = "fatal", color = "\27[35m", },  
  { name = "critc", color = "\27[48;5;238m\27[38;5;202m", }, -- gray background with light gray text  
}

---
-- Initialize a new livefeed instance
-- @param exchange An exchange
-- @param verb A verbosity level  
function logclass:initialize(name,loglevel,msdos)
  self.name = name or 'unnamed'
  self.usecolor = not msdos
  if paths.is_msdos and paths.is_msdos() then self.usecolor=false end

  --self.usecolor = true --override
  
  self.outfile = nil
  self.level = loglevel or "info"
  self.showlines = false
  self.levels = {}
  local levels = self.levels
  for i, v in ipairs(modes) do
    levels[v.name] = i
  end    

  for i, x in ipairs(modes) do
    local nameupper = x.name:upper()    
    self[x.name] = function(fmt,...)      
      -- Return early if we're below the log level
      if i < levels[self.level] then
        return
      end
      if fmt:find("no value") then
        traceback()
        if not (...) then
          print("Bad ... value, it is nil")
        end  
        io.read()
      end
      local msg = sprintf(fmt,...) --tostring(...)
      local info, lineinfo = nil, ""
      if self.showlines then 
        info = debug.getinfo(2, "Sl")
        lineinfo = info.short_src .. ":" .. info.currentline
      end
  
      -- Output to console
      --[[
      print(string.format("%s[%-6s%s]%s %s: %s",
                          self.usecolor and x.color or "",
                          nameupper,
                          os.date("%H:%M:%S"),
                          self.usecolor and "\27[0m" or "",
                          lineinfo,
                          msg))
      --                 ]]
      assert(nameupper)
      assert(lineinfo)
      assert(msg)
      local dtstr=os.date("!%H:%M:%S")
      assert(dtstr)
      printf("%s[%-6s%s]%s%s: %s",
                          self.usecolor and x.color or "",
                          nameupper,
                          dtstr,
                          self.usecolor and "\27[0m" or "",
                          lineinfo,
                          msg)                              
      -- Output to log file
      if self.outfile then
        local fp = io.open(self.outfile, "a")
        local str = string.format("[%-6s%s] %s: %s\n",
                                  nameupper, os.date(), lineinfo, msg)
        fp:write(str)
        fp:close()
      end
    end
  end        
end

return logclass
