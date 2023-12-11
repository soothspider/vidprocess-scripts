#!/usr/bin/bash

# ---
# Extract links from Twitch chat.json files.
#
# Requires jq
#
# Usage: extract_links.sh file [file ...]
#
# Will put extracted links in file_basename.links.txt.
# e.g. extract_links.sh 1234_chat.json
# --> links put into: 1234_chat.links.txt
# ---

files=()
while (( "$#" )); do
	files+=("$1")
	echo Adding file: "$1"
	shift
done

echo 
echo Extracting links from ${#files[@]} files.
echo

for ((i = 0; i < ${#files[@]}; i++)); do
	file="${files[$i]}"
	base="${file%.*}"
	target="${base}.links.txt"

	echo Extracting from: $file
	echo to: $target
	jq . "$file" | grep \"body\": | grep -i http | grep -shoP 'http.*?[" >]' | cut -d'"' -f1 | tee "$target"
done

