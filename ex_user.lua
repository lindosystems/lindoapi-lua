#!/usr/bin/env lslua
-- File: ex_lindo1.lua
-- Description: Example of using the Lindo API to read a model file and 
 --             perform various solver operations
-- Author: mka
-- Date: 2019-07-01
local Lindo = require("llindo_tabox")
require "llindo_usage"

local solver
function myprintlog(pModel,str)
  printf("%s",str)
end

function cbmip(pModel,dobj,pX)
  printf("mipobj: %g, |X|=%g\n",dobj,pX:norm())    
  return 0
end

function cbstd(pModel,iLoc)
  printf("loc: %d\n",iLoc)  
  return 0
end

-- Function g(t) to integrate over [a, b]
function gox(x, t)
  return math.exp(x * math.cos(t))
end

-- Black-box #2 -- G(x) calculated by Simpson's Rule
function Gox(n, x)
  local a = 0
  local b = 2 * math.pi
  local h = (b - a) / n
  local dsum = gox(x, a)
  local c = 2

  for k = 1, n - 1 do
      c = 6 - c  -- alternates between 4 and 2
      dsum = dsum + c * gox(x, a + k * h)
  end

  return (dsum + gox(x, b)) * h / 3
end

-- Black-box function #1 -- f(x)
function fox(a, b)
  return math.sin(a) + math.cos(b)
end

local function equal_eps(a,b)
  return math.abs(a - b) < 1e-6
end

-- Grey-box interface
function MyUserFunc(argval)
  local f
  if equal_eps(argval[1], 1) then
      local a = argval[2]
      local b = argval[3]
      f = fox(a, b)
  elseif equal_eps(argval[1], 2) then
      local n = math.floor(argval[2])
      local x = argval[3]
      f = Gox(n, x)
  else
      printf("Unknown function type %g\n", argval[1])
      error()
  end
  return f
end

function cbuser(pModel,primal)
  local val = 0
  val = MyUserFunc(primal)
  --printf("usercalc: %g\n",val)
  return val
end


function testUserCalc()
  local ymd,hms = xta:datenow(),xta:timenow() 
  local jsec = xta:jsec(ymd,hms)
  printf("%06d-%06d jsec:%d\n",ymd,hms,jsec)
  local res
  local pModel = solver:mpmodel()
  --pModel.logfun = myprintlog  
  local file=os.getenv("LINDOAPI_HOME") .. "/samples/c/ex_user/ex_user.mpi"
  file = cygpath_w(file)
  printf("Reading %s\n",file)  
  
  pModel.usercalc = cbuser
  pModel.logfun = myprintlog
  --pModel:setUsercalc(cbuser)
  local nErr = pModel:readfile(file,0)
  pModel:dispstats()
  local szmsg = sprintf("Error %d: %s\n",nErr,pModel:errmsg(nErr) or "N/A")
  assert(nErr==0,szmsg)
  assert(nErr==0)

  res = pModel:optimize()
  print_table3(res)

  pModel:dispose()
  gModel = nil
  print(solver)   
end

--- MAIN 
solver = xta:solver()
assert(solver,"\n\nError: failed create a solver instance.\n")
testUserCalc()
printf("Disposing %s\n",tostring(solver))  
solver:dispose()
