#!/usr/bin/env lslua
local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info

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
function xsolve(options, model_file, results)    
    local solver
    local flag 
    local res
    
    solver = xta:solver()        
    assert(solver,"\nError: cannot create a solver instance\n")        
    glogger.info("Created a new solver instance %s\n",solver.version);    
    res = solver:setEnvLogfunc(myprintlog)
    solver:wassert(res)
    res = solver:setEnvIntParameter(pars.LS_IPARAM_SPLEX_USE_EXTERNAL, options.xsolver)
    solver:wassert(res)
    res = solver:setEnvIntParameter(pars.LS_IPARAM_MIP_PRINTLEVEL, 2)        
    solver:wassert(res)
    
    apply_solver_options(solver, options)     
    -- New model instance
    local pModel = solver:mpmodel()
    glogger.info("Created a new model instance\n");
    pModel.logfun = myprintlog
    glogger.info("Reading '%s'\n",model_file)
    local nErr = pModel:readfile(model_file,0)
    pModel:xassert({ErrorCode=nErr})    
    if options.solve>0 then
        pModel:set_params_user(options)   
        pModel:disp_params_non_default()                 
        res = pModel:solve(options)
        pModel:xassert(res)
        if not results then
            results = {}
        end
        if not results[model_file] then
            results[model_file] = {}
        end
        results[model_file][options.xdll] = res
    else
        glogger.info("Model %s ready, use --solve=1 to solve\n",model_file)
    end
    pModel:dispose()
    
    solver:dispose() 
    glogger.info("Disposed solver instance\n")
    solver = nil
    
    return results
end

function app_options(options, k, v)

end

-- Usage function
local function usage(help_)
	print()
	print("Test xsolvers.")
	print()
	print("Usage: lslua ex_xsolver.lua [options]")
	if help_ then print_default_usage() end
	print()
	print("    , --solve=<INTEGER>  Solve as tightened model")
	print()
	if not help_ then print_help_option() end        	    
	print("Example:")
	print("\t lslua ex_xsolver.lua [options]")
	print("")        	    
end   

---
-- Parse command line arguments
local long={
	}
local short = ""
options, opts, optarg = parse_options(arg,short,long)
--print_table3(options)
--print_table3(opts)
           
if options.help then
	usage(true)
	return
end

-- New solver instance
local ymd,hms = xta:datenow(),xta:timenow() 
local jsec = xta:jsec(ymd,hms)
printf("Timestamp: %06d-%06d jsec:%d\n",ymd,hms,jsec)

xta.loglevel = 2
local res
local results = {   }

for k,v in pairs(netlib) do    
    v = sprintf("%s/lp/mps/netlib/%s",probdir(),v)

    options.xsolver = 12
    options.xdll = "cbc"        
    res = xsolve(options, v, results)    

    options.xsolver = 14
    options.xdll = "liblindohighs"      
    res = xsolve(options, v, results)
    
    options.xsolver = 7
    if xta.platformid==xta.const.win64x86 then
        options.xdll = "cplex2211.dll"        
    else
        options.xdll = "cplex125.dll"        
    end
    res = xsolve(options, v, results)
    break
end


    
    
