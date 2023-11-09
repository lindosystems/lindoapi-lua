-- File: ex_cbfun.lua
-- Description: Example of using callback functions with the Lindo API
-- Author: [Your Name Here]
-- Date: [Date Here]
package.path = package.path..";./?.lua;./share/lua/5.1/?.lua;./share/lua/5.1/?/init.lua"
package.cpath = package.cpath..";./lib/win32x86/systree/lib/lua/5.1/?.dll;./lib/win32x86/systree/lib/lua/5.1/?.so;./lib/win32x86/systree/lib/lua/5.1/?.dylib"

local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local status = Lindo.status

--- Callback function for logging messages from  with respect to Lindo API
-- @param pModel Pointer to the model instance
-- @param str String to be printed
function myprintlog(pModel, str)
    printf("%s", str)
    if string.len(str)<-2 then
		io.read()
	end
end


--- Callback function that gets called everytime a new MIP solution is found
-- @param pModel Pointer to the model instance
-- @param dobj Objective value of the new MIP solution
-- @param pX Pointer to the new MIP solution
function cbmip(pModel, dobj, pX, udata)
    local iter,bncnt,lpcnt,mipcnt,pfeas,bestbnd,pobj,accnt,status,curtime 
    local szerr
    local res
    local iLoc = 5
    local retval = 0
    local counter = pModel.utable.counter
    if counter%20==0 then
        printf("\n\n%6s %8s %8s %8s %14s %14s %14s %8s %6s %8s %10s\n",
        "LOC","ITER","BRANCH","LPs","INFEAS","BEST BND","BEST SOL","ACTIVE","STATUS","CPUTIME","|X|");
    end
    counter = counter + 1
    pModel.utable.counter = counter

    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_ITER)
    iter = res and res.pValue or 0

    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_STATUS)
    status = res and res.pValue or 0    

    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_LP_COUNT)
    lpcnt = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_BRANCH_COUNT)
    bncnt = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_MIP_COUNT)
    mipcnt = res and res.pValue or 0    

    res = pModel:getProgressInfo(iLoc,info.LS_DINFO_SUB_PINF)
    pfeas = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_DINFO_CUR_BEST_BOUND)
    bestbnd = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_DINFO_CUR_OBJ)
    pobj = res and res.pValue or 0    

    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_ACTIVE_COUNT)
    accnt = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_STATUS)
    curtime = res and res.pValue or 0    

    szerr = "" --pModel:errmsg(res.ErrorCode) or "N/A"
    printf("\n%6s:%8u %8u %8u %14e %14e %14e %8u %6u %8.2f %10g %s",
    "(NEW)",iter,bncnt,lpcnt+mipcnt,pfeas,bestbnd,pobj,accnt,status,curtime,pX:norm(2),szerr);
    
    retval = 0
    if retval>0 then        
        printf("Warning: cbmip is returning interrupt signal !\n")
    end
    return retval
end

--- General callback function that gets called from various localtions in the Lindo API
-- @param pModel Pointer to the model instance
-- @param iLoc Location code
function cbstd(pModel, iLoc,udata)
    local iter,bncnt,lpcnt,mipcnt,pfeas,bestbnd,pobj,accnt,status,curtime,szerr
    local res
    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_ITER)
    iter = res and res.pValue or 0

    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_STATUS)
    status = res and res.pValue or 0    

    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_LP_COUNT)
    lpcnt = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_BRANCH_COUNT)
    bncnt = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_MIP_COUNT)
    mipcnt = res and res.pValue or 0    

    res = pModel:getProgressInfo(iLoc,info.LS_DINFO_SUB_PINF)
    pfeas = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_DINFO_CUR_BEST_BOUND)
    bestbnd = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_DINFO_CUR_OBJ)
    pobj = res and res.pValue or 0    

    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_ACTIVE_COUNT)
    accnt = res and res.pValue or 0    
    
    res = pModel:getProgressInfo(iLoc,info.LS_IINFO_CUR_STATUS)
    curtime = res and res.pValue or 0    

    szerr = "" -- pModel:errmsg(res.ErrorCode) or "N/A"
    printf("\n%6s:%8u %8u %8u %14e %14e %14e %8u %6u %8.2f %s",
    "(NEW)",iter,bncnt,lpcnt+mipcnt,pfeas,bestbnd,pobj,accnt,status,curtime,szerr);

    return 0
end

--- Pretty options displayer
function print_table_dots(tbl)
    local max_key_length = 0
    local max_value_length = 0
    print()
    printf("Options:\n")
    -- Find the maximum length of the keys and values in the table
    for key, value in pairs(tbl) do
        local key_length = string.len(tostring(key))
        local value_length = string.len(tostring(value))
        if key_length > max_key_length then
            max_key_length = key_length
        end
        if value_length > max_value_length then
            max_value_length = value_length
        end
    end

    -- Print each key-value pair in the table
    for key, value in pairs(tbl) do
        local row = string.format("%-"..max_key_length.."s.........: %s", tostring(key), tostring(value))
        print(row)
    end
    print()
end

