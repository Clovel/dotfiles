#!/usr/bin/env sh
# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -x polybar >/dev/null; do
    sleep 1;
done

# Launch bar for each
if type "xrandr"; then
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        env SHELL=/bin/sh MONITOR=$m polybar main &
    done
    
    echo "Bars launched..."
else
    echo "Error: Not using xrandr"
fi
