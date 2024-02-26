#!/usr/bin/env lua
---
-- Misc 'print' implementations
--
--


--- 
-- Execute formatted command
-- 
os_executef = function(fmt, ...)
  local CMD = string.format(fmt, ...)
  os.execute(CMD)
end

---
--
assertf = function(expr,fmt,...)
  assert(expr,sprintf(fmt,...))
end
  
---
-- Callback to display logs from TABOX
-- @param str
--
printlinex = function(fmt, ...)
    io.stdout:flush()
    io.write(string.format(fmt, ...))
    io.write(string.format("\n"))
    io.stdout:flush()
end

printline = function(fmt, ...)
    io.stdout:flush() 
    glogger.capi(fmt,...)
    io.write(string.format("\n"))
    io.stdout:flush()
end
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

---
-- Same as printf4
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
-- Similar to printf2 but does not use glogger
printf4 = function(fmt, ...)   
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

dprintf4 = function(v,fmt, ...)
  if (type(v)=='number' and v>0) or (v and type(v)=='boolean') then
    printf4(fmt,...)
  end
end
  
---
--
sprintf = function(fmt, ...)  
    local s=string.format(fmt, ...)
    return s 
end


---
--
fprintf = function(fp, s, ...)
    assert(fp)
    fp:write(s:format(...)) 
end

---
--
fprintf2 = function(fp,fmt, ...)   
    local ts = sprintf("%d:%d | ",xta:now())
    if (fp) then 
        fp:write(ts,string.format(fmt, ...)) 
    end 
end

---
--
fprintf3 = function(fp,fmt, ...)   
    io.stdout:flush()
    local ts = sprintf("%d:%d | ",xta:now())
    io.write(ts,string.format(fmt, ...))
    io.stdout:flush() 
    if (fp) then 
        fp:write(ts,string.format(fmt, ...)) 
    end 
end

---
--
fprintf4 = function(fp,fmt, ...)   
    io.write(string.format(fmt, ...)) 
    if (fp) then 
        fp:write(string.format(fmt, ...)) 
    end 
end

---
--
dprintf = function(v,fmt, ...)
  if (type(v)=='number' and v>0) or (v and type(v)=='boolean') then
    io.write(string.format(fmt, ...))    
    io.stdout:flush() 
  end 
end

---
--
dprintf2 = function(v,fmt, ...)
  if (type(v)=='number' and v>0) or (v and type(v)=='boolean') then
    printf2(fmt, ...)     
  end 
end

---
--
fwrite = function(fname,mode,str)
  assert(fname,"\n\nError: fwrite arg #1 is required to be a valid file name\n")
  assert(mode and (mode=="a" or mode=="w"),"\n\nError: fwrite arg #2 is required to be a valid file mode, e.g. 'w','a'\n")
  assert(str,"\n\nError: fwrite arg #3 is required to be a string\n")  
  local fp = io.open(fname,mode)
  assert(fp, "\n\nError: failed to open " .. fname .. "\n")
  fp:write(str)
  fp:flush()
  fp:close()
  return
end

---
--
fwritef = function(fname,mode,fmt,...)
  assert(fname,"\n\nError: fwrite arg #1 is required to be a valid file name\n")
  assert(mode and (mode=="a" or mode=="w"),"\n\nError: fwrite arg #2 is required to be a valid file mode, e.g. 'w','a'\n")
  assert(fmt,"\n\nError: fwrite arg #3 is required to be a string format\n") 
  local fp = io.open(fname,mode)
  assert(fp, "Error: file open " .. fname)
  fprintf(fp,fmt,...)
  fp:flush()
  fp:close()
  return
end

---
--
fwritef2 = function(fname,mode,fmt,...)
  assert(fname,"\n\nError: fwrite arg #1 is required to be a valid file name\n")
  assert(mode and (mode=="a" or mode=="w"),"\n\nError: fwrite arg #2 is required to be a valid file mode, e.g. 'w','a'\n")
  assert(fmt,"\n\nError: fwrite arg #3 is required to be a string format\n") 
  local fp = io.open(fname,mode)
  assert(fp, "Error: file open " .. fname)
  fprintf2(fp,fmt,...)
  fp:flush()
  fp:close()
  return
end

---
--
function printmat(v)
  assert(v)
  assert(type(v)=='userdata')
  v.printmode=0
  v.printdelim=string.byte(',')
  local ans = v.name
  if ans=="" then ans="ans" end
  printf("%s = \n",ans)
  v:print()
end

