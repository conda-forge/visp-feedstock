setlocal EnableDelayedExpansion

cd build

set "CC=clang-cl.exe"
set "CXX=clang-cl.exe"
set "CL=/MP"

:: rattler-build restricts the use of pip, but in ViSP pip is called
:: through cmake to create/install the python bindings generator. So
:: temporarly change this settings for the build.
set PIP_NO_INDEX=False
set PIP_NO_DEPENDENCIES=False

::Configure
cmake ^
    %CMAKE_ARGS% .. ^
    %SRC_DIR% ^
    -G Ninja ^
    -DCMAKE_BUILD_TYPE:STRING=Release ^
    -DVISP_PYTHON_SKIP_DETECTION=OFF ^
    -DBUILD_PYTHON_BINDINGS=ON ^
    -DBUILD_TESTS=ON ^
    -DVISP_LIB_INSTALL_PATH:PATH="lib" ^
    -DVISP_BIN_INSTALL_PATH:PATH="bin" ^
    -DVISP_CONFIG_INSTALL_PATH:PATH="cmake"    
if errorlevel 1 exit 1

:: build python bidings
cmake --build . --parallel "%CPU_COUNT%" --target visp_python_bindings
if errorlevel 1 exit 1

:: Restore rattler-build pip restrictions
set PIP_NO_INDEX=True
set PIP_NO_DEPENDENCIES=True

:: Install python bindings
cd modules\python\bindings
%PYTHON% -m pip install . -vv --no-deps --no-build-isolation --ignore-installed .

:: and stubs
cd ..\stubs
%PYTHON% -m pip install . -vv --no-deps --no-build-isolation --ignore-installed .
