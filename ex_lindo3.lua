#!/usr/bin/env lslua
-- File: ex_lindo3.lua
-- Description: Example of using the Lindo API to 
--  1. setup a model with linear constraints
--  2. designate integer variables
--  3. solve the model 
--  4. set up another model using first model's data
--  5. solve the second model
--  6. sample calls to get/set parameters
-- Author: mka
-- Date: 2019-07-01

local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info

function myprintlog(pModel,str)
  printf("%s",str)
end

function myprintlog2(pModel,str)
  printf("%s",str)
  if pModel.utable and pModel.utable.ncalls  then
    pModel.utable.ncalls=pModel.utable.ncalls+1
  end
  --print_table3(pModel.utable)
end

--- Sample 1
-- Generated by LSwriteSrcFile (mode=+1). 
function solver_ex3()
 -- begin LP data

-------- Model sizes, objective sense and constant
  local      ierr = 0;
  local     nCons = 27;
  local     nVars = 32;
  local     dObjSense = 1;
  local     dObjConst = 0;
-------- Objective coefficients
  local  padC= 
  {
    0,  -0.4,  0,  0,  0,  0, 
    0,  0,  0,  0,  0,  0, 
    -0.32,  0,  0,  0,  -0.6,  0, 
    0,  0,  0,  0,  0,  0, 
    0,  0,  0,  0,  -0.48,  0, 
    0,  10,   
  };

-------- RHS values
  local  padB= 
  {
    0,  0,  80,  0,  0,  0, 
    80,  0,  0,  0,  0,  0, 
    500,  0,  0,  44,  500,  0, 
    0,  0,  0,  0,  0,  0, 
    0,  310,  300,   
  };

-------- Constraint types
  local  pszConTypes= 
   "EELLEELLLLEE"..
   "LLEELLLLLLLL"..
   "LLL"


--------  Total nonzeros in A matrix
  local     nAnnz = 83;
--------  Column offset
  local  paiAcols= 
  {
               0,             4,             6,             8,            10,            14, 
              18,            22,            26,            28,            30,            32, 
              34,            36,            38,            40,            44,            46, 
              48,            50,            52,            56,            60,            64, 
              68,            70,            72,            74,            76,            78, 
              80,            82,            83,   
  };

--------  Column counts
  local  panAcols= 
  {
               4,             2,             2,             2,             4,             4, 
               4,             4,             2,             2,             2,             2, 
               2,             2,             2,             4,             2,             2, 
               2,             2,             4,             4,             4,             4, 
               2,             2,             2,             2,             2,             2, 
               2,             1,   
  };

--------  A coeff
  local  padAcoef= 
  {
    0.301,  -1,  -1.06,  1,  -1,  1, 
    -1,  1,  1,  1,  0.301,  -1, 
    -1.06,  1,  0.313,  -1,  -1.06,  1, 
    0.313,  -1,  -0.96,  1,  0.326,  -1, 
    -0.86,  1,  2.364,  -1,  2.386,  -1, 
    2.408,  -1,  2.429,  -1,  1.4,  1, 
    -1,  1,  1,  1,  0.109,  -1, 
    -0.43,  1,  -1,  1,  -1,  1, 
    -1,  1,  1,  1,  0.109,  -0.43, 
    1,  1,  0.108,  -0.43,  1,  1, 
    0.108,  -0.39,  1,  1,  0.107,  -0.37, 
    1,  1,  2.191,  -1,  2.219,  -1, 
    2.249,  -1,  2.279,  -1,  1.4,  -1, 
    -1,  1,  1,  1,  1,   
  };

--------- Row indices
  local  paiArows= 
  {
              23,             0,             1,             2,             3,             0, 
              21,             0,            25,             1,            24,             4, 
               5,             6,            24,             4,             5,             7, 
              24,             4,             5,             8,            24,             4, 
               5,             9,            20,             6,            20,             7, 
              20,             8,            20,             9,             3,             4, 
              22,             4,            26,             5,            21,            10, 
              11,            12,            13,            10,            23,            10, 
              20,            10,            25,            11,            22,            14, 
              15,            16,            22,            14,            15,            17, 
              22,            14,            15,            18,            22,            14, 
              15,            19,            20,            16,            20,            17, 
              20,            18,            20,            19,            13,            15, 
              24,            15,            26,            14,            15,   
  };

-------- Lower bounds
  local  padL= 
  {
    0,  0,  0,  0,  0,  0, 
    0,  0,  0,  0,  0,  0, 
    0,  0,  0,  0,  0,  0, 
    0,  0,  0,  0,  0,  0, 
    0,  0,  0,  0,  0,  0, 
    0,  0,   
  };

-------- Upper bounds
  local  padU= 
  {
    1e+030,  1e+030,  1e+030,  1e+030,  1e+030,  1e+030, 
    1e+030,  1e+030,  1e+030,  1e+030,  1e+030,  1e+030, 
    1e+030,  1e+030,  1e+030,  1e+030,  1e+030,  1e+030, 
    1e+030,  1e+030,  1e+030,  1e+030,  1e+030,  1e+030, 
    1e+030,  1e+030,  1e+030,  1e+030,  1e+030,  1e+030, 
    1e+030,  1e+030,   
  };
  
