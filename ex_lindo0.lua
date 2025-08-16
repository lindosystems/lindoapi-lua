#!/usr/bin/env lslua
local Lindo = require("llindo_tabox")
assert(Lindo)
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local status = Lindo.status
require "ex_cbfun"
require 'llindo_usage'


-- MAIN
print()
local short=""
local long={}
local options, opts, optarg = parse_options(arg,short,long)
print(options.major_lic,options.minor_lic)
xta:setlindodll(options.major_lic,options.minor_lic)
solver = xta:solver()
assert(solver,"\n\nError: failed create a solver instance.\n")
printf("Created a new solver instance %s\n",solver.version);
printf("Lindo status codes:\n")
print_table3(Lindo.status)

solver:dispose()