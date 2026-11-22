#!/bin/bash
# ------------------------------------------------------------------------------
# setup_cobaya.sh: download Cobaya (the Bayesian analysis framework Cocoa
# drives).
#
# Sourced, never executed (only `source` keeps its environment changes).
# setup_cocoa.sh runs it during a full installation, and sourcing it on its
# own redoes just this package (see the README FAQ on installing a single
# package). Setup scripts MAY use the internet (git clone, wget, pip index);
# the matching compile step never does, so anything that must be downloaded
# happens here.
#
# Skipped (return 99) when IGNORE_COBAYA_CODE is set. Reruns are safe:
# existing results are kept unless OVERWRITE_EXISTING_COBAYA_CODE is set. On
# failure error() names the failing step and unsets everything defined here;
# on success the script returns 55, the value the runner caches so a finished
# step is not repeated.
# ------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------
if [ -n "${IGNORE_COBAYA_CODE:-}" ]; then
  return 99
fi

if [ -z "${ROOTDIR}" ]; then
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
  unset -v COB CCCOB COBLIKE COBTH URL TFILE TFOLDER
  cdroot || return 1;
}

# unset_env_funcs: forget every helper function defined below (functions leak
# into the user's shell exactly like variables).
unset_env_funcs () {
  unset -f gitclone gitfetch
  unset -f cdfolder cpfolder error cpfile cppatch cppatchfolder
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

# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------

unset_env_vars || return 1

CCIL="${ROOTDIR:?}/../cocoa_installation_libraries" # IL = installation lib

COB="${ROOTDIR:?}/cobaya"        # COB = Cobaya

CCCOB="${CCIL:?}/cobaya_changes"  # CC = CoCoA, COB = Cobaya (Cocoa Cobaya)

COBLIKE="cobaya/likelihoods"      # COB = Cobaya, LIKE = likelihoods

COBTH="cobaya/theories"           # COB = Cobaya, TH = theory

cppatch() {
  cp "${CCCOB:?}/${1:?}/${2:?}" "${COB:?}/${1:?}" || 
    { error "CP FILE ${CCCOB:?}/${1:?}/${2:?} on ${COB:?}/${1:?}"; return 1; }
}

cppatchfolder() {
  cp -r "${CCCOB:?}/${1:?}/${2:?}" "${COB:?}/${1:?}" || 
    { error "CP FOLDER ${CCCOB:?}/${1:?}/${2:?} on ${COB:?}/${1:?}"; \
    return 1; }
}

# ----------------------------------------------------------------------------
  
ptop "SETUP COBAYA" || { unset_all; return 1; }

#-----------------------------------------------------------------------------
# Remove any previous installed cobaya folder --------------------------------
#-----------------------------------------------------------------------------
if [ -n "${OVERWRITE_EXISTING_COBAYA_CODE:-}" ]; then

  rm -rf "${ROOTDIR:?}/cobaya"

fi

SETUP_NEW_CLONE=0
if [ ! -d "${ROOTDIR:?}/cobaya" ]; then
  SETUP_NEW_CLONE=1

  #-----------------------------------------------------------------------------
  # Clone Cobaya from original git repo ----------------------------------------
  #-----------------------------------------------------------------------------
  cdfolder "${ROOTDIR:?}" || return 1;
  
  URL="${COBAYA_URL:-"https://github.com/CobayaSampler/cobaya.git"}"

  gitclone cobaya "${URL:?}" --depth ${GIT_CLONE_MAXIMUM_DEPTH:-1000} --recursive --no-single-branch \
    >>${OUT1:?} 2>>${OUT2:?} || { error "${EC15:?}"; return 1; }
  
  unset URL
  
fi

# Resolve the requested revision on reruns too. A local pin needs no fetch.
cdfolder "${COB:?}" || return 1;
if [ ! -d .git ] && [ ! -f .git ]; then
  error "DIRECTORY IS NOT A GIT CHECKOUT: ${COB}"; return 1;
fi
REQUESTED_REF=""
if [ -n "${COBAYA_GIT_COMMIT:-}" ]; then
  REQUESTED_REF="${COBAYA_GIT_COMMIT}"
elif [ -n "${COBAYA_GIT_BRANCH:-}" ]; then
  REQUESTED_REF="origin/${COBAYA_GIT_BRANCH}"
elif [ -n "${COBAYA_GIT_TAG:-}" ]; then
  REQUESTED_REF="refs/tags/${COBAYA_GIT_TAG}"
fi
if [ -n "${REQUESTED_REF}" ]; then
  if ! "${GIT:?}" cat-file -e "${REQUESTED_REF}^{commit}" 2>/dev/null; then
    gitfetch >>${OUT1:?} 2>>${OUT2:?} || { error "COBAYA GIT FETCH"; return 1; }
  fi
  if [ -z "${COBAYA_GIT_COMMIT:-}" ] && [ -n "${COBAYA_GIT_BRANCH:-}" ]; then
    # Keep an existing local branch (including local commits); do not reset it.
    if "${GIT:?}" show-ref --verify --quiet "refs/heads/${COBAYA_GIT_BRANCH}"; then
      "${GIT:?}" checkout "${COBAYA_GIT_BRANCH}" \
        >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
    else
      "${GIT:?}" checkout -b "${COBAYA_GIT_BRANCH}" "${REQUESTED_REF}" \
        >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
    fi
  else
    # Detached tags and commits are repeatable without creating a TMP branch.
    "${GIT:?}" checkout --detach "${REQUESTED_REF}" \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC16:?}"; return 1; }
  fi
