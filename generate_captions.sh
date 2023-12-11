#!/usr/bin/bash

# ---
# Using whisper, generates captions using the base.en model.
#
# Requires whisper
#
# Usage: generate_captions.sh file [file ...]
#
# Will generate captions for file (video or audio) and put it in the captions folder.
# e.g. generate_captions.sh 1234_*.mp4
# 
# Puts captions for 1234_*.mp4 files in ./captions/ folder. Captions will have the same
# basename as the video/audio source file.
# ---

# Reset in case getopts has been used previously in the shell.
OPTIND=1

model="base.en"

while getopts "h?m:" opt; do
  case "$opt" in
    h|\?)
      echo "Usage: $(basename $0) [-h] [-m <model>] <file> [<file> ...]"
      echo ""
      echo "<model> is one of:  tiny.en,tiny,base.en,base,small.en,small,medium.en,medium,large-v1,large-v2,large"
      echo "<model> defaults to base.en"
      echo "e.g.  $(basename $0) \"1234 - stream.mp4\" \"2345 - stream.mp4\""
      echo "e.g.  $(basename $0) -m base.en \"1234 - stream.mp4\" \"2345 - stream.mp4\""
      exit 0
      ;;
    m)  model="${OPTARG}"
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
echo Generating captions for ${#files[@]} videos.
echo

for ((i = 0; i < ${#files[@]}; i++)); do
	file="${files[$i]}"

	echo Generating captions for: $file
	echo Start $(date)
	time whisper --model "${model}" -o captions "$file"
	echo "Completed $(date) --> [${model}] $file"
done

[ ${#files[@]} -gt 1 ] && printf "\nCaptions attempted:\n----\n" && printf '> %s\n' "${files[@]}"
