#!/bin/bash

# Read the first CPU sample directly from the kernel
read -r cpu user nice system idle iowait irq softirq steal _ < /proc/stat
idle1=$idle
total1=$((user + nice + system + idle + iowait + irq + softirq + steal))

# Wait a tiny fraction of a second to get a differential
sleep 1

# Read the second CPU sample
read -r cpu user nice system idle iowait irq softirq steal _ < /proc/stat
idle2=$idle
total2=$((user + nice + system + idle + iowait + irq + softirq + steal))

# Calculate the difference
total_diff=$((total2 - total1))
idle_diff=$((idle2 - idle1))

# Prevent division by zero and output the percentage
if [ "$total_diff" -eq 0 ]; then
    echo "0%"
else
    usage=$(( 100 * (total_diff - idle_diff) / total_diff ))
    echo "${usage}%"
fi
