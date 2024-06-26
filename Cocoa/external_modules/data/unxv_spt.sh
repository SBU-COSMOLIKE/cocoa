#!/bin/bash
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
if [ -z "${SKIP_DECOMM_SPT}" ]; then

  if [ -z "${ROOTDIR}" ]; then
    pfail 'ROOTDIR'; return 1
  fi

  # parenthesis = run in a subshell 
  ( source "${ROOTDIR:?}/installation_scripts/.check_flags.sh" ) || return 1;
    
  unset_env_vars () { FOLDER
    unset -v EDATAF URL
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

  URL="${SPT3G_DATA_URL:-"https://github.com/SouthPoleTelescope/spt3g_y1_dist.git"}"

  FOLDER="${SPT_3G_NAME:-"spt_3g"}"

  # ---------------------------------------------------------------------------

  ptop "DECOMPRESSING SPT-3G Y1 DATA" || return 1
  
  # ---------------------------------------------------------------------------
  # note: in case this script is run twice
  rm -rf "${EDATAF:?}/${FOLDER:?}"
  
  # ---------------------------------------------------------------------------

  cdfolder "${EDATAF:?}"

  ${GIT:?} clone "${URL:?}" "${FOLDER:?}" \
    >${OUT1:?} 2>${OUT2:?} || { error "${EC15:?}"; return 1; }

  if [ -n "${SPT3G_DATA_GIT_COMMIT}" ]; then
    cdfolder "${EDATAF:?}/${FOLDER:?}"

    ${GIT:?} checkout "${SPT3G_DATA_GIT_COMMIT:?}" \
      >${OUT1:?} 2>${OUT2:?} || { error "${EC16:?}"; return 1; }
  fi

  # ---------------------------------------------------------------------------

  cdfolder "${ROOTDIR}" || return 1

  unset_all || return 1; 

  pbottom 'DECOMPRESSING SPT-3G Y1 DATA' || return 1
  
fi

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------