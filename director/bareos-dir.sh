#!/usr/bin/env bash

: "${DBDRIVER:?DBDRIVER needs to be set}"
: "${PGHOST:?PGHOST needs to be set}"
: "${PGPORT:?PGPORT needs to be set}"
: "${PGDATABASE:?PGDATABASE needs to be set}"
: "${PGUSER:?PGUSER needs to be set}"
: "${PGPASSWORD:?PGPASSWORD needs to be set}"
: "${MAILUSER:?MAILUSER needs to be set}"
: "${MAILHUB:?MAILHUB needs to be set}"
: "${MAILDOMAIN:?MAILDOMAIN needs to be set}"
: "${MAILHOSTNAME:?MAILHOSTNAME needs to be set}"
: "${WEBADMINUSER:?WEBADMINUSER needs to be set}"
: "${WEBADMINPASS:?WEBADMINPASS needs to be set}"
: "${HOST:=""}"

daemon_user=bareos
daemon_group=bareos
DEFCONFIGDIR="/usr/lib/bareos/defaultconfigs/bareos-dir.d/"
CONFIGDIR="/etc/bareos/bareos-dir.d/"

/usr/lib/bareos/scripts/bareos-config deploy_config "$DEFCONFIGDIR" "$CONFIGDIR"
for dir in /etc/bareos/bareos-dir-export/ /etc/bareos/bareos-dir-export/client; do 
    chown ${daemon_user}:${daemon_group} "$dir"
    chmod 755 "$dir"
done

DEFCONFIGDIR="/usr/lib/bareos/defaultconfigs"
CONFIG="bconsole.conf"
TARGET="/etc/bareos/${CONFIG}"
if [ ! -f "${TARGET}" ]; then
    cat ${DEFCONFIGDIR}/${CONFIG} > ${TARGET}
    /usr/lib/bareos/scripts/bareos-config initialize_local_hostname
    /usr/lib/bareos/scripts/bareos-config initialize_passwords
    chown root:${daemon_group} ${TARGET}
    chmod 640 ${TARGET}
fi

cat <<EOF > /etc/bareos/bareos-dir.d/catalog/MyCatalog.conf
Catalog {
  Name = MyCatalog
  dbdriver = "$DBDRIVER"
  dbaddress = "$PGHOST"
  dbport = "$PGPORT"
  dbname = "$PGDATABASE"
  dbuser = "$PGUSER"
  dbpassword = "$PGPASSWORD"
}
EOF

cat <<EOF > /etc/ssmtp/ssmtp.conf
root=$MAILUSER
mailhub=$MAILHUB
rewriteDomain=$MAILDOMAIN
hostname=$MAILHOSTNAME
FromLineOverride=NO
EOF

cat <<EOF > /etc/bareos/bareos-dir.d/console/admin.conf
Console {
	Name = $WEBADMINUSER
	Password = "$WEBADMINPASS"
	Profile = "webui-admin"
	TlsEnable = false
}
EOF

if [ ! -f ${CONFIGDIR}/.dbready ]; then
    until  psql -c "\q"; do
        sleep 5s;
    done

	if [ /usr/lib/bareos/scripts/create_bareos_database~="exists" ]; then
		/usr/lib/bareos/scripts/make_bareos_tables
		/usr/lib/bareos/scripts/grant_bareos_privileges
		touch ${CONFIGDIR}/.dbready
	fi
fi

if [ ! -f ${CONFIGDIR}/.hostready ]; then
	echo ${HOST} >> /etc/hosts && touch ${CONFIGDIR}/.hostready	
fi

exec /usr/sbin/bareos-dir -f
