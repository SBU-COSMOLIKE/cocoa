#!/bin/bash
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
if [ -z "${IGNORE_POLYCHORD_COMPILATION}" ]; then
  echo -e '\033[1;34m''\tCLEANING POLYCHORD''\033[0m'

  if [ -z "${ROOTDIR}" ]; then
      echo -e '\033[0;31m''ERROR ENV VARIABLE ROOTDIR IS NOT DEFINED''\033[0m'
      return 1
  fi
  if [ -z "${PYTHON3}" ]; then
      echo -e '\033[0;31m''ERROR ENV VARIABLE PYTHON3 IS NOT DEFINED''\033[0m'
      cd $ROOTDIR
      return 1
  fi
  if [ -z "${PYTHON_VERSION}" ]; then
    echo -e '\033[0;31m''ERROR ENV VARIABLE PYTHON_VERSION IS NOT DEFINED''\033[0m'
    cd $ROOTDIR
    return 1
  fi
  if [ -z "${DEBUG_POLY_OUTPUT}" ]; then
    export OUTPUT_POLY_1="/dev/null"
    export OUTPUT_POLY_2="/dev/null"
  else
    export OUTPUT_POLY_1="/dev/tty"
    export OUTPUT_POLY_2="/dev/tty"
  fi

  rm -rf $ROOTDIR/.local/lib/python$PYTHON_VERSION/site-packages/pypolychord-*

  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------
  cd $ROOTDIR/external_modules/code/PolyChordLite/
  # ---------------------------------------------------------------------------
  # ---------------------------------------------------------------------------

  make clean > ${OUTPUT_POLY_1} 2> ${OUTPUT_POLY_2}
  if [ $? -ne 0 ]; then
    echo -e '\033[0;31m'"POLYCHORD COULD NOT RUN \e[3mMAKE CLEAN"'\033[0m'
  else
    echo -e '\033[0;32m'"\t\t POLYCHORD RUN \e[3mMAKE CLEAN\e[0m\e\033[0;32m DONE"'\033[0m'
  fi

  rm -rf ./lib/*.a
  rm -rf ./lib/*.so

  cd $ROOTDIR
  unset OUTPUT_POLY_1
  unset OUTPUT_POLY_2
  unset POLY_MAKE_NUM_THREADS
  echo -e '\033[1;34m''\t\e[4mCLEANING POLYCHORD DONE''\033[0m'
fi
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------