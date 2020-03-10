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
                    print("\t{}=".format(key))
                    for k, v in value.items():
                        print("\t\t{}={}".format(k, v))
                else:
                    print("\t{}={}".format(key, value))
                print("}")
        else:
            print("No QOS found")
    except ValueError as qos_exception:
        print("Error:{}".format(qos_exception.args[0]))
