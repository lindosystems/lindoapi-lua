#!/usr/bin/env lslua
-- File: ex_solu2sol.lua
-- Description: Convert Lingo solution file to a solution file for a related MPI model.
-- Author: mka
-- Date: 2019-07-01

local solver
local options, opts, optarg

-- runlindo
local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local status = Lindo.status
require 'ex_cbfun'
require 'llindo_usage'

if (xta==nil) then
  xta = tabox.env()
end

function trimString(s)
    return s:match("^%s*(.-)%s*$")
end

-- Replace '(' with '_' and ')' with ''
function lingo_scalarized_name(name)
    local name2 = name:gsub("%(","_"):gsub("%)","")
    name2 = name2:gsub(",","_")
    return name2
end

-- Function to parse a fixed-width text file with two columns
function parseFixedWidthFile(lines)
    local data = {}  -- Store variables with native Lingo names
    for _, line in ipairs(lines) do        
        local key = line:sub(1,60)
        local value = tonumber(line:sub(70,-1))  -- Extract and convert the value to a number        
        key = trimString(key)
        local key2= lingo_scalarized_name(key)
        --print(key,key:gsub(" ",""),value)        
        data[key2] = value  -- Add the key-value pair to the table
        --printf("'%s' = %s\n",key2,value)
    end       
    if options.verb>3 then print_table3(data) end
    return data
end

-- Function to parse a fixed-width text file with two columns delimited with '='
function parseScalarizedInitFile(lines)
    local data = {}  -- Store variables with native Lingo names
    for _, line in ipairs(lines) do        
        local tokens = split(line,"=")                
        if tokens[1] and tokens[2] then            
            local key = trimString(tokens[1])
            tokens[2] = tokens[2]:gsub(";","")
            local value = tonumber(tokens[2])  -- Extract and convert the value to a number       
            data[key] = value  -- Add the key-value pair to the table
        end
    end    
    if options.verb>3 then print_table3(data) end
    return data
end

-- Usage function
local function usage(help_)
    print()
    print("Read solution of a Lingo model and create a solution file for a related MPI model.")
    print()
    print("Usage: lua ex_solu2sol.lua [options]")
    print("Example:")
    print("\t lslua ex_solu2sol.lua -f /path/to/my.solu -m /path/to/my.mpi [options]")
    print()
    if help_ then print_default_usage() end
    print()
    print("    , --solve                    Solve last state of model")
	print("")
	if not help_ then print_help_option() end        
	print()    
end  
---
-- Parse command line arguments
local long={
    solve = 0
}
local short = ""
options, opts, optarg = parse_options(arg,short,long)
--print_table3(options)

-- parse app specific options
for i, k in pairs(opts) do
    local v = optarg[i]             
    if k=="solve" then options.solve=true end
end

options.verb = math.max(options.verb and options.verb or 1, 2)
if not options.input_file then
	usage()
	return
end	

-- New solver instance
xta:setsolverdll("",8);
xta:setlindodll(14,0)
solver = xta:solver()
printf("Created a new solver instance %s\n",solver.version);
local ymd,hms = xta:datenow(),xta:timenow() 
local jsec = xta:jsec(ymd,hms)
printf("Timestamp: %06d-%06d jsec:%d\n",ymd,hms,jsec)
local res

local pModel = solver:mpmodel()
glogger.info("Created a new model instance\n");
pModel.usercalc=xta.const.size_max
if options.has_cblog>0 then    
	pModel.logfun = myprintlog
	glogger.info("Set a new log function for the model instance\n");
end	

-- Read model from file	
glogger.info("Reading %s\n",options.model_file)
local nErr = pModel:readfile(options.model_file,0)
pModel:xassert({ErrorCode=nErr})

local solu_file
local lines_solu, lines_init
local t_solu, t_init
if 0>1 then
    -- non-scalar solution file
    solu_file = changeFileExtension(options.input_file,".init")
else    
    -- scalarized solution file
    solu_file = options.input_file
end
printf("Reading solution file '%s'\n",solu_file) 
lines_solu = lines_from(solu_file)
t_solu = parseFixedWidthFile(lines_solu)
if solu_file:find(".init") then
    lines_init = lines_from(solu_file)
    t_init = parseScalarizedInitFile(lines_init)
end
local szsol = ""
local nfound = 0
if 2>1 then
    for j=1,pModel.numvars do
        local res = pModel:getVariableNamej(j-1)
        pModel:xassert(res)
        local name = res.pachVarName
        local value     
        local name2 = lingo_scalarized_name(name)
        if t_init then 
            -- use .init file        
            value = t_init[name2]
        else
            -- use t_sol
            value = t_solu[name2]
        end
        if value then
            --pModel:setvar(j,value)
            szsol = szsol .. sprintf("%60s %22.9e\n",name,value)
            nfound = nfound + 1
        else        
            printf("Warning: value for '%s' ~ '%s' is *not* found.\n",name,name2)
            os.exit(1)
        end    
    end
    printf("Found %d values.\n",nfound)    
end
local outfile = changeFileExtension(options.model_file,".sol~")
fwritef(outfile,"w","%s",szsol)
printf("Wrote solution to '%s'\n",outfile)

solver:dispose()
printf("Disposed solver instance %s\n",tostring(solver))  
