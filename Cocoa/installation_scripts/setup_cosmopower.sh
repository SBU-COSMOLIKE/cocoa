#!/bin/bash
# ------------------------------------------------------------------------------
# setup_cosmopower.sh: download CosmoPower (neural-network emulators for CMB
# and matter power spectra).
#
# Sourced, never executed (only `source` keeps its environment changes).
# setup_cocoa.sh runs it during a full installation, and sourcing it on its
# own redoes just this package (see the README FAQ on installing a single
# package). Setup scripts MAY use the internet (git clone, wget, pip index);
# the matching compile step never does, so anything that must be downloaded
# happens here.
#
# Skipped (return 99) when IGNORE_COSMOPOWER_CODE is set. Reruns are safe:
# existing results are kept unless OVERWRITE_EXISTING_COSMOPOWER_CODE is set.
# On failure error() names the failing step and unsets everything defined
# here; on success the script returns 55, the value the runner caches so a
# finished step is not repeated.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
if [ -n "${IGNORE_COSMOPOWER_CODE:-}" ]; then
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

# Retry only network work. A failed local checkout is not a network failure.
# Ten attempts means at most nine waits; success returns immediately.
gitfetch() {
  local ATTEMPT=1
  local ARGS=""
  if ! [[ "${GIT_NETWORK_MAX_ATTEMPTS:-10}" =~ ^[1-9][0-9]*$ ]] ||
     ! [[ "${GIT_NETWORK_RETRY_DELAY:-5}" =~ ^[0-9]+$ ]]; then
    echo "Git retries require a positive attempt count and a nonnegative delay" >&2
    return 1
  fi
  while [ "${ATTEMPT}" -le "${GIT_NETWORK_MAX_ATTEMPTS:-10}" ]; do
    # Recheck after each failure: an interrupted fetch may have unshallowed
    # the repository before a later part of that same fetch failed.
    ARGS=""
    if [ "$("${GIT:?}" rev-parse --is-shallow-repository)" = "true" ]; then
      ARGS="--unshallow"
    fi
    if "${GIT:?}" fetch ${ARGS} --all --tags --prune; then
      return 0
    fi
    if [ "${ATTEMPT}" -ge "${GIT_NETWORK_MAX_ATTEMPTS:-10}" ]; then
      return 1
    fi
    echo "GIT FETCH attempt ${ATTEMPT} failed; retrying in ${GIT_NETWORK_RETRY_DELAY:-5}s" >&2
    sleep "${GIT_NETWORK_RETRY_DELAY:-5}" || return 1
    ATTEMPT=$((ATTEMPT + 1))
  done
  return 1
}

# Arguments: destination, URL, then the ordinary git clone options.
# Clone into a temporary sibling directory. A failed recursive clone can
# leave files behind; only publish the destination after the clone succeeds.
# We remove only the temporary directory created by this call.
gitclone() {
  local DESTINATION="${1:?}"
  # Accept folder names written with a trailing slash as well.
  DESTINATION="${DESTINATION%/}"
  local URL="${2:?}"
  local TEMP=""
  local ATTEMPT=1
  shift 2
  if [ -e "${DESTINATION}" ]; then
    echo "GIT CLONE destination already exists: ${DESTINATION}" >&2
    return 1
  fi
  if ! [[ "${GIT_NETWORK_MAX_ATTEMPTS:-10}" =~ ^[1-9][0-9]*$ ]] ||
     ! [[ "${GIT_NETWORK_RETRY_DELAY:-5}" =~ ^[0-9]+$ ]]; then
    echo "Git retries require a positive attempt count and a nonnegative delay" >&2
    return 1
  fi
  while [ "${ATTEMPT}" -le "${GIT_NETWORK_MAX_ATTEMPTS:-10}" ]; do
    TEMP=$(mktemp -d "${DESTINATION}.clone.XXXXXX") || return 1
    # "$@" passes the remaining clone options without changing their quoting.
    if "${GIT:?}" clone "${URL}" "$@" "${TEMP}/repo"; then
      mv "${TEMP}/repo" "${DESTINATION}" || return 1
      rmdir "${TEMP}" || return 1
      return 0
    fi
    rm -rf "${TEMP:?}"
    if [ "${ATTEMPT}" -ge "${GIT_NETWORK_MAX_ATTEMPTS:-10}" ]; then
      return 1
    fi
    echo "GIT CLONE attempt ${ATTEMPT} failed; retrying in ${GIT_NETWORK_RETRY_DELAY:-5}s" >&2
    sleep "${GIT_NETWORK_RETRY_DELAY:-5}" || return 1
    ATTEMPT=$((ATTEMPT + 1))
  done
  return 1
}

