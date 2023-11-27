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

--- Compute SHA1/2 hash of a string
---@param str String to be hashed
function SHA2(str) 
    local sha2_
    if 2>1 then
        sha2_ = xta:digest(str)
    else
        sha2_ = xta:sha(str,256)        
    end 
    if 0>1 and string.len(str)<128 then
        printf("DIGEST: '%s' '%s'\n",sha2_,str)       
    end
    return sha2_
end    

--- Callback function for logging messages from  with respect to Lindo API
-- @param pModel Pointer to the model instance
-- @param str String to be printed
function myprintlog(pModel, str)
    if str:find("Processed") then
        str="\nProcessed ..."
    end
    printf("%s", str)
    if string.len(str)<-2 then
		io.read()
	end
    if pModel.utable.ktrylogfp then
        fprintf(pModel.utable.ktrylogfp,"%s",str)
        if not pModel.utable.ktrylogsha then
            pModel.utable.ktrylogsha = ""
        end
        pModel.utable.ktrylogsha = SHA2(pModel.utable.ktrylogsha..str)
    end
end

--- MIP Callback function progress line getter
function lsi_pdline(p)
    local sline = sprintf("%6s:%8u %8u %8u %14e %14e %14e %8u %6u",
    "(NEW)",p.iter,p.bncnt,p.lpcnt+p.mipcnt,p.pfeas,p.bestbnd,p.pobj,p.accnt,p.status);
    return sline
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

    local p = pModel:getProgressData()
    local normx = pX:norm(2)
    szerr = "" --pModel:errmsg(res.ErrorCode) or "N/A"
    local line = lsi_pdline(p,normx,szerr)
    printf("\n%s %8.2f %10g %s",line,p.curtime,normx,szerr) 
    if pModel.utable.ktrylogfp then
        local str = sprintf("\n%s %8.2f %10g %s",line,-99,normx,szerr)
        fprintf(pModel.utable.ktrylogfp,"%s",str) 
        if not pModel.utable.ktrylogsha then
            pModel.utable.ktrylogsha = ""
        end
        pModel.utable.ktrylogsha = SHA2(pModel.utable.ktrylogsha..str)
    end    

    if pModel.utable.lines==nil then
        pModel.utable.lines = {}
    end
    if line ~= pModel.utable.lines[#pModel.utable.lines] then
        pModel.utable.lines[#pModel.utable.lines+1] = line
    end
    
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
    
    res = pModel:getProgressInfo(iLoc,info.LS_DINFO_CUR_TIME)
    curtime = res and res.pValue or 0    

    szerr = "" -- pModel:errmsg(res.ErrorCode) or "N/A"
    printf("\n%6s:%8u %8u %8u %14e %14e %14e %8u %6u %8.2f %s",
    "(CB)",iter,bncnt,lpcnt+mipcnt,pfeas,bestbnd,pobj,accnt,status,curtime,szerr);

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
    print("  -x, --xsolver=INTEGER          Set external solver to 'INTEGER' (default: 0)")
    print("    , --ktrymod=INTEGER          Set ktrymod to 'INTEGER' (default: 1)")
    print("    , --ktryenv=INTEGER          Set ktryenv to 'INTEGER' (default: 1)")
    print("    , --ktrysolv=INTEGER         Set ktrysolv to 'INTEGER' (default: 1)")
    print("    , --ktrylogf=STRING          Set logfile file basename to 'STRING' (default: nil)")
    print("    , --xdll=STRING              Set external solver dll to 'STRING' (default: nil)")
    print("    , --max                      Set objective sense to maximize (default: minimize)")
    print("  -m, --model=STRING             Specify the model file name")
    print("  -p, --parfile=STRING           Specify the parameter file name")
    print("  -v, --verb=INTEGER             Set print/verbose level")    
    print("    , --print=INTEGER            Set print/verbose level for solver")
    print("    , --cbmip=VALUE              User mip-callback on/off (1/0)")
    print("    , --cblog=VALUE              User log-callback on/off (1/0)")
    print("    , --cbstd=VALUE              User std-callback on/off (1/0)")
    print("    , --gop                      Use gop solver")
    print("    , --rng                      Compute bound ranges analysis")
    print("    , --writeas=EXT              Write model to a file with extension 'EXT'")
    print("  -M, --lindomajor=INTEGER       Lindo api major version to use")
    print("  -I, --lindominor=INTEGER       Lindo api minor version to use")    
    print("    , --seed=INTEGER             Set random number generator 'seed'")
    print("    , --max                      Set objective sense to maximize (default: minimize)")
    print()    
    -- Additional options    
    print("      --ilim=<value>             Set ilim value")
    print("    , --tlim=<value>             Set tlim value")
    print("    , --branlim=<value>          Set branlim value")
    print("    , --mipsollim=<value>        Set mipsollim value")
    print("    , --mipcutoff=<value>        Set mipcutoff value")
    print("    , --mipsym=<value>           Set mipsym value")
    print("    , --saveroot                 Use saveroot")
    print("    , --loadroot                 Use loadroot")
    print("    , --lbigm=<value>            Set lbigm value")
    print("    , --mipobjthr=<value>        Set mipobjthr value")
    print("    , --ainttol=<value>          Set ainttol value")
    print("    , --rinttol=<value>          Set rinttol value")
    print("    , --pftol=<value>            Set pftol value")
    print("    , --dftol=<value>            Set dftol value")
    print("    , --aoptol=<value>           Set aoptol value")
    print("    , --ropttol=<value>          Set ropttol value")
    print("    , --popttol=<value>          Set popttol value")    
    print("    , --pivttol=<value>          Set pivtol value")    
    print("    , --pre_root=<value>         Set pre_root value")
    print("    , --pre_lp=<value>           Set pre_lp value")
    print("    , --heulevel=<value>         Set heulevel value")
    print("    , --strongb=<value>          Set strong-branch level")
end    

require 'alt_getopt'

local long_default = {       
    help = "h",
    model = "m",
    solve = "s",
    xsolver = "x",
    xdll = 1,
    parfile = "p",
    verb = "v",
    print = 1,
    cbmip = 1,
    cblog = 1,
    cbstd = 1,
    gop = 0,    
    rng = 0,
    writeas = "w",
    lindomajor = 1, 
    lindominor = 1,
    seed = 1,
    max = 0,
    -- Additional options
    ilim = 1,
    tlim = 1,
    branlim = 1,
    mipsollim = 1,
    mipcutoff = 1,
    mipsym = 1,
    saveroot = 0,
    loadroot = 0,
    lbigm = 1,
    mipobjthr = 1,
    ainttol = 1,
    rinttol = 1,
    pftol = 1,
    dftol = 1,
    aoptol = 1,
    ropttol = 1,
    popttol = 1,
    pivtol = 1,
    pre_root = 1,
    pre_lp = 1,    
    ktrymod = 1,
    ktryenv = 1,
    ktrysolv = 1,
    heulevel = 1,
    prtfg = 1,
    ktrylogf = 1,
    strongb = 1
}
local short_default = "m:hv:w:M:I:p:s:f:x:"

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
    options.solve = 1
    options.xsolver = 0
    options.xdll = nil
    options.model_file = nil
    options.input_file = nil
    options.verb = 1
    options.print = nil
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
    options.pivotol = nil
    options.pre_root = nil
    options.pre_lp = nil
    options.ktrymod = 1
    options.ktryenv = 1
    options.ktrysolv = 1
    options.heulevel = nil
    options.prtfg = nil
    options.ktrylogf = nil
    options.strongb = nil
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
        elseif k=="ktrymod" then options.ktrymod = tonumber(v)
        elseif k=="ktryenv" then options.ktryenv = tonumber(v)
        elseif k=="ktrysolv" then options.ktrysolv = tonumber(v)
        elseif k=="ktrylogf" then options.ktrylogf = v
        elseif k=="solve" or k=="s" then options.solve = tonumber(v)   
        elseif k=="parfile" or k=="p" then options.parfile = v   
        elseif k=="verb" or k=="v" then options.verb = tonumber(v)
        elseif k=="print" then options.print = tonumber(v)
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
        elseif k == "pivtol" then options.pivtol = tonumber(v) 
        elseif k=="xsolver" or k=="x" then options.xsolver=tonumber(v)
        elseif k=="xdll" then options.xdll=v
        elseif k=="pre_root" then options.pre_root=tonumber(v)
        elseif k=="pre_lp" then options.pre_lp=tonumber(v)
        elseif k=="heulevel" then options.heulevel=tonumber(v)  
        elseif k=="prtfg" then options.prtfg=tonumber(v)          
        elseif k=="strongb" then options.strongb=tonumber(v)
        else
            printf("Unknown option '%s'\n",k)
            options.help=true
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
