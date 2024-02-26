#!/usr/bin/env lslua
-- File: ex_cluster.lua
-- Description: Cluster analysis of input file using Self-organizing map
-- Author: mka
-- Date: 2019-07-01
-- $Id: ex_cluster.lua 570 2015-10-03 19:32:31Z lindo $

local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local GNUPLOT = 'gnuplot -p '
-- config
require 'ex_cbfun'
require 'llindo_usage'
ModuleName='ex_cluster.lua'

local options, opts, optarg

--- 
--  Display som border
-- @param nx
function dispsomborder(nx)
    local width = options and options.somboxwidth or 12
    for i = 1, nx do
        printf("+" .. repchar('-', width))
        if i == nx then
            printf("+")
        end
    end
end


--- Display som box
---@param nx any
---@param viewj any
---@param NLINES any
function dispsombox(nx, viewj, NLINES)
    local width = options and options.somboxwidth or 12
    assert(nx)
    assert(NLINES)
    for k = 1, NLINES do
        printf("\n")
        for i = 1, nx do
            if k > viewj[i].len then
                printf("|" .. repchar(' ', width))
            else
                local fmt
                fmt = sprintf("|%%+%ds", width)
                -- fmt = "|%-8s"
                printf(fmt, viewj[i][k])
            end
            if i == nx then
                printf("|")
            end
        end
    end
    printf("\n")
end

--- Get som view
---@param SomMap any
---@param nx any
---@param ny any
---@param Labels any
function getsomview(SomMap, nx, ny, Labels)
    local view = {}
    for j = 1, ny do
        view[j] = {}
        for i = 1, nx do
            view[j][i] = {}
            view[j][i].len = 0
        end
    end
    local i, j
    view.maxlen = 0
    for k = 1, SomMap.nrows do
        if SomMap["xmap"] then
            j = SomMap["ymap"][k] + 1
            i = SomMap["xmap"][k] + 1
        end
        if Labels and Labels[k] and Labels[k][1] then
            table.insert(view[j][i], Labels[k][1])
        elseif Labels and Labels[k] then
            table.insert(view[j][i], Labels[k])
        else
            table.insert(view[j][i], sprintf("Item%d", k))
        end
        view[j][i].len = view[j][i].len + 1
        view.maxlen = math.max(view.maxlen, view[j][i].len)
    end
    -- print_table3(view)
    return view
end

--- Display som hexagon centers
---@param fileHexagon any
---@param fileSomSammon any
---@param nx any
---@param ny any
---@param verb any
function dispsomhexacenters(fileHexagon, fileSomSammon, nx, ny, verb)
    local fileHexagon = fileHexagon or './gnuplot/hexagon.dat'
    local fileSomSammon = fileSomSammon or options.outpath .. '/somsammon.csv'
    local verb = verb or 1
    local v1 = verb > 0
    local v2 = verb > 1

    --->>
    glogger.info("Reading SomSammon from '%s'\n", fileSomSammon)
    local SomSammon = xta:dlmread(fileSomSammon, ',')
    SomSammon.name = sprintf("SammonMap%dx%d", nx, ny)
    local colname = SomSammon:at(1).name
    SomSammon:delete(colname)
    if verb > 2 then
        SomSammon:print()
    end
    assert(SomSammon, "\nError: dlmread failed " .. fileSomSammon)
    xta:xassert()
    assert(SomSammon.nrows == nx * ny, sprintf("Sammon.nrows:%d ~= %dx%d\n", SomSammon.nrows, nx, ny))
    local r = SomSammon[1]
    local g = SomSammon[2]
    local b = SomSammon[3]
    if r.type == 'string' or g and g.type == 'string' then
        SomSammon:print()
        printf("Error: Sammon map has invalid data")
        return
    end

    --->>  
    glogger.info("Writing hexagon to '%s'\n", fileHexagon)
    local stepx = 1
    local stepy = stepx * math.sqrt(3) / 2
    local radius = stepx / math.sqrt(3)
    local height = (ny - 1) * stepy + 2 * radius
    local x0 = stepx
    local y0 = radius + 2 * stepy * ny
    local fp = io.open(fileHexagon, "w")
    if not fp then
        printf("\nWarning: cannot create file '%s'\n", fileHexagon)
        return
    end
    if fp then
        fprintf(fp, "#hexagon centers\n")
        fprintf(fp, "#stepx = %g, stepy=%g, radius=%g, height=%g\n", stepx, stepy, radius, height)
    end

    local K1, K2
    -- K1 = 2.56; K2 = 2.56^2
    K1 = 1.0;
    K2 = 1.0;
    for j = 1, ny do
        for i = 1, nx do
            local k = i + nx * (j - 1)
            local rgb = r[k]
            if (g) then
                rgb = rgb + K1 * g[k]
            end
            if (b) then
                rgb = rgb + K2 * b[k]
            end
            local xc = x0 + (i - 1) * 2 * stepx - (j % 2) * stepx
            local yc = y0 - (j - 1) * 2 * stepy
            fprintf(fp, "%10.5f %10.5f %10.5f\n", xc, yc, rgb)
        end
    end
    fprintf(fp, "\n")
    glogger.info2("\n")
    glogger.info2("Written hexagon centers to %s\n", fileHexagon)
    io.close(fp)

    --->>

    if options.plotMode > 0 then
        os.execute(GNUPLOT .. ' ./gnuplot/hexa.gnu')
    else
        glogger.info2("To display Sammon map, run 'gnuplot -p ./gnuplot/hexa.gnu', or use '-p 1'\n")
    end

    return
