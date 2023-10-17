-- runlindo
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
    print("Read a model from a file and optimize or debug.")
    print()
    print("Usage: lua ex_debug.lua [options]")
    print("Example:")
    print("\t lua ex_debug.lua -m model.mps [options]")
    print()
    print_default_usage()
    print()
end   

local short="i:"
local long={
    iis_level = "i",
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

-- solve NLPs as LP
if 2>1 then
    print_table3(pModel:setModelDouParameter(pars.LS_IPARAM_IIS_USE_EFILTER,1))
end    

print_table3(status)
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
        local paiCons = res.paiCons
        pModel:modifyConstraintType(1,paiCons,"N")
        printf("Removed constraint %d\n",paiCons[1] or -1)
        removed[#removed+1] = paiCons[1]
        if 0>1 then
            printf("Press enter to reoptimize")
            io.read()        
        end            
        res_opt, res_rng = pModel:solve(options)        
    end
end    
print_table3(removed)


-- Write model
if options.writeas then
    pModel:write(options.writeas)
end    
 
pModel:dispose()
glogger.info("Disposed model instance %s\n",tostring(pModel))  
solver:dispose()
glogger.info("Disposed solver instance %s\n",tostring(solver))  
