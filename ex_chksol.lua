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
function display_solution_differences(xmip, xlp, eps)
  eps = eps or 1e-6
  
  if not xmip or not xlp then
    printf("Error: invalid solution vectors\n")
    return
  end
  
  local delta = xmip - xlp
  local n = delta.len
  local count = 0
  
  printf("\nNonzero differences (eps = %.2e):\n", eps)
  printf("%-8s %-15s %-15s %-15s\n", "Index", "MIP Value", "LP Value", "Difference")
  printf("%s\n", string.rep("-", 60))
  
  for i = 1, n do
    local diff = delta[i]
    local abs_diff = math.abs(diff)
    
    if abs_diff > eps then
      local mip_val = xmip[i]
      local lp_val = xlp[i]
      printf("%-8d %-15.7g %-15.7g %-15.7g\n", i-1, mip_val, lp_val, diff)
      count = count + 1
    end
  end
  
  if count == 0 then
    printf("No differences greater than eps = %.2e found\n", eps)
  else
    printf("\nTotal variables with differences > eps: %d\n", count)
  end
  printf("\n")
end


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
  -- gunzip -d lpsolfile if needed
  os.execute("gzip -d " .. lpsolfile)
  lpsolfile = lpsolfile:gsub("%.gz$","")
  res = pModel:readVarStartPoint(lpsolfile)
  assert(res.ErrorCode==0,string.format("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A"))
  os.execute("gzip " .. lpsolfile)
  lpsolfile = lpsolfile .. ".gz"  
  printf("\n")
  if file_exists(lpsolfile) then
    printf("Recompressed %s\n",lpsolfile .. ".gz")  
  else
    printf("Warning: failed to recompress %s\n",lpsolfile)  
  end
  

  local mipsolfile = get_mipsolu_filename(file)
  printf("MIP solution file %s\n",mipsolfile)  
  printf("Reading MIP solution file %s\n",mipsolfile)  
  mipsolfile = cygpath_w(mipsolfile)
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
  printf("|delta|_1 = %.7g\n",delta:norm(1))
  printf("|delta|_2 = %.7g\n",delta:norm(2))
  printf("|delta|_inf = %.7g\n",delta:norm(xta.const.inf))
  
  -- Display nonzero differences between MIP and LP solutions
  display_solution_differences(xmip, xlp, 1e-6)

  pModel:dispose()
  
end


--- MAIN 
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
