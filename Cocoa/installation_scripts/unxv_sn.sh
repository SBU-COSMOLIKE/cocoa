#!/bin/bash
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
if [ -z "${SKIP_DECOMM_SN}" ]; then

  if [ -z "${ROOTDIR}" ]; then
    source start_cocoa.sh || { pfail 'ROOTDIR'; return 1; }
  fi

  # parenthesis = run in a subshell 
  ( source "${ROOTDIR:?}/installation_scripts/flags_check.sh" ) || return 1;
    
  unset_env_vars () { 
    unset -v EDATAF FOLDER FILE PACKDIR
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
    fail_script_msg "$(basename ${BASH_SOURCE[0]})" "${1}"
    unset_all || return 1
  }

  cdfolder() {
    cd "${1:?}" 2>"/dev/null" || { error "CD FOLDER: ${1}"; return 1; }
  }

  # --------------------------------------------------------------------------- 
  # --------------------------------------------------------------------------- 
  # ---------------------------------------------------------------------------

  unset_env_vars || return 1

  # E = EXTERNAL, DATA, F=FODLER
  EDATAF="${ROOTDIR:?}/external_modules/data"

  FOLDER="sn_data"

  # PACK = PACKAGE, DIR = DIRECTORY
  PACKDIR="${EDATAF:?}/${FOLDER:?}"

  FILE="sn_data.xz"
  
  # ---------------------------------------------------------------------------

  ptop 'DECOMPRESSING SN DATA' || return 1

  # ---------------------------------------------------------------------------
  # note: in case script run >1x w/ previous run stoped prematurely b/c error

  rm -rf "${PACKDIR:?}"

  # ---------------------------------------------------------------------------

  cdfolder "${EDATAF:?}" || return 1

  tar xf "${FILE:?}" >${OUT1:?} 2>${OUT2:?} || { error "${EC25:?}"; return 1; }
  
  # ---------------------------------------------------------------------------
  
  unset_all || return 1

  pbottom 'DECOMPRESSING SN DATA' || return 1

fi

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------