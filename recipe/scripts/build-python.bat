setlocal EnableDelayedExpansion

:: We need to clean previous build as space is too low on runners
rmdir /s /q build

mkdir build
cd build

::Configure
cmake ^
    %CMAKE_ARGS% .. ^
    %SRC_DIR% ^
    -G Ninja ^
    -DCMAKE_BUILD_TYPE:STRING=Release ^
    -DVISP_PYTHON_SKIP_DETECTION=OFF ^
    -DBUILD_PYTHON_BINDINGS=ON ^
    -DBUILD_TESTS=ON ^
    -DGENERATE_PYTHON_STUBS=ON ^
    -DPython3_ROOT_DIR:PATH=%PREFIX% ^
    -DPython3_EXECUTABLE:PATH="%PREFIX%\python.exe" ^
    -DVISP_LIB_INSTALL_PATH:PATH="lib" ^
    -DVISP_BIN_INSTALL_PATH:PATH="bin" ^
    -DVISP_CONFIG_INSTALL_PATH:PATH="lib\cmake\VISP"
if errorlevel 1 exit 1

:: build python bidings
cmake --build . --parallel "%CPU_COUNT%" --target visp_python_bindings
if errorlevel 1 exit 1
