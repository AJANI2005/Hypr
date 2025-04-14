
#!/bin/bash

BATTERY_PATH="/sys/class/power_supply/BAT1"
STATE_FILE="$HOME/.battery_state"

# Ensure battery path exists
if [ ! -e "$BATTERY_PATH" ]; then
  echo "Battery path $BATTERY_PATH not found."
  exit 1
fi

# Read current battery info
capacity=$(<"$BATTERY_PATH/capacity")
status=$(<"$BATTERY_PATH/status")

# Load last state
[ -f "$STATE_FILE" ] && last_state=$(<"$STATE_FILE") || last_state="none"

notify_and_update() {
  notify-send -u normal "$1"
  echo "$2" > "$STATE_FILE"
}

# Notify based on battery status and avoid spamming
if [[ "$status" == "Charging" && "$capacity" -eq 100 && "$last_state" != "battery_full" ]]; then
  notify_and_update "Battery Full" "battery_full"

elif [[ "$status" == "Discharging" && "$capacity" -le 20 && "$last_state" != "battery_low" ]]; then
  notify_and_update "Battery Low" "battery_low"

elif [[ "$status" == "Charging" && "$last_state" != "plugged_in" && "$capacity" -lt 100 ]]; then
  notify_and_update "Power Plugged In" "plugged_in"

elif [[ "$status" == "Discharging" && "$last_state" != "plugged_out" ]]; then
  notify_and_update "Power Unplugged" "plugged_out"
fi

