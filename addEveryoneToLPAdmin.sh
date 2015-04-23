#!/bin/sh
# Eric Hemmeter - 2012

# add everyone to the lpadmin group to let them manage printers
/usr/sbin/dseditgroup -o edit -n /Local/Default -a everyone -t group lpadmin
