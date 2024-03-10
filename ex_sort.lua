#!/usr/bin/env lslua
-- File: ex_sort.lua
-- Description: Example of using the Lindo API to sort a vector
--              over an affine transformation
-- Remarks:
--   - Solving as an MILP is difficult
--   - Solving as an NLP is easy
-- 
-- Author: mka
-- Date: 2019-07-01

local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local GNUPLOT = 'gnuplot -p '
-- config
require 'ex_cbfun'
require 'llindo_usage'
local solver
local options, opts, optarg

---
--
function gen_sort(options)
    local ymd, hms = xta:datenow(), xta:timenow()
    local jsec = xta:jsec(ymd, hms)
    printf("%06d-%06d jsec:%d\n", ymd, hms, jsec)
    local res
    local pModel = solver:mpmodel()
    pModel.logfun = myprintlog

    pModel:setMIPCallback(cbmip)
    -- pModel:setCallback(cbstd)

    local m, n
    m = options.mdim or 10
    n = options.ndim or 4    
    local model_file = options.model_file
    if not model_file then
        local tmppath = probdir() .. sprintf("/minlp/mpx")
        if not paths.dirp(tmppath) then
            tmppath = "/tmp/minlp/mpx"
            if not paths.dirp(tmppath) then
                paths.mkdir(tmppath)
                printf("Created directory %s\n", tmppath)
            end
        end
        model_file = sprintf("%s/sort%dx%d.mpx", tmppath, m, n)    
    end
    local R = xta:rtable(n, m, "uniform(0,1)", 1031)
    local p = xta:rtable(m, 1, "uniform(0,1)", 1031)
    local w0 = xta:rtable(n, 1, "uniform(0,1)", 1031)
    local sbuf = stringBuffer()
    local bigM = 1e2
    addString(sbuf, sprintf("minimize z;\n"))
    addString(sbuf, sprintf("subject to\n"))
    addString(sbuf, sprintf(""))
    -- z = p'.x + |w-w0|_inf
    for i = 1, m do
        local term
        local c = "+"
        if i == m then
            c = " + "
        end
        term = sprintf("%g * x_%d %s ", p[i][1], i, c)
        addString(sbuf, sprintf("%s", term))
        if i % 5 == 0 then
            addString(sbuf, sprintf("\n"))
        end
    end
    for i = 1, n do
        local term
        local c = "+"
        if i == n then
            c = ""
        end
        term = sprintf("%g * (dp%d + dn%d) %s ", bigM, i, i, c)
        addString(sbuf, sprintf("%s", term))
        if i % 5 == 0 then
            addString(sbuf, sprintf("\n"))
        end
    end
    addString(sbuf, sprintf(" - z = 0;\n"))
    -- R'.w = x 
    for i = 1, m do
        local line = ""
        for j = 1, n do
            local term
            local c = "+"
            if j == n then
                c = ""
            end
            term = sprintf("%g * w_%d %s ", R[j][i], j, c)
            line = line .. term
            if j % 5 == 0 then
                line = line .. "\n"
            end
        end
        line = line .. sprintf(" - x_%d = 0;", i)
        addString(sbuf, sprintf("%s\n", line))
    end
    -- P.x = s
    for i = 1, m do
        local line = ""
        for j = 1, m do
            local term
            local c = "+"
            if j == m then
                c = ""
            end
            term = sprintf("P_%d_%d * x_%d %s ", i, j, j, c)
            line = line .. term
            if j % 5 == 0 then
                line = line .. "\n"
            end
        end
        line = line .. sprintf(" - s_%d = 0;", i)
        addString(sbuf, sprintf("%s\n", line))
    end
    -- s_i - s_{i+1} >= 0
    for i = 1, m - 1 do
        local line = ""
        line = line .. sprintf("s_%d - s_%d >= 0;", i, i + 1)
        addString(sbuf, sprintf("%s\n", line))
    end
    -- P.e = 1
    for i = 1, m do
        local line = ""
        for j = 1, m do
            local term
            local c = "+"
            if j == m then
                c = ""
            end
            term = sprintf("P_%d_%d %s ", i, j, c)
            line = line .. term
            if j % 5 == 0 then
                line = line .. "\n"
            end
        end
        line = line .. sprintf(" = 1;")
        addString(sbuf, sprintf("%s\n", line))
    end
    -- P'.e = 1
    for i = 1, m do
        local line = ""
        for j = 1, m do
            local term
            local c = "+"
            if j == m then
                c = ""
            end
            term = sprintf("P_%d_%d %s ", j, i, c)
            line = line .. term
            if j % 5 == 0 then
                line = line .. "\n"
            end
        end
        line = line .. sprintf(" = 1;")
        addString(sbuf, sprintf("%s\n", line))
    end
    -- w <= wLinf
    for i = 1, n do
        local line = ""
        line = line .. sprintf("w_%d - wLinf <=0;", i)
        addString(sbuf, sprintf("%s\n", line))
    end
    -- w - w0 = dp - dn
    for i = 1, n do
        local line = ""
        line = line .. sprintf("w_%d - %g = dp%d - dn%d;", i, w0[i][1], i, i)
        addString(sbuf, sprintf("%s\n", line))
    end

    addString(sbuf, sprintf("BOUNDS\n"))
    addString(sbuf, sprintf("wLinf <= 1;\n"))
    for i = 1, m do
        addString(sbuf, sprintf("-inf <= s_%d <= +inf;\n", i))
        addString(sbuf, sprintf("-inf <= x_%d <= +inf;\n", i))
    end
    for i = 1, n do
        -- addString(sbuf,sprintf("-inf <= w_%d <= +inf;\n",i))
    end
    addString(sbuf, sprintf("BINARY\n"))
    for i = 1, m do
        local line = ""
        for j = 1, m do
            local term
            term = sprintf("P_%d_%d ", i, j)
            line = line .. term
            if j % 5 == 0 then
                line = line .. "\n"
            end
        end
        addString(sbuf, sprintf("%s\n", line))
    end

    addString(sbuf, sprintf("END\n"))
    local str = toString(sbuf)
    pModel:readMPXStream(str)

    if model_file then
        fwrite(model_file, "w", str) 
        glogger.info("Wrote model to %s\n", model_file)    
    end    

    if options.solve then        
        res = pModel:solveGOP()
        print_table3(res)
        -- xassert(res)

        if res.ErrorCode == 0 then
            printf("pobj: %.7f\n", pModel.pobj and pModel.pobj or pModel.mipobj and pModel.mipobj or pModel.gopobj and
                pModel.gopobj or -99)
            printf("dobj: %.7f\n", pModel.dobj and pModel.dobj or pModel.mipbnd and pModel.mipbnd or pModel.gopbnd and
                pModel.gopbnd or -99)
        end
    end
    
    if options.writeas then
        assert(options.writeas=='mpi',"Only MPI format is supported")
        options.model_file = changeFileExtension(model_file,".mpi")
        pModel:write(options)        
        glogger.info("Wrote model to %s\n", options.model_file)
    end

    pModel:dispose()
    print(solver)
