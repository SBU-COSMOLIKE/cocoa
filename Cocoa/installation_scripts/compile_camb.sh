#!/bin/bash
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
if [ -z "${IGNORE_CAMB_COMPILATION}" ]; then
  
  if [ -z "${ROOTDIR}" ]; then
    pfail 'ROOTDIR'; return 1
  fi

  # ----------------------------------------------------------------------------
  # Clean any previous compilation. Parenthesis = run in a subshell
  ( TMP="${ROOTDIR:?}/installation_scripts/clean";
    source "${TMP:?}/clean_compile_camb.sh" ) || return 1;
  # ----------------------------------------------------------------------------
  
  ( source "${ROOTDIR:?}/installation_scripts/.check_flags.sh" ) || return 1;

  unset_env_vars () {
    unset -v ECODEF CAMBF PACKDIR
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
    fail_script_msg "compile_camb.sh" "${1}"
    unset_all || return 1
  }
  
  cdfolder() {
    cd "${1:?}" 2>"/dev/null" || { error "CD FOLDER ${1}"; return 1; }
  }
  
  # --------------------------------------------------------------------------- 
  # --------------------------------------------------------------------------- 
  # ---------------------------------------------------------------------------

  ptop 'COMPILING CAMB' || return 1

  unset_env_vars || return 1

  # E = EXTERNAL, CODE, F=FODLER
  ECODEF="${ROOTDIR:?}/external_modules/code"

  CAMBF=${CAMB_NAME:-"CAMB"}

  PACKDIR="${ECODEF:?}/${CAMBF:?}"

  cdfolder "${PACKDIR}" || return 1

  COMPILER="${FORTRAN_COMPILER:?}" F90C="${FORTRAN_COMPILER:?}" \
    "${PYTHON3:?}" setup.py build \
    >${OUT1:?} 2>${OUT2:?} || { error "${EC4:?}"; return 1; }

  unset_all || return 1
  
  pbottom 'COMPILING CAMB' || return 1
  
fi
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------