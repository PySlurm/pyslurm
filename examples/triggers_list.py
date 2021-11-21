#!/usr/bin/env python
"""
List triggers
"""

import pyslurm

try:
    a = pyslurm.trigger()
    trig_dict = a.get()
except ValueError as value_error:
    print(f"Trigger error - {value_error.args[0]}")
else:
    if trig_dict:

        print(f"{'':*^80}")
        for key, value in trig_dict.items():
            print(f"Trigger ID                : {key}")
            for part_key in sorted(value.items()):

                res_type = pyslurm.get_trigger_res_type(value[part_key])
                if "res_type" in part_key:
                    print(f"{part_key:<25} : {res_type}")
                elif "trig_type" in part_key:
                    print(f"{part_key:<25} : {res_type}")
                else:
                    print(f"{part_key:<25} : {value[part_key]}")
            print(f"{'':*^80}")
    else:
        print("No triggers found !")
