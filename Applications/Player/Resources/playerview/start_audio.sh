#!/bin/bash

unset TERM
vlc -q -I rc --rc-show-pos --no-playlist-autostart "$1"
#vlc -I rc --rc-fake-tty --rc-show-pos
#vlc --width 100 --no-autoscale --drawable-xid 0x1a1c516