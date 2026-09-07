#!/bin/bash
# Args: $1=icon_bg  $2=surface_bg  $3=fg_color
bat=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' 2>/dev/null | head -1)
[ -z "$bat" ] && exit 0

capacity=$(cat "$bat/capacity" 2>/dev/null) || exit 0
status=$(cat "$bat/status" 2>/dev/null)

case 1 in
  # if status is Charging or Full, show the charging icon
  $([ "$status" = "Charging" ] && echo 1)) icon="󰂄" ;;
  $([ "$status" = "Full" ] && echo 1))     icon="󰂄" ;;
  $([ "$capacity" -ge 90 ] && echo 1))     icon="󰁹" ;;
  $([ "$capacity" -ge 70 ] && echo 1))     icon="󰂁" ;;
  $([ "$capacity" -ge 50 ] && echo 1))     icon="󰁾" ;;
  $([ "$capacity" -ge 30 ] && echo 1))     icon="󰁻" ;;
  *)                                       icon="󰁺" ;;
esac

echo "#[bg=${1},fg=${2}]#[reverse]#[noreverse]${icon} #[fg=${3},bg=${2}] ${capacity}% "
