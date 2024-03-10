#!/usr/bin/env lslua
local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local status = Lindo.status
require 'ex_cbfun'
require 'llindo_usage'

local options, opts, optarg 


local function usage(help_)
  print()
  print("Usage: lsscan_tuner_log.lua -f <filename>")
  print()
  if help_ then print_default_usage() end
  print()
  print("App. Options:")
  print("  -f <filename>           Specify the filename to process.")
  print("  -v, --verb=INTEGER      Enable verbose mode")    
  print("  -h, --help              Show this help message")  
  print("")
  if not help_ then print_help_option() end        
  print("Example:")
  print("\t lslua lsscan_tuner_log.lua -f /path/to/model.mps [options]")    	
  print()    
end  

local long = {       

}

local short = ""
options, opts, optarg = parse_options(arg,short,long)

if options.help then
  usage(true)
  return
end

local logFile = options.input_file
local verb = options.verb and options.verb or 1

if not logFile then
    usage()
    return
end


-- Table to keep track of instances and their configs
local instances = {}
-- Table to keep track of runs
local runs = {}

-- Read the log file line by line
local file = io.open(logFile, "r")
if not file then
  print("Could not open log file.")
  return
end

local currentConfigId = nil
local currentInstanceId = nil
for line in file:lines() do
  -- Check if the line indicates the start of an instance
  local instanceId, instanceFile = line:match("Starting instance #(%d+) '(.+)'")
  if instanceId and instanceFile then
    currentInstanceId = instanceId  -- Keep track of the current instance ID
    instances[instanceId] = {file = instanceFile, config = {}}
  end

  -- Check if the line indicates the start of a config section
  local configId = line:match("config%[(%d+)%] :")
  if configId then
    currentConfigId = configId
  elseif currentConfigId and line:find("=") then
    -- Remove leading and trailing spaces, and capture the configuration parameter and its value
    local param, value = line:match("^%s*(.-)%s*=%s*(.-)%s*$")
    if param and value then
      -- Ensure the config table for this id exists and store the parameter and value
      if not instances[currentInstanceId].config[currentConfigId] then
        instances[currentInstanceId].config[currentConfigId] = {}
      end
      instances[currentInstanceId].config[currentConfigId][param] = value
    end
  end
  
  -- Check if the line indicates the start of a run
  local instanceStart, configStart = line:match("Instance #(%d+) is solving with config%[(%d+)%]")
  if instanceStart and configStart then
    -- Store the start of the run in the runs table
    local key = "Instance #" .. instanceStart .. ", config[" .. configStart .. "]"
    runs[key] = "started"
  end

  -- Check if the line indicates the completion of a run
  local instanceEnd, configEnd = line:match("Instance #(%d+), config%[(%d+)%] run completed")
  if instanceEnd and configEnd then
    -- Mark the run as completed
    local key = "Instance #" .. instanceEnd .. ", config[" .. configEnd .. "]"
    runs[key] = "completed"
  end  
end

file:close()

if verb>1 then
	-- Output the instances with their file names and config contents
	for id, instance in pairs(instances) do
	  print("Instance #" .. id .. " file: " .. instance.file)
	  print("Config for instance #" .. id .. ":")
	  for configId, configParams in pairs(instance.config) do
      print("  Config " .. configId .. ":")
      for param, value in pairs(configParams) do
        print("    " .. param .. " = " .. value)
      end
	  end
	end
end
print(#instances .. " instances found.")
--print_table3(instances)
if verb>0 then
	-- Check for runs that started but did not complete
	for key, status in pairs(runs) do
	  if status == "started" then
      local instanceId, configId = key:match("Instance #(%d+), config%[(%d+)%]")
      print()
		  printf("Run started but did not complete '%s': %s\n", key, instances[instanceId].file)
      print()
      print("  Config " .. configId .. ":")
      local configParams = instances[instanceId].config[configId]
      for param, value in pairs(configParams) do
        print("    " .. param .. " = " .. value)
      end
      if options and options.solve and options.solve>0 then
        local model_file = cygpath_w(instances[instanceId].file)
        if not options.tlim then
          glogger.error("No time limit specified, this app requires a time limit to be set.\n")
          return
        else   
          options.model_file = model_file    
          ls_runlindo(0,options,configParams)
        end
      end
	  end
	end
end