end

--- Display sommap 
---@param SomMap any
---@param nx any
---@param ny any
---@param Labels any
---@param title any
---@param verbose any
function dispsom(SomMap, nx, ny, Labels, title, verbose)
    local verbose = verbose or 1
    local title = title or "Items"
    assert(SomMap);
    local view = getsomview(SomMap, nx, ny, Labels)
    if xta.debugmode > 0 then
        print_table(view)
        fwrite(options.outpath .. "/somview.json", "w", JSON:encode_pretty(view))
    end
    if verbose > 0 then
        printf("\n")
        printf("Self-Organizing Map of  '%s'", title)
        printf("\n\n")
        dispsomborder(nx)
        for j = 1, ny do
            dispsombox(nx, view[j], view.maxlen)
            dispsomborder(nx)
        end
        printf("\n")
    end
    return view
end

--- Repeat char for n times
---@param mychar any
---@param n any
function repchar(mychar, n)
    return mychar:rep(n)
end

-- Usage function
local function usage(help_)
    print()
    print("Perform cluster analysis of specified model.")
    print()
    print("Usage: lslua ex_cluster.lua [options]")
    if help_ then print_default_usage() end
    print()
    print("Options:")
    print("    , --somboxwidth=INTEGER      Set the somboxwidth (default: 12)")
    print("    , --outpath=STRING           Specify the output path (default: './tmp/')")
    print("    , --plotMode=INTEGER         Set the plotMode (default: 1)")
    print("    , --testId=INTEGER           Set the testId (default: 1)")
    print("    , --ldim=INTEGER             Set the ldim (default: 2)")
    print("    , --optmethod=INTEGER        Set the optmethod (default: 0)")
    print("    , --ilim=INTEGER             Set the ilim (default: 5000)")
    print("    , --dist=INTEGER             Set the distmetric (default: 1)")
    print("    , --maxiters=INTEGER         Set the maxiters (default: 10000)")
    print()
    print("Extra Options:")
    print("    , --nx=INTEGER           Set the value for 'nx'")
    print("    , --ny=INTEGER           Set the value for 'ny'")
    print("    , --alphafun=STRING      Specify the 'alphafun'")
    print("    , --neigh=INTEGER        Set the value for 'neigh'")
    print("    , --topol=STRING         Specify the 'topol'")
    print("    , --init=STRING          Specify the 'init'")
    print()          
    print()
    print [[
      Remark: Possible values for 'distance' parameter
      dist=='e': Euclidean distance
      dist=='b': City-block distance
      dist=='c': correlation
      dist=='a': absolute value of the correlation
      dist=='u': uncentered correlation
      dist=='x': absolute uncentered correlation
      dist=='s': Spearman's rank correlation
      dist=='k': Kendall's tau      
      ]]      
    print("Example:")
    print("\t lslua ex_cluster.lua -m tmp/Rset0-1.txt --maxiters=5000 --nx=20 --ny=20")
    print()
end


--
-- Main

-- Extensions to default options
local long = {
  somboxwidth = 1,
  outpath = 1,
  plotMode = 1,
  testId = 1,
  ldim = 1,
  optmethod = 1,
  ilim = 1,
  dist = 1,
  maxiters = 1,
  nx = 1,
  ny = 1,
  alphafun = 1,
  neigh = 1,
  topol = 1,
  init = 1,

}
local short = ""
-- Parse options
options, opts, optarg = parse_options(arg,short,long)

