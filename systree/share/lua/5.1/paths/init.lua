--require 'libpaths'
local paths = tabox.paths()


local assert = assert
local debug = debug
local pcall = pcall
local type = type
local ipairs = ipairs
local os = os

function paths.is_win()
   return paths.uname():match('Windows')
end

function paths.is_mac()
   return paths.uname():match('Darwin')
end

if paths.is_win() then
   paths.home = os.getenv('HOMEDRIVE') or 'C:'
   paths.home = paths.home .. ( os.getenv('HOMEPATH') or '\\' )
   paths.sep = "\\"
else
   paths.home = os.getenv('HOME') or '.'
   paths.sep = "/"
end

function paths.is_msdos()   
  if not paths.is_win() then
    return false
  else
    if not os.getenv('SHELL') then
      return true
    else
      return false
    end
  end
end  
      

function paths.files(s, f)
   local d = paths.dir(s)
   local n = 0
   if type(f) == 'string' then
      local pattern = f
      f = function(file) return file:find(pattern) end
   elseif f and type(f) ~= 'function' then
      error("Expecting optional arg 2 to be function or string. Got : "..type(f))
   end
   f = f or function(file) return true end
   local n = 0
   return function()
      while true do
         n = n + 1
         if d == nil or n > #d then
            return nil
         elseif f(d[n]) then
            return d[n]
         end
      end
   end
end

function paths.iterdirs(s)
   return paths.files(s, 
      function(dir)
         return paths.dirp(paths.concat(s, dir)) and dir ~= '.' and dir ~= '..'
      end)
end
   
function paths.iterfiles(s)
   return paths.files(s, 
      function(file)
         return paths.filep(paths.concat(s, file)) and file ~= '.' and file ~= '..' 
      end)
end

function paths.thisfile(arg, depth)
   local s = debug.getinfo(depth or 2).source
   if type(s) ~= "string" then
      s = nil
   elseif s:match("^@") then     -- when called from a file
      s = paths.concat(s:sub(2))
   elseif s:match("^qt[.]") then -- when called from a qtide editor
      local function z(s) return qt[s].fileName:tostring() end 
      local b, f = pcall(z, s:sub(4));
      if b and f and f ~= "" then s = f else s = nil end
   end
   if type(arg) == "string" then
      if s then s = paths.concat(paths.dirname(s), arg) else s = arg end
   end 
   return s
end

function paths.dofile(f, depth)
   local s = paths.thisfile(nil, 1 + (depth or 2))
   if s and s ~= "" then
      f = paths.concat(paths.dirname(s),f)
   end
   return dofile(f)
end

function paths.rmall(d, more)
   if more ~= 'yes' then
      return nil, "missing second argument ('yes')"
   elseif paths.filep(d) then
      return os.remove(d)
   elseif paths.dirp(d) then
      for f in paths.files(d) do
         if f ~= '.' and f ~= '..' then
            local ff = paths.concat(d, f)
            local r0,r1,r2 = paths.rmall(ff, more)
            if not r0 then
               return r0,r1,ff
            end
        end
     end
     return paths.rmdir(d)
   else
     return nil, "not a file or directory", d
   end
end

function paths.findprogram(...)
   for _,exe in ipairs{...} do
      if paths.is_win() then
         if not exe:match('[.]exe$') then
            exe = exe .. '.exe'
         end
         local path, k, x = os.getenv("PATH") or "."
         for dir in path:gmatch('[^;]+') do
            x = paths.concat(dir, exe)
            if paths.filep(x) then return x end
         end
         local function clean(s)
            if s:match('^"') then return s:match('[^"]+') else return s end 
         end
         k = 'SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths\\' .. exe
         x = paths.getregistryvalue('HKEY_CURRENT_USER', k, '')
         if type(x) == 'string' then return clean(x) end
         x = paths.getregistryvalue('HKEY_LOCAL_MACHINE', k, '')
         if type(x) == 'string' then return clean(x) end
         k = 'Applications\\' .. exe .. '\\shell\\open\\command'
         x = paths.getregistryvalue('HKEY_CLASSES_ROOT', k, '')
         if type(x) == 'string' then return clean(x) end
      else
         local path = os.getenv("PATH") or "."
         for dir in path:gmatch('[^:]+') do
            local x = paths.concat(dir, exe)
            if paths.filep(x) then return x end
         end
      end
   end
   return nil
end

-- ### paths.read
--
-- Return the content of the file by reading the given `path` and `mode`.
--
-- - `path` is a string.
-- - `mode` is a string.
--
function paths.read(path, mode)
  mode = mode or '*a'
  local file, err = io.open(path, 'rb')
  if err then
    error(err)
  end
  local content = file:read(mode)
  file:close()
  return content
end

-- ### paths.write
--
-- Write to the file with the given `path`, `content` and `mode`.
--
-- - `path`    is a string.
-- - `content` is a string.
-- - `mode`    is a string.
--
function paths.write(path, content, mode)
  mode = mode or 'w'
  local file, err = io.open(path, mode)
  if err then
    error(err)
  end
  file:write(content)
  file:close()
end

-- ### file.copy
--
-- Copy the file by reading the `src` and writing it to the `dest`.
--
-- - `src`  is a string.
-- - `dest` is a string.
--
function paths.copy(src, dest)
  assert(paths.filep(src),"\n\nError: " .. src .. " not found\n")
  local content = paths.read(src)
  paths.write(dest, content)
end

-- ### file.move
--
-- Move the file by reading the `src` and writing it to the `dest`.
--
-- - `src`  is a string.
-- - `dest` is a string.
--
function paths.move(src,dest)
  assert(paths.filep(src),"\n\nError: " .. src .. " not found\n")
  paths.copy(src,dest)
  paths.rmall(src,"yes")
end

-- ### file.backup
--
-- Backup the file by reading the `src` and writing it to the `src~`.
--
-- - `src`  is a string.
--
function paths.backup(src)
  assert(paths.filep(src),"\n\nError: " .. src .. " not found\n")
  local dest = src .. "~"
  paths.move(src,dest)
end

return paths
