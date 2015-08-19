#!/bin/bash
if [ "$(id -u)" != "0" ]; then
   echo "The installer script must be run as root" 1>&2
   exit 1
fi

echo "Installing Tideways Profiler Daemon\n"

INSTALLERDIR=`dirname $0`

if id -u "tideways" >/dev/null 2>&1; then
    echo "User tideways already exists, skipping.."
else
    useradd -r --shell /bin/false -U -M -d /nonexistant tideways
fi

if [ -n "$(pidof tideways-daemon)" ]; then
    /etc/init.d/tideways-daemon stop
fi

cp $INSTALLERDIR/tideways-daemon /usr/bin/tideways-daemon
cp $INSTALLERDIR/tideways-daemon.init /etc/init.d/tideways-daemon

mkdir -p /var/run/tideways
chown tideways.tideways /var/run/tideways

mkdir -p /var/log/tideways
chown tideways.tideways /var/log/tideways

chmod a+x /usr/bin/tideways-daemon
chmod a+x /etc/init.d/tideways-daemon

if type "update-rc.d" 2>/dev/null; then
    update-rc.d tideways-daemon defaults
fi

if type "rc-update" 2>/dev/null; then
    rc-update add tideways-daemon default
fi

if [ -z "$(pidof tideways-daemon)" ]; then
    /etc/init.d/tideways-daemon start
else
    /etc/init.d/tideways-daemon stop
    /etc/init.d/tideways-daemon start
fi
