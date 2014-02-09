### Setup for SmartOS
As SmartOS completely runs in RAM, setting up crontabs on it involves creating an SMF service script to load crontabs on system boot. So scripts provided in this directory can be used as an example to setup bzman to manage replication between two machines (i.e. primary and its backup).

Basically you also have to change host names, set ssh keys, probably host files and update sendmail alias. In our example, this is being automatically done in ```custom/setup.sh```. Below is how one would do it on primary host (the one being backed up). It also includes a better ```.bashrc``` bash profile file including a maintenance script to run monthly scrub on first Saturday and to recycle bzman database. This assumes that you have a secondary backup machine with SmartOS readily setup and available.

For a proper setup, you may also want to repeat the below process *first* on this secondary backup machine and then the primary.

	# install pkgin from http://wiki.smartos.org/display/DOC/Installing+pkgin if not already
	cd /
	curl -k http://pkgsrc.joyent.com/packages/SmartOS/bootstrap/bootstrap-2013Q3-x86_64.tar.gz | gzcat | tar -xf -
	pkg_admin rebuild
	pkgin -y up

	# install python26 and gdbm
	pkgin in git
	pkgin in python26
	pkgin in py26-gdbm

	# clone and set it up
	cd /opt
	git clone https://github.com/bassu/bzman.git
	# edit files custom/setup.sh, replace host names and IPs, change email address; customize to your taste
	vim bzman/custom/setup.sh
	# edit crontab and change email address and replication times as desired
	vim bzman/rcfiles/root.cron.primary
	# move the smf directory to /opt
	mv -f bzman/custom /opt
	# next time you reboot and login to primary machine, an ssh key will be generated and will be sent to backup host

	# that's pretty much it
	bzman --help

##### Note on timezone
Since bzman creates snapshot names with ISO 8601 format date, it is important to keep **one** timezone environment for all of your SmartOS machines because that's how they are identified for ease of manageability. And of course because the system env is volatile in SmartOS, the default timezone UTC is pretty much unconfigurable. If you change it in bash profile, then you also have to change to it in the scripts and cron env. If you don't touch it at all, that's fine too. Whatever you choose, just stick with one TZ in your env everywhere. Above example scripts use PST.



