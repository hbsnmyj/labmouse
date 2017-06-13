#!/bin/bash

# usage ./resubmit_job.sh <job script path>

export JOBID=$SLURM_JOB_ID
echo $(squeue -o %i,%E -u $USER)
echo $(squeue -o %i,%E -u $USER | egrep "(afterok|afternotok|afterany):$JOBID" | cut -f1 -d",")

echo "RESUBMITTING JOB $1 and update all dependencies"
NEWJOBID=`sbatch --dependency=afterok:$JOBID --begin=now+600 $1 | egrep -o "[0-9]+"`
echo "new job id = $NEWJOBID"
cp $1 "$NEWJOBID.sbatch"

for i in $(squeue -o %i,%E -u $USER | egrep "(afterok|afternotok|afterany):$JOBID" | cut -f1 -d",")
do
    if [ $i -eq $NEWJOBID ]; then
        continue
    fi
    echo "Begin Updating job $i"
    DEPENDENCY_TYPE=$(squeue -o %E -u $USER -j $i -h | egrep "(afterok|afternotok|afterany):$JOBID" | egrep -o "(afterok|afternotok|afterany)")
    echo "Dependency type of $i is $DEPENDENCY_TYPE"
    echo scontrol update JobId=$i TimeLimit=$(squeue -o %l -u $USER -j $i -h) Dependency="$(squeue -o %E -u $USER -j $i -h),$DEPENDENCY_TYPE:$NEWJOBID"
    scontrol update JobId=$i TimeLimit=$(squeue -o %l -u $USER -j $i -h) Dependency="$(squeue -o %E -u $USER -j $i -h),$DEPENDENCY_TYPE:$NEWJOBID"
    scontrol show job $i
    echo "End Updating job $i"
done
