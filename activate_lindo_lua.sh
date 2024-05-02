#!/bin/bash
UNAME=`uname`
MNAME=`uname -m`
CURPATH=$(pwd)

# Check for LINDOAPI_HOME and LINDOAPI_LICENSE_FILE variables
if [ -z "$LINDOAPI_HOME" ]; then
  echo "LINDOAPI_HOME is not set. Please set the LINDOAPI_HOME environment variable."
  return 1
fi
if [ "$1" = "win32" -o  "$1" = "32" -o  "$1" = "win32x86" ]; then
	export PLATFORM=win32
fi	
# Set LINDO API environment and PLATFORM
source $LINDOAPI_HOME/bin/lindoapivars.sh

if [ -z "$LINDOAPI_LICENSE_FILE" ]; then
  echo "LINDOAPI_LICENSE_FILE is not set. Please check the installation of LINDO API."
  return 1
fi
if is_cygwin; then
	LINDOAPI_LICENSE_FILE=$(cygpath -w $LINDOAPI_LICENSE_FILE)
fi

# Use the correct library for the platform
if [ "${UNAME}" = "Darwin" ]; then
  export XTASOLVER_LINDO_LIB=$LINDOAPI_HOME/bin/$PLATFORM/liblindo64.dylib
fi

# Patch names from lindoapivars.sh
if [ "$PLATFORM" == "win32" ]; then
  PLATFORM="win32x86"
fi

if [ "$PLATFORM" == "win64" ]; then
  PLATFORM="win64x86"
fi

if [ "$PLATFORM" == "linux64" ]; then
  PLATFORM="linux64x86"
fi

if [ ! -z $TABOX_HOME ]; then
    remove_path $TABOX_HOME/bin/$PLATFORM 
fi
export PATH=$CURPATH/lib/$PLATFORM/systree/lib/lua/5.1:$PATH
if [ "${UNAME}" = "Darwin" ]; then
    export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$LINDOAPI_HOME/bin/$PLATFORM:$CURPATH/lib/$PLATFORM/systree/lib/lua/5.1
else
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LINDOAPI_HOME/bin/$PLATFORM:$CURPATH/lib/$PLATFORM/systree/lib/lua/5.1
fi    
export LUA_PATH="./?.lua;./share/lua/5.1/?.lua;./share/lua/5.1/?/init.lua"
export LUA_CPATH="$CURPATH/lib/$PLATFORM/systree/lib/lua/5.1/?.dll;$CURPATH/lib/$PLATFORM/systree/lib/lua/5.1/?.so;$CURPATH/lib/$PLATFORM/systree/lib/lua/5.1/?.dylib"


