#!/usr/bin/env lslua
-- File: ex_odbc.lua
-- Description: Example of odbc connection to a database
-- Author: mka
-- Date: 2019-07-01

local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local status = Lindo.status
local JSON = require("JSON")
require 'ex_cbfun'
require 'llindo_usage'

local options, opts, optarg

-- parse app specific options
function app_options(options,k,v)
  if k=="z" or k=="zfilter" then options.zfilter=v
  elseif k=="scale_by_time" then options.scale_by_time=tonumber(v)
  else
    printf("Unknown option '%s'\n",k)
  end
end

---
-- Parse command line arguments
local function usage(help_)
  print()
  print("Ge")
  print()
  print("Usage: lslua ex_odbc.lua [options]")
  print()
  if help_ then print_default_usage() end
  print()  
  print("  -z, --zfilter=STRING             Specify z_filter table") 
  print("    , --scale_by_time=NUMBER       Scale mip stats by time (default: 1000)") 
  print("")
  if not help_ then print_help_option() end
  print("Example:")
  print("\t lslua ex_odbc.lua -z <TABLE_NAME> [options]")    
  print()    
end   


--- Take the average of the mip stats
-- @param t table of mip stats
local function avg(t)
  local sum = 0
  local sum2 = 0
  local sum3 = 0
  local count = 0
  for k, v in pairs(t) do
    sum = sum + v.nBRAN_TOTAL
    sum2 = sum2 + v.nSIM_ITER
    sum3 = sum3 + v.fTIME_TOT
    count = count + 1
  end
  local a, b, c = sum /count, sum2/count, sum3/count
  if options.scale_by_time then
    a = math.floor(a/c*options.scale_by_time)
    b = math.floor(b/c*options.scale_by_time)    
  end
  return a,b,c
end 

-- Collect mip stats
-- @param options table of options
local function get_mip_stats(options)    
  -- create environment object
  local env = assert (xta.odbc().odbc())

  -- connect to data source
  local con = assert (env:connect ("bapps"))

  local sql_tmp = sprintf(
  [[
    SELECT r.sNAME, r.nMAJ AS nMAJOR, r.nMIN, r.nSTAT, r.nERR, r.nBRAN_TOT AS nBRAN_TOTAL, r.fTIME_TOT, r.nSIM_ITER
    FROM RUNS_MILP r
    INNER JOIN %s z ON r.sNAME = z.sNAME
    where r.fTIME_TOT > 1000 and r.nSIM_ITER > 0
    ORDER BY r.sNAME
  ]], options.zfilter)
  
  local sql = {}
  -- Retrieve a cursor for the specific fields
  table.insert(sql, sql_tmp)

  local cur = assert(con:execute(sql[1]))

  -- Print selected rows
  local t = {}
  local count = 0
  local row = cur:fetch({}, "a") -- the rows will be indexed by field names
  while row do
    count = count + 1
    --print(string.format("%05d> Name: %s, Major: %d, Minor: %d, Status: %d, Error: %d, Branch Total: %d, Time Total: %f",
      --count, row.sNAME or 'N/A', row.nMAJOR or -1, row.nMIN or -1, row.nSTAT or -1, row.nERR or -1, row.nBRAN_TOTAL or -1, row.fTIME_TOT or -1))
      if not t[row.sNAME] then
        t[row.sNAME] = {}
      end
      table.insert(t[row.sNAME], {
        nBRAN_TOTAL = row.nBRAN_TOTAL,
        nSIM_ITER = row.nSIM_ITER,
        fTIME_TOT = row.fTIME_TOT})
    row = cur:fetch(row, "a") -- reusing the table of results
  end
  local count = 0
  local t2 = {}
  for k, v in pairs(t) do
    local a, b, c = avg(v)
    count = count + 1
    printf("%03d>  %40s %14g, %14g %14g secs\n", count, k, a, b, c)  
    t2[k] = {avg_bran = a, avg_sim_iter = b, avg_time_tot = c }    
    if options.scale_by_time then
      t2[k].scale_by_time = options.scale_by_time      
    end
  end
  con:close()
  env:close()
  return t2
end

local long = {
  zfilter = "z",
  scale_by_time = 1,
}
local short = "z:"

options, opts, optarg = parse_options(arg,short,long)

if not options.zfilter then
  options.zfilter = "Z_MIPLIB3"
end
--[[
if not options.scale_by_time then
  options.scale_by_time = 1000
end
]]

local MDB_DIR
if os.getenv("LS_SHARED") then  
  MDB_DIR = sprintf("%s/opt/local/var/bapps",os.getenv("LS_SHARED"))
  if not MDB_DIR then
    MDB_DIR = os.getenv("LS_BAPPS_PATH") or os.getenv("LS_BAPPS_HOME") or os.getenv("LS_BAPPS")    
    if not MDB_DIR then
      MDB_DIR = "/home/mka/bapps"
    end
    if MDB_DIR then
      MDB_DIR = sprintf("%s/mdb",MDB_DIR)
    end
  end
  if not paths.dirp(MDB_DIR) then
    glogger.error("MDB_DIR: %s does not exist\n", MDB_DIR)
    return
  end
end

local t = get_mip_stats(options)

local jfile = sprintf("%s/%s_stats.json", MDB_DIR, options.zfilter)
local jstr = JSON:encode_pretty(t)
fwrite(jfile, "w",jstr) 
if paths.filep(jfile) then
  os.execute(sprintf("cat %s", jfile))
  glogger.info("Wrote to %s\n", jfile)
else
  glogger.error("Failed to write to %s\n", jfile)
end

