#!/bin/sh
# Eric Hemmeter - 2012

# add the current user to the admin group
dseditgroup -o edit -a $(ls -l /dev/console | cut -d " " -f 4) -t user admin
