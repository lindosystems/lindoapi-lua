----
-- TBtable extensions
-- $Id$
local JSON = require("JSON")

---
-- Transpose a table/matrix
-- 
TBtable.yytr = function(A)
  assert(type(A)=='userdata')
  if A.ncols==0 or A.nrows==0 then
    return nil
  end
  local labels=xta:field(0,"Field","string")
  local collen={}
  for k=1,A.ncols do
    labels:add(A:at(k).name)
  end
  
 
  local At = xta:tr(A)  
  assert(At,sprintf("Error %d: %s\n",xta.lasterr,xta.lasterrmsg))
  if At then    
    At.rownames = labels
    if A.rownames then
      assert(A.nrows==At.ncols)
      for k=1,At.ncols do
        --printf("%d: %s -> %s\n",k,At:at(k).name,A.rownames[k])
        At:at(k).name = A.rownames[k]
      end
    end
  end
  return At
end


---
-- Convert TBtable to a Lua table
-- @param rt
-- @return Lua table
local function totable(rt) 
  assert(type(rt)=='userdata')
  local lxt
  if rt:istable() then
    lxt = {}
    for j=1,rt.ncols do
      local f = rt:at(j)
      local lxf,name = f:totable()
      if string.len(name)<=1 then name=tostring(j) end
      lxt[name] = lxf
    end
  end
  return lxt
end
TBtable.totable = totable

---
-- Move all fields in rts to rtt
-- @param rtsrc
-- @param rttgt
-- @return a Tabox error code
local function moveall(rtsrc,rttgt)
  rtsrc:movefirst()
  local nErr=0

  while (rtsrc:getcursor()~=nil) do
    local f = rtsrc:getcursor()
    nErr = rttgt:add(f)
    if nErr>0 then
      break;
    end        
    rtsrc:movenext()
  end
  return nErr
end
TBtable.moveall = moveall

---
-- Get the effective number of bars in 'bars' object
-- @param bars price bars
-- @return number of bars 
-- @remark if the bars were randomly generated, the effective bar count corresponds to
--  the value indicated by 'bargencursorindex' attribute. Otherwise, it is simply the
--  'number of rows' in 'bars'. 
-- @remark notice how 'bargencursorindex' has to be incremented when new bars 
-- are added.  
local function barcount(bars)
  local bgcursor = bars:getattr("bargencursorindex")
  local lastbar 
  if not bgcursor then
    lastbar = bars.nrows
  else
    lastbar = (bgcursor - 1) + 1 -- 1-based indices
  end
  return lastbar
end 
TBtable.barcount = barcount

---
-- 
local function convert2lua(bars)
  local jarr = xta_table_make_jarray(bars) 
  return jarr
end
TBtable.convert2lua = convert2lua

---
-- 
local function convert2json(bars)
  local jarr = xta_table_make_jarray(bars)
  local jstr = JSON:encode_pretty(jarr) 
  return jstr
end
TBtable.convert2json = convert2json

---
-- 
local function saveasjson(bars,jfile)
  assert(jfile,"\n\nError: saveasjson requires a filename\n")
  local jstr = bars:convert2json()  
  fwrite(jfile,"w",jstr)
end
TBtable.saveasjson = saveasjson

---
-- Set row count for all fields
local function setrowcount(rt,len)
  for k=1,rt.ncols do
    local f = rt:at(k)
    f.len = len
  end
end
TBtable.setrowcount = setrowcount

---
-- Set row count for all fields
local function yynorm(rt,stype)
  local sum = 0  
  for k=1,rt.ncols do
    local f = rt:at(k)
    local fn = f:norm(2)
    sum = sum + fn*fn
  end
  return math.sqrt(sum)
end
TBtable.yynorm = yynorm


---
-- Sort rows by field 'name'
local function yysortrows(rt,fname,dir,base,method)
  assert(rt)
  assert(fname)
  local f = rt[fname]
  if f then
    local midx = f:mindex(dir,base,method)
    rt:add(midx,"MINDEX__")
    rt:sortrows("MINDEX__")
    rt:delete("MINDEX__")
  end
end
TBtable.yysortrows = yysortrows


--- func desc
---@param rt any
local function getcolinfo(rt,infotype)  
  assert(rt)
  assert(rt:istable()==true)
  local infotype = infotype or 'name'
  local f
  if rt.ncols>0 then
    f = xta:field(rt.ncols,infotype,'string')
    for k=1,rt.ncols do
      f[k]=rt:at(k)[infotype] or 'n/a'
    end
  end
  return f
end
TBtable.getcolinfo = getcolinfo  

--- func desc
---@param rt any
local function getcolprop(rt,proptype)  
  assert(rt)
  assert(rt:istable()==true)
  local proptype = proptype or 'symbol'
  local f
  if rt.ncols>0 then
    f = xta:field(rt.ncols,proptype,'string')
    for k=1,rt.ncols do
      f[k]=rt:at(k).prop[proptype] or 'n/a'
    end
  end
  return f
end
TBtable.getcolprop = getcolprop 