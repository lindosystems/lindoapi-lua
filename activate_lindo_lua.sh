#!/bin/bash
PLATFORM=$1
UNAME=`uname`
MNAME=`uname -m`
CURPATH=$(pwd)

if [ "${TABOX_HOME}" = "" ]; then
    echo "TABOX_HOME variable is not defined!"
    exit 1
fi

if [ "${PLATFORM}" != "" ]; then
    echo PLATFORM specified: $PLATFORM
elif [ "${UNAME:0:6}" = "CYGWIN" ]; then
    PLATFORM=win32x86
    TABOX_HOME=$(cygpath $TABOX_HOME)
    CURPATH=$(cygpath -w $CURPATH)
    TABOX_LICENSE_FILE=$(cygpath -w $TABOX_HOME/license/tabox.lic)
elif [ "${UNAME:0:7}" = "MINGW64" ]; then
    PLATFORM=win64x86   
    TABOX_HOME=$(cygpath $TABOX_HOME)
    CURPATH=$(cygpath -w $CURPATH)
    TABOX_LICENSE_FILE=$(cygpath -w $TABOX_HOME/license/tabox.lic)
elif [ "${UNAME:0:7}" = "MINGW32" ]; then
    PLATFORM=win32x86
    TABOX_HOME=$(cygpath $TABOX_HOME)
    CURPATH=$(cygpath -w $CURPATH)
    TABOX_LICENSE_FILE=$(cygpath -w $TABOX_HOME/license/tabox.lic)
elif [ "${UNAME:0:7}" = "MSYS_NT" ]; then
    PLATFORM=win32x86   
    TABOX_HOME=$(cygpath -w $TABOX_HOME)
    CURPATH=$(cygpath -w $CURPATH)
    TABOX_LICENSE_FILE=$(cygpath -w $TABOX_HOME/license/tabox.lic)
elif [ "${UNAME}" = "Linux" ]; then
    PLATFORM=linux64x86
    TABOX_LICENSE_FILE=$TABOX_HOME/license/tabox.lic
elif [ "${UNAME}" = "Darwin" ]; then
    PLATFORM=osx64x86
    TABOX_LICENSE_FILE=$TABOX_HOME/license/tabox.lic
    #if [ "${MNAME}" = "arm64" ]; then
    #   PLATFORM=osx64arm
    #fi
fi
export TABOX_LICENSE_FILE
remove_path /c/dev/c/tabox/trunk/bin/$PLATFORM 
export PATH=$CURPATH/lib/$PLATFORM/systree/lib/lua/5.1:$PATH
export LUA_PATH="./?.lua;./share/lua/5.1/?.lua;./share/lua/5.1/?/init.lua"
export LUA_CPATH="$CURPATH/lib/$PLATFORM/systree/lib/lua/5.1/?.dll;$CURPATH/lib/$PLATFORM/systree/lib/lua/5.1/?.so;$CURPATH/lib/$PLATFORM/systree/lib/lua/5.1/?.dylib"


