#!/usr/bin/env lslua
-- File: ex_graybox.lua
-- Description: Derived from samples/c/ex_user3/ex_user3.c
 -- Author: mka
-- Date: 2025-04-01

local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local status = Lindo.status
require "llindo_usage"

local solver
local gModel, Xvec, csense

-- Parse command line arguments
local function usage(help_)
    print()
    print("Read a model from a supported file format and optimize or modify.")
    print()
    print("Usage: lslua ex_graybox.lua [options]")
    print()
    if help_ then print_default_usage() end
    print()
    print("App. Options:")
    printf("    -m, --model=[string]       Model file name (default: nil)\n")
    print("    , --xuserdll=[string]       Set user DLL (default: nil)")
	print("")
	if not help_ then print_help_option() end        
    print("Example:")
    print("\t lslua ex_graybox.lua -m /path/to/model.mps [options]")    	
    print("\t lslua ex_graybox.lua -m ~/prob/milp/mps/miplib3/p0201.mps.gz ") 
    print("\t lslua ex_graybox.lua -m ~/prob/lp/mps/netlib/25fv47.mps.gz ")     
    print("\t lslua ex_graybox.lua -m ~/prob/nlp/mpi/nonconvex/dejong.gz --gop")     
    print("\t lslua ex_graybox.lua -m ~/prob/nlp/mpi/nonconvex/dejong.gz --multis=10")     
	print()    
end   


function myprintlog(pModel,str)
  printf("%s",str)
end

function cbstd(pModel,iLoc)
  printf("loc: %d\n",iLoc)  
  return 0
end

-- Lua implementation of the user-defined function
function MyUserFunc(argval)
    -- Ensure argval is a table with at least 7 elements
    if #argval < 7 then
        error("argval must contain at least 7 elements: function ID followed by six variables.")
    end

    assert(Xvec,"Xvec not initialized")
    -- Extract variables from argval
    for k=1,gModel.numvars do
        Xvec[k] = argval[k+1]
    end
    local res_slk = gModel:calcConFunc(-1,Xvec)
    local f = 0
    local funcID = math.floor(argval[1]+0.5)
    local res
    if equal_eps(funcID, -1) then
        -- Objective function
        res = gModel:calcObjFunc(Xvec)      
        f = res.pdObjval  
    elseif funcID>=0 and funcID<=gModel.numcons then
        -- Constraint #funcID
        f = res_slk.padSlacks[funcID+1]        
        if csense[funcID+1] == 'L' then
            f = -f            
        end
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

function string_to_char_table(str)
    local t = {}
    for i = 1, #str do
      t[i] = str:sub(i, i)
    end
    return t
  end
  

function solve_graybox(options)
  local ymd,hms = xta:datenow(),xta:timenow() 
  local jsec = xta:jsec(ymd,hms)
  printf("%06d-%06d jsec:%d\n",ymd,hms,jsec)
  local res
  local pModel = solver:mpmodel()
  gModel = pModel
  pModel.logfun = myprintlog  
  printf("Reading %s\n",options.model_file)  
  --pModel:setUsercalc(cbuser)
  local nErr = pModel:readfile(options.model_file,0)
  pModel:dispstats()
  local szmsg = sprintf("Error %d: %s\n",nErr,pModel:errmsg(nErr) or "N/A")
  assert(nErr==0,szmsg)
  assert(nErr==0)

  res = pModel:loadData2Inst() -- to keep instructions for LP/QP
  pModel:wassert(res)

  pData = pModel:getLPData()
  --print_table3(pData)
  local numvars = pModel.numvars
  local numcons = pModel.numcons
  local objsense = pData.pdObjSense
  
  if 2>1 then
    local res = pModel:optimize()
    print_table3(res)
    local sol = pModel:getPrimalSolution()
    pModel:wassert(sol)
    res = pModel:calcObjFunc(sol.padPrimal)
    print_table3(res)
    res = pModel:calcConFunc(-1,sol.padPrimal)
    print_table3(res)
    sol.padSlacks = res.padSlacks
    sol.padPrimal:printmat()
    sol.padSlacks:printmat()
  end
  print(pData.pachConTypes)
  csense = string_to_char_table(pData.pachConTypes)
  res = pModel:getVarType()  
  pModel:wassert(res)
  local pachVarTypes = res.pachVarTypes
  local yModel = solver:mpmodel()
  yModel.usercalc = cbuser
  yModel.logfun = myprintlog  
  Xvec = xta:zeros(numvars)
  assert(pData.pachConTypes,"pData.pachConTypes not initialized")
  assert(pachVarTypes,"pachVarTypes not initialized")
  
  res = yModel:loadNLPDense(numcons,numvars,objsense,pData.pachConTypes,pachVarTypes,Xvec,pData.padL,pData.padU)
  yModel:wassert(res)
  
  if 0>1 then
    res = yModel:optimize()
    print_table3(res)
    if res.padPrimal then
        res.padPrimal:printmat()
        local padPrimal = res.padPrimal
        res = yModel:calcConFunc(-1,padPrimal)    
        print_table3(res)
        res.padSlacks:printmat()    
        print(pData.pachConTypes)
    end
  end
  local X={}
  local Jac={}
  local X0 = xta:zeros(numvars)
  local Y0 = yModel:calcConFunc(-1,X0).padSlacks
  local F0 = yModel:calcObjFunc(X0).pdObjval
  local M = xta:table()
  local F = xta:zeros(numvars)
  for k=1,numvars do
    X[k] = xta:zeros(numvars)
    X[k][k] = 1
    local res = yModel:calcConFunc(-1,X[k])
    yModel:wassert(res)
    Jac[k] = res.padSlacks - Y0  
    for r = 1,numcons do
      if csense[r] == 'L' then
        Jac[k][r] = -Jac[k][r]
      end
    end   
    Jac[k].name = "Jac[" .. k .. "]"    
    Jac[k]:printmat()
    M[k] = Jac[k]
    local res = yModel:calcObjFunc(X[k])
    yModel:wassert(res)
    F[k] = res.pdObjval - F0
  end
  M:print()
  F:printmat()



  yModel:dispose()
  pModel:dispose()
end

local short=""
local long={
    xuserdll = 1,
}
local options, opts, optarg = parse_options(arg,short,long)

if options.help then
	usage(true)
	return
end

if not options.model_file then
	usage(options.help)
	return
end	

--- MAIN 
solver = xta:solver()
assert(solver,"\n\nError: failed create a solver instance.\n")
solve_graybox(options)
printf("Disposing %s\n",tostring(solver))  
solver:dispose()
