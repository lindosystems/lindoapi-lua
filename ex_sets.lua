#!/usr/bin/env lslua
-- File: ex_sets.lua
-- Description: Example of adding (randomized) SETS (sos1/sos2/sos3) to models.
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
local verb
local options, opts, optarg

---
--
function ls_disp_set_data(pModel)
    local res = pModel:getSETSData()
    print_table3(res)
    pModel:xassert(res)    
    if verb>0 then
      res.paiCardnum:printmat()
      res.paiBegset:printmat()
      res.paiVarndx:printmat()    
      res.paiNnz:printmat()      
      local t={}
      for k=1,res.piNsets do
          local byteValue = string.byte(res.pachSETtype,k)
          table.insert(t,byteValue)
      end
      local paiSETStype = xta:field(t,'paiSETStype','integer')
      paiSETStype:printmat()
    end

    if false and res.piNsets > 0 then
        local res = pModel:getSETSDatai(0)
        print_table3(res)
        pModel:xassert(res)        
    end

    if pModel.numsc>0 then
      local res = pModel:getSemiContData()
      print_table3(res)
      pModel:xassert(res)
    end
    return
end




-- Function to find the longest continuous block of indices
function findLongestBlock(idx)
  local longestBlock = {}  -- Initialize the longest block as an empty array
  local currentBlock = {}  -- Initialize the current block as an empty array  
  local currentBlockIdx = {}
  local longestBlockIdx = {}
  for i = 1, #idx do
      -- Check if the current index is consecutive to the last index in the current block
      if i > 1 and idx[i] == idx[i - 1] + 1 then
          table.insert(currentBlock, idx[i])  -- Add the index to the current block
          table.insert(currentBlockIdx, i)
      else
          -- If not consecutive, start a new current block
          currentBlock = {idx[i]}
          currentBlockIdx = {i}
      end

      -- Update the longest block if the current block is longer
      if #currentBlock > #longestBlock then
          longestBlock = currentBlock
          longestBlockIdx = currentBlockIdx
      end
  end
  --print_table3(longestBlock)
  --print_table3(longestBlockIdx)
  --io.read()
  return longestBlock,longestBlockIdx
end

---
---

function generateConsecutiveIndices(idx,nlen)      
  assert(#idx>nlen,"#idx must be >= nlen" )
  local ridx = {} 
  local longestBlock,longestBlockIdx = findLongestBlock(idx)
  if not longestBlock or #longestBlock<3 then
    longestBlock = {}
    longestBlockIdx = {}    
    local roffset = generateRandomIntegers(1,#idx-nlen,1)
    roffset = roffset[1]
    for k=1,nlen do
      table.insert(longestBlock,idx[roffset]+k)
      table.insert(longestBlockIdx,k)    
    end
  end
  local xlen = math.min(nlen,math.floor(#longestBlock*0.85)+1) 
  if xlen < 3 then
    xlen = 3
  end
  for k=1,xlen do    
    table.insert(ridx,longestBlock[k])
    idx[longestBlockIdx[k]]=nil    
  end  
  --print_table3(ridx)
  return ridx
end

--- Build the index set of candidate variables to be added to the model as 'sets'
---@param res_opt any
---@param res_rng any
function ls_build_var_list(res_opt, res_rng, prob)
  local prob = prob or 0.4
  local varlist = {}  
  if res_rng and res_rng.bounds then    
    local res_rng = res_rng.bounds
    for k=1,res_opt.padPrimal.len do
      local flag = res_opt.padPrimal[k]>0 and (res_rng.padDec[k]>0 and res_rng.padDec[k]<1e30 or res_rng.padInc[k]>0 and res_rng.padInc[k]<1e30)
      if flag then
        if options.verb>1 then
          printf("%3d %10g %10g %10g %s\n",k,res_opt.padPrimal[k],res_rng.padDec[k],res_rng.padInc[k],"*")
        end
        table.insert(varlist,k)
      end
    end
  else
    for k=1,res_opt.padPrimal.len do
      local flag 
      if prob>0 then
        flag = math.random(0,1)>prob
      end
      if res_opt.padPrimal[k]>0 then
        flag = true
      end
      if flag then
        if options.verb>1 then
          printf("%3d %10g %s\n",k,res_opt.padPrimal[k],"*")
        end
        table.insert(varlist,k)
      end
    end    
  end
  return varlist
end

--- func desc
---@param pModel any
---@param t_sets any
function ls_load_sets(pModel, t_sets)
  local pszSETStype,paiCARDnum,paiSETSbegcol,paiSETScols, nSETS = t_sets.pszSETStype,t_sets.paiCARDnum,t_sets.paiSETSbegcol,t_sets.paiSETScols, t_sets.nSETS  
  assert(nSETS == paiSETSbegcol.len-1,sprintf("\n nSETS=%d must be equal to paiSETSbegcol.len-1 = %d\n",nSETS,paiSETSbegcol.len-1))  
  local pszSETStype_ = ""
  for k=1,nSETS do
    pszSETStype_ = pszSETStype_ .. string.char(pszSETStype[k])
  end
  local res_ = pModel:loadSETSData(nSETS,pszSETStype_,paiCARDnum,paiSETSbegcol,paiSETScols)
  return res_
end

--- func desc
---@param pModel any
---@param res_opt any
---@param res_rng any
function ls_gen_random_sets(pModel,  idx, settype_k, options, t_sets)
  local nsets_k = options.nsets
  assert(settype_k>=1 and settype_k<=4,"settype must be in [1,4]")  
  assert(#idx>2,"#idx must be > 2")
  local pszSETStype,paiCARDnum,paiSETSbegcol,paiSETScols,nSETS = t_sets.pszSETStype,t_sets.paiCARDnum,t_sets.paiSETSbegcol,t_sets.paiSETScols,t_sets.nSETS
  if not paiSETSbegcol then
    paiSETSbegcol = xta:field(0,'paiSETSbegcol','integer')
    paiSETScols = xta:field(0,'paiSETScols','integer')  
    paiCARDnum = xta:field(0,'paiCARDnum','integer')
    pszSETStype = xta:field(0,'pszSETStype','integer')
    t_sets.pszSETStype,t_sets.paiCARDnum,t_sets.paiSETSbegcol,t_sets.paiSETScols,t_sets.nSETS = pszSETStype,paiCARDnum,paiSETSbegcol,paiSETScols,nSETS
    t_sets.nz = 0
    t_sets.nSETS = 0
  end
  printf("----\n")
  printf("nsets_k: %d\n",nsets_k)
  printf("settype_k: %d\n",settype_k)
  printf("|idx|: %d\n",#idx)    
  printf("min_k|S_k|: %d\n",options.min_sk)  
  printf("max_k|S_k|: %d\n",options.max_sk)  
  printf("t_sets.nSETS: %d\n",t_sets.nSETS)
  printf("t_sets.nz: %d\n",t_sets.nz)
  printf("paiSETSbegcol.len: %d\n",paiSETSbegcol.len)
  assert(options.min_sk<options.max_sk,"min_sk must be < max_sk")

  local ridx  
  local nz = t_sets.nz         
  local setlen
  --setlen = generateLeftSkewedRandomIntegers(5,max_sk,nsets_k)  
  setlen = generateRandomIntegers(options.min_sk,options.max_sk,nsets_k)
  print_table3(setlen)  
  for k=1,nsets_k do
    -- ridx = generateUniqueRandomIntegers(3,#idx,setlen[k])      
    idx = compressArray(idx)         
    ridx = generateConsecutiveIndices(idx,setlen[k])    
    if verb>0 then 
      printf("SET: %d = {",k) 
    end  
    pszSETStype:add(settype_k)
    if settype_k==4 then
      paiCARDnum:add(math.floor(setlen[k]/3)+1)
    end
    if k>1 or t_sets.nSETS==0 then
      paiSETSbegcol:add(nz) -- else already added
    end    
    for j=1,#ridx do
      local i = ridx[j]
      if verb>0 then printf("%d ",i) end
      paiSETScols:add(i-1)
      nz = nz + 1
    end      
    if verb>0 then printf("}, setlen:%d\n",#ridx) end      
  end  
  paiSETSbegcol:add(nz)              
  if verb>1 then
    paiSETSbegcol:printmat()
    paiSETScols:printmat()
    pszSETStype:printmat()
  end
  if nz>0 then
    t_sets.nSETS = t_sets.nSETS + nsets_k
    t_sets.nz = t_sets.nz + nz
  end
  return t_sets, idx
end

---
-- Parse command line arguments
local function usage(help_)
    print()
    print("Read a model from an MPS file and optimize or modify.")
    print()
    print("Usage: lslua ex_sets.lua [options]")
    print()
    if help_ then print_default_usage() end
	print()
    print("    , --disp_sets                Display set/sc data")
    print("    , --addsets_mask=INTEGER     An integer mask to specify how to add sets")        
    print("    , --nsets=INTEGER            Set number of sets to 'INTEGER'")        
    print("    , --nsemicont=INTEGER        Set number of semi-cont vars to 'INTEGER'")        
    print("    , --max_sk=INTEGER           Set maximum set-size to 'INTEGER'")        
    print("    , --min_sk=INTEGER           Set minimum set-size to 'INTEGER'")     
    print("")
    if not help_ then print_help_option() end
    print("Example:")
    print("\t lslua ex_sets.lua -m model.mps [options]")    
    print()    
end   

local long = {      
    nsets = 1,
    nsemicont = 1,
    max_sk = 1,
    min_sk = 1,
    disp_sets = 0,
    addsets_mask = 1,
    max = 0
}
local short = ""
options, opts, optarg = parse_options(arg,short,long)

-- parse app specific options
for i, k in pairs(opts) do
    local v = optarg[i]         
    if k=="disp_sets" then options.disp_sets=true end
    if k=="addsets_mask" then options.addsets_mask = tonumber(v) end    
    if k=="nsets" then options.nsets=tonumber(v) end
    if k=="nsemicont" then options.nsemicont=tonumber(v) end
    if k=='max_sk' then options.max_sk=tonumber(v) end
    if k=='min_sk' then options.min_sk=tonumber(v) end
    if k=='max' then options.max=true end
end

options.disp_sets = options.disp_sets or false
options.addsets_mask = options.addsets_mask or 0
options.nsets = options.nsets or 3 
options.nsemicont = options.nsemicont or 0
options.min_sk = options.min_sk or 3
options.max_sk = options.max_sk or 20
options.verb = options.verb or 0
options.seed = options.seed or 0
verb = options.verb

if options.help then
  usage(true)
  return
end

if not options.model_file then
	usage(options.help)
	return
end	


-- New solver instance
xta:setsolverdll("",8);
xta:setlindodll(options.lindomajor,options.lindominor)
solver = xta:solver()
printf("Created a new solver instance %s\n",solver.version);
local ymd,hms = xta:datenow(),xta:timenow() 
local jsec = xta:jsec(ymd,hms)
printf("Timestamp: %06d-%06d jsec:%d\n",ymd,hms,jsec)
local res

-- New model instance
local pModel = solver:mpmodel()
printf("Created a new model instance\n");
if options.has_cblog>0 then    
	pModel.logfun = myprintlog
	printf("Set a new log function for the model instance\n");
end	
-- set options and utable
pModel:set_params_user(options)  
assert(pModel.utable.counter)

-- Read model from file	
printf("Reading %s\n",options.model_file)
local nErr = pModel:readfile(options.model_file,0)
pModel:xassert({ErrorCode=nErr})

if options.max then    
  pModel:setModelIntParameter(pars.LS_IPARAM_OBJSENSE,-1)
  printf("Set model sense to maximize (%d)\n",-1)
end

-- Set callback or logback
if options.has_cbmip>0 then 
	pModel:setMIPCallback(cbmip)
elseif options.has_cbstd>0 then	
	pModel:setCallback(cbstd)
end

-- Display set/sc data
if options.disp_sets then
	ls_disp_set_data(pModel)
end	

-- Solve model
options.ranges = "bounds"
local res_opt, res_rng = pModel:solve(options)
if res_rng then
    if options.verb>2 then print_table3(res_rng) end
    if options.verb>1 then
        res_rng.bounds.padDec:printmat(6,nil,12,nil,'.3e')
    end
end	
if res_opt then
    if options.verb>2 then print_table3(res_opt) end
    if res_opt.padPrimal then
        if options.verb>1 then
            res_opt.padPrimal:printmat(6,nil,12,nil,'.3e')
        end
    else
        printf("No primal solution\n")
    end
end

if options.sol then
  local solfile = changeFileExtension(options.model_file,".sol")
  res = pModel:writesol(solfile,nil,1)
  pModel:wassert(res)
end

-- Build candidate variables to go into sets
local varlist, t_sets
if options.addsets_mask>0 then
  -- Add random sets
  varlist = ls_build_var_list(res_opt,res_rng)
  assert(varlist and #varlist>0)
  t_sets = {}
end

local settype
if hasbit(options.addsets_mask,bit(1)) then --addset=+1
  settype = 1 -- SOS1
  t_sets, varlist = ls_gen_random_sets(pModel,varlist,settype,options,t_sets)
end

if hasbit(options.addsets_mask,bit(2)) then --addset=+2
  settype = 2 -- SOS2
  t_sets, varlist = ls_gen_random_sets(pModel,varlist,settype,options,t_sets)
end

if hasbit(options.addsets_mask,bit(3)) then --addset=+4
  settype = 3 -- SOS3
  t_sets, varlist = ls_gen_random_sets(pModel,varlist,settype,options,t_sets)
end

if hasbit(options.addsets_mask,bit(4)) then --addset=+8
  settype = 4 -- CARD
  t_sets, varlist = ls_gen_random_sets(pModel,varlist,settype,options,t_sets)
end

local sc_list
local seed = options.seed

if options.nsemicont>0 then  
  -- Add random semi-cont vars
  local nsemicont = options.nsemicont
  local varlist = ls_build_var_list(res_opt,res_rng,0.0)  
  local varorder = xta:randperm(#varlist,seed)
  local nvars = pModel.numvars
  sc_list = {}
  for k=1,nsemicont do
    local i = varlist[varorder[k]]
    table.insert(sc_list,i-1)
  end
  local lb_sc = xta:field(#sc_list,'lb_sc','double')
  local ub_sc = xta:field(#sc_list,'ub_sc','double')
  local reps = 1e-5
  for k=1,#sc_list do
    local i = sc_list[k]
    local x_i = res_opt.padPrimal[i+1]
    assert(x_i>reps or x_i<-reps)    
    lb_sc[k]=x_i
    ub_sc[k]=x_i*10
  end
  local sc_vars = xta:field(sc_list,'paiVarndx','integer')
  lb_sc:printmat()
  ub_sc:printmat()    
  sc_vars:printmat()
  local res 
  if options.verb>0 then
    printf("Adding %d semi-cont vars\n",#sc_list)
  end
  if pModel.numsc==0 then
    if 1>0 then
      print_table3(sc_list)
      local sc_type = string.rep("S",#sc_list)
      res = pModel:modifyLowerBounds(#sc_list,sc_vars,lb_sc)  
      pModel:xassert(res)
      res= pModel:modifyUpperBounds(#sc_list,sc_vars,ub_sc)    
      pModel:xassert(res)
      local bytes = {}
      for k=1,nvars do
        table.insert(bytes,"C")
      end
      for k=1,#sc_list do
        local i = sc_list[k]+1
        bytes[i]="S"
      end      
      local var_type = table.concat(bytes)
      local var_idx = xta:field(nvars,'var_idx','integer')
      --res = pModel:modifyVarType(#sc_list,sc_vars,sc_type)
      res = pModel:loadVarType(var_type)
      pModel:xassert(res)    
    else
      res = pModel:loadSemiContData(#sc_list,sc_vars,lb_sc,ub_sc)    
      pModel:xassert(res)
    end
  end
  
  if options.verb>2 then print_table3(res) end
end

if options.addsets_mask>0 then  
  res = ls_load_sets(pModel, t_sets)
  pModel:xassert(res)
  if options.verb>2 then print_table3(res) end
end


if options.nsemicont > 0 or options.addsets_mask > 0 then
    --res = pModel:setMIPCallback(cbmip)
    --pModel:xassert(res)
    pModel:dispstats()
    options.ranges = nil
    printf("Re-solving model with new sets/sc\n")
    res_opt, _ = pModel:solve(options)
    pModel:wassert(res_opt)
    if verb > 2 then
        print_table3(res_opt)
    end
    if res_opt.pnMIPSolStatus ~= status.LS_STATUS_INFEASIBLE then
      if options.writeas then
        options.writeas = 'mps'
      end
    else
        printf("No MIP solution, cannot write MPS file\n")
    end
    for k=1,#sc_list do
      local i = sc_list[k]
      res = pModel:getLPVariableDataj(i)
      print_table3(res)      
    end
    print()
end

if options.writeas then
    options.subfolder = "sets"
    options.writeas = "mpssets" --change to special model 'mpssets'
    options.suffix = sprintf("%d",options.seed)    
    pModel:write(options)
end    
 
pModel:dispose()
printf("Disposed model instance %s\n",tostring(pModel))  
solver:dispose()
printf("Disposed solver instance %s\n",tostring(solver))  
