#!/usr/bin/bash

# ---
# Using whisperx, generates captions using the large-v2 model.
#
# Requires whisperx
#
# Usage: generatex_captions.sh file [file ...]
#
# Will generatex captions for file (video or audio) and put it in the captions folder.
# e.g. generatex_captions.sh 1234_*.mp4
# 
# Puts captions for 1234_*.mp4 files in ./captions/ folder. Captions will have the same
# basename as the video/audio source file.
# ---

# Reset in case getopts has been used previously in the shell.
OPTIND=1

model="large-v2"
language="en"
output="captions"
declare -a options

while getopts "h?m:l:dwo:" opt; do
	case "$opt" in
		h|\?)
			echo "Wrapper for whisperx."
			echo ""
			echo "Usage: $(basename $0) [-h] [-m <model>] [-l <language>] [-d] [-w] [-o <folder>] <file> [<file> ...]"
			echo ""
			echo "<model> is one of: tiny.en,tiny,base.en,base,small.en,small,medium.en,medium,large-v1,large-v2,large"
			echo "<model> defaults to ${model}"
			echo "<language> examples: en,English,zh,Chinese,fr,French,ja,Japanese"
			echo "<language> defaults to ${language}"
			echo
			echo "-d Turns on diarization"
			echo "-w Turns on Highlighting words"
			echo "-o <folder> Puts the output in <folder>. Defaults to ${output}."
			echo 
			echo "e.g.  $(basename $0) \"1234 - stream.mp4\" \"2345 - stream.mp4\""
			echo "e.g.  $(basename $0) -m base.en \"1234 - stream.mp4\" \"2345 - stream.mp4\""
			echo "e.g.  $(basename $0) -m large-v2 -l en \"1234 - stream.mp4\" \"2345 - stream.mp4\""
			echo "e.g.  $(basename $0) -dwo captions.diarized \"1234 - stream.mp4\" \"2345 - stream.mp4\""
			exit 0
			;;
		m)  model="${OPTARG}"
			;;
		l)  language="${OPTARG}"
			;;
		d)  options+="--diarize"
			;;
		w)  options+="--highlight_words True"
			;;
		o)  output="${OPTARG}"
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

times=()
for ((i = 0; i < ${#files[@]}; i++)); do
	file="${files[$i]}"

	echo Generating captions for: $file
	echo Start $(date)
	start=$(date +%s)
	args=(--model "${model}" --language "${language}" "${options[@]}" -o "${output}")
	echo time whisperx ${args[@]} "${file}"
	time whisperx ${args[@]} "${file}"
	end=$(date +%s)
	times+=($((end-start)))
	echo "Completed $(date) --> [${model} ${language} : ${options}] ${file} => ${output}"
done

[ ${#files[@]} -gt 1 ] && printf "\nCaptions attempted:\n----\n" && paste -d "" <(printf '> [%d s]\n' "${times[@]}") <(printf ' - %s\n' "${files[@]}")
