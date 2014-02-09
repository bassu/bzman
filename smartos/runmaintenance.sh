#!/bin/bash
export TZ='America/Los_Angeles'
export LC_ALL='en_US.UTF-8'

env=/usr/bin/env
date=/usr/bin/date
weekday=$($env TZ='America/Los_Angeles' $date '+%w')

# run scrub on saturday (monthly via cron)
[[ $weekday -eq 6 ]] && /usr/sbin/zpool scrub zones || echo 'Today is not Saturday. No scrub to run.'
[[ $weekday -eq 6 && -f /opt/bzman/bzman.db ]] && { >/opt/bzman/bzman.db; echo 'Rotated bzman.db'; } || echo 'Not clearing bzman.db'

