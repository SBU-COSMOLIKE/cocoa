#!/bin/bash
# ------------------------------------------------------------------------------
# setup_treecorr.sh: download TreeCorr (two- and three-point correlations).
#
# Sourced, never executed (only `source` keeps its environment changes).
# setup_cocoa.sh runs it during a full installation, and sourcing it on its
# own redoes just this package (see the README FAQ on installing a single
# package). Setup scripts MAY use the internet (git clone, wget, pip index);
# the matching compile step never does, so anything that must be downloaded
# happens here.
#
# Skipped (return 99) when IGNORE_TREECORR_CODE is set. Reruns are safe: existing
# results are kept unless OVERWRITE_EXISTING_TREECORR_CODE is set. On failure
# error() names the failing step and unsets everything defined here; on
# success the script returns 55, the value the runner caches so a finished
# step is not repeated.
# ------------------------------------------------------------------------------
if [ -n "${IGNORE_TREECORR_CODE:-}" ]; then
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
  unset -v URL CCIL ECODEF FOLDER PACKDIR
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

URL="${TREECORR_URL:-"https://github.com/rmjarvis/TreeCorr.git"}"

FOLDER="${TREECORR_NAME:-"treecorr"}"

PACKDIR="${ECODEF:?}/${FOLDER:?}"
ptop "INSTALLING TREECORR CORRELATION MEASUREMENTS" || { unset_all; return 1; }

# ----------------------------------------------------------------------------
# In case this script is called twice ----------------------------------------
# ----------------------------------------------------------------------------
if [ -n "${OVERWRITE_EXISTING_TREECORR_CODE:-}" ]; then
  rm -rf "${PACKDIR:?}"
fi

if [ ! -d "${PACKDIR:?}" ]; then
  echo "${PACKDIR:?}"

  cdfolder "${ECODEF:?}" || return 1;

  "${GIT:?}" clone "${URL:?}" --depth ${GIT_CLONE_MAXIMUM_DEPTH:-1000} \
    --recursive --no-single-branch "${PACKDIR:?}" \
    >>${OUT1:?} 2>>${OUT2:?} || { error "${EC15:?}"; return 1; }

  cdfolder "${PACKDIR:?}" || return 1;

  if [[ -n "${TREECORR_GIT_COMMIT:-}" ||
        -n "${TREECORR_GIT_BRANCH:-}" ||
        -n "${TREECORR_GIT_TAG:-}" ]]; then
    if [ "$("${GIT:?}" rev-parse --is-shallow-repository)" = "true" ]; then
      "${GIT:?}" fetch --unshallow --all --tags --prune \
        >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
    else
      "${GIT:?}" fetch --all --tags --prune \
        >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
    fi
  fi

  if [ -n "${TREECORR_GIT_COMMIT:-}" ]; then

    "${GIT:?}" checkout "${TREECORR_GIT_COMMIT:?}" \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }

  elif [ -n "${TREECORR_GIT_BRANCH:-}" ]; then

    "${GIT:?}" checkout -B "${TREECORR_GIT_BRANCH:?}" "origin/${TREECORR_GIT_BRANCH:?}" \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }

  elif [ -n "${TREECORR_GIT_TAG:-}" ]; then

    "${GIT:?}" checkout "tags/${TREECORR_GIT_TAG:?}" -b "${TREECORR_GIT_TAG:?}TMP" \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }

  fi

fi

# Download the two additional dependencies now; the compile step is offline.
mkdir -p "${PACKDIR:?}/cocoa_dependencies" \
  || { error "TREECORR DEPENDENCY DIRECTORY"; return 1; }
${PIP3:?} download --no-deps --only-binary=:all: \
  --dest "${PACKDIR:?}/cocoa_dependencies" \
  "LSSTDESC.Coord==${TREECORR_COORD_VERSION:?}" \
  "pybind11==${TREECORR_PYBIND11_VERSION:?}" \
  >>${OUT1:?} 2>>${OUT2:?} || { error "TREECORR DEPENDENCIES"; return 1; }

# Upstream enables fast-math. Cocoa preserves ordinary floating-point rules.
# This local build-flag patch is repeatable and leaves the algorithms intact.
${PYTHON3:?} - "${PACKDIR:?}/setup.py" <<'PATCH'
import pathlib
import sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace("'-ffast-math',", ""))
# Clang 21 rejects redundant template disambiguators without explicit
# template arguments. Both calls infer their types from their arguments.
path = path.parent / 'src' / 'Corr3.cpp'
text = path.read_text()
text = text.replace('::template trivial_stop(', '::trivial_stop(')
text = text.replace('::template ProjectWithSq(', '::ProjectWithSq(')
path.write_text(text)
PATCH
if [ "$?" -ne 0 ]; then
  error "TREECORR BUILD FLAGS"; return 1;
fi

cdfolder "${ROOTDIR:?}" || return 1;

pbottom "INSTALLING TREECORR CORRELATION MEASUREMENTS" || { unset_all; return 1; }

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
