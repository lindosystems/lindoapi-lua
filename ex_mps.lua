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
    print("Options:")
    print("    , --addobjcut=[number]      Add objcut with rhs 'number' (default: nil)")    
    print("    , --histmask=[number]       Analyze LP data with histogram with specified mask 'number' (default: nil)")    
    print("    , --xuserdll=[string]       Set user DLL (default: nil)")
    print()
    print("Usage: lua ex_mps.lua [options]")
    print("Example:")
    print("\t lua ex_mps.lua -m /path/to/model.mps [options]")
    print()
end   

local short=""
local long={
    addobjcut = 1,
    histmask = 1,
    xuserdll = 1,
}
local options, opts, optarg = parse_options(arg,short,long)

-- parse app specific options
for i, k in pairs(opts) do
    local v = optarg[i]         
    if k=="addobjcut" then options.addobjcut=tonumber(v) end
    if k=="histmask" then options.histmask=tonumber(v) end
    if k=="xuserdll" then options.xuserdll=v end
end

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
local lines_digests = {}
local ktryenv = options.ktryenv
while ktryenv>0 do
    ktryenv = ktryenv-1
    solver = xta:solver()
    assert(solver,"\n\nError: failed create a solver instance.\n")
    printf("\n")
    glogger.info("Created a new solver instance %s\n",solver.version);
    local ymd,hms = xta:datenow(),xta:timenow() 
    local jsec = xta:jsec(ymd,hms)
    glogger.info("Timestamp: %06d-%06d jsec:%d\n",ymd,hms,jsec)
    local res
    if options.xuserdll then
        local xuserdll = options.xuserdll 
        if not xuserdll:find(".dll") and not xuserdll:find(".so") and not xuserdll:find(".dylib") then
            xuserdll = "j:\\usr2\\LINGO\\64_20\\MyUser.dll"        
        end
        res = solver:setXSolverLibrary(94,xuserdll)
        solver:xassert(res)
    end

    if options.xsolver>0 then
        local xdll = options.xdll 
        res = solver:setXSolverLibrary(options.xsolver,xdll)
        solver:xassert(res)
    end

    if options.ktrylogf then
        local flist = paths.files("tmp",function(file) return file:find(options.ktrylogf) and not file:find("~") end)
        if flist then
            local flog
            for file in flist do
                flog = "tmp/"..file
                paths.backup(flog)                
                paths.rmall(flog,"yes")
                glogger.info("Backed up %s\n",flog)
            end
        end
    end
    
    local ktrymod = options.ktrymod
    while ktrymod > 0 do
        ktrymod = ktrymod-1
        -- New model instance
        local pModel = solver:mpmodel()
        assert(pModel,"\n\nError: failed create a model instance.\n")
        glogger.info("Created a new model instance\n");
        pModel.usercalc=xta.const.size_max
        if options.has_cblog>0 and not (options.has_cbmip~=0 or options.has_cbstd~=0) then    
            pModel.logfun = myprintlog
            glogger.info("Set a new log function for the model instance\n");
        end	

        -- Set the new parameters
        pModel:set_params_user(options)   
        pModel:disp_params_non_default()

        if options.ktrylogf then
            pModel.utable.ktrylogf = sprintf("tmp/ktrylogf_%s_m%02d_e%02d.log",options.ktrylogf,ktrymod,ktryenv)
            pModel.utable.ktrylogfp = io.open(pModel.utable.ktrylogf,"w")
        end
    
        -- Read model from file	
        glogger.info("Reading %s\n",options.model_file)
        local nErr = pModel:readfile(options.model_file,0)
        pModel:xassert({ErrorCode=nErr})
        if options.max then    
            pModel:setModelIntParameter(pars.LS_IPARAM_OBJSENSE,-1)
            printf("Set model sense to maximize (%d)\n",-1)
        end
        local res_lp 
        if options.histmask then
            res_lp = pModel:getLPData() 
        end    
        if res_lp and options.histmask then
            --print_table3(res_lp)    
            if hasbit(options.histmask,3) then --histmask=4
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
            h = ld:histogram(10)
            if h then
                h:print()
                local idx = d:find(0)
                if idx then
                    idx:printmat()
                end
            end
            if pModel.utable.ktrylogfp then
                io.close(pModel.utable.ktrylogfp)
            end
            solver:dispose()
            return
        end

        if options.addobjcut then
            if not res_lp then
                res_lp = pModel:getLPData() 
            end
            local c = res_lp.padC
            local ka, ia, a, rhs, sense = {}, {}, {}, {}, 'L'
            ia[1]  = 0
            for k=1,c.len do        
                if math.abs(c[k])>0 then
                    table.insert(ka,k-1)
                    table.insert(a,c[k])
                end
            end
            ia[2] = #ka
            table.insert(rhs,options.addobjcut)
            if res_lp.pdObjSense ==-1 then
                sense = 'G'
            end
            res = pModel:addConstraints(1, 
                sense, 
                nil,
                xta:field(ia,'ia','int'),
                xta:field(a,'a','double'),
                xta:field(ka,'ka','int'),
                xta:field(rhs,'rhs','double'))
            pModel:xassert(res)
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
            local ktrysolv = options.ktrysolv
            while ktrysolv>0 do
                ktrysolv = ktrysolv-1
                res_opt, res_rng = pModel:solve(options)            
                if options.verb>0 then
                    local pd = pModel:getProgressData()                    
                    if pModel.utable.lines then
                        local str = table.concat(pModel.utable.lines)
                        local last_line = lsi_pdline(pd)  
                        printf("\n")                  
                        printf("lines.digest: %s (last:%s)\n",SHA2(str),SHA2(last_line))
                        if lines_digests == nil then
                            lines_digests = {}
                        end 
                        lines_digests[SHA2(str)] = true
                    end        
                    if options.verb>2 then                        
                        print_table3(pd)                                            
                    end                                
                    if options.verb>2 then            
                        res_opt.padPrimal:printmat(6,nil,12,nil,'.3e')
                    end
                    if res_opt.padPrimal then
                        local dgst = SHA2(res_opt.padPrimal:ser())
                        printf("x.digest: %s\n", dgst)
                    end                    
                end
            end    
        end    

        if res_rng then
            if options.verb>2 then print_table3(res_rng) end
            if options.verb>1 then
                res_rng.padDec:printmat(6,nil,12,nil,'.3e')
            end
        end	

        if res_opt then
            if options.verb>3 then print_table3(res_opt) end
            if res_opt.padPrimal then
                if options.verb>2 then
                    res_opt.padPrimal:printmat(6,nil,12,nil,'.3e')
                end
            else
                glogger.info("No primal solution\n")
            end
        end	

        if options.writeas then
            pModel:write(options.writeas)
        end

        pModel:delete()        
    end -- ktrymod

    solver:dispose()
    glogger.info("Disposed solver instance %s\n",tostring(solver))  
end -- ktryenv    
print_table3(lines_digests)
