#!/usr/bin/env python

# ---
# Using twitch-cli, fetches the video and chats (in html and json).
#
# Requires twitch-cli
#
# Usage: fetch_twitch_videos_and_chat.py <video>
#
# Will fetch the html and json chats as well as the stream for a video with id <video>.
# ---

import os, textwrap, getopt, sys, re, subprocess, ujson
from dateutil.parser import parse as dateparser
from prettytable import PrettyTable

def print_usage(msg = None):
    scriptname = os.path.basename(sys.argv[0])
    usage = textwrap.dedent("""\
            Fetches chat (html+json) and video of specified video id.
            Usage: {script} [-h] [-n] [-c | -v] <video|video-url>

            -h : Help                            
            -n : Dry run. Don't download anything.
            -c : Do not download chats
            -v : Do not download video

            e.g.
              {script} 12345
              {script} https://twitch.tv/videos/12345
            
            Will fetch from https://twitch.tv/videos/12345
        """.format(script = scriptname))
    
    if not msg is None:
       print(msg)
       print()
    print(usage)

def extract_video_id(candidate):
    # Extract <number> http?://*[.]twitch.tv/<number> or just <number>
    pattern = re.compile("^(http.?:\/\/.*\.?twitch\.tv.*?)?(?P<id>\d+)")
    matches = pattern.match(candidate)
    return matches['id'] if matches else None


def parse_options(argv):
    results = lambda : None
    results.dryrun = False
    results.dl_chats = True
    results.dl_video = True
    try:
        opts, args = getopt.getopt(argv,"h?ncv")
    except getopt.GetoptError as e:
        print_usage(e.msg)
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-h", "-?"):
            print_usage()
            sys.exit()
        elif opt == "-n":
            results.dryrun = True
        elif opt == "-c":
            results.dl_chats = False
        elif opt == "-v":
            results.dl_video = False

    results.video = extract_video_id(args[0]) if args else None

    return results

def get_twitch_video_metadata(video_id):
    results = subprocess.getoutput("twitch api get videos -q id={id}".format(id = video_id))
    return results

def extract_video_title_info(data):
    video_data = ujson.loads(data)
    results = []

    for video in video_data["data"]:
        entry = lambda : None
        entry.id = video["id"]
        date = dateparser(video["created_at"])
        entry.date = "{}-{:02d}-{:02d}".format(date.year, date.month, date.day)
        entry.title = video["title"]
        entry.nicetitle = slugify_filename(video["title"])
        entry.channel = video["user_name"]
        entry.duration = video["duration"]
        results.append(entry)

    return results[0] if results[0] else None

def slugify_filename(filename):
    result = filename if filename else ""
    result = result.replace("?", "_")
    result = result.replace(":", "_")
    result = result.replace("/", "_")
    return result

def adjust_titles(metadata):
    if metadata.channel.lower() == "GigaohmBiological".lower():
        metadata.title = metadata.title.replace("Gigaohm Biological High Resistance Low Noise Information ", "")
        metadata.title = metadata.title.replace("Gigaohm Biological High Resistance Low Noise Info ", "")
        metadata.nicetitle = slugify_filename(metadata.title)

    return metadata

def runner(command, dryrun = False):
    if dryrun:
        print(f"Dry-Run for: {command}")
    else:
        os.system(command)

def fetch_chat(metadata, dryrun = False):
    title = f"{metadata.id} [Chat] - {metadata.nicetitle} [{metadata.channel} - {metadata.date}]"

    print(f"Fetching HTML chat for video {metadata.id} as: {title}.html")
    runner(f"twitchdownloadercli chatdownload -u {metadata.id} -o \"{title}.html\" -E", dryrun)

    print(f"Fetching JSON chat for video {metadata.id} as: {title}.json")
    runner(f"twitchdownloadercli chatdownload -u {metadata.id} -o \"{title}.json\" -E", dryrun)

def fetch_video(metadata, dryrun = False):
    title = f"{metadata.id} - {metadata.nicetitle} [{metadata.channel} - {metadata.date}]"

    print(f"Fetching video {metadata.id}")
    runner(f"twitchdownloadercli videodownload -u {metadata.id} -o \"{title}.mp4\"", dryrun)

def main(argv):
    params = parse_options(argv)

    if params.video is None:
        print_usage("video id or url is a required parameter")
        sys.exit(1)

    print(f"Fetching https://twitch.tv/videos/{params.video}")

    video = get_twitch_video_metadata(params.video)
    if video is None:
        print(f"Unable to find video: {params.video}")
        sys.exit(1)

    video_data = adjust_titles(extract_video_title_info(video))

    if params.dl_chats:
        fetch_chat(video_data, params.dryrun)

    if params.dl_video:
        fetch_video(video_data, params.dryrun)

if __name__ == "__main__":
   main(sys.argv[1:])
