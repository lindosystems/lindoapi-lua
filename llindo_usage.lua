#!/usr/bin/env lua

function cygpath_w(ls_prob)
    -- Check if the environment variable exists
    if not ls_prob then
        print("The input argument is nil.")
        return nil
    end

    -- Prepare the command to execute
    local command = "cygpath -w " .. ls_prob

    -- Execute the command using io.popen, which runs the command and returns a file handle
    local handle = io.popen(command)
    if not handle then
        print("Failed to execute the command.")
        return nil
    end

    -- Read the command output
    local output = handle:read("*a")

    -- Close the file handle
    handle:close()

    -- Trim any trailing whitespace or newlines
    output = output:gsub("%s+$", "")
    output = output:gsub("\\", "/")

    -- Return the command output
    return output
end

--- Get the version from the license file
function probdir()
    local dir=os.getenv("LS_PROB_PATH")
    if not dir or (dir and paths.dirp(dir)) then
      dir = "/home/mka/prob"
    end    
    if xta.platformid==xta.const.win32x86 or xta.platformid==xta.const.win64x86 then                           
        dir = cygpath_w(dir)
    end        
    return dir
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

--- Notify all applications the -h option to see more options
function print_help_option()
    print("  -h, --help                    Show extended options list")
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
    print("  -f, --input_file=STRING        Specify file to process")    
    print("  -v, --verb=INTEGER             Set print/verbose level")    
    print("    , --print=INTEGER            Set print/verbose level for solver")
    print("    , --cbmip=VALUE              User mip-callback on/off (1/0), 2: log lines")
    print("    , --cblog=VALUE              User log-callback on/off (1/0)")
    print("    , --cbstd=VALUE              User std-callback on/off (1/0)")
    print("    , --gop                      Use gop solver")
    print("    , --multis=VALUE             Use multistart solver with 'VALUE' multi starts")
    print("    , --ranges=STRING            Compute range analysis, possible values are 'bounds', 'obj', etc..")
    print("    , --writeas=EXT              Write model to a file with extension 'EXT'")
    print("    , --lsversion=x.y            Lindo api <major.minor> version to use")
    print("    , --seed=INTEGER             Set random number generator 'seed'")
    print("    , --max                      Set objective sense to maximize (default: minimize)")
    printf("   , --llogger=STRING           Set logger value (default: %s), possible values are 'debug', 'info', 'warn', 'critc','error', 'fatal'\n",'info')
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
    print("    , --pprice=<value>           Set pprice value")
    print("    , --dprice=<value>           Set dprice value")
    print("    , --lp                       Solve as LP")
    print("    , --prtfg=<value>            Set prtfg value")
    print("    , --method=<value>           Set method value")
    print("")
    print("    , --iis_method=<value>       Set IIS method value")
    print("    , --iis_norm=<value>         Set IIS norm value")
end    

require 'alt_getopt'

