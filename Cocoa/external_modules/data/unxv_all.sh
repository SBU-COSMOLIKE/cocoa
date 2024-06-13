#!/bin/bash
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
if [ -z "${ROOTDIR}" ]; then
    echo 'ERROR ROOTDIR not defined'
    return
fi

sh $ROOTDIR/external_modules/data/clean_all.sh 
cd $ROOTDIR/external_modules/data

sh unxv_sn.sh
if [ $? -ne 0 ]; then
  cd $ROOTDIR
  return 1
fi

sh unxv_bao.sh
if [ $? -ne 0 ]; then
  cd $ROOTDIR
  return 1
fi

sh unxv_h0licow.sh
if [ $? -ne 0 ]; then
  cd $ROOTDIR
  return 1
fi

sh unxv_act_dr6.sh
if [ $? -ne 0 ]; then
  cd $ROOTDIR
  return 1
fi

sh unxv_simons_observatory.sh
if [ $? -ne 0 ]; then
  cd $ROOTDIR
  return 1
fi

sh unxv_bicep.sh
if [ $? -ne 0 ]; then
  cd $ROOTDIR
  return 1
fi

sh unxv_spt.sh
if [ $? -ne 0 ]; then
  cd $ROOTDIR
  return 1
fi

sh unxv_planck2018_basic.sh
if [ $? -ne 0 ]; then
  cd $ROOTDIR
  return 1
fi

sh unxv_camspec.sh
if [ $? -ne 0 ]; then
  cd $ROOTDIR
  return 1
fi

sh unxv_lipop.sh
if [ $? -ne 0 ]; then
  cd $ROOTDIR
  return 1
fi

cd $ROOTDIR
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------