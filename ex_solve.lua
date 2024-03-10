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
local log_digests, sol_digests

local platform_name = {
    [xta.const.win32x86] = "win32",
    [xta.const.win64x86] = "win64",
    [xta.const.linux64x86] = "linux64x86",
    [xta.const.osx64x86] = "osx64x86"
}

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
    local temp_base = sprintf("tmp/%s",platform_name[xta.platformid] or "unknown")
    if not paths.dirp(temp_base) then
        paths.mkdir(temp_base)
    end
    return temp_base
end

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
end


local ktryenv = options.ktryenv
while ktryenv>0 do
    ktryenv = ktryenv-1
    ls_runlindo(ktryenv,options)    
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

