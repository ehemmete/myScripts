#!/bin/sh
# Eric Hemmeter - 2012
# Reports the most common user out of the last 10 logins
# If there are less than 10 logins, it reports the most recent user

# a very handy function to check if a string is in an array 
# usage as follows: containsElement "$string to look for" "${array to look in[@]}"
# if the string is found, returns 0.  Else returns 1.  Check $? to find result
containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

# gets the list of previous logins at the login window
# this ignores any tty (command line) logins
userList=($(last -t console | cut -d " " -f 1))
numOfUsers=${#userList[@]}

# if less than 10 logins, return the most recent
if [ "$numOfUsers" -lt 10 ]; then
  echo "<result>${userList[0]}</result>"
  exit 1
fi

# find the list of unique entries in the user list
uniqueList[0]="${userList[0]}"

echo "" > /tmp/userList.txt
echo "" > /tmp/uniqueList.txt

# go through the list of last 10 logins
# if this is the first time we see the name add them to the unique list array
for i in {0..9}
do
containsElement "${userList[$i]}" "${uniqueList[@]}"
contains=$?
  if [ "$contains" == "1" ]; then
    uniqueList=("${uniqueList[@]}" "${userList[$i]}")
  fi
echo "${userList[$i]}" >> /tmp/userList.txt
echo "${uniqueList[$i]}" >> /tmp/uniqueList.txt
done

# this complex one liner takes a list in one file (uniqueList)
# and finds the most common occurrence in the other (userList)
result=$(grep -Ff /tmp/uniqueList.txt /tmp/userList.txt | sort | uniq -c | sort -n | tail -n1)
result=${result:5}
echo "<result>$result</result>"
