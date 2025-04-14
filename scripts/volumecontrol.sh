#!/usr/bin/env bash

print_usage() {
  cat <<EOF
Usage: $(basename "$0") <action> [step]

Actions:
    i    <i>ncrease volume [+5%]
    d    <d>ecrease volume [-5%]
    m    toggle <m>ute

Optional:
    step  volume change step [default: 5]

Examples:
    $(basename "$0") i 10    # Increase volume by 10%
    $(basename "$0") m       # Toggle mute
EOF
  exit 1
}

notify_vol() {
  local vol=$1
  local delta=$2
  level=$((vol / 34 + 1))
  muted=""
  mute=$(pamixer --get-mute | cat)
  [ "${mute}" = "true" ] && muted=" (Muted)"
  notify-send -a "volumecontrol.sh" -r 2 -t 800 -h int:value:"${vol}" -i "${icodir}/volume-${level}.svg" "Volume${muted}" "${vol} (${delta})"
}

notify_mute() {
  mute=$(pamixer --get-mute | cat)
  vol=$(pamixer --get-volume)
  if [ "${mute}" == "true" ]; then
    notify-send -a "volumecontrol.sh" -r 2 -t 800 -h int:value:"${vol}" -i "${icodir}/muted.svg" "muted" "${vol}"
  else
    notify-send -a "volumecontrol.sh" -r 2 -t 800 -h int:value:"${vol}" -i "${icodir}/volume-3.svg" "unmuted" "${vol}"
  fi
}

change_volume() {
  local action=$1
  local step=$2
  local sign="-"

  [ "${action}" = "i" ] && sign="+"

  vol=$(pamixer --get-volume)

  # Ensure volume is within bounds
  if [ "${sign}" = "+" ] && [ "${vol}" -ge 100 ]; then
    notify_vol 100 "..."
    return 0
  elif [ "${sign}" = "-" ] && [ "${vol}" -le 0 ]; then
    notify_vol 0 "..."
    return 0
  fi

  # Adjust volume
  wpctl set-volume @DEFAULT_SINK@ "$step%$sign"
  vol=$(pamixer --get-volume)

  # Clamp volume to 0-100%
  if [ "${vol}" -gt 100 ]; then
    vol=100
    wpctl set-volume @DEFAULT_SINK@ 100%
  elif [ "${vol}" -lt 0 ]; then
    vol=0
    wpctl set-volume @DEFAULT_SINK@ 0%
  fi

  [ "${action}" = "d" ] && sign="\-"
  notify_vol "$vol" "$sign$step%"
}

toggle_mute() {
  wpctl set-mute @DEFAULT_SINK@ toggle
  notify_mute
}

step=${VOLUME_STEPS:-5}
icodir="$HOME/.config/dunst/icons"

# Execute action
case $1 in
i | d) change_volume "$1" "${2:-$step}" ;;
m) toggle_mute ;;
*) print_usage ;;
esac
