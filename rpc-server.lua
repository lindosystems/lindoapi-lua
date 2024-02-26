#!/usr/bin/env lslua
--- A dummy JSON-RPC server receiving requests on a ZeroMQ socket
local usage = [[
Start an instance of RPC server
Example:
    $ lslua rpc-server.lua --rpcserver=localhost
]]
require "alt_getopt"
local Lindo = require("llindo_tabox")
local jsonrpc = require("myjson-rpc")
local procedures = require("llindo_rpc")
local zmq  = require("lzmq")
local timer = require("lzmq.timer")
local logger = jsonrpc.logger

local short = "s:h"
local long = {
  rpcserver = 1,
  help = 0
}

local opts, optind, optarg = alt_getopt.get_ordered_opts(arg, short, long)
assert(opts)
if 0>1 then
  xta_dump_alt_getopt(opts,optind,optarg)
  os.exit(1)
end

local cmdOptions={}
cmdOptions.rpcserver='localhost'

for i, k in pairs(opts) do
  local v = optarg[i]
  if     k=='rpcserver' then cmdOptions.rpcserver=v   
  else cmdOptions[k] = true
  end
end
--print_table3(cmdOptions)

-- Signal handling requires luaposix
--local signal = require("posix.signal")

-- ZMQ for the networking

-- Global var to control the run status
-- Set CTRL-C to stop the running
local run = true

--signal.signal(signal.SIGINT, function(signum)
--  run = false
--end)


if 2>1 then
  local error_objects = require("lserr_objects")
  if error_objects then
    --print_table3(error_objects)
    for k,v in pairs(error_objects) do
      --print_table3(v)       
      jsonrpc.add_error_object(k,v)
    end         
    logger.info("Loaded error objects to RPC..\n")   
  end
end

-- Set up the socket
local rpcport,url,rpchost = get_zmq_server_url(cmdOptions.rpcserver)
local context = zmq.context()
local responder, err = context:socket{zmq.REP, bind = url}
zmq.assert(responder, err)

local verb = 1
-- The "event loop" ...
while run do
    local req, err = responder:recv()
    print("received: " .. req)
    if err == false then              
        local res = jsonrpc.server_response(procedures, req)
        if verb>0 then
          print_table3(res) 
        end

        if req:find("verb") and res.result then
          verb=res.result
          glogger.debug("Verb set to "..verb)
        end

        if req:find("quit") and res.result=='ok' then
          run=false
        end

        res = jsonrpc.encode(res)
        zmq.assert(responder:send(res))
        print("sent: " .. res)
    else
        logger:error("'recv()' failed: " .. tostring(err))
        timer.sleep(100) -- in ms
    end
end
print("exiting...")

responder:close(0)
context:shutdown(0)



