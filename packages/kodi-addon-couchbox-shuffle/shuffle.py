"""Shuffle a TV show's or season's episodes from the library context menu.

Kodi runs this with the focused list item in sys.listitem and the entry's
args in sys.argv: "one" plays a single random episode, "all" queues every
episode in random order. The episodes come from Kodi's own video library
(which the Jellyfin add-on keeps in sync). For "all" they are shuffled here
and queued in that order, so Kodi's playlist shuffle stays off and the queue
shows the order that will play. Multi-part stories stay together and in
order (see story_groups).
"""
import json
import random
import re
import sys

import xbmc
import xbmcgui

VIDEO_PLAYLIST = 1


def rpc(method, **params):
    request = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
    response = json.loads(xbmc.executeJSONRPC(json.dumps(request)))
    if "error" in response:
        raise RuntimeError("{}: {}".format(method, response["error"].get("message")))
    return response["result"]


EPISODE_PROPERTIES = ["season", "episode", "title"]

_NUMBERS = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "i": 1, "ii": 2, "iii": 3, "iv": 4, "v": 5}
_PART = r"(?P<n>\d+|one|two|three|four|five|i{1,3}|iv|v)"
# "Title (2)", "Title (Part 2)", "Title, Part Two", "Title - Pt. 2", "Title: Part II",
# "Title II" (a bare Roman numeral)
_PART_PATTERNS = [
    re.compile(r"^(?P<base>.+?)[\s,:-]*\(\s*(?:part\s*|pt\.?\s*)?" + _PART + r"\s*\)$", re.IGNORECASE),
    re.compile(r"^(?P<base>.+?)[\s,:-]+(?:part|pt\.?)\s*" + _PART + r"$", re.IGNORECASE),
    re.compile(r"^(?P<base>.+?)\s+(?P<n>I{1,3}|IV|V)$"),
]


def part_of(title):
    """(base title, part number) for a title that names its part, else None."""
    title = (title or "").strip()
    for pattern in _PART_PATTERNS:
        match = pattern.match(title)
        if match:
            return match.group("base").strip(" ,:-").casefold(), _NUMBERS.get(match.group("n").lower()) or int(match.group("n"))
    return None


def story_groups(episodes):
    """Split episodes into stories: runs of consecutive episodes in one season
    whose titles mark them as parts 1, 2, ... of the same title (part 1 may be
    unmarked, as in "Title" then "Title (2)"). Every other episode is a story
    of its own. Groups keep airing order."""
    groups = []
    previous = None  # (episode, base, part) of the last episode placed
    for episode in sorted(episodes, key=lambda e: (e["season"], e["episode"])):
        part = part_of(episode["title"])
        joins = False
        if part and previous:
            prev_episode, prev_base, prev_part = previous
            consecutive = prev_episode["season"] == episode["season"] and prev_episode["episode"] + 1 == episode["episode"]
            same_story = prev_base == part[0] and part[1] == (prev_part or 1) + 1
            joins = consecutive and same_story
        if joins:
            groups[-1].append(episode)
        else:
            groups.append([episode])
        if part:
            previous = (episode, part[0], part[1])
        else:
            previous = (episode, (episode["title"] or "").strip().casefold(), None)
    return groups


def episodes_for(dbtype, dbid):
    """Episodes of a show (without specials, unless that is all it has) or of
    one season."""
    if dbtype == "season":
        season = rpc("VideoLibrary.GetSeasonDetails", seasonid=dbid, properties=["tvshowid", "season"])
        details = season["seasondetails"]
        result = rpc(
            "VideoLibrary.GetEpisodes",
            tvshowid=details["tvshowid"],
            season=details["season"],
            properties=EPISODE_PROPERTIES,
        )
        return result.get("episodes", [])
    result = rpc("VideoLibrary.GetEpisodes", tvshowid=dbid, properties=EPISODE_PROPERTIES)
    episodes = result.get("episodes", [])
    regular = [e for e in episodes if e["season"] != 0]
    return regular or episodes


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"
    tag = sys.listitem.getVideoInfoTag()
    dbtype, dbid = tag.getMediaType(), tag.getDbId()
    if dbtype not in ("tvshow", "season") or dbid <= 0:
        return
    episodes = episodes_for(dbtype, dbid)
    if not episodes:
        xbmcgui.Dialog().notification("Shuffle", "No episodes in the library", xbmcgui.NOTIFICATION_INFO)
        return
    if mode == "one":
        rpc("Player.Open", item={"episodeid": random.choice(episodes)["episodeid"]})
        return
    groups = story_groups(episodes)
    random.shuffle(groups)
    queue = [{"episodeid": e["episodeid"]} for group in groups for e in group]
    rpc("Playlist.Clear", playlistid=VIDEO_PLAYLIST)
    rpc("Playlist.Add", playlistid=VIDEO_PLAYLIST, item=queue)
    rpc("Player.Open", item={"playlistid": VIDEO_PLAYLIST, "position": 0}, options={"shuffled": False})


if __name__ == "__main__":
    main()
