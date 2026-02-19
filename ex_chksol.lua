#!/usr/bin/env lslua
-- File: ex_chksol.lua
 -- Author: mka
-- Date: 2025-08-30

--[[
  @purpose: Read a model and its lp and mip solutions from files and check the solutions.
  @usage: lslua ex_chksol.lua -m /path/to/model  
]]
local Lindo = require("llindo_tabox")
require 'ex_cbfun'
require "llindo_usage"

-- Helper function to check if a file exists
local function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

local solver
function myprintlog(pModel,str)
  printf("%s",str)
end

function cbstd(pModel,iLoc)
  printf("loc: %d\n",iLoc)  
  return 0
end

-- Display nonzero differences between two solution vectors
-- @param xmip MIP solution vector
-- @param xlp LP solution vector  
-- @param eps tolerance threshold (default 1e-6)
function display_solution_differences(pModel, xmip, xlp, eps)
  eps = eps or 1e-6
  
  if not xmip or not xlp then
    printf("Error: invalid solution vectors\n")
    return
  end
  
  local delta = xmip - xlp
  local n = delta.len
  local count = 0
  local xp = pModel:getPrimalSolution()  
  local dj = pModel:getReducedCosts()
  local res = pModel:getVarType()
  local vtype = res.pachVarTypes
  local data = pModel:getLPData()

  local lb = data.padL
  local ub = data.padU
  local c = data.padC
  
  -- Create a modified vtype string with binary detection
  local vtype_chars = {}
  for k=1,n do
    local char = vtype:sub(k,k)
    if char=='I' and lb[k]>=0 and ub[k]<=1 then
      vtype_chars[k] = 'B'  -- mark binary variable
    else
      vtype_chars[k] = char
    end
  end
  
  printf("\nNonzero differences (eps = %.2e):\n", eps)
  printf("%-6s %-13s %-13s ? %-13s | %-13s %-13s | %-13s %-13s %-5s\n", "Index", "MIP Value", "LP Value", "Difference", "Primal", "Reduced Cost", "Lower Bound", "Upper Bound", "Type")
  printf("%s\n", string.rep("-", 130))
  local objval_mip = xmip:yydotprod(c)
  local objval_lp = xlp:yydotprod(c)  
  for i = 1, n do
    local diff = delta[i]
    local abs_diff = math.abs(diff)
    
    if abs_diff > eps then
      local mip_val = xmip[i]
      local lp_val = xlp[i]
      local primal_val = xp.padPrimal and xp.padPrimal[i] or 0.0
      local reduced_cost = dj.padRedcosts and dj.padRedcosts[i] or 0.0
      local lower_bound = lb[i]
      local upper_bound = ub[i]
      local var_type = vtype_chars[i]
      printf("%-6d %-13.6g %-13.6g d= %-13.6g | %-13.6g %-13.6g | %-13g %-13g %-5s\n", 
             i-1, mip_val, lp_val, diff, primal_val, reduced_cost, lower_bound, upper_bound, var_type)
      count = count + 1
    end
  end
  
  if count == 0 then
    printf("No differences greater than eps = %.2e found\n", eps)
  else
    printf("\nTotal variables with differences > eps: %d (out of %d)\n", count, n)
    printf("Stats:\n")
    printf("numvars: %d (int: %d, bin: %d)\n", pModel.numvars, pModel.numint, pModel.numbin)
  end
  printf("Obj. values: MIP = %.6g, LP = %.6g (diff = %.6g)\n", objval_mip, objval_lp, objval_mip - objval_lp)
  printf("\n")
end

