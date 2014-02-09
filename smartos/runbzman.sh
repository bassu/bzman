#!/bin/bash
# example wrapper to run bzman

export TZ='America/Los_Angeles'
export LC_ALL='en_US.UTF-8'
bzmanpath=/opt/bzman/
dumppath=$bzmanpath/jsondumps/
backupnode=$1

# run only one instance of this wrapper
lockfile=$bzmanpath/bzman.lock
if [[ -f $lockfile ]]; then
	pid=$(head -1 $lockfile)
	[[ $(ps -ef | grep -c $pid) -ge 2 ]] && { echo $0 already running with pid $pid; exit 1; } || { echo Dormant lockfile $lockfile found; exit 1; }
else
	echo $$ > $lockfile
fi

# process the bzman on smartos env
# vmadm=/opt/bzman/vm #customized and tweaked vmadm 
vmadm=$(which vmadm)
json=/usr/bin/json
env=/usr/bin/env
python=/opt/local/bin/python2.6

[[ ! -d "$dumppath" ]] && mkdir $dumppath

for vm in $($vmadm list -H -o uuid type=KVM); do  # selecting on the KVM type virtual machines for now
        echo "$(tput setaf 8)=> Dumping $vm in $dumppath"
	$vmadm get $vm > $dumppath/$vm.json
        disk0=$($vmadm get $vm | $json disks | $json 0 | $json zfs_filesystem)
        echo "$(tput setaf 4)=> Replicating $disk0 $(tput sgr 0)"
        cd $bzmanpath
        $env LC_ALL='en_US.UTF-8' TZ='America/Los_Angeles' $python bzman -d $disk0 $backupnode --db=$bzmanpath
        echo "$(tput setaf 4)=> Done $(tput sgr 0)"
done

# replication the zones/isos/ dataset
cd $bzmanpath
echo -e '\e[0;34mReplicating zones/isos\e[0m'
$env LC_ALL='en_US.UTF-8' TZ='America/Los_Angeles' $python bzman -d zones/isos $backupnode --db=$bzmanpath
echo -e '\e[0;34mDone\e[0m'

# remove the lock file
rm -f $lockfile


