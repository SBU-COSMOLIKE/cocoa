#!/bin/bash
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
if [ -z "${IGNORE_CMAKE_INSTALLATION}" ]; then
  echo -e '\033[1;44m''SETUP_CMAKE''\033[0m'

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
  if [ -z "${FORTRAN_COMPILER}" ]; then
      echo -e '\033[0;31m''ERROR ENV VARIABLE FORTRAN_COMPILER IS NOT DEFINED''\033[0m'
      cd $ROOTDIR
      return 1
  fi
  if [ -z "${MAKE_NUM_THREADS}" ]; then
      echo -e '\033[0;31m''ERROR ENV VARIABLE MAKE_NUM_THREADS IS NOT DEFINED''\033[0m'
      cd $ROOTDIR
      return 1
  fi

  echo -e '\033[1;34m''INSTALLING CMAKE LIBRARY - \e[4mIT WILL TAKE A WHILE''\033[0m'

  if [ -z "${DEBUG_CMAKE_PACKAGE}" ]; then
    export OUTPUT_CMAKE_PACKAGES_1="/dev/null"
    export OUTPUT_CMAKE_PACKAGES_2="/dev/null"
    export CMAKE_MAKE_NUM_THREADS="${MAKE_NUM_THREADS}"
  else
    export OUTPUT_CMAKE_PACKAGES_1="/dev/tty"
    export OUTPUT_CMAKE_PACKAGES_2="/dev/tty"
    export CMAKE_MAKE_NUM_THREADS=1
  fi

  cd $ROOTDIR/../cocoa_installation_libraries/$COCOA_CMAKE_DIR

  env CC=$C_COMPILER CXX=$CPP_COMPILER ./bootstrap \
    --prefix=$ROOTDIR/.local > ${OUTPUT_CMAKE_PACKAGES_1} 2> ${OUTPUT_CMAKE_PACKAGES_2}
  if [ $? -eq 0 ]; then
    echo -e '\033[0;32m'"CMAKE RUN \e[3mBOOTSTRAP\e[0m\e\033[0;32m DONE"'\033[0m'
  else
    echo -e '\033[0;31m'"CMAKE COULD NOT RUN \e[3mBOOTSTRAP"'\033[0m'
    cd $ROOTDIR
    unset OUTPUT_CMAKE_PACKAGES_1
    unset OUTPUT_CMAKE_PACKAGES_2
    unset CMAKE_MAKE_NUM_THREADS
    return 1
  fi

  make -j $CMAKE_MAKE_NUM_THREADS > ${OUTPUT_CMAKE_PACKAGES_1} 2> ${OUTPUT_CMAKE_PACKAGES_2}
  if [ $? -eq 0 ]; then
    echo -e '\033[0;32m'"CMAKE RUN \e[3mMAKE\e[0m\e\033[0;32m DONE"'\033[0m'
  else
    echo -e '\033[0;31m'"CMAKE COULD NOT RUN \e[3mMAKE"'\033[0m'
    cd $ROOTDIR
    unset OUTPUT_CMAKE_PACKAGES_1
    unset OUTPUT_CMAKE_PACKAGES_2
    unset CMAKE_MAKE_NUM_THREADS
    return 1
  fi

  make install > ${OUTPUT_CMAKE_PACKAGES_1} 2> ${OUTPUT_CMAKE_PACKAGES_2}
  if [ $? -eq 0 ]; then
    echo -e '\033[0;32m'"CMAKE RUN \e[3mMAKE INSTALL\e[0m\e\033[0;32m DONE"'\033[0m'
  else
    echo -e '\033[0;31m'"CMAKE COULD NOT RUN \e[3mMAKE INSTALL"'\033[0m'
    cd $ROOTDIR
    unset OUTPUT_CMAKE_PACKAGES_1
    unset OUTPUT_CMAKE_PACKAGES_2
    unset CMAKE_MAKE_NUM_THREADS
    return 1
  fi

  cd $ROOTDIR
  unset OUTPUT_CMAKE_PACKAGES_1
  unset OUTPUT_CMAKE_PACKAGES_2
  unset CMAKE_MAKE_NUM_THREADS
  echo -e '\033[1;34m''\e[4mINSTALLING CMAKE LIBRARY DONE''\033[0m'
  echo -e '\033[1;44m''\e[4mSETUP_CMAKE DONE''\033[0m'
fi
# --------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------