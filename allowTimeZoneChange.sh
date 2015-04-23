#!/bin/sh
# Eric Hemmeter - 2012

# first back up the current authorization file
cp /etc/authorization /etc/authorization.clean
# this is a trick so that defaults will work properly
cp /etc/authorization /etc/authorization.plist
# add the dictionary that allows everyone to change the time zone
defaults write /etc/authorization rights -dict-add system.preferences.dateandtime.changetimezone '<dict><key>class</key><string>allow</string><key>comment</key><string>This right is used by DateAndTime preference to allow any user to change the system timezone.</string><key>shared</key><true/></dict>'
# defaults makes the file a binary, which is wrong for the authorization file
plutil -convert xml1 /etc/authorization.plist
# put the file back in the right place and set the permissions correctly
cp /etc/authorization.plist /etc/authorization
chmod 644 /etc/authorization
