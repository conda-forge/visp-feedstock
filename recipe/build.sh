#!/bin/sh

set -ex

# debugging X11 headers
echo "-------- BEFORE -------"
echo "----------------------------"
cat ${PREFIX}/include/X11/Xlib.h
echo "----------------------------"

if [[ $target_platform == osx* ]] ; then
    # Dealing with modern C++ for Darwin in embedded catch library.
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

    # Workaround for https://github.com/conda-forge/tk-feedstock/issues/15
    #  In MacOS, `tk` ships some X11 headers that interfere with the X11 libraries
    # Taken from https://github.com/conda-forge/isce2-feedstock/blob/a3c25f04af4fc831eafe76f6b931514b4fdc5b4c/recipe/build.sh#L6
    # Force reinstall these to (un)clobber any broken headers
    conda install -p ${PREFIX} -c conda-forge \
        xorg-xproto \
        xorg-libxfixes \
        xorg-libx11 \
        --yes --clobber --force-reinstall
    # these enable the declaration of some X function missings in TK embedded Xlib.h, but not all that visp 
    # is using
    CXXFLAGS="${CXXFLAGS} -DMAC_OSX_TK=1"
fi

# debugging X11 headers
echo "-------- AFTER -------"
echo "----------------------------"
cat ${PREFIX}/include/X11/Xlib.h
echo "----------------------------"

mkdir build
cd build

cmake ${CMAKE_ARGS} .. \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DVISP_PYTHON_SKIP_DETECTION=ON \
      -DBUILD_TESTS=ON

# debugging X11 headers
echo "-------- cat CMakeCache.txt -------"
echo "----------------------------"
cat CMakeCache.txt
echo "----------------------------"

# build
cmake --build . --parallel ${CPU_COUNT}

# install 
cmake --build . --parallel ${CPU_COUNT} --target install

# test
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
  ctest --progress --output-on-failure
fi