-------- Load LP data  
   local solver = xta:solver() 
   local pModel = solver:mpmodel()   
      
   ierr = pModel:loadlp(
               dObjSense,
               dObjConst,
               xta:field(padC,"padC","double"),
               xta:field(padB,"padB","double"),
               pszConTypes,
               xta:field(paiAcols,"paiAcols","int"),
               xta:field(panAcols,"panAcols","int"),
               xta:field(padAcoef,"padAcoef","double"),
               xta:field(paiArows,"paiArows","int"),
               xta:field(padL,"padL","double"),
               xta:field(padU,"padU","double") )
 	local szmsg = sprintf("Error %d: %s\n",ierr,pModel:errmsg(ierr) or "N/A")
 	assert(ierr==0,szmsg)
 -- end LP/QP/CONE data




 -- begin INTEGER data

 -- begin INTEGER data

--------  Variable type
  local  pszVarTypes= 
   "ICCCCCCCCCCI"..
   "ICCCCCCCCCCI"..
   "ICCCCCCC"


   local res = pModel:loadVarType(pszVarTypes);
 	 local szmsg = sprintf("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A")
 	 assert(res.ErrorCode==errs.LSERR_NO_ERROR,szmsg)
 -- end INTEGER data

   pModel.logfun = myprintlog
   
   local nStatus
   local res = pModel:solveMIP()
   szmsg = sprintf("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A")
   assert(res.ErrorCode==errs.LSERR_NO_ERROR,szmsg)   

   local pData = {}   
   --pData.ErrorCode,pData.pdObjSense,pData.pdObjConst,pData.padC,pData.padB,pData.pachConTypes,pData.paiAcols,pData.panAcols,pData.padAcoef,pData.paiArows,pData.padL,pData.padU = pModel:getLPData()
   pData = pModel:getLPData()
   print_table3(pData)
   pData.padC:print()
   printf("%s\n",pData.pachConTypes)
   
   local yModel = solver:mpmodel()
   
   local res = yModel:loadLPData(
               pData.pdObjSense,
               pData.pdObjConst,
               pData.padC,
               pData.padB,
               pData.pachConTypes,
               pData.paiAcols,
               pData.panAcols,
               pData.padAcoef,
               pData.paiArows,
               pData.padL,
               pData.padU)
   print_table3(res)
   local szmsg = sprintf("Error %d: %s\n",res.ErrorCode,yModel:errmsg(res.ErrorCode) or "NA")
   assert(res.ErrorCode==errs.LSERR_NO_ERROR,szmsg)
   
   yModel.logfun = myprintlog
   res = yModel:setModelIntParameter(pars.LS_IPARAM_LP_PRELEVEL,0)
   print_table3(res)
   
   res = yModel:optimize()
   szmsg = sprintf("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "NA")
   assert(res.ErrorCode==errs.LSERR_NO_ERROR,szmsg)    
   
   res = yModel:getPrimalSolution()
   print_table3(res)  
   szmsg = sprintf("Error %d: %s\n",res.ErrorCode,yModel:errmsg(res.ErrorCode) or "N/A")
   assert(res.ErrorCode==0,szmsg)
   
   local result = {}
   result.jstrPrimal = res.padPrimal:ser()

   -- Test ftran/btran ops
   local k = 5
   local nz_ak=pData.panAcols[k]
   local ibeg=pData.paiAcols[k]
   local iend=pData.paiAcols[k+1]
   local ia_k=pData.paiArows:copy("ia_k",ibeg+1,iend)
   local a_k=pData.padAcoef:copy("a_k",ibeg+1,iend)
   a_k:printmat()
   ia_k:printmat()
   local vec =yModel:doFTRAN(nz_ak,ia_k,a_k)
   print_table3(vec)
   if vec.ErrorCode==errs.LSERR_NO_ERROR then
     vec.padX:printmat()
     vec.paiX:printmat()
     local vec =yModel:doBTRAN(nz_ak,ia_k,a_k)
     print_table3(vec)  
     vec.padX:printmat()
     vec.paiX:printmat()
   else
    printf("Warning: doFTRAN failed error:%s\n",yModel:errmsg(vec.ErrorCode))   
   end

   -- get solver/environment parameters and display
   print_table3(solver:getParamMacroName(pars.LS_IPARAM_LP_PRELEVEL))
   print_table3(solver:getParamLongDesc(pars.LS_IPARAM_LP_PRELEVEL))
   print_table3(solver:getParamShortDesc(pars.LS_IPARAM_LP_PRELEVEL))
   
   -- get/set model parameters
   res = yModel:getModelIntParameter(pars.LS_IPARAM_LP_PRELEVEL)
   print_table3(res)   
   print_table3(yModel:getIntParamRange(pars.LS_IPARAM_LP_PRELEVEL))
   print_table3(yModel:getDouParamRange(pars.LS_DPARAM_SOLVER_FEASTOL))
   print_table3(yModel:getModelIntParameter(pars.LS_IPARAM_LP_PRELEVEL))
   print_table3(yModel:getModelDouParameter(pars.LS_DPARAM_SOLVER_FEASTOL))
   print_table3(yModel:setModelDouParameter(pars.LS_DPARAM_SOLVER_FEASTOL,yModel:getModelDouParameter(pars.LS_DPARAM_SOLVER_FEASTOL).pValue*2))
   print_table3(yModel:getModelDouParameter(pars.LS_DPARAM_SOLVER_FEASTOL))
   
   
 -- begin QCP data

 -- end QCP data
   


 -- begin CONE data

 -- end CONE data




 -- begin SETS data

 -- end SETS data




 -- begin SC data

 -- end SC data

   printf("Disposing %s\n",tostring(solver))
   solver:dispose()  
   return result
end   


-- MAIN
local result = solver_ex3()
print_table3(result)
local fPrimal = xta:field(0,"primal","double")
fPrimal:des(result.jstrPrimal)
fPrimal:print()