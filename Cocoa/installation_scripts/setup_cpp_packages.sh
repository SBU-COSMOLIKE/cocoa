#!/bin/bash
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
if [ -z "${IGNORE_CPP_INSTALLATION}" ]; then
  echo -e '\033[1;44m''SETUP_CPP_PACKAGES''\033[0m'

  if [ -z "${ROOTDIR}" ]; then
      echo -e '\033[0;31m''ERROR ENV VARIABLE ROOTDIR IS NOT DEFINED''\033[0m'
      return 1
  fi
  if [ -z "${CXX_COMPILER}" ]; then
      echo -e '\033[0;31m''ERROR ENV VARIABLE CXX_COMPILER IS NOT DEFINED''\033[0m'
      cd $ROOTDIR
      return 1
  fi
  if [ -z "${C_COMPILER}" ]; then
      echo -e '\033[0;31m''ERROR ENV VARIABLE C_COMPILER IS NOT DEFINED''\033[0m'
      cd $ROOTDIR
      return 1
  fi
  if [ -z "${CMAKE}" ]; then
      echo -e '\033[0;31m''ERROR ENV VARIABLE MAKE IS NOT DEFINED''\033[0m'
      return 1
  fi
  if [ -z "${FORTRAN_COMPILER}" ]; then
      echo -e '\033[0;31m''ERROR ENV VARIABLE FORTRAN_COMPILER IS NOT DEFINED''\033[0m'
      cd $ROOTDIR
      return 1
  fi
  if [ -z "${PYTHON3}" ]; then
      echo -e '\033[0;31m''ERROR ENV VARIABLE PYTHON3 IS NOT DEFINED''\033[0m'
      cd $ROOTDIR
      return 1
  fi
  if [ -z "${MAKE_NUM_THREADS}" ]; then
      echo -e '\033[0;31m''ERROR ENV VARIABLE MAKE_NUM_THREADS IS NOT DEFINED''\033[0m'
      cd $ROOTDIR
      return 1
  fi

  unset_env_vars () {
    cd $ROOTDIR
    unset OUT_CPP_PACK_1
    unset OUT_CPP_PACK_2
    unset CPP_MAKE_NUM_THREADS
  }

  if [ -z "${DEBUG_CPP_PACKAGES}" ]; then
    export OUT_CPP_PACK_1="/dev/null"
    export OUT_CPP_PACK_2="/dev/null"
    export CPP_MAKE_NUM_THREADS="${MAKE_NUM_THREADS}"
  else
    export OUT_CPP_PACK_1="/dev/tty"
    export OUT_CPP_PACK_2="/dev/tty"
    export CPP_MAKE_NUM_THREADS=1
  fi

  # ------------------------------------------------------------------------------
  # --------------------------------------- SPDLOG -------------------------------
  # ------------------------------------------------------------------------------
  if [ -z "${IGNORE_CPP_SPDLOG_INSTALLATION}" ]; then
    echo -e '\033[1;34m''\tINSTALLING SPDLOG C++ LIBRARY''\033[0m'

    cd $ROOTDIR/../cocoa_installation_libraries/$COCOA_SPDLOG_DIR

    rm -f CMakeCache.txt

    $CMAKE -DCMAKE_INSTALL_PREFIX=$ROOTDIR/.local \
      -DCMAKE_C_COMPILER=$C_COMPILER \
      -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
      --log-level=ERROR . > ${OUT_CPP_PACK_1} 2> ${OUT_CPP_PACK_2}
    if [ $? -eq 0 ];then
      echo -e '\033[0;32m'"\t\t SPDLOG RUN \e[3mCMAKE\e[0m\e\033[0;32m DONE"'\033[0m'
    else
      echo -e '\033[0;31m'"SPDLOG COULD NOT RUN \e[3mCMAKE"'\033[0m'
      unset_env_vars
      unset unset_env_vars
      return 1
    fi

    make -j $CPP_MAKE_NUM_THREADS > ${OUT_CPP_PACK_1} 2> ${OUT_CPP_PACK_2}
    if [ $? -eq 0 ]; then
      echo -e '\033[0;32m'"\t\t SPDLOG RUN \e[3mMAKE\e[0m\e\033[0;32m DONE"'\033[0m'
    else
      echo -e '\033[0;31m'"SPDLOG COULD NOT RUN \e[3mMAKE"'\033[0m'
      unset_env_vars
      unset unset_env_vars
      return 1
    fi

    make install > ${OUT_CPP_PACK_1} 2> ${OUT_CPP_PACK_2}
    if [ $? -eq 0 ]; then
      echo -e '\033[0;32m'"\t\t SPDLOG RUN \e[3mMAKE INSTALL\e[0m\e\033[0;32m DONE"'\033[0m'
    else
      echo -e '\033[0;31m'"SPDLOG COULD NOT RUN \e[3mMAKE INSTALL"'\033[0m'
      unset_env_vars
      unset unset_env_vars
      return 1
    fi

    cd $ROOTDIR
    echo -e '\033[1;34m''\t\e[4mINSTALLING SPDLOG C++ LIBRARY DONE''\033[0m'
  fi

  # ------------------------------------------------------------------------------
  # ------------------------------------- ARMADILLO ------------------------------
  # ------------------------------------------------------------------------------
  if [ -z "${IGNORE_CPP_ARMA_INSTALLATION}" ]; then
    echo -e '\033[1;34m''\tINSTALLING ARMADILLO C++ LIBRARY - \e[4mIT MAY TAKE A WHILE''\033[0m'

    cd $ROOTDIR/../cocoa_installation_libraries/$COCOA_ARMADILLO_DIR

    rm -f CMakeCache.txt

    $CMAKE -DBUILD_SHARED_LIBS=TRUE -DCMAKE_INSTALL_PREFIX=$ROOTDIR/.local \
      -DCMAKE_C_COMPILER=$C_COMPILER -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
      -DLAPACK_FOUND=YES -DLAPACK_LIBRARIES=$ROOTDIR/.local/lib/liblapack.so \
      -DBLAS_FOUND=NO --log-level=ERROR . > ${OUT_CPP_PACK_1} 2> ${OUT_CPP_PACK_2}
    if [ $? -eq 0 ]; then
      echo -e '\033[0;32m'"\t\t ARMADILLO RUN \e[3mCMAKE\e[0m\e\033[0;32m DONE"'\033[0m'
    else
      echo -e '\033[0;31m'"ARMADILLO COULD NOT RUN \e[3mCMAKE"'\033[0m'
      unset_env_vars
      unset unset_env_vars
      return 1
    fi

    make clean > ${OUT_CPP_PACK_1} 2> ${OUT_CPP_PACK_2}
    if [ $? -eq 0 ]; then
      echo -e '\033[0;32m'"\t\t ARMADILLO RUN \e[3mMAKE CLEAN\e[0m\e\033[0;32m DONE"'\033[0m'
    else
      echo -e '\033[0;31m'"ARMADILLO COULD NOT RUN \e[3mMAKE CLEAN"'\033[0m'
      unset_env_vars
      unset unset_env_vars
      return 1
    fi

    make -j $CPP_MAKE_NUM_THREADS all -Wno-dev > ${OUT_CPP_PACK_1} 2> ${OUT_CPP_PACK_2}
    if [ $? -eq 0 ]; then
      echo -e '\033[0;32m'"\t\t ARMADILLO RUN \e[3mMAKE\e[0m\e\033[0;32m DONE"'\033[0m'
    else
      echo -e '\033[0;31m'"ARMADILLO COULD NOT RUN \e[3mMAKE"'\033[0m'
      unset_env_vars
      unset unset_env_vars
      return 1
    fi

    make install > ${OUT_CPP_PACK_1} 2> ${OUT_CPP_PACK_2}
    if [ $? -eq 0 ]; then
      echo -e '\033[0;32m'"\t\t ARMADILLO RUN \e[3mMAKE INSTALL\e[0m\e\033[0;32m DONE"'\033[0m'
    else
      echo -e '\033[0;31m'"ARMADILLO COULD NOT RUN \e[3mMAKE INSTALL"'\033[0m'
      unset_env_vars
      unset unset_env_vars
      return 1
    fi

    cd $ROOTDIR
    echo -e '\033[1;34m''\t\e[4mINSTALLING ARMADILLO C++ LIBRARY DONE''\033[0m'
  fi

  # ------------------------------------------------------------------------------
  # ------------------------ CARMA (ARMADILLO <-> PYBIND11) ----------------------
  # ------------------------------------------------------------------------------
  if [ -z "${IGNORE_CPP_CARMA_INSTALLATION}" ]; then
    echo -e '\033[1;34m''\tINSTALLING CARMA C++ LIBRARY''\033[0m'

    cd $ROOTDIR/../cocoa_installation_libraries/$COCOA_CARMA_DIR

    rm -rf $ROOTDIR/.local/include/carma/
    
    mkdir $ROOTDIR/.local/include/carma/ 

    cp ./carma.h $ROOTDIR/.local/include/

    cp -r ./carma_bits $ROOTDIR/.local/include/

    cd $ROOTDIR
    echo -e '\033[1;34m''\t\e[4mINSTALLING CARMA C++ LIBRARY DONE''\033[0m'
  fi

  # ------------------------------------------------------------------------------
  # ------------------------------------- BOOST ----------------------------------
  # ------------------------------------------------------------------------------
  if [ -z "${IGNORE_CPP_BOOST_INSTALLATION}" ]; then
    echo -e '\033[1;34m''\tINSTALLING BOOST C++ LIBRARY''\033[0m'

    cd $ROOTDIR/../cocoa_installation_libraries/$COCOA_BOOST_DIR

    ./bootstrap.sh \
      --prefix=$ROOTDIR/.local > ${OUT_CPP_PACK_1} 2> ${OUT_CPP_PACK_2}
    if [ $? -eq 0 ]; then
      echo -e '\033[0;32m'"\t\t BOOST RUN \e[3mBOOTSTRAP\e[0m\e\033[0;32m DONE"'\033[0m'
    else
      echo -e '\033[0;31m'"BOOST COULD NOT RUN \e[3mBOOTSTRAP"'\033[0m'
      unset_env_vars
      unset unset_env_vars
      return 1
    fi

    ./b2 --with=regex install --without-python --without-thread \
      --without-timer --without-mpi \
      --without-atomic > ${OUT_CPP_PACK_1} 2> ${OUT_CPP_PACK_2}
    if [ $? -eq 0 ]; then
      echo -e '\033[0;32m'"\t\t BOOST RUN \e[3mB2\e[0m\e\033[0;32m DONE"'\033[0m'
    else
      echo -e '\033[0;31m'"BOOST COULD NOT RUN \e[3mB2"'\033[0m'
      unset_env_vars
      unset unset_env_vars
      return 1
    fi
    
    cd $ROOTDIR
    echo -e '\033[1;34m''\t\e[4mINSTALLING BOOST C++ LIBRARY DONE''\033[0m'
  fi

  # ----------------------------------------------------------------------------
  # ----------------------------------------------------------------------------
  # ----------------------------------------------------------------------------
  unset_env_vars
  unset unset_env_vars
  echo -e '\033[1;44m''\e[4mSETUP_CPP_PACKAGES DONE''\033[0m'
fi
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------