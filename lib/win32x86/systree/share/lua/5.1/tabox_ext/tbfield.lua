----
-- TBfield extensions
-- $Id$
--

---
-- f:yydump()
TBfield.yydump = function (f) printf('\ndumping values in field\n') for k=1,f.len do print(f[k]) end print("done!\n")end

---
-- f:yyrand()
TBfield.yyrand = function (f) printf('\nrandomizing values in field') for k=1,f.len do f[k]=math.random() end  print("\ndone!\n") end

---
-- Convert TBfield to a Lua table
-- @param f
-- @return A Lua table and name
TBfield.totable = function (f) 
  assert(type(f)=='userdata')
  local lxf
  if f:isfield() then
    lxf = {}
    for k=1,f.len do
      table.insert(lxf,f[k])
    end
  end
  return lxf, f.name
end


---
-- Perform dot product on two fields
-- @param f1
-- @param f2
-- @return dot product value
TBfield.yydotprod = function(f1,f2)
  assert(f1:isfield() and f2:isfield())
  assert(f1.len==f2.len,"Field length mismatch in dotprod")
  local sum=0
  for i=1,f1.len do
    sum = sum + f1[i]*f2[i]
  end
  return sum
end

---
-- Map index
TBfield.mindex = function(f1,dir,base,method)
  assert(f1:isfield())
  local idx = f1:index(dir,base,method)
  local midx
  if idx then
    midx = xta:izeros(idx.len)
    for k=1,idx.len do 
      midx[idx[k]]=k
    end    
  end
  return midx
end

---
-- 
TBfield.sprintj = function(txf,strbuf)
  assert(txf:isfield())
  assert(type(strbuf)=='table')
  local jNL=''
  local printindent = txf.printindent  
  if hasbit(txf.printmode,xta.const.print_json_nl) then
    jNL='\n'
  else
    printindent = 0
  end
  local key = txf.prop.jsonname
  local indent
  if printindent>0 then
    indent = repchar(" ",2*printindent)
    addStringx(strbuf,indent)
  end
  if hasbit(txf.printmode,xta.const.print_json_ob) then
    addString(strbuf,'"%s": {'..jNL,key)
    if printindent>0 then
      addStringx(strbuf,indent)
    end
  else
    addString(strbuf,"%s","")
  end
  local szbuf = txf.name
  local k
  local fwidth = "" 
  --fwidth = tostring(txf.prop.fwidth) -- ignore fwidth for json elements
  local mask = txf.prop.mask
  local jname = txf.prop.jsonname
  if jname and jname:len()>0 and (not hasbit(txf.printmode,xta.const.print_json_ob)) then
    szbuf = jname
  end
  
  addString(strbuf,'  "%s": [',szbuf)     
  local fmt0,fmt,fmtl
  if txf.type=='string' then
    fmt0 = '%' .. fwidth .. 's'
    fmt = '"' .. fmt0 .. '",'
    fmtl = '"' .. fmt0 .. '"' -- no trailing comma
    for k=1,txf.len-1 do
      addString(strbuf,fmt,txf[k])
    end  
    k = txf.len
    addString(strbuf,fmtl,txf[k])
    addStringx(strbuf,"]")
  elseif txf.type=='int' or txf.type=='integer' then
    fmt0 = '%' .. fwidth .. 'd'
    fmt = fmt0 .. ','
    fmtl = fmt0              -- no trailing comma
    for k=1,txf.len-1 do
      addString(strbuf,fmt,txf[k])
    end
    k = txf.len
    addString(strbuf,fmtl,txf[k])
    addStringx(strbuf,"]")        
  else
    if hasbit(mask,1) then
      fmt0 = '%' .. fwidth .. 'f.0'
    else
      fmt0 = '%' .. fwidth .. 'g'
    end
    fmt = fmt0 .. ','
    fmtl = fmt0              -- no trailing comma
    for k=1,txf.len-1 do
      addString(strbuf,fmt,txf[k])
    end
    k = txf.len
    addString(strbuf,fmtl,txf[k])
    addStringx(strbuf,"]")
  end
  
  if hasbit(txf.printmode,xta.const.print_json_cb) then
    addStringx(strbuf,""..jNL);
    if printindent>0 then
      addStringx(strbuf,indent)
    end
    addStringx(strbuf,"}")
  end
  if hasbit(txf.printmode,xta.const.print_json_csv) then
    addStringx(strbuf,",")
  end
  addStringx(strbuf,""..jNL);
  return
end 

--- func desc
---@param txf any
local function field_type_to_format(txf,width,dfmt)
  local fmt 
  local width = width or 12
  if txf.type=='double' then
    fmt = '%' .. tostring(width) .. dfmt
  elseif txf.type=='int' then
    fmt = '%' .. tostring(width) .. 'd'
  else
    fmt = '%' .. tostring(width) .. 's'
  end
  return fmt
end
---
-- Print a field/vector in 'numcols' columns
TBfield.printmat = function(txf,numcols,gstrbuf,width,delim,dfmt)
  local delim = delim or ""
  local dfmt = dfmt or '.4f'
  local numcols = numcols or 10
  local width = width or 12
  local strbuf = gstrbuf or stringBuffer()
  if txf:isfield() then
    addString(strbuf,"\n")
    local fmt = field_type_to_format(txf,width,dfmt)
    fmt = fmt .. delim .. " "
    for k=1,txf.len do
      addString(strbuf,fmt,txf[k])
      if k%numcols==0 then addString(strbuf,"\n") end
    end
    addString(strbuf,"\n")
  elseif type(txf)=='table' and txf[1] then
    addString(strbuf,"\n")
    local fmt = sprintf("%%%d.4f%s ",width,delim)
    for k,v in ipairs(txf) do
      addString(strbuf,fmt,v)
      if k%numcols==0 then addString(strbuf,"\n") end
    end
    addString(strbuf,"\n")
  end
  if not gstrbuf then
    printf("%s[]:\n",txf.name)
    printf("%s\n",toString(strbuf))
  end
end

---
-- Convert a field/vector to a JSON dataset format
-- suitable for spark-charts
TBfield.data2set = function(f)
  local dataset
  if f:isfield() then
    dataset = {}
    local data = {}    
    for k=1,f.len do
      local v = {}
      v['value'] = f[k]
      table.insert(data,v)
    end
    dataset.data = data    
  else
    glogger.warn("TBfield is required\n")    
  end    
  return dataset
end 
