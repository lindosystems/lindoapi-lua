#!/usr/bin/env lua

TBsolver.errmsg = function(pSolver, ErrorCode)
    local res = pSolver:getErrorMessage(ErrorCode)   
    if res.pachMessage then
        return res.pachMessage
    else
        return "N/A"
    end
end

local function check_error(pSolver, res, allowed, stop_on_err)
    local stop_on_err = stop_on_err    
    -- Check if res.ErrorCode is in the allowed table              
    if res.ErrorCode == 0 then
        return
    end        
    local allowed = allowed or {0}
    local isContinue = false    
    for i, code in ipairs(allowed) do
        if res.ErrorCode == code then
            isContinue = true   -- white error for the call
            break
        end
    end
    
    -- If the error code is not allowed, trigger an assert
    if not isContinue then
        local errMsg = string.format("\nError %d: %s", res.ErrorCode, pSolver:errmsg(res.ErrorCode))        
        if stop_on_err then
            error(errMsg)  -- This will terminate the program and print the error message        
        end
    else
        local errMsg = string.format("\nError %d: %s", res.ErrorCode, pSolver:errmsg(res.ErrorCode))        
        printf("\nIGNORE %s\n",errMsg);        
    end    
end 

TBsolver.xassert = function(pSolver,res, allowed)
    check_error(pSolver, res, allowed, true)
end

TBsolver.wassert = function(pSolver,res, allowed)
    check_error(pSolver, res, allowed, false)
end

TBsolver.disp_pretty_version = function(solver) -- Display version info
    glogger.info("\n")    
    local res = solver:getVersionInfo()        
    local tokens = split(res.pachBuildDate,"\n")
    glogger.info("LINDO API %s  built on %s\n",res.pachVernum,tokens[1])
    glogger.info("%s\n",tokens[2])
    glogger.info("%s\n",tokens[3])
    glogger.info("\n")    
end