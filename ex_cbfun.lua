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

