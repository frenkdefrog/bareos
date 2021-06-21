#!/usr/bin/env bash

: "${DIRADDRESS:?DIRADDRESS needs to be set}"
: "${DIRPORT:?DIRPORT needs to be set}"

#this patch needed to prevent filling the disk with error messages if a wrong username/password is provided to webui
sed -i 's/send === 0/send === false/g' /usr/share/bareos-webui/vendor/Bareos/library/Bareos/BSock/BareosBSock.php

cat <<EOF > /etc/bareos-webui/directors.ini
[bareos-dir]
enabled = "yes"
diraddress = "$DIRADDRESS"
dirport = $DIRPORT
EOF

: "${APACHE_CONFDIR:=/etc/apache2}"
: "${APACHE_ENVVARS:=$APACHE_CONFDIR/envvars}"
if test -f "$APACHE_ENVVARS"; then
	. "$APACHE_ENVVARS"
fi

# Apache get grumpy about PID files pre-existing
: "${APACHE_RUN_DIR:=/var/run/apache2}"
: "${APACHE_PID_FILE:=$APACHE_RUN_DIR/apache2.pid}"
rm -f "$APACHE_PID_FILE"

exec apache2 -DFOREGROUND "$@"

