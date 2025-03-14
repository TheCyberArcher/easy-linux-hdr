#!/bin/bash

usage() { echo "Usage: $0 <on|off>" 1>&2; exit 1; }

action=${1};

if [ -z $action ];
then
  if [ "$(kscreen-doctor -o >> hdr.conf | grep -cm1 "HDR: enabled")" -ge 1 ];
  then
    action="off";
  else
    action="on";
  fi;
fi;

if [ ${action} == "on" ];
then
  echo "Enabling HDR"
  kscreen-doctor output.DP-2.wcg.enable output.DP-2.hdr.enable output.DP-2.brightness.100;
elif [ ${action} == "off" ];
then
  echo "Disabling HDR"
  kscreen-doctor output.DP-2.wcg.disable output.DP-2.hdr.disable output.DP-2.brightness.30;
else
  usage;
fi;