--- Display standard usage, applicable to all examples
--@note This function is called by all examples
function print_default_usage()
    print("Options:")
    print("  -h, --help                     Show this help message")
    print("  -s, --solve=solverId           Solve model with 'solverId'")
    print("    , --max                      Set objective sense to maximize (default: minimize)")
    print("  -m, --model=STRING             Specify the model file name")
    print("  -p, --parfile=STRING           Specify the parameter file name")
    print("  -v, --verb=INTEGER             Set print/verbose level")    
    print("    , --cbmip=VALUE              User mip-callback on/off (1/0)")
    print("    , --cblog=VALUE              User log-callback on/off (1/0)")
    print("    , --cbstd=VALUE              User std-callback on/off (1/0)")
    print("    , --gop                      Use gop solver")
    print("    , --rng                      Compute bound ranges analysis")
    print("    , --writeas=EXT              Write model to a file with extension 'EXT'")
    print("  -M, --lindomajor=INTEGER       Lindo api major version to use")
    print("  -I, --lindominor=INTEGER       Lindo api minor version to use")    
    print("    , --seed=INTEGER             Set random number generator 'seed'")
    print()    
end    

require 'alt_getopt'

local long_default = {       
    help = "h",
    model = "m",
    solve = "s",
    parfile = "p",
    verb = "v",
    cbmip = 1,
    cblog = 1,
    cbstd = 1,
    gop = 0,    
    rng = 0,
    writeas = "w",
    lindomajor = 1, 
    lindominor = 1,
    seed = 1,
    max = 0
}
local short_default = "m:hv:w:M:I:p:s:f:"

--- Parses command line options using the alt_getopt library
-- @param arg The command line arguments
-- @param short The short options string
-- @param long The long options table
-- @return A table containing the parsed options
function parse_options(arg,short,long)
    local short = short
    local long = long
    assert(arg)
    assert(short)
    assert(long)
    short = short_default .. short
    -- append defaults to long
    for k,v in pairs(long_default) do
        long[k] = v
    end
    local opts,optind,optarg = alt_getopt.get_ordered_opts(arg, short, long)

    local options = {}
    options.help = false
    options.parfile = nil
    options.has_cbmip = 0
    options.has_cbstd = 0
    options.has_cblog = 1
    options.has_gop   = false
    options.has_rng = false
    options.writeas = nil
    options.lindomajor = 14
    options.lindominor = 0
    options.solve = nil
    options.model_file = nil
    options.input_file = nil
    options.verb = 1
    options.seed = 0
    options.max = false
    options.branlim = nil
    options.ilim = nil
    options.tlim = nil
    options.mipsollim = nil
    options.mipcutoff = nil
    options.mipsym = nil
    options.saveroot = false
    options.loadroot = false
    options.lbigm = 1e5
    options.mipobjthr = nil
    options.ainttol = nil
    options.rinttol = nil
    options.pftol = nil
    options.dftol = nil
    options.aoptol = nil
    options.ainttol = nil
    options.rinttol = nil
    options.ropttol = nil
    options.popttol = nil

    for k,v in pairs(long) do
        if not options[k] then 
            options[k] = nil
        end
    end
    -- read and parse config file if specified
    for i, k in pairs(opts) do
        local v = optarg[i] 
        --print(i,k,v)
        if k=="help" or k=="h" then options.help=true    
        elseif k=="model" or k=="m" then options.model_file = v   
        elseif k=="file" or k=="f" then options.input_file = v
        elseif k=="solve" or k=="s" then options.solve = tonumber(v)   
        elseif k=="parfile" or k=="p" then options.parfile = v   
        elseif k=="verb" or k=="v" then options.verb = tonumber(v)
        elseif k=="cbmip" then options.has_cbmip=tonumber(v)
        elseif k=="cbstd" then options.has_cbstd=tonumber(v)
        elseif k=="cblog" then options.has_cblog=tonumber(v)
        elseif k=="gop" then options.has_gop=true
        elseif k=="ranges" then options.has_rng=true
        elseif k=="writeas" or k=="w" then options.writeas=v
        elseif k=="lindomajor" or k=="M" then options.lindomajor=tonumber(v)
        elseif k=="lindominor" or k=="I" then options.lindominor=tonumber(v)
        elseif k=="seed" then options.seed=tonumber(v)
        elseif k=="max" then options.max=true        
        elseif k=="ilim" then options.ilim=tonumber(v)
        elseif k=="tlim" then options.tlim=tonumber(v)
        elseif k=="branlim" then options.branlim=tonumber(v)
        elseif k=="mipsollim" then options.mipsollim=tonumber(v)
        elseif k=="mipcutoff" then options.mipcutoff=tonumber(v)
        elseif k=="mipsym" then options.mipsym=tonumber(v)
        elseif k=="saveroot" then options.saveroot=true
        elseif k=="loadroot" then options.loadroot=true
        elseif k=="lbigm" then options.lbigm=tonumber(v)
        elseif k=="mipobjthr" then options.mipobjthr=tonumber(v)
        elseif k=="ainttol" then options.ainttol=tonumber(v)
        elseif k=="rinttol" then options.rinttol=tonumber(v)
        elseif k == "pftol" then options.pftol = tonumber(v)
        elseif k == "dftol" then options.dftol = tonumber(v)
        elseif k == "aoptol" then options.aoptol = tonumber(v)
        elseif k == "ropttol" then options.ropttol = tonumber(v)
        elseif k == "popttol" then options.popttol = tonumber(v)
        end        
    end
    if options.seed==0 then
        options.seed = os.time()
        printf("Initialized with seed %d (time)\n",options.seed)
    else
        printf("Initialized with seed %d\n",options.seed)
    end
    math.randomseed(options.seed)     
    if options.verb>2 then 
        print_table_dots(options)
        print_table_dots(opts)
        print_table_dots(optarg)
    end
    
    return options, opts, optarg
end
