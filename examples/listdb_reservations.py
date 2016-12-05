import time as tm
from datetime import datetime
def reservation_display(reservation):
    if reservation:
        for key,value in reservation.items():
           print ("\t{}={}".format(key, value))

if __name__ == "__main__":
    import pyslurm
    try:
        epoch = datetime(1970,1,1)
        start = (datetime(2016,12,5) - epoch).total_seconds()
        end = (datetime(2016,12,6) - epoch).total_seconds() - 1
        print "start={}, end={}".format(start, end)
        reservations = pyslurm.slurmdb_reservations()
        reservations.set_reservation_condition(start, end)
        reservations_dict = reservations.get()
        if len(reservations_dict):
            for key, value in reservations_dict.items():
                print ("{} Job: {}".format('{', key))
                reservation_display(value)
                print("}")
        else:
            print("No reservation found")
    except ValueError as e:
        print("Error:{}".format(e.args[0]))

