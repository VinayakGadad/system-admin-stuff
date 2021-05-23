#!/usr/bin/env bash
# Author Vinayak Gadad
# This script restarts logstash-forwarder and sends an email alert for disk utilization.

df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | while read diskusage;
do
  echo $diskusage
  usepart=$(echo $diskusage | awk '{ print $1}' | cut -d'%' -f1  )
  dskpart=$(echo $diskusage | awk '{ print $2 }' )

  if [ $usepart -ge 90 ]; then
    echo "Running out of space \"$dskpart ($usepart%)\" free > /tmp/TMPFILE

    printf "\nAfter restarting the logstash-forwarder\n" >> /tmp/TMPFILE
    service logstash-forwarder restart
  fi
done
    df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' >> /tmp/TMPFILE

    if [ -f /tmp/TMPFILE ]; then
        cat /tmp/TMPFILE
        cp /tmp/TMPFILE `mktemp -q /tmp/logstash-forwarder.XXXXXX`
        cat /tmp/TMPFILE | mail -s "Alert: Almost out of disk space on $(hostname)" username@email.com
    fi