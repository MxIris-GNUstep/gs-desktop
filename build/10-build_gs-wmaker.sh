#!/bin/sh

. ../BUILD_SETTINGS.conf
. /Developer/Makefiles/GNUstep.sh

unset LD
unset LDFLAGS

cd ../../gs-wmaker || exit 1

gmake clean
if [ -n "$RELEASE_BUILD" ];then
  DEBUG_ARGS=""
else
  DEBUG_ARGS="--enable-debug"
fi

DBINC="`pkg-config --cflags dbus-1`"

export CPPFLAGS="$DBINC -I/usr/local/include -I/usr/include"
export LDFLAGS="-L/usr/local/lib -I/usr/lib -linotify"

./autogen.sh
./configure --prefix=/System $DEBUG_ARGS \
  --enable-randr --enable-dbus || exit 1

gmake $MKARGS || exit 1
gmake install || exit 1
