#!/usr/bin/env python
"""
Retrieve list up Slurm controllers
"""

import socket
import pyslurm


def controller_up(controller=0):
    """Check if controller up via ping"""
    try:
        pyslurm.slurm_ping(controller)
    except ValueError as ping_error:
        print(f"Failed - {ping_error.args[0]}")
    else:
        print("Success")


if __name__ == "__main__":

    print()
    print(f"PySLURM\t\t{pyslurm.version()}")
    major, minor, micro = pyslurm.slurm_api_version()
    print(f"SLURM API\t{major}-{minor}-{micro}\n")

    host = socket.gethostname()
    print(f"Checking host.....{host}")

    try:
        a = pyslurm.is_controller(host)
        print(f"\tHost is controller ({a})\n")

        print("Querying SLURM controllers")
        control_machs = pyslurm.get_controllers()

        X = 0
        for machine in control_machs:
            if X == 0:
                print(f"\tPrimary - {machine}")
                print("\t\tPing .....", end=" ")
                controller_up()
            else:
                print(f"\tBackup{X}  - {machine}")
                print("\t\tPing .....", end=" ")
                controller_up(X)
            X = X + 1

    except ValueError as value_error:
        print(f"Error - {value_error.args[0]}")
