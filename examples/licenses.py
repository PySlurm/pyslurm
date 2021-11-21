#!/usr/bin/env python
"""
List Slurm licenses
"""


def display(lic_dict):
    """Format output"""
    if lic_dict:
        license_date = slurm.epoch2date(licenses.lastUpdate())
        print(f"State last updated : {license_date}")
        print(f"{'':*^80}")

        for key, value in lic_dict.items():

            print(f"{key} :")
            for part_key in sorted(value.keys()):
                print(f"\t{part_key:<17} : {value[part_key]}")

            print(f"{'':*^80}")
    else:
        print("No Licenses found !")


if __name__ == "__main__":

    import pyslurm as slurm
    import sys
    import time

    try:
        licenses = slurm.licenses()
        lic = licenses.get()
        old = licenses.lastUpdate()

        new = old
        display(lic)

        while True:
            time.sleep(1)
            lic = licenses.get()
            new = licenses.lastUpdate()
            if new > old:
                old = new
                print(f"{'':*^80}")
                display(lic)
                print(f"{'':*^80}")
    except ValueError as value_error:
        print(f"License error : {value_error.args[0]}")
        sys.exit(-1)
    except KeyboardInterrupt:
        print("Exiting....")
        sys.exit()
