#!/usr/bin/env python

import pyslurm

if __name__ == "__main__":
    try:
        qos_dict = pyslurm.qos().get()
        if len(qos_dict):
            for key, value in qos_dict.items():
                print("{")
                if type(value) is dict:
                    print("\t{}=".format(key))
                    for k, v in value.items():
                        print("\t\t{}={}".format(k, v))
                else:
                    print("\t{}={}".format(key, value))
                print("}")
        else:
            print("No QOS found")
    except ValueError as e:
        print("Error:{}".format(e.args[0]))

