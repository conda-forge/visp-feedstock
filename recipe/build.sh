#!/bin/sh

set -ex

if [[ $target_platform == osx* ]] ; then
    # Dealing with modern C++ for Darwin in embedded catch library.
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

mkdir build
cd build

cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DVISP_PYTHON_SKIP_DETECTION=ON \
      -DBUILD_TESTS=ON

# build
cmake --build . --parallel ${CPU_COUNT}

# install 
cmake --build . --parallel ${CPU_COUNT} --target install

# test
if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
  ctest --progress --output-on-failure
fi