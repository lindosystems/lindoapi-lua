#!/usr/bin/env lslua
-- File: ex_user.lua
-- Description: Derived from samples/c/ex_user/ex_user.c
 -- Author: mka
-- Date: 2025-04-01

--[[
  @purpose: Solve an NLP that uses two black-box functions within
  the instruction-list interface.

            minimize f(x)
                G(x) <= 100
             0 <= x  <= 10

  The black-box functions are

    f(x)   the expression sin(pi*x)+cos(pi*x)
    G(x)   the integral[g(x),a,b)], where a,b constants specifying
           the limits of the integral.

  @remark : This application uses the Instruction Style Interface,
  where the instructions are imported from ex_user.mpi file.

  @remark : EP_USER operator is used in the instruction list to
  identify each black-box function and specify the number of
  arguments they take. For each function, the first argument
  is reserved to identify the function, whereas the rest are the
  actual arguments for the associated function.

  @remark : LSsetUsercalc() is used to set the user-defined
  MyUserFunc() function  as the gateway to the black-box functions.
  
]]
local Lindo = require("llindo_tabox")
require "llindo_usage"

local solver
function myprintlog(pModel,str)
  printf("%s",str)
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
  
end

--- MAIN 
solver = xta:solver()
assert(solver,"\n\nError: failed create a solver instance.\n")
testUserCalc()
printf("Disposing %s\n",tostring(solver))  
solver:dispose()
