#!/bin/sh

set -ex

cd build

# rattler-build restricts the use of pip, but in ViSP pip is called
# through cmake to create/install the python bindings generator. So
# temporarly change this settings for the build.
export PIP_NO_INDEX=False
export PIP_NO_DEPENDENCIES=False

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
      -DBUILD_PYTHON_BINDINGS=ON \
      -DBUILD_TESTS=ON

# build
cmake --build . --parallel ${CPU_COUNT} --target visp_python_bindings

# Restore rattler-build pip restrictions
export PIP_NO_INDEX=True
export PIP_NO_DEPENDENCIES=True

# Install python bindings
cd modules/python/bindings
${PYTHON} -m pip install . -vv --no-deps --no-build-isolation --ignore-installed .

# and stubs
cd ../stubs
${PYTHON} -m pip install . -vv --no-deps --no-build-isolation --ignore-installed .
