--- A simple JSON-RPC client using a ZeroMQ socket to communicate with the server

require "alt_getopt"
local Lindo = require("llindo_tabox")
local jsonrpc = require("myjson-rpc")
local zmq   = require("lzmq")
local timer = require("lzmq.timer")
local modStack = require("Stack")
local logger  = jsonrpc.logger

local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info

if (xta==nil) then
  xta=tabox.env()
end
local lsmajor,lsminor = 14,0 --xta_get_config('solver_major_version'),xta_get_config('solver_minor_version')
local iModel = -1
local serialize_byfile = Lindo.serialize_byfile

function default_usage()
  print("")
  print("A simple JSON-RPC client using a ZeroMQ socket to communicate with the LINDO API server")
  print("")
  print("Usage: lslua rpc-client.lua [options] [args]")
  print("Options:")
  print("  -h, --help")
  print("  -s, --rpcserver=<url>  URL of the RPC server")
  print("  -v, --verb=<level>     Verbosity level")
  print("  -q, --quit             Quit the server")
  print("  --createEnv            Create a new environment")
  print("  --deleteEnv            Delete the current environment")
  print("  --createModel          Create a new model")
  print("  --deleteModel=<id>     Delete the model with id=<id>")
  print("  --loadLPData=<file>    Load LP data from <file>")
  print("  --optimize=<method>    Optimize the model with <method>")
  print("  --getSolution=<id>     Get solution <id>")
  print("  --getInfo=<id>         Get info <id>")
  print("  --freeSolutionMemory   Free solution memory")
  print("  --freeSolverMemory     Free solver memory")
  print("  --getModelParameter=<id>  Get model parameter <id>")
  print("  --setModelParameter=<id>  Set model parameter <id>")
  print("  --showModels           Show all models")
  print("  --showEnvs             Show all environments")
  print("  --dump_error_objects   Dump error objects")
  print("  --parValue=<value>     Parameter value")
  print("  --lsmajor=<value>      Major version of the solver")
  print("  --lsminor=<value>      Minor version of the solver")
  print("  --ping=<value>         Ping the server")
  print("  --szModel=<id>         Model id")
  print("  --model_file=<file>    Model file")
  print("  --loadMIPVarStartPoint=<file>       Load MIP variable start point from file")
  print("  --solveMIP             Solve MIP")
  print("  --solveGOP             Solve GOP")
  print("  --modifyLowerBounds    Modify lower bounds")
  print("  --modifyUpperBounds    Modify upper bounds")
  print("  --modifyRHS            Modify RHS")
  print("  --modifyAj             Modify Aj")
  print("  --deleteAj             Delete Aj")
  print("  --iModel=<id>          Model id")
  print("")
end

local short = "hs:v:q"
local long = {
  help = "h",
  szModel = 1,
  createEnv = 0,
  deleteEnv = 0,  
  createModel = 0,
  deleteModel = 1,
  loadLPData = 0,
  model_file = 1,
  optimize = 1,
  getSolution = 1,
  getInfo = 1,
  freeSolutionMemory = 0,
  freeSolverMemory = 0,
  getModelParameter = 1,
  setModelParameter = 1,

  ping = 1,   --bitmask
  rpcserver = 's',  
  showModels = 0,
  showEnvs = 0,
  dump_error_objects = 0,
  parValue = 1,
  verb = 'v',
  quit = 'q',
  lsmajor = 1,
  lsminor = 1,
  iModel = 1,
}

local opts, optind, optarg = alt_getopt.get_ordered_opts(arg, short, long)
assert(opts)
if 0>1 then
  xta_dump_alt_getopt(opts,optind,optarg)
  os.exit(1)
end

local cmdOptions={}
cmdOptions.ping = 0
if #arg==0 then 
  default_usage()
  cmdOptions.ping=1; 
end  

