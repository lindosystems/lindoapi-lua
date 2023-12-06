-- File: ex_mps.lua
-- Description: Example of reading a model from an MPS file and optimizing it.
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

local platform_name = {
    [xta.const.win32x86] = "win32",
    [xta.const.win64x86] = "win64",
    [xta.const.linux64x86] = "linux64x86",
    [xta.const.osx64x86] = "osx64x86"
}

--- 
local function add_objcut(pModel,options,res_lp)
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
    local res = pModel:addConstraints(1, 
        sense, 
        nil,
        xta:field(ia,'ia','int'),
        xta:field(a,'a','double'),
        xta:field(ka,'ka','int'),
        xta:field(rhs,'rhs','double'))
    pModel:xassert(res)
end

--- 
local function hist_bnds(pModel,options,res_lp)
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
end

local function get_tmp_base()
    local temp_base = sprintf("tmp/%s",platform_name[xta.platformid] or "unknown")
    if not paths.dirp(temp_base) then
        paths.mkdir(temp_base)
    end
    return temp_base
end
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

if not options.ktrylogf and 0> 1 then
    if options.ktryenv or options.ktrymod or options.ktrysolv then
        options.ktrylogf = getBasename(options.model_file)
    end
end

local log_digests, sol_digests
if options.ktryenv>1 or options.ktrymod>1 or options.ktrysolv>1 then
    glogger.info("Invoking back-to-back runs with ..\n")
    glogger.info("ktryenv: %s\n",options.ktryenv or "N/A")
    glogger.info("ktrymod: %s\n",options.ktrymod or "N/A")
    glogger.info("ktrysolv: %s\n",options.ktrysolv or "N/A")
    if options.ktrylogf then 
        glogger.info("ktrylogf: %s\n",options.ktrylogf)
    end
    log_digests = {}
    log_digests.total = 0
    sol_digests = {}
    sol_digests.total = 0    
end

-- New solver instance
xta:setsolverdll("",8);
xta:setlindodll(options.lindomajor,options.lindominor)

local ktryenv = options.ktryenv
while ktryenv>0 do
    ktryenv = ktryenv-1
    solver = xta:solver()    
    assert(solver,"\n\nError: failed create a solver instance.\n")
    solver:disp_pretty_version()

    glogger.info("Created a new solver instance ..\n");
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
        local flist = paths.files(get_tmp_base(),function(file) return file:find(options.ktrylogf) and not file:find("~") end)
        if flist then
            local flog
            for file in flist do
                flog = sprintf("%s/%s",get_tmp_base(),file)
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
    
        -- Read model from file	
        glogger.info("Reading '%s'\n",options.model_file)
        local nErr = pModel:readfile(options.model_file,0)
        pModel:xassert({ErrorCode=nErr})
        if options.max then    
            pModel:setModelIntParameter(pars.LS_IPARAM_OBJSENSE,-1)
            printf("Set model sense to maximize (%d)\n",-1)
        end
        local res_lp 
        if options.histmask or options.addobjcut then
            res_lp = pModel:getLPData() 
        end

        if options.histmask then
            if res_lp then
                hist_bnds(pModel,options,res_lp)
            else
                glogger.info("Failed to get LP data\n")
            end
            solver:dispose()
            return
        end

        if options.addobjcut then
            add_objcut(pModel,options,res_lp)
        end

        -- Set callback or logback
        if options.has_cbmip>0 then 
            pModel:setMIPCallback(cbmip)
            if options.has_cbmip>1 then
                pModel.utable.lines = {}
            end
        elseif options.has_cbstd>0 then	
            pModel:setCallback(cbstd)
        end

        if options.parfile then
            res = pModel:readModelParam(options.parfile)
            pModel:wassert(res)
        end 

        if options.lp then
            local str=""
            for k=1,pModel.numvars do
                str = str .. "C"
            end
            res = pModel:loadVarType(str)
            pModel:wassert(res)
        end

        -- Solve model        
        local ktrysolv = options.ktrysolv 
        if options.solve then             
            local res_opt, res_rng
            while ktrysolv>0 do         
                local szktryid = sprintf("e%02d_m%02d_s%02d",ktryenv,ktrymod,ktrysolv)
                collectgarbage()       
                if options.ktrylogf then
                    pModel.utable.ktrylogf = sprintf("%s/ktrylogf_%s_%s.log",get_tmp_base(),options.ktrylogf,szktryid)
                    pModel.utable.ktrylogfp = io.open(pModel.utable.ktrylogf,"w")
                end
                if pModel.utable.lines then
                    if not pModel.utable.lines[szktryid] then
                        pModel.utable.lines[szktryid] = {}                        
                    end
                    pModel.utable.lines_ktry = pModel.utable.lines[szktryid]
                end
                ktrysolv = ktrysolv-1
                pModel.utable.ktrylogsha = nil
                res_opt, res_rng = pModel:solve(options)            
                if options.verb>0 then
                    printf("\n")
                    if options.has_cbmip==1 then
                        pModel:disp_mip_sol_report()
                    end
                    local pd = pModel:getProgressData()
                    if options.verb>2 then
                        print_table3(pd)
                    end
                    local pd_line = lsi_pdline(pd)
                    local dgst_pd = SHA2(pd_line)
                    local dgst = pModel.utable.ktrylogsha
                    if pModel.utable.lines then
                        local str = table.concat(pModel.utable.lines[szktryid])                        
                        dgst = SHA2(str)
                        glogger.info("Overwriting dgst with %s (cbmip=%d)\n",dgst,options.has_cbmip)
                    end
                    if log_digests then
                        if dgst then
                            if not log_digests[dgst] then
                                log_digests[dgst] = 0
                            end
                            log_digests[dgst] = log_digests[dgst] + 1  
                            log_digests.total = log_digests.total + 1                  
                            printf("log.digest: %s  (hits:%d/%d), (last_pd_line.digest:%s)\n",dgst,log_digests[dgst],log_digests.total,dgst_pd)
                            local xdgst = "files:" .. dgst
                            if not log_digests[xdgst] then
                                log_digests[xdgst] = {}
                            end       
                            table.insert(log_digests[xdgst],pModel.utable.ktrylogf)
                        end
                    end

                    if sol_digests then
                        if res_opt.padPrimal then                        
                            local dgst = SHA2(res_opt.padPrimal:ser())                        
                            if not sol_digests[dgst] then
                                sol_digests[dgst] = 0
                            end
                            sol_digests[dgst] = sol_digests[dgst] + 1 
                            sol_digests.total = sol_digests.total + 1
                            printf("sol.digest: %s  (hits:%d/%d)\n", dgst,sol_digests[dgst],sol_digests.total)  
                        end
                    end                    

                    -- solution
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
                    -- ranges 
                    if res_rng then
                        if options.verb>2 then print_table3(res_rng) end
                        if options.verb>1 then
                            res_rng.padDec:printmat(6,nil,12,nil,'.3e')
                        end
                    end	                    
                end
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

if log_digests then
    printf("\n")
    printf("log.digests:\n")
    print_table3(log_digests)
end
if sol_digests then
    printf("\n")
    printf("sol.digests:\n")
    print_table3(sol_digests)
end

