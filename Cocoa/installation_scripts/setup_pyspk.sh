#!/bin/bash
# ------------------------------------------------------------------------------
# setup_pyspk.sh: download pyspk (the SP(k) baryonic feedback model).
#
# Sourced, never executed (only `source` keeps its environment changes).
# setup_cocoa.sh runs it during a full installation, and sourcing it on its
# own redoes just this package (see the README FAQ on installing a single
# package). Setup scripts MAY use the internet (git clone, wget, pip index);
# the matching compile step never does, so anything that must be downloaded
# happens here.
#
# Skipped (return 99) when IGNORE_PYSPK_CODE is set. Reruns are safe: existing
# results are kept unless OVERWRITE_EXISTING_PYSPK_CODE is set. On failure
# error() names the failing step and unsets everything defined here; on
# success the script returns 55, the value the runner caches so a finished
# step is not repeated.
# ------------------------------------------------------------------------------
if [ -n "${IGNORE_PYSPK_CODE:-}" ]; then
  return 99
fi

if [ -z "${ROOTDIR:-}" ]; then
  source start_cocoa.sh || { pfail 'ROOTDIR'; return 1; }
fi

# parenthesis = run in a subshell
( source "${ROOTDIR:?}/installation_scripts/flags_check.sh" ) || return 1;

# unset_env_vars: forget every variable the body defines. Sourced scripts
# share the caller's shell, so anything not unset here would leak into the
# user's environment. cdroot returns to the directory the user launched from.
unset_env_vars () {
  unset -v URL CCIL ECODEF FOLDER PACKDIR PYSPK_REQUESTED_REF
  cdroot || return 1;
}

# unset_env_funcs: forget every helper function defined below (functions leak
# into the user's shell exactly like variables).
unset_env_funcs () {
  unset -f cdfolder cpfolder error cpfile
  unset -f unset_env_funcs
  cdroot || return 1;
}

# unset_all: the single cleanup entry point: variables, then functions, then
# itself.
unset_all () {
  unset_env_vars
  unset_env_funcs
  unset -f unset_all
  cdroot || return 1;
}

# error: print which step failed (fail_script_msg names this script and the
# message) and run the FULL cleanup. A call site whose helper already routes
# through error() therefore uses plain `|| return 1`; adding another unset_all
# there would run the cleanup twice.
error () {
  fail_script_msg "$(basename "${BASH_SOURCE[0]}")" "${1}"
  unset_all || return 1
}

# cdfolder: cd that reports the target and cleans up on failure.
cdfolder() {
  cd "${1:?}" 2>"/dev/null" || { error "CD FOLDER: ${1}"; return 1; }
}

# cpfolder: recursive copy that reports source/target and cleans up on
# failure.
cpfolder() {
  cp -r "${1:?}" "${2:?}"  \
    2>"/dev/null" || { error "CP FOLDER ${1} on ${2}"; return 1; }
}

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------

unset_env_vars || return 1

CCIL="${ROOTDIR:?}/../cocoa_installation_libraries"

# E = EXTERNAL, CODE, F=FODLER
ECODEF="${ROOTDIR:?}/external_modules/code"

URL="${PYSPK_URL:-"https://github.com/jemme07/pyspk.git"}"

FOLDER="${PYSPK_NAME:-"pyspk"}"

PACKDIR="${ECODEF:?}/${FOLDER:?}"
ptop "INSTALLING BARYONIC PYSPK FEEDBACK MODELS" || { unset_all; return 1; }

# ----------------------------------------------------------------------------
# In case this script is called twice ----------------------------------------
# ----------------------------------------------------------------------------
if [ -n "${OVERWRITE_EXISTING_PYSPK_CODE:-}" ]; then
  rm -rf "${PACKDIR:?}"
fi

if [ ! -d "${PACKDIR:?}" ]; then
  echo "${PACKDIR:?}"

  cdfolder "${ECODEF:?}" || return 1;

  "${GIT:?}" clone "${URL:?}" --depth ${GIT_CLONE_MAXIMUM_DEPTH:-1000} \
    --recursive --no-single-branch "${PACKDIR:?}" \
    >>${OUT1:?} 2>>${OUT2:?} || { error "${EC15:?}"; return 1; }

fi

# A completed clone may remain after a later setup step failed. Resolve the
# requested revision on every attempt, not only when creating the directory.
cdfolder "${PACKDIR:?}" || return 1;
if [ ! -d .git ] && [ ! -f .git ]; then
  error "PYSPK DIRECTORY IS NOT A GIT CHECKOUT: ${PACKDIR}"; return 1;
fi

PYSPK_REQUESTED_REF=""
if [ -n "${PYSPK_GIT_COMMIT:-}" ]; then
  PYSPK_REQUESTED_REF="${PYSPK_GIT_COMMIT}"
elif [ -n "${PYSPK_GIT_BRANCH:-}" ]; then
  PYSPK_REQUESTED_REF="origin/${PYSPK_GIT_BRANCH}"
elif [ -n "${PYSPK_GIT_TAG:-}" ]; then
  PYSPK_REQUESTED_REF="refs/tags/${PYSPK_GIT_TAG}"
fi

# A shallow clone already contains its tip commit. Do not make a second
# network request when that is the requested pin. Fetch only missing refs.
if [ -n "${PYSPK_REQUESTED_REF}" ]; then
  if ! "${GIT:?}" cat-file -e "${PYSPK_REQUESTED_REF}^{commit}" 2>/dev/null; then
    if [ "$("${GIT:?}" rev-parse --is-shallow-repository)" = "true" ]; then
      "${GIT:?}" fetch --unshallow --all --tags --prune \
        >>${OUT1:?} 2>>${OUT2:?} || { error "PYSPK GIT FETCH"; return 1; }
    else
      "${GIT:?}" fetch --all --tags --prune \
        >>${OUT1:?} 2>>${OUT2:?} || { error "PYSPK GIT FETCH"; return 1; }
    fi
  fi

  if [ -n "${PYSPK_GIT_COMMIT:-}" ]; then
    "${GIT:?}" checkout --detach "${PYSPK_GIT_COMMIT}" \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
  elif [ -n "${PYSPK_GIT_BRANCH:-}" ]; then
    "${GIT:?}" checkout -B "${PYSPK_GIT_BRANCH}" "${PYSPK_REQUESTED_REF}" \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
  else
    "${GIT:?}" checkout --detach "${PYSPK_REQUESTED_REF}" \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
  fi
fi

cdfolder "${ROOTDIR:?}" || return 1;

pbottom "INSTALLING BARYONIC PYSPK FEEDBACK MODELS" || { unset_all; return 1; }

# ---------------------------------------------------------------------------

unset_all || return 1
  
#-------------------------------------------------------------------------------

return 55; # why this odd number? Setup_cocoa will cache this installation only
           #   if this script runs entirely. What if the user close the terminal 
           #   or the system shuts down in the middle of a git clone?  
           #   In this case, PACKDIR would exists, but it is corrupted

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
