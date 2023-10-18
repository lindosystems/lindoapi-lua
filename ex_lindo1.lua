-- File: ex_lindo1.lua
-- Description: Example of using the Lindo API to read a model file and 
 --             perform various solver operations
-- Author: [Your Name Here]
-- Date: [Date Here]
local Lindo = require("llindo_tabox")

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
function testSolverLicense()
  local licfile = os.getenv("LINDOAPI_HOME") .. "/license/lndapi130.lic"
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

solver = xta:solver()
testSolverLicense()
testSolverMPX()
testSolverSETS()
printf("Disposing %s\n",tostring(solver))  
solver:dispose()