fi

if [ "${SETUP_NEW_CLONE}" = 1 ]; then
  cdfolder "${ROOTDIR:?}" || return 1;

  #-----------------------------------------------------------------------------
  # Adjust Cobaya Files --------------------------------------------------------
  #-----------------------------------------------------------------------------
  
  TFILE="change_python_files.sh" # T = TMP
  
  cppatch "cobaya" "${TFILE:?}" || return 1;

  cdfolder "${COB:?}/cobaya/" || return 1;
  
  # parenthesis = run in a subshell
  ( sh change_python_files.sh ) || { error "${EC22:?} (CPF)"; return 1; }

  # --------------------------------------------------------------------------
  # PATCH FILE --------------------------------------------- -----------------
  # --------------------------------------------------------------------------  
  # instead of using JAX-CLIK - uses the original CLIK in FORTRAN
  declare -a TFOLDER=("cobaya/likelihoods/base_classes/") # Must include  
  declare -a TFILE=("planck_clik.py")
  declare -a TFILEP=("planck_clik.patch")

  for (( i=0; i<${#TFOLDER[@]}; i++ ));
  do
    cdfolder "${COB:?}/${TFOLDER[$i]}" || return 1;
  
    cpfolder "${CCCOB:?}/${TFOLDER[$i]}${TFILEP[$i]:?}" . \
      2>>${OUT2:?} || return 1;
  
   patch --quiet --batch --verbose -u -R "${TFILE[$i]:?}" -i "${TFILEP[$i]:?}" \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC17:?} (${TFILE[$i]:?})"; return 1; }
  done

  # --------------------------------------------------------------------------
  # PATCH FILE2 --------------------------------------------- -----------------
  # --------------------------------------------------------------------------  
  declare -a TFOLDER=("cobaya/") # Must include  
  declare -a TFILE=("model.py")
  declare -a TFILEP=("model.patch")

  for (( i=0; i<${#TFOLDER[@]}; i++ ));
  do
    cdfolder "${COB:?}/${TFOLDER[$i]}" || return 1;
  
    cpfolder "${CCCOB:?}/${TFOLDER[$i]}${TFILEP[$i]:?}" . \
      2>>${OUT2:?} || return 1;
  
    # HERE I CAN't USE THE -R
    patch --quiet --batch --verbose -u "${TFILE[$i]:?}" -i "${TFILEP[$i]:?}" \
      >>${OUT1:?} 2>>${OUT2:?} || { error "${EC17:?} (${TFILE[$i]:?})"; return 1; }
  done
  
  cdfolder "${ROOTDIR:?}" || return 1;
  
  unset -v TFILE

  #-----------------------------------------------------------------------------
  # Adjust SN / STRONG LENSING -------------------------------------------------
  #-----------------------------------------------------------------------------
  
  TFOLDER="${COBLIKE:?}/sn" # T = TMP

  cp "${CCCOB:?}/${TFOLDER:?}/"roman_* "${COB:?}/${TFOLDER:?}/" \
    2>>${OUT2:?} || { error "CP ROMAN FILES"; return 1; }

  cppatchfolder "${COBLIKE:?}" "h0licow" || return 1;

  unset -v TFOLDER

  #-----------------------------------------------------------------------------
  # Remove native DES-Y1 cobaya likelihood -------------------------------------
  #-----------------------------------------------------------------------------
  
  rm -rf "${COB:?}/${COBLIKE:?}/des_y1"

  #-----------------------------------------------------------------------------
  # Remove Planck 2015 likelihood files ----------------------------------------
  #-----------------------------------------------------------------------------
  
  rm -rf "${COB:?}/${COBLIKE:?}"/planck_2015_*

  #-----------------------------------------------------------------------------
  # Adjust Planck 2018 CLIK ----------------------------------------------------
  #-----------------------------------------------------------------------------
  
  TFOLDER="${COBLIKE:?}/base_classes" # T = TMP
  
  cppatch "${TFOLDER:?}" "change_planck_clik.sh" || return 1

  cdfolder "${COB:?}/${TFOLDER}" || return 1;
  
  # parenthesis = run in a subshell
  ( sh change_planck_clik.sh ) || { error "${EC22:?} (CPC)"; return 1; }
  
  unset -v TFOLDER

  cdfolder "${ROOTDIR:?}" || return 1;

  #---------------------------------------------------------------------------
  # Adjust Planck 2018 low-ell -----------------------------------------------
  #---------------------------------------------------------------------------
  
  # note 1: we remove Cobaya native python CLIK implementation
  # note 2: In the original Cobaya, TT_clik.py/EE_clik.py are the files 
  # note 2: associated with CLIK. We rename them to simply TT/EE.py
  
  TFOLDER="${COBLIKE:?}/planck_2018_lowl"
  
  rm -f "${COB:?}/${TFOLDER:?}/EE_clik.py"
  rm -f "${COB:?}/${TFOLDER:?}/EE_clik.yaml"
  rm -f "${COB:?}/${TFOLDER:?}/EE_sroll2.py"
  #rm -f "${COB:?}/${TFOLDER:?}/EE_sroll2.bibtex"

  cppatch "${TFOLDER:?}" "EE.py" || return 1;

  cppatch "${TFOLDER:?}" "EE.yaml" || return 1;

  cppatch "${TFOLDER:?}" "TT.py" || return 1;

  cppatch "${TFOLDER:?}" "TT.yaml" || return 1;

  cppatch "${TFOLDER:?}" "EE_sroll2.py" || return 1;

  unset -v TFOLDER
  
  #-----------------------------------------------------------------------------
  # Adjust Planck 2018 lensing -------------------------------------------------
  #-----------------------------------------------------------------------------
  
  # note: we remove Cobaya native python CLIK implementation

  TFOLDER="${COBLIKE:?}/planck_2018_lensing"
  
  rm -f "${COB:?}/${TFOLDER:?}/CMBMarged.yaml"
  rm -f "${COB:?}/${TFOLDER:?}/native.yaml"

  cppatch "${TFOLDER:?}" "clik.yaml" || return 1;

  unset -v TFOLDER

  #-----------------------------------------------------------------------------
  # Adjust Planck 2018 high-ell (Plik) -----------------------------------------
  #-----------------------------------------------------------------------------
  
  # note 1: we remove Cobaya native python CLIK implementation
  # note 2: we remove unbinned likelihood for now 

  TFOLDER="${COBLIKE:?}/planck_2018_highl_plik"  # T = TMP
  
  rm -f "${COB:?}/${TFOLDER:?}/TTTEEE_unbinned.py"
  rm -f "${COB:?}/${TFOLDER:?}/TTTEEE_unbinned.yaml"
  rm -f "${COB:?}/${TFOLDER:?}/TT_unbinned.py"
  rm -f "${COB:?}/${TFOLDER:?}/TT_unbinned.yaml"
  rm -f "${COB:?}/${TFOLDER:?}/TTTEEE_lite_native.py"
  rm -f "${COB:?}/${TFOLDER:?}/TTTEEE_lite_native.yaml"
  rm -f "${COB:?}/${TFOLDER:?}/TT_lite_native.py"
  rm -f "${COB:?}/${TFOLDER:?}/TT_lite_native.yaml"

  cppatch "${TFOLDER:?}" "EE.yaml" || return 1;
  
  cppatch "${TFOLDER:?}" "TE.yaml" || return 1;
  
  cppatch "${TFOLDER:?}" "TT.yaml" || return 1;
  
  cppatch "${TFOLDER:?}" "TTTEEE.yaml" || return 1;
  
  cppatch "${TFOLDER:?}" "TT_lite.yaml" || return 1;
  
  cppatch "${TFOLDER:?}" "TTTEEE_lite.yaml" || return 1;
  
  unset -v TFOLDER

  #-----------------------------------------------------------------------------
  # SPT3G Y1 LIKELIHOOD --------------------------------------------------------
  #-----------------------------------------------------------------------------

  cppatchfolder "${COBLIKE:?}" "SPT3G_Y1" || return 1;
  
  #-----------------------------------------------------------------------------
  # ACT DR6 LENSLIKE LIKELIHOOD ------------------------------------------------
  #-----------------------------------------------------------------------------

  cppatchfolder "${COBLIKE:?}" "act_dr6_lenslike" || return 1;
  
  #-----------------------------------------------------------------------------
  # Fix renaming parameters in CAMB --------------------------------------------
  #-----------------------------------------------------------------------------
  
  cppatch "${COBTH:?}/camb" "camb.yaml" || return 1;

  #---------------------------------------------------------------------------
  # CAMSPEC ------------------------------------------------------------------
  #---------------------------------------------------------------------------
  
  cppatch "${COBLIKE}/base_classes" "InstallableLikelihood.patch" || return 1;
  
  cdfolder "${COB:?}/${COBLIKE}/base_classes/" || return 1;
  
  patch --quiet --batch --verbose -u "InstallableLikelihood.py" -i "InstallableLikelihood.patch" \
    >>${OUT1:?} 2>>${OUT2:?} || { error "${EC17:?}"; return 1; }
  
  cdfolder "${ROOTDIR:?}" || return 1;

  # ----------------------------------------------------------------------------
  # PIP COBAYA -----------------------------------------------------------------
  # ----------------------------------------------------------------------------
  
  ${PIP3:?} install --editable cobaya --prefix="${ROOTDIR:?}/.local" \
    >>"${OUT1:?}" 2>>"${OUT2:?}" || { error "${EC13:?}"; return 1; }

  #-----------------------------------------------------------------------------

fi

pbottom "SETUP COBAYA" || { unset_all; return 1; }

cdfolder "${ROOTDIR:?}" || return 1;

#-----------------------------------------------------------------------------

unset_all || return 1;

#-----------------------------------------------------------------------------

return 55; # why this odd number? Setup_cocoa will cache this installation only
           #   if this script runs entirely. What if the user close the terminal 
           #   or the system shuts down in the middle of a git clone?  
           #   In this case, PACKDIR would exists, but it is corrupted
           
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
