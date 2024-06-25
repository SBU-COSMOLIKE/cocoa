#!/bin/bash
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
if [ -z "${SKIP_DECOMM_ACT}" ]; then
  
  if [ -z "${ROOTDIR}" ]; then
    pfail 'ROOTDIR'; return 1;
  fi

  unset_env_vars () {
    unset -v EDATAF DATAF PACKDIR FILE URL_BASE URL
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
    fail_script_msg "unxv_act_dr6.sh" "${1}"
    unset_all || return 1
  }
  
  cdfolder() {
    cd "${1:?}" 2>"/dev/null" || { error "CD FOLDER ${1}"; return 1; }
  }

  # --------------------------------------------------------------------------- 
  # --------------------------------------------------------------------------- 
  # ---------------------------------------------------------------------------

  ptop 'DECOMPRESSING ACT-DR6 DATA' || return 1

  unset_env_vars || return 1

  # E = EXTERNAL, DATA, F=FODLER
  EDATAF="${ROOTDIR:?}/external_modules/data"
  
  DATAF="act"

  # PACK = PACKAGE, DIR = DIRECTORY
  PACKDIR="${EDATAF:?}/${DATAF:?}"

  URL_BASE="https://lambda.gsfc.nasa.gov/data/suborbital/ACT/ACT_dr6/likelihood/data"

  FILE="${ACT_DR6_DATA_FILE:-"ACT_dr6_likelihood_v1.2.tgz"}"

  URL="${ACT_DR6_DATA_URL:-"${URL_BASE:?}"}/${FILE:?}"

  # ---------------------------------------------------------------------------
  # in case this script is called twice
  # ---------------------------------------------------------------------------
  rm -rf "${PACKDIR:?}"

  mkdir -p "${PACKDIR:?}"
  mkdir -p "${PACKDIR:?}/lensing"
    
  cdfolder "${PACKDIR:?}/lensing" || return 1

  wget "${URL:?}" >${OUT1:?} 2>${OUT2:?} || { error "${EC24:?}"; return 1; }

  tar -zxvf "${FILE:?}" \
    >${OUT1:?} 2>${OUT2:?} || { error "${EC25:?}"; return 1; }

  unset_all || return 1
  
  pbottom 'DECOMPRESSING ACT-DR6 DATA' || return 1

fi

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------