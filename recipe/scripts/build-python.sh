#!/bin/sh

set -ex

if [[ $target_platform == osx* ]] ; then
    # Dealing with modern C++ for Darwin in embedded catch library.
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

# We need to clean previous build as space is too low on runners
rm -rf build
mkdir build
cd build


export GENERATE_PYTHON_STUBS=1
if [[ $CONDA_BUILD_CROSS_COMPILATION == 1 ]]; then
  export GENERATE_PYTHON_STUBS=0
fi

# We have to force CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH to False, otherwise
# it is set to some system paths such as the base conda environment, and 
# some dependencies can be detected outside active conda environment is they are not
# used for this recipe (such as nlohmann_json), as they are installed in the conda base env
cmake ${CMAKE_ARGS} .. \
      -G Ninja \
      -DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=FALSE \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DVISP_PYTHON_SKIP_DETECTION=OFF \
      -DPython3_ROOT_DIR:PATH=${PREFIX} \
      -DPython3_EXECUTABLE:PATH=${PREFIX}/bin/python \
      -DBUILD_PYTHON_BINDINGS=ON \
      -DGENERATE_PYTHON_STUBS=${GENERATE_PYTHON_STUBS} \
      -DBUILD_TESTS=ON

# build
cmake --build . --parallel ${CPU_COUNT} --target visp_python_bindings

# Install python bindings
cd modules/python/bindings
${PYTHON} -m pip install . -vv --no-deps --no-build-isolation --ignore-installed .

# and stubs
# Can't generate the stubs when cross-compiling since stubs generation needs 
# to import the built binary which is built for target platform
# echo "================================="
# echo "CONDA_BUILD_CROSS_COMPILATION = ${CONDA_BUILD_CROSS_COMPILATION}"
# if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" ]]; then
#   echo "========== Cross compiling if OFF, building stubs..."
#   cd ../stubs
#   ${PYTHON} -m pip install . -vv --no-deps --no-build-isolation --ignore-installed .
# else
#   echo "========== Cross compiling if ON, skipping stubs..."
# fi
