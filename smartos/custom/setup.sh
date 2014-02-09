#!/bin/bash
# startup script to configure live os

# change all four variables below


primary="yes"                   # set no if this is replica/backup (secondary) host
host="primary"                  # this machine's name
hostip="192.168.1.3"            # this machine's local IP
replica="backup"                # replica (secondary) host name
replicaip="192.168.1.4"         # replica (secondary) host ip


set -o xtrace

. /lib/svc/share/smf_include.sh

cd /
PATH=/usr/sbin:/usr/bin:/opt/custom/bin:/opt/custom/sbin; export PATH

case "$1" in
'start')

        ### setting up hostname, bashrc, sendmail
        hostname "$host" && hostname > /etc/nodename
        cp /opt/rcfiles/bashrc /root/.bashrc

        echo 'root:  you@example.com' >> /etc/mail/aliases
        newaliases
        svcadm restart sendmail

        ### bzman crontab is here
        if [[ $primary == "yes" ]]; then
	    crontab /opt/rcfiles/root.cron.primary
	else
	    crontab /opt/rcfiles/root.cron.secondary
	fi
        svcadm restart cron

        ### hosts setup here
        echo -e "$hostip\t$host"       >> /etc/hosts
        echo -e "$replicaip\t$replica" >> /etc/hosts

        ### generating key for replica/backup host; other ssh configs in /usbkey
	[[ ! -d /usbkey/config.inc ]] && mkdir /usbkey/config.inc || :
	if [[ $primary == "yes" ]]; then
	    if [[ ! -f /opt/rcfiles/id_rsa ]]; then
		echo 'Generating the key for the first time'
		ssh-keygen -q -t rsa -f /root/.ssh/id_rsa -N ''
		cp /root/.ssh/id_* /opt/rcfiles/
		echo "scp -P22 /root/.ssh/id_rsa.pub $replica:/usbkey/config.inc/authorized_keys" >> /root/.bashrc
	     else
		cp /opt/rcfiles/id_* /root/.ssh/
		cp /root/rcfiles/known_hosts /root/.ssh/
	     fi
	fi
        ;;

'stop')
        ### Insert code to execute on shutdown here.
        ;;

*)
        echo "Usage: $0 { start | stop }"
        exit $SMF_EXIT_ERR_FATAL
        ;;
esac
exit $SMF_EXIT_OK
