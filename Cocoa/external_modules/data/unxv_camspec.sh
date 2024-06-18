#!/bin/bash
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
if [ -z "${SKIP_DECOMM_CAMSPEC}" ]; then
  if [ -z "${ROOTDIR}" ]; then
      echo 'ERROR ROOTDIR not defined'
      return
  fi

  if [ -z "${DEBUG_UNXV_CLEAN_ALL}" ]; then
    export OUT1="/dev/null"
    export OUT2="/dev/null"
  else
    export OUT1="/dev/tty"
    export OUT2="/dev/tty"
  fi

  cd $ROOTDIR/external_modules/data

  echo -e '\033[0;32m'"\t\t DECOMPRESSING CAMSPEC DATA"'\033[0m'

  rm -f  $ROOTDIR/external_modules/data/planck/CamSpec/CamSpec2021.zip
  rm -rf $ROOTDIR/external_modules/data/planck/CamSpec/CamSpec2021

  cd  $ROOTDIR/external_modules/data/planck/CamSpec/
  
  export CAMSPEC_URL="https://github.com/CobayaSampler/planck_native_data/releases/download/v1/CamSpec2021.zip"

  wget $CAMSPEC_URL > ${OUT1} 2> ${OUT2}
  if [ $? -ne 0 ]; then 
    echo -e '\033[0;31m'"\t\t DECOMPRESSING CAMSPEC FAILED"'\033[0m'
    cd $ROOTDIR
    unset OUT1
    unset OUT2
    unset CAMSPEC_URL
    return 1
  fi
  
  unzip CamSpec2021.zip > ${OUT1} 2> ${OUT2}
  if [ $? -ne 0 ]; then
    echo -e '\033[0;31m'"\t\t DECOMPRESSING CAMSPEC FAILED"'\033[0m'
    cd $ROOTDIR
    unset OUT1
    unset OUT2
    unset CAMSPEC_URL
    return 1
  fi

  rm -f  $ROOTDIR/external_modules/data/planck/CamSpec/CamSpec2021.zip

  cd $ROOTDIR/
  unset OUT1
  unset OUT2
  unset CAMSPEC_URL
  echo -e '\033[0;32m'"\t\t DECOMPRESSING CAMSPEC DATA DONE"'\033[0m'
fi
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------