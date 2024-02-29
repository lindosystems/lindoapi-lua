#!/usr/bin/env lslua
-- File: ex_imbnd.lua
-- Description: Example of computing best implied bounds for a model.
-- Author: mka
-- Date: 2019-07-01

local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info

-- config
require 'ex_cbfun'
require 'llindo_usage'
local options, opts, optarg
local solver
local model_file
local verb=1
local szerrmsg

-- Optimize a subproblems with MIP or LP solver, maximizing or minimizing a variable
function im_optimize(yModel,kidx,objsense)
	if not options.solve_as_lp then   
		yModel:setModelDouParameter(pars.LS_DPARAM_MIP_TIMLIM,1000)
		res = yModel:solveMIP()
		yModel:xassert(res,{errs.LSERR_TIME_LIMIT})		
		if yModel.mipstatus==1 then
			res.objval = objsense*yModel.mipobj
			res.status = 'ok'
		elseif yModel.mipstatus==5 then
			res.objval = objsense*yModel.mipbnd
			res.status = 'ok'
            local suffix = sprintf("_%06d_%s",kidx,objsense==-1 and "max" or "min")
            local tempfile = addSuffix2Basename(options.model_file,suffix,"im")
            yModel:write({writeas='ltx', suffix=suffix, subfolder="im"})
		end				
	else
		res = yModel:optimize()
		if yModel.solstatus==1 or yModel.solstatus==2 then
			res.objval = objsense*yModel.dobj
			res.status = 'ok'
		end		
	end	
	local resx
	if verb>3  then
		if not solve_as_lp then   
			resx = yModel:getMIPPrimalSolution()
		else
			resx = yModel:getPrimalSolution()
		end
		yModel:xassert(resx)
	end	
	return res, resx
end

