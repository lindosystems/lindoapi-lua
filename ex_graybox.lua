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
    print("    , --solve=[bitmask]         +1: solve as graybox (default), +2: solve original, +4: solve graybox with Jacobian")
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

local res_slk 
local kount = 0
-- Lua implementation of the user-defined function
function MyUserFunc(argval)

    assert(Xvec,"Xvec not initialized")
    -- Extract variables from argval
    for k=1,gModel.numvars do
        Xvec[k] = argval[k+1]
    end
    local funcID = math.floor(argval[1]+0.5)    
    if funcID==0 then
      res_slk = gModel:calcConFunc(-1,Xvec)
      --printf("Computed slack values for all constraints\n")
      kount = kount + 1
    end
    local f = 0    
    local res
    if equal_eps(funcID, -1) then
        -- Objective function
        res = gModel:calcObjFunc(Xvec)      
        f = res.pdObjval  
    elseif funcID>=0 and funcID<=gModel.numcons then
        -- Constraint #funcID
        if res_slk then
          f = res_slk.padSlacks[funcID+1]        
        else
          res = gModel:calcConFunc(funcID,Xvec)
          f = res.padSlacks
        end
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
  
local function dense_to_sparse(J)
  local numcons = J.nrows
  local numvars = J.ncols  
  local pSparse = {}
  pSparse.paiArows = xta:izeros(0)
  pSparse.paiAcols = xta:izeros(numvars+1)
  pSparse.panAcols = xta:izeros(numvars)
  pSparse.padAcoef = xta:zeros(0)
  local nnz = 0
  pSparse.paiAcols[1] = 0
  for i=1,numvars do
    local col = J:at(i)        
    for j=1,numcons do
      if math.abs(col[j]) > 1e-12 then
        nnz = nnz + 1
        pSparse.paiArows:add(j-1)        
        pSparse.padAcoef:add(col[j])
        pSparse.panAcols[i] = pSparse.panAcols[i] + 1
      end      
    end
    pSparse.paiAcols[i+1] = nnz
  end
  --print_table3(pSparse)
  return pSparse
end

