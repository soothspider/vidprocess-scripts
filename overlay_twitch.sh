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

# Reset in case getopts has been used previously in the shell.
OPTIND=1

targetDir="composed"

while getopts "h?t:" opt; do
  case "$opt" in
    h|\?)
      echo "Usage: $(basename $0) [-h] [-t <folder>] <file> <file-chat> [<file> <file-chat> ...]"
      echo ""
      echo "<file> must start with an ID. <file-chat> must start with the same ID followed by \" [Chat]\"."
      echo "e.g.  $(basename $0) \"1234 - stream.mp4\" \"1234 [Chat] - stream.mkv\""
      exit 0
      ;;
    t)  targetDir="${OPTARG}"
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
	target="${targetDir}/${name}.composed.mp4"

  echo "Proceding to overlay <overlay> ontop of <base> for stream $id."
  echo "base: $base"
  echo "overlay: $overlay"
  echo "---------"
  echo "target: $target"
  echo "---------"
  echo

  echo Start $(date)
  time ffmpeg -i "${base}" -i "${overlay}" -c:a copy -c:v h264_nvenc -filter_complex '[1:v]colorkey=0x000000:0.28[ckout];[0:v][ckout]overlay=1219[out]' -map 0:a:0 -map '[out]' "${target}"
	echo Completed $(date)
  echo 

  unset base
  unset overlay
done

