#!/bin/bash
# ------------------------------------------------------------------------------
# setup_private_projects.sh: download the private Cosmolike project
# repositories.
#
# Sourced, never executed (only `source` keeps its environment changes).
# setup_cocoa.sh runs it during a full installation, and sourcing it on its
# own redoes just this package (see the README FAQ on installing a single
# package). Setup scripts MAY use the internet (git clone, wget, pip index);
# the matching compile step never does, so anything that must be downloaded
# happens here.
#
# Reruns are safe: existing results are kept unless
# OVERWRITE_EXISTING_PRIVATE_PROJECTS_CODE is set. On failure error() names
# the failing step and unsets everything defined here; on success the script
# returns 55, the value the runner caches so a finished step is not repeated.
# ------------------------------------------------------------------------------
if [ -z "${ROOTDIR:-}" ]; then
  pfail 'ROOTDIR'; return 1
fi

# parenthesis = run in a subshell
( source "${ROOTDIR:?}/installation_scripts/flags_check.sh" )  || return 1;

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
  unset -v PRINTNAME FOLDER URL PACKAGE_VERSION PACKAGE_BRANCH
  cdroot || return 1;
}

# unset_env_funcs: forget every helper function defined below (functions leak
# into the user's shell exactly like variables).
unset_env_funcs () {
  unset -f gitclone gitfetch
  unset -f cdfolder cpfolder cpfile error gitact0 gitact1 gitact2 gitact3 devurl
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

# cpfile: file copy that reports source/target and cleans up on failure.
cpfile() {
  cp "${1:?}" "${2:?}" \
    2>"/dev/null" || { error "CP FILE ${1} on ${2}"; return 1; }
}

gitact0() {  
  local PROJECT="${ROOTDIR:?}/projects"
  local NAME="${1:?}"
  local URL="${2:?}"
  local PACKDIR="${PROJECT:?}/${NAME}"
  cdfolder "${PROJECT:?}" || return 1;

  # ---------------------------------------------------------------------------
  # In case this script runs twice --------------------------------------------
  # ---------------------------------------------------------------------------
  if [ -n "${OVERWRITE_EXISTING_PRIVATE_PROJECTS_CODE}" ]; then
    rm -rf "${PACKDIR:?}"
  fi

  if [ ! -d "${PACKDIR:?}" ]; then
  
    gitclone "${NAME}" "${URL}" --depth ${GIT_CLONE_MAXIMUM_DEPTH:-1000} --no-single-branch --recursive \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC15:?}"; return 1; }
  
  fi
    
  cdfolder "${ROOTDIR:?}" || return 1;
}

gitact1() { 
  local PROJECT="${ROOTDIR:?}/projects" 
  local NAME="${1:?}"
  local PACKDIR="${ROOTDIR:?}/projects/${NAME}"
  local URL="${2:?}"
  local TAG="${3:?}"
  cdfolder "${PROJECT:?}" || return 1;
  
  # ---------------------------------------------------------------------------
  # In case this script runs twice --------------------------------------------
  # ---------------------------------------------------------------------------
  if [ -n "${OVERWRITE_EXISTING_PRIVATE_PROJECTS_CODE:-}" ]; then
    rm -rf "${PACKDIR:?}"
  fi

  if [ ! -d "${PACKDIR:?}" ]; then
    gitclone "${NAME}" "${URL}" --branch "${TAG}" --single-branch \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC15:?}"; return 1; }
  fi
    
  cdfolder "${PACKDIR:?}" || return 1;
  if [ ! -d .git ] && [ ! -f .git ]; then
    error "DIRECTORY IS NOT A GIT CHECKOUT: ${PACKDIR}"; return 1;
  fi
  # Prefer the existing local branch; it may contain the user's own commits.
  if ! "${GIT:?}" show-ref --verify --quiet "refs/heads/${TAG}"; then
    if ! "${GIT:?}" cat-file -e "origin/${TAG}^{commit}" 2>/dev/null; then
      gitfetch >>${OUT1:?} 2>>${OUT2:?} || { error "GIT FETCH"; return 1; }
    fi
    "${GIT:?}" checkout -b "${TAG}" "origin/${TAG}" \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
  else
    "${GIT:?}" checkout "${TAG}" \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
  fi

  cdfolder "${ROOTDIR:?}" || return 1;
}

