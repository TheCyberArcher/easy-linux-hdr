SCREEN=$(xrandr --listactivemonitors | awk '{print $NF}' | tail +2)

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
  kscreen-doctor output.$SCREEN.wcg.enable output.$SCREEN.hdr.enable output.$SCREEN.brightness.60;
elif [ ${action} == "off" ];
then
  echo "Disabling HDR"
  kscreen-doctor output.$SCREEN.wcg.disable output.$SCREEN.hdr.disable output.$SCREEN.brightness.30;
else
  usage;
fi;
