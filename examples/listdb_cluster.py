import time as tm
def cluster_display( cluster ):
    if cluster:
        for key,value in cluster.items():
           print ("\t{}={}".format(key, value))

if __name__ == "__main__":
    import pyslurm
    try:
        end = tm.time()
        start = end - (30*24*60*60)
        print "start={}, end={}".format(start,end)
        clusters = pyslurm.slurmdb_clusters()
        print clusters.set_cluster_condition(start,end)
        clusters_dict = clusters.get()
        if len(clusters_dict):
            for key, value in clusters_dict.items():
                print ("{} Clusters: {}".format('{',key))
                cluster_display( value)
                print("}")
        else:
            print("No cluster found")
    except ValueError as e:
        print("Error:{}".format(e.args[0]))

