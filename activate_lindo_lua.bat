@echo off

rem Check for LINDOAPI_HOME and LINDOAPI_LICENSE_FILE variables
if not defined LINDOAPI_HOME (
    echo LINDOAPI_HOME is not set. Please set the LINDOAPI_HOME environment variable.    
    exit /b 1
)
if exist "%LINDOAPI_HOME%\bin\lindoapivars.bat" (
    @call "%LINDOAPI_HOME%\bin\lindoapivars.bat"
) else (
    echo %LINDOAPI_HOME%\bin\lindoapivars.bat does not exist in the specified directory. Please check the installation of LINDO API.
    exit /b 1
)

if not defined LINDOAPI_LICENSE_FILE (
    echo LINDOAPI_LICENSE_FILE is not set. Please check the installation of LINDO API.
    echo Or run "/path/to/lindoapi/bin/lindoapivars.bat" from command prompt
    exit /b 1
)

if "%PLATFORM%"=="" (
    if exist "%LINDOAPI_HOME%\bin\win32" (
        set "PLATFORM=win32x86"
    ) else (
        if exist "%LINDOAPI_HOME%\bin\win64" (
            set "PLATFORM=win64x86"
        ) else (
            echo Unable to determine the platform. Please check the installation of LINDO API.
            exit /b 1
        )
    )
)
REM Add x86 suffix if missing
if "%PLATFORM%"=="win32" set "PLATFORM=win32x86"
if "%PLATFORM%"=="win64" set "PLATFORM=win64x86"

set "CURPATH=%~dp0"
set LUA_PATH=.\?.lua;%CURPATH%\share\lua\5.1\?.lua;%CURPATH%\share\lua\5.1\?\init.lua;%LUA_PATH%
set LUA_CPATH=%CURPATH%\lib\%PLATFORM%\systree\lib\lua\5.1\?.dll
set PATH=%PATH%;%CURPATH%\lib\%PLATFORM%\systree\lib\lua\5.1