unset_env_vars () {
  unset -v REQUESTED_REF SETUP_NEW_CLONE
  unset -v URL CCIL ECODEF FOLDER PACKDIR  
  cdroot || return 1;
}

# unset_env_funcs: forget every helper function defined below (functions leak
# into the user's shell exactly like variables).
unset_env_funcs () {
  unset -f gitclone gitfetch
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

# ----------------------------------------------------------------------------
# In case this script is called twice ----------------------------------------
# ----------------------------------------------------------------------------

if [ ! -d "${ECODEF:?}/emulators" ]; then
  mkdir -p "${ECODEF:?}/emulators" \
    >>${OUT1:?} 2>>${OUT2:?} || { error "${EC20:?}"; return 1; }
fi

URL="${COSMOPOWER_SOLIKET_URL:-"https://github.com/simonsobs/SOLikeT.git"}"

FOLDER="${COSMOPOWER_SOLIKET_NAME:-"soliket"}"

PACKDIR="${ECODEF:?}/emulators/${FOLDER:?}"

ptop "INSTALLING COSMOPOWER SO.LIKE.T THEORY (COBAYA)" || { unset_all; return 1; }

# ----------------------------------------------------------------------------
# In case this script is called twice ----------------------------------------
# ----------------------------------------------------------------------------
if [ -n "${OVERWRITE_EXISTING_COSMOPOWER_CODE:-}" ]; then

  rm -rf "${PACKDIR:?}"

fi

if [ ! -d "${PACKDIR:?}" ]; then

  cdfolder "${ECODEF:?}/emulators" || { cdroot; return 1; }

  gitclone "${PACKDIR:?}" "${URL:?}" --depth ${GIT_CLONE_MAXIMUM_DEPTH:-1000} --recursive --no-single-branch \
    >>${OUT1:?} 2>>${OUT2:?} || { error "${EC15:?}"; return 1; }
fi

# Resolve the requested revision on reruns too. A local pin needs no fetch.
cdfolder "${PACKDIR:?}" || return 1;
if [ ! -d .git ] && [ ! -f .git ]; then
  error "DIRECTORY IS NOT A GIT CHECKOUT: ${PACKDIR}"; return 1;
fi
REQUESTED_REF=""
if [ -n "${COSMOPOWER_SOLIKET_GIT_COMMIT:-}" ]; then
  REQUESTED_REF="${COSMOPOWER_SOLIKET_GIT_COMMIT}"
elif [ -n "${COSMOPOWER_SOLIKET_GIT_BRANCH:-}" ]; then
  REQUESTED_REF="origin/${COSMOPOWER_SOLIKET_GIT_BRANCH}"
elif [ -n "${COSMOPOWER_SOLIKET_GIT_TAG:-}" ]; then
  REQUESTED_REF="refs/tags/${COSMOPOWER_SOLIKET_GIT_TAG}"
fi
if [ -n "${REQUESTED_REF}" ]; then
  if ! "${GIT:?}" cat-file -e "${REQUESTED_REF}^{commit}" 2>/dev/null; then
    gitfetch >>${OUT1:?} 2>>${OUT2:?} || { error "COSMOPOWER_SOLIKET GIT FETCH"; return 1; }
  fi
  if [ -z "${COSMOPOWER_SOLIKET_GIT_COMMIT:-}" ] && [ -n "${COSMOPOWER_SOLIKET_GIT_BRANCH:-}" ]; then
    # Keep an existing local branch (including local commits); do not reset it.
    if "${GIT:?}" show-ref --verify --quiet "refs/heads/${COSMOPOWER_SOLIKET_GIT_BRANCH}"; then
      "${GIT:?}" checkout "${COSMOPOWER_SOLIKET_GIT_BRANCH}" \
        >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
    else
      "${GIT:?}" checkout -b "${COSMOPOWER_SOLIKET_GIT_BRANCH}" "${REQUESTED_REF}" \
        >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
    fi
  else
    # Detached tags and commits are repeatable without creating a TMP branch.
    "${GIT:?}" checkout --detach "${REQUESTED_REF}" \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
  fi
fi

cdfolder "${ROOTDIR}" || return 1;

pbottom "INSTALLING COSMOPOWER SO.LIKE.T THEORY (COBAYA)" || { unset_all; return 1; }

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------

URL="${COSMOPOWER_URL:-"https://github.com/alessiospuriomancini/cosmopower.git"}"

FOLDER="${COSMOPOWER_NAME:-"cosmopower"}"

PACKDIR="${ECODEF:?}/emulators/${FOLDER:?}"

ptop "INSTALLING COSMOPOWER" || { unset_all; return 1; }

# ----------------------------------------------------------------------------
# In case this script is called twice ----------------------------------------
# ----------------------------------------------------------------------------
if [ -n "${OVERWRITE_EXISTING_COSMOPOWER_CODE:-}" ]; then

  rm -rf "${PACKDIR:?}"

fi

if [ ! -d "${PACKDIR:?}" ]; then

  cdfolder "${ECODEF:?}/emulators" || { cdroot; return 1; }

  gitclone "${PACKDIR:?}" "${URL:?}" --depth ${GIT_CLONE_MAXIMUM_DEPTH:-1000} --recursive \
    >>${OUT1:?} 2>>${OUT2:?} || { error "${EC15:?}"; return 1; }
fi

# Resolve the requested revision on reruns too. A local pin needs no fetch.
cdfolder "${PACKDIR:?}" || return 1;
if [ ! -d .git ] && [ ! -f .git ]; then
  error "DIRECTORY IS NOT A GIT CHECKOUT: ${PACKDIR}"; return 1;
fi
REQUESTED_REF=""
if [ -n "${COSMOPOWER_GIT_COMMIT:-}" ]; then
  REQUESTED_REF="${COSMOPOWER_GIT_COMMIT}"
elif [ -n "${COSMOPOWER_GIT_BRANCH:-}" ]; then
  REQUESTED_REF="origin/${COSMOPOWER_GIT_BRANCH}"
elif [ -n "${COSMOPOWER_GIT_TAG:-}" ]; then
  REQUESTED_REF="refs/tags/${COSMOPOWER_GIT_TAG}"
fi
if [ -n "${REQUESTED_REF}" ]; then
  if ! "${GIT:?}" cat-file -e "${REQUESTED_REF}^{commit}" 2>/dev/null; then
    gitfetch >>${OUT1:?} 2>>${OUT2:?} || { error "COSMOPOWER GIT FETCH"; return 1; }
  fi
  if [ -z "${COSMOPOWER_GIT_COMMIT:-}" ] && [ -n "${COSMOPOWER_GIT_BRANCH:-}" ]; then
    # Keep an existing local branch (including local commits); do not reset it.
    if "${GIT:?}" show-ref --verify --quiet "refs/heads/${COSMOPOWER_GIT_BRANCH}"; then
      "${GIT:?}" checkout "${COSMOPOWER_GIT_BRANCH}" \
        >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
    else
      "${GIT:?}" checkout -b "${COSMOPOWER_GIT_BRANCH}" "${REQUESTED_REF}" \
        >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
    fi
  else
    # Detached tags and commits are repeatable without creating a TMP branch.
    "${GIT:?}" checkout --detach "${REQUESTED_REF}" \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
  fi
fi

cdfolder "${ROOTDIR:?}" || return 1;

pbottom "INSTALLING COSMOPOWER" || { unset_all; return 1; }

# ------------------------------------------------------------------------------

unset_all || return 1

#-------------------------------------------------------------------------------

return 55; # why this odd number? Setup_cocoa will cache this installation only
           #   if this script runs entirely. What if the user close the terminal 
           #   or the system shuts down in the middle of a git clone?  
           #   In this case, PACKDIR would exists, but it is corrupted

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
