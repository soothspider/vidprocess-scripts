#!/usr/bin/env python

# ---
# Using twitch-cli, generates list of videos for a channel/user_id.
#
# Requires twitch-cli
#
# Usage: list_twitch_videos.py [-c <count>] <login>
#
# Will fetch the last <count> videos for a given <login> user.
# ---

default_count=5

import os, textwrap, getopt, sys, subprocess, ujson
from dateutil.parser import parse as dateparser
from prettytable import PrettyTable

def print_usage(msg = None):
    scriptname = os.path.basename(sys.argv[0])
    usage = textwrap.dedent("""\
            Fetches list of videos from twitch for a given user login.
            Usage: {script} [-c <count>] login

            <count> defaults to 5

            e.g.
              {script} gigaohmbiological
              {script} -c 1 gigaohmbiological
        """.format(script = scriptname))
    
    if not msg is None:
       print(msg)
       print()
    print(usage)

def parse_options(argv):
    results = lambda : None
    results.count = default_count
    try:
        opts, args = getopt.getopt(argv,"h?c:")
    except getopt.GetoptError as e:
        print_usage(e.msg)
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-h", "-?"):
            print_usage()
            sys.exit()
        elif opt in ("-c", "--count"):
            results.count = arg
    results.login = args[0] if args else None
    return results

def get_twitch_user(login):
    results = subprocess.getoutput("twitch api get users -q login={}".format(login))
    return results

def extract_userid(data):
    user_data = None
    try:
        user_data = ujson.loads(data)
    except ujson.JSONDecodeError as e:
            sys.stderr.write("Error parsing results: {}".format(e.msg))
    return user_data["data"][0]["id"] if user_data and user_data["data"] and user_data["data"][0] else None

def get_twitch_videos(user_id, count):
    results = subprocess.getoutput("twitch api get videos -q user_id={id} -q first={num}".format(id = user_id, num = count))
    return results

def extract_video_results(data):
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

    return results

def print_video_results(videos):
    table = PrettyTable(['id', 'date', 'title', 'channel', 'duration'])
    table.align["title"] = "l"
    for v in videos:
        table.add_row([v.id, v.date, v.title, v.channel, v.duration])
    print(table)

def main(argv):
    params = parse_options(argv)

    if params.login is None:
        print_usage("login is a required parameter")
        sys.exit(1)

    print("Fetching the last {} videos for logins: {}".format(params.count, params.login))

    userId = extract_userid(get_twitch_user(params.login))
    if userId is None:
        print("Unable to find user: {}".format(params.login))
        sys.exit(1)

    print_video_results(extract_video_results(get_twitch_videos(userId, params.count)))

if __name__ == "__main__":
   main(sys.argv[1:])
