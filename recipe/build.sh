#!/bin/sh

set -ex

if [[ $target_platform == osx* ]] ; then
    # Dealing with modern C++ for Darwin in embedded catch library.
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

    # Workaround for https://github.com/conda-forge/tk-feedstock/issues/15
    # export X11_PATH=$PREFIX/include/X11
    # export X11_ALIAS_PATH=$PREFIX/include/tk_X11
    # mv $X11_PATH $X11_ALIAS_PATH
fi

mkdir build
cd build

cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_TESTS=ON

# build
cmake --build . --parallel ${CPU_COUNT}

# install 
cmake --build . --parallel ${CPU_COUNT} --target install

# test
ctest --parallel ${CPU_COUNT}

if [[ $target_platform == osx* ]] ; then
    # Restore the fix
    # mv $X11_ALIAS_PATH $X11_PATH
fi