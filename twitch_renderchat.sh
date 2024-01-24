#!/usr/bin/bash

# ---
# Using TwitchDownloaderCLI, renders the chat.
#
# Requires TwitchDownloaderCLI
#
# Usage: twitch_renderchat.sh file.json [file.json ...]
#
# Will render the chat for all the .json or .json.gz files passed in.
# e.g. twitch_renderchat.sh 1234_*.json
# 
# Renders the chat for 1234_*.json and puts the rendered file in the current folder as 1234_*.mkv.
# Rendered chats will have the same basename as the json chat file.
# ---

# Colours (background)
#FF00FF04 - neon green
#FF000000 - black
# Colours (message)
#FFFFFF - white
#FFA500 - Orange

black_background="FFFFFFFF"
darkgrey_background="FF111111"
neongreen_background="FF00FF04"
orange_message="FFA500"
white_message="FFFFFF"

default_background="$darkgrey_background"
default_message="$orange_message"

background="$default_background"
message="$default_message"
#extra_params="--sharpening"
extra_params=""

# Reset in case getopts has been used previously in the shell.
OPTIND=1

while getopts "h?b:m:p:" opt; do
	case "$opt" in
		h|\?)
			echo "WIP, needs completing"
			echo "Usage: $(basename $0) [-h] [-b <colour>] [-m <colour>] <file.json> [<file.json> ...]"
			echo ""
			echo "<file.json> is a .json or .json.gz chat file."
			echo "<colour> is 'RRGGBB' or 'AARRGGBB' in hexidecimal."
			echo "The default background colour is ${default_background}. The default message colour is ${default_message}."
			echo ""
			echo "e.g.  $(basename $0) \"1234 - stream.json\" \"2345 - stream.json.gz\""
			echo "e.g.  $(basename $0) -b FF000000 -m FFFFFF \"1234 - stream.mp4\" \"2345 - stream.mp4\""
			echo "(for white message on black background)"
			exit 0
			;;
		b)  background="${OPTARG}"
			;;
		m)  message="${OPTARG}"
			;;
		p)  extra_params="${OPTARG}"
			;;
	esac
done
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

files=()
while (( "$#" )); do
	files+=("$1")
	echo Adding file: "$1"
	shift
done

echo 
echo Rendering ${#files[@]} chats.
echo

times=()
for ((i = 0; i < ${#files[@]}; i++)); do
	file="${files[$i]}"
	base="${file%.*}"
	target="${base}.mkv"

	echo "Generating chat [#${message} on #${background}]: $file"
	echo Start $(date)
	start=$(date +%s)
	time twitchdownloadercli chatrender -i "${file}" -h 1080 -w 700 --background-color "#${background}" --message-color "#${message}" --font-size 24 ${extra_params} --outline --framerate 60 --output-args='-c:v hevc_nvenc -preset:v p4 -cq 21 -pix_fmt yuv420p "{save_path}"' -o "${target}"
	end=$(date +%s)
	times+=($((end-start)))
	echo "Completed $(date) --> [#${message} on #${background}] $target"
done

[ ${#files[@]} -gt 1 ] && printf "\nChat renders attempted:\n----\n" && paste -d "" <(printf '> [%d s]\n' "${times[@]}") <(printf ' - %s\n' "${files[@]}")