local function solve_graybox(options)
  local ymd,hms = xta:datenow(),xta:timenow() 
  local jsec = xta:jsec(ymd,hms)
  printf("%06d-%06d jsec:%d\n",ymd,hms,jsec)
  local res
  local oModel = solver:mpmodel()
  gModel = oModel
  oModel.logfun = myprintlog  
  printf("Reading %s\n",options.model_file)  
  --oModel:setUsercalc(cbuser)
  local nErr = oModel:readfile(options.model_file,0)
  oModel:dispstats()
  local szmsg = sprintf("Error %d: %s\n",nErr,oModel:errmsg(nErr) or "N/A")
  assert(nErr==0,szmsg)
  assert(nErr==0)

  if oModel.numinst == 0 then
    res = oModel:loadData2Inst() -- to keep instructions for LP/QP
    oModel:wassert(res)
  end

  local pData = oModel:getLPData()
  --print_table3(pData)
  local numvars = oModel.numvars
  local numcons = oModel.numcons
  local objsense = pData.pdObjSense
  
  -- Solve input model with standard solver (solve=2)
  if hasbit(options.solve,bit(2)) then --solve=2
    --oModel:setModelParameter(pars.LS_IPARAM_NLP_SOLVE_AS_LP,1)
    --oModel:setModelParameter(pars.LS_IPARAM_NLP_USE_LINDO_CRASH,1)
    local res = oModel:solve(options)
    print_table3(res)
    if res.pnSolStatus==status.LS_STATUS_OPTIMAL or 
        res.pnSolStatus==status.LS_STATUS_LOCAL_OPTIMAL or
        res.pnSolStatus==status.LS_STATUS_BASIC_OPTIMAL then          
      local sol = oModel:getPrimalSolution()
      oModel:wassert(sol)
      res = oModel:calcObjFunc(sol.padPrimal)
      print_table3(res)
      res = oModel:calcConFunc(-1,sol.padPrimal)
      print_table3(res)
      sol.padSlacks = res.padSlacks
      sol.padPrimal:printmat()
      sol.padSlacks:printmat()
    end
  end
  printf("Constraint types: \n")
  print(pData.pachConTypes)
  print()
  printf("Objective sense: %s\n",objsense)
  print()
  csense = string_to_char_table(pData.pachConTypes)
  res = oModel:getVarType()  
  oModel:wassert(res)
  local pachVarTypes = res.pachVarTypes

  -- Set up the graybox model
  local pModel = solver:mpmodel()
  pModel.usercalc = cbuser
  pModel.logfun = myprintlog  
  Xvec = xta:zeros(numvars)
  assert(pData.pachConTypes,"pData.pachConTypes not initialized")
  assert(pachVarTypes,"pachVarTypes not initialized")
  local tstart = xta:tic()
  printf("Loading graybox model..")
  res = pModel:loadNLPDense(numcons,numvars,objsense,pData.pachConTypes,pachVarTypes,Xvec,pData.padL,pData.padU)
  pModel:wassert(res)
  printf("done in %.2f sec\n",xta:toc(tstart))
  
  -- Solve the input model after it is wrapped in a graybox model (solve=1)
  if hasbit(options.solve,bit(1)) then --solve=1
    --pModel:setModelParameter(pars.LS_IPARAM_NLP_SOLVE_AS_LP,1)
    pModel:setModelParameter(pars.LS_IPARAM_NLP_SOLVER,11)
    --pModel:setModelParameter(pars.LS_IPARAM_NLP_FEASCHK,2)
    pModel:setModelParameter(pars.LS_IPARAM_NLP_PRINTLEVEL,10)
    pModel:setModelParameter(pars.LS_IPARAM_LP_PRINTLEVEL,2)
    if pModel.numint + pModel.numbin > 0 then
      res = pModel:solveMIP()
      pModel:wassert(res)
    else
      res = pModel:optimize()
      pModel:wassert(res)
    end   
    print_table3(res)
    if res.padPrimal then
        res.padPrimal:printmat()
        local padPrimal = res.padPrimal
        res = pModel:calcConFunc(-1,padPrimal)    
        print_table3(res)
        res.padSlacks:printmat()    
        print(pData.pachConTypes)
    end
  end


  
  -- Construct the LP approximation explictly and solve (solve=4)
  if hasbit(options.solve,bit(3)) then -- --solve=4
    printf("Solving graybox model as LP approximation explicitly..\n")
    printf("Calculating Jacobian and gradient..\n")
    local X={}
    local Jac={}
    local X0 = xta:zeros(numvars)
    local Y0 = pModel:calcConFunc(-1,X0).padSlacks
    local F0 = pModel:calcObjFunc(X0).pdObjval
    local J = xta:table()
    local F = xta:zeros(numvars)
    local count = 0
    for k=1,numvars do
      X[k] = xta:zeros(numvars)
      X[k][k] = 1
      local res = pModel:calcConFunc(-1,X[k])
      pModel:wassert(res)
      Jac[k] = res.padSlacks - Y0  
      for r = 1,numcons do
        if csense[r] == 'L' then
          Jac[k][r] = -Jac[k][r]
        end
      end   
      Jac[k].name = "Jac[" .. k .. "]"    
      --Jac[k]:printmat()
      J[k] = Jac[k]
      local res = pModel:calcObjFunc(X[k])
      pModel:wassert(res)
      F[k] = res.pdObjval - F0
      if k % 10 == 0 then
        printf("*");
        count = count + 1
        if count % 10 == 0 then
          printf(" :%d .. %.2f secs\n",count,xta:toc(tstart))
        end            
      end
    end
    printf("\nDone in %.2f sec, kount=%d\n",xta:toc(tstart),kount)    
    local yModel
    -- J is the Jacobian of the constraints, and F is the gradient of the objective function
    -- Construct the sparse matrix representation of J to load into the solver
    yModel = solver:mpmodel()
    yModel.logfun = myprintlog    
    local pSparse = dense_to_sparse(J)
    res = yModel:loadLPData(
      pData.pdObjSense,
      pData.pdObjConst,
      F,
      pData.padB,
      pData.pachConTypes,
      pSparse.paiAcols,
      pSparse.panAcols,
      pSparse.padAcoef,
      pSparse.paiArows,
      pData.padL,
      pData.padU)
    yModel:wassert(res)    
    if oModel.numint + oModel.numbin > 0 then
      res = yModel:loadVarType(pachVarTypes)
      yModel:wassert(res)
      res = yModel:solveMIP()
      yModel:wassert(res)
    else
      res = yModel:optimize()
      yModel:wassert(res)
    end    
    if options.verb>1 then
      yModel:writeMPSFile("graybox-l.mps",0)
    else
      printf("Set --verb=2 to write graybox-l.mps\n")
    end
    print_table3(res)
    if res.padPrimal then
        res.padPrimal:printmat()
        local padPrimal = res.padPrimal
        res = yModel:calcConFunc(-1,padPrimal)    
        print_table3(res)
        res.padSlacks:printmat()    
        print(pData.pachConTypes)
    end
    yModel:dispose()
  end

  if options.verb>1 then
    J:print("J.csv")  
    F:print("G.csv")
    printf("Written Jacobian (J.csv) and Gradient (G.csv)..\n")
  else
    printf("Set --verb=2 to write Jacobian (J.csv) and Gradient (G.csv)..\n")
  end

  pModel:dispose()   
  oModel:dispose()
end

--------------------------------------------------
--- MAIN 
--- Parse command line arguments and run
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

solver = xta:solver()
assert(solver,"\n\nError: failed create a solver instance.\n")
solve_graybox(options)
printf("Disposing %s\n",tostring(solver))  
solver:dispose()
