local paths = require('paths')

---
-- Std C-printf with auto flush
printf = function(fmt, ...)    
    io.stdout:flush()   
    io.write(string.format(fmt, ...)) 
    io.stdout:flush()     
end

---
-- Same as printf with optional prefixes 
-- @remark requires 'xta.loglevel>0' to print
printf2 = function(fmt, ...)   
	if xta.loglevel>0 then
    io.stdout:flush() 
    local ts    
    local sbuf
    if hasbit(xta.printmode,xta.const.print_prefxlog) then
      ts=xta_epoch()    
      local dt,tm = xta:unixsecinv(ts) 
      sbuf = sprintf("XTL%02d|%08d-%06d| ",xta.loglevel,dt,tm)
    elseif hasbit(xta.printmode,xta.const.print_prefxlogts) then
      ts=xta_epoch()    
      sbuf = sprintf("XTL%02d|%10d| ",xta.loglevel,ts) 
    else
      sbuf=""
    end    
    if 0>1 then
      sbuf = sbuf .. string.format(fmt, ...)
		  io.write(sbuf) 
		  io.stdout:flush()
		else
		  glogger.info(fmt,...)
		end 
	end
end 

printf3 = function(fmt, ...)   
  if xta.loglevel>0 then
    io.stdout:flush() 
    local ts=xta_epoch()    
    local sbuf
    if hasbit(xta.printmode,xta.const.print_prefxlog) then
      local dt,tm = xta:unixsecinv(ts) 
      sbuf = sprintf("XTL%02d|%08d-%06d| ",xta.loglevel,dt,tm)
    elseif hasbit(xta.printmode,xta.const.print_prefxlogts) then
      sbuf = sprintf("XTL%02d|%10d| ",xta.loglevel,ts)    
    else
      sbuf = ""
    end
    io.write(sbuf,string.format(fmt, ...)) 
    io.stdout:flush() 
  end
end 

---
--
sprintf = function(fmt, ...)  
    local s=string.format(fmt, ...)
    return s 
end

---
-- @param t
-- @param name
-- @param lvl
--
function print_table3(t, name, depth)
    depth  = depth or 1
    --if #t==0 then return end
    local tab = string.rep("   ", depth)
    local tokey = tostring
    --tokey = keystr
    if name then
       io.write(string.format("%s\n",tab..tokey(name) .. " = {"))
       --io.write(string.format("%s\n",tab..name .. " = {"))
    else
       io.write(string.format("%s\n","{"))
    end
    for k, v in pairs(t) do
        if(type(v) == "table") then
            if k~="Assets"  then
              print_table3(v, k, depth+1)
            else
              io.write(string.format("%s\n",tab..tab..tokey(k).." = "..tostring(v)..","))
            end
        elseif(type(v) == "userdata") then
            io.write(string.format("%s\n",tab..tab..tokey(k).." = "..tostring(v)..","))
        else
            io.write(string.format("%s\n",tab..tab..tokey(k).." = "..tostring(v)..","))
        end
    end        
    if depth>1 then
        --printf("%s\n",tab..tab.."Data".." = ".."nil")
        io.write(string.format("%s\n",tab.."},"))
    else
        io.write(string.format("%s\n",tab.."}"))
    end
    io.stdout:flush()
end

--
--
function bit(p)
  assert(p,"\n\nError: bit arg #1 is nil\n")
  return 2 ^ (p - 1) -- 1-based indexing
end

---
--
function bitpos(n)
  assert(n,"\n\nError: bitpos arg #1 is nil\n")
  return math.floor(math.log(n)/math.log(2))
end

---
-- @brief
-- 
function dumpbits(x)
  for i=1,10 do
    printf("%2d, %s\n",i,hasbit(x,bit(i)))
  end
end

---
-- Typical call: if hasbit(x, bit(3)) then ...
-- 
function hasbit(x, p)
  --traceback()
  assert(x,"\n\nError: hasbit arg #1 is nil\n")
  assert(p,"\n\nError: hasbit arg #2 is nil\n")
  return x % (p + p) >= p
