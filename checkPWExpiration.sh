#!/bin/sh
##########################
#  WARNING
#This requires alerter from https://github.com/vjeantet/alerter
#
##########################

# Check if the users password will expire in X days

# defines when to start prompting the user
promptWhenLessThan=90

# get the current username to read their last password change date
username=$( python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");' )

# write profiles out to temp so we can find the maximum age value
profiles -Cv -o /tmp/profiles.plist

# search for and capture the max age from the profile
maxPINAgeDays=$(grep -A1 maxPINAgeInDays /tmp/profiles.plist | tail -n1 | sed 's/<integer>//g' | sed 's/<\/integer>//g' | tr -d '[[:space:]]')

# if we can't find the max age in the profiles, assume 90 days.
if [ "$maxPINAgeDays" == "" ]; then	
	maxPINAgeDays=90
fi

# Get the users password policy data from the local node using dscl and write it to a file
dscl . read /Users/"$username" dsAttrTypeNative:accountPolicyData | sed '1d' > /tmp/pwdpolicy.plist

# Find when the password was last changed and trim to an integer
pwdLastSet=$(defaults read /tmp/pwdpolicy.plist passwordLastSetTime | cut -d"." -f 1)
# Find the current date
currentUnixTime=$( date +"%s" )

# Convert both times from seconds to days
passwordSetTimeDays=$( expr $pwdLastSet / 60 / 60 / 24 )
currentTimeDays=$( expr $currentUnixTime / 60 / 60 / 24 )

# How many days since the password was last changed
passwordResetDaysAgo=$( expr $currentTimeDays - $passwordSetTimeDays )

# Which leaves this many days to make a change
passwordDaysLeft=$( expr $maxPINAgeDays - $passwordResetDaysAgo )

# If the days left is less than or equal to our cutoff, prompt the user
if [ $passwordDaysLeft -le $promptWhenLessThan ]; then
# 	buttonReturned=`/usr/bin/osascript <<EOT
# 	tell application "SystemUIServer"
# 		activate
# 		with timeout of 600 seconds
# 		set buttonReturned to button returned of (display dialog "Your password expires in $passwordDaysLeft" buttons {"Change Now", "Wait"} default button "Change Now" cancel button "Wait" with title "Please change your password" with icon caution)
# 		end timeout
# 	end tell
# EOT`

	# prompt and capture the users decision
	buttonReturned=$(/usr/local/bin/alerter -message "Your password will expire in $passwordDaysLeft days" -actions "Change Now" -closeLabel "Wait" -title "Password Expiration" -sound default)

	# if they agree to change, open system preferences to the right place
	if [ "$buttonReturned" = "Change Now" ]; then

		/usr/bin/osascript <<EOT
		tell application "System Preferences"
			activate
			set the current pane to pane id "com.apple.preferences.users"
		end tell
# 		tell application "System Events"
#			tell process "System Preferences"
# 				click button "Change Password…" of tab group 1 of window "Users & Groups"
#  			end tell
#		end tell
EOT

	#if they wait, warn them again to do it soon
	else
	/usr/bin/osascript <<EOT
	tell application "SystemUIServer"
		activate
		with timeout of 600 seconds
		set buttonReturned to button returned of (display dialog "Please change your password soon in\nSystem Preferences -> Users & Groups.\nYou have $passwordDaysLeft days left." buttons {"OK"} default button "OK")
		end timeout
	end tell
EOT
	#/usr/local/bin/alerter -message "Please change your password soon!" -title "Password Expiration"

	fi

fi

# clean up after ourselves
rm /tmp/pwdpolicy.plist
rm /tmp/profiles.plist

