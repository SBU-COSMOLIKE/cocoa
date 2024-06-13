# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
echo -e '\033[1;45m''SETUP COCOA INSTALLATION PACKAGES''\033[0m'

if [ -n "${ROOTDIR}" ]; then
    source stop_cocoa
fi

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ------------------------------ Basic Settings ------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------

function addvar () {
    local tmp="${!1}" ;
    tmp="${tmp//:${2}:/:}" ;
    tmp="${tmp/#${2}:/}" ;
    tmp="${tmp/%:${2}/}" ;
    export $1="${2}:${tmp}" ;
}

if [ -n "${OMP_NUM_THREADS}" ]; then
    export OLD_OMP_NUM_THREADS=$OMP_NUM_THREADS
else
    export OLD_OMP_NUM_THREADS="x"
fi

if [ -n "${LD_LIBRARY_PATH}" ]; then
    export OLD_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
else
    export OLD_LD_LIBRARY_PATH="x"
fi

if [ -n "${PYTHONPATH}" ]; then
    export OLD_PYTHONPATH=$PYTHONPATH
else
    export OLD_PYTHONPATH="x"
fi

if [ -n "${PATH}" ]; then
    export OLD_PATH=$PATH
else
    export OLD_PATH="x"
fi

if [ -n "${C_INCLUDE_PATH}" ]; then
    export OLD_C_INCLUDE_PATH=$C_INCLUDE_PATH
else
    export OLD_C_INCLUDE_PATH="x"
fi

if [ -n "${CPLUS_INCLUDE_PATH}" ]; then
    export OLD_CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH
else
    export OLD_CPLUS_INCLUDE_PATH="x"
fi

if [ -n "${LDFLAGS}" ]; then
    export OLD_LDFLAGS=$LDFLAGS
else
    export OLD_LDFLAGS="x"
fi

if [ -n "${CPATH}" ]; then
    export OLD_CPATH=$CPATH
else
    export OLD_CPATH="x"
fi

if [ -n "${LD_RUN_PATH}" ]; then
    export OLD_LD_RUN_PATH=$LD_RUN_PATH
else
    export OLD_LD_RUN_PATH="x"
fi

if [ -n "${CMAKE_LIBRARY_PATH}" ]; then
    export OLD_CMAKE_LIBRARY_PATH=$CMAKE_LIBRARY_PATH
else
    export OLD_CMAKE_LIBRARY_PATH="x"
fi

if [ -n "${CMAKE_INCLUDE_PATH}" ]; then
    export OLD_CMAKE_INCLUDE_PATH=$CMAKE_INCLUDE_PATH
else
    export OLD_CMAKE_INCLUDE_PATH="x"
fi

if [ -n "${LIBRARY_PATH}" ]; then
    export OLD_LIBRARY_PATH=$LIBRARY_PATH
else
    export OLD_LIBRARY_PATH="x"
fi

if [ -n "${INCLUDEPATH}" ]; then
    export OLD_INCLUDEPATH=$INCLUDEPATH
else
    export OLD_INCLUDEPATH="x"
fi

if [ -n "${INCLUDE}" ]; then
    export OLD_INCLUDE=$INCLUDE
else
    export OLD_INCLUDE="x"
fi

if [ -n "${CPATH}" ]; then
    export OLD_CPATH=$CPATH
else
    export OLD_CPATH="x"
fi

if [ -n "${NUMPY_HEADERS}" ]; then
    export OLD_NUMPY_HEADERS=$NUMPY_HEADERS
else
    export OLD_NUMPY_HEADERS="x"
fi

if [ -n "${OBJC_INCLUDE_PATH}" ]; then
    export OLD_OBJC_INCLUDE_PATH=$OBJC_INCLUDE_PATH
else
    export OLD_OBJC_INCLUDE_PATH="x"
fi

if [ -n "${OBJC_PATH}" ]; then
    export OLD_OBJC_PATH=$OBJC_PATH
else
    export OLD_OBJC_PATH="x"
fi

if [ -n "${CFLAGS}" ]; then
    export OLD_CFLAGS=$CFLAGS
else
    export OLD_CFLAGS="x"
fi

