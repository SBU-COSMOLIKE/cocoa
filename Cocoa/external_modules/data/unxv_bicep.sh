#!/bin/bash

if [ -z "${ROOTDIR}" ]; then
    echo 'ERROR ROOTDIR not defined'
    return
fi

if [ -z "${DEBUG_UNXV_CLEAN_ALL}" ]; then
  export OUTPUT_UNXV_ALL_1="/dev/null"
  export OUTPUT_UNXV_ALL_2="/dev/null"
else
  export OUTPUT_UNXV_ALL_1="/dev/tty"
  export OUTPUT_UNXV_ALL_2="/dev/tty"
fi

cd $ROOTDIR/external_modules/data

if [ -z "${SKIP_DECOMM_SPT}" ]; then
  echo -e '\033[0;32m'"\t\t DECOMPRESSING BICEP 2015 DATA"'\033[0m'
  
  cd $ROOTDIR/external_modules/data
  tar xf bicep_keck_2015.xz
  
  echo -e '\033[0;32m'"\t\t DECOMPRESSING BICEP 2015 DATA DONE"'\033[0m'
fi

cd $ROOTDIR/