gitact2() {  
  local PACKDIR="${ROOTDIR:?}/projects/${1:?}"
  local COMMIT="${2}"
  local ARGS="--all --tags --prune"
  
  if [ -d "${PACKDIR:?}" ]; then
    cdfolder "${PACKDIR:?}" || return 1;
    
    # The requested revision may already be present from an earlier run.
    if ! "${GIT:?}" cat-file -e "${COMMIT}^{commit}" 2>/dev/null; then
      gitfetch >>${OUT1:?} 2>>${OUT2:?} || { error "GIT FETCH"; return 1; }
    fi

    # in case it this script runs twice:
    # check if the current commit = wanted commit
    local CURRENT=$("${GIT:?}" rev-parse HEAD 2>/dev/null)
    local TARGET=$("${GIT:?}" rev-parse "${COMMIT}" 2>/dev/null)
    if [ "${CURRENT}" != "${TARGET}" ]; then
      # first check unstagged, second check staged but uncommitted work
      # only checkout on a second run if there isn't uncommitted work
      if "${GIT:?}" diff --quiet HEAD 2>/dev/null && \
         "${GIT:?}" diff --cached --quiet HEAD 2>/dev/null; then
        "${GIT:?}" checkout "${COMMIT}" \
          >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
      else
        local tmp="skipping checkout: uncommitted changes in ${PACKDIR}"
        warning_script_msg "$(basename "${BASH_SOURCE[0]}")" "${tmp:?}"
      fi
    fi
  
  fi
    
  cdfolder "${ROOTDIR}" || return 1;
}

gitact3() {  
  local PACKDIR="${ROOTDIR:?}/projects/${1:?}"
  local TAG="${2}"
  local ARGS="--all --tags --prune"

  if [ -d "${PACKDIR:?}" ]; then
    cdfolder "${PACKDIR:?}" || return 1;

    # The requested revision may already be present from an earlier run.
    if ! "${GIT:?}" cat-file -e "refs/tags/${TAG}^{commit}" 2>/dev/null; then
      gitfetch >>${OUT1:?} 2>>${OUT2:?} || { error "GIT FETCH"; return 1; }
    fi
    
    if "${GIT:?}" show-ref --verify --quiet "refs/heads/${TAG:?}TMP"; then
      # in case it this script runs twice (CB = CURRENT BRANCH)
      # check if the branch = tag name. 
      # why this works? --branch creates a local branch with the TAG name
      local CB=$("${GIT:?}" rev-parse --abbrev-ref HEAD 2>/dev/null)
      CB="${CB##*/}"
      if [ "${CB}" != "${TAG}TMP" ]; then
        # first check unstagged, second check staged but uncommitted work
        # only checkout on a second run if there isn't uncommitted work
        if "${GIT:?}" diff --quiet HEAD 2>/dev/null && \
           "${GIT:?}" diff --cached --quiet HEAD 2>/dev/null; then
          "${GIT:?}" checkout "${TAG:?}TMP" \
              >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
        else
          local tmp="skipping checkout: uncommitted changes in ${PACKDIR}"
          warning_script_msg "$(basename "${BASH_SOURCE[0]}")" "${tmp:?}"
        fi
      fi
    else
      "${GIT:?}" checkout "tags/${TAG:?}" -b "${TAG:?}TMP" \
        >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
    fi
  fi
    
  cdfolder "${ROOTDIR}" || return 1;
}

devurl() {
  # SWITCH_TO_DEV_MODE=1: rewrite GitHub https URLs to their ssh form
  local U="${1:?}"
  if [ -n "${SWITCH_TO_DEV_MODE:-}" ]; then
    case "${U}" in
      https://*github.com/*) U="git@github.com:${U#*github.com/}" ;;
    esac
  fi
  echo "${U}"
}

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------

unset_env_vars || return 1

# ----------------------------------------------------------------------------
# -------------------------------- AXIONS -----------------------------------
# ----------------------------------------------------------------------------
if [ -n "${INSTALL_AXIONS_2025_PROJECT:-}" ]; then 

  # Name to be printed on this shell script messages
  PRINTNAME="AXIONS PROJECT"

  ptop "GETTING ${PRINTNAME:?}" || { unset_all; return 1; }

  FOLDER="${AXIONS_PROJECT_NAME:-"axions"}"

  URL="${AXIONS_2025_PROJECT_URL:?}"
  URL=$(devurl "${URL:?}")

  if [ -n "${AXIONS_2025_PROJECT_GIT_COMMIT:-}" ]; then

    gitact0 "${FOLDER:?}" "${URL:?}" || return 1;
    
    gitact2 "${FOLDER:?}" "${AXIONS_2025_PROJECT_GIT_COMMIT:?}" || return 1;
  
  elif [ -n "${AXIONS_2025_PROJECT_GIT_BRANCH:-}" ]; then 
  
    gitact1 "${FOLDER:?}" "${URL:?}" "${AXIONS_2025_PROJECT_GIT_BRANCH:?}" || return 1;
  
  elif [ -n "${AXIONS_2025_PROJECT_GIT_TAG:-}" ]; then 
  
    gitact0 "${FOLDER:?}" "${URL:?}" || return 1;
    
    gitact3 "${FOLDER:?}" "${AXIONS_2025_PROJECT_GIT_TAG:?}" || return 1;
  
  else
  
    gitact0 "${FOLDER:?}" "${URL:?}" || return 1;
  fi

  pbottom "GETTING ${PRINTNAME:?}" || { unset_all; return 1; }

fi

# ----------------------------------------------------------------------------
# -------------------------------- INFPC -------------------------------------
# ----------------------------------------------------------------------------

if [ -n "${INSTALL_PRIVATE_INFPC_PROJECT:-}" ]; then 
 
  # Name to be printed on this shell script messages
  PRINTNAME="INFPC PROJECT"

  ptop "GETTING ${PRINTNAME:?}" || { unset_all; return 1; }

  FOLDER="${INFPC_PROJECT_NAME:-"InPCReiPC"}"

  URL="${INFPC_PROJECT_URL:-"git@github.com:SBU-COSMOLIKE/InPCReiPCNewCAMB.git"}"
  URL=$(devurl "${URL:?}")

  if [ -n "${INFPC_PROJECT_GIT_COMMIT:-}" ]; then

    gitact0 "${FOLDER:?}" "${URL:?}" || return 1;

    gitact2 "${FOLDER:?}" "${INFPC_PROJECT_GIT_COMMIT:?}"  || return 1;

  elif [ -n "${INFPC_PROJECT_GIT_BRANCH:-}" ]; then 

    gitact1 "${FOLDER:?}" "${URL:?}" "${INFPC_PROJECT_GIT_BRANCH:?}" || return 1;

  elif [ -n "${INFPC_PROJECT_GIT_TAG:-}" ]; then 

    gitact0 "${FOLDER:?}" "${URL:?}" || return 1;

    gitact3 "${FOLDER:?}" "${INFPC_PROJECT_GIT_TAG:?}" || return 1;

  else

    gitact0 "${FOLDER:?}" "${URL:?}" || return 1;

  fi

  pbottom "GETTING ${PRINTNAME:?}" || { unset_all; return 1; }

fi
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

if [ -n "${INSTALL_AXIE_CAMB_2026_PROJECT:-}" ]; then 
  # Name to be printed on this shell script messages
  PRINTNAME="AXIE CAMB 2026 PROJECT"

  ptop "GETTING ${PRINTNAME:?}" || { unset_all; return 1; }

  FOLDER="${AXIE_CAMB_2026_PROJECT_NAME:-"axicambv2"}"

  URL="${AXIE_CAMB_2026_PROJECT_URL:?}"
  URL=$(devurl "${URL:?}")

  if [ -n "${AXIE_CAMB_2026_PROJECT_GIT_COMMIT:-}" ]; then

    gitact0 "${FOLDER:?}" "${URL:?}" || return 1;

    gitact2 "${FOLDER:?}" "${AXIE_CAMB_2026_PROJECT_GIT_COMMIT:?}"  || return 1;
  
  elif [ -n "${AXIE_CAMB_2026_PROJECT_GIT_BRANCH:-}" ]; then 
  
    gitact1 "${FOLDER:?}" "${URL:?}" "${AXIE_CAMB_2026_PROJECT_GIT_BRANCH:?}" || return 1;
  
  elif [ -n "${AXIE_CAMB_2026_PROJECT_GIT_TAG:-}" ]; then 
  
    gitact0 "${FOLDER:?}" "${URL:?}" || return 1;
  
    gitact3 "${FOLDER:?}" "${AXIE_CAMB_2026_PROJECT_GIT_TAG:?}" || return 1;
  
  else
  
    gitact0 "${FOLDER:?}" "${URL:?}" || return 1;
  
  fi

  pbottom "GETTING ${PRINTNAME:?}" || { unset_all; return 1; }
fi

unset_all || return 1;

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

return 55; # why this odd number? Setup_cocoa will cache this installation only
           #   if this script runs entirely. What if the user close the terminal 
           #   or the system shuts down in the middle of a git clone?  
           #   In this case, PACKDIR would exists, but it is corrupted

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
