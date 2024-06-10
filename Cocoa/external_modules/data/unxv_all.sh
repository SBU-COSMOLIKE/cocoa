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

sh $ROOTDIR/external_modules/data/clean_all.sh 
cd $ROOTDIR/external_modules/data

sh unxv_sn.sh

sh unxv_bao.sh

sh unxv_h0licow.sh

sh unxv_act_dr6.sh

sh unxv_simons_observatory.sh

sh unxv_bicep.sh

sh unxv_spt.sh

sh unxv_planck2018_basic.sh

cd $ROOTDIR
