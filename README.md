bzman
=====

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mbrant%40phi9%2ecom&lc=US&item_name=Bzman&no_note=0&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHostedGuest)


Bassu's ZFS (replication) Manager
---------------------------------

### What is it?
Bzman is a small (~900 lines of code) Python appliction to systematically maintain and report ZFS replications.
Although it was primarily written for SmartOS for having continuously identical copies of virtual machine disks but it also can be run on Unix and Linux for replication.

### Why and how?
One of the main powerful features of ZFS is pool-wide incremental replication. That means you can maintain a hotcopy of your current pool for distaster recovery or for backup purposes.
But since I did not find any tool that reliably automated replication streams while keeping their record so I decided to write one. Whatever may be the reason, you may want (or will have) a near-instant copy of your datasets or pool that is to least 10 minutes behind the original pool -- all the time.

*And that's what bzman is here for!*

On the plus side, it also monitors pool health status and usage capacity as well. 

### Features

*New*

- Individual dataset (either fs or zvol) replication
- Unix support

*Old*

- Keeps track of each replication in a serialized shelve database
- Nightly HTML reports
- Performs all sorts of preflight checks
- Automated full initial replication
- Outputs elasped times for all phases
- Logs to syslog as well as stdout
- Sends an instant email in case of error at any phase
- Lots of error handling (almost all)
- Uses optimized SSH for fast transfers (without compresssion, arcfour encryption)
- Ability to use mbuffer if needed

### Requirements

- Python 2.6+
- Python GNU GDBM module (only needed on Unix)
- SSH keys setup 

The gdbm module is usually readily avaiable on Linux and shipped with Python.
On Unix install it with your OS package manager. 

### Setup

Install python2 
Simply download the [bzman raw file](https://raw.github.com/bassu/bzman/master/bzman), run `./bzman -h` to see the examples.
After playing with it, setup ssh keys (send public key to destination host) and run bzman from cron.
That's it.

For instructions on (awesome) SmartOS see below.

### Tested Operating Systems

- SmartOS
- RHEL 6.x

### FAQs

##### *I has the awesome Unix a.ka. SmartOS*. How do I set this thing up there?
SmartOS is awesome but a pretty volatile operating system. Since it entirely runs on RAM with much of OS as read-only, you will have to either use /etc or /opt for bzman. Latter is recommended. If you already have crons running, you might have some kind of a startup script to load the crontab at system boot. If not, see the [smartos](./smartos) folder of this repository. Even if you don't know what SmartOS is, you should still check it out (because, you should have known by now as it's ... wait for it ..... "pretty awesome")!

##### How stable is it?
Like any software, you should always do some testing. With that being said, it is being used in production to manage replication between a small set of ZFS pools in my day job. Of course there are still some chances that it will burn down your mansion (if you live in one) or eat your cat.
Nah, I am just kidding but still make sure to check all options and test it before putting to use ;)!

##### How can I help?
Probably testing, contributing code and ideas or donation for improvements! See below.

##### What's in the future?
Since I wrote bzman in my free time so it would be **appreciative** to consider it as [Donationware](http://en.wikipedia.org/wiki/Donationware). If the tool helps and you want to **help back**, there's that golden button on top! There are indeed plans for future given that it gets enough attention including a full blown implementation in C, a proper database, better reporting, sync status monitoring, even a failover or switchover system that someone recently suggested and who knows what other cool stuff lies ahead!!

##### I want the machine to snapshot and send Monthly, Daily, and Hourly, or every Minute?
That's what bzman does, depending upon the cron. It has an option of ```snapkeep``` that lets you keep a particular number of snapshots created by it before they are rotated. See the first few lines of code.

##### Replication task should check to make sure there isn't a replication task still running.
I have a wrapper script with lock file to replicate one by one. Plus, the receive command by default does it by keeping a dataset "busy". See the ```runbzman.sh``` shell script in [smartos](./smartos) directory for example.

##### Does it set filesystem property readonly=on (so it doesn't replicate snapshot deletions from the source ZFS dataset and prevents changes that would make incrementals fail) ?
Not really needed if backup machine is just a backup but could serve as an additional check. May be a feature in bzman.

##### I want each server to be responsible for their own snapshot retention/cleanup, for protection and possibly having different policies per server.
Bzman already takes care of that. It was introduced as an additional check because ZOL had a bug and did not delete the stale snapshots on receiving end. See the aforementioned snapkeep option.

##### Is it possible to define different destination pool?
A backup machine technically should have the same pool name as the source one unless it is not really a backup, IMHO. Let me know if you really need this.

### Usage and Examples

	Usage: bzman [options]
	bzman - ZFS replication managing tool to systematically monitor health, check free space,
	report, compute and send replication streams

	Options:
	-m             monitors health status of ZFS pools and
				   sends error email if unhealthy

	-c             checks free size of ZFS pools and
				   sends an email if it's less than 25%

	-s [pool] [host]
				   sends a complete ZFS [pool] to same [pool]
				   on [host] via fast arcfour SSH or mbuffer

	-d [pool]/[dataset] [host]
				   sends a particular ZFS [dataset], whether of type zvol or
				   filesystem to same [pool] on [host] via fast arcfour SSH

	-p             print the daily report of incremental snapshots streams,
				   looks like a replication log and currently does not check
				   terminal dimentions so better suited in maximized terminals

	-r [to]        sends immediate daily HTML report of incremental streams
				   to [to] recipient email address

	-b, --db=[path]
				   the [path] to save gdbm db into, default is current dir
				   with file name of bzman.db

	-h, --help     show this help menu


	Defaults:

	* Error/report emails are sent to root (changeable in /etc/aliases).
	* Initial replication is automatic, destination pool with same name must exist.
	* All info and error messages are also logged to syslog.
	* Snapshots are prefixed 'incremental' and kept for a week i.e. 3*24*7
	* Destination pool name is chosen based on source pool name and will
	  fail if it doesn't exit.

	I hate the tools that don't include any examples.

	Examples:

	# bzman -d tank/myzvol 172.16.1.5
	Sends dataset "myzvol" from pool "tank" to "tank" pool on host 172.16.1.5 via ssh

	# bzman -s tank 172.16.1.5 --db=/root
	Sends whole pool "tank" to "tank" on host 172.16.1.5 via ssh while keeping the db
	in /root/ directory instead of default current directory

	# bzman -r bassu@example.com --db=/root
	Sends a tabulated HTML replication report to bassu@example.com after reading off
	data from the db stored in /root


### Screenshots

##### Replication
![Image](./img/replication.png)

##### Printing Replication Events
![Image](./img/eventlogs.png)

##### HTML Report
![Image](./img/htmlreport.png)

### License
Bzman is released under GNU GPL.

### Bugs & Feature Requests
If you stumble upon a bug or have any feature requests, open up an issue. 
