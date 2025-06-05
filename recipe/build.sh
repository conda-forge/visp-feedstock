#!/bin/sh

set -ex

if [[ $target_platform == osx* ]] ; then
    # Dealing with modern C++ for Darwin in embedded catch library.
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

    # Workaround for https://github.com/conda-forge/tk-feedstock/issues/15

    #  In MacOS, `tk` ships some X11 headers that interfere with the X11 libraries
    # Taken from https://github.com/conda-forge/isce2-feedstock/blob/a3c25f04af4fc831eafe76f6b931514b4fdc5b4c/recipe/build.sh#L6
    # Force reinstall these to (un)clobber any broken headers
    conda install -p ${PREFIX} -c conda-forge \
        xorg-xorgproto \
        xorg-libxfixes \
        xorg-libx11 \
        --yes --clobber --force-reinstall
fi

mkdir build
cd build

# We have to force CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH to False, otherwise
# it is set to some system paths such as the base conda environment, and 
# some dependencies can be detected outside active conda environment is they are not
# used for this recipe (such as nlohmann_json), as they are installed in the conda base env
cmake ${CMAKE_ARGS} .. \
      -G Ninja \
      -DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=FALSE \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DVISP_PYTHON_SKIP_DETECTION=ON \
      -DBUILD_TESTS=ON

# build
cmake --build . --parallel ${CPU_COUNT}

# install 
cmake --build . --parallel ${CPU_COUNT} --target install

# test
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
  ctest --progress --output-on-failure
fi
