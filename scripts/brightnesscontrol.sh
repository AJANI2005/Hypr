#!/usr/bin/env bash

print_usage() {
  cat <<EOF
Usage: $(basename "${0}") <action> [value] 

Actions:
    i    <i>ncrease brightness [+value%] [default: 5]
    d    <d>ecrease brightness [-value%] [default: 5]
    s    <s>et brightness to exact value (0-100%)

Examples:
    $(basename "${0}") i 10    # Increase brightness by 10%
    $(basename "${0}") d       # Decrease brightness by default step (5%)
    $(basename "${0}") s 40    # Set brightness to 40%
EOF
  exit 1
}

send_notification() {
  local delta=$1
  brightness=$(brightnessctl info | grep -oP "(?<=\()\d+(?=%)")
  brightness_level=$((brightness / 15 + 1))
  ico="$HOME/.config/dunst/icons/brightness-${brightness_level:-4}.svg"
  notify-send -a "brightnesscontrol.sh" -r 1 -t 800 -h int:value:"${brightness}" -i "${ico}" "Brightness" "${brightness}% (${delta})"
}

get_brightness() {
  brightnessctl -m | grep -o '[0-9]\+%' | head -c-2
}

clamp_brightness() {
  local new_brightness=$1
  if (( new_brightness > 100 )); then
    echo 100
  elif (( new_brightness < 1 )); then
    echo 1
  else
    echo "$new_brightness"
  fi
}

step="${2:-5}"

case $1 in
i | -i)
  brightness=$(get_brightness)
  [ "$brightness" -lt 10 ] && step=1
  new_brightness=$((brightness + step))
  new_brightness=$(clamp_brightness "$new_brightness")
  delta="+${step}%"
  brightnessctl set "${new_brightness}%"
  send_notification "$delta"
  ;;
d | -d)
  brightness=$(get_brightness)
  [ "$brightness" -le 10 ] && step=1
  new_brightness=$((brightness - step))
  new_brightness=$(clamp_brightness "$new_brightness")
  delta="-${step}%"
  brightnessctl set "${new_brightness}%"
  send_notification "$delta"
  ;;
s | -s)
  if [[ -z "$2" || ! "$2" =~ ^[0-9]+$ ]]; then
    echo "Please provide a numeric brightness value (0-100)."
    print_usage
  fi
  new_brightness=$(clamp_brightness "$2")
  delta="set to ${new_brightness}%"
  brightnessctl set "${new_brightness}%"
  send_notification "$delta"
  ;;
*)
  print_usage
  ;;
esac