--- Check solution from repository files
-- @param cmdline options
function test_check_solution(options)
  local ymd,hms = xta:datenow(),xta:timenow() 
  local jsec = xta:jsec(ymd,hms)
  printf("%06d-%06d jsec:%d\n",ymd,hms,jsec)
  local res
  local pModel = solver:mpmodel()
  --pModel.logfun = myprintlog  
  local file=options.model_file
  file = cygpath_w(file)
  printf("Reading %s\n",file)  
  
  pModel.logfun = myprintlog
  --pModel:setUsercalc(cbuser)
  local nErr = pModel:readfile(file,0)
  pModel:dispstats()
  local szmsg = sprintf("Error %d: %s\n",nErr,pModel:errmsg(nErr) or "N/A")
  assert(nErr==0,szmsg)
  assert(nErr==0)

  local lpsolfile = get_lpsolu_filename(file)
  printf("Reading LP solution file %s\n",lpsolfile)
  lpsolfile = cygpath_w(lpsolfile)
  
  -- Check if the gzipped or uncompressed file exists
  local lpsolfile_nogz = lpsolfile:gsub("%.gz$","")
  local lpsolfile_exists = file_exists(lpsolfile) or file_exists(lpsolfile_nogz)
  
  if not lpsolfile_exists then
    printf("Warning: LP solution file not found. Skipping LP solution check.\n")
    printf("         Expected: %s or %s\n", lpsolfile, lpsolfile_nogz)
    printf("         The script will exit.\n")
    pModel:dispose()
    return
  end
  
  -- gunzip -d lpsolfile if needed
  if file_exists(lpsolfile) then
    os.execute("gzip -d " .. lpsolfile)
  end
  lpsolfile = lpsolfile_nogz
  
  res = pModel:readVarStartPoint(lpsolfile)
  assert(res.ErrorCode==0,string.format("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A"))
  
  -- Recompress if we unzipped it
  os.execute("gzip " .. lpsolfile)
  lpsolfile = lpsolfile .. ".gz"  
  printf("\n")
  if file_exists(lpsolfile) then
    printf("Recompressed %s\n",lpsolfile)  
  else
    printf("Warning: failed to recompress %s\n",lpsolfile)  
  end
  

  local mipsolfile = get_mipsolu_filename(file)
  printf("MIP solution file %s\n",mipsolfile)  
  printf("Reading MIP solution file %s\n",mipsolfile)  
  mipsolfile = cygpath_w(mipsolfile)
  
  if not file_exists(mipsolfile) then
    printf("Warning: MIP solution file not found: %s\n", mipsolfile)
    printf("         The script will exit.\n")
    pModel:dispose()
    return
  end
  
  res = pModel:readMipSolution(mipsolfile)
  assert(res.ErrorCode==0,string.format("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A"))

  res = pModel:getVarStartPoint()
  assert(res.ErrorCode==0,string.format("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A"))
  print_table3(res)
  local xlp = res.padPrimal

  res = pModel:getMIPVarStartPoint()
  assert(res.ErrorCode==0,string.format("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A"))
  print_table3(res)
  local xmip = res.padPrimal
  
  --xmip:printmat()
  --xlp:printmat()
  local delta = xmip - xlp
  --delta:printmat()

  res = pModel:optimize()

    -- Display nonzero differences between MIP and LP solutions
  display_solution_differences(pModel, xmip, xlp, 1e-6)

  printf("|delta|_1 = %.7g\n",delta:norm(1))
  printf("|delta|_2 = %.7g\n",delta:norm(2))
  printf("|delta|_inf = %.7g\n",delta:norm(xta.const.inf))
  
  res = pModel:solveMIP()
  
  pModel:dispose()
  
end

--- Usage function  
local function usage(help_)
    print()
    print("Read a model and its lp and mip solutions from files and check the solutions.")
    print()
    print("Usage: lslua ex_chksol.lua [options]")
    if help_ then print_default_usage() end
    print()
    if not help_ then print_help_option() end        
    print("Example:")
    print("\t lslua ex_chksol.lua -m /path/to/model.mps [options]")    
    print()
end


--- MAIN ---
local short=""
local long={
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
test_check_solution(options)
printf("Disposing %s\n",tostring(solver))  
solver:dispose()
