#!/usr/bin/env lslua
local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info

-- config
require 'ex_cbfun'
require 'llindo_usage'
local options, opts, optarg

-- Function to generate a random N-variable knapsack problem with K constraints
function generateKnapsackProblem(N, K, min_w, max_w, min_c, max_c)
    -- Randomly generate objective vector (coefficients for the variables)
    local objective = {}
    for i = 1, N do
        table.insert(objective, math.random(min_w, max_w)) -- Random coefficients between min_w and max_w
    end

    -- Randomly generate constraint coefficients and RHS value
    local constraintCoefficients = {}
    local sumOfWeights = 0
    for i = 1, N do
        local weight = math.random(min_c, max_c) -- Random weights between min_c and max_c
        sumOfWeights = sumOfWeights + weight
        table.insert(constraintCoefficients, weight)
    end
    local rhs = math.random(math.floor(sumOfWeights * 3/5), math.floor(sumOfWeights * 5/7)) -- Random RHS value between 3/5 and 5/7 of the sum of weights

    -- Output the constraint in LINDO format
    local constraintString = "Subject To\n"
    constraintString = constraintString .. "    Constraint1) "
    for i = 1, N do
        constraintString = constraintString .. constraintCoefficients[i] .. " x" .. i 
        if i < N then
            constraintString = constraintString .. " +  \n"
        end
    end
    constraintString = constraintString .. " >= " .. rhs .. "\n"

    -- Output the objective function
    local objectiveString = "minimize\n"
    objectiveString = objectiveString .. "    "
    for i = 1, N do
        objectiveString = objectiveString .. objective[i] .. " x" .. i
        if i < N then
            objectiveString = objectiveString .. " + \n"
        end
    end
    objectiveString = objectiveString .. "\n"

    -- Output the problem
    local problemString = objectiveString .. constraintString

    problemString = problemString .. "END\n"
    for i = 1, N do
        problemString = problemString .. "SUB x" .. i .. " 1.0\n"
    end    
    for i = 1, N do
        problemString = problemString .. "INT x" .. i .. "\n"
    end

    return problemString
end

function app_options(options, k, v)
    -- parse app specific options   
	if k=="min_w" then options.min_w=tonumber(v) 
	elseif k=="max_w" then options.max_w=tonumber(v) 
	elseif k=="min_c" then options.min_c=tonumber(v) 
	elseif k=="max_c" then options.max_c=tonumber(v) 
	elseif k=="N" or k=="nvars" then options.nvars=tonumber(v) 
	elseif k=="K" or k=="ncons" then options.ncons=tonumber(v) 
	else
		printf("Unknown option '%s'\n",k)
	end
end

-- Usage function
local function usage(help_)
	print()
	print("Read a model and compute tightest possible bounds.")
	print()
	print("Usage: lslua ex_gen_knap.lua [options]")
	if help_ then print_default_usage() end
	print()
	print("    , --solve=<INTEGER>  Solve as tightened model")
	print(" -N , --nvars=<INTEGER>  Number of variables")
	print(" -K , --ncons=<INTEGER>  Number of constraints")
	print("    , --min_w=<INTEGER>  Minimum weight for objective coefficients")
	print("    , --max_w=<INTEGER>  Maximum weight for objective coefficients")
	print("    , --min_c=<INTEGER>  Minimum weight for constraint coefficients")
	print("    , --max_c=<INTEGER>  Maximum weight for constraint coefficients")        
	print()
	if not help_ then print_help_option() end        	    
	print("Example:")
	print("\t lslua ex_gen_knap.lua -N 100 -K 10  [options]")
	print("")        	    
end   

---
-- Parse command line arguments
local long={
		min_w = 1,
		max_w = 1,
		min_c = 1,
		max_c = 1,
		nvars = "N",
		ncons = "K",
	}
local short = "N:K:"
options, opts, optarg = parse_options(arg,short,long)
--print_table3(options)
--print_table3(opts)
           
    
if options.help then
	usage(true)
	return
end

if not options.nvars then
	usage(options.help)
	return
end	

-- Get N, K, min_w, max_w, min_c, and max_c from command line arguments
local N = options.nvars -- required
local K = options.ncons or 1
local min_w = options.min_w or 1
local max_w = options.max_w or 10
local min_c = options.min_c or 1
local max_c = options.max_c or 10

if options.seed then
    if options.seed~=0 then
      math.randomseed(options.seed)
    else
      math.randomseed(os.time())
      printf("Initialized random seed with %d (time)\n",os.time())
    end    
end

local ltxstream = generateKnapsackProblem(N, K, min_w, max_w, min_c, max_c)

if options.solve then    
    -- New solver instance
    local solver = xta:solver()
    assert(solver,"\nError: cannot create a solver instance\n")
    printf("Created a new solver instance %s\n",solver.version);
    local ymd,hms = xta:datenow(),xta:timenow() 
    local jsec = xta:jsec(ymd,hms)
    printf("Timestamp: %06d-%06d jsec:%d\n",ymd,hms,jsec)

    local res

    -- New model instance
    local pModel = solver:mpmodel()
    printf("Created a new model instance\n");
    pModel:set_params_user(options)   
    pModel:disp_params_non_default()
        
    pModel.logfun = myprintlog
    local res = pModel:readLINDOStream(ltxstream,#ltxstream)
    pModel:xassert(res)
    printf("Read model from stream\n")
    res = pModel:solve(options)
    pModel:wassert(res)
else
    print(ltxstream)    
end