--
--
function ls_calc_im_opt_bounds(pModel)    
	local solve_as_lp = options.solve_as_lp
    local yModel = pModel:copyModel(0)
    yModel:copyParam(pModel)
    if not yModel then
        return
    end
    yModel:setModelIntParameter(pars.LS_IPARAM_LP_PRINTLEVEL,0)
    local res     
    if 0>1 then
        res = yModel:loadData2Inst()
        print_table3(res)    
    end
    res = yModel:dispstats()
    local res_lpdata = yModel:getLPData()
    --[[
{
      pdObjConst = 576,
      padAcoef = lua_Field: 0x0x02e2a600 (pField: 0x0x02d7ecd8, len:91(91),
      panAcols = lua_Field: 0x0x02e29e18 (pField: 0x0x02d7c0b0, len:28(28),
      pachConTypes = LLLLLLLLLLLLL,
      padU = lua_Field: 0x0x02e38f18 (pField: 0x0x02d87520, len:28(28),
      ErrorCode = 0,
      pdObjSense = 1,
      paiArows = lua_Field: 0x0x02e2de68 (pField: 0x0x02d81b68, len:91(91),
      paiAcols = lua_Field: 0x0x02e2cce0 (pField: 0x0x02d78520, len:29(29),
      padL = lua_Field: 0x0x02e327f8 (pField: 0x0x02d84888, len:28(28),
      padB = lua_Field: 0x0x02e4ce88 (pField: 0x0x02d75998, len:13(13),
      padC = lua_Field: 0x0x02e39c88 (pField: 0x0x02d72e10, len:28(28),
   }    
    ]]
    if verb>3 then print_table3(res_lpdata) end    
    res_mipdata = yModel:getVarType()
    if verb>3 then print_table3(res_mipdata) end
    --[[
    {
      pachVarTypes = BBBBBBBBBBBBBBBBBBBBBBBBBBBB,
      ErrorCode = 0,
   }
]]

    -- GET BEST BOUNDS
    if verb>1 then printf("computing best-bounds..\n") end
    res = yModel:getBestBounds()
    yModel:wassert(res,{2009}) 
    if verb>2 then
		res.padBestL:printmat()
		res.padBestU:printmat()
		print("Press Enter")
		io.read()
	end
    local resb = res
    --print_table3(resb)
    
	local check_gin = false	
	local L, U = resb.padBestL, resb.padBestU
	if check_gin then		
		for j=1,L.len do
			if res_mipdata.pachVarTypes:sub(j,j)=="I" then
				if math.abs(L[j])<=1e-12 and math.abs(U[j]-1.0)<=1e-12 then				
					--printf("(L,U) = (%g,%g) ** binary\n",L[j],U[j])
					--io.read()
				else
					printf("j:%d, (L,U) = (%g,%g)\n",j,L[j],U[j])
				end    			
			end
		end    
    end        
    
    res = yModel:getModelDouParameter(pars.LS_DPARAM_SOLVER_FEASTOL)
    yModel:wassert(res)
    local reps = res and res.pValue or 1e-6
    
    --- DEL QTERMS
    if yModel.nonzqcp>0 then
		local nqterms = 1;
		local pairows = {-1}    
		res = yModel:deleteQCterms(nqterms, xta:field(pairows,"pairows","int"))    
		yModel:xassert(res,{2009})
		--print_table3(res)
    end
    printf("verb: %d\n",verb)
    -- ZERO OUT OBJ
    res = yModel:modifyObjConstant(0)
    yModel:xassert(res,{2009})
    local n_objs, objndx, objval
    n_objs = yModel.numvars
    objndx = xta:izeros(n_objs)
    objval = xta:zeros(n_objs)    
    for k=1,n_objs do objndx[k] = k-1 end
    local varndx = objndx:copy()
    
    res = yModel:modifyObjective(n_objs,objndx,objval)
    yModel:xassert(res,{2009})
    
    local elapsed = 0
    -- CALC BEST LB and UB for each var        
    local vnames = xta:field(yModel.numvars,"names","string")
    printf("\n")
    for k=1,yModel.numvars do     		        
		-- prepare for modifications		
        local resn = yModel:getVariableNamej(k-1)
        if resn.pachVarName then
			vnames[k] = resn.pachVarName
		else
			vnames[k] = sprintf("X%d",k)
		end
		if verb>1 then printf("%06d, '%20s', ",k-1,vnames[k]) end
		
        objndx[1] = k-1
        objval[1] = -1        
        n_objs = 1
        if k>1 then
            objndx[2] = k-2
            objval[2] = 0
            n_objs = n_objs + 1
        end                
        elapsed = xta:tic()
        -- maximize x[k]
        if verb>1  then printf("U=%10g, ",U[k]) end
        res = yModel:modifyObjective(n_objs,objndx,objval)        
        yModel:xassert(res)             
        local resx 
        res, resx = im_optimize(yModel,k,-1)        
        local lb_j, ub_j = L[k], U[k]
        if res.status=='ok' then                    
            ub_j = res.objval            
        end
        if verb>1  then printf("MAXU=%10g, ",ub_j) end            
        
		-- minimize x[k]
        if verb>1  then printf("L=%10g, ",L[k]) end
        objval[1] = 1
        res = yModel:modifyObjective(1,objndx,objval)
        yModel:xassert(res)
		
		res, resx = im_optimize(yModel,k,1)                
        if res.status=='ok' then
            lb_j = res.objval            
        end
        if verb>1  then printf("MINL=%10g, ",lb_j) end            
        
        -- update best bounds
        if verb>1 then printf(" -- "); end
        
        if lb_j > resb.padBestL[k] + reps then
			resb.padBestL[k] = lb_j;
            if verb>1 then printf("(*L*)") end
        end
        
        if ub_j < resb.padBestU[k] - reps then
			resb.padBestU[k] = ub_j;
            if verb>1 then printf("(*U*)") end
        end
        elapsed = xta:tic() - elapsed
        if verb>1 then printf(" %.2f secs\n",elapsed) end
    end
    local rt = xta:table()
    rt:add(vnames)
    rt:add(resb.padBestL,"lb")
    rt:add(resb.padBestU,"ub")
    if verb>2 then
		for k=1,rt.nrows do
			if resb.padBestL[k]>-1e30 and resb.padBestU[k]<1e30 then
				printf("@BND(%g, %s, %g);\n",resb.padBestL[k],vnames[k],resb.padBestU[k]);
			end
		end    
    end
    printf("Calculated best im bounds\n")
    local norm={}
    norm["bestU"]=0; norm["bestL"]=0; norm["U"]=0; norm["L"]=0
    for k=1,yModel.numvars do
        if resb.padBestL[k]>-1e30 and resb.padBestU[k]<1e30 then
            norm["bestU"] = norm["bestU"] + resb.padBestU[k] * resb.padBestU[k];
            norm["bestL"] = norm["bestL"] + resb.padBestL[k] * resb.padBestL[k];
        end
        if res_lpdata.padL[k]>-1e30 and res_lpdata.padU[k]<1e30 then
            norm["U"] = norm["U"] + res_lpdata.padU[k] * res_lpdata.padU[k];
            norm["L"] = norm["L"] + res_lpdata.padL[k] * res_lpdata.padL[k];
        end        
    end
    printf("|L|=%10g, |BestL|=%10g\n",norm.L,norm.bestL)
    printf("|U|=%10g, |BestU|=%10g\n",norm.U,norm.bestU)
    res = yModel:modifyLowerBounds(yModel.numvars,varndx,resb.padBestL)
    yModel:wassert(res)
    res = yModel:modifyUpperBounds(yModel.numvars,varndx,resb.padBestU)
    yModel:wassert(res)
    res = yModel:modifyObjConstant(res_lpdata.pdObjConst)
    yModel:wassert(res)
    res = yModel:modifyObjective(yModel.numvars,varndx,res_lpdata.padC)
    yModel:wassert(res)    
      
    return yModel
end

-- parse app specific options
function app_options(options,k,v)
    
	if 0>1 then print()
	else
		printf("Unknown option '%s'\n",k)
	end
end

-- Usage function
local function usage(help_)
    print()
    print("Read a model and compute tightest possible bounds.")
    print()
    print("Usage: lslua ex_imbnd.lua [options]")
    if help_ then print_default_usage() end
    print("App. Options:")
    print()
    print("  -m, --model=STRING             Specify the model file name")    
    print("    , --lp                       Solve as lp when finding best bounds")
    print("    , --solve                    Solve as tightened model")
	print("")
	if not help_ then print_help_option() end        
    print("Example:")
    print("\t lslua ex_imbnd.lua -m /path/to/model.mps [options]")    	
    print() 
end   

---
-- Parse command line arguments
local long={

	}
local short = ""
options, opts, optarg = parse_options(arg,short,long)
--print_table3(options)

-- Local copies of options
local has_cbmip = options.has_cbmip
local has_cbstd = options.has_cbstd
local has_cblog = options.has_cblog
local has_gop   = options.has_gop
local model_file = options.model_file
verb = math.max(options.verb and options.verb or 1, 2)


if options.help then
	usage(true)
	return 
end

if not options.model_file then
	usage(options.help)
	return
end	

if options.seed then
  if options.seed~=0 then
    math.randomseed(options.seed)
  else
    math.randomseed(os.time())
    printf("Initialized random seed with %d (time)\n",os.time())
  end    
end

-- New solver instance
solver = xta:solver()
assert(solver,"\nError: cannot create a solver instance\n")
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
local yModel 
printf("\nStarted computing optimal bounds\n")
yModel = ls_calc_im_opt_bounds(pModel)
assert(yModel,"Error: failed to compute optimal bounds\n")
printf("Finished computing optimal bounds\n")

if options.solve then
	-- Solve model
	printf("\n")
	yModel:setMIPCallback(cbmip)
	--yModel:setModelIntParameter(pars.LS_IPARAM_MIP_PRINTLEVEL,2)
	yModel:setModelIntParameter(pars.LS_IPARAM_LP_PRINTLEVEL,2)
	printf("Solving %s\n",model_file)	
	local res_opt, res_rng = yModel:solve({has_gop=false,ranges=nil})
	if res_rng then
		print_table3(res_rng)
		if verb>1 then
			res_rng.padDec:printmat(6,nil,12,nil,'.3e')
		end
	end	
end

if options.writeas then
	printf("\n")
	printf("Writing ext '%s'\n",options.writeas)	
    yModel:write(options)
end    

 
pModel:dispose()
printf("Disposed model instance %s\n",tostring(pModel))  
yModel:dispose()
printf("Disposed model instance %s\n",tostring(yModel))  
solver:dispose()
printf("Disposed solver instance %s\n",tostring(solver))  
