#!/usr/bin/bash

# ---
# Gets the Twitch user_id of a person (for other functions).
#
# Requires twitch-cli (configured)
#
# Usage: get_twitch_userid.sh <login>
#
# Will try to get the user_id of the login.
# e.g. get_twitch_userid.sh gigaohmbiological
# --> returns user_id for gigaohmbiological
# ---

if [ -z "$1" ]; then
	echo Requires login to be specified. e.g. $0 gigabohmbiological
fi

twitch api get users -q login=$1 | grep "id" | awk -F'"' '$0=$4'
