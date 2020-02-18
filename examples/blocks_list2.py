#!/usr/bin/env python
"""
Retrieve list of blocked items
"""
from __future__ import print_function

from time import sleep

import pyslurm


class DictDiffer:
    """
    http://stackoverflow.com/questions/1165352/fast-comparison-between-two-python-dictionary

    Calculate the difference between two dictionaries as:
    (1) items added
    (2) items removed
    (3) keys same in both but changed values
    (4) keys same in both and unchanged values
    """

    def __init__(self, current_dict, past_dict):
        """set class attr"""
        self.current_dict, self.past_dict = current_dict, past_dict
        self.set_current, self.set_past = (
            set(current_dict.keys()),
            set(past_dict.keys()),
        )
        self.intersect = self.set_current.intersection(self.set_past)

    def added(self):
        """Check if added"""
        return self.set_current - self.intersect

    def removed(self):
        """Check if removed"""
        return self.set_past - self.intersect

    def changed(self):
        """Check if changed"""
        return set(
            o for o in self.intersect if self.past_dict[o] != self.current_dict[o]
        )

    def unchanged(self):
        """Check for no change"""
        return set(
            o for o in self.intersect if self.past_dict[o] == self.current_dict[o]
        )


if __name__ == "__main__":

    interval = 2
    change = 0

    a = pyslurm.block()
    block_dict = a.get()
    lastUpdate = a.lastUpdate()

    print("Loaded Slurm block data at {0}".format(pyslurm.epoch2date(lastUpdate)))
    print("Waiting for updated data ... polling every {0} second".format(interval))

    sleep(0.5)

    while True:
        new_dict = a.get()
        newUpdate = a.lastUpdate()
        if newUpdate > lastUpdate:

            lastUpdate = a.lastUpdate()
            print(
                "Block data update time changed - {0}".format(
                    pyslurm.epoch2date(lastUpdate)
                )
            )

            b = DictDiffer(block_dict, new_dict)
            if b.changed():
                print("\tChanged block {0}".format(b.changed()))
                change = 1
            if b.added():
                print("\tAdded block {0}".format(b.added()))
                change = 1
            if b.removed():
                print("\tRemoved block {0}".format(b.removed()))
                change = 1
            if change == 0:
                print("\tBut no data was changed !")
            change = 0
            block_dict = new_dict

        sleep(interval)
