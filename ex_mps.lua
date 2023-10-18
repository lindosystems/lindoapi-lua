-- File: ex_mps.lua
-- Description: Example of reading a model from an MPS file and optimizing it.
-- Author: [Your Name Here]
-- Date: [Date Here]

local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local status = Lindo.status
require 'ex_cbfun'

local solver

---
-- Parse command line arguments
local function usage()
    print()
    print("Read a model from an MPS file and optimize or modify.")
    print()
    print_default_usage()
    print()
    print("Usage: lua ex_mps.lua [options]")
    print("Example:")
    print("\t lua ex_mps.lua -m /path/to/model.mps [options]")
    print()
end   

local short=""
local long={}
local options, opts, optarg = parse_options(arg,short,long)

if not options.model_file then
	usage()
	return
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
if 0>1 then
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

-- Read model from file	
glogger.info("Reading %s\n",options.model_file)
local nErr = pModel:readfile(options.model_file,0)
pModel:xassert({ErrorCode=nErr})

local res_lp 
-- res_lp = pModel:getLPData() 
if res_lp and 0>1 then
    --print_table3(res_lp)    
    if 0>1 then
        res_lp.padU:printmat(20)
        res_lp.padL:printmat(20)
    end
    local d = res_lp.padU- res_lp.padL
    printf("min |u-l|=%g\n",d.min)
    printf("max |u-l|=%g\n",d.max)
    local eps = math.pow(10,-15)
    if d.min<eps then
        d=d+eps
    end
    local ld = xta:LOG10(d)
    local h 
    h = ld:histogram()
    if h then
        h:print()
        local idx = d:find(0)
        if idx then
            idx:printmat()
        end
    end    
    solver:dispose()
    return
end

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

if res_rng then
	if options.verb>2 then print_table3(res_rng) end
    if options.verb>1 then
	  res_rng.padDec:printmat(6,nil,12,nil,'.3e')
    end
end	

if res_opt then
	if options.verb>2 then print_table3(res_opt) end
    if res_opt.padPrimal then
        if options.verb>1 then
            res_opt.padPrimal:printmat(6,nil,12,nil,'.3e')
        end
    else
        glogger.info("No primal solution\n")
    end
end	

if options.writeas then
    pModel:write(options.writeas)
end    
 
pModel:dispose()
glogger.info("Disposed model instance %s\n",tostring(pModel))  
solver:dispose()
glogger.info("Disposed solver instance %s\n",tostring(solver))  
