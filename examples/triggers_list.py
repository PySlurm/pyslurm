#!/usr/bin/env python

from __future__ import print_function

import pyslurm

try:
    a = pyslurm.trigger()
    trig_dict = a.get()
except ValueError as e:
        print("Trigger error - {0}".format(e.args[0]))
else:
    if len(trig_dict) > 0:

        print('{0:*^80}'.format(''))
        for key, value in trig_dict.items():
            print("Trigger ID                : {0}".format(key))
            for part_key in sorted(value.items()):

                if 'res_type' in part_key:
                    print("{0:<25} : {1}".format(part_key, pyslurm.get_trigger_res_type(value[part_key])))
                elif 'trig_type' in part_key:
                    print("{0:<25} : {1}".format(part_key, pyslurm.get_trigger_type(value[part_key])))
                else:
                    print("{0:<25} : {1}".format(part_key, value[part_key]))
            print('{0:*^80}'.format(''))
    else:
        print("No triggers found !")
