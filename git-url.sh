#!/bin/bash
# ---
# Predicts the URL from the file path.
# Based on: https://superuser.com/questions/1148246/get-github-link-for-file-in-checkout-in-cli
# ---
# Usually what's below is enough...
# ---
# FILE=$1
# GIT_URL=$(git config --local remote.origin.url | cut -d "@" -f 2 | cut -d "." -f "1-2" | sed "s/:/\//")
# BRANCH=`git rev-parse --abbrev-ref HEAD`
# URL="https://${GIT_URL}"
#
# echo $URL/blob/$BRANCH/$FILE
# ---
# But..

# ----
# Note: My setup is a bit more complicated than that because of:
# 1) To use the right key/user/etc, I replace the real host name with one configured in ~/.ssh/config.
# 2) The URL path needs to be URLEncoded.
# 3) I want to be able to run this anywhere in the git repo, not just at the base of the repo.
# ----

remote="origin"

usage() {
  command="$(basename $0)"
  echo "Usage: $command [-h] [-r <remote>] <file-path>"
  echo ""
  echo "<remote> is the name of the remote to use. Defaults to 'origin' (so use this if it's not origin)."
  echo "e.g.  $command) \"Path to my folder/or file.txt\""
  echo "e.g.  $command -d other-origin \"Path to my folder/or file.txt\""
}

# Reset in case getopts has been used previously in the shell.
OPTIND=1

while getopts "h?r:" opt; do
	case "$opt" in
		h|\?)
			usage
			exit 0
			;;
		r)  remote="${OPTARG}"
			;;
	esac
done
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

FILE=$1

real_git_host() {
  GIT_HOST="$1"
  MAYBE_HOST="$(awk -v host="$GIT_HOST" '
    BEGIN { found = 0; IGNORECASE = 1 }
    $1 == "Host" && $2 == host { found = 1 }
    found && $1  == "Hostname" { print $2; exit }
  ' ~/.ssh/config)"
  if [ -n "$MAYBE_HOST" ]; then
    GIT_HOST="$MAYBE_HOST"
  fi

  echo "$GIT_HOST"
}

GIT_HOST=$(git config --local remote.${remote}.url | cut -d ":" -f1 | cut -d '@' -f2)
GIT_REPO=$(git config --local remote.${remote}.url | cut -d ":" -f2)
if [[ $GIT_REPO == *.git ]]; then
  GIT_REPO="${GIT_REPO%.git}"
fi

GIT_REAL_HOST=$(real_git_host "$GIT_HOST")

echo GIT_REPO: $GIT_REPO GIT_HOST: $GIT_HOST GIT_REAL_HOST: $GIT_REAL_HOST

repo_path() {
  # Get the path to the root of the git repo
  repo_root=$(git rev-parse --show-toplevel)

  # Get the relative path of the file from the repo root
  relative_path=$(realpath --relative-to="$repo_root" "$1")

  echo "$relative_path"
}

url_encode() {
  TARGET="$1"
  echo $(python3 -c 'import urllib.parse; print(urllib.parse.quote(input(), safe="/()"))' <<< "$TARGET")
}

RELATIVE_FILE=$(repo_path "$FILE")
TARGET_FILE=$(url_encode "$RELATIVE_FILE")

BRANCH=`git rev-parse --abbrev-ref HEAD`
URL="https://${GIT_REAL_HOST}/${GIT_REPO}"

echo $URL/tree/$BRANCH/$TARGET_FILE

exit 0
