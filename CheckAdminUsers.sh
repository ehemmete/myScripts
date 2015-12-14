#!/bin/sh
# Eric Hemmeter - 2012

# a very handy function to check if a string is in an array 
# usage as follows: containsElement "$string to look for" "${array to look in[@]}"
# if the string is found, returns 0.  Else returns 1.  Check $? to find result
containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

# get the list of users in the admin group
userslist=$(dscacheutil -q group -a name admin | grep users | cut -d : -f2- | sed 's/^ *//g')
usersArray=($userslist)

# to allow other users to be admin, modify this array
approvedUsers=(root manager)

rogueUser="No"

for (( i=0; i < ${#usersArray[@]}; i++ ))
do
        containsElement "${usersArray[$i]}" "${approvedUsers[@]}"
        contains=$?
        if [ "$contains" == "1" ]; then
        rogueUser="Yes"
  fi
done

# if the list doesn't match what it should, return the list
if [[ "$rogueUser" == "Yes" ]];then
        echo "<result>$userslist</result>"
else
        echo "<result>In policy</result>"
fi
