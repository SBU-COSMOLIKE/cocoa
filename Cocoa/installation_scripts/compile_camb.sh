#!/bin/bash
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
if [ -z "${IGNORE_CAMB_CODE}" ]; then
  
  if [ -z "${ROOTDIR}" ]; then
    source start_cocoa.sh || { pfail 'ROOTDIR'; return 1; }
  fi

  # parenthesis = run in a subshell  
  ( source "${ROOTDIR:?}/installation_scripts/flags_check.sh" ) || return 1;

  unset_env_vars () {
    unset -v ECODEF FOLDER PACKDIR PRINTNAME
    cdroot || return 1;
  }

  unset_env_funcs () {
    unset -f cdfolder cpfolder error
    unset -f unset_env_funcs
    cdroot || return 1;
  }

  unset_all () {
    unset_env_vars
    unset_env_funcs
    unset -f unset_all
    cdroot || return 1;
  }
  
  error () {
    fail_script_msg "$(basename "${BASH_SOURCE[0]}")" "${1}"
    unset_all || return 1
  }
  
  cdfolder() {
    cd "${1:?}" 2>"/dev/null" || { error "CD FOLDER ${1}"; return 1; }
  }
  
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------

  unset_env_vars || return 1

  # ---------------------------------------------------------------------------

  # E = EXTERNAL, CODE, F=FODLER
  ECODEF="${ROOTDIR:?}/external_modules/code"

  FOLDER="${CAMB_NAME:-"CAMB"}"

  PACKDIR="${ECODEF:?}/${FOLDER:?}"

  # Name to be printed on this shell script messages
  PRINTNAME="CAMB"

  ptop "COMPILING ${PRINTNAME:?}" || return 1

  cdfolder "${PACKDIR}" || return 1

  # ---------------------------------------------------------------------------
  # cleaning any previous compilation
  
  rm -rf "${PACKDIR:?}/build/"
  rm -rf "${PACKDIR:?}/camb/__pycache__/"
  rm -f  "${PACKDIR:?}/camb/camblib.so"
  rm -rf "${PACKDIR:?}/forutils/Releaselib/"
  
  "${PYTHON3:?}" setup.py clean \
    >${OUT1:?} 2>${OUT2:?} || { error "${EC1:?}"; return 1; }
  
  # ---------------------------------------------------------------------------
  
  if [ -z "${IGNORE_COSMOREC_CODE}" ] && [ -n "${IGNORE_HYREC_CODE}" ]; then

    RECOMBINATION_FILES="recfast cosmorec" COMPILER="${FORTRAN_COMPILER:?}" \
      F90C="${FORTRAN_COMPILER:?}" "${PYTHON3:?}" setup.py build \
      >${OUT1:?} 2>${OUT2:?} || { error "${EC4:?}"; return 1; }
  
  elif [ -n "${IGNORE_COSMOREC_CODE}" ] && [ -z "${IGNORE_HYREC_CODE}" ]; then

    RECOMBINATION_FILES="recfast hyrec" COMPILER="${FORTRAN_COMPILER:?}" \
      F90C="${FORTRAN_COMPILER:?}" "${PYTHON3:?}" setup.py build \
      >${OUT1:?} 2>${OUT2:?} || { error "${EC4:?}"; return 1; }
  
  elif [ -z "${IGNORE_COSMOREC_CODE}" ] && [ -z "${IGNORE_HYREC_CODE}" ]; then

    RECOMBINATION_FILES="recfast cosmorec hyrec" \
      COMPILER="${FORTRAN_COMPILER:?}" F90C="${FORTRAN_COMPILER:?}" \
      "${PYTHON3:?}" setup.py build \
      >${OUT1:?} 2>${OUT2:?} || { error "${EC4:?}"; return 1; }

  else

    COMPILER="${FORTRAN_COMPILER:?}" F90C="${FORTRAN_COMPILER:?}" \
      "${PYTHON3:?}" setup.py build \
      >${OUT1:?} 2>${OUT2:?} || { error "${EC4:?}"; return 1; }

  fi

  pbottom "COMPILING ${PRINTNAME:?}" || return 1

  # ---------------------------------------------------------------------------

  unset_all || return 1

fi
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------