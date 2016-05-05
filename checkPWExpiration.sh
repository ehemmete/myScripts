#!/bin/sh

##########################
#
#  This relies on alerter from https://github.com/vjeantet/alerter
#
##########################


# Warn the user if their password expires in less than X days

# defines when to start prompting the user
promptWhenLessThan=14

# get the current username to read their pwpolicy and last password change date
username=$( python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");' )

# grab the number of days until a password expires from the users policy, can be null
pwExpirationDaysUser=$(pwpolicy -getaccountpolicies -u "$username" | grep -A1 "<key>policyAttributeExpiresEveryNDays</key>" | tail -n1 | sed 's/<integer>//g' | sed 's/<\/integer>//g' | tr -d '[[:space:]]')

# grab the number of days until a password expires from any global policy, can be null
pwExpirationDaysGlobal=$(pwpolicy -getaccountpolicies | grep -A1 "<key>policyAttributeExpiresEveryNDays</key>" | tail -n1 | sed 's/<integer>//g' | sed 's/<\/integer>//g' | tr -d '[[:space:]]')

if [ -z $pwExpirationDaysUser ] && [ -z $pwExpirationDaysGlobal ]; then
# both are null, no expiration found
	logger -t "checkPWExpiration" "Cannot find the pwExpirationDays from pwpolicy."
	exit 1
elif [ -z $pwExpirationDaysUser ]; then
# user expiration is null, use global
	pwExpirationDays=$pwExpirationDaysGlobal
elif [ -z $pwExpirationDaysGlobal ]; then
# global expiration is null, use user
	pwExpirationDays=$pwExpirationDaysUser
else
# both have a value, use the smaller.  If equal, it doesn't matter, so use User.
	if [ $pwExpirationDaysUser -le $pwExpirationDaysGlobal ]; then
		pwExpirationDays=$pwExpirationDaysUser
	else
		pwExpirationDays=$pwExpirationDaysGlobal
	fi
fi

# Find when the password was last changed and trim to an integer (Apple stores this as a decimal, which Bash doesn't handle)
pwdLastSet=$(dscl . read /Users/"$username" dsAttrTypeNative:accountPolicyData | grep -A1 "<key>passwordLastSetTime</key>" | tail -n1 | sed 's/<real>//g' | sed 's/<\/real>//g' | tr -d '[[:space:]]' | cut -d"." -f 1)

# Find the current date in seconds 
currentUnixTime=$( date +"%s" )

# Convert both times from seconds to days
passwordSetTimeDays=$( expr $pwdLastSet / 60 / 60 / 24 )
currentTimeDays=$( expr $currentUnixTime / 60 / 60 / 24 )

# How many days since the password was last changed
passwordResetDaysAgo=$( expr $currentTimeDays - $passwordSetTimeDays )

# Which leaves this many days to make a change
passwordDaysLeft=$( expr $pwExpirationDays - $passwordResetDaysAgo )

# log how many days left for testing/checking
logger -t "checkPWExpiration" "User $username has $passwordDaysLeft to change their password."

# If the days left is less than or equal to our cutoff, prompt the user
if [ $passwordDaysLeft -le $promptWhenLessThan ]; then
# 	buttonReturned=`/usr/bin/osascript <<EOT  #this is the applescript way to do it, but I like the alerter notification better
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
		display dialog "Click the Change Password button for your account" # incase users are unsure what to do...

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
	fi
fi