local long_default = {       
    help = "h",
    model = "m",
    solve = "s",
    xsolver = "x",
    xdll = 1,
    parfile = "p",
    input_file = "f",
    verb = "v",
    print = 1,
    cbmip = 1,
    cblog = 1,
    cbstd = 1,
    gop = 0,    
    ranges = 1,
    writeas = "w",
    lsversion = 1,
    seed = 1,
    max = 0,
    llogger = 1,
    multis = 1,
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
    strongb = 1,
    pprice = 1,
    dprice = 1,
    lp=0,
    method = 1,
    qa = 1,
    sol = 0,
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
    local major_lic, minor_lic = get_version_from_licfile(os.getenv("LINDOAPI_LICENSE_FILE"))
    if not major_lic then
        major_lic = 15
        minor_lic = 0
        printf("Warning: Could not determine Lindo API version from license file, using default version %d\n",major_lic)
    end
    local options = {}
    options.help = false
    options.parfile = nil
    options.cbmip = 0
    options.cbstd = 0
    options.cblog = 1
    options.has_gop   = false
    options.ranges = nil
    options.writeas = nil
    options.lsversion = sprintf("%s.%s",major_lic,minor_lic) -- start with the <major.minor> version from the license file
    options.solve = nil
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
    options.pprice = nil
    options.dprice = nil
    options.lp = nil
    options.method = nil
    options.iis_method = nil
    options.iis_norm = nil
    options.iis_level = nil
    options.qa = nil
    options.multis = nil
    options.llogger = 'info'
    options.sol = nil
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
        elseif k=="writeas" or k=="w" then options.writeas=v
        elseif k=="lsversion" then options.lsversion=v -- major version
        elseif k=="solve" or k=="s" then options.solve = tonumber(v)   
        elseif k=="parfile" or k=="p" then options.parfile = v   
        elseif k=="verb" or k=="v" then options.verb = tonumber(v)
        elseif k=="xsolver" or k=="x" then options.xsolver=tonumber(v)            
        elseif k=="ktrymod" then options.ktrymod = tonumber(v)
        elseif k=="ktryenv" then options.ktryenv = tonumber(v)
        elseif k=="ktrysolv" then options.ktrysolv = tonumber(v)
        elseif k=="ktrylogf" then options.ktrylogf = v
        elseif k=="print" then options.print = tonumber(v)
        elseif k=="cbmip" then options.cbmip=tonumber(v)
        elseif k=="cbstd" then options.cbstd=tonumber(v)
        elseif k=="cblog" then options.cblog=tonumber(v)
        elseif k=="gop" then options.has_gop=true
        elseif k=="multis" then options.multis=tonumber(v)
        elseif k=="ranges" then options.ranges=v
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
        elseif k=="pftol" then options.pftol = tonumber(v)
        elseif k=="dftol" then options.dftol = tonumber(v)
        elseif k=="aoptol" then options.aoptol = tonumber(v)
        elseif k=="ropttol" then options.ropttol = tonumber(v)
        elseif k=="popttol" then options.popttol = tonumber(v)
        elseif k=="pivtol" then options.pivtol = tonumber(v) 
        elseif k=="xdll" then options.xdll=v
        elseif k=="pre_root" then options.pre_root=tonumber(v)
        elseif k=="pre_lp" then options.pre_lp=tonumber(v)
        elseif k=="heulevel" then options.heulevel=tonumber(v)  
        elseif k=="prtfg" then options.prtfg=tonumber(v)          
        elseif k=="strongb" then options.strongb=tonumber(v)
        elseif k=="pprice" then options.pprice=tonumber(v)
        elseif k=="dprice" then options.dprice=tonumber(v)
        elseif k=="lp" then options.lp=true
        elseif k=="method" then options.method=tonumber(v)                    
        elseif k=="llogger" then options.llogger=v
        elseif k=="iis_method" then options.iis_method=tonumber(v)
        elseif k=="iis_norm" then options.iis_norm=tonumber(v)              
        elseif k=="iis_level" then options.iis_level=tonumber(v)
        elseif k=="qa" then options.qa=v
        elseif k=="sol" then options.sol=true
        else            
            app_options(options,k,v)
        end        
    end
    if options.seed==0 then
        options.seed = os.time()
        printf("Initialized with seed %d (time)\n",options.seed)
        math.randomseed(options.seed)
    else
        printf("Initialized with seed %d\n",options.seed)
        math.randomseed(options.seed)
    end

    if options.llogger then
        glogger.level =options.llogger
    end

    if is_cygwin() then
        options.model_file = cygpath_w(options.model_file)
        options.parfile = cygpath_w(options.parfile)
        options.input_file = cygpath_w(options.input_file)
    end

    if not options.solve then
        options.solve = 1
        printf("No --solve=<integer> option specified, defaulting to solve=1\n")
    end

    if options.model_file then
        options.model_path = paths.dirname(options.model_file)
    end
    major_lic, minor_lic = unpack(options.lsversion:splitz("."))    
    options.major_lic,options.minor_lic = tonumber(major_lic), tonumber(minor_lic)
    -- New solver instance
    xta:setsolverdll("",8);
    xta:setlindodll(options.major_lic,options.minor_lic)
    printf("Configured for Lindo API %d.%d\n",options.major_lic,options.minor_lic)

    math.randomseed(options.seed)     
    if options.verb>2 then 
        print_table_dots(options)
        print_table_dots(opts)
        print_table_dots(optarg)
    end
    
    return options, opts, optarg
end

--- Get xuserdll path
-- @param xuserdll The xuserdll path passed by user at command line
-- @return The xuserdll path to be used
function get_xuserdll_path(xuserdll)    
    if not xuserdll:find(".dll") and not xuserdll:find(".so") and not xuserdll:find(".dylib") then
        -- if no extension is given, assume it is a dll
        local tag = ""
        if raw_os_arch:match"64" then
            tag = "64_"
        end
        local s
        if not os.getenv(sprintf("LINGO%s21_HOME",tag)) then
            if not os.getenv(sprintf("LINGO%s20_HOME",tag)) then
                if not os.getenv(sprintf("LINGO%s19_HOME",tag)) then
                    if options.model_path then
                        s = options.model_path -- use model path
                    else
                        s = "." -- use current directory as a last resort
                    end
                else
                    s = os.getenv(sprintf("LINGO%s19_HOME",tag)) 
                end
            else
                s = os.getenv(sprintf("LINGO%s20_HOME",tag)) 
            end
        else
            s = os.getenv(sprintf("LINGO%s21_HOME",tag))
        end
        xuserdll = sprintf("%s/MyUser.dll",s)
    end
    return xuserdll
end

--- Apply solver options
-- @param solver The solver instance
-- @param options The options table
function apply_solver_options(solver, options)
    local res
    options.raw_os_name, options.raw_os_arch, options.raw_require_name, options.uname =  getos_name_arch() 
    if options.xuserdll then
        local xuserdll = get_xuserdll_path(options.xuserdll)
        res = solver:setXSolverLibrary(94,xuserdll)
        solver:xassert(res)
    end

    if options.xsolver>0 then
        local xdll = options.xdll 
        res = solver:setXSolverLibrary(options.xsolver,xdll)
        solver:xassert(res)
        glogger.info("Set external solver %d to %s\n",options.xsolver,xdll)
    end   
    
    return
end