if [ -n "${INCLUDE_PATH}" ]; then
    export OLD_INCLUDE_PATH=$INCLUDE_PATH
else
    export OLD_INCLUDE_PATH="x"
fi

if [ -n "${SET_INSTALLATION_OPTIONS}" ]; then
    source $SET_INSTALLATION_OPTIONS
else
    source set_installation_options
fi

# BASIC TEST IF A CONDA ENV IS ACTIVATED
if [ -n "${MINICONDA_INSTALLATION}" ]; then
  if [ -z ${CONDA_PREFIX} ]; then
    echo -e '\033[0;31m'"MINICONDA_INSTALLATION SET BUT CONDA ENVIRONMENT NOT ACTIVATED"'\033[0m'
    source stop_cocoa
    return 1
  fi
fi

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ---------------------- Activate Virtual Environment ------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
cd $ROOTDIR/../

if [ -n "${DONT_USE_SYSTEM_PIP_PACKAGES}" ]; then
    $GLOBALPYTHON3 -m venv $ROOTDIR/.local/
else
    $GLOBALPYTHON3 -m venv $ROOTDIR/.local/ --system-site-packages
fi

cd $ROOTDIR

source $ROOTDIR/.local/bin/activate

export PATH=$ROOTDIR/.local/bin:$PATH

export CFLAGS="${CFLAGS} -I$ROOTDIR/.local/lib/python$PYTHON_VERSION/site-packages/numpy/core/include"

export LDFLAGS="${LDFLAGS} -L$ROOTDIR/.local/lib"

export C_INCLUDE_PATH=$C_INCLUDE_PATH:$ROOTDIR/.local/lib/python$PYTHON_VERSION/site-packages/numpy/core/include

export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:$ROOTDIR/.local/lib/python$PYTHON_VERSION/site-packages/numpy/core/include

export PYTHONPATH=$ROOTDIR/.local/lib/python$PYTHON_VERSION/site-packages:$PYTHONPATH
export PYTHONPATH=$ROOTDIR/.local/lib:$PYTHONPATH

export LD_RUN_PATH=$ROOTDIR/.local/lib:$LD_RUN_PATH

export LIBRARY_PATH=$ROOTDIR/.local/lib:$LIBRARY_PATH

export CMAKE_INCLUDE_PATH=$ROOTDIR/.local/include/python${PYTHON_VERSION}m/:$CMAKE_INCLUDE_PATH
export CMAKE_INCLUDE_PATH=$ROOTDIR/.local/include/:$CMAKE_INCLUDE_PATH    

export CMAKE_LIBRARY_PATH=$ROOTDIR/.local/lib/python$PYTHON_VERSION/site-packages:$CMAKE_LIBRARY_PATH
export CMAKE_LIBRARY_PATH=$ROOTDIR/.local/lib:$CMAKE_LIBRARY_PATH

export INCLUDE_PATH=$ROOTDIR/.local/include/:$INCLUDE_PATH

export INCLUDEPATH=$ROOTDIR/.local/include/:$INCLUDEPATH

export INCLUDE=$ROOTDIR/.local/include/:$INCLUDE

export CPATH=$ROOTDIR/.local/lib/python$PYTHON_VERSION/site-packages/numpy/core/include:$CPATH
export CPATH=$ROOTDIR/.local/include/:$CPATH

export OBJC_INCLUDE_PATH=$ROOTDIR/.local/:OBJC_INCLUDE_PATH

export OBJC_PATH=$ROOTDIR/.local/:OBJC_PATH

export LD_LIBRARY_PATH=$ROOTDIR/.local/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$ROOTDIR/.local/lib/python$PYTHON_VERSION/site-packages/numpy/core/lib:$LD_LIBRARY_PATH

export NUMPY_HEADERS=$ROOTDIR/.local/lib/python$PYTHON_VERSION/site-packages/numpy/core/include

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------

if [ -z "${MINICONDA_INSTALLATION}" ]; then
  source $ROOTDIR/installation_scripts/setup_xz.sh
  if [ $? -ne 0 ]; then
    echo  -e '\033[0;31m'"SCRIPT setup_xz FAILED"'\033[0m'
    cd $ROOTDIR
    source stop_cocoa
    return 1
  fi
