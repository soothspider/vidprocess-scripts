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
	# Filter body line from JSON pretty printer, grep for links, cut out important part, remove the trailing ")"" if any.
	# jq . "$file" | grep \"body\": | grep -i http | grep -ishoP 'http.*?[" >]' | cut -d'"' -f1 | sed 's_)$__' | tee "$target"
	# Prefix the links for the console (for nicer pasting into soapbox)
	jq . "$file" | grep \"body\": | grep -i http | grep -ishoP 'http.*?[" >]' | cut -d'"' -f1 | sed 's_)$__' | tee "$target" | sed 's/^http/- http/'
done

