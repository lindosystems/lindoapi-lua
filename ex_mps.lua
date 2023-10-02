--
-- luatabox unit tests

require 'ex_cbfun'

-- runlindo
local Lindo = require("base_lindo")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local status = Lindo.status

local solver

---
-- Parse command line arguments
local function usage()
    print()
    print("Read a model from an MPS file and optimize or modify.")
    print()
    print("Usage: lua ex_mps.lua [options]")
    print("Example:")
    print("\t lua ex_mps.lua -m model.mps [options]")
    print()
    print_default_usage()
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
    printf("Initialized random seed with %d (time)\n",os.time())
  end    
end

-- New solver instance
xta:setsolverdll("",8);
xta:setlindodll(options.lindomajor,options.lindominor)
solver = xta:solver()
printf("Created a new solver instance %s\n",solver.version);
local ymd,hms = xta:datenow(),xta:timenow() 
local jsec = xta:jsec(ymd,hms)
printf("Timestamp: %06d-%06d jsec:%d\n",ymd,hms,jsec)
local res

-- New model instance
local pModel = solver:mpmodel()
printf("Created a new model instance\n");
if options.has_cblog>0 then    
	pModel.logfun = myprintlog
	printf("Set a new log function for the model instance\n");
end	

-- Read model from file	
printf("Reading %s\n",options.model_file)
local nErr = pModel:readfile(options.model_file,0)
pModel:xassert({ErrorCode=nErr})

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
local res_opt, res_rng = pModel:solve(options)

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
        printf("No primal solution\n")
    end
end	

if options.writeas then
    pModel:write(options.writeas)
end    
 
pModel:dispose()
printf("Disposed model instance %s\n",tostring(pModel))  
solver:dispose()
printf("Disposed solver instance %s\n",tostring(solver))  
