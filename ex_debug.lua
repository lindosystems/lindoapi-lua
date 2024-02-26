#!/usr/bin/env lslua
-- File: ex_debug.lua
-- Description: Example of debugging a model via IIS finder
-- Author: mka
-- Date: 2019-07-01

local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local status = Lindo.status
require 'ex_cbfun'
require 'llindo_usage'
local solver

---
-- Parse command line arguments
local function usage(help_)
    print()
    print("Read a model from a file and optimize or debug.") 
    print()
    if help_ then print_default_usage() end
    print()
    print("Usage: lslua ex_debug.lua [options]")
    print("Example:")
    print("\t lslua ex_debug.lua -m netlibinf/bgdbg1.mps.gz --iis_level=5 --iis_method=3 --iis_norm=1")
    print("")
    if not help_ then print_help_option() end    
    print()
end   

local short=""
local long={
    iis_level = 1,     
    iis_method = 1,
    iis_norm = 1,     
}
local options, opts, optarg = parse_options(arg,short,long)

if not options.model_file then
	usage()
	return
end	
if not options.iis_level then
    options.iis_level = 1   
end

if options.seed then
  if options.seed~=0 then
    math.randomseed(options.seed)
  else
    math.randomseed(os.time())
    glogger.info("Initialized random seed with %d (time)\n",os.time())
  end    
end

-- New solver instance
xta:setsolverdll("",8);
xta:setlindodll(options.lindomajor,options.lindominor)
solver = xta:solver()
glogger.info("Created a new solver instance %s\n",solver.version);
local ymd,hms = xta:datenow(),xta:timenow() 
local jsec = xta:jsec(ymd,hms)
glogger.info("Timestamp: %06d-%06d jsec:%d\n",ymd,hms,jsec)
local res
if options.model_file:find("LMDmodelOpgestuurdLINDOseptember2023c.mpi") then
    res = solver:setXSolverLibrary(94,"j:\\usr2\\LINGO\\64_20\\MyUser.dll")
    solver:xassert(res)
end

-- New model instance
local pModel = solver:mpmodel()
glogger.info("Created a new model instance\n");
pModel.usercalc=xta.const.size_max
if options.has_cblog>0 then    
	pModel.logfun = myprintlog
	glogger.info("Set a new log function for the model instance\n");
end	
pModel.utable = {}

-- Read model from file	
glogger.info("Reading %s\n",options.model_file)
local nErr = pModel:readfile(options.model_file,0)
res={}
res.ErrorCode=nErr;
pModel:xassert(res)

-- Set callback or logback
if options.has_cbmip>0 then 
	pModel:setMIPCallback(cbmip)
elseif options.has_cbstd>0 then	
	pModel:setCallback(cbstd)
end

if options.parfile then
    res = pModel:readModelParam(options.parfile)
    pModel:wassert(res)
end 

-- Solve model
local res_opt, res_rng 
if options.solve then 
    res_opt, res_rng = pModel:solve(options)
end    

if 0>1 then
    -- solve NLPs as LP
    print_table3(pModel:setModelIntParameter(pars.LS_IPARAM_IIS_USE_EFILTER,2))
end    

if options.iis_method then
    res=pModel:setModelIntParameter(pars.LS_IPARAM_IIS_METHOD,options.iis_method)
    pModel:xassert(res)
end    

if options.iis_norm then
    res=pModel:setModelIntParameter(pars.LS_IPARAM_IIS_INFEAS_NORM,options.iis_norm)
    pModel:xassert(res)
end    

local removed = {}
while true do
    if res_opt.pnSolStatus==status.LS_STATUS_OPTIMAL or 
        res_opt.pnSolStatus==status.LS_STATUS_FEASIBLE or
        res_opt.pnSolStatus==status.LS_STATUS_BASIC_OPTIMAL or
        res_opt.pnSolStatus==status.LS_STATUS_LOCAL_OPTIMAL or
        res_opt.pnSolStatus==status.LS_STATUS_NEAR_OPTIMAL or
        0>1 then
        glogger.info("A solution is found, infeasibilities are removed..\n")
        break
    else
        res = pModel:findIIS(options.iis_level)
        pModel:xassert(res)
        res = pModel:getIIS()
        pModel:xassert(res)
        print_table3(res)
        if res.paiCons then
            local paiCons = res.paiCons
            pModel:modifyConstraintType(1,paiCons,"N")
            printf("Removed constraint %d\n",paiCons[1] or -1)
            removed[#removed+1] = paiCons[1]
            if options.qa~='yes' then
                printf("Press enter to reoptimize or q to quit\n")
                local q = io.read()        
                if q=='q' then
                    break
                end
            end            
            res_opt, res_rng = pModel:solve(options)        
        else
            break
        end
    end
end

printf("Removed constraints: ")
print_table3(removed)
if 2>1 then
    for k=1,#removed do
        res = pModel:getConstraintDatai(removed[k])
        print_table3(res)
    end
    local fname = "tmp/debug.mpi"
    res = pModel:writeMPIFile(fname)
    pModel:xassert(res)
    if res.ErrorCode==0 then
        glogger.info("Exported reduced model to %s\n",fname)
    end
end
if 0>1 then
    res = pModel:getLPVariableDataj(0)
    print_table3(res)
end


-- Write model
if options.writeas then
    pModel:write(options.writeas)
end    
 
pModel:dispose()
glogger.info("Disposed model instance %s\n",tostring(pModel))  
solver:dispose()
glogger.info("Disposed solver instance %s\n",tostring(solver))  
