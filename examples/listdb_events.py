#!/usr/bin/env python
"""
List Slurm events
"""
import sys
import time
from datetime import datetime

import pyslurm


def event_display(event):
    """Format output"""
    for key, value in event.items():
        if (key == "time_start") or (key == "time_end"):
            print("\t{}={}  <->  {}".format(key, value, datetime.fromtimestamp(value)))
        else:
            print("\t{}={}".format(key, value))


if __name__ == "__main__":
    try:
        if len(sys.argv) != 3:
            print("usage: python listdb_events.py start-tme end-time")
            print("(format: yyyy-mm-dd)")
            sys.exit(1)

        start = time.mktime(time.strptime(sys.argv[1], "%Y-%m-%d"))
        end = time.mktime(time.strptime(sys.argv[2], "%Y-%m-%d"))
        print("start={}, end={}".format(start, end))

        events = pyslurm.slurmdb_events()
        events.set_event_condition(start, end)
        events_dict = events.get()
        ii = 0
        if events_dict:
            for key, value in events_dict.items():
                d = int(value["time_end"]) - int(value["time_start"])
                ii += 1
                print("{")
                event_display(value)
                print("}")
        else:
            print("No event found")
    except ValueError as value_error:
        print("Error:{}".format(value_error.args[0]))
