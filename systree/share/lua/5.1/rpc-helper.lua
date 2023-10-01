
require("libtabox32")

-- Logging
local Logclass_ = require('logclass') -- global logger
glogger = Logclass_:new('glogger','info')

if (xta==nil) then
  xta = tabox.env()
end

---
-- include class extensions
require 'tabox_ext.tbenv'
require 'tabox_ext.tbfield'
require 'tabox_ext.tbtable'
require 'tabox_ext.tbsim'
require 'tabox_ext.tbparam'
require 'tabox_ext.tbasset'

local portmap = {luna=40117, fuji=40245, jazz=40139, bobcat=40135, localhost=7791, ['tabox.de']=40139, planet=40245}


--
--
function bit(p)
  return 2 ^ (p - 1) -- 1-based indexing
end

---
--
function bitpos(n)
  return math.floor(math.log(n)/math.log(2))
end

---
-- Typical call: if hasbit(x, bit(3)) then ...
-- 
function hasbit(x, p)
  assert(x,"\n\nError: hasbit arg #1 is nil\n")
  return x % (p + p) >= p
end

---
-- @brief
-- 
function setbit(x, p)
  assert(x,"\n\nError: hasbit arg #1 is nil\n")
  return hasbit(x, p) and x or x + p
end

---
-- @brief
-- 
function clearbit(x, p)
  assert(x,"\n\nError: hasbit arg #1 is nil\n")
  return hasbit(x, p) and x - p or x
end

---
--
sprintf = function(fmt, ...)  
    local s=string.format(fmt, ...)
    return s 
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