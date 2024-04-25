#!/usr/bin/env lslua
-- File: ex_cbfun.lua
-- Description: Example of using callback functions with the Lindo API
-- Author: mka
-- Date: 2019-07-01

local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local status = Lindo.status

--- Compute SHA1/2 hash of a string
---@param str String to be hashed
function SHA2(str) 
    local sha2_
    if 2>1 then
        sha2_ = xta:digest(str)
    else
        sha2_ = xta:sha(str,256)        
    end 
    if 0>1 and string.len(str)<128 then
        printf("DIGEST: '%s' '%s'\n",sha2_,str)       
    end
    return sha2_
end    

--- Callback function for logging messages from  with respect to Lindo API
-- @param pModel Pointer to the model instance
-- @param str String to be printed
function myprintlog(pModel, str)
    if str:find("Processed") then
        str="\nProcessed ..."
    end
    printf("%s", str)
    if string.len(str)<-2 then
		io.read()
	end
    if pModel.utable and pModel.utable.ktrylogfp then
        fprintf(pModel.utable.ktrylogfp,"%s",str)
        if not pModel.utable.ktrylogsha then
            pModel.utable.ktrylogsha = ""
        end
        pModel.utable.ktrylogsha = SHA2(pModel.utable.ktrylogsha..str)
    end
end

--- MIP Callback function progress line getter
-- @param p Pointer to the progress data
function lsi_pdline(p)
    local sline = sprintf("%6s:%8u %8u %8u %14e %14e %14e %8u %6u",
    "(NEW)",p.iter,p.bncnt,p.lpcnt+p.mipcnt,p.pfeas,p.bestbnd,p.pobj,p.accnt,p.status);
    return sline
end    


--- Callback function that gets called everytime a new MIP solution is found
-- @param pModel Pointer to the model instance
-- @param dobj Objective value of the new MIP solution
-- @param pX Pointer to the new MIP solution
function cbmip(pModel, dobj, pX, udata)
    local iter,bncnt,lpcnt,mipcnt,pfeas,bestbnd,pobj,accnt,status,curtime 
    local szerr
    local res
    local iLoc = 5
    local retval = 0

    if 2>1 then
        local counter = pModel.utable.counter
        if counter%20==0 then
            printf("\n\n%6s %8s %8s %8s %14s %14s %14s %8s %6s %8s %10s\n",
            "LOC","ITER","BRANCH","LPs","INFEAS","BEST BND","BEST SOL","ACTIVE","STATUS","CPUTIME","|X|");
        end
        counter = counter + 1
        pModel.utable.counter = counter
        
        local p = pModel:getProgressData()
        local normx = -99
        if pX then
            normx = pX:norm(2)
        end
        szerr = "" --pModel:errmsg(res.ErrorCode) or "N/A"
        local line = lsi_pdline(p)
        printf("\n%s %8.2f %10g %s",line,p.curtime,normx,szerr) 
        local str = sprintf("\n%s %8.2f %10g %s",line,-99,normx,szerr)
        if pModel.utable.ktrylogfp then            
            fprintf(pModel.utable.ktrylogfp,"%s",str)            
        end    
        if not pModel.utable.ktrylogsha then
            pModel.utable.ktrylogsha = ""
        end        
        pModel.utable.ktrylogsha = SHA2(pModel.utable.ktrylogsha..str)

        if pModel.utable.lines_ktry then
            if line ~= pModel.utable.lines_ktry[#pModel.utable.lines_ktry] then
                pModel.utable.lines_ktry[#pModel.utable.lines_ktry+1] = line
            end
        end
        
        retval = 0
        if retval>0 then        
            printf("Warning: cbmip is returning interrupt signal !\n")
        end
    end
    return retval
end

--- General callback function that gets called from various localtions in the Lindo API
-- @param pModel Pointer to the model instance
-- @param iLoc Location code
function cbstd(pModel, iLoc,udata)
    local iter,bncnt,lpcnt,mipcnt,pfeas,bestbnd,pobj,accnt,status,curtime,szerr
    local res
    
    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_ITER)
    iter = res and res.pValue or 0

    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_STATUS)
    status = res and res.pValue or 0    

    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_LP_COUNT)
    lpcnt = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_BRANCH_COUNT)
    bncnt = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_MIP_COUNT)
    mipcnt = res and res.pValue or 0    

    res = pModel:getProgressInfo(iLoc,info.LS_DINFO_SUB_PINF)
    pfeas = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_DINFO_CUR_BEST_BOUND)
    bestbnd = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_DINFO_CUR_OBJ)
    pobj = res and res.pValue or 0    

    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_ACTIVE_COUNT)
    accnt = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_DINFO_CUR_TIME)
    curtime = res and res.pValue or 0    

    szerr = "" -- pModel:errmsg(res.ErrorCode) or "N/A"
    printf("\n%6s:%8u %8u %8u %14e %14e %14e %8u %6u %8.2f %s",
    "(CB)",iter,bncnt,lpcnt+mipcnt,pfeas,bestbnd,pobj,accnt,status,curtime,szerr);

    return 0
