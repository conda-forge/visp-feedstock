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

    # Taken from https://github.com/conda-forge/ambertools-feedstock/blob/2ccbcde9a96c90da31ed199e64c33a4e5f64695c/recipe/build.sh#L40-L51
    #  In MacOS, `tk` ships some X11 headers that interfere with the X11 libraries
    #  1) delete clobbered X11 headers (mix of tk and xorg)

    # rm -rf ${PREFIX}/include/X11/{DECkeysym,HPkeysym,Sunkeysym,X,XF86keysym,Xatom,Xfuncproto}.h
    # rm -rf ${PREFIX}/include/X11/{ap_keysym,keysym,keysymdef,Xlib,Xutil,cursorfont}.h
    # #  2) Reinstall Xorg dependencies
    # #     We temporarily disable the (de)activation scripts because they fail otherwise
    # mv ${BUILD_PREFIX}/etc/conda/{activate.d,activate.d.bak}
    # mv ${BUILD_PREFIX}/etc/conda/{deactivate.d,deactivate.d.bak}
    # # Using rattler-build does not keep the conda-meta/history file,
    # # making impossible to perform the conda install command that follows.
    # # We fake it by creating an empty conda-meta/history.
    # touch ${PREFIX}/conda-meta/history
    # CONDA_SUBDIR="$target_platform" conda install --yes --no-deps --force-reinstall -p ${PREFIX} xorg-xorgproto xorg-libx11 xorg-libxfixes
    # mv ${BUILD_PREFIX}/etc/conda/{activate.d.bak,activate.d}
    # mv ${BUILD_PREFIX}/etc/conda/{deactivate.d.bak,deactivate.d}

    #  In MacOS, `tk` ships some X11 headers that interfere with the X11 libraries
    # Taken from https://github.com/conda-forge/isce2-feedstock/blob/a3c25f04af4fc831eafe76f6b931514b4fdc5b4c/recipe/build.sh#L6
    # Force reinstall these to (un)clobber any broken headers
    conda install -p ${PREFIX} -c conda-forge \
        xorg-xorgproto \
        xorg-libxfixes \
        xorg-libx11 \
        --yes --clobber --force-reinstall
    # these enable the declaration of some X function missings in TK embedded Xlib.h, but not all that visp 
    # is using
    # CXXFLAGS="${CXXFLAGS} -DMAC_OSX_TK=1"
fi
# echo "-------- find xlib -------"
# echo "----------------------------"
# find / -name "Xlib.h" 2>/dev/null 
# echo "----------------------------"


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

make developer_scripts

./bin/visp-config --cflags

# build
cmake --build . --parallel ${CPU_COUNT}

# install 
cmake --build . --parallel ${CPU_COUNT} --target install

# test
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
  ctest --progress --output-on-failure
fi