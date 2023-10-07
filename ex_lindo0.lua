local Lindo = require("llindo_tabox")
assert(Lindo)
require "ex_cbfun"
print()

local short=""
local long={}
local options, opts, optarg = parse_options(arg,short,long)

xta:setlindodll(options.lindomajor,options.lindominor)
solver = xta:solver()
assert(solver,"\n\nError: failed create a solver instance.\n")
printf("Created a new solver instance %s\n",solver.version);

printf("Lindo status codes:\n")
print_table3(Lindo.status)

solver:dispose()