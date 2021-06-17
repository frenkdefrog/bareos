#!/usr/bin/env bash

datasets="voldemortpool/ROOT/ubuntu voldemortpool/datas/docker voldemortpool/home voldemortpool/root voldemortpool/srv voldemortpool/tmp voldemortpool/var/cache voldemortpool/var/cache/apt voldemortpool/var/lib/apt voldemortpool/var/lib/dpkg voldemortpool/var/log voldemortpool/var/mail voldemortpool/var/spool voldemortpool/var/tmp"

function chkdataset {
	zfs list $1>/dev/null 2>/dev/null
	return $?
}

function mksnap {
for ds in $datasets ; do
	if chkdataset ${ds}@backup ; then
		eco "ERROR: dataset ($ds) snapshot exists"
		exit 2
	else
	 zfs snapshot ${ds}@backup
	fi
done
}

function rmsnap {
for ds in $datasets ; do
	if chkdataset ${ds}@backup ; then
		zfs destroy ${ds}@backup
	fi
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
