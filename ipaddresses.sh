#! /bin/bash
connection=false
services=$(networksetup -listallnetworkservices)
while read service; do
	ip=$(networksetup -getinfo "$service" | grep "IP address" | grep -v "IPv6" | awk '{print $3}')
	if [ "$ip" != "" ]; then
	echo "$service : $ip"
	connection=true
	fi
done <<<"$services"


astatus=$(networksetup -getinfo "Wi-Fi" | grep "IP address" | grep -v "IPv6" | awk '{print $3}')
if [ "$astatus" != "" ]; then
   NetName=`system_profiler SPAirPortDataType | awk '/Current Network Information:/ { found=NR } found && NR==found+1' | awk '{$1=$1};1' | cut -d":" -f1`
   Channel=`system_profiler SPAirPortDataType | awk '/Current Network Information:/ { found=NR } found && NR==found+4' | awk '{$1=$1};1' | sed 's/Channel/Ch/g'`
   echo "$NetName / $Channel"
fi

if [ $connection = false ]; then
	echo "No Connected Services"
else
	extIP=$(curl -s http://checkip.dyndns.org/ | sed 's/[a-zA-Z<>/ :]//g')
	if [ "$extIP" != "" ]; then
		echo "External IP: $extIP"
	else
		echo "No External Connection"
	fi
fi
