#!/usr/bin/env python

import time as tm
import sys
#import datetime 
from datetime import datetime

def format_seconds_to_dayhhmmss(seconds):
    days = seconds // (60*60*24)
    seconds %= (60*60*24)
    hours = seconds // (60*60)
    seconds %= (60*60)
    minutes = seconds // 60
    seconds %= 60
    if days > 0 :
        return "%3i days %02i:%02i:%02i" % (days, hours, minutes, seconds)
    else:
        return "%02i:%02i:%02i" % (hours, minutes, seconds)
    
def event_display(event):
    if event:
        for key,value in event.items():
           if (key == "time_start") or (key == "time_end") :
               print ("\t{}={}  <->  {}".format(key, value, datetime.fromtimestamp(value)))
           else :
               print ("\t{}={}".format(key, value))

if __name__ == "__main__":
    import pyslurm
    try:
        if len(sys.argv) < 3 :
            print("you must give start-tme and end-time as arguments( format: yyyy-dd-mm )")
            exit(0)
        else :
            dayStart = str(sys.argv[1]).split("-")
            dayEnd   = str(sys.argv[2]).split("-")
            print(dayStart)
        
        epoch = datetime(1970,1,1)
        start = (datetime(int(dayStart[0]),int(dayStart[1]),int(dayStart[2])) - epoch).total_seconds()
        end = (datetime(int(dayEnd[0]),int(dayEnd[1]),int(dayEnd[2])) - epoch).total_seconds() - 1
        print "start={}, end={}".format(start, end)
        events = pyslurm.slurmdb_events()
        events.set_event_condition(start, end)
        events_dict = events.get()
        if len(events_dict):
            for key, value in events_dict.items():
                d = int(value['time_end']) - int(value['time_start'])
                print("duration: {}".format(format_seconds_to_dayhhmmss(d)))
                print("}")
                event_display(value)
                print("}")
        else:
            print("No event found")
    except ValueError as e:
        print("Error:{}".format(e.args[0]))