fi

source ./installation_scripts/setup_installation_libraries.sh
if [ $? -ne 0 ]; then
  echo  -e '\033[0;31m'"SCRIPT setup_intallation_libraries FAILED"'\033[0m'
  cd $ROOTDIR
  source stop_cocoa
  return 1
fi
  
if [ -z "${DEBUG_SKIP_FILE_DECOMPRESSION_SETUP_COCOA}" ]; then
  source $ROOTDIR/installation_scripts/setup_decompress_files.sh
  if [ $? -ne 0 ]; then
    echo  -e '\033[0;31m'"SCRIPT setup_decompress_files FAILED"'\033[0m'
    cd $ROOTDIR
    source stop_cocoa
    return 1
  fi
fi

if [ -z "${MINICONDA_INSTALLATION}" ]; then
  source ./installation_scripts/setup_cmake.sh
  if [ $? -ne 0 ]; then
    echo -e '\033[0;31m'"SCRIPT setup_cmake FAILED"'\033[0m'
    cd $ROOTDIR
    source stop_cocoa
    return 1
  fi
fi

if [ -z "${MINICONDA_INSTALLATION}" ]; then
  source $ROOTDIR/installation_scripts/setup_binutils.sh
  if [ $? -ne 0 ]; then
    echo -e '\033[0;31m'"SCRIPT setup_binutils FAILED"'\033[0m'
    cd $ROOTDIR
    source stop_cocoa
    return 1
  fi
fi

if [ -z "${MINICONDA_INSTALLATION}" ]; then
  source $ROOTDIR/installation_scripts/setup_hdf5.sh
  if [ $? -ne 0 ]; then
    echo -e '\033[0;31m'"SCRIPT setup_hdf5 FAILED"'\033[0m'
    cd $ROOTDIR
    source stop_cocoa
    return 1
  fi
fi

if [ -z "${MINICONDA_INSTALLATION}" ]; then
  source $ROOTDIR/installation_scripts/setup_openblas.sh
  if [ $? -ne 0 ]; then
    echo -e '\033[0;31m'"SCRIPT setup_openblas FAILED"'\033[0m'
    cd $ROOTDIR
    return 1
  fi
fi

source $ROOTDIR/installation_scripts/setup_pip_packages.sh
if [ $? -ne 0 ]; then
  echo -e '\033[0;31m'"SCRIPT setup_pip_packages FAILED"'\033[0m'
  cd $ROOTDIR
  source stop_cocoa
  return 1
fi

source $ROOTDIR/installation_scripts/setup_fortran_packages.sh
if [ $? -ne 0 ]; then
  echo -e '\033[0;31m'"SCRIPT setup_fortran_packages FAILED"'\033[0m'
  cd $ROOTDIR
  source stop_cocoa
  return 1
fi

source $ROOTDIR/installation_scripts/setup_cpp_packages.sh
if [ $? -ne 0 ]; then
  echo -e '\033[0;31m'"SCRIPT setup_cpp_packages FAILED"'\033[0m'
  cd $ROOTDIR
  source stop_cocoa
  return 1
fi

source $ROOTDIR/installation_scripts/setup_c_packages.sh
if [ $? -ne 0 ]; then
  echo -e '\033[0;31m'"SCRIPT setup_c_packages FAILED"'\033[0m'
  cd $ROOTDIR
  source stop_cocoa
  return 1
fi

source $ROOTDIR/installation_scripts/setup_update_cobaya.sh
if [ $? -ne 0 ]; then
  echo -e '\033[0;31m'"SCRIPT setup_update_cobaya FAILED"'\033[0m'
  cd $ROOTDIR
  source stop_cocoa
  return 1
fi

source $ROOTDIR/installation_scripts/setup_polychord.sh
if [ $? -ne 0 ]; then
  echo -e '\033[0;31m'"SCRIPT setup_polychord FAILED"'\033[0m'
  cd $ROOTDIR
  source stop_cocoa
  return 1
fi

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
source stop_cocoa
echo -e '\033[1;45m''\e[4mSETUP COCOA INSTALLATION PACKAGES DONE''\033[0m'
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------