

-- f = xta:ivector(len)
local ivector = function (env,len) return tabox.field(env,len,"newIvec",'int') end
tabox.ivector = ivector
-- f = xta:dvector(len)
local dvector = function (env,len) return tabox.field(env,len,"newDvec",'double') end
tabox.dvector = dvector

---
--
local fielddes = function (env, str, name, ttype)
  local f = tabox.field(env,0,name or "na", ttype or "double")
  f:des(str)
  return f
end
tabox.fielddes = fielddes

---
--
local setlindodll = function(env,vermaj,vermin)
    local dllname
    if env.platformid==env.const.win32x86 then
      dllname = sprintf("lindo%d_%d.dll",vermaj,vermin)
    elseif env.platformid==env.const.win64x86 then
      dllname = sprintf("lindo64_%d_%d.dll",vermaj,vermin)
    elseif env.platformid==env.const.linux64x86 then
      dllname = sprintf("liblindo64.so.%d.%d",vermaj,vermin)
    elseif env.platformid==env.const.osx64x86 then
      dllname = sprintf("liblindo64.%d.%d.dylib",vermaj,vermin)
    else
      error('unhandled solver platform')
    end    
    local ierr = tabox.setsolverdll(env,dllname,env.const.solver_lindo)    
end
tabox.setlindodll = setlindodll

---
-- Get UTC date,time from ISO8601 formatted timestamp
-- @param iso_date  ISO formatted timestamp, e.g. "2019-11-21T22:35:03.332+02:00"
-- @return my_utc_date,my_utc_time = xta:iso2datetime(iso_date)
local iso2datetime = function(env,iso_date)
  -- our input
  assert(env)
  assert(iso_date)
  iso_date = string.gsub(iso_date,"Z","+00:00")
  --local my_date = "2019-11-21T22:35:03.332+02:00"
  -- we can just keep anything befor T as our date
  local day = iso_date:match("(.*)T")
  
  -- now parse the UTC offset
  local offsetH, offsetM = iso_date:match("([%+%-]%d%d):(%d%d)")
  
  -- apply sign to our minute offset
  offsetM = offsetM * (tonumber(offsetH) > 0 and 1 or -1)
  
  -- get time components
  local h, m, s, ms = iso_date:match("(%d%d):(%d%d):(%d%d).(%d%d%d)")

  local yy,mm,dd = day:match("(%d+)-(%d+)-(%d+)") 

  -- fix our and minute to get UTC
  h = h - offsetH
  m = m - offsetM
  -- round seconds as we have microseconds in our input
  s = math.floor(s + ms / 1000 + .5)

  -- now put everything together with leading zeros
  local my_utc_date,my_utc_time = string.format("%04d%02d%02d",yy,mm,dd),string.format("%02d%02d%02d", h, m, s)
  local my_utc_offset = offsetM

  return my_utc_date,my_utc_time,my_utc_offset
end  
tabox.iso2datetime = iso2datetime
---
-- Convert current or given timestamp in unixsec to ISO-8601 format 
-- @param t unixtime
-- @return iso date
local unixsec2iso = function(env,t)
  local retval
  local fmt = "!%Y-%m-%dT%H:%M:%SZ"
  if t then    
    retval = os.date(fmt,t)
  else
    retval = os.date(fmt)
  end
  return retval
end
tabox.unixsec2iso = unixsec2iso

---
--
local secstoday = function(env)
  local tm = xta:timenow()
  return xta:hour(tm)*3600+xta:minute(tm)*60+xta:second(tm)
end
tabox.secstoday = secstoday


local closeds_by_key = function(env,key)
  glogger.info("Removing locks from '%s' datasources\n",key)
  for k,v in pairs(cmdOptions._dstable[key]) do
    glogger.warn("Closing %s\n",v)
    local ierr = xta:closeds(v)
  end
end
tabox.closeds_by_key = closeds_by_key

tabox.DBL_EPSILON = 2.2204460492503131e-16

local function check_error(xta, res, allowed, stop_on_err)
  local stop_on_err = stop_on_err    
  -- Check if res is in the allowed table              
  if res == 0 then
      return
  end        
  local allowed = allowed or {0}
  local isContinue = false    
  for i, code in ipairs(allowed) do
      if res == code then
          isContinue = true   -- white error for the call
          break
      end
  end

  -- If the error code is not allowed, trigger an assert
  if not isContinue then
      local errMsg = string.format("\nError %d: %s", res, xta:errmsg(res))        
      if stop_on_err then
          error(errMsg)  -- This will terminate the program and print the error message        
      end
  else
      local errMsg = string.format("Error %d: %s", res, xta:errmsg(res))        
      printf("\nIGNORE %s",errMsg);        
  end    
end    

tabox.xassert = function(xta,res, allowed)
  local res = res or xta.lasterr
  check_error(xta, res, allowed, true)
end

tabox.wassert = function(xta,res, allowed)
  local res = res or xta.lasterr
  check_error(xta, res, allowed, false)
end