#!/usr/bin/env lua

local islivenow = function(xsim)
  local flag = xsim:isstate(xta.const.state_sim_live)>0
  return flag
end
TBsim.islivenow = islivenow

local catchup = function(xsim,lfeed,imark)  
  assert(lfeed)
  local nbars,ierr=0,0
  if not lfeed then 
    return nbars,-1 
  end
  local xfile
  local logger = xsim.utable.logger or glogger
  logger.debug("xsim '%s' started catching up bars for all assets..\n",xsim.name)
  for i=1,xsim.nassets do
    local xasset = xsim:getasset(i)
    local bars = xasset.bars
    local pair_ = xasset.symbol
    local interval = xasset.interval
    local prewait = 0
    local maxtries = 1
    local method = nil
    local rt, tsfetch, report    
    if cmdOptions.writeFlag>0 then
      xfile = sprintf(xta_outpath() ..'/bars-%s-a.txt',imark or "t")
      bars:print(xfile)
      logger.info("Exported '%s' bars to '%s' before catchup\n",pair_,xfile)
    end
    
    logger.debug("Catching up '%s' bars\n",pair_)
    
    nbars,ierr = lfeed:catchup(pair_, bars, interval, prewait, maxtries, method)
    if cmdOptions.writeFlag>0 then
      xfile = sprintf(xta_outpath() ..'/bars-%s-c.txt',imark or "t")
      bars:print(xfile)
      logger.info("Exported '%s' bars to '%s' after catchup\n",pair_,xfile)
    end              
    xfile = xta_outpath() .. '/bars_t.txt'
    if xta_file_exists(xfile) then
      paths.rmall(xfile,"yes")
      logger.debug("Removed '%s'\n",xfile)
    end
    if ierr<0 then
      break
    end       
  end
  logger.debug("xsim '%s' finished catching up bars..\n",xsim.name)
  return nbars,ierr
end
TBsim.catchup = catchup