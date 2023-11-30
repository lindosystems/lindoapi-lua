#!/bin/bash
PLATFORM=$1
UNAME=`uname`
MNAME=`uname -m`
CURPATH=$(pwd)

if [ "${PLATFORM}" != "" ]; then
    echo PLATFORM specified: $PLATFORM
elif [ "${UNAME:0:6}" = "CYGWIN" ]; then
    PLATFORM=win32x86
    CURPATH=$(cygpath -w $CURPATH)
elif [ "${UNAME:0:7}" = "MINGW64" ]; then
    PLATFORM=win64x86   
    CURPATH=$(cygpath -w $CURPATH)    
elif [ "${UNAME:0:7}" = "MINGW32" ]; then
    PLATFORM=win32x86
    CURPATH=$(cygpath -w $CURPATH)
elif [ "${UNAME:0:7}" = "MSYS_NT" ]; then
    PLATFORM=win32x86   
    CURPATH=$(cygpath -w $CURPATH)
elif [ "${UNAME}" = "Linux" ]; then
    PLATFORM=linux64x86
elif [ "${UNAME}" = "Darwin" ]; then
    PLATFORM=osx64x86
    #if [ "${MNAME}" = "arm64" ]; then
    #   PLATFORM=osx64arm
    #fi
fi
if [ ! -z $TABOX_HOME ]; then
    remove_path $TABOX_HOME/bin/$PLATFORM 
fi
export PATH=$CURPATH/lib/$PLATFORM/systree/lib/lua/5.1:$PATH
export LUA_PATH="./?.lua;./share/lua/5.1/?.lua;./share/lua/5.1/?/init.lua"
export LUA_CPATH="$CURPATH/lib/$PLATFORM/systree/lib/lua/5.1/?.dll;$CURPATH/lib/$PLATFORM/systree/lib/lua/5.1/?.so;$CURPATH/lib/$PLATFORM/systree/lib/lua/5.1/?.dylib"


