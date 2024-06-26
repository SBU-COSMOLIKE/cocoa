#!/bin/bash
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
if [ -z "${ROOTDIR}" ]; then
  pfail 'ROOTDIR'; return 1
fi

unset_env_funcs () {
  unset -f cdfolder cpfolder error
  unset -f unset_env_funcs
  cdroot || return 1;
}

unset_all () {
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
# ----------------------------------------------------------------------------

ptop2 'DELETING CORE PACKAGES' || return 1

cdfolder "${ROOTDIR:?}/../cocoa_installation_libraries" || return 1

# parenthesis = run in a subshell
( sh clean_all ) || { error "script clean_all.sh"; return 1; }

unset -v SETUP_PREREQUISITE_DONE
unset_all || return 1;

pbottom2 'DELETING CORE PACKAGES' || return 1

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------