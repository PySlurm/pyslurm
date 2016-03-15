#!/usr/bin/env python

from __future__ import print_function

import pyslurm
import socket
import sys

def controller_up(controller=1):

    try:
        pyslurm.slurm_ping(controller)
    except valueError as e:
        print("Failed - {0}".format(e.args[0]))
    else:
        print("Success")

if __name__ == "__main__":

    print()
    print("PySLURM\t\t{0}".format(pyslurm.version()))
    print("SLURM API\t{0}-{1}-{2}\n".format(*pyslurm.slurm_api_version()))

    host = socket.gethostname()
    print("Checking host.....{0}".format(host))

    try:
        a = pyslurm.is_controller(host)
        print("\tHost is controller ({0})\n".format(a))

        print("Querying SLURM controllers")
        primary, backup = pyslurm.get_controllers()

        print("\tPrimary - {0}".format(primary))
        print("\tBackup  - {0}".format(backup))

        print("\nPinging SLURM controllers")

        if primary:
            print("\tPrimary .....", end=' ')
            controller_up()

        if backup:
            print("\tBackup .....", end=' ')
            controller_up(2)
    except ValueError as e:
        print("Error - {0}".format(e.args[0]))
