#!/bin/bash
# --------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------
if [ -z "${IGNORE_PLANCK_COMPILATION}" ]; then
  echo -e '\033[1;34m''\tCOMPILING PLANCK''\033[0m'

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
  if [ -z "${DEBUG_PLANCK_OUTPUT}" ]; then
    export OUTPUT_PLANCK_1="/dev/null"
    export OUTPUT_PLANCK_2="/dev/null"
  else
    export OUTPUT_PLANCK_1="/dev/tty"
    export OUTPUT_PLANCK_2="/dev/tty"
  fi
  if [ -z "${IGNORE_C_CFITSIO_INSTALLATION}" ]; then
    export CLIK_CFITSLIBS=$ROOTDIR/.local/lib
  else
    export CLIK_CFITSLIBS=$GLOBAL_PACKAGES_LOCATION
  fi
  
  if [ -z "${IGNORE_FORTRAN_INSTALLATION}" ]; then
    export CLIK_LAPALIBS=$ROOTDIR/.local
  else
    export CLIK_LAPALIBS=$GLOBAL_PACKAGES_LOCATION
  fi

  source $ROOTDIR/installation_scripts/clean_planck.sh

  # ----------------------------------------------------------------------------
  # ----------------------------------------------------------------------------
  if [ -z "${USE_SPT_CLIK_PLANCK}" ]; then
    cd $ROOTDIR/external_modules/code/planck/code/plc_3.0/plc-3.1/
  else
    cd $ROOTDIR/external_modules/code/planck/code/spt_clik/
  fi
  # ----------------------------------------------------------------------------
  # ----------------------------------------------------------------------------
  
  FC=$FORTRAN_COMPILER CC=$C_COMPILER CXX=$CXX_COMPILER $PYTHON3 waf configure \
    --gcc --gfortran --cfitsio_islocal --prefix $ROOTDIR/.local \
    --lapack_prefix=${CLIK_LAPALIBS} --cfitsio_lib=${CLIK_CFITSLIBS} \
    --python=${PYTHON3} > ${OUTPUT_PLANCK_1} 2> ${OUTPUT_PLANCK_2}
  if [ $? -ne 0 ]; then
    echo -e '\033[0;31m'"PLANCK COULD NOT RUN WAF CONFIGURE"'\033[0m'
    unset CLIK_LAPALIBS
    unset CLIK_CFITSLIBS
    unset OUTPUT_PLANCK_1
    unset OUTPUT_PLANCK_2
    cd $ROOTDIR
    return 1
  else
    unset CLIK_LAPALIBS
    unset CLIK_CFITSLIBS
    echo -e '\033[0;32m'"PLANCK RUN \e[3mWAF CONFIGURE RUN\e[0m\e\033[0;32m DONE"'\033[0m'
  fi
  
  $PYTHON3 waf install -v > ${OUTPUT_PLANCK_1} 2> ${OUTPUT_PLANCK_2}
  if [ $? -ne 0 ]; then
    echo -e '\033[0;31m'"PLANCK COULD NOT RUN \e[3mWAF INSTALL"'\033[0m'
    cd $ROOTDIR
    unset OUTPUT_PLANCK_1
    unset OUTPUT_PLANCK_2
    return 1
  else
    echo -e '\033[0;32m'"\t\t PLANCK RUN \e[3mWAF INSTALL\e[0m\e\033[0;32m DONE"'\033[0m'
  fi

  cd $ROOTDIR
  unset OUTPUT_PLANCK_1
  unset OUTPUT_PLANCK_2
  echo -e '\033[1;34m''\t\e[4mCOMPILING PLANCK DONE''\033[0m'
fi
# --------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------