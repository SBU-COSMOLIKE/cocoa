#!/bin/bash
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
if [ -z "${IGNORE_PLANCK_COMPILATION}" ]; then
  
  if [ -z "${ROOTDIR}" ]; then
    pfail 'ROOTDIR'; return 1
  fi
  
  # ----------------------------------------------------------------------------
  # Clean any previous compilation
  source "${ROOTDIR:?}/installation_scripts/clean_planck.sh" || return 1
  # ----------------------------------------------------------------------------
  
  source "${ROOTDIR:?}/installation_scripts/.check_flags.sh" || return 1;
    
  unset_env_vars () {
    unset -v EMCPC CLIK_LAPALIBS CLIK_CFITSLIBS
    cdroot || return 1;
  }
  
  error () {
    fail_script_msg "compile_planck.sh" "${1}"
    unset error
    unset_env_vars || return 1
  }

  cdfolder() {
    cd "${1:?}" 2>"/dev/null" || { error "CD FOLDER: ${1}"; return 1; }
  }
    
  if [ -z "${IGNORE_C_CFITSIO_INSTALLATION}" ]; then
    CLIK_CFITSLIBS="${ROOTDIR:?}/.local/lib"
  else
    if [ -z "${GLOBAL_PACKAGES_LOCATION}" ]; then
      pfail "GLOBAL_PACKAGES_LOCATION"; cdroot; return 1;
    fi
    CLIK_CFITSLIBS="${GLOBAL_PACKAGES_LOCATION:?}"
  fi
  
  if [ -z "${IGNORE_FORTRAN_INSTALLATION}" ]; then
    CLIK_LAPALIBS="${ROOTDIR:?}/.local"
  else
    if [ -z "${GLOBAL_PACKAGES_LOCATION}" ]; then
      pfail "GLOBAL_PACKAGES_LOCATION"; cdroot; return 1;
    fi
    CLIK_LAPALIBS="${GLOBAL_PACKAGES_LOCATION:?}"
  fi

  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
  
  ptop 'COMPILING PLANCK' || return 1

  unset_env_vars || return 1

  EMCPC="external_modules/code/planck/code"
  
  if [ -z "${USE_SPT_CLIK_PLANCK}" ]; then
    cdfolder "${ROOTDIR:?}/${EMCPC:?}/plc_3.0/plc-3.1/" || return 1
  else
    cdfolder "${ROOTDIR:?}/${EMCPC:?}/spt_clik/" || return 1
  fi
  
  FC="${FORTRAN_COMPILER:?}" CC="${C_COMPILER:?}" CXX="${CXX_COMPILER:?}" \
    ${PYTHON3:?} waf configure \
    --gcc --gfortran --cfitsio_islocal \
    --prefix "${ROOTDIR:?}/.local" \
    --lapack_prefix="${CLIK_LAPALIBS:?}" \
    --cfitsio_lib="${CLIK_CFITSLIBS:?}" \
    --python="${PYTHON3:?}" \
    >${OUT1:?} 2>${OUT2:?} || { error "${EC5:?}"; return 1; }
  
  ${PYTHON3:?} waf install -v \
    >${OUT1:?} 2>${OUT2:?} || { error "${EC6:?}"; return 1; }

  unset_env_vars || return 1
  
  pbottom 'COMPILING PLANCK' || return 1
  
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
fi
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------