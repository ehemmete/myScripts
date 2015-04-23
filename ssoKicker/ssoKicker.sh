#!/bin/sh
#created by Eric Hemmeter  4/21/2015

#/usr/local/bin/BigHonkingText -d -p 1 "ssoKicker is running" 

# enter all routers in here
declare -a internalRouters=(10.224.10.1 10.0.0.1)
# enter domain name in all upper case
domainname="PRETENDCO.COM"

# a useful function to see if an element exists in an array.  Returns 0 (or True) if the element is in the array
containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

declare -x UserName="$(/usr/bin/who | /usr/bin/awk '/console/{print $1;exit}')"
echo "Derived Console username: $UserName"
declare -x LoginWindowPID="$(/bin/ps -axww | /usr/bin/grep loginwindo[w] | /usr/bin/awk '/console/{print $1;exit}')"
echo "Found PID: $LoginWindowPID"

if ! /bin/launchctl bsexec "${LoginWindowPID:?}" /usr/bin/sudo -u "$UserName" klist -t; then
#	/usr/local/bin/BigHonkingText -d -p 1 "already have TGT"
#else
	services=$(networksetup -listallnetworkservices) # get the list of services on this computer
	while read service; do # for each service
		router=$(networksetup -getinfo "$service" | grep "Router" | grep -v "IPv6" | awk '{print $2}') # capture the router setting of each service
		if [ "$router" != "" ]; then  # we only care about services with a valid router
			if containsElement "$router" "${internalRouters[@]}" ; then  # if the router is in our list of routers
				#we are on an appropriate network so prompt for name and password						
				/bin/launchctl bsexec "${LoginWindowPID:?}" /usr/bin/sudo -u "$UserName" osascript /Library/Scripts/GetTicket.scpt
			fi
		fi
	done <<<"$services"
fi
sleep 10