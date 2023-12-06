

local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local logger = Lindo.logger
local modStack = require("Stack")
local envDict = {}
local modDict = {}
local solver_

local function get_keys(t,stk)
  local keys={}
  local pos={}  
  for key,_ in pairs(t) do
    table.insert(keys, key)
    if stk then
      table.insert(pos,stk:pos(key))
    end
  end
  return keys,pos
end

local function parse_model(args)
  local szModel
  if args and args[1] then
    szModel = args[1]      
    if string.upper(string.sub(szModel, 1, 2))~="0X" then
      szModel = modStack:at(tonumber(szModel))
    end
  else
    print_table3(args)
    logger.error("parse_model: args do not contain a valid model handle\n")
  end
  return szModel
end

function myprintlog2(pModel,str)
  printf("%s",str)
  local ctx = pModel.umodel.ctx
  if pModel.utable and pModel.utable.ncalls  then
    pModel.utable.ncalls=pModel.utable.ncalls+1
  end
  --print_table3(pModel.utable)
end

local remote_procedures = {
      
    ping1 = function(args)
        logger.info("Client pinging..Replying 'ALIVE'...\n")
        return true, "ALIVE"
    end,

    quit = function(args)
        logger.debug("'quit()' was called, acting with following args:\n")
        for k,v in pairs(args) do logger.debug("%s = %s\n",k,v) end
        return true, "ok"
    end,
    
    verb = function(args)     
      if logger.level=='debug' then print_table3(result) end
      return true, tonumber(args[1])
    end,
    
    createEnv = function(args)
      if not solver_ then
        local lsmaj,lsmin = args and args[1] or 14, args and args[2] or 0
        xta:setlindodll(lsmaj,lsmin)
        solver_ = xta:solver()
        local flag = true
        if solver_ then          
          logger.info("createEnv: solver %s (%s)\n",solver_.handle,tostring(solver_)) 
          envDict[solver_.handle] = solver_
        else
          flag=false
        end
        return flag,solver_.handle
      else
        logger.warn("createEnv: solver already exists\n");
        return false,'none'
      end
    end,
    
    dump_error_objects = function(args)      
      local  error_objects = setmetatable({}, {__mode='k'}) 
      --print_table3(errs)
      if not solver_ then
        logger.warn("dump_error_objects: solver not init'ed\n");
        return false,'none'
      end
            
      for key,v in pairs(errs) do
        local res = solver_:getErrorMessage(v)
        res.ErrorCode = v
        res.err_code = res.ErrorCode
        res.err_message = res.pachMessage
        res.ErrorCode = nil
        res.pachMessage = nil
        if v~=errs.LSERR_NO_ERROR then
          error_objects[v] = res
        end
      end
      if 0>1 then 
        local JSON = require("JSON")     
        local jstr = JSON:encode_pretty(error_objects)
        local jfile = "tmp/lserr_objects.json"
        fwritef(jfile,"w","%s",jstr)
      end
      print_table4(error_objects)
      return true,0
    end,
    
    
    deleteEnv = function(args)
      if solver_ then
        if envDict[solver_.handle] then
          envDict[solver_.handle] = nil
        end
        envDict[solver_.handle] = nil 
        logger.info("deleteEnv: deleting solver %s\n",solver_.handle);
        solver_:dispose()
        solver_=nil  
        modDict={}
        return true,0
      else
        logger.warn("deleteEnv: solver not init'ed\n");
        return false,0
      end
    end,
    
    versionInfo = function(args)
      if solver_ then
        logger.info("versionInfo: version: %s\n",solver_.version)
        return true,solver_.version
      else
        logger.warn("versionInfo: solver not init'ed\n");
        return false,'none'
      end
    end,

    showModels = function(args)
      return true, get_keys(modDict,modStack)
    end,

    modelAt = function(args)
      local pos = tonumber(args[1])
      if pos then
        local szModel = modStack:at(pos)
        if szModel then
          return true,szModel
        else
          return false,'none'
        end
      else
        return false,'none'
      end
    end,
    
    showEnvs = function(args)
      return true,get_keys(envDict)
    end,
    
    createModel = function(args)
      local szEnv = args[1]
      if not solver_ then
        logger.warn("createModel: solver env does not exist\n");
        return false, -1
      end
      if szEnv then
        assert(szEnv==solver_.handle)
      end
      local pModel = solver_:mpmodel()
      if pModel then
        logger.info("createModel: pModel %s created (%s)\n",pModel.handle,tostring(pModel)) 
        modDict[pModel.handle] = pModel
        modStack:push(pModel.handle)
        if not pModel.utable then
          pModel.utable = {}
        end
        pModel.logfun = function (pModel,str)
          --printf("\nmylog: %s",str:sub(2,-1))
          printf("%s",str)
          if pModel.utable.ncalls  then
            pModel.utable.ncalls=pModel.utable.ncalls+1
          end
          --print_table3(pModel.utable)
        end
        
        return true,pModel.handle
      else
        return false,-2
      end      
    end,
    
    deleteModel = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("deleteModel: Model '%s' does not exist\n",szModel);
        return false, -1
      end
      
      pModel:dispose()
      modDict[szModel]=nil
      local pos = modStack:pos(szModel)
      if pos then 
        modStack:remove(pos)
        logger.info("deleteModel: Removed model from stack pos '%d'\n",pos)
      end
      local flag=true      
      logger.info("deleteModel: pModel %s disposed, stack left:%d\n",szModel,modStack:getn()) 
      return flag,0
    end,  
    
    optimize = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("optimize: pModel '%s' does not exist\n",szModel);
        return false, -1
      end
      
      local res = pModel:optimize(args[2])      
      local flag=res.ErrorCode==0
      
      logger.info("optimize: termination status:%d, etime:%g, error:%d \n",
      pModel:getInfo(Lindo.info.LS_IINFO_MODEL_STATUS).pValue,
      pModel:getInfo(Lindo.info.LS_IINFO_ELAPSED_TIME).pValue,
      res.ErrorCode) 

      local status = pModel:getInfo(Lindo.info.LS_IINFO_MODEL_STATUS).pValue
      
      if status==Lindo.status.LS_STATUS_OPTIMAL or status==Lindo.status.LS_STATUS_FEASIBLE or status==Lindo.status.LS_STATUS_LOCAL_OPTIMAL or status==Lindo.status.LS_STATUS_BASIC_OPTIMAL then
        logger.info("optimize: pobj=%g, dobj:%g, siter:%g, biter:%g\n",
          pModel:getInfo(Lindo.info.LS_DINFO_POBJ).pValue,
          pModel:getInfo(Lindo.info.LS_DINFO_DOBJ).pValue,
          pModel:getInfo(Lindo.info.LS_DINFO_SIM_ITER).pValue,
          pModel:getInfo(Lindo.info.LS_DINFO_BAR_ITER).pValue
          ) 
      end
               
      return flag,
        res.ErrorCode,
        pModel:getInfo(Lindo.info.LS_IINFO_MODEL_STATUS).pValue
    end,  
    
    loadLPData = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("loadLPData: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local pnode_list = args[2]
      --print_table3(pnode_list)
      local res = pModel:loadDataNode(pnode_list['lp_data'],"lp_data")
      local flag=false
      if res then
        flag = res.ErrorCode==0 
        if flag then    
          logger.info("loadLPData: pModel %s is loaded\n",szModel)
        end
        return flag, res.ErrorCode        
      else
        return flag, -1
      end 
    end, 
    
    loadModelData = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("loadModelData: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local pnode_list = args[2]
      local res, res_tmp
      
      res = pModel:loadModelDataNode(pnode_list)
      local flag=false
      if res then
        flag = res.ErrorCode==0 
        if flag then    
          logger.info("loadModelData: pModel %s is loaded\n",szModel)
        end
        return flag, res.ErrorCode        
      else
        return flag, -1
      end 
    end,
    
    getPrimalSolution = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("getPrimalSolution: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local res = pModel:getPrimalSolution()
      local flag = false  
      if res then
        flag = res.ErrorCode==0
        return flag, res.ErrorCode, flag and res.padPrimal:ser() or nil
      else
        return flag, -1
      end  
    end,   
    
    getDualSolution = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("getDualSolution: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local res = pModel:getDualSolution()
      local flag = false  
      if res then
        flag = res.ErrorCode==0
        return flag, res.ErrorCode, flag and res.padDual:ser() or nil
      else
        return flag, -1
      end  
    end,   
    
    getReducedCosts = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("getReducedCosts: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local res = pModel:getReducedCosts()
      local flag = false  
      if res then
        flag = res.ErrorCode==0
        return flag, res.ErrorCode, flag and res.padRedcosts:ser() or nil
      else
        return flag, -1
      end  
    end,   
    
    getSlacks = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("getSlacks: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local res = pModel:getSlacks()
      local flag = false  
      if res then
        flag = res.ErrorCode==0
        return flag, res.ErrorCode, flag and res.padSlacks:ser() or nil
      else
        return flag, -1
      end  
    end,   
    
    getInfo = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("getInfo: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local key = args[2]      
      local res
      if Lindo.info[key] then
        res = pModel:getInfo(Lindo.info[key])
      else
        logger.warn("getInfo: invalid key '%s'\n",key)
        return false,errs.LSERR_INVALID_INPUT
      end
      local flag = false  
      if res then
        flag = res.ErrorCode==0
        return flag, res
      else
        return flag, -1
      end  
    end,    
    
    freeSolutionMemory = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("freeSolutionMemory: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local res = pModel:freeSolutionMemory()
      if type(res)=='table' then print_table3(res) end
      return true,res
    end,
    
    freeSolverMemory = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("freeSolverMemory: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local res = pModel:freeSolverMemory()
      if type(res)=='table' then print_table3(res) end
      return true,res
    end,
    
    setModelParameter = function(args)
      local szModel = parse_model(args)
      local iparam = args[2]
      local value = args[3]
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("setModelParameter: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local res = pModel:setModelParameter(iparam,value)
      local flag = false
      if res then
        flag = res.ErrorCode==0
        return flag, res
      else
        return flag, -1
      end     
    end,
    
    getModelParameter = function(args)
      local szModel = parse_model(args)
      local iparam = args[2]
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("getModelParameter: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local res = pModel:getModelParameter(iparam)
      local flag = false
      if res then
        flag = res.ErrorCode==0
        return flag, res
      else
        return flag, -1
      end          
    end,
    
    modifyLowerBounds = function(args)
      local szModel = parse_model(args)
      local nVars = args[2]
      local paiVars = args[3]
      local padL = args[4]
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("modifyLowerBounds: model '%s' does not exist\n",szModel);
        return false, -1
      end

      local res = pModel:modifyLowerBounds(
         nVars,
         paiVars and xta:fielddes(paiVars,"paiVars","int") or nil,
         padL and xta:fielddes(padL,"padL","double") or nil)
         
      local flag = false
      if res then
        flag = res.ErrorCode==0
        return flag, res
      else
        return flag, -1
      end                                          
    end,
    
    modifyUpperBounds = function(args)
      local szModel = parse_model(args)
      local nVars = args[2]
      local paiVars = args[3]
      local padU = args[4]
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("modifyUpperBounds: model '%s' does not exist\n",szModel);
        return false, -1
      end

      local res = pModel:modifyUpperBounds(
         nVars,
         paiVars and xta:fielddes(paiVars,"paiVars","int") or nil,
         padU and xta:fielddes(padU,"padU","double") or nil)
         
      local flag = false
      if res then
        flag = res.ErrorCode==0
        return flag, res
      else
        return flag, -1
      end                                          
    end,
    
    modifyRHS = function(args)
      local szModel = parse_model(args)
      local nCons = args[2]
      local paiCons = args[3]
      local padB = args[4]
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("modifyRHS: model '%s' does not exist\n",szModel);
        return false, -1
      end

      local res = pModel:modifyRHS(
         nCons,
         paiCons and xta:fielddes(paiCons,"paiCons","int") or nil,
         padB and xta:fielddes(padB,"padB","double") or nil)
         
      local flag = false
      if res then
        flag = res.ErrorCode==0
        return flag, res
      else
        return flag, -1
      end                                          
    end,   
    
    modifyAj = function(args)
      local szModel = parse_model(args)
      local jCol = args[2]
      local nRows = args[3]
      local paiCons = args[4]
      local padAj = args[5]
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("modifyAj: model '%s' does not exist\n",szModel);
        return false, -1
      end

      local res = pModel:modifyAj(
         jCol, 
         nRows,
         paiCons and xta:fielddes(paiCons,"paiCons","int") or nil,
         padAj and xta:fielddes(padAj,"padAj","double") or nil)
         
      local flag = false
      if res then
        flag = res.ErrorCode==0
        return flag, res
      else
        return flag, -1
      end    
    end, 
    
    deleteAj = function(args)
      local szModel = parse_model(args)
      local jCol = args[2]
      local nRows = args[3]
      local paiCons = args[4]
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("deleteAj: model '%s' does not exist\n",szModel);
        return false, -1
      end

      local res = pModel:deleteAj(
         jCol, 
         nRows,
         paiCons and xta:fielddes(paiCons,"paiCons","int") or nil)
         
      local flag = false
      if res then
        flag = res.ErrorCode==0
        return flag, res
      else
        return flag, -1
      end
    end,     
    
    
    modifyObjective = function(args)
      local szModel = parse_model(args)
      local nVars = args[2]
      local paiVars = args[3]
      local padC = args[4]
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("modifyObjective: model '%s' does not exist\n",szModel);
        return false, -1
      end

      local res = pModel:modifyObjective(
         nVars,
         paiVars and xta:fielddes(paiVars,"paiVars","int") or nil,
         padC and xta:fielddes(padC,"padC","double") or nil)
         
      local flag = false
      if res then
        flag = res.ErrorCode==0
        return flag, res
      else
        return flag, -1
      end                                          
    end,
    

    modifyObjConstant = function(args)
      local szModel = parse_model(args)
      local dVal = args[2]
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("modifyObjConstant: model '%s' does not exist\n",szModel);
        return false, -1
      end

      local res = pModel:modifyObjConstant(
         dVal)
         
      local flag = false
      if res then
        flag = res.ErrorCode==0
        return flag, res
      else
        return flag, -1
      end                                          
    end,    
    
    
    modifyConstraintType = function(args)
      local szModel = parse_model(args)
      local nCons = args[2]
      local paiCons = args[3]
      local szConTypes = args[4]
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("modifyConstraintType: model '%s' does not exist\n",szModel);
        return false, -1
      end

      local res = pModel:modifyConstraintType(
         nCons,
         paiCons and xta:fielddes(paiCons,"paiCons","int") or nil,
         szConTypes or nil)
         
      local flag = false
      if res then
        flag = res.ErrorCode==0
        return flag, res
      else
        return flag, -1
      end                                          
    end,
    
    addConstraints = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("addConstraints: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local nNumaddcons = args[2]
      local pszConTypes = args[3]
      local paszConNames = args[4]
      local paiArows = args[5]
      local padAcoef = args[6]
      local paiAcols = args[7]
      local padB = args[8]
      
      local res = pModel:addConstraints(
         nNumaddcons,
         pszConTypes,
         paszConNames,                        
         paiArows and xta:fielddes(paiArows,"paiArows","int") or nil,
         padAcoef and xta:fielddes(padAcoef,"padAcoef","double") or nil,
         paiAcols and xta:fielddes(paiAcols,"paiArows","int") or nil,
         padB and xta:fielddes(padB,"padB","double") or nil
        )      
      local flag=false
      if res then
        flag = res.ErrorCode==0 
        if flag then    
          logger.info("addConstraints: %d new constraints are added\n",nNumaddcons)
        end
        return flag, res.ErrorCode        
      else
        return flag, -1
      end 
    end,   
        

    addVariables = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("addVariables: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local  nNumaddvars = args[2]
      local  pszVarTypes = args[3]
      local  paszVarNames = args[4]
      local  paiAcols = args[5]
      local  panAcols = args[6]
      local  padAcoef = args[7]
      local  paiArows = args[8]
      local  padC = args[9]
      local  padL = args[10]
      local  padU = args[11]
      local res = pModel:addVariables(
         nNumaddvars,
         pszVarTypes,
         paszVarNames,
         paiAcols and xta:fielddes(paiAcols,"paiAcols","double") or nil,
         panAcols and xta:fielddes(panAcols,"panAcols","int") or nil,
         padAcoef and xta:fielddes(padAcoef,"padAcoef","double") or nil,                 
         paiArows and xta:fielddes(paiArows,"paiArows","int") or nil,
         padC and xta:fielddes(padC,"padC","double") or nil,
         padL and xta:fielddes(padL,"padL","double") or nil,
         padU and xta:fielddes(padU,"padU","double") or nil   
        )      
      local flag=false
      if res then
        flag = res.ErrorCode==0 
        if flag then    
          logger.debug("addVariables: %d new variables are added\n",nNumaddvars)
        end
        return flag, res.ErrorCode        
      else
        return flag, -1
      end 
    end,
    
    deleteConstraints = function(args)
      local szModel = parse_model(args)
      local nItems = args[2]
      local paiItems = args[3]
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("deleteConstraints: model '%s' does not exist\n",szModel);
        return false, -1
      end

      local res = pModel:deleteConstraints(
         nItems,
         paiItems and xta:fielddes(paiItems,"paiItems","int") or nil)
         
      local flag = false
      if res then
        flag = res.ErrorCode==0
        if flag then    
          logger.debug("deleteConstraints: %d contraints are deleted\n",nItems)
        end        
        return flag, res
      else
        return flag, -1
      end                                          
    end,   
    
    deleteVariables = function(args)
      local szModel = parse_model(args)
      local nItems = args[2]
      local paiItems = args[3]
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("deleteVariables: model '%s' does not exist\n",szModel);
        return false, -1
      end

      local res = pModel:deleteVariables(
         nItems,
         paiItems and xta:fielddes(paiItems,"paiItems","int") or nil)
         
      local flag = false
      if res then
        flag = res.ErrorCode==0
        if flag then    
          logger.debug("deleteVariables: %d variables are deleted\n",nItems)
        end         
        return flag, res
      else
        return flag, -1
      end                                          
    end,
    
    
    loadBasis = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("loadBasis: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local panCstatus = args[2]
      local panRstatus = args[3]
      
      local res = pModel:loadBasis(
         panCstatus,
         panRstatus)
         
      local flag=false
      if res then
        flag = res.ErrorCode==0 
        if flag then    
          logger.debug("loadBasis: new basis is loaded\n")
        end
        return flag, res.ErrorCode        
      else
        return flag, -1
      end 
    end,     
    
    loadVarType = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("loadBasis: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local szVarType = args[2]
      
      local res = pModel:loadVarType(
         szVarType)
         
      local flag=false
      if res then
        flag = res.ErrorCode==0 
        if flag then    
          logger.debug("loadVarType: variable type is loaded\n")
        end
        return flag, res.ErrorCode        
      else
        return flag, -1
      end 
    end,     
        
    setProbAllocSizes = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("setProbAllocSizes: model '%s' does not exist\n",szModel);
        return false, -1
      end
       local  n_vars_alloc = args[2]
       local  n_cons_alloc = args[3]
       local  n_QC_alloc = args[4]
       local  n_Annz_alloc = args[5]
       local  n_Qnnz_alloc = args[6]
       local  n_NLPnnz_alloc = args[7]
      
      local res = pModel:setProbAllocSizes(
        n_vars_alloc,
        n_cons_alloc,
        n_QC_alloc,
        n_Annz_alloc,
        n_Qnnz_alloc,
        n_NLPnnz_alloc)
         
      local flag=false
      if res then
        flag = res.ErrorCode==0 
        if flag then    
          logger.debug("setProbAllocSizes: new alloc sizes are set\n")
        end
        return flag, res.ErrorCode        
      else
        return flag, -1
      end         
    end,  
    
    
    addEmptySpacesAcolumns = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("addEmptySpacesAcolumns: model '%s' does not exist\n",szModel);
        return false, -1
      end  
      local paiColnnz = args[2]
      local res = pModel:addEmptySpacesAcolumns(
        paiColnnz and xta:fielddes(paiColnnz,"panColNonz","int") or nil)
        
      local flag=false
      if res then
        flag = res.ErrorCode==0 
        if flag then    
          logger.debug("setProbAllocSizes: new alloc sizes are set\n")
        end
        return flag, res.ErrorCode        
      else
        return flag, -1
      end         
    end,
    
    solveMIP = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("solveMIP: pModel '%s' does not exist\n",szModel);
        return false, -1
      end
      
      local res = pModel:solveMIP()      
      local flag=res.ErrorCode==0   

      logger.info("solveMIP: termination status:%d, etime:%g, error:%d \n",
      pModel:getInfo(Lindo.info.LS_IINFO_MIP_STATUS).pValue,
      pModel:getInfo(Lindo.info.LS_DINFO_MIP_TOT_TIME).pValue,
      res.ErrorCode) 

      local status = pModel:getInfo(Lindo.info.LS_IINFO_MIP_STATUS).pValue
      
      if status==Lindo.status.LS_STATUS_OPTIMAL or status==Lindo.status.LS_STATUS_FEASIBLE or status==Lindo.status.LS_STATUS_LOCAL_OPTIMAL then
        logger.info("solveMIP: mipobj=%g, bound:%g, status:%d, siter:%g, biter:%g, nodes:%g, etime:%g\n",
          pModel:getInfo(Lindo.info.LS_DINFO_MIP_OBJ).pValue,
          pModel:getInfo(Lindo.info.LS_DINFO_MIP_BESTBOUND).pValue,
          pModel:getInfo(Lindo.info.LS_IINFO_MIP_STATUS).pValue,
          pModel:getInfo(Lindo.info.LS_DINFO_MIP_SIM_ITER).pValue,
          pModel:getInfo(Lindo.info.LS_DINFO_MIP_BAR_ITER).pValue,
          pModel:getInfo(Lindo.info.LS_IINFO_MIP_BRANCHCOUNT).pValue+1,
          pModel:getInfo(Lindo.info.LS_DINFO_MIP_TOT_TIME).pValue          
          )
      end
      return flag,
        res.ErrorCode,
        pModel:getInfo(Lindo.info.LS_IINFO_MIP_STATUS).pValue
    end,
    
    solveGOP = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("solveGOP: pModel '%s' does not exist\n",szModel);
        return false, -1
      end
      
      local res = pModel:solveGOP()      
      local flag=res.ErrorCode==0   

      logger.info("solveGOP: termination status:%d, etime:%g, error:%d \n",
      pModel:getInfo(Lindo.info.LS_IINFO_GOP_STATUS).pValue,
      pModel:getInfo(Lindo.info.LS_DINFO_GOP_TOT_TIME).pValue,
      res.ErrorCode) 

      local status = pModel:getInfo(Lindo.info.LS_IINFO_GOP_STATUS).pValue
      
      if status==Lindo.status.LS_STATUS_OPTIMAL or status==Lindo.status.LS_STATUS_FEASIBLE or status==Lindo.status.LS_STATUS_LOCAL_OPTIMAL then
        logger.info("solveGOP: mipobj=%g, bound:%g, status:%d, siter:%g, biter:%g, boxes:%g, etime:%g\n",
          pModel:getInfo(Lindo.info.LS_DINFO_GOP_OBJ).pValue,
          pModel:getInfo(Lindo.info.LS_DINFO_GOP_BESTBOUND).pValue,
          pModel:getInfo(Lindo.info.LS_IINFO_GOP_STATUS).pValue,
          pModel:getInfo(Lindo.info.LS_DINFO_GOP_SIM_ITER).pValue,
          pModel:getInfo(Lindo.info.LS_DINFO_GOP_BAR_ITER).pValue,
          pModel:getInfo(Lindo.info.LS_IINFO_GOP_BOX).pValue+1,
          pModel:getInfo(Lindo.info.LS_IINFO_GOP_TOT_TIME).pValue          
          )      
      end
      return flag,
        res.ErrorCode,
        pModel:getInfo(Lindo.info.LS_IINFO_GOP_STATUS).pValue
    end,
    
    loadMIPVarStartPoint = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("loadMIPVarStartPoint: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local padPrimal = args[2]
      
      local res = pModel:loadMIPVarStartPoint(
         padPrimal)
         
      local flag=false
      if res then
        flag = res.ErrorCode==0 
        if flag then    
          logger.debug("loadMIPVarStartPoint: new MIP solution is loaded\n")
        end
        return flag, res.ErrorCode        
      else
        return flag, -1
      end    
    end,   
    
    loadVarStartPoint = function(args)
      local szModel = parse_model(args)
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("loadVarStartPoint: model '%s' does not exist\n",szModel);
        return false, -1
      end
      local padPrimal = args[2]
      
      local res = pModel:loadVarStartPoint(
         padPrimal)
         
      local flag=false
      if res then
        flag = res.ErrorCode==0 
        if flag then    
          logger.debug("loadVarStartPoint: new MIP solution is loaded\n")
        end
        return flag, res.ErrorCode        
      else
        return flag, -1
      end    
    end,   
    
    loadVarStartPointPartial = function(args)
      local szModel = parse_model(args)
      local nVars = args[2]
      local paiVars = args[3]
      local padVals = args[4]
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("loadVarStartPointPartial: model '%s' does not exist\n",szModel);
        return false, -1
      end

      local res = pModel:loadVarStartPointPartial(
         nVars,
         paiVars and xta:fielddes(paiVars,"paiVars","int") or nil,
         padVals and xta:fielddes(padVals,"padVals","double") or nil)
         
      local flag = false
      if res then
        flag = res.ErrorCode==0
        return flag, res
      else
        return flag, -1
      end                                          
    end,     
    
    loadMIPVarStartPointPartial = function(args)
      local szModel = parse_model(args)
      local nVars = args[2]
      local paiVars = args[3]
      local padVals = args[4]
      local pModel = modDict[szModel]
      if not pModel then
        logger.warn("loadMIPVarStartPointPartial: model '%s' does not exist\n",szModel);
        return false, -1
      end

      local res = pModel:loadMIPVarStartPointPartial(
         nVars,
         paiVars and xta:fielddes(paiVars,"paiVars","int") or nil,
         padVals and xta:fielddes(padVals,"padVals","double") or nil)
         
      local flag = false
      if res then
        flag = res.ErrorCode==0
        return flag, res
      else
        return flag, -1
      end                                          
    end,                                                           
}

return remote_procedures
