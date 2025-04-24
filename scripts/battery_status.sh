#!/bin/bash

BAT="BAT1"
BAT_PATH="/sys/class/power_supply/$BAT"

if [ ! -e "$BAT_PATH" ]; then
  echo "Battery $BAT not found."
  exit 1
fi

capacity=$(<"$BAT_PATH/capacity")
status=$(<"$BAT_PATH/status")

low=20
full=79

case "$status" in
  "Charging")
    echo "charging"
    ;;
  "Discharging")
    if [ "$capacity" -le "$low" ]; then
      echo "discharging-low"
    else
      echo "discharging"
    fi
    ;;
  "Not charging")
    if [ "$capacity" -ge "$full" ]; then
      echo "full"
    else
      echo "not-charging"
    fi
    ;;
  *)
    echo "unknown"
    ;;
esac