---
--
function repchar1(mychar,n)
  local str=""
  assert(n>0)
  for i=1,n do
    str = str .. mychar
  end
  return str
end

---
--
function repchar(mychar,n)
  return mychar:rep(n)
end

---
-- @param t
--
tprint = function(t)
    io.stdout:flush()
	if t==nil then
    return
  elseif type(t)=='userdata' then 
		print(t.name,t)
		return 
	end
	for i,v in pairs(t) do 
		if type(v)=='table' then 
			tprint(v) 
		elseif type(v)=='userdata' then
        if v:istable() or v:isfield() then
            print(i,v)
            v:print()
        else
          print(i,v)
        end
    else
			print (i,v)
    end 
	end
    io.stdout:flush()
end	

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
tprintx = function (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    local formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))      
    else
      print(formatting .. v)
    end
  end
end


---
-- @param tokens
--
function tokprint(tokens)
   local print, format = _G.print, _G.string.format
   for i, token in pairs(tokens) do
      print(format('%d line %i, %s: `%s`', i,token[3], token[1], token[2]))
   end
   print(format('total of %i tokens, %i lines', #tokens, tokens[#tokens][3]))
end

---
-- @param t
-- @param tab
-- @param lookup
--
function printtbl( t,tab,lookup )
    local lookup = lookup or { [t] = 1 }
    local tab = tab or ""
    for i,v in pairs( t ) do
        print( tab..tostring(i), v )
        if type(i) == "table" and not lookup[i] then
            lookup[i] = 1
            print( tab.."Table: i","size:",#i )
            printtbl( i,tab.."\t",lookup )
        end
        if type(v) == "table" and not lookup[v] then
            lookup[v] = 1
            print( tab.."Table: v","size:",#v )
            printtbl( v,tab.."\t",lookup )
        end
    end
end

---
-- @param tt
-- @param indent
-- @param done
--
function sprint_table2(tt, indent, done)
  done = done or {}
  indent = indent or 1
  if type(tt) == "table" then
    local sb = {}
    if indent==1 then table.insert(sb, "{\n"); end
    for key, value in pairs (tt) do
      table.insert(sb, string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        table.insert(sb, string.format("%s = {\n",key));
        table.insert(sb, sprint_table2 (value, indent + 2, done))
        table.insert(sb, string.rep (" ", indent)) -- indent it
        table.insert(sb, "},\n");
      elseif "number" == type(key) then
        table.insert(sb, string.format("\"%s\",\n", tostring(value)))
      else
        table.insert(sb, string.format(
            "%s = \"%s\",\n", tostring (key), tostring(value)))
       end
    end
    if indent==1 then table.insert(sb, "}\n"); end
    return table.concat(sb) .. "\n"
  else
    return tt .. "\n"
  end
end

---
-- @param t
-- @param name
-- @param lvl
--
function print_table(t, name, depth)
    depth  = depth or 1
    --if #t==0 then return end
    local tab = string.rep("   ", depth)
    printf(tab..(name and (name .. " = {") or "{") .."\n")
    for k, v in spairs(t) do
        if(type(v) == "table") then
            print_table(v, k, depth+1)
        elseif(type(v) == "userdata") then
            tprint(v)
        else
            printf(tab..tab..tostring(k).." = "..tostring(v).."," .. "\n")
        end
    end
    printf(tab.."}" .. "\n")
end

---
-- @param t
-- @param name
-- @param lvl
--
function sprint_table(t, name, depth, buffer)
    buffer = buffer or stringBuffer()
    depth  = depth or 1
    --if #t==0 then return end
    local tab = string.rep("   ", depth)
    addString(buffer,tab..(name and (name .. " = {") or "{") .."\n")
    for k, v in pairs(t) do
        if(type(v) == "table") then
            sprint_table(v, k, depth+1,buffer)
        elseif(type(v) == "userdata") then
            tprint(v)
        elseif(type(v) == "number") then
            addString(buffer,tab..tab..tostring(k).." = "..tostring(v).."," .. "\n")
        elseif(type(v) == "boolean") then
            addString(buffer,tab..tab..tostring(k).." = "..tostring(v).."," .. "\n")
        else -- treat as string            
          addString(buffer,tab..tab..tostring(k).." = \"".. tostring(v).."\"," .. "\n")
        end
    end
    if depth>1 then
        --printf("%s\n",tab..tab.."Data".." = ".."nil")
        addString(buffer,tab.."}," .. "\n")
    else
        addString(buffer,tab.."}" .. "\n")
    end
        
    return toString(buffer)
end


function print_table2(input_table, keyprop)  
   for k,v in pairs(input_table) do   
    if keyprop ~=nil then 
        print(k[keyprop] .. "," .. v)
      else
        print(k .. "," .. v)
     end     
   end   
end

function keystr(k)
  return "['" .. tostring(k) .. "']"
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

function print_table4(t, name, depth)
    depth  = depth or 1
    --if #t==0 then return end
    local tab = string.rep("   ", depth)
    local tokey = tostring
    --tokey = keystr
    if name then
       io.write(string.format("%s\n",tab.."[\"" .. tokey(name).."\"]" .. " = {"))
       --io.write(string.format("%s\n",tab..name .. " = {"))
    else
       io.write(string.format("%s\n","{"))
    end
    for k, v in pairs(t) do
        if(type(v) == "table") then
            if k~="Assets"  then
              print_table3(v, k, depth+1)
            else
              io.write(string.format("%s\n",tab..tab.."[\"" .. tokey(k).."\"]".." = "..tostring(v)..","))
            end
        elseif(type(v) == "userdata") then
            io.write(string.format("%s\n",tab..tab..tokey(k).." = "..tostring(v)..","))
        elseif(type(v) == "number") then
            io.write(string.format("%s\n",tab..tab.."[\"" .. tokey(k).."\"]" .. " = "..tostring(v)..","))
        else
            io.write(string.format("%s\n",tab..tab.."[\"" .. tokey(k).."\"]" .. " = \""..tostring(v).."\","))
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

---
-- @param t
-- @param name
-- @param lvl
--
function fprint_table(fp, t, name, lvl2)
    lvl2  = lvl2 or 1
    --if #t==0 then return end
    local tab = string.rep("   ", lvl2)
    if name then
       fprintf(fp,"%s\n",tab..name .. " = {")
    else
       fprintf(fp,"%s\n","{")
    end
    for k, v in pairs(t) do
        if(type(v) == "table") then
            fprint_table(fp,v, k, lvl2+1)
        elseif(type(v) == "userdata") then
            fprintf(fp,"%s\n",tab..tab..tostring(k).." = "..tostring(v)..",")
        else
            fprintf(fp,"%s\n",tab..tab..tostring(k).." = "..tostring(v)..",")
        end
    end        
    if lvl2>1 then
        fprintf(fp,"%s\n",tab..tab.."Data".." = ".."nil")
        fprintf(fp,"%s\n",tab.."},")
    else
        fprintf(fp,"%s\n",tab.."}")
    end  
end

---
-- @param t
--
function print_match(t)
    if(type(t) == "table") then
        print_table(t)
    else
        print(t)
    end
end

---
-- @param x
--
function boolean2number(x)
    if (type(x)=='number') then
        return x
    elseif (type(x)=='boolean') then
        if (x==true) then
            return 1
        else
            return 0
        end
    else
        return x
    end
end    

b2n = boolean2number


-- Compatibility: Lua-5.1
---
-- @param str
-- @param pat
--
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

-- Compatibility: Lua-5.0
---
-- @param str
-- @param delim
-- @param maxNb
--
function Split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

-- Split text into a list consisting of the strings in text,
-- separated by strings matching delimiter (which may be a pattern). 
-- example: strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
---
-- @param delimiter
-- @param text
--
function strsplit(text,delimiter)
  local list = {}
  local pos = 1
  if string.find("", delimiter, 1) then -- this would result in endless loops
    error("delimiter matches empty string!")
  end
  while 1 do
    local first, last = string.find(text, delimiter, pos)
    if first then -- found?
      table.insert(list, string.sub(text, pos, first-1))
      pos = last+1
    else
      table.insert(list, string.sub(text, pos))
      break
    end
  end
  return list
end


--[[ written for Lua 5.1
-- split a string by a pattern, take care to create the "inverse" pattern 
yourself. default pattern splits by white space.
-- @param
-- @param
]]
string.splitx = function(str, pattern)
  pattern = pattern or "[^%s]+"
  if pattern:len() == 0 then pattern = "[^%s]+" end
  local parts = {__index = table.insert}
  setmetatable(parts, parts)
  str:gsub(pattern, parts)
  setmetatable(parts, nil)
  parts.__index = nil
  return parts
end

-- another split a string by a pattern,
-- @param
-- @param
string.splitz = function(str, delim)
  local delim = delim or "%s"
  local pattern = pattern or "[^" .. delim .. "]+"
  if pattern:len() == 0 then pattern = "[^" .. delim .. "]+" end
  local parts = {__index = table.insert}
  setmetatable(parts, parts)
  str:gsub(pattern, parts)
  setmetatable(parts, nil)
  parts.__index = nil
  return parts
end

-- yet another split a string by a pattern,
-- @param
-- @param
string.splity = function(txt, delim)
  local tbl = {}
  for k in txt:gmatch("([^"..delim.."]+)" .. delim) do
      table.insert(tbl, k)
  end
  return tbl
end

---
--  joins two tables and returns combined table
-- @param t1
-- @param t2
--
function join_tables(t1, t2) for k,v in ipairs(t2) do table.insert(t1, v) end return t1 end

--- func desc
---@param pos any
---@param str any
---@param r any
function replace_char(pos, str, r)
    return ("%s%s%s"):format(str:sub(1,pos-1), r, str:sub(pos+1))
end
---
--  
--
--
function progress_onbar(ibar,every,max)
  local every = every or 200
  local max = max or 10000
  if ((ibar)%every==0) then 
      printf("%s",'*')
  end  
  if ((ibar)%max==0) then printf("\n") end
end

function progress_offbar(ibar,every,max)
  local every = every or 200
  local max = max or 10000
  if ((ibar)%every==0) then 
      printf("%s",'|')
  end
  if ((ibar)%max==0) then printf("\n") end
end    
  
function tellme(t)
    assert(t)
    for n,v in pairs(t) do
      print (n,v)
     end
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

--- func desc
---@param str any
---@param delim any
---@param maxNb any
function strsplit2(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gmatch(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

local charset = {}  do -- [0-9a-zA-Z]
    for c = 48, 57  do table.insert(charset, string.char(c)) end
    for c = 65, 90  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

function sleep(s)
  local ntime = os.clock() + s
  repeat until os.clock() > ntime
end

function randomString(rg,length,seed)
    if not length or length <= 0 then return '' end
    if seed then rg.seed = seed end
    return randomString(rg,length - 1) .. charset[rg:int(1, #charset)]
end

function randomInteger(rg,digits,seed)
    if not digits or digits <=0 then return 0 end
    if seed then rg.seed = seed end
    local u
    u = 1e9 + rg:int(0,10^(digits-1)-1)
    return u
end

function string.random(length)
  math.randomseed(os.time())

  if length > 0 then
    return string.random(length - 1) .. charset[math.random(1, #charset)]
  else
    return ""
  end
end

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
-- Callback function to order pairs in t
-- @param t Lua table
-- @param a An item in t
-- @param b Another item in t
function szSymbolOrder(t, a, b)  
  if tonumber(a) and tonumber(b) then
    return t[tonumber(a)][1]<t[tonumber(b)][1]
  elseif tonumber(a) and not tonumber(b) then
    return true
  elseif not tonumber(a) and tonumber(b) then
    return false
  else -- string
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
function read_file(path,mode)
    local file = io.open(path, mode or "rb") -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end

-- see if the file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function read_file_lines(file)
  if not file_exists(file) then return {} end
  local lines = {}
  for line in io.lines(file) do 
    lines[#lines + 1] = line
  end
  return lines
end

---
-- 
-- 
function clear_table(t)
  if not t then return end
  for k in pairs (t) do
    t [k] = nil
  end 
end


---
-- Differs from SplitFilename by not checking if input is a 'dir'
--  
function SplitFilenameX(strFilename)
  -- Returns the Path, Filename, and Extension as 3 values
  local a,b,c = strFilename:match("(.-)([^\\/]-([^\\/%.]+))$")
  b = b:match("(.+)%..+")
  if not b then
    b = c
    c = nil
  end
  return a,b,c
end

---
-- Format table 
-- @param tt
-- @param which
function print_tabular(tt, which,cmp_)
  local which = which or 0
  local count = 0
  local width = 22
  -- print_pretty3(tt)
  -- os.exit(1)
  for k, v in spairs(tt,cmp_) do
    count = count + 1
    if count == 1 then
      if type(v) == 'table' then
        printf("%-16s,", "symbol")
        local ntickers = 0
        for j, v2 in pairs(v) do
          local fmt
          ntickers = ntickers + 1
          if type(j) == 'number' then
            fmt = sprintf("%%%dg,", math.max(string.len(j), width))
          else
            fmt = sprintf("%%%ds,", math.max(string.len(j), width))
          end
          -- printf("%s %s\n",j,v2)
          if which == 0 then
            if j ~= "isFrozen" and j ~= "pair" then
              printf(fmt, j)
            end
          else
            fmt = sprintf("%%%ds,", math.max(string.len(j), width))
            if j ~= "isFrozen" and j ~= "pair" then
              printf(fmt, "ticker" .. ntickers)
            end
          end
        end
        printf("\n")
      end
    end

    if type(v) == 'table' then
      printf("%-16s,", k)
      for j, v2 in pairs(v) do
        local fmt
        if type(v2) == 'number' then
          fmt = sprintf("%%%dg,", math.max(string.len(j), width))
        else
          fmt = sprintf("%%%ds,", math.max(string.len(j), width))
        end
        if j ~= "isFrozen" and j ~= "pair" then
          printf(fmt, v2)
        end
      end
      printf("\n")
    else
      -- printf("***%s\n",k)
    end
  end
end

------------------------------------------------------------------
--- Split iterator, tokenizer
-- 
-- @example
--    local first, str = split.first(str, '\r\n')
--    for token in split.iter(str, '\r\n') do
--      ..
--    end
local split = {} do
  function split.iter(str, sep, plain)
    local b, eol = 0,0
    return function()
      if b > #str then
        if eol then eol = nil return "" end
        return
      end
  
      local e, e2 = string.find(str, sep, b, plain)
      if e then
        local s = string.sub(str, b, e-1)
        b = e2 + 1
        if b > #str then eol = true end
        return s
      end
  
      local s = string.sub(str, b)
      b = #str + 1
      return s
    end
  end
  
  function split.first(str, sep, plain)
    local e, e2 = string.find(str, sep, nil, plain)
    if e then
      return string.sub(str, 1, e - 1), string.sub(str, e2 + 1)
    end
    return str
  end
end

---
-- 
--
function showupvalues (f)
  assert (type (f) == "function")
  print("Upvalues for f",f)
  local i = 1
  local name, val
  repeat
    name, val = debug.getupvalue (f, i)
    if name then
      print ("index", i, name, "=", val)
      i = i + 1
    end -- if
  until not name

end -- function showupvalues

---
-- user-defined stack traceback
--
function traceback2 ()
  local level = 1
  while true do
    local info = debug.getinfo(level, "Sl")
    if not info then break end
    if info.what == "C" then -- is a C function?
      printf("%d %s",level, "C function")
    else -- a Lua function
      printf("[%s]:%d\n",info.short_src, info.currentline)
    end
    level = level + 1
  end
end

---
-- native stack traceback
--
function traceback ()
  io.write(string.format("\n%s\n",debug.traceback()))
end

function uuid()
  local uuid = require("uuid")
  return uuid.new()
end

---
-- Get format string for specified q and width
-- 
function get_dblfmt(q,w,d)
  local w = w or 14 -- width
  local d = d or 2  -- digits  
  local q0 = q
  if q<0 then q=-q end
  local qsig = math.ceil(math.log10(q))
  
  local qfmt
  if qsig < w - d - 2 then
    qfmt = "%" .. tostring(w) .. "." .. tostring(d) .. "f"
  elseif qsig < w - 2 then
    d = w - 2 - qsig
    qfmt = "%" .. tostring(w) .. "." .. tostring(d) .. "f"
  else    
    d = w - 3 - 5  -- [-][1.]xxxx[e+008]
    qfmt = "%" .. tostring(w) .. "." .. tostring(d) .. "e"
  end  
  local szq = sprintf(qfmt,q0)
  return szq,qfmt 
end

--- func desc
---@param w any
---@param h any
function box(w,h)                           -- Define Anonymous Function
    function g(s)                       -- Define 'Row Creation' function. We use this twice, so it's less bytes to function it.
        return'|'..s:rep(w-2)..'|\n'    -- Sides, Surrounding the chosen filler character (' ' or '-'), followed by a newline
    end
    b=g'-'                              -- Assign the top and bottom rows to the g of '-', which gives '|---------|', or similar.
    print(b..g' ':rep(h-2)..b)          -- top, g of ' ', repeated height - 2 times, bottom. Print.
end


function printPackagePaths()
  print("package.path entries:")
  for path in package.path:gmatch("[^;]+") do
      print(path)
  end

  print("\npackage.cpath entries:")
  for path in package.cpath:gmatch("[^;]+") do
      print(path)
  end
end


function searchPackagePath(moduleName)
  local path = package.searchpath(moduleName, package.path)
  if path then
      print(moduleName .. " is loaded from: " .. path)
  else
      print(moduleName .. " not found")
  end
end