-- Set defaults
options.somboxwidth=12
options.outpath='./tmp/'
options.plotMode=1
options.testId=1
options.ldim=2
options.optmethod=0
options.ilim=5000
options.dist=1
options.maxiters=10000
options.nx=10
options.ny=10
options.alphafun=1 --'linear'
options.neigh=1 --'bubble'
options.topol=3 --'hexa'
options.init=1 --'rand'

for i, k in pairs(opts) do
  local v = optarg[i]
  -- ... (existing conditions)

  if k == "somboxwidth" then options.somboxwidth = tonumber(v)
  elseif k == "outpath" then options.outpath = v 
  elseif k == "plotMode" then options.plotMode = tonumber(v) 
  elseif k == "testId" then options.testId = tonumber(v) 
  elseif k == "ldim" then options.ldim = tonumber(v) 
  elseif k == "optmethod" then options.optmethod = tonumber(v) 
  elseif k == "ilim" then options.ilim = tonumber(v) 
  elseif k == "dist" then options.dist = tonumber(v) 
  elseif k == "maxiters" then options.maxiters = tonumber(v) 
  elseif k == "nx" then options.nx = tonumber(v) 
  elseif k == "ny" then options.ny = tonumber(v)
  elseif k == "alphafun" then options.alphafun = v
  elseif k == "neigh" then options.neigh = tonumber(v)
  elseif k == "topol" then options.topol = v
  elseif k == "init" then options.init = v  
  end
end

if options.help then
  usage(true)
  return
end

if not options.model_file then  
  usage(options.help)
  glogger.error("No input file specified. Use -m <input_file> to input.\n")
  return
end

--print(fileHexagon,fileSomSammon)
if not paths.dirp(options.outpath) then
    paths.mkdir(options.outpath)
end

local R={}
if 0>1 then
  printf("Hit enter to start reading data from file: %s\n",options.model_file)
  io.read()
end  
R.exdat = xta:dlmread(options.model_file,' ')
assert(R.exdat)
R.exdat.name="SomData"
--R.exdat:print('tmp/a.csv')
printf("Read data from file: %s\n",R.exdat.name)
printf("Number of rows: %d\n",R.exdat.nrows)
printf("Number of cols: %d\n",R.exdat.ncols)

R.nx = options.nx
R.ny = options.ny
printf('\n')
local _xpar = xta:param()
 
_xpar.alphafun = options.alphafun -- linear
_xpar.neigh = options.neigh -- bubble
_xpar.topol = options.topol -- hexa
_xpar.init = options.init -- rand
_xpar.distmetric = options.dist -- euclid

local seed = options.seed
printf('Grouping w.r.t similarity of data using Selforgmap, seed=%d\n',seed)

local SomMap,nerr
local codes

if options.testId==1 then
    R.maxiters = options.maxiters
    _xpar.alpha = 0.05
    _xpar.radius = 10
elseif options.testId==2 then
    R.maxiters = options.maxiters
    _xpar.alpha = 0.02
    _xpar.radius = 3
elseif options.testId==3 then
    R.maxiters = options.maxiters
    _xpar.alpha = 0.01
    _xpar.radius = 2
end

-- Som train
SomMap, nerr = R.exdat:somtrain(_xpar, R.nx, R.ny, R.maxiters, seed)
SomMap.name = sprintf("SomMap%d",options.testId)
xta:wassert(nerr)
assert(SomMap)
SomMap.printmode=0
SomMap:print('tmp/sommap.csv')
printf('\n')
printf('qerror : %g\n', R.exdat.qerror)
printf('qerror2: %g\n', R.exdat.qerror2)

-- Get codebook
codes = R.exdat:somcodebook()
local codefile = sprintf('tmp/ex.cod.%d',options.testId)
codes:print(codefile)
printf('Wrote codebook to %s\n',codefile)

-- Compute Sammon map
printf("Computing Sammon map\n")
local SomSammon = codes:somsammon(options.ldim,options.optmethod,options.ilim)
SomSammon.printmode=0
SomSammon:print('tmp/somsammon.csv')

printf("Computing Sammon umatrix\n")
local umat = codes:somumatrix(1);
assert(umat)
local umatfile = 'tmp/somumatrix.csv'
umat:print(umatfile)
printf('Wrote umatrix to %s\n',umatfile)
umat:printeps('tmp/somumatrix.eps')
printf('Wrote umatrix to %s\n','tmp/somumatrix.eps')

print()
dispsom(SomMap,R.nx,R.ny,nil)
dispsomhexacenters(nil,'tmp/somsammon.csv',R.nx,R.ny)
