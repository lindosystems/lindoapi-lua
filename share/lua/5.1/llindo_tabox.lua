#!/usr/bin/env lua
--
-- LINDO API Lua Interface
-- 
-- 
-- $Id$

local LINDOAPI_LUA = os.getenv("LINDOAPI_LUA")
if not LINDOAPI_LUA then
  LINDOAPI_LUA="."
end
--
getos_name = function()
  local BinaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
  
  if BinaryFormat == "dll" then      
      return "Windows"      
  elseif BinaryFormat == "so" then
      return "Linux"
  elseif BinaryFormat == "dylib" then
      return "Darwin"
  end
  return nil
end
--print(package.cpath)
--print(package.path)
--os.exit(1)

---
---
getos_name_arch = function()
  local uname={}
  local raw_os_name, raw_arch_name = '', ''  
  -- LuaJIT shortcut
  if jit and jit.os and jit.arch then
    raw_os_name = jit.os
    raw_arch_name = jit.arch
  else
    -- is popen supported?
    local popen_status, popen_result = pcall(io.popen, "")
    if popen_status then
      popen_result:close()
      -- Unix-based OS
      raw_os_name = io.popen('uname -s','r'):read('*l')
      raw_arch_name = io.popen('uname -m','r'):read('*l')
      uname.s = raw_os_name
      uname.m = raw_arch_name      
    else
      -- Windows
      local env_OS = os.getenv('OS')
      local env_ARCH = os.getenv('PROCESSOR_ARCHITECTURE')
      if env_OS and env_ARCH then
        raw_os_name, raw_arch_name = env_OS, env_ARCH
      end      
    end
  end

  raw_os_name = (raw_os_name):lower()
  raw_arch_name = (raw_arch_name):lower()
  --print(raw_os_name,raw_arch_name)
  local os_patterns = {
    ['windows'] = 'Windows',
    ['linux'] = 'Linux',
    ['mac'] = 'Darwin',
    ['osx'] = 'Darwin',
    ['darwin'] = 'Darwin',
    ['^mingw'] = 'Windows',
    ['^cygwin'] = 'Windows',
    ['bsd$'] = 'BSD',
    ['SunOS'] = 'Solaris',
  }
  
  local arch_patterns = {
    ['^x86$'] = 'x86',
    ['i[%d]86'] = 'x86',
    ['amd64'] = 'x86_64',
    ['x64'] = 'x86_64',
    ['x86_64'] = 'x86_64',
    ['Power Macintosh'] = 'powerpc',
    ['^arm'] = 'arm',
    ['^mips'] = 'mips',
  }
  
  local require_patterns = {
    ['x86'] = "libtabox32",
    ['x86_64'] = "libtabox64",
    ['powerpc'] = "libtabox64",
    ['arm'] = "libtabox32",
    ['mips'] = "libtabox64",
  }

  local os_name, arch_name, require_name = 'unknown', 'unknown', 'unknown'

  for pattern, name in pairs(os_patterns) do
    if raw_os_name:match(pattern) then
      os_name = name
      break
    end
  end
  for pattern, name in pairs(arch_patterns) do
    if raw_arch_name:match(pattern) then
      arch_name = name
      require_name = require_patterns[name]
      break
    end
  end
  return os_name, arch_name, require_name, uname
end


--[[
package.path = package.path .. ";;" .. LINDOAPI_LUA .. "/apps/lua/?.lua"
package.path = package.path .. ";;" .. LINDOAPI_LUA .. "/apps/lua/dataViz/?.lua"
package.path = package.path .. ";;" .. LINDOAPI_LUA .. "/apps/lua/modules/?.lua"
package.path = package.path .. ";;" .. LINDOAPI_LUA .. "/apps/lua/3rdparty/?.lua"
package.path = package.path .. ";;" .. LINDOAPI_LUA .. "/apps/lua/3rdparty/?/init.lua"
]]
local arch_path
local raw_os_name, raw_os_arch, raw_require_name, uname

raw_os_name, raw_os_arch, raw_require_name, uname =  getos_name_arch()    
--print(raw_os_name, raw_os_arch, raw_require_name) -- Windows  x86 libtabox32       
if raw_os_name=="Windows" then
  if raw_os_arch:match"64" then
    arch_path = 'win64x86'
  else
    arch_path = 'win32x86'
  end
  package.cpath =  package.cpath .. ";" .. LINDOAPI_LUA ..  string.format("/lib/%s",arch_path) .. "/systree/lib/lua/5.1/?.dll" .. ";" ..  LINDOAPI_LUA ..  string.format("/bin/%s/?.dll",arch_path)
else -- non-windows
  if raw_os_name == "Linux" then
    if (raw_os_arch or ""):match"64" then
        arch_path = 'linux64x86'        
    else
        arch_path = 'linux32x86'            
    end
    package.cpath =  package.cpath .. ";" .. LINDOAPI_LUA ..  string.format("/lib/%s",arch_path) .. "/systree/lib/lua/5.1/?.so" .. ";" ..  LINDOAPI_LUA ..  string.format("/bin/%s/?.so",arch_path)
  elseif raw_os_name == "Darwin" then
    if (raw_os_arch or ""):match"64" then
        arch_path = 'osx64x86'
    else
        arch_path = 'osx32x86'
    end
    package.cpath =  package.cpath .. ";" .. LINDOAPI_LUA ..  string.format("/lib/%s",arch_path) .. "/systree/lib/lua/5.1/?.so" .. ";" ..  LINDOAPI_LUA ..  string.format("/bin/%s/?.dylib",arch_path) 
  else
    error("OS ".. raw_os_name .. " not supported!")
  end
end
package.path = package.path .. ";;" .. LINDOAPI_LUA .. string.format("/lib/%s",arch_path) .. "/systree/share/lua/5.1/?.lua"
package.path = package.path .. ";;" .. LINDOAPI_LUA .. string.format("/lib/%s",arch_path) .. "/systree/share/lua/5.1/?/init.lua"
require (raw_require_name)
local szkey=[[
  bnKf9IC6VzkK1XFPSs7ymoHigvi1hTGS4xj2P8k/Uh1YBNYOK54qabTHPPt8ng9J
  rL4U40/ZX4AfLjYJKMQwbu2Crlke7WHNv3qlNkDcGM4Mg8rhP6AwrOgup0PjAZHA
  9fOJGkVr8YzXVXrG5fDLu06Hi84yrswATAVG+G6QnOsaZl5aV8c04rcX0vfNKrhd
  H8hQ3MkA2pPZRJw6ftDKKcMm23JwIolCUlXnHxiRb4HZE1ybO54/Yj0mVbLimbXz
  Qzmcl637ngRbKEjArbY5EmwhVcL1v3fBNYhsd9AHxzdYAXO3sd/iXOYizlv3jPbg
  Cyu4K6bJMwRJFNP9wzIEvw==
]]
xta = tabox.env(szkey)
assert(xta,"\n\nError: failed to create a tabox environment.\n")

---
-- include class extensions
require 'tabox_ext.tbenv'
require 'tabox_ext.tbfield'
require 'tabox_ext.tbtable'
require 'tabox_ext.tbsim'
require 'tabox_ext.tbparam'
require 'tabox_ext.tbasset'
require 'tabox_ext.tbann'
require 'tabox_ext.tbsolver'
require 'tabox_ext.tbmpmodel'

require "llindo_helper"

local Lindo = require("llindo")

return Lindo



