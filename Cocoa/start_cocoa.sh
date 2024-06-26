#!/bin/bash
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
if [ -n "${START_COCOA_DONE}" ]; then
  source stop_cocoa.sh 
fi

error_start_cocoa () {
  local FILE="$(basename ${BASH_SOURCE[0]})"
  local FAILMSG="\033[0;31m (${FILE}) we cannot run "
  local FAILMSG2="\033[0m"
  echo -e "${FAILMSG}${1:?}${FAILMSG2}" 2>"/dev/null"
  unset -f error
  cd $(pwd -P) 2>"/dev/null"
  source stop_cocoa 2>"/dev/null"
  return 1
}

# ----------------------------------------------------------------------------
# ------------------------------ Basic Settings ------------------------------
# ----------------------------------------------------------------------------

source $(pwd -P)/.save_old_flags.sh
if [ $? -ne 0 ]; then
  error_start_cocoa 'script .save_old_flags.sh'; return 1;
fi

# note: here is where we define env flag ROOTDIR as $(pwd -P)
source ${SET_INSTALLATION_OPTIONS:-"set_installation_options.sh"}


if [ -n "${MINICONDA_INSTALLATION}" ]; then
  if [ -z ${CONDA_PREFIX} ]; then
    error_start_cocoa "conda environment activation"; return 1;
  fi
fi

# ----------------------------------------------------------------------------
# ---------------------- Activate Virtual Environment ------------------------
# ----------------------------------------------------------------------------

source "${ROOTDIR:?}/.local/bin/activate"
if [ $? -ne 0 ]; then
  error_start_cocoa "cocoa private python environment activation"; return 1;
fi

source "${ROOTDIR:?}/.set_new_flags.sh"
if [ $? -ne 0 ]; then
  error_start_cocoa 'script .set_new_flags.sh'; return 1;
fi

# ----------------------------------------------------------------------------
# ----------------------------- PLANCK LIKELIHOOD ----------------------------
# ----------------------------------------------------------------------------

if [ -z "${IGNORE_PLANCK_COMPILATION}" ]; then
  
  if [ -n "${CLIK_PATH}" ]; then
    export OLD_CLIK_PATH=$CLIK_PATH
  else
    export OLD_CLIK_PATH="x"
  fi

  if [ -n "${CLIK_DATA}" ]; then
    export OLD_CLIK_DATA=$CLIK_DATA
  else
    export OLD_CLIK_DATA="x"
  fi

  if [ -n "${CLIK_PLUGIN}" ]; then
    export OLD_CLIK_PLUGIN=$CLIK_PLUGIN
  else
    export OLD_CLIK_PLUGIN="x"
  fi
  
  export CLIK_PATH="${ROOTDIR:?}/.local"

  export CLIK_DATA="${ROOTDIR:?}/.local/share/clik"

  export CLIK_PLUGIN=rel2015

fi

# ----------------------------------------------------------------------------
# ------------------------ START EXTERNAL PROJECTS ---------------------------
# ----------------------------------------------------------------------------
source "${ROOTDIR:?}/projects/start_all.sh"

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
unset -f error_start_cocoa 

export START_COCOA_DONE=1

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------