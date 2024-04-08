#!/usr/bin/gawk -f

# takes a column of values
# prints the standard deviation

BEGIN {r=0}

{
n+=1;
sum+=$1;
sumsqr+=$1*$1;
}

END {
    numer = (sumsqr - (sum * sum/n));
    denom = n - 1;
    #printf "%1.3f\n", sumsqr;
    #printf "%1.3f\n", sum;
    #printf "%1.3f\n", n;
    #printf "%1.3f\n", numer;
    #printf "%1.3f\n", denom;
    print sqrt(numer/denom); 
}
