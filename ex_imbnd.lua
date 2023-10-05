-- config
require 'ex_cbfun'

-- runlindo
local Lindo = require("base_lindo")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info

local options, opts, optarg
local solver
local model_file
local verb=1
local szerrmsg

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
    res_lpdata = yModel:getLPData()
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
    resb = res
    --print_table3(resb)
    
	local check_gin = true	
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
    
    res = yModel:modifyObjective(n_objs,objndx,objval)
    yModel:xassert(res,{2009})
    
    
    -- CALC BEST LB and UB for each var        
    local vnames = xta:field(yModel.numvars,"names","string")
    printf("\n")
    for k=1,yModel.numvars do     
        local resn = yModel:getVariableNamej(k-1)
        if resn.pachVarName then
			vnames[k] = resn.pachVarName
		else
			vnames[k] = sprintf("X%d",k)
		end
        objndx[1] = k-1
        objval[1] = -1        
        n_objs = 1
        if k>1 then
            objndx[2] = k-2
            objval[2] = 0
            n_objs = n_objs + 1
        end
        if verb>1 then printf("%06d, '%20s', U=%10g, ",k-1,vnames[k],U[k]) end
        res = yModel:modifyObjective(n_objs,objndx,objval)        
        yModel:xassert(res)     
        if not solve_as_lp then   
			res = yModel:solveMIP()
		else
			res = yModel:optimize()
		end
        yModel:xassert(res)
        
        local lb_j, ub_j = -1e30, 1e30
        if yModel.solstatus==2 or yModel.solstatus==1 or yModel.mipstatus==1 then        
            local resx 
            if verb>3 then
				if not solve_as_lp then   
					resx = yModel:getMIPPrimalSolution()
				else
					resx = yModel:getPrimalSolution()
				end
            end
            ub_j = yModel.mipobj and -yModel.mipobj or -yModel.dobj
            if verb>1  then printf("MAXU=%10g, ",ub_j) end            
        else			
			if verb>1  then printf("MAXU=%10g, ",U[k]) end
        end
        
        if verb>1  then printf("L=%10g, ",L[k]) end
        objval[1] = 1
        res = yModel:modifyObjective(1,objndx,objval)
        yModel:xassert(res)
        if not solve_as_lp then   
			res = yModel:solveMIP()
		else
			res = yModel:optimize()
		end
        yModel:xassert(res)
        if yModel.solstatus==2 or yModel.solstatus==1 or yModel.mipstatus==1 then        
            local resx 
            if verb>3  then
				if not solve_as_lp then   
					resx = yModel:getMIPPrimalSolution()
				else
					resx = yModel:getPrimalSolution()
				end
                yModel:xassert(resx)
            end
            lb_j = yModel.mipobj and yModel.mipobj or yModel.dobj
            if verb>1  then printf("MINL=%10g, ",lb_j) end            
        else
			if verb>1  then printf("MINL=%10g, ",L[k]) end            
        end
        if verb>1 then printf(" -- "); end
        
        if lb_j > resb.padBestL[k] + reps then
			resb.padBestL[k] = lb_j;
            if verb>1 then printf("(*L*)") end
        end
        
        if ub_j < resb.padBestU[k] - reps then
			resb.padBestU[k] = ub_j;
            if verb>1 then printf("(*U*)") end
        end
        if verb>1 then printf("\n") end
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
    print()
    print("    , --lp                       Solve as lp when finding best bound")
end   

---
-- Parse command line arguments
local long={
		lp = 0,
	}
local short = ""
options, opts, optarg = parse_options(arg,short,long)

-- parse app specific options
for i, k in pairs(opts) do
    local v = optarg[i]         
    if k=="lp" then options.solve_as_lp=true end
end

-- Local copies of options
local has_cbmip = options.has_cbmip
local has_cbstd = options.has_cbstd
local has_cblog = options.has_cblog
local has_gop   = options.has_gop
local writeas = options.writeas
local lindomajor = options.lindomajor
local lindominor = options.lindominor
local model_file = options.model_file
verb = options.verb
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
