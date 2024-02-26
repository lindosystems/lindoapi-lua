#!/usr/bin/env lua

TBasset.islivenow = function(xasset)
  return xasset.sim:islivenow()
end
