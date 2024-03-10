#!/usr/bin/env lslua
-- File: ex_solve.lua
-- Description: Example of reading a model from a supported file format and optimizing it.
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


-- parse app specific options
function app_options(options,k,v)
    if k=="addobjcut" then options.addobjcut=tonumber(v) 
    elseif k=="histmask" then options.histmask=tonumber(v)
    elseif k=="xuserdll" then options.xuserdll=v 
	else
		printf("Unknown option '%s'\n",k)
    end    
end


---
-- Parse command line arguments
local function usage(help_)
    print()
    print("Read a model from a supported file format and optimize or modify.")
    print()
    print("Usage: lslua ex_solve.lua [options]")
    print()
    if help_ then print_default_usage() end
    print()
    print("App. Options:")
    print("    , --addobjcut=[number]      Add objcut with rhs 'number' (default: nil)")    
    print("    , --histmask=[number]       Analyze LP data with histogram with specified mask 'number' (default: nil)")    
    print("    , --xuserdll=[string]       Set user DLL (default: nil)")
	print("")
	if not help_ then print_help_option() end        
    print("Example:")
    print("\t lslua ex_solve.lua -m /path/to/model.mps [options]")    	
    print("\t lslua ex_solve.lua -m ~/prob/milp/mps/miplib3/p0201.mps.gz --cblog=0 --cbmip=1") 
    print("\t lslua ex_solve.lua -m ~/prob/lp/mps/netlib/25fv47.mps.gz --ranges=obj,bnd,rhs")     
    print("\t lslua ex_solve.lua -m ~/prob/nlp/mpi/nonconvex/dejong.gz --gop")     
    print("\t lslua ex_solve.lua -m ~/prob/nlp/mpi/nonconvex/dejong.gz --multis=10")     
	print()    
end   

local short=""
local long={
    addobjcut = 1,
    histmask = 1,
    xuserdll = 1,
}
local options, opts, optarg = parse_options(arg,short,long)

if options.help then
	usage(true)
	return
end

if not options.model_file then
	usage(options.help)
	return
end	

if not options.ktrylogf and 0> 1 then
    if options.ktryenv or options.ktrymod or options.ktrysolv then
        options.ktrylogf = getBasename(options.model_file)
    end
end

local model_list, model_dir
model_dir = paths.dirname(options.model_file)
if options.model_file:find(".list") then
    model_list = read_file_lines(options.model_file)
    if not model_list then
        glogger.error("Failed to read model list from %s\n",options.model_file)
        return
    end
else
    local model_file = paths.basename(options.model_file)
    model_list = {model_file}
end

-- Setup log and sol digest tables
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
    options.log_digests = log_digests
    options.sol_digests = sol_digests
    options.cblog = 0
    options.cbmip = 1  
end


-- Solve all models in the list
for k=1,#model_list do    
    local ktryenv = options.ktryenv
    local model_file = sprintf("%s/%s",model_dir,model_list[k])
    options.model_file = model_file
    while ktryenv>0 do
        ktryenv = ktryenv-1
        ls_runlindo(ktryenv,options)    
    end
end

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

