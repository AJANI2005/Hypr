#!/bin/bash

BAT="BAT1"
BAT_PATH="/sys/class/power_supply/$BAT"
STATE_FILE="/tmp/.battery_notify_state"

# Thresholds
low=20
full=79

# Fallback to BAT0 if BAT1 doesn't exist
if [ ! -e "$BAT_PATH" ]; then
  BAT="BAT0"
  BAT_PATH="/sys/class/power_supply/$BAT"
  if [ ! -e "$BAT_PATH" ]; then
    echo "Battery not found."
    exit 1
  fi
fi

# Check for --ignore option
force_notify=false
if [ "$1" == "--ignore" ]; then
  force_notify=true
fi

capacity=$(<"$BAT_PATH/capacity")
status=$(<"$BAT_PATH/status")

# Determine new state
case "$status" in
  "Charging")
    new_state="charging"
    ;;
  "Discharging")
    if [ "$capacity" -le "$low" ]; then
      new_state="discharging-low"
    else
      new_state="discharging"
    fi
    ;;
  "Not charging")
    if [ "$capacity" -ge "$full" ]; then
      new_state="full"
    else
      new_state="not-charging"
    fi
    ;;
  *)
    new_state="unknown"
    ;;
esac

# Load last known state
last_state="none"
[ -f "$STATE_FILE" ] && last_state=$(<"$STATE_FILE")

# Notify if state changed or forced
if [ "$new_state" != "$last_state" ] || [ "$force_notify" = true ]; then
  case "$new_state" in
    "charging")
      notify-send -u normal "Power Plugged In" "Battery is charging ($capacity%)"
      ;;
    "discharging")
      notify-send -u normal "Power Unplugged" "Running on battery ($capacity%)"
      ;;
    "discharging-low")
      notify-send -u critical "Battery Low" "Battery is low: $capacity%"
      ;;
    "full")
      notify-send -u normal "Battery Full" "You can unplug the charger now."
      ;;
    "not-charging")
      notify-send -u normal "Charger Plugged In" "Not charging (Battery: $capacity%)"
      ;;
    *)
      notify-send -u normal "Battery Status" "Status: $status ($capacity%)"
      ;;
  esac

  # Save new state unless forced (so --ignore doesn’t mess with actual state tracking)
  if [ "$force_notify" = false ]; then
    echo "$new_state" > "$STATE_FILE"
  fi
fi
