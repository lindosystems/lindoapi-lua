--- A dummy JSON-RPC client using a ZeroMQ socket to communicate with the server

require ("rpc-helper")
require "alt_getopt"
local jsonrpc = require("myjson-rpc")
local logger  = jsonrpc.logger
local zmq   = require("lzmq")
local timer = require("lzmq.timer")
local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info

if (xta==nil) then
  xta=tabox.env()
end
local vermaj,vermin = 13,0 --xta_get_config('solver_major_version'),xta_get_config('solver_minor_version')

local getSerializedLPData = Lindo.getSerializedLPData

local short = "s:t:"
local long = {
  szModel = 1,
  createEnv = 0,
  deleteEnv = 0,  
  createModel = 0,
  deleteModel = 1,
  loadLPData = 0,
  mpsfile = 1,
  optimize = 1,
  getSolution = 1,
  getInfo = 1,
  freeSolutionMemory = 0,
  freeSolverMemory = 0,
  getModelParameter = 1,
  setModelParameter = 1,

  itry = 1,
  rpcserver = 1,  
  showModels = 0,
  showEnvs = 0,
  dump_error_objects = 0,
  parValue = 1,
}

local opts, optind, optarg = alt_getopt.get_ordered_opts(arg, short, long)
assert(opts)
if 0>1 then
  xta_dump_alt_getopt(opts,optind,optarg)
  os.exit(1)
end

local cmdOptions={}
cmdOptions.itry = 0
for i, k in pairs(opts) do
  local v = optarg[i]
  if k=='rpcserver' then cmdOptions.rpcserver=v
  elseif k=='itry' then cmdOptions.itry = tonumber(v)
  elseif k=='parValue' then cmdOptions.parValue = tonumber(v) 
  elseif k=='mpsfile' then cmdOptions.mpsfile = v
    
  elseif k=='createEnv' then cmdOptions.createEnv = true
  elseif k=='deleteEnv' then cmdOptions.deleteEnv = true  
  elseif k=='createModel' then cmdOptions.createModel = true
  elseif k=='deleteModel' then cmdOptions.deleteModel = v
  elseif k=='szModel' then cmdOptions.szModel = v
  elseif k=='loadLPData' then cmdOptions.loadLPData = true
  elseif k=='optimize' then cmdOptions.optimize = tonumber(v)
  elseif k=='getSolution' then cmdOptions.getSolution = v
  elseif k=='getInfo' then cmdOptions.getInfo = v
  elseif k=='freeSolutionMemory' then cmdOptions.freeSolutionMemory = true
  elseif k=='freeSolverMemory' then cmdOptions.freeSolverMemory = true
  elseif k=='setModelParameter' then cmdOptions.setModelParameter = tonumber(v) or pars[v]
  elseif k=='getModelParameter' then cmdOptions.getModelParameter = tonumber(v) or pars[v]

  else cmdOptions[k] = true
  end
end
--print_table3(cmdOptions)
  
-- Establish connection with the RPC server

local rpcport,server_url = get_zmq_client_url(cmdOptions.rpcserver)
logger.info("Attempting to connect to %s \n" , server_url)

local context = zmq.context()
local requester, err = context:socket{zmq.REQ,
  connect = server_url
}
zmq.assert(requester, err)

local itry = cmdOptions.itry
if hasbit(itry,bit(1)) then
-- Request the server to invoke the method 'try1'
  for request_nbr = 0,2 do
      local request = jsonrpc.encode_rpc(jsonrpc.request, "try1")
  
      logger.info("Sending request: %s \n", request)
      requester:send(request)
  
      local response = requester:recv()
      logger.info("Received response: %s \n" , response )
  
      timer.sleep(500) -- in ms
  end
end

if hasbit(itry,bit(2)) then
-- Request the server to invoke the method 'try2', with some arguments
  for request_nbr = 0,2 do
      local request = jsonrpc.encode_rpc(jsonrpc.request, "try2", {arg1=1, arg2=2})
  
      logger.info("Sending request: %s\n" , request)
      requester:send(request)
  
      local response = requester:recv()
      logger.info("Received response: %s\n" , response )
  
      timer.sleep(500) -- in ms
  end
