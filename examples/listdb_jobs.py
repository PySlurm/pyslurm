def job_display( job ):
    if job:
        for key,value in job.items():
           print ("\t{}={}".format(key, value))
if __name__ == "__main__":
    import pyslurm
    try:
        jobs_dict = pyslurm.slurmdb_jobs().get()
        if len(jobs_dict):
            for key, value in jobs_dict.items():
                print ("{} Job: {}".format('{',key))
                job_display( value)
                print("}")
        else:
            print("No job found")
    except ValueError as e:
        print("Error:{}".format(e.args[0]))

