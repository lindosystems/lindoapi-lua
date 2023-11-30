@echo off
set PLATFORM=%1
if %PLATFORM%=="" set PLATFORM=win32x86

set "CURPATH=%~dp0"
set LUA_PATH=.\?.lua;%CURPATH%\share\lua\5.1\?.lua;%CURPATH%\share\lua\5.1\?\init.lua;%LUA_PATH%
set LUA_CPATH=%CURPATH%\lib\%PLATFORM%\systree\lib\lua\5.1\?.dll

