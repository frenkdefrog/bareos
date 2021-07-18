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
: "${SLACK_NOTIFICATION:=false}"
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

if [ ${SLACK_NOTIFICATION} == true ]; then
        notification_command="/usr/local/sbin/webhook-notify.sh %t %e %c %l %n"
else
        notification_command="/usr/bin/bsmtp -h localhost -f \\\"\(Bareos\) \<%r\>\\\" -s \\\"Bareos daemon message\\\" %r"
fi

cat <<EOF > /etc/bareos/bareos-dir.d/messages/Daemon.conf
Messages {
  Name = Daemon
  Description = "Message delivery for daemon messages (no job)."
  mailcommand = "${notification_command}"
  mail = root = all, !skipped, !audit # (#02)
  console = all, !skipped, !saved, !audit
  append = "/var/log/bareos/bareos.log" = all, !skipped, !audit
  append = "/var/log/bareos/bareos-audit.log" = audit
}
EOF

cat <<EOF > /etc/bareos/bareos-dir.d/messages/Standard.conf
Messages {
  Name = Standard
  Description = "Reasonable message delivery -- send most everything to email address and to the console."
  operatorcommand = "/usr/bin/bsmtp -h localhost -f \"\(Bareos\) \<%r\>\" -s \"Bareos: Intervention needed for %j\" %r"
  mailcommand = "${notification_command}"
  operator = root = mount                                 # (#03)
  mail = root = all, !skipped, !saved, !audit             # (#02)
  console = all, !skipped, !saved, !audit
  append = "/var/log/bareos/bareos.log" = all, !skipped, !saved, !audit
  catalog = all, !skipped, !saved, !audit
}
EOF

exec /usr/sbin/bareos-dir -f
