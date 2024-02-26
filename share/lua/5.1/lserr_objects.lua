#!/usr/bin/env lua
local M = {
      ["2365"] = {
            ["err_code"] = 2365,
            ["err_message"] = "Stochastic tree already initialized.",
      },
      ["2594"] = {
            ["err_code"] = 2594,
            ["err_message"] = "Could not solve the current sub-problem.",
      },
      ["2349"] = {
            ["err_code"] = 2349,
            ["err_message"] = "Iteration limit has been reached during a root finding operation.",
      },
      ["2578"] = {
            ["err_code"] = 2578,
            ["err_message"] = "Missing COLUMNS tag in the MPS file.",
      },
      ["2586"] = {
            ["err_code"] = 2586,
            ["err_message"] = "Extra value in the RHS section of the MPS file.",
      },
      ["2325"] = {
            ["err_code"] = 2325,
            ["err_message"] = "Core file does not have a valid range name tag.",
      },
      ["2317"] = {
            ["err_code"] = 2317,
            ["err_message"] = "Specified stochastic parameter index is invalid.",
      },
      ["2309"] = {
            ["err_code"] = 2309,
            ["err_message"] = "Stochastic model/data has not been loaded yet.",
      },
      ["2052"] = {
            ["err_code"] = 2052,
            ["err_message"] = "The specified row index is out of range for the underlying model.",
      },
      ["2068"] = {
            ["err_code"] = 2068,
            ["err_message"] = "Column token is not found.",
      },
      ["2076"] = {
            ["err_code"] = 2076,
            ["err_message"] = "Column limit is reached before solving to completion.",
      },
      ["2084"] = {
            ["err_code"] = 2084,
            ["err_message"] = "External solver API library not installed.",
      },
      ["2092"] = {
            ["err_code"] = 2092,
            ["err_message"] = "Specified external solver version is not a valid w.r.t current version.",
      },
      ["2205"] = {
            ["err_code"] = 2205,
            ["err_message"] = "Matrix or vector is empty.",
      },
      ["2390"] = {
            ["err_code"] = 2390,
            ["err_message"] = " Mapping stochastic instructions leads to multiple occurrences in matrix model.",
      },
      ["2382"] = {
            ["err_code"] = 2382,
            ["err_message"] = "One or more rows already belong to another chance constraint.",
      },
      ["2012"] = {
            ["err_code"] = 2012,
            ["err_message"] = "Specified index is out of range.",
      },
      ["2366"] = {
            ["err_code"] = 2366,
            ["err_message"] = "Random number generator seed not initialized.",
      },
      ["2595"] = {
            ["err_code"] = 2595,
            ["err_message"] = "Could not write to binary solution file.",
      },
      ["2016"] = {
            ["err_code"] = 2016,
            ["err_message"] = "Iteration limit is reached before solving to completion.",
      },
      ["2342"] = {
            ["err_code"] = 2342,
            ["err_message"] = "Scale parameter for specified distribution is out of range.",
      },
      ["2587"] = {
            ["err_code"] = 2587,
            ["err_message"] = "Missing value in the BOUNDS section of the MPS file.",
      },
      ["2326"] = {
            ["err_code"] = 2326,
            ["err_message"] = "Stoc file does not have an expected token name.",
      },
      ["2318"] = {
            ["err_code"] = 2318,
            ["err_message"] = "A stochastic parameter was not expected in Time file..",
      },
      ["2044"] = {
            ["err_code"] = 2044,
            ["err_message"] = "The given basis is invalid.",
      },
      ["2040"] = {
            ["err_code"] = 2040,
            ["err_message"] = "The specified decomposition type is invalid.",
      },
      ["2053"] = {
            ["err_code"] = 2053,
            ["err_message"] = "The total number of nonzeroes specified is invalid or inconsistent with other input.",
      },
      ["2069"] = {
            ["err_code"] = 2069,
            ["err_message"] = "Row token is not found.",
      },
      ["2077"] = {
            ["err_code"] = 2077,
            ["err_message"] = "Quadratic data not loaded.",
      },
      ["2085"] = {
            ["err_code"] = 2085,
            ["err_message"] = "Error loading zlib library.",
      },
      ["2093"] = {
            ["err_code"] = 2093,
            ["err_message"] = "A Function/Derivative Evaluator (FDE) function was not installed.",
      },
      ["2206"] = {
            ["err_code"] = 2206,
            ["err_message"] = "Matrix is not symmetric.",
      },
      ["2391"] = {
            ["err_code"] = 2391,
            ["err_message"] = " Two or more stochastic instructions maps to the same position in matrix model.",
      },
      ["2383"] = {
            ["err_code"] = 2383,
            ["err_message"] = " No chance-constraints were loaded.",
      },
      ["2375"] = {
            ["err_code"] = 2375,
            ["err_message"] = "No rows were assigned to one of the stages.",
      },
      ["2367"] = {
            ["err_code"] = 2367,
            ["err_message"] = "All sample points in the sample has been used. Resampling may be required.",
      },
      ["2596"] = {
            ["err_code"] = 2596,
            ["err_message"] = "Could not read from binary solution file.",
      },
      ["2351"] = {
            ["err_code"] = 2351,
            ["err_message"] = "Limiting PDF does not exist.",
      },
      ["2343"] = {
            ["err_code"] = 2343,
            ["err_message"] = "Shape parameter for specified distribution is out of range.",
      },
      ["2588"] = {
            ["err_code"] = 2588,
            ["err_message"] = "Extra value in the BOUNDS section of the MPS file.",
      },
      ["2327"] = {
            ["err_code"] = 2327,
            ["err_message"] = "Stoc file does not have a 'ROOT' token to specify a root scenario.",
      },
      ["2319"] = {
            ["err_code"] = 2319,
            ["err_message"] = "Number of stochastic parameters found in Time file do notmatch to that of Stoc file.",
      },
      ["2311"] = {
            ["err_code"] = 2311,
            ["err_message"] = "Stochastic parameter specified in Time file has not been found.",
      },
      ["2054"] = {
            ["err_code"] = 2054,
            ["err_message"] = "Model is not linear.",
      },
      ["2070"] = {
            ["err_code"] = 2070,
            ["err_message"] = "NAME token is not found.",
      },
      ["2078"] = {
            ["err_code"] = 2078,
            ["err_message"] = "Specified row does not have quadratic data.",
      },
      ["2086"] = {
            ["err_code"] = 2086,
            ["err_message"] = "External solver API environment cannot be created.",
      },
      ["2700"] = {
            ["err_code"] = 2700,
            ["err_message"] = "Scripting engine error.",
      },
      ["2580"] = {
            ["err_code"] = 2580,
            ["err_message"] = "Missing ENDATA tag in the MPS file.",
      },
      ["2004"] = {
            ["err_code"] = 2004,
            ["err_message"] = "An invalid constraint type was found.",
      },
      ["2322"] = {
            ["err_code"] = 2322,
            ["err_message"] = "Core file does not have a valid bound name tag.",
      },
      ["2032"] = {
            ["err_code"] = 2032,
            ["err_message"] = "Specified index has duplicates.",
      },
      ["2207"] = {
            ["err_code"] = 2207,
            ["err_message"] = "Matrix has zero diagonal.",
      },
      ["2392"] = {
            ["err_code"] = 2392,
            ["err_message"] = " A stochastic parameter was not expected in the objective function.",
      },
      ["2005"] = {
            ["err_code"] = 2005,
            ["err_message"] = "Model data is inconsistent.",
      },
      ["2376"] = {
            ["err_code"] = 2376,
            ["err_message"] = "No columns were assigned to one of the stages.",
      },
      ["2013"] = {
            ["err_code"] = 2013,
            ["err_message"] = "Specified error-message file is not found.",
      },
      ["2360"] = {
            ["err_code"] = 2360,
            ["err_message"] = "Event tree exceeds the maximum number of scenarios allowed to attempt an exact solution.",
      },
      ["2021"] = {
            ["err_code"] = 2021,
            ["err_message"] = "Solver stopped because of no improvement in step size.",
      },
      ["2017"] = {
            ["err_code"] = 2017,
            ["err_message"] = "Time limit is reached before solving to completion.",
      },
      ["2336"] = {
            ["err_code"] = 2336,
            ["err_message"] = "Specified number of stages in Core model is invalid.",
      },
      ["2328"] = {
            ["err_code"] = 2328,
            ["err_message"] = "Node model is unbounded.",
      },
      ["2037"] = {
            ["err_code"] = 2037,
            ["err_message"] = "Branch limit is reached in the Branch-and-Bound method.",
      },
      ["2312"] = {
            ["err_code"] = 2312,
            ["err_message"] = "Specified scenario index is out of sequence.",
      },
      ["2303"] = {
            ["err_code"] = 2303,
            ["err_message"] = "Stoc file/model has an error.",
      },
      ["2041"] = {
            ["err_code"] = 2041,
            ["err_message"] = "",
      },
      ["2063"] = {
            ["err_code"] = 2063,
            ["err_message"] = "",
      },
      ["2071"] = {
            ["err_code"] = 2071,
            ["err_message"] = "",
      },
      ["2079"] = {
            ["err_code"] = 2079,
            ["err_message"] = "Clock setback was detected.",
      },
      ["2087"] = {
            ["err_code"] = 2087,
            ["err_message"] = "LP solution pool is empty.",
      },
      ["2028"] = {
            ["err_code"] = 2028,
            ["err_message"] = "No license is available for the chosen method.",
      },
      ["2374"] = {
            ["err_code"] = 2374,
            ["err_message"] = "No stochastic parameters were assigned to one of the stages.",
      },
      ["2014"] = {
            ["err_code"] = 2014,
            ["err_message"] = "Specified variable is not found in the model.",
      },
      ["2372"] = {
            ["err_code"] = 2372,
            ["err_message"] = "A random number generator is already set.",
      },
      ["2306"] = {
            ["err_code"] = 2306,
            ["err_message"] = "Unable to open Core file.",
      },
      ["2304"] = {
            ["err_code"] = 2304,
            ["err_message"] = "Core MPI file/model has an error.",
      },
      ["2302"] = {
            ["err_code"] = 2302,
            ["err_message"] = "Time file/model has an error.",
      },
      ["2301"] = {
            ["err_code"] = 2301,
            ["err_message"] = "Core MPS file/model has an error.",
      },
      ["2030"] = {
            ["err_code"] = 2030,
            ["err_message"] = "Specified model is already loaded.",
      },
      ["2055"] = {
            ["err_code"] = 2055,
            ["err_message"] = "A checksum operation has failed during license checking.",
      },
      ["2031"] = {
            ["err_code"] = 2031,
            ["err_message"] = "Model data is not loaded.",
      },
      ["2062"] = {
            ["err_code"] = 2062,
            ["err_message"] = "",
      },
      ["2359"] = {
            ["err_code"] = 2359,
            ["err_message"] = "Node probability cannot be computed due to presence of continuous stochastic parameters.",
      },
      ["2061"] = {
            ["err_code"] = 2061,
            ["err_message"] = "",
      },
      ["2035"] = {
            ["err_code"] = 2035,
            ["err_message"] = "Specified license file does not exist.",
      },
      ["2208"] = {
            ["err_code"] = 2208,
            ["err_message"] = "Invalid permutation.",
      },
      ["2385"] = {
            ["err_code"] = 2385,
            ["err_message"] = " GA instance has not been initialized yet.",
      },
      ["2377"] = {
            ["err_code"] = 2377,
            ["err_message"] = "Default sample sizes per stoc.pars and stage are in conflict.",
      },
      ["2369"] = {
            ["err_code"] = 2369,
            ["err_message"] = "Sample points are not yet generated for a stochastic parameter.",
      },
      ["2361"] = {
            ["err_code"] = 2361,
            ["err_message"] = "Specified correlation type is invalid.",
      },
      ["2353"] = {
            ["err_code"] = 2353,
            ["err_message"] = "Distribution function value was truncated during calculations.",
      },
      ["2345"] = {
            ["err_code"] = 2345,
            ["err_message"] = "Derivative information is unavailable.",
      },
      ["2582"] = {
            ["err_code"] = 2582,
            ["err_message"] = "Extra value in the ROW section of the MPS file.",
      },
      ["2590"] = {
            ["err_code"] = 2590,
            ["err_message"] = "Binary variables in the MPS file.",
      },
      ["2321"] = {
            ["err_code"] = 2321,
            ["err_message"] = "Requested information is unavailable.",
      },
      ["2313"] = {
            ["err_code"] = 2313,
            ["err_message"] = "Stochastic model/data has already been loaded.",
      },
      ["2305"] = {
            ["err_code"] = 2305,
            ["err_message"] = "Stoc file associated with Core MPI file has an error.",
      },
      ["2060"] = {
            ["err_code"] = 2060,
            ["err_message"] = "String list is not loaded.",
      },
      ["2048"] = {
            ["err_code"] = 2048,
            ["err_message"] = "The index vector that mark the beginning of structural columns in three (or four) vector representation of the underlying model is invalid.",
      },
      ["2056"] = {
            ["err_code"] = 2056,
            ["err_message"] = "A user-defined function has not been set yet.",
      },
      ["2072"] = {
            ["err_code"] = 2072,
            ["err_message"] = "The underlying decomposition structure is not compatible with the solver or the decomposition method used.",
      },
      ["2080"] = {
            ["err_code"] = 2080,
            ["err_message"] = "Error loading external solver library.",
      },
      ["2088"] = {
            ["err_code"] = 2088,
            ["err_message"] = "LP solution pool is full.",
      },
      ["2581"] = {
            ["err_code"] = 2581,
            ["err_message"] = "Missing value in the ROW section of the MPS file.",
      },
      ["2025"] = {
            ["err_code"] = 2025,
            ["err_message"] = "Error in input.",
      },
      ["2593"] = {
            ["err_code"] = 2593,
            ["err_message"] = "Multiple objective funtion rows in the ROWS section of the MPS file.",
      },
      ["2008"] = {
            ["err_code"] = 2008,
            ["err_message"] = "There is an error in the MPI file.",
      },
      ["2029"] = {
            ["err_code"] = 2029,
            ["err_message"] = "Specified feature is not yet supported or not compatible with the model type.",
      },
      ["2003"] = {
            ["err_code"] = 2003,
            ["err_message"] = "There is an error in the input model file.",
      },
      ["2310"] = {
            ["err_code"] = 2310,
            ["err_message"] = "Stochastic parameter specified in Stoc file has not been found.",
      },
      ["2384"] = {
            ["err_code"] = 2384,
            ["err_message"] = " Cut limit has been reached.",
      },
      ["2026"] = {
            ["err_code"] = 2026,
            ["err_message"] = "License is too small for the given problem.",
      },
      ["2036"] = {
            ["err_code"] = 2036,
            ["err_message"] = "The specified license file does not exist or contains a corrupt license key.",
      },
      ["2597"] = {
            ["err_code"] = 2597,
            ["err_message"] = "Trying to read past the end of file.",
      },
      ["2357"] = {
            ["err_code"] = 2357,
            ["err_message"] = "Core file/model is not in temporal order.",
      },
      ["2006"] = {
            ["err_code"] = 2006,
            ["err_message"] = "Specified solver type is not known.",
      },
      ["2201"] = {
            ["err_code"] = 2201,
            ["err_message"] = "Error in LDLt factorization.",
      },
      ["2209"] = {
            ["err_code"] = 2209,
            ["err_message"] = "Duplicate elements detected in LDLt factorization.",
      },
      ["2386"] = {
            ["err_code"] = 2386,
            ["err_message"] = " There exists stochastic rows not loaded to any chance constraints yet.",
      },
      ["2002"] = {
            ["err_code"] = 2002,
            ["err_message"] = "Could not open file for problem I/O.",
      },
      ["2370"] = {
            ["err_code"] = 2370,
            ["err_message"] = "Sample points are already generated for a stochastic parameter.",
      },
      ["2010"] = {
            ["err_code"] = 2010,
            ["err_message"] = "Illegal NULL pointer as argument.",
      },
      ["2354"] = {
            ["err_code"] = 2354,
            ["err_message"] = "Stoc file has a parameter value missing.",
      },
      ["2018"] = {
            ["err_code"] = 2018,
            ["err_message"] = "Specified model is not convex.",
      },
      ["2583"] = {
            ["err_code"] = 2583,
            ["err_message"] = "Missing value in the COLUMNS section of the MPS file.",
      },
      ["2591"] = {
            ["err_code"] = 2591,
            ["err_message"] = "Semi continuous variables in the MPS file.",
      },
      ["2038"] = {
            ["err_code"] = 2038,
            ["err_message"] = "Model contains unsupported function for global solver.",
      },
      ["2314"] = {
            ["err_code"] = 2314,
            ["err_message"] = "Specified scenario CDF is invalid, e.g. scenario probabilities do not sum to 1.0.",
      },
      ["2046"] = {
            ["err_code"] = 2046,
            ["err_message"] = "The specified model is already a block of a decomposed model.",
      },
      ["2042"] = {
            ["err_code"] = 2042,
            ["err_message"] = "The specified value for basis status does not match to the  upper or lower bound the variable can attain.",
      },
      ["2057"] = {
            ["err_code"] = 2057,
            ["err_message"] = "",
      },
      ["2065"] = {
            ["err_code"] = 2065,
            ["err_message"] = "Instruction list is too short.",
      },
      ["2073"] = {
            ["err_code"] = 2073,
            ["err_message"] = "Selected method does not support multithreading.",
      },
      ["2081"] = {
            ["err_code"] = 2081,
            ["err_message"] = "External solver library file name not specified.",
      },
      ["2089"] = {
            ["err_code"] = 2089,
            ["err_message"] = "Solution pool limit has been reached.",
      },
      ["2047"] = {
            ["err_code"] = 2047,
            ["err_message"] = "The input values fall out side allowed range.",
      },
      ["2337"] = {
            ["err_code"] = 2337,
            ["err_message"] = "Underlying model has an invalid temporal order.",
      },
      ["2329"] = {
            ["err_code"] = 2329,
            ["err_message"] = "Node model is infeasible.",
      },
      ["2330"] = {
            ["err_code"] = 2330,
            ["err_message"] = "Stochastic model has too many scenarios to solve with specified solver.",
      },
      ["2331"] = {
            ["err_code"] = 2331,
            ["err_message"] = "One or more node-models have irrecoverable numerical problems.",
      },
      ["2334"] = {
            ["err_code"] = 2334,
            ["err_message"] = "Specified stage index is invalid.",
      },
      ["2333"] = {
            ["err_code"] = 2333,
            ["err_message"] = "Event tree is either not initialized yet or was too big to create.",
      },
      ["2335"] = {
            ["err_code"] = 2335,
            ["err_message"] = "Specified algorithm/method is invalid or not supported.",
      },
      ["2340"] = {
            ["err_code"] = 2340,
            ["err_message"] = "Specified stochastic structure has an invalid CDF.",
      },
      ["2341"] = {
            ["err_code"] = 2341,
            ["err_message"] = "Specified distribution type is invalid or not supported.",
      },
      ["2394"] = {
            ["err_code"] = 2394,
            ["err_message"] = " Specified stochastic input is invalid.",
      },
      ["2344"] = {
            ["err_code"] = 2344,
            ["err_message"] = "Specified probabability value is invalid.",
      },
      ["2202"] = {
            ["err_code"] = 2202,
            ["err_message"] = "Empty column detected in LDLt factorization.",
      },
      ["2210"] = {
            ["err_code"] = 2210,
            ["err_message"] = "Detected rank deficiency in LDLt factorization.",
      },
      ["2387"] = {
            ["err_code"] = 2387,
            ["err_message"] = " Specified sample is already assigned as the source for the target sample.",
      },
      ["2379"] = {
            ["err_code"] = 2379,
            ["err_message"] = "A correlation structure has not been induced yet.",
      },
      ["2371"] = {
            ["err_code"] = 2371,
            ["err_message"] = "Sample sizes selected are too small.",
      },
      ["2363"] = {
            ["err_code"] = 2363,
            ["err_message"] = "Model already contains a sampled tree.",
      },
      ["2355"] = {
            ["err_code"] = 2355,
            ["err_message"] = "Distribution has invalid number of parameters.",
      },
      ["2347"] = {
            ["err_code"] = 2347,
            ["err_message"] = "Specified value is invalid.",
      },
      ["2339"] = {
            ["err_code"] = 2339,
            ["err_message"] = "Core and Time data are inconsistent.",
      },
      ["2584"] = {
            ["err_code"] = 2584,
            ["err_message"] = "Extra value in the COLUNMS section of the MPS file.",
      },
      ["2323"] = {
            ["err_code"] = 2323,
            ["err_message"] = "Core file does not have a valid objective name tag.",
      },
      ["2315"] = {
            ["err_code"] = 2315,
            ["err_message"] = "No stochastic parameters were found in the Core file.",
      },
      ["2307"] = {
            ["err_code"] = 2307,
            ["err_message"] = "Unable to open Time file.",
      },
      ["2346"] = {
            ["err_code"] = 2346,
            ["err_message"] = "Specified standard deviation is invalid.",
      },
      ["2058"] = {
            ["err_code"] = 2058,
            ["err_message"] = "Illegal string operation.",
      },
      ["2066"] = {
            ["err_code"] = 2066,
            ["err_message"] = "Instruction list has conflicting variable bounds.",
      },
      ["2074"] = {
            ["err_code"] = 2074,
            ["err_message"] = "The specified parameter identifier is invalid.",
      },
      ["2082"] = {
            ["err_code"] = 2082,
            ["err_message"] = "External solver library already loaded.",
      },
      ["2090"] = {
            ["err_code"] = 2090,
            ["err_message"] = "Parameter tuning tool has not been set up yet.",
      },
      ["2350"] = {
            ["err_code"] = 2350,
            ["err_message"] = "Given array is out of bounds.",
      },
      ["2050"] = {
            ["err_code"] = 2050,
            ["err_message"] = "The number of nonzeroes in one or more columns specified is invalid or inconsistent with other input vectors.",
      },
      ["2592"] = {
            ["err_code"] = 2592,
            ["err_message"] = "Unknown tag in the BOUNDS section of the MPS file.",
      },
      ["2358"] = {
            ["err_code"] = 2358,
            ["err_message"] = "Specified sample size is invalid.",
      },
      ["2001"] = {
            ["err_code"] = 2001,
            ["err_message"] = "Could not allocate enough memory.",
      },
      ["2011"] = {
            ["err_code"] = 2011,
            ["err_message"] = "Specified parameter cannot be set.",
      },
      ["2064"] = {
            ["err_code"] = 2064,
            ["err_message"] = "Instruction list has incorrect numbers of elements.",
      },
      ["2362"] = {
            ["err_code"] = 2362,
            ["err_message"] = "Number of stages in the model is not set yet.",
      },
      ["2393"] = {
            ["err_code"] = 2393,
            ["err_message"] = " One of the distribution parameters of the specified sample was not set.",
      },
      ["2352"] = {
            ["err_code"] = 2352,
            ["err_message"] = "A random number generator is not set.",
      },
      ["2579"] = {
            ["err_code"] = 2579,
            ["err_message"] = "Missing RHS tag in the MPS file.",
      },
      ["2332"] = {
            ["err_code"] = 2332,
            ["err_message"] = "Specified aggregation structure is not compatible with model's stage structure.",
      },
      ["2320"] = {
            ["err_code"] = 2320,
            ["err_message"] = "Specified stochastic parameter does not have a valid outcome value.",
      },
      ["2203"] = {
            ["err_code"] = 2203,
            ["err_message"] = "Matrix data is invalid or has bad input in LDLt factorization.",
      },
      ["2045"] = {
            ["err_code"] = 2045,
            ["err_message"] = "The specified basis status for  a constraint's slack//surplus is invalid.",
      },
      ["2007"] = {
            ["err_code"] = 2007,
            ["err_message"] = "Specified objective sense is invalid.",
      },
      ["2380"] = {
            ["err_code"] = 2380,
            ["err_message"] = "A discrete PDF table has not been loaded.",
      },
      ["2015"] = {
            ["err_code"] = 2015,
            ["err_message"] = "Internal error -- please contact LINDO Systems..",
      },
      ["2364"] = {
            ["err_code"] = 2364,
            ["err_message"] = "Stochastic events are not loaded yet.",
      },
      ["2023"] = {
            ["err_code"] = 2023,
            ["err_message"] = "User interrupt.",
      },
      ["2348"] = {
            ["err_code"] = 2348,
            ["err_message"] = "Specified parameters are invalid for the given distribution.",
      },
      ["2577"] = {
            ["err_code"] = 2577,
            ["err_message"] = "Missing ROWS tag in the MPS file.",
      },
      ["2027"] = {
            ["err_code"] = 2027,
            ["err_message"] = "Specified license is not valid or license file is corrupt.",
      },
      ["2039"] = {
            ["err_code"] = 2039,
            ["err_message"] = "Branch limit is reached in the global solver.",
      },
      ["2316"] = {
            ["err_code"] = 2316,
            ["err_message"] = "Number of stochastic parameters found in Core file do notmatch to that of Time file.",
      },
      ["2308"] = {
            ["err_code"] = 2308,
            ["err_message"] = "Unable to open Stoc file.",
      },
      ["2043"] = {
            ["err_code"] = 2043,
            ["err_message"] = "The specified basis status for a column is invalid.",
      },
      ["2051"] = {
            ["err_code"] = 2051,
            ["err_message"] = "The error code inquired about is invalid.",
      },
      ["2067"] = {
            ["err_code"] = 2067,
            ["err_message"] = "Instruction list contains a syntax error.",
      },
      ["2075"] = {
            ["err_code"] = 2075,
            ["err_message"] = "The specified number of threads is invalid.",
      },
      ["2083"] = {
            ["err_code"] = 2083,
            ["err_message"] = "External solver API function not installed.",
      },
      ["2091"] = {
            ["err_code"] = 2091,
            ["err_message"] = "Specified external solver is not supported or unknown.",
      },
      ["2019"] = {
            ["err_code"] = 2019,
            ["err_message"] = "Solver stopped because of numerical instability.",
      },
      ["2059"] = {
            ["err_code"] = 2059,
            ["err_message"] = "String list is already loaded.",
      },
      ["2033"] = {
            ["err_code"] = 2033,
            ["err_message"] = "Instruction list is not loaded.",
      },
      ["2324"] = {
            ["err_code"] = 2324,
            ["err_message"] = "Core file does not have a valid right-hand-side name tag.",
      },
      ["2585"] = {
            ["err_code"] = 2585,
            ["err_message"] = "Missing value in the RHS section of the MPS file.",
      },
      ["2009"] = {
            ["err_code"] = 2009,
            ["err_message"] = "Requested information is not available.",
      },
      ["2388"] = {
            ["err_code"] = 2388,
            ["err_message"] = " No user-defined distribution function has been set for the specified sample.",
      },
      ["2368"] = {
            ["err_code"] = 2368,
            ["err_message"] = "Sampling is not supported for models with explicit scenarios.",
      },
      ["2589"] = {
            ["err_code"] = 2589,
            ["err_message"] = "Integer variables in the MPS file.",
      },
      ["2338"] = {
            ["err_code"] = 2338,
            ["err_message"] = "Number of stages specified in Time structure is invalid.",
      },
      ["2034"] = {
            ["err_code"] = 2034,
            ["err_message"] = "License is for an older version.",
      },
      ["2378"] = {
            ["err_code"] = 2378,
            ["err_message"] = "Empty scenario data.",
      },
      ["2024"] = {
            ["err_code"] = 2024,
            ["err_message"] = "Specified parameter is out of range.",
      },
      ["2204"] = {
            ["err_code"] = 2204,
            ["err_message"] = "Invalid matrix or vector dimension.",
      },
      ["2049"] = {
            ["err_code"] = 2049,
            ["err_message"] = "The specified column index is out of range for the underlying model.",
      },
      ["2389"] = {
            ["err_code"] = 2389,
            ["err_message"] = " Specified sample does not support the function call or it is incompatible with the argument list.",
      },
      ["2381"] = {
            ["err_code"] = 2381,
            ["err_message"] = "No continously distributed random parameters are found.",
      },
      ["2373"] = {
            ["err_code"] = 2373,
            ["err_message"] = "Sampling is not allowed for random parameters which are part of block/joint distributions.",
      },
   }
   
return M;