end

if hasbit(itry,bit(3)) then
-- Now request a non-available method
  local request = jsonrpc.encode_rpc(jsonrpc.request, "not-available", {"foo"})
  logger.info("Sending request: %s\n" , request)
  requester:send(request)
  local response = requester:recv()
  logger.info("Received response: %s\n" , response )
  
end

if hasbit(itry,bit(4)) then
-- Request the server to invoke the method 'try3', with some arguments
  for request_nbr = 0,2 do
      local request = jsonrpc.encode_rpc(jsonrpc.request, "try3", {arg1=1, arg2=2})
  
      logger.info("Sending request: %s\n" , request)
      requester:send(request)
  
      local response = requester:recv()
      logger.info("Received response: %s\n" , response:sub(1,20) .. " ...}" )
      local jnode = jsonrpc.decode(response).result
      --print_table3(jnode)
      
      local fPrimal = xta:field(0,"primal","double")
      fPrimal:des(jnode.jstrPrimal)
      fPrimal:print()
      if jnode.jstrDual then
        local fDual = xta:field(0,"dual","double")
        fDual:des(jnode.jstrDual)
        fDual:print()   
      end
  
      timer.sleep(500) -- in ms
  end
end

local szEnv
if cmdOptions.createEnv then
-- Request the server to invoke the method 'createEnv', with some arguments

      local vermaj,vermin = vermaj or 13,vermin or 0
      local request = jsonrpc.encode_rpc(jsonrpc.request, "createEnv", {vermaj=vermaj, vermin=vermin})
  
      logger.info("Sending request: %s\n" , request)
      requester:send(request)
  
      local response = requester:recv()
      logger.info("Received response: %s\n" , response )
      szEnv = response.result
      
      local request = jsonrpc.encode_rpc(jsonrpc.request, "versionInfo", {arg1=1, arg2=2})
  
      logger.info("Sending request: %s\n" , request)
      requester:send(request)
  
      local response = requester:recv()
      logger.info("Received response: %s\n" , response )    
           
      timer.sleep(500) -- in ms
end

if cmdOptions.dump_error_objects then
  local request = jsonrpc.encode_rpc(jsonrpc.request, "dump_error_objects", {arg1=1, arg2=2})

  logger.info("Sending request: %s\n" , request)
  requester:send(request)

  local response = requester:recv()
  logger.info("Received response: %s ...\n" , response )  
  timer.sleep(500) -- in ms
end 

if cmdOptions.deleteEnv then
-- Request the server to invoke the method 'deleteEnv', with some arguments

      local request = jsonrpc.encode_rpc(jsonrpc.request, "deleteEnv", {arg1=1, arg2=2})
  
      logger.info("Sending request: %s\n" , request)
      requester:send(request)
  
      local response = requester:recv()
      logger.info("Received response: %s\n" , response )
      
      timer.sleep(500) -- in ms
end

local szModel
if cmdOptions.createModel then
-- Request the server to invoke the method 'createModel', with some arguments
      local request = jsonrpc.encode_rpc(jsonrpc.request, "createModel", {szEnv})
  
      logger.info("Sending request: %s\n" , request)
      requester:send(request)
  
      local response = requester:recv()
      logger.info("Received response: %s\n" , response )
      szModel = response.result
          
      timer.sleep(500) -- in ms
end

if cmdOptions.deleteModel then
-- Request the server to invoke the method 'deleteModel', with some arguments
      szModel = cmdOptions.deleteModel
      local request = jsonrpc.encode_rpc(jsonrpc.request, "deleteModel", {szModel})
  
      logger.info("Sending request: %s\n" , request)
      requester:send(request)
  
      local response = requester:recv()
      logger.info("Received response: %s\n" , response )      
          
      timer.sleep(500) -- in ms
end


