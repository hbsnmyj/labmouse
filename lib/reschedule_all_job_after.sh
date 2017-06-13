#!/bin/bash
export JOBID=$SLURM_JOB_ID
echo $(squeue -o %i,%E -u $USER)
echo $(squeue -o %i,%E -u $USER| egrep "(afterok|after|afterany):$JOBID")
echo "####"
for i in $(squeue -o %i,%E -u $USER | egrep "(afterok|after|afterany):$JOBID" | cut -f1 -d",")
do
    echo "Updating job $i"
    echo scontrol update JobId=$i StartTime=now+$1 TimeLimit=$(squeue -o %l -u $USER -j $JOBID -h)
    scontrol update JobId=$i StartTime=now+$1 TimeLimit=$(squeue -o %l -u $USER -j $i -h)
    echo "End Updating job $i"
done
