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

import os, textwrap, getopt, sys, subprocess, ujson
from dateutil.parser import parse as dateparser
from prettytable import PrettyTable

def print_usage(msg = None):
    scriptname = os.path.basename(sys.argv[0])
    usage = textwrap.dedent("""\
            Fetches chat (html+json) and video of specified video id.
            Usage: {script} [-n | -x] <video>
                            
            -n : Do not download chats
            -x : Do not download video

            e.g.
              {script} 12345
            
            Will fetch from https://twitch.tv/video/12345
        """.format(script = scriptname))
    
    if not msg is None:
       print(msg)
       print()
    print(usage)

def parse_options(argv):
    results = lambda : None
    results.dl_chats = True
    results.dl_video = True
    try:
        opts, args = getopt.getopt(argv,"h?nx")
    except getopt.GetoptError as e:
        print_usage(e.msg)
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-h", "-?"):
            print_usage()
            sys.exit()
        elif opt == "-n":
            results.dl_chats = False
        elif opt == "-x":
            results.dl_video = False

    results.video = args[0] if args else None
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
        entry.channel = video["user_name"]
        entry.duration = video["duration"]
        results.append(entry)

    return results[0] if results[0] else None

def adjust_titles(metadata):
    if metadata.channel.lower() == "GigaohmBiological".lower():
        metadata.title = metadata.title.replace("Gigaohm Biological High Resistance Low Noise Information ", "")

    return metadata

def fetch_chat(metadata):
    title = f"{metadata.id} [Chat] - {metadata.title} [{metadata.channel} - {metadata.date}]"

    print(f"Fetching HTML chat for video {metadata.id} as: {title}.html")
    os.system(f"twitchdownloadercli chatdownload -u {metadata.id} -o \"{title}.html\" -E")

    print(f"Fetching JSON chat for video {metadata.id} as: {title}.json")
    os.system(f"twitchdownloadercli chatdownload -u {metadata.id} -o \"{title}.json\" -E")

def fetch_video(metadata):
    title = f"{metadata.id} - {metadata.title} [{metadata.channel} - {metadata.date}]"

    print(f"Fetching video {metadata.id}")
    os.system(f"twitchdownloadercli videodownload -u {metadata.id} -o \"{title}.mp4\"")

def main(argv):
    params = parse_options(argv)

    if params.video is None:
        print_usage("video id is a required parameter")
        sys.exit(1)

    print(f"Fetching https://twitch.tv/video/{params.video}")

    video = get_twitch_video_metadata(params.video)
    if video is None:
        print(f"Unable to find video: {params.video}")
        sys.exit(1)

    video_data = adjust_titles(extract_video_title_info(video))

    if params.dl_chats:
        fetch_chat(video_data)

    if params.dl_video:
        fetch_video(video_data)

if __name__ == "__main__":
   main(sys.argv[1:])
