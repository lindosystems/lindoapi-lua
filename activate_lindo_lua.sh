#!/bin/bash
PLATFORM=$1
UNAME=`uname`
MNAME=`uname -m`
CURPATH=$(pwd)

if [ "${PLATFORM}" != "" ]; then
	echo PLATFORM specified: $PLATFORM
elif [ "${UNAME:0:6}" = "CYGWIN" ]; then
	PLATFORM=win32x86
    TABOX_HOME=$(cygpath $TABOX_HOME)
    CURPATH=$(cygpath -w $CURPATH)
elif [ "${UNAME:0:7}" = "MINGW64" ]; then
	PLATFORM=win64x86	
	TABOX_HOME=$(cygpath $TABOX_HOME)
    CURPATH=$(cygpath -w $CURPATH)
elif [ "${UNAME:0:7}" = "MINGW32" ]; then
	PLATFORM=win32x86
	TABOX_HOME=$(cygpath $TABOX_HOME)
    CURPATH=$(cygpath -w $CURPATH)
elif [ "${UNAME:0:7}" = "MSYS_NT" ]; then
	PLATFORM=win32x86	
	TABOX_HOME=$(cygpath -w $TABOX_HOME)
    CURPATH=$(cygpath -w $CURPATH)
elif [ "${UNAME}" = "Linux" ]; then
	PLATFORM=linux64x86
elif [ "${UNAME}" = "Darwin" ]; then
	PLATFORM=osx64x86
	#if [ "${MNAME}" = "arm64" ]; then
	#	PLATFORM=osx64arm
	#fi
fi
source ${TABOX_HOME}/bin/${PLATFORM}/taboxvars.sh
export PATH=$TABOX_HOME/bin/$PLATFORM:$PATH
export LUA_PATH="./?.lua;$CURPATH/systree/share/lua/5.1/?.lua;$CURPATH/systree/share/lua/5.1/?/init.lua"
export LUA_CPATH="$CURPATH/systree/lib/lua/5.1/?.dll;$CURPATH/systree/lib/lua/5.1/?.so;$CURPATH/systree/lib/lua/5.1/?.dylib"
export TABOX_LICENSE_FILE=$TABOX_HOME/license/tabox.lic

