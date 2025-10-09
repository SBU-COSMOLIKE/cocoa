#!/bin/bash
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
if [ -z "${IGNORE_COSMOLIKE_CODE}" ]; then

  if [ -z "${ROOTDIR}" ]; then
    source start_cocoa.sh || { pfail 'ROOTDIR'; return 1; }
  fi

  # parenthesis = run in a subshell
  ( source "${ROOTDIR:?}/installation_scripts/flags_check.sh" ) || return 1;

  unset_env_vars () {
    unset -v URL ECODEF FOLDER PACKDIR 
    cdroot || return 1;
  }

  unset_env_funcs () {
    unset -f cdfolder cpfolder error cpfile
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
    cd "${1:?}" 2>"/dev/null" || { error "CD FOLDER: ${1}"; return 1; }
  }

  cpfolder() {
    cp -r "${1:?}" "${2:?}"  \
      2>"/dev/null" || { error "CP FOLDER ${1} on ${2}"; return 1; }
  }

  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------

  unset_env_vars || return 1

  ptop "SETUP COCOA-COSMOLIKE CORE" || return 1;

  URL="${COSMOLIKE_URL:-"https://github.com/CosmoLike/cocoa-cosmolike-core.git"}"

  ECODEF="${ROOTDIR:?}/external_modules/code" # E = EXTERNAL, CODE, F=FODLER

  FOLDER="${COSMOLIKE_NAME:-"cosmolike_core"}"

  PACKDIR="${ECODEF:?}/${FOLDER:?}"

  if [ -n "${OVERWRITE_EXISTING_COSMOLIKE_CODE}" ]; then
    rm -rf "${PACKDIR:?}"
  fi

  if [ ! -d "${PACKDIR:?}" ]; then
    cdfolder "${ECODEF:?}" || { cdroot; return 1; }

    "${GIT:?}" clone --depth ${GIT_CLONE_MAXIMUM_DEPTH:?} "${URL:?}" "${FOLDER:?}" \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC15:?}"; return 1; }
    
    cdfolder "${PACKDIR}" || { cdroot; return 1; }

    if [ -n "${COSMOLIKE_GIT_COMMIT}" ]; then
      "${GIT:?}" checkout "${COSMOLIKE_GIT_COMMIT:?}" \
        >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
    fi
  fi

  pbottom "SETUP COCOA-COSMOLIKE CORE" || return 1
  
  cdfolder "${ROOTDIR}" || return 1

  unset_all || return 1
fi
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------