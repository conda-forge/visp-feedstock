setlocal EnableDelayedExpansion

:: We need to clean previous build as space is too low on runners
rm -rf build
cd build
mkdir build

set "CC=clang-cl.exe"
set "CXX=clang-cl.exe"
set "CL=/MP"


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
    -DVISP_CONFIG_INSTALL_PATH:PATH="lib\cmake\VISP"
if errorlevel 1 exit 1

:: build python bidings
cmake --build . --parallel "%CPU_COUNT%" --target visp_python_bindings
if errorlevel 1 exit 1

:: Install python bindings
cd modules\python\bindings
%PYTHON% -m pip install . -vv --no-deps --no-build-isolation --ignore-installed .

:: and stubs
cd ..\stubs
%PYTHON% -m pip install . -vv --no-deps --no-build-isolation --ignore-installed .