for i, k in pairs(opts) do
  local v = optarg[i]
  if k=='rpcserver' then cmdOptions.rpcserver=v
  elseif k=='ping' then cmdOptions.ping = tonumber(v)
  elseif k=='parValue' then cmdOptions.parValue = tonumber(v) 
  elseif k=='model_file' then cmdOptions.model_file = v
    
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
  elseif k=='showModels' then cmdOptions.showModels = true
  elseif k=='showEnvs' then cmdOptions.showEnvs = true
  elseif k=='verb' then cmdOptions.verb = tonumber(v)
  elseif k=='quit' or k =='q' then cmdOptions.quit = true
  elseif k=='lsmajor' then lsmajor = tonumber(v)
  elseif k=='lsminor' then lsminor = tonumber(v)
  elseif k=='dump_error_objects' then cmdOptions.dump_error_objects = true
  elseif k=='loadMIPVarStartPoint' then cmdOptions.loadMIPVarStartPoint = v
  elseif k=='solveMIP' then cmdOptions.solveMIP = true
  elseif k=='solveGOP' then cmdOptions.solveGOP = true
  elseif k=='iModel' then iModel = tonumber(v)
  else
    cmdOptions[k] = true  
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

--- Get remote model by position
-- @param pos Position of the model in the stack
local function getModelAtRemote(pos)
  local request = jsonrpc.encode_rpc(jsonrpc.request, "modelAt", {pos})
  requester:send(request)
  local response = requester:recv()
  
  logger.debug("Received response: %s\n" , response )
  local jnode = jsonrpc.decode(response)
  if jnode.result then
    return jnode.result
  else
    return nil
  end
end

local ping = cmdOptions.ping
if hasbit(ping,bit(1)) then -- ping=+1
-- Request the server to invoke the method 'try1'
  for request_nbr = 0,0 do
      local request = jsonrpc.encode_rpc(jsonrpc.request, "ping1")
  
      logger.info("Pinging server %s\n", server_url)
      requester:send(request)
  
      local response = requester:recv()
      local jnode = jsonrpc.decode(response).result
      logger.info("Server %s responseded '%s' \n" , server_url,jnode )      
  
      timer.sleep(500) -- in ms
  end
end

if hasbit(ping,bit(2)) then -- ping=+2
-- Request the server to invoke the method 'quit', with some arguments
  for request_nbr = 0,2 do
      local request = jsonrpc.encode_rpc(jsonrpc.request, "ping2", {arg1=1, arg2=2})
  
      logger.info("Sending quit request: %s\n" , request)
      requester:send(request)
      return 
  --[[
      local response = requester:recv()
      logger.info("Received response: %s\n" , response )
  ]]
      timer.sleep(500) -- in ms
  
  end
end

if hasbit(ping,bit(3)) then -- ping=+4
-- Now request a non-available method
  local request = jsonrpc.encode_rpc(jsonrpc.request, "ping3", {1})
  logger.info("Sending request: %s\n" , request)
  requester:send(request)
  local response = requester:recv()
  logger.info("Received response: %s\n" , response )  
end

if hasbit(ping,bit(4)) then -- ping=+8
-- Request the server to invoke the method 'try3', with some arguments
  for request_nbr = 0,2 do
      local request = jsonrpc.encode_rpc(jsonrpc.request, "ping4", {arg1=1, arg2=2})
  
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

if cmdOptions.quit then
  local request = jsonrpc.encode_rpc(jsonrpc.request, "quit", {arg1=1, arg2=2})
  logger.info("Sending quit request: %s\n" , request)
  requester:send(request)
  return 
end

if cmdOptions.verb then -- 
  -- Now request a non-available method
    local request = jsonrpc.encode_rpc(jsonrpc.request, "verb", {cmdOptions.verb})
    logger.info("Sending request: %s\n" , request)
    requester:send(request)
    local response = requester:recv()
    logger.info("Received response: %s\n" , response )  
end

local szEnv
if cmdOptions.createEnv then
-- Request the server to invoke the method 'createEnv', with some arguments
      
      local request = jsonrpc.encode_rpc(jsonrpc.request, "createEnv", {lsmajor, lsminor})
  
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
      modStack:push(modStack) 
          
      timer.sleep(500) -- in ms
end

if cmdOptions.deleteModel then
-- Request the server to invoke the method 'deleteModel', with some arguments
      szModel = cmdOptions.deleteModel or getModelAtRemote(iModel) 
      assert(szModel,"\nError: --deleteModel=<id> is required\n")
      local request = jsonrpc.encode_rpc(jsonrpc.request, "deleteModel", {szModel})
  
      logger.info("Sending request: %s\n" , request)
      requester:send(request)
  
      local response = requester:recv()
      logger.info("Received response: %s\n" , response )
      local pos = modStack:pos(szModel)
      if pos then 
        modStack:remove(pos) 
      end
          
      timer.sleep(500) -- in ms
