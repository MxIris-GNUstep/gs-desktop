#!/bin/bash

unset TERM
XID="$1"
vlc -q -I rc --rc-show-pos --no-playlist-autostart --drawable-xid "$XID" "$2"
