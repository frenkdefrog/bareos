#!/usr/bin/env bash

DIR="/mnt/backup"
test -d ${DIR} || mkdir -p ${DIR}

VG=vg
LVS="root home etc"
SNAPSIZE="5G"

##Snapshot of LVS
LVC="/sbin/lvcreate"
LVRM="/sbin/lvremove -f"

function msnap {
for LV in $LVS ; do
	if [ -e /dev/${VG}/${LV}-bs ] ; then
		echo "ERROR: the snapshot exists..."
		$LVRM /dev/${VG}/${LV}-bs || exit 1
	fi
	sync
	$LVC -s -L ${SNAPSIZE} -n ${LV}-bs /dev/${VG}/${LV} > /dev/null || exit 2
	[ -d ${DIR}/${VG}/${LV} ] || mkdir -p ${DIR}/${VG}/${LV}
	mount -o ro /dev/${VG}/${LV}-bs ${DIR}/${VG}/${LV}
done
}

function rmsnap {
for LV in $LVS ; do
	umount ${DIR}/${VG}/${LV} || exit 4
	$LVRM /dev/${VG}/${LV}-bs > /dev/null || exit 5
done
}

case $1 in
	"create")
		mksnap
		;;
	"remove")
		rmsnap
		;;
	*)
		echo "ERROR: bad option"
		exit 1
		;;
esac

