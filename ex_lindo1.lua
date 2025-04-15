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
  printf("usercalc: %g\n",val)
  return val
end

function probdir()
  local file=os.getenv("LS_PROB")
  if not file then
    file = "/home/mka/prob"
  end
  return file
end

function testSolverMPX()
 local ymd,hms = xta:datenow(),xta:timenow() 
 local jsec = xta:jsec(ymd,hms)
 printf("%06d-%06d jsec:%d\n",ymd,hms,jsec)
 
 local pModel = solver:mpmodel()
 
 local file=probdir() .. "/nlp/mpx/ex7_3_3.mpx"
 printf("Reading %s\n",file) 
 local res = pModel:readMPXFile(file)
 local szmsg = sprintf("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A")
 assert(res.ErrorCode==0,szmsg) 
 
 if pModel.nlpnonz==0 then
  res = pModel:writeLINDOFile(probdir() .. "/lp/ltx/err/a.ltx")
 end
 assert(res.ErrorCode==0)
 pModel.logfun = myprintlog
 res = pModel:solveGOP()
 if res.ErrorCode==0 then
  printf("pobj: %.7f\n",pModel.pobj and pModel.pobj or -99)
  printf("dobj: %.7f\n",pModel.dobj and pModel.dobj or -99)
 end
 local res = pModel:getHess()
 print_table3(res)
 pModel:dispose()
 print(solver) 
end

---
--
function testSolverLicense(solver)
  local licfile = os.getenv("LINDOAPI_HOME") .. "/license/lndapi150.lic"
  printf("\nLoading %s\n",licfile)
  local res = solver:loadLicenseString(licfile)
  print_table3(res)
  print(solver) 
end

---
--
function testSolverSETS()
 local ymd,hms = xta:datenow(),xta:timenow() 
 local jsec = xta:jsec(ymd,hms)
 printf("%06d-%06d jsec:%d\n",ymd,hms,jsec)
 local res
 local pModel = solver:mpmodel()
 --pModel.logfun = myprintlog
 local file=probdir() .. "/milp/mps/sos/multi1.mps"
 printf("Reading %s\n",file)
 local nErr = pModel:readfile(file,0)
 local szmsg = sprintf("Error %d: %s\n",nErr,pModel:errmsg(nErr) or "N/A")
 assert(nErr==0,szmsg)
 assert(nErr==0)
 
 pModel:setMIPCallback(cbmip)
 --pModel:setCallback(cbstd)
 
 res = pModel:solveMIP()
 print_table3(res)  
 szmsg = sprintf("Error %d: %s\n",nErr,pModel:errmsg(res.ErrorCode) or "N/A")
 assert(res.ErrorCode==0,szmsg) 
 if res.ErrorCode==0 then
  printf("pobj: %.7f\n",pModel.pobj and pModel.pobj or -99)
  printf("dobj: %.7f\n",pModel.dobj and pModel.dobj or -99)
 end
 
 local res = pModel:getSETSData()
 print_table3(res)  
 szmsg = sprintf("Error %d: %s\n",nErr,pModel:errmsg(res.ErrorCode) or "N/A")
 assert(res.ErrorCode==0,szmsg)
  
 if res.piNsets>0 then
  local res = pModel:getSETSDatai(0)
  print_table3(res)
  szmsg = sprintf("Error %d: %s\n",nErr,pModel:errmsg(res.ErrorCode) or "N/A")
  assert(res.ErrorCode==0,szmsg)
 end
 
 local res = pModel:getSemiContData()
 print_table3(res)  
 szmsg = sprintf("Error %d: %s\n",nErr,pModel:errmsg(res.ErrorCode) or "N/A")
 assert(res.ErrorCode==0,szmsg)

   
 pModel:dispose()
 print(solver) 
end


--- MAIN 
solver = xta:solver()
assert(solver,"\n\nError: failed create a solver instance.\n")
if 2>1 then
  testSolverLicense(solver)
  testSolverMPX()
  testSolverSETS()
end
printf("Disposing %s\n",tostring(solver))  
solver:dispose()
