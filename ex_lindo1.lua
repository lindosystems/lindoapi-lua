#!/usr/bin/env lslua
-- File: ex_lindo1.lua
-- Description: Example of using the Lindo API to read a model file and 
 --             perform various solver operations
-- Author: mka
-- Date: 2019-07-01
local Lindo = require("llindo_tabox")
local gModel 
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


function cbuser(pModel,primal)
  local val = 0
  for k,v in ipairs(primal) do
    val = val + v
  end
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

function testUserDll()
  local ymd,hms = xta:datenow(),xta:timenow() 
  local jsec = xta:jsec(ymd,hms)
  printf("%06d-%06d jsec:%d\n",ymd,hms,jsec)
  local res
  local pModel = solver:mpmodel()
  --pModel.logfun = myprintlog  
  local file=os.getenv("LINDOAPI_HOME") .. "/samples/c/ex_user/ex_user.mpi"
  printf("Reading %s\n",file)  
  gModel = pModel  
  pModel.usercalc = cbuser
  --pModel:setUsercalc(cbuser)
  local nErr = pModel:readfile(file,0)
  pModel:dispstats()
  local szmsg = sprintf("Error %d: %s\n",nErr,pModel:errmsg(nErr) or "N/A")
  assert(nErr==0,szmsg)
  assert(nErr==0)
  pModel.usercalc = 0

  res = pModel:optimize()
  print_table3(res)

  pModel:dispose()
  gModel = nil
  print(solver)   
end

--- MAIN 
solver = xta:solver()
assert(solver,"\n\nError: failed create a solver instance.\n")
if 0>1 then
  testSolverLicense(solver)
  testSolverMPX()
  testSolverSETS()
end
testUserDll()
printf("Disposing %s\n",tostring(solver))  
solver:dispose()
