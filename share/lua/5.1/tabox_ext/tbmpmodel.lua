local Lindo = require("llindo")
local lxp = Lindo.parameters
local lxe = Lindo.errors
local lxi = Lindo.info
local lxs = Lindo.status

local function check_error(pModel, res, allowed, stop_on_err)
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
        local errMsg = string.format("Error %d: %s", res.ErrorCode, pModel:errmsg(res.ErrorCode))        
        if stop_on_err then
            error(errMsg)  -- This will terminate the program and print the error message        
        end
    else
        local errMsg = string.format("Error %d: %s", res.ErrorCode, pModel:errmsg(res.ErrorCode))        
        printf("IGNORE %s\n",errMsg);        
    end    
end    

TBmpmodel.xassert = function(pModel,res, allowed)
    check_error(pModel, res, allowed, true)
end

TBmpmodel.wassert = function(pModel,res, allowed)
    check_error(pModel, res, allowed, false)
end

---
--
TBmpmodel.solve = function(pModel, options)
    local has_gop = options and options.has_gop
    local has_rng = options and options.has_rng
    local verb = options and options.verb or 0
    local res    

    if verb>0 then printf("Solving %s\n",options and options.model_file or 'current model') end
    if has_gop then
        res = pModel:solveGOP()
    elseif pModel.numint + pModel.numbin + pModel.numsc + pModel.numsets > 0 then
        res = pModel:solveMIP()
    else
        res = pModel:optimize()
    end    
    if verb>2 then print_table3(res) end
    pModel:xassert(res,{lxe.LSERR_USER_INTERRUPT})
    -- check status
    if res.pnMIPSolStatus == lxs.LS_STATUS_OPTIMAL or 
       res.pnSolStatus == lxs.LS_STATUS_BASIC_OPTIMAL or 
       res.pnSolStatus == lxs.LS_STATUS_OPTIMAL or 
       res.pnGOPSolStatus==lxs.LS_STATUS_OPTIMAL or 
       res.pnGOPSolStatus==lxs.LS_STATUS_BASIC_OPTIMAL or 
       res.pnGOPSolStatus==lxs.LS_STATUS_LOCAL_OPTIMAL or 
       res.pnGOPSolStatus==lxs.LS_STATUS_FEASIBLE then
        local res_
        if pModel.numint + pModel.numbin + pModel.numsc + pModel.numsets > 0 then
            res_ = pModel:getMIPPrimalSolution()
        else
            res_ = pModel:getPrimalSolution()
            if has_rng and not has_gop then
                res_rng = pModel:getBoundRanges()
                if verb>2 then
                    print_table3(res_rng)
                end
            end            
        end
        res.padPrimal = res_.padPrimal
        printf("pobj: %.7f\n", pModel.pobj and pModel.pobj or pModel.mipobj or -99)
        if pModel.pobj then
            printf("dobj: %.7f\n", pModel.dobj and pModel.dobj or -99)
        end
    end
    return res, res_rng
end

TBmpmodel.write = function(pModel, options)
    local writeas = options.writeas or 'mps'
    local suffix = options.suffix or '_tmp'
    local model_file = options.model_file
    local addsets_mask = options.addsets_mask
    local nsets = options.nsets
    local settype = options.settype
    local subfolder = options.subfolder
    local res_w
    if writeas=='ltx' then
      local fname = addSuffix2Basename(model_file,suffix,subfolder)        
      res_w = pModel:writeLINDOFile(fname)
      if pModel.nonznlp>0 then
        printf("WARNING: nonznlp=%d, nonlinear terms are excluded..\n")
      end      
    elseif writeas=='mps' then
      local fname = addSuffix2Basename(model_file,suffix,subfolder)        
      res_w = pModel:writeMPSFile(fname,0) 
      if pModel.nonznlp>0 then
        printf("WARNING: nonznlp=%d, nonlinear terms are excluded..\n")
      end        
    elseif writeas=='mpssets' then
      if not pModel.nonznlp or pModel.nonznlp==0 then
        local fname 
        if pModel.numsets==0 and pModel.numsc==0 then
          fname = addSuffix2Basename(model_file,suffix,subfolder)
        else
          local altname = sprintf("_set%s_%dx%d",suffix,addsets_mask,nsets)
          fname = addSuffix2Basename(model_file,altname,subfolder)        
          local salt = 'A'
          while file_exist(fname) do
            local altname = sprintf("_set%s_%dx%d_%s",suffix,addsets_mask,nsets,salt)
            fname = addSuffix2Basename(model_file,altname,subfolder)
            salt = salt .. 'A'
          end
        end
        res_w = pModel:writeMPSFile(fname,0) 
        if res_w.ErrorCode==0 then
          printf("Written model SOS%s extensions to '%s'\n",tostring(settype),fname)
        else
          printf("Error %d: %s\n",res_w.ErrorCode,pModel:errmsg(res_w.ErrorCode) or "N/A")
        end        
      else
        printf("pModel has nonznlp=%d > 0, cannot write MPS file\n",pModel.nonznlp)
      end   
    elseif writeas=='mpi' then
        if pModel.numinstr==0 then
            pModel:loadData2Inst()
        end
        local fname = addSuffix2Basename(model_file,suffix,subfolder)
        res_w = pModel:writeMPIFile(fname)         
    end
    return res_w
end    

TBmpmodel.serialize = function(pModel)
    local res = pModel:getLPData()
    pModel:wassert(res)
    local arg
    if not res then
        print("getLPData returned nil..\n")
        arg = { ErrorCode = Lindo.errors.LSERR_INTERNAL_ERROR }
    else
        if res.pdObjSense then
            --print_table3(res)
            arg = {
                pdObjSense = res.pdObjSense,
                pdObjConst = res.pdObjConst,
                padC = res.padC:ser(),
                padB = res.padB:ser(),
                pachConTypes = res.pachConTypes,
                paiAcols = res.paiAcols:ser(),
                panAcols = res.panAcols:ser(),
                padAcoef = res.padAcoef:ser(),
                paiArows = res.paiArows:ser(),
                padL = res.padL:ser(),
                padU = res.padU:ser(),
                ErrorCode = res.ErrorCode
            }
        else
            arg = res
        end
    end
    return arg
end    



local status_keys = {"modelstatus","solstatus","mipstatus","gopstatus"}
local model_keys = {"modeltype","numvars","numcons","nonz","numint","numbin","numvarsnlp","numvarsqcp","numconsnlp","numconsqcp","nonznlp","nonzqcp","numsets","numsc","numinst"}
local sol_keys = {"simiters","nlpiters","bariters","mipsimiters","mipnlpiters","mipbariters","gopsimiters","gopnlpiters","gopbariters","branches","pobj","dobj","suminf","mipobj","gopobj","mipbnd","gopbnd"}
local other_keys = {"utable"}

TBmpmodel.dispstats = function(pModel)
    local res
    --res = pModel:getIntInfo(info.LS_IINFO_NUM_CONS)
    --res = pModel:getIntInfo(info.LS_IINFO_NUM_VARS)
    --res = pModel:getIntInfo(info.LS_IINFO_NUM_INST_CODES)
    printf("\n")
    printf("Model stats:\n")
    for k,v in ipairs(model_keys) do
        if pModel[v] then
            printf("%-12s: %g\n",v,pModel[v])
        else
            printf("%s not found in pModel\n",v)
        end
    end
    printf("\n")
    return
end

