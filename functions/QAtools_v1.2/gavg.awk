#!/usr/bin/gawk -f

# takes a column of values
# prints the average

BEGIN {r=0}

{
n+=1;
sum+=$1;
}

END {
    print sum/n; 
}
