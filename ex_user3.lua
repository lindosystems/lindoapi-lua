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

local function equal_eps(a,b)
    return math.abs(a - b) < 1e-6
  end

-- Lua implementation of the user-defined function
function MyUserFunc(argval)
    -- Ensure argval is a table with at least 7 elements
    if #argval < 7 then
        error("argval must contain at least 7 elements: function ID followed by six variables.")
    end

    -- Extract variables from argval
    local X1 = argval[2]
    local X2 = argval[3]
    local X3 = argval[4]
    local X4 = argval[5]
    local X5 = argval[6]
    local X6 = argval[7]

    local f = 0
    local funcID = argval[1]

    if equal_eps(funcID, -1) then
        -- Objective function
        f = -10.5 * X1 - 7.5 * X2 - 3.5 * X3 - 2.5 * X4 - 1.5 * X5 - 10 * X6
            - 0.5 * X1^2 - 0.5 * X2^2 - 0.5 * X3^2 - 0.5 * X4^2 - 0.5 * X5^2
    elseif equal_eps(funcID, 0) then
        -- Constraint #1
        f = 6 * X1 + 3 * X2 + 3 * X3 + 2 * X4 + X5 - 6.5
    elseif equal_eps(funcID, 1) then
        -- Constraint #2
        f = 10 * X1 + 10 * X3 + X6 - 20
    else
        printf("Unrecognized function ID %g\n",funcID);
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
  local file=os.getenv("LINDOAPI_HOME") .. "/samples/c/ex_user3/ex_user3.mpi"
  file = cygpath_w(file)
  printf("Reading %s\n",file)  
  local options = {}
  options.method = 0
  pModel.usercalc = cbuser
  pModel.logfun = myprintlog
  --pModel:setUsercalc(cbuser)
  local nErr = pModel:readfile(file,0)
  pModel:dispstats()
  local szmsg = sprintf("Error %d: %s\n",nErr,pModel:errmsg(nErr) or "N/A")
  assert(nErr==0,szmsg)
  assert(nErr==0)

  res = pModel:solve(options)
  print_table3(res)
  if res.padPrimal then
    res.padPrimal:printmat()
    local padPrimal = res.padPrimal
    local res = pModel:calcObjFunc(padPrimal)
    print_table3(res)
  
  end

  pModel:dispose()
  
end

--- MAIN 
solver = xta:solver()
assert(solver,"\n\nError: failed create a solver instance.\n")
testUserCalc()
printf("Disposing %s\n",tostring(solver))  
solver:dispose()
