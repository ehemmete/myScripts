#!/bin/sh
for computers in $(ls /var/db/dslocal/nodes/Default/computers)
do
computer=$(echo ${computers%.*})
dscl . read computers/$computer ipaddressandenetaddress >> /tmp/addresses.txt
done
