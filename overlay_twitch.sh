#!/usr/bin/bash

# ---
# Using ffmpeg, overlay the rendered chat by TwitchDownloader.
#
# Requires ffmpeg (and overlay should be 700x1080 resolution)
#
# Usage: overlay_twitch.sh [-h] [-t <folder>] <file> <file-chat> [<file> <file-chat> ...]
#
# Will overlay <file-chat> (video) on top of <file> (video) and put in <folder>.
# By default <folder> will be "./composed".
# By convention it will be able to tell <file> and <file-chat> apart because of a "[Chat]" in the filename.
#
# For example:
# - '1979495123 - Engler and Hockett on DailyClout --(16 Nov 2023)-- Brief [gigaohmbiological - 2023-11-16].mp4'
# - '1979495123 [Chat] - Engler and Hockett on DailyClout --(16 Nov 2023)-- Brief [gigaohmbiological - 2023-11-16].mkv'
# 
# <file> should start with the stream ID followed by a " ".
# <file> should start with the stream ID followed by " [Chat]"
# An ID should just be any identifier that doesn't have spaces (due to how I'll be parsing it).
# 
# This way we can batch process things without making the script overly complicated. 
# (Simplified by convention, but you must know the convention.)
# ---

black_colorKey="000000"
black_similarity="0.28"
darkgrey_colorKey="111111"
darkgrey_similarity="0.02"

default_targetDir="composed"
default_colorKey="$darkgrey_colorKey"
default_similarity="$darkgrey_similarity"

targetDir="$default_targetDir"
colorKey="$default_colorKey"
similarity="$default_similarity"

# Reset in case getopts has been used previously in the shell.
OPTIND=1

while getopts "h?t:k:s:" opt; do
	case "$opt" in
		h|\?)
			echo "Usage: $(basename $0) [-h] [-t <folder>] [-k <color-key>] <file> <file-chat> [<file> <file-chat> ...]"
			echo ""
			echo "<folder> defaults to '${default_targetDir}'. If folder does not exist, it will error out."
			echo "<file> must start with an ID. <file-chat> must start with the same ID followed by \" [Chat]\"."
			echo "e.g.  $(basename $0) \"1234 - stream.mp4\" \"1234 [Chat] - stream.mkv\""
			echo ""
			echo "<color-key> should be in the format RRGGBB or RRGGBBAA in hexidecimal. It defaults to ${default_colorKey}."
			echo "e.g.  $(basename $0) -k 00AABB"
			exit 0
			;;
		t)  targetDir="${OPTARG}"
			;;
		k)  colorKey="${OPTARG}"
			;;
		s)  similarity="${OPTARG}"
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

# sort list so that it's more predictable.
IFS=$'\n' files=($(sort <<<"${files[*]}")); unset IFS

echo 
echo Processing video files in order:
printf "file: [%s]\n" "${files[@]}"
echo

times=()
composed=()
for ((i = 0; i < ${#files[@]}; i++)); do
	[ -z "${base}" ] && base="${files[$i]}" && continue
	[ -z "${overlay}" ] && overlay="${files[$i]}"

	# Check to make sure base and overlay agree (e.g. related to same stream).
	# If you need to change how <file> and <file-chat> formats are handled, these are the relevant 2 lines.
	id=$(cut -d' ' -f1 <<< "$base")
	if [[ ! "${overlay}" =~ .*"${id} ["[Cc]"hat]".* ]]; then
		echo "!!! Base and overlay do not seem to be part of the same stream. Skipping..."
		echo "base: $base"
		echo "overlay: $overlay"
		echo 
		unset base
		unset overlay
		continue
	fi

	name="${base%.*}"
	target="$(echo "${targetDir}" | sed 's:/*$::')/${name}.composed.mp4"

	echo "Proceding to overlay <overlay> ontop of <base> for stream $id."
	echo "base: $base"
	echo "overlay: $overlay"
	echo "---------"
	echo "target: $target"
	echo "---------"
	echo
	composed+=("$target")

	echo Start $(date)
	start=$(date +%s)
	time ffmpeg -i "${base}" -i "${overlay}" -c:a copy -c:v h264_nvenc -filter_complex "[1:v]colorkey=0x${colorKey}:${similarity}[ckout];[0:v][ckout]overlay=1219[out]" -map 0:a:0 -map '[out]' "${target}"
	end=$(date +%s)
	times+=($((end-start)))
	echo "Completed $(date) [colorKey:${colorKey} similarity:${similarity}] $target"
	echo 

	unset base
	unset overlay
done

[ ${#composed[@]} -gt 1 ] && printf "\nCompositions attempted:\n----\n" && paste -d "" <(printf '> [%d s]\n' "${times[@]}") <(printf ' - %s\n' "${composed[@]}")
