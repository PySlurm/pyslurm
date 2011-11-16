import pyslurm

Node_dict = {
		'node_names': 'makalu',
		'state': 0x0100,
		'reason': 'API test'
	}

rc = pyslurm.slurm_update_node(Node_dict)
if rc == -1:
	print "Error : %s" % pyslurm.slurm_strerror(pyslurm.slurm_get_errno())
elif rc == 0:
	print "Node %s successfully updated" % Node_dict["node_names"]

