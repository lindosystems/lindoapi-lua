
local TB_ANN_TRF_SSIGMOID = 1
local TB_ANN_TRF_LSIGMOID = 2
local TB_ANN_TRF_MSIGMOID = 3
local TB_ANN_TRF_AGAUSSIAN = 4
local TB_ANN_TRF_LINEAR = 5
local TB_ANN_TRF_DLINEAR = 6
local TB_ANN_TRF_ZSIGMOID = 7
local TB_ANN_TRF_DSIGMOID = 8
local TB_ANN_TRF_TIMEMACHINE = 9
local TB_ANN_TRF_TANH = 10
local TB_ANN_TRF_RELU = 11
local TB_ANN_TRF_LRELU = 12
local TB_ANN_TRF_ELU = 13
local TB_ANN_TRF_SOFTMAX = 14

local invtrf_map = {
  [TB_ANN_TRF_SSIGMOID]= "SSIGMOID",
  [TB_ANN_TRF_LSIGMOID]= "LSIGMOID",
  [TB_ANN_TRF_MSIGMOID]= "MSIGMOID",
  [TB_ANN_TRF_AGAUSSIAN]= "AGAUSSIAN",
  [TB_ANN_TRF_LINEAR]= "LINEAR",
  [TB_ANN_TRF_DLINEAR]= "DLINEAR",
  [TB_ANN_TRF_ZSIGMOID]= "ZSIGMOID",
  [TB_ANN_TRF_DSIGMOID]= "DSIGMOID",
  [TB_ANN_TRF_TIMEMACHINE]= "TIMEMACHINE",
  [TB_ANN_TRF_TANH]= "TANH",
  [TB_ANN_TRF_RELU]= "RELU",
  [TB_ANN_TRF_LRELU]= "LRELU",
  [TB_ANN_TRF_ELU]= "ELU",
  [TB_ANN_TRF_SOFTMAX]= "SOFTMAX"
} 

TBann.trfname = function(xann,k)
  assert(xann)
  assert(k,"\nError: #arg 2 is an integer index (required)\n")
  local id = xann:trf(k)
  local name = invtrf_map[id]
  return name
end
