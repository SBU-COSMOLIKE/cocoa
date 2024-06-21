#!/bin/bash
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
if [ -z "${IGNORE_PLANCK_COMPILATION}" ]; then
  
  if [ -z "${ROOTDIR}" ]; then
    echo -e "\033[0;31m\t\t ERROR ENV VARIABLE ${ROOTDIR} NOT DEFINED \033[0m"
    return 1
  fi
  
  # ----------------------------------------------------------------------------
  # Clean any previous compilation
  source "${ROOTDIR:?}/installation_scripts/clean_planck.sh"
  # ----------------------------------------------------------------------------
  
  pfail() {
    echo -e \
    "\033[0;31m\t\t ERROR ENV VARIABLE ${1:-"empty arg"} NOT DEFINED \033[0m"
    unset pfail
  }
  
  cdroot() {
    cd "${ROOTDIR:?}" 2>"/dev/null" || { echo -e \
      "\033[0;31m\t\t CD ROOTDIR (${ROOTDIR}) FAILED \033[0m"; return 1; }
    unset cdroot
  }
  
  if [ -z "${CXX_COMPILER}" ]; then
    pfail 'CXX_COMPILER'; cdroot; return 1;
  fi
  
  if [ -z "${C_COMPILER}" ]; then
    pfail 'C_COMPILER'; cdroot; return 1;
  fi
  
  if [ -z "${PIP3}" ]; then
    pfail 'PIP3'; cdroot; return 1;
  fi
  
  if [ -z "${PYTHON3}" ]; then
    pfail "PYTHON3"; cdroot; return 1;
  fi
    
  unset_env_vars_comp_pl () {
    unset OUT1
    unset OUT2
    unset pfail
    unset CFL
    unset CLIK_LAPALIBS
    unset CLIK_CFITSLIBS
    unset unset_env_vars_comp_pl
    cdroot || return 1;
  }
  
  fail_comp_pl () {
    local MSG="\033[0;31m\t\t (compile_planck.sh) we cannot run \e[3m"
    local MSG2="\033[0m"
    echo -e "${MSG} ${1:-"empty arg"} ${MSG2}"
    unset fail_comp_pl
    unset_env_vars_comp_pl
  }
  
  cdfolder() {
    cd "${1:?}" 2>"/dev/null" || { fail_comp_pl "CD FOLDER: ${1}"; return 1; }
  }
  
  if [ -z "${DEBUG_PLANCK_OUTPUT}" ]; then
    export OUT1="/dev/null"; export OUT2="/dev/null"
  else
    export OUT1="/dev/tty"; export OUT2="/dev/tty"
  fi
  
  if [ -z "${IGNORE_C_CFITSIO_INSTALLATION}" ]; then
    export CLIK_CFITSLIBS="${ROOTDIR:?}/.local/lib"
  else
    if [ -z "${GLOBAL_PACKAGES_LOCATION}" ]; then
      pfail "GLOBAL_PACKAGES_LOCATION"; cdroot; return 1;
    fi
    export CLIK_CFITSLIBS="${GLOBAL_PACKAGES_LOCATION:?}"
  fi
  
  if [ -z "${IGNORE_FORTRAN_INSTALLATION}" ]; then
    export CLIK_LAPALIBS="${ROOTDIR:?}/.local"
  else
    if [ -z "${GLOBAL_PACKAGES_LOCATION}" ]; then
      pfail "GLOBAL_PACKAGES_LOCATION"; cdroot; return 1;
    fi
    export CLIK_LAPALIBS="${GLOBAL_PACKAGES_LOCATION:?}"
  fi

  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
  
  ptop 'COMPILING PLANCK'

  export CFL="external_modules/code/planck/code"
  
  if [ -z "${USE_SPT_CLIK_PLANCK}" ]; then
    cdfolder "${ROOTDIR:?}/${CFL:?}/plc_3.0/plc-3.1/" || return 1
  else
    cdfolder "${ROOTDIR:?}/${CFL:?}/spt_clik/" || return 1
  fi
  
  FC="${FORTRAN_COMPILER:?}" CC="${C_COMPILER:?}" CXX="${CXX_COMPILER:?}" \
    "${PYTHON3:?}" waf configure \
    --gcc \
    --gfortran \
    --cfitsio_islocal \
    --prefix "${ROOTDIR:?}/.local" \
    --lapack_prefix="${CLIK_LAPALIBS:?}" \
    --cfitsio_lib="${CLIK_CFITSLIBS:?}" \
    --python="${PYTHON3:?}" >${OUT1:?} 2>${OUT2:?} || 
    { fail_comp_pl "PYTHON3 WAF CONFIGURE"; return 1; }
  
  "${PYTHON3:?}" waf install -v >${OUT1:?} 2>${OUT2:?} || 
    { fail_comp_pl "PYTHON3 WAF INSTALL"; return 1; }

  unset_env_vars_comp_pl || return 1
  
  pbottom 'COMPILING PLANCK'
  
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
fi

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------