#!/usr/bin/env python

# Merges 2 Twitch chat json files together into 1.
# Usage:
# command file1 file2 ... output_file

import sys, os, ujson
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("files",nargs="+")
args = parser.parse_args()

# print(args.files)
# print(type(args.files))

source = args.files[0]
merges = args.files[1:-1]
target = args.files[-1:][0]

print("src:", source, type(source))
print("merging:", merges, type(merges))
print("dest:", target, type(target))

def merge_embedded(target_data, source_data, party):
    party_data = target_data["embeddedData"][party]
    merge_party = source_data["embeddedData"][party]
    for item in merge_party:
        if not any(x for x in party_data if x["id"] == item["id"]):
            party_data.append(item)

def merge_badges(target_data, source_data):
    party_data = target_data["embeddedData"]["twitchBadges"]
    merge_party = source_data["embeddedData"]["twitchBadges"]
    for item in merge_party:
        if not any(x for x in party_data if x["name"] == item["name"]):
            party_data.append(item)

target_file = open(target, "w", encoding="UTF-8")

source_file = open(source, "r", encoding="UTF-8")
data = ujson.load(source_file)
source_file.close()

twitchIds = []
twitchIds.append(data["video"]["id"])

currentLength = data["video"]["length"]
currentViewCount = data["video"]["viewCount"]

print("twitchIds", twitchIds, type(twitchIds))
print("currentLength", currentLength, type(currentLength))
print("currentViewCount", currentViewCount, type(currentViewCount))

for merge in merges:
    print("Processing: ", merge)
    merge_file = open(merge, "r", encoding="UTF-8")
    merge_data = ujson.load(merge_file)
    merge_file.close()

    comments = merge_data["comments"]
    for comment in comments:
        comment["content_offset_seconds"] += currentLength

    data["comments"] += comments
    merge_embedded(data, merge_data, "thirdParty")
    merge_embedded(data, merge_data, "firstParty")
    merge_badges(data, merge_data)

    twitchIds.append(merge_data["video"]["id"])
    currentLength += merge_data["video"]["length"]
    currentViewCount += merge_data["video"]["viewCount"]
    print("twitchIds", twitchIds, type(twitchIds))
    print("currentLength", currentLength, type(currentLength), "added", merge_data["video"]["length"])
    print("currentViewCount", currentViewCount, type(currentViewCount))

    data["video"]["id"] = ','.join(twitchIds)
    data["video"]["end"] = currentLength
    data["video"]["length"] = currentLength
    data["video"]["viewCount"] = currentViewCount

target_file.write(ujson.dumps(data))
target_file.close()

