--
-- luatabox unit tests
package.path = package.path..";./?.lua;./systree/share/lua/5.1/?.lua;./systree/share/lua/5.1/?/init.lua"

-- runlindo
local Lindo = require("llindo_tabox")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info
local status = Lindo.status
require 'ex_cbfun'
if (xta==nil) then
  xta = tabox.env()
end

local solver
local model_file
local verb=1
local szerrmsg


function ls_probdir(subpath)
    local prob_dir = os.getenv("LS_PROB")
    if not prob_dir then
        prob_dir = sprintf("%s/prob", os.getenv("HOME") or os.getenv("HOMEPATH"))
    end
    if subpath then
        prob_dir = prob_dir .. "/" .. subpath
    end
    return prob_dir
end

function ls_test_solve_mpx()
    local ymd, hms = xta:datenow(), xta:timenow()
    local jsec = xta:jsec(ymd, hms)
    printf("%06d-%06d jsec:%d\n", ymd, hms, jsec)

    local pModel = solver:mpmodel()
    pModel.logfun = myprintlog

    local file = ls_probdir("nlp/mpx/ex7_3_3.mpx") 
    printf("Reading %s\n", file)
    local res = pModel:readMPXFile(file)
    szerrmsg = sprintf("Error %d: %s\n", res.ErrorCode, pModel:errmsg(res.ErrorCode) or "N/A")
    assert(res.ErrorCode == 0, szerrmsg)

    if pModel.nlpnonz == 0 then
        res = pModel:writeLINDOFile(ls_probdir("lp/ltx/err/a.ltx"))
    end
    assert(res.ErrorCode == 0)
    pModel.logfun = myprintlog
    res = pModel:solve({has_gop=true})
    if res.ErrorCode == 0 then
        printf("pobj: %.7f\n", pModel.pobj and pModel.pobj or -99)
        printf("dobj: %.7f\n", pModel.dobj and pModel.dobj or -99)
    end
    local res = pModel:getHess()
    print_table3(res)
    pModel:dispose()
    printf("%s\n",pModel)
end



-- New solver instance
xta:setsolverdll("",8);
xta:setlindodll(14,0)
solver = xta:solver()
printf("Created a new solver instance %s\n",solver.version);
local ymd,hms = xta:datenow(),xta:timenow() 
local jsec = xta:jsec(ymd,hms)
printf("Timestamp: %06d-%06d jsec:%d\n",ymd,hms,jsec)
local res

ls_test_solve_mpx()

solver:dispose()
printf("Disposed solver instance %s\n",tostring(solver))  
