-- File: ex_cbfun.lua
-- Description: Example of using callback functions with the Lindo API
-- Author: [Your Name Here]
-- Date: [Date Here]
package.path = package.path..";./?.lua;./share/lua/5.1/?.lua;./share/lua/5.1/?/init.lua"
package.cpath = package.cpath..";./lib/win32x86/systree/lib/lua/5.1/?.dll;./lib/win32x86/systree/lib/lua/5.1/?.so;./lib/win32x86/systree/lib/lua/5.1/?.dylib"

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
function cbmip(pModel, dobj, pX)
    printf("new MIP solution: mipobj: %g, |X|=%g\n", dobj, pX:norm())
    local retval = 0
    retval = 0
    if retval>0 then        
        printf("Warning: cbmip is returning interrupt signal !\n")
    end
    return retval
end

--- General callback function that gets called from various localtions in the Lindo API
-- @param pModel Pointer to the model instance
-- @param iLoc Location code
function cbstd(pModel, iLoc)
    printf("loc: %d\n", iLoc)
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
    for k,v in pairs(long) do
        if not options[k] then 
            options[k] = nil
        end
    end
    -- read and parse config file if specified
    for i, k in pairs(opts) do
        local v = optarg[i] 
        --print(i,k,v)
        if k=="help" or k=="h" then options.help=true end    
        if k=="model" or k=="m" then options.model_file = v end   
        if k=="file" or k=="f" then options.input_file = v end
        if k=="solve" or k=="s" then options.solve = tonumber(v) end   
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
    if options.verb>2 then 
        print_table_dots(options)
        print_table_dots(opts)
        print_table_dots(optarg)
    end
    
    return options, opts, optarg
end