end


if cmdOptions.loadLPData then
  
   modStack:list()
   szModel = cmdOptions.szModel or getModelAtRemote(iModel)
   assert(szModel,"\nError: --szModel is required\n") 
   local model_file = cmdOptions.model_file or sprintf("%s\\lp\\mps\\netlib\\afiro.mps.gz",os.getenv("LS_PROB_PATH")) 
   local arg={}
   arg[1] = szModel
   logger.info("Loading '%s' into '%s'\n",model_file,szModel)
   arg[2] = serialize_byfile(model_file)
   if not (arg[2]) then
      logger.error("Failed to serialize '%s'\n",model_file)       
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
   szModel = cmdOptions.szModel or getModelAtRemote(iModel)
   assert(szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=szModel
   arg[2]=cmdOptions.optimize
   
    -- Request the server to invoke the method 'optimize', with some arguments
    local request = jsonrpc.encode_rpc(jsonrpc.request, "optimize", arg)

    logger.info("Sending request: %s\n" , request)
    requester:send(request)

    --do
    local response = requester:recv()
    logger.info("Received response: %s\n" , response )            
    --end
    
    timer.sleep(500) -- in ms   
end

if cmdOptions.solveMIP then
   szModel = cmdOptions.szModel or getModelAtRemote(iModel)
   assert(szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=szModel
   
    -- Request the server to invoke the method 'optimize', with some arguments
    local request = jsonrpc.encode_rpc(jsonrpc.request, "solveMIP", arg)

    logger.info("Sending request: %s\n" , request)
    requester:send(request)

    local response = requester:recv()
    logger.info("Received response: %s\n" , response )      
        
    timer.sleep(500) -- in ms   
end

if cmdOptions.solveGOP then
   szModel = cmdOptions.szModel or getModelAtRemote(iModel)
   assert(szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=szModel
   
    -- Request the server to invoke the method 'optimize', with some arguments
    local request = jsonrpc.encode_rpc(jsonrpc.request, "solveGOP", arg)

    logger.info("Sending request: %s\n" , request)
    requester:send(request)

    local response = requester:recv()
    logger.info("Received response: %s\n" , response )      
        
    timer.sleep(500) -- in ms   
end

if cmdOptions.freeSolutionMemory  then
   szModel = cmdOptions.szModel or getModelAtRemote(iModel)
   assert(szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=szModel
   
    -- Request the server to invoke the method 'freeSolutionMemory', with some arguments
    local request = jsonrpc.encode_rpc(jsonrpc.request, "freeSolutionMemory", arg)

    logger.info("Sending request: %s\n" , request)
    requester:send(request)

    local response = requester:recv()
    logger.info("Received response: %s\n" , response )      
        
    timer.sleep(500) -- in ms   
end

if cmdOptions.freeSolverMemory then
   szModel = cmdOptions.szModel or getModelAtRemote(iModel)
   assert(szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=szModel
   
    -- Request the server to invoke the method 'freeSolverMemory', with some arguments
    local request = jsonrpc.encode_rpc(jsonrpc.request, "freeSolverMemory", arg)

    logger.info("Sending request: %s\n" , request)
    requester:send(request)

    local response = requester:recv()
    logger.info("Received response: %s\n" , response )      
        
    timer.sleep(500) -- in ms   
end


if cmdOptions.getSolution then
   szModel = cmdOptions.szModel or getModelAtRemote(iModel)
   assert(szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=szModel
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
      local jnode = jsonrpc.decode(response)
      if #jnode.result[2]>0 then
        for k,v in spairs(jnode.result[2],stackpos) do
          local szModel_ = jnode.result[1][k]
          local pos = jnode.result[2][k]
          logger.info("pModel '%s' is at pos %d\n",szModel_,pos)
        end      
      else
        if logger.level == 'debug' then print_table3(jnode) end
        logger.warn("Model list is empty!\n")
      end
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
   szModel = cmdOptions.szModel or getModelAtRemote(iModel)
   assert(szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=szModel
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
   szModel = cmdOptions.szModel or getModelAtRemote(iModel)
   assert(szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=szModel
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
   szModel = cmdOptions.szModel or getModelAtRemote(iModel)
   assert(szModel,"\nError: --szModel is required\n")
   local arg={}
   arg[1]=szModel
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