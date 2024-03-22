#!/usr/bin/env lslua
local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local SF = require 'LuaSF' -- for random number generation

-- config
require 'ex_cbfun'
require 'llindo_usage'
local options, opts, optarg

local netlib = {
    "pilot87.mps.gz",
    "pilot4.mps.gz",
    "pilotnov.mps.gz",
}

local miplib3 = {
    "stein45.mps.gz",
    "pk1.mps.gz",
}

---
function create_new_model(solver,model_file,options)
    -- New model instance
    local pModel = solver:mpmodel()
    glogger.info("Created a new model instance\n");
    pModel.logfun = myprintlog    
    glogger.info("Reading '%s'\n",model_file)
    local nErr = pModel:readfile(model_file,0)
    pModel:xassert({ErrorCode=nErr})    
    return pModel
end


--- 
function modify_model(pModel, options)    
    local res = {ErrorCode=errs.LSERR_NOT_SUPPORTED}
    pModel:disp_params_non_default() 
    pModel:set_params_user(options)
    if options.modtype == "rhs" then
      glogger.error("Not implemented yet\n")
    elseif options.modtype == "lb" then
        glogger.error("Not implemented yet\n")
    elseif options.modtype == "ub" then
      glogger.error("Not implemented yet\n")
    elseif options.modtype == "objective" then      
      local nVars = math.floor(pModel.numvars/3)+1
      local perm = xta:randperm(pModel.numvars)
      local paiVars = xta:izeros(nVars)
      local padC = xta:zeros(nVars) 
      for i=1,nVars do
          paiVars[i] = perm[i] - 1 -- 0-based
          padC[i] = SF.gamVA(0.1,0.5)
      end
      res = pModel:modifyObjective(nVars,paiVars,padC)
      pModel:xassert(res)
      glogger.info("Modified %d coeff in the objective\n",nVars)
    else
        glogger.error("Unknown modification type '%s'\n",options.modtype)
    end
    return res
end

--- 
function solve_model(pModel)
  local res
  pModel:disp_params_non_default()                 
  res = pModel:solve(options)
  pModel:xassert(res)
  return res
end

-- parse app specific options
function app_options(options, k, v)
  if k=="dist" then options.dist = v
  elseif k=="modtype" then options.modtype = v
  else
    printf("Unknown option '%s'\n",k)
  end
end

-- Usage function
local function usage(help_)
	print()
	print("Test ex_modify.")
	print()
	print("Usage: lslua ex_modify.lua [options]")
	if help_ then print_default_usage() end
	print()
	print("    , --solve=<INTEGER>                  Solve modified model")
  print("    , --dist=<distName,arg1,arg2,..>     Distribution of random numbers (default: geometricVA,0.5)")
  print("    , --modtype=<STRING>                 Type of modification")  
	print()
	if not help_ then print_help_option() end        	    
	print("Example:")
	print("\t lslua ex_modify.lua [options]")
  print("\t lslua ex_modify.lua --dist=geometricVA,0.5 --modtype=objective --seed=1234")
  print("\t lslua ex_modify.lua --dist=chiSquareVA,10 --modtype=rhs")
  print("\t lslua ex_modify.lua --dist=gamVA,0.5,0.5 --modtype=lb")
  print()
  printf(" Supported distributions:\n")
  local supported_distributions_usage = {
    "lognoRandVA(10, 2)",
    "normalVA(10, 2)",
    "lognoVA(10, 2)",
    "normal_inv_D(0.5, 10, 2)",
    "gamVA(10, 2)",
    "chiSquareVA(10)",
    "poissonVA(10)",
    "geometricVA(0.5)",
    "binomialVA(10, 0.5)",
    "trianVA(1,2,3)",
    "erlangVA(10, 2)",
    "weibullVA(10, 2)",
    "expoVA(10)",
    "unifVA(1, 10)",
    "bernoulliVA(0.5)",
    "normalVA(10, 2)"
  }
  for _, dist in ipairs(supported_distributions_usage) do
    printf("\t %s \n",dist)
  end
  print()
end
---
-- Parse command line arguments
local long={
  dist = 1,   -- distribution of random numbers, 
  modtype = 1,  -- type of modification
	}
local short = ""
options, opts, optarg = parse_options(arg,short,long)
--print_table3(options)
--print_table3(opts)
           
if options.help then
	usage(true)
	return
end

if options.modtype == nil then
  usage(options.help)
  return
end

-- New solver instance
local ymd,hms = xta:datenow(),xta:timenow() 
local jsec = xta:jsec(ymd,hms)
printf("Timestamp: %06d-%06d jsec:%d\n",ymd,hms,jsec)

xta.loglevel = 2
local res
local results = {   }

local solver = xta:solver()        
assert(solver,"\nError: cannot create a solver instance\n")        
glogger.info("Created a new solver instance %s\n",solver.version);    
res = solver:setEnvLogfunc(myprintlog)
solver:wassert(res)
res = solver:setEnvIntParameter(pars.LS_IPARAM_SPLEX_USE_EXTERNAL, options.xsolver)
solver:wassert(res)
res = solver:setEnvIntParameter(pars.LS_IPARAM_MIP_PRINTLEVEL, 2)        
solver:wassert(res)
apply_solver_options(solver, options)     

-- if a model file is specified, then work with it, otherwise work with the netlib models
if options.model_file then
    netlib = {options.model_file}
end

for k,v in pairs(netlib) do    
    if not paths.path(v) then            
      v = sprintf("%s/lp/mps/netlib/%s",probdir(),v)
    end
    local pModel = create_new_model(solver,v,options)
    res = modify_model(pModel, options)
    pModel:wassert(res)
    if res.ErrorCode==0 and options.solve>0 then
        res = solve_model(pModel)
    end
    pModel:dispose()
    pModel = nil
    glogger.info("Disposed model instance\n")
    print()
end


solver:dispose() 
glogger.info("Disposed solver instance\n")
solver = nil

    
