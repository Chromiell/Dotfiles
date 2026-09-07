#!/bin/bash

# Get the creation time from the argument passed by tmux
created=$1
now=$(date +%s)
s=$((now - created))

# Calculate hours, minutes, seconds
h=$((s / 3600))
m=$(( (s % 3600) / 60 ))
s=$((s % 60))

out=""

# Only add segments if they are greater than 0
[ $h -gt 0 ] && out="${h}h "
[ $m -gt 0 ] && out="${out}${m}m "
[ $s -gt 0 ] && out="${out}${s}s"

# If the session just started and out is empty, show 0s
echo "${out:-0s}"
