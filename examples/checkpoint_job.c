#include<stdio.h>
#include <slurm/slurm.h>

main(int argc, char* argv[])
{
 	int jobID = atoi(argv[1]);
	int stepID = 0;
	int err = 0;
	time_t startTime = 0;
	
	err =  slurm_checkpoint_able ( jobID, stepID, &startTime);
	printf ("Err is %d\n",err);
					 
}