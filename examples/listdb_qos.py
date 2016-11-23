
if __name__ == "__main__":
    import pyslurm
    try:
        qos_dict = pyslurm.qos().get()
        if len(qos_dict):
            for key, value in qos_dict.items():
                print ("{},{}".format(key, value))
        else:
            print("No QOS found")
    except ValueError as e:
        print("Error:{}".format(e.args[0]))

