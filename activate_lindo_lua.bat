@echo off
set LUADIR=C:\usr2\Lua
@call %LUADIR%\luadirs.bat
set PATH=%LUADIR%\bin;%PATH%

rem LuaRocks;
set PATH=c:\usr2\Lua\luarocks;%PATH%
set LUA_PATH=c:\usr2\Lua\luarocks\lua\?.lua;c:\usr2\Lua\luarocks\lua\?\init.lua;%LUA_PATH%

rem Local user rocktree (Note: %APPDATA% is user dependent);
rem  PATH     :   %APPDATA%\LuaRocks\bin
rem  LUA_PATH :   %APPDATA%\LuaRocks\share\lua\5.1\?.lua;%APPDATA%\LuaRocks\share\lua\5.1\?\init.lua
rem  LUA_CPATH:   %APPDATA%\LuaRocks\lib\lua\5.1\?.dll

rem System rocktree
rem set PATH=c:\usr2\Lua\luarocks\systree\bin;%PATH%;C:\usr\Qt\4.7.4\bin
rem set LUA_PATH=.\?.lua;c:\usr2\Lua\luarocks\systree\share\lua\5.1\?.lua;c:\usr2\Lua\luarocks\systree\share\lua\5.1\?\init.lua;%LUA_PATH%
rem set LUA_CPATH=c:\usr2\Lua\luarocks\systree\lib\lua\5.1\?.dll

set "CURPATH=%~dp0"
set LUA_PATH=%CURPATH%\systree\share\lua\5.1\?.lua;%CURPATH%\systree\share\lua\5.1\?\init.lua;%LUA_PATH%
set LUA_CPATH=%CURPATH%\systree\lib\lua\5.1\?.dll

set TABOX_LICENSE_FILE=%TABOX_HOME%\license\tabox.lic
rem echo %TABOX_LICENSE_FILE%

rem Note that the %APPDATA% element in the paths above is user specific and it MUST be replaced by its actual value.
rem For the current user that value is: C:\Users\mka\AppData\Roaming.
set PLATFORM=win32x86
@echo Set variable PLATFORM=%PLATFORM% (by %0)
setenv-vcpkg-x86
