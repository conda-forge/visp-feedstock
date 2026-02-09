setlocal EnableDelayedExpansion

mkdir build
cd build

:: Hints OGRE to find its CMake module file
set "OGRE_DIR=%LIBRARY_PREFIX%\cmake"

set "LAPACK_DIR=%LIBRARY_PREFIX%"

::Configure
cmake ^
    %CMAKE_ARGS% ^
    %SRC_DIR% ^
    -G Ninja ^
    -DBUILD_TESTS=ON ^
    -DOGRE_DIR="%OGRE_DIR%" ^
    -DCMAKE_BUILD_TYPE:STRING=Release ^
    -DVISP_LIB_INSTALL_PATH:PATH="lib" ^
    -DVISP_BIN_INSTALL_PATH:PATH="bin" ^
    -DVISP_CONFIG_INSTALL_PATH:PATH="lib\cmake\VISP"
if errorlevel 1 exit 1

:: Build.
cmake --build . --parallel "%CPU_COUNT%"
if errorlevel 1 exit 1

:: Install.
cmake --build . --parallel "%CPU_COUNT%" --target install
if errorlevel 1 exit 1

:: The visp-config batch file will be used for testing the recipe, so
:: we have to make it accessible without knowledge on the current compiler
:: version (as VS_xxx environment variables are not accessible within the test section
:: of the recipe)
copy %LIBRARY_PREFIX%\bin\visp-config*.bat %LIBRARY_PREFIX%\bin\visp-config.bat

:: Test
ctest --parallel "%CPU_COUNT%"
if errorlevel 1 exit 1