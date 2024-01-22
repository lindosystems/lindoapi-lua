#!/bin/bash
lslua rpc-client.lua --createEnv
lslua rpc-client.lua --createModel
lslua rpc-client.lua --showModels
lslua rpc-client.lua --loadLPData
lslua rpc-client.lua --getInfo=LS_IINFO_NUM_VARS
lslua rpc-client.lua --getInfo=LS_IINFO_NUM_CONS
lslua rpc-client.lua --optimize=0
lslua rpc-client.lua --showModels
#lslua rpc-client.lua --loadLPData=c\:/tmp/prob/netlib/agg3.mps --szModel=0x008AB718
#lslua rpc-client.lua --readMPSFile=c\:/tmp/prob/netlib/agg3.mps --szModel=0x008AB718
#lslua rpc-client.lua --mpsfile=c\:/tmp/prob/netlib/agg3.mps --szModel=0x008AB718 --loadLPData
#lslua rpc-client.lua --mpsfile=c\:/tmp/prob/netlib/agg3.mps --szModel=0x008AB718 --loadLPData
#lslua rpc-client.lua -q
