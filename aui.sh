#!/bin/bash

if [[ -f `pwd`/sharedfuncs ]]; then
  source sharedfuncs
else
  echo "missing file: sharedfuncs"
  exit 1
fi

#pacstrap ${MOUNTPOINT} kdebase networkmanager kdeplasma-applets-plasma-nm