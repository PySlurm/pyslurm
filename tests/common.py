# -*- coding: utf-8 -*-
import subprocess

def scontrol_show(subcommand, *args):
    """Return output of 'scontrol show <subcommand>'"""
    if args:
        extra_args = " ".join(args)
    else:
        extra_args = ""

    sctl = subprocess.Popen(
        ["scontrol", "-d", "show", subcommand, extra_args],
        stdout=subprocess.PIPE
    ).communicate()

    sctl_stdout = sctl[0].strip().decode("UTF-8", "replace").split()
    sctl_dict = dict((value.split("=")[0], value.split("=")[1])
                     for value in sctl_stdout)

    return sctl_dict