end

---
-- @brief
-- 
function setbit(x, p)
  assert(x,"\n\nError: hasbit arg #1 is nil\n")
  assert(p,"\n\nError: hasbit arg #2 is nil\n")
  return hasbit(x, p) and x or x + p
end

---
-- @brief
-- 
function clearbit(x, p)
  assert(x,"\n\nError: hasbit arg #1 is nil\n")
  assert(p,"\n\nError: hasbit arg #2 is nil\n")
  return hasbit(x, p) and x - p or x
end

---
--
--
function bitand(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
      if a % 2 == 1 and b % 2 == 1 then -- test the rightmost bits
          result = result + bitval      -- set the current bit
      end
      bitval = bitval * 2 -- shift left
      a = math.floor(a/2) -- shift right
      b = math.floor(b/2)
    end
    return result
end

--[[
-- Rudimentary string buffer
-- https://www.lua.org/pil/11.6.html
-- Usage:
    local s = stringBuffer()
    for line in io.lines() do
      addString(s, line .. "\n")
    end
    s = toString(s)
]]
function stringBuffer ()
  return {""}   -- starts with an empty string
end

---
-- Format and add
function addString (stack, fmt, ...)
  local s=string.format(fmt, ...)
  table.insert(stack, s)    -- push 's' into the the stack
  if 2>1 then
    for i=table.getn(stack)-1, 1, -1 do
      if string.len(stack[i]) > string.len(stack[i+1]) then
        break
      end
      stack[i] = stack[i] .. table.remove(stack)
    end
  end
end

---
-- No formats
function addStringx (stack, s)
  table.insert(stack, s)    -- push 's' into the the stack
  if 2>1 then
    for i=table.getn(stack)-1, 1, -1 do
      if string.len(stack[i]) > string.len(stack[i+1]) then
        break
      end
      stack[i] = stack[i] .. table.remove(stack)
    end
  end
end

--- func desc
---@param stack any
---@param delim any
function toString(stack,delim)
  local delim = delim or ""
  local s = table.concat(stack, delim) .. delim
  return s
end

--- func desc
---@param stack any
function stringBufferLen(stack)
  if #stack==1 and stack[1]=="" then
    return 0
  else
    return #stack
  end
end

-- Function to compress and remove nil elements from an array
function compressArray(arr)
  local result = {}  -- Initialize the result array

  for _, value in pairs(arr) do
      if value ~= nil then
          table.insert(result, value)
      end
  end

  return result
end

function file_exist(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

function getBasename(filePath)
  local basename = string.match(filePath, "([^\\/]-%.?([^%.\\/]*))$")
  if basename then
      basename = string.gsub(basename, "(%..*)$", "")  -- Remove the file extension
      return basename
  else
      return nil
  end
end

function addSuffix2Basename(model_file, suffix, subfolder)
  -- Find the position of "/path/to/myfile.mps" in the string
  local basename = getBasename(model_file)
  local startPos, endPos = string.find(model_file, basename)  
  --print("basename:",basename)    -- 'myfile'

  -- Check if "myfile" was found
  if startPos then
      -- Extract the part of the string before "myfile"
      local prefix = string.sub(model_file, 1, startPos - 1) -- /path/to
      if subfolder then
        prefix = prefix .. "/" .. subfolder .. "/"           -- /path/to/subfolder
        if not paths.dirp(prefix) then
            paths.mkdir(prefix)
        end
      end
      
      -- Extract the part of the string after "myfile"
      local extname = string.sub(model_file, endPos + 1) -- .mps

      -- Create the new string with "myfile_sos2xN" inserted
      local newModelFile = prefix .. basename .. suffix .. extname  -- /path/to/subfolder .. myfile .. suffix .mps

      return newModelFile
  else
      -- "myfile" not found, return the original string
      return nil
  end
end

function generateRandomIntegers(xmin, xmax, count)
  local randomIntegers = {}
  
  for _ = 1, count do
      local randomInteger = math.random(xmin, xmax)      
      table.insert(randomIntegers, randomInteger)
  end
  
  return randomIntegers
end

function generateLeftSkewedRandomIntegers(min, max, count)
  if count > max - min + 1 then
      return nil  -- Not enough unique integers in the range
  end

  local randomIntegers = {}
  local availableIntegers = {}

  for i = min, max do
      table.insert(availableIntegers, i)
  end

  for _ = 1, count do
      if #availableIntegers == 0 then
          return nil  -- Not enough unique integers left
      end

      local index = math.random(1, #availableIntegers)
      local randomInteger = table.remove(availableIntegers, index)
      table.insert(randomIntegers, randomInteger)

      -- Increase the probability of selecting smaller integers
      for i = 1, math.floor(#availableIntegers / 2) do
          local swapIndex = math.random(i, #availableIntegers)
          availableIntegers[i], availableIntegers[swapIndex] = availableIntegers[swapIndex], availableIntegers[i]
      end
  end

  return randomIntegers
end

function generateUniqueRandomIntegers(min, max, count)
  if count > max - min + 1 then
      return nil  -- Not enough unique integers in the range
  end

  local randomIntegers = {}
  local availableIntegers = {}

  for i = min, max do
      table.insert(availableIntegers, i)
  end

  for _ = 1, count do
      if #availableIntegers == 0 then
          return nil  -- Not enough unique integers left
      end

      local index = math.random(1, #availableIntegers)
      local randomInteger = table.remove(availableIntegers, index)
      table.insert(randomIntegers, randomInteger)
  end

  return randomIntegers
end


local portmap = {luna=40117, fuji=40245, jazz=40139, bobcat=40135, localhost=7791, ['tabox.de']=40139, planet=40245}

---
-- Callback function to in stack order
--
function stackpos(t, a, b)  
    return t[a]>t[b]
end 

---
-- Callback function to order pairs in t
-- @param t Lua table
-- @param a An item in t
-- @param b Another item in t
function keyorder(t, a, b)
  if tonumber(a) and tonumber(b) then
    return tonumber(a)<tonumber(b)
  elseif tonumber(a) and not tonumber(b) then
    return true
  elseif not tonumber(a) and tonumber(b) then
    return false
  else
    return a<b
  end
end

---
-- Sorted pairs iterator
-- @param t Lua table
-- @param order callback function to order pairs
function spairs(t, order)
  local order = order or keyorder
  -- collect the keys
  local keys = {}
  for k in pairs(t) do keys[#keys+1] = k end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys
  if order then
    table.sort(keys, function(a,b) return order(t, a, b) end)
  else
    table.sort(keys)
  end

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

---
-- 
--
function gethostname()
  if xta.platformid==xta.const.win32x86 or xta.platformid==xta.const.win64x86 then
    return string.lower(os.getenv("COMPUTERNAME"))
  else
    return string.lower(os.getenv("HOSTNAME") or gethostname2())
  end  
end

---
-- 
--
function gethostname2()
    local f = io.popen ("/bin/hostname")
    local hostname = f:read("*a") or ""
    f:close()
    hostname =string.gsub(hostname, "\n$", "")
    return hostname
end

---
--
function get_zmq_server_url(server)
  local server = server or gethostname()
  local rpcport = portmap[server]
  assert(rpcport,sprintf("\nError: no ports for server %s in portmap[]\n",server))
  local url = sprintf("tcp://*:%d",rpcport)  
  printf2("RPC server at url: %s\n",url)
  return rpcport,url,server
end

---
--
function get_zmq_client_url(server)  
  local server = server or "localhost"
  local rpcport = portmap[server]
  assert(rpcport,sprintf("\nError: no ports for server %s in portmap[]\n",server))
  local url = sprintf("tcp://%s:%d",server,rpcport)
  printf2("RPC client to url: %s\n",url)
  return rpcport,url
end
