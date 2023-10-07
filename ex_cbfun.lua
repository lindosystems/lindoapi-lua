local szPLATFORM="win32x86"
package.path = package.path..";./?.lua;./lib/" .. szPLATFORM .. "/systree/share/lua/5.1/?.lua;./lib/" .. szPLATFORM .. "/systree/share/lua/5.1/?/init.lua"

function myprintlog(pModel, str)
    printf("%s", str)
    if string.len(str)<-2 then
		io.read()
	end
end

function cbmip(pModel, dobj, pX)
    printf("new MIP solution: mipobj: %g, |X|=%g\n", dobj, pX:norm())
    local retval = 0
    retval = 0
    if retval>0 then        
        printf("Warning: cbmip is returning interrupt signal !\n")
    end
    return retval
end

function cbstd(pModel, iLoc)
    printf("loc: %d\n", iLoc)
    return 0
end

function print_default_usage()
    print("Options:")
    print("  -h, --help                     Show this help message")
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
    model = "m",
    parfile = "p",
    help = "h",
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
}
local short_default = "m:hv:w:M:I:p:"

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

    options = {}
    options.parfile = nil
    options.has_cbmip = 0
    options.has_cbstd = 0
    options.has_cblog = 1
    options.has_gop   = false
    options.has_rng = false
    options.writeas = nil
    options.lindomajor = 14
    options.lindominor = 0
    options.model_file = nil
    options.verb = 1
    options.seed = 0
    -- read and parse config file if specified
    for i, k in pairs(opts) do
        local v = optarg[i] 
        --print(i,k,v)
        if k=="help" or k=="h" then usage(); os.exit(1); end    
        if k=="model" or k=="m" then options.model_file = v end   
        if k=="parfile" or k=="p" then options.parfile = v end   
        if k=="verb" or k=="v" then options.verb = tonumber(v) end
        if k=="cbmip" then options.has_cbmip=tonumber(v) end
        if k=="cbstd" then options.has_cbstd=tonumber(v) end
        if k=="cblog" then options.has_cblog=tonumber(v) end
        if k=="gop" then options.has_gop=true end
        if k=="rng" then options.has_rng=true end
        if k=="writeas" or k=="w" then options.writeas=v end
        if k=="lindomajor" or k=="M" then options.lindomajor=tonumber(v) end
        if k=="lindominor" or k=="I" then options.lindominor=tonumber(v) end
        if k=="seed" then options.seed=tonumber(v) end
    end
    if options.seed==0 then
        options.seed = os.time()
        printf("Initialized with seed %d (time)\n",options.seed)
    else
        printf("Initialized with seed %d\n",options.seed)
    end
    math.randomseed(options.seed)     
    return options, opts, optarg
end
