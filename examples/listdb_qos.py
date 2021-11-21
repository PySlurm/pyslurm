#!/usr/bin/env python
"""
List Slurm QOS
"""
import pyslurm

if __name__ == "__main__":
    try:
        qosDict = pyslurm.qos().get()
        if qosDict:
            for key, value in qosDict.items():
                print("{")
                if isinstance(value, dict):
                    print(f"\t{key}=")
                    for k, v in value.items():
                        print(f"\t\t{k}={v}")
                else:
                    print("\t{key}={value}")
                print("}")
        else:
            print("No QOS found")
    except ValueError as qos_exception:
        print(f"Error:{qos_exception.args[0]}")
