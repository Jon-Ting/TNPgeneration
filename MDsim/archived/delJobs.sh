# Delete all jobs in PBS
qstat | awk '
    {
        if (NR > 2) {
            cmd = "qdel " $1
            system(cmd)
            print $1, "has been deleted!"
        }
    }
'