end

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
    local platform_name = {
        [xta.const.win32x86] = "win32",
        [xta.const.win64x86] = "win64",
        [xta.const.linux64x86] = "linux64x86",
        [xta.const.osx64x86] = "osx64x86"
    }    
    local temp_base = sprintf("tmp/%s",platform_name[xta.platformid] or "unknown")
    if not paths.dirp(temp_base) then
        paths.mkdir(temp_base)
    end
    return temp_base
end

--- Solve a model with a new solver instance
-- @param ktryenv index of environment
-- @param options table of options
function ls_runlindo(ktryenv,options)    
    local sol_digests = options.sol_digests
    local log_digests = options.log_digests
    local solver = xta:solver()    
    assert(solver,"\nError: cannot create a solver instance\n")   
    solver:disp_pretty_version()

    glogger.info("Created a new solver instance ..\n");
    local ymd,hms = xta:datenow(),xta:timenow() 
    local jsec = xta:jsec(ymd,hms)
    glogger.info("Timestamp: %06d-%06d jsec:%d\n",ymd,hms,jsec)
    local res
    apply_solver_options(solver,options)

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
        if options.cblog>0 and not (options.cbmip~=0 or options.cbstd~=0) then    
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
        if options.cbmip>0 then 
            pModel:setMIPCallback(cbmip)
            if options.cbmip>1 then
                pModel.utable.lines = {}
            end
        elseif options.cbstd>0 then	
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
        if options.solve>0 then             
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
                    if options.cbmip==1 then
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
                        glogger.info("Overwriting dgst with %s (cbmip=%d)\n",dgst,options.cbmip)
                    end

                    local model_file = paths.basename(options.model_file)                                        
                    if log_digests then
                        if not log_digests[model_file] then
                            log_digests[model_file] = {}
                            log_digests[model_file].total = 0
                        end                        
                        if dgst then
                            if not log_digests[model_file][dgst] then
                                log_digests[model_file][dgst] = 0
                            end
                            local mlog_digests = log_digests[model_file]
                            mlog_digests[dgst] = mlog_digests[dgst] + 1  
                            mlog_digests.total = mlog_digests.total + 1                  
                            printf("log.digest: %s  (hits:%d/%d), (last_pd_line.digest:%s)\n",dgst,mlog_digests[dgst],mlog_digests.total,dgst_pd)
                            local xdgst = "ktrylogf:" .. dgst
                            if not log_digests[xdgst] then
                                mlog_digests[xdgst] = {}
                            end
                            table.insert(mlog_digests[xdgst],pModel.utable.ktrylogf)
                        end
                    end

                    if sol_digests then
                        if not sol_digests[model_file] then
                            sol_digests[model_file] = {}
                            sol_digests[model_file].total = 0
                        end                        
                        local msol_digests = sol_digests[model_file]   
                        if res_opt.padPrimal then                        
                            local dgst = SHA2(res_opt.padPrimal:ser())                        
                            if not msol_digests[dgst] then
                                msol_digests[dgst] = 0
                            end
                            msol_digests[dgst] = msol_digests[dgst] + 1 
                            msol_digests.total = msol_digests.total + 1
                            printf("sol.digest: %s  (hits:%d/%d)\n", dgst,msol_digests[dgst],msol_digests.total)  
                        end
                    end

                    -- solution
                    if res_opt then
                        if options.verb>2 then print_table3(res_opt) end
                            if options.verb>0 then
                            if res_opt.padPrimal then
                                if options.verb>1 then
                                    res_opt.padPrimal:printmat(6,nil,12,nil,'.3e')
                                end
                            else
                                glogger.info("No primal solution\n")
                            end
                        end
                    end
                    -- ranges 
                    if res_rng then
                        if options.verb>2 then print_table3(res_rng) end
                        if options.verb>0 then
                            for ktype,v in pairs(res_rng) do
                                printf("Range %s:\n", ktype)
                                v.padDec:printmat(6,nil,12,nil,'.3e')
                                v.padInc:printmat(6,nil,12,nil,'.3e') 
                            end                            
                        end
                    end	                    
                end
            end    
        end    

        if options.writeas then
            pModel:write(options.writeas)
        end

        if options.sol then
            local solfile = changeFileExtension(options.model_file,".sol")
            res = pModel:writesol(solfile,options.verb)
            pModel:wassert(res)
        end
        
        pModel:delete()    
        pModel = nil    
        collectgarbage()
    end -- ktrymod

    solver:dispose()
    glogger.info("Disposed solver instance %s\n",tostring(solver))  
end -- ktryenv    