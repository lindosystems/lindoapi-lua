-- config
require 'ex_cbfun'

-- runlindo
local Lindo = require("base_lindo")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info


local solver
local model_file
local verb=1
local szerrmsg

--
--
function ls_calc_im_opt_bounds(pModel)    
    local yModel = pModel:copyModel()
    if not yModel then
        return
    end
    local res     
    if 0>1 then
        res = yModel:loadData2Inst()
        print_table3(res)    
    end
    res = yModel:dispstats()
    
    res = yModel:getModelDouParameter(pars.LS_DPARAM_SOLVER_FEASTOL)
    yModel:wassert(res)
    local reps = res and res.pValue or 1e-6
    
    --- DEL QTERMS
    local nqterms = 1;
    local pairows = {-1}    
    res = yModel:deleteQCterms(nqterms, xta:field(pairows,"pairows","int"))    
    yModel:xassert(res,{2009})
    --print_table3(res)
    
    -- ZERO OUT OBJ
    res = yModel:modifyObjConstant(0)
    yModel:xassert(res,{2009})
    local n_objs, objndx, objval
    n_objs = yModel.numvars
    objndx = xta:izeros(n_objs)
    objval = xta:zeros(n_objs)
    for k=1,n_objs do objndx[k] = k-1 end
    
    res = yModel:modifyObjective(n_objs,objndx,objval)
    yModel:xassert(res,{2009})
    
    -- GET BEST BOUNDS
    res = yModel:getBestBounds()
    yModel:wassert(res,{2009})
    
    resb = res
    --print_table3(resb)
    
    -- CALC BEST LB and UB for each var
    local v = false    
    local vnames = xta:field(yModel.numvars,"names","string")
    printf("\n")
    for k=1,yModel.numvars do     
        local resn = yModel:getVariableNamej(k-1)
        vnames[k] = resn.pachVarName
        objndx[1] = k-1
        objval[1] = -1        
        n_objs = 1
        if k>1 then
            objndx[2] = k-2
            objval[2] = 0
            n_objs = n_objs + 1
        end
        res = yModel:modifyObjective(n_objs,objndx,objval)
        yModel:xassert(res)
        res = yModel:optimize()
        yModel:xassert(res)
        
        local lb_j, ub_j = -1e30, 1e30
        if yModel.solstatus==2 or yModel.solstatus==1 then        
            local resx 
            if v then
                resx = yModel:getPrimalSolution()
                yModel:xassert(res)
            end
            if v then printf("max x[%d] = %g %s\n",k-1,-yModel.dobj,vnames[k]) end
            ub_j = -yModel.dobj
        end
        
        objval[1] = 1
        res = yModel:modifyObjective(1,objndx,objval)
        yModel:xassert(res)
        res = yModel:optimize()
        yModel:xassert(res)
        if yModel.solstatus==2 or yModel.solstatus==1 then        
            local resx 
            if v then
                resx = yModel:getPrimalSolution()
                yModel:xassert(resx)
            end
            if v then printf("min x[%d] = %g %s\n",k-1,yModel.dobj,vnames[k]) end
            lb_j = yModel.dobj
        end
        
        if lb_j > resb.padBestL[k] + reps then
            printf("%s.lb = %g (> %g)\n",vnames[k], lb_j, resb.padBestL[k])
            resb.padBestL[k] = lb_j;
        end
        
        if ub_j < resb.padBestU[k] - reps then
            printf("%s.ub = %g (< %g)\n",vnames[k], ub_j, resb.padBestU[k])
            resb.padBestU[k] = ub_j;
        end
  
    end
    local rt = xta:table()
    rt:add(vnames)
    rt:add(resb.padBestL,"lb")
    rt:add(resb.padBestU,"ub")
    for k=1,rt.nrows do
        if resb.padBestL[k]>-1e30 and resb.padBestU[k]<1e30 then
            printf("@BND(%g, %s, %g);\n",resb.padBestL[k],vnames[k],resb.padBestU[k]);
        end
    end    
      
    if yModel then
        yModel:dispose()
    end
end

-- Usage function
local function usage()
    print()
    print("Read a model and compute tightest possible bounds.")
    print()
    print("Usage: lua ex_imbnd.lua [options]")
    print("Example:")
    print("\t lua ex_imbnd.lua -m model.mps [options]")
    print()
    print_default_usage()
end   

---
-- Parse command line arguments
local long={}
local short = ""
local options, opts, optarg = parse_options(arg,short,long)

-- Local copies of options
local has_cbmip = options.has_cbmip
local has_cbstd = options.has_cbstd
local has_cblog = options.has_cblog
local has_gop   = options.has_gop
local writeas = options.writeas
local lindomajor = options.lindomajor
local lindominor = options.lindominor
local model_file = options.model_file

if not model_file then
	usage()
	return
end	

if seed then
  if seed~=0 then
    math.randomseed(seed)
  else
    math.randomseed(os.time())
    printf("Initialized random seed with %d (time)\n",os.time())
  end    
end

-- New solver instance
xta:setsolverdll("",8);
xta:setlindodll(lindomajor,lindominor)
solver = xta:solver()
printf("Created a new solver instance %s\n",solver.version);
local ymd,hms = xta:datenow(),xta:timenow() 
local jsec = xta:jsec(ymd,hms)
printf("Timestamp: %06d-%06d jsec:%d\n",ymd,hms,jsec)

local res

-- New model instance
local pModel = solver:mpmodel()
printf("Created a new model instance\n");

-- Set callbacks and logbacks
if has_cblog>0 then    
	pModel.logfun = myprintlog
	printf("Set a new log function for the model instance\n");
end	
if has_cbmip>0 then 
	res = pModel:setMIPCallback(cbmip)
elseif has_cbstd>0 then	
	res = pModel:setCallback(cbstd)
end

-- Read model from file	
printf("Reading %s\n",model_file)
local nErr = pModel:readfile(model_file,0)
pModel:xassert({ErrorCode = nErr})

-- Calc implied bounds
ls_calc_im_opt_bounds(pModel)

if writeas then
    pModel:write(writeas)
end    

-- Solve model
printf("Solving %s\n",model_file)	
local res_opt, res_rng = pModel:solve({has_gop=false,has_rng=false})
if res_rng then
	print_table3(res_rng)
    if verb>1 then
        res_rng.padDec:printmat(6,nil,12,nil,'.3e')
    end
end	

 
pModel:dispose()
printf("Disposed model instance %s\n",tostring(pModel))  
solver:dispose()
printf("Disposed solver instance %s\n",tostring(solver))  