if cmdOptions.loadLPData then
   assert(cmdOptions.szModel,"\nError: --szModel is required\n") 
   local mpsfile = cmdOptions.mpsfile or sprintf("%s\\lp\\mps\\netlib\\afiro.mps.gz",os.getenv("LS_PROB_PATH")) 
   local arg={}
   arg[1] = cmdOptions.szModel
   arg[2] = getSerializedLPData(mpsfile)
   if not (arg[2]) then
      logger.error("Failed to serialize '%s'\n",mpsfile)       
   end   
   assert(arg[2])
   
    -- Request the server to invoke the method 'loadLPData', with some arguments
    local request = jsonrpc.encode_rpc(jsonrpc.request, "loadLPData", arg)

    logger.debug("Sending request (digest): %s\n" , xta:hash(request))
    requester:send(request)

    local response = requester:recv()
    logger.info("Received response: %s\n" , response )      
        
    timer.sleep(500) -- in ms
end

if cmdOptions.optimize then
   assert(cmdOptions.szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=cmdOptions.szModel
   arg[2]=cmdOptions.optimize
   
    -- Request the server to invoke the method 'optimize', with some arguments
    local request = jsonrpc.encode_rpc(jsonrpc.request, "optimize", arg)

    logger.info("Sending request: %s\n" , request)
    requester:send(request)

    local response = requester:recv()
    logger.info("Received response: %s\n" , response )      
        
    timer.sleep(500) -- in ms   
end

if cmdOptions.solveMIP then
   assert(cmdOptions.szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=cmdOptions.szModel
   
    -- Request the server to invoke the method 'optimize', with some arguments
    local request = jsonrpc.encode_rpc(jsonrpc.request, "solveMIP", arg)

    logger.info("Sending request: %s\n" , request)
    requester:send(request)

    local response = requester:recv()
    logger.info("Received response: %s\n" , response )      
        
    timer.sleep(500) -- in ms   
end

if cmdOptions.solveGOP then
   assert(cmdOptions.szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=cmdOptions.szModel
   
    -- Request the server to invoke the method 'optimize', with some arguments
    local request = jsonrpc.encode_rpc(jsonrpc.request, "solveGOP", arg)

    logger.info("Sending request: %s\n" , request)
    requester:send(request)

    local response = requester:recv()
    logger.info("Received response: %s\n" , response )      
        
    timer.sleep(500) -- in ms   
end

if cmdOptions.freeSolutionMemory  then
   assert(cmdOptions.szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=cmdOptions.szModel
   
    -- Request the server to invoke the method 'freeSolutionMemory', with some arguments
    local request = jsonrpc.encode_rpc(jsonrpc.request, "freeSolutionMemory", arg)

    logger.info("Sending request: %s\n" , request)
    requester:send(request)

    local response = requester:recv()
    logger.info("Received response: %s\n" , response )      
        
    timer.sleep(500) -- in ms   
end

if cmdOptions.freeSolverMemory then
   assert(cmdOptions.szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=cmdOptions.szModel
   
    -- Request the server to invoke the method 'freeSolverMemory', with some arguments
    local request = jsonrpc.encode_rpc(jsonrpc.request, "freeSolverMemory", arg)

    logger.info("Sending request: %s\n" , request)
    requester:send(request)

    local response = requester:recv()
    logger.info("Received response: %s\n" , response )      
        
    timer.sleep(500) -- in ms   
end


if cmdOptions.getSolution then
   assert(cmdOptions.szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=cmdOptions.szModel
   local solutionId = cmdOptions.getSolution
   
    -- Request the server to invoke the method 'optimize', with some arguments
    local request
    if solutionId=='primal' then 
      request = jsonrpc.encode_rpc(jsonrpc.request, "getPrimalSolution", arg)
    elseif solutionId=='dual' then
      request = jsonrpc.encode_rpc(jsonrpc.request, "getDualSolution", arg)
    elseif solutionId=='dj' then
      request = jsonrpc.encode_rpc(jsonrpc.request, "getReducedCosts", arg)
    elseif solutionId=='slacks' then
      request = jsonrpc.encode_rpc(jsonrpc.request, "getSlacks", arg)
    end

    logger.info("Sending request: %s\n" , request)
    requester:send(request)

    local response = requester:recv()
    logger.trace("Received response: %s\n" , response )
    local res = jsonrpc.decode(response)
    if res then
      local result = res.result      
      --print_table3(res)
      if result[1]==errs.LSERR_NO_ERROR then
        local fvec = xta:fielddes(result[2],solutionId,"double")
        fvec:print()
      else
        logger.error("Cannot access solution '%s', error: %d\n",solutionId,result[1])
        print_table3(result)
      end
    else
      logger.error("Unknown RPC error\n")
    end
        
    timer.sleep(500) -- in ms   
end

if cmdOptions.showModels then
-- Request the server to invoke the method 'showModels', with some arguments

      local request = jsonrpc.encode_rpc(jsonrpc.request, "showModels", {arg1=1, arg2=2})
  
      logger.info("Sending request: %s\n" , request)
      requester:send(request)
  
      local response = requester:recv()
      logger.debug("Received response: %s\n" , response )
      print_table3(jsonrpc.decode(response))
      
      timer.sleep(500) -- in ms
end

if cmdOptions.showEnvs then
-- Request the server to invoke the method 'showModels', with some arguments

      local request = jsonrpc.encode_rpc(jsonrpc.request, "showEnvs", {arg1=1, arg2=2})
  
      logger.info("Sending request: %s\n" , request)
      requester:send(request)
  
      local response = requester:recv()
      logger.debug("Received response: %s\n" , response )
      print_table3(jsonrpc.decode(response))
      
      timer.sleep(500) -- in ms
end

if cmdOptions.getInfo then
-- Request the server to invoke the method 'showModels', with some arguments
   assert(cmdOptions.szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=cmdOptions.szModel
   arg[2]=cmdOptions.getInfo
   
    local request = jsonrpc.encode_rpc(jsonrpc.request, "getInfo", arg)

    logger.info("Sending request: %s\n" , request)
    requester:send(request)

    local response = requester:recv()
    logger.debug("Received response: %s\n" , response )
    print_table3(jsonrpc.decode(response))
    
    timer.sleep(500) -- in ms
end

if cmdOptions.getModelParameter then
-- Request the server to invoke the method 'getModelParameter', with some arguments
   assert(cmdOptions.szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=cmdOptions.szModel
   arg[2]=cmdOptions.getModelParameter

   
    local request = jsonrpc.encode_rpc(jsonrpc.request, "getModelParameter", arg)

    logger.info("Sending request: %s\n" , request)
    requester:send(request)

    local response = requester:recv()
    logger.debug("Received response: %s\n" , response )
    print_table3(jsonrpc.decode(response))
    
    timer.sleep(500) -- in ms
end

if cmdOptions.setModelParameter then
-- Request the server to invoke the method 'setModelParameter', with some arguments
   assert(cmdOptions.szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=cmdOptions.szModel
   arg[2]=cmdOptions.setModelParameter
   arg[3]=cmdOptions.parValue   
   
    local request = jsonrpc.encode_rpc(jsonrpc.request, "setModelParameter", arg)

    logger.info("Sending request: %s\n" , request)
    requester:send(request)

    local response = requester:recv()
    logger.debug("Received response: %s\n" , response )
    print_table3(jsonrpc.decode(response))
    
    timer.sleep(500) -- in ms
end

--[[
    modifyLowerBounds = function(args)
    modifyUpperBounds = function(args)
    modifyRHS = function(args)
    modifyAj = function(args)
    deleteAj = function(args)
    modifyObjective = function(args)
    modifyObjConstant = function(args)
    modifyConstraintType = function(args)
    addConstraints = function(args)
    addVariables = function(args)
    deleteConstraints = function(args)
    deleteVariables = function(args)
    loadBasis = function(args)
    setProbAllocSizes = function(args)
    addEmptySpacesAcolumns = function(args)
    loadMIPVarStartPoint = function(args)
]]

requester:close(0)
context:shutdown(0)