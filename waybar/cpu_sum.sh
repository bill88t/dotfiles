#!/bin/sh
n=$(nproc)

read total0 idle0 < <(
  awk '/^cpu /{idle=$5+$6; for(i=2;i<=NF;i++) t+=$i; print t, idle}' /proc/stat
)
sleep 0.12
read total1 idle1 < <(
  awk '/^cpu /{idle=$5+$6; for(i=2;i<=NF;i++) t+=$i; print t, idle}' /proc/stat
)

percent=$(awk -v t0="$total0" -v i0="$idle0" -v t1="$total1" -v i1="$idle1" -v n="$n" \
  'BEGIN{
     dt = t1 - t0; di = i1 - i0; used = dt - di;
     if (dt > 0) printf("%d", int((used/dt*100*n)+0.5));
     else print 0;
  }')

printf "C %s%%\n" "$percent"