end

-- parse app specific options
function app_options(options,k,v)
    if k=="ndim" then options.ndim=tonumber(v)
    elseif k=="mdim" then options.mdim=tonumber(v) 
    else
    	printf("Unknown option '%s'\n",k)
    end
end

-- Usage function
local function usage(help_)
    print()
    print("Sort a vector 'x' via MILP.")
    print()
    print("Usage: lslua ex_sort.lua [options]")    
    if help_ then print_default_usage() end
    print()
    print("    , --solve=<INTEGER>          Solve last state of model")
    print("    , --ndim                     Number of columns")
    print("    , --mdim                     Number of rows")
	print("")
	if not help_ then print_help_option() end        	
    print("Example:")
    print("\t lslua ex_sort.lua --ndim=10 --mdim=2 [-m /path/to/model_file.mpx [options]]")    
    print()    
end

---
-- Parse command line arguments
local long={
    solve = 0,
    ndim = 1,
    mdim = 1
}
local short = "n:m:"
options, opts, optarg = parse_options(arg,short,long)
--print_table3(options)

if options.help then
	usage(true)
	return
end

if not options.ndim then
	usage(options.help)
	return
end	

xta.logfun = printline
xta.loglevel = 2

options.verb = math.max(options.verb and options.verb or 1, 2)
solver = xta:solver()
assert(solver,"\nError: cannot create a solver instance\n")
apply_solver_options(solver,options)

gen_sort(options)
printf("Disposing %s\n",tostring(solver))  
solver:dispose()
