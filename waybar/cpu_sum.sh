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

# Append per-core frequencies: use /sys cpufreq when available, fallback to /proc/cpuinfo
i=0
while [ "$i" -lt "$n" ]; do
    path="/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_cur_freq"
    if [ -r "$path" ]; then
        val=$(cat "$path" 2>/dev/null)
        # scaling_cur_freq is in kHz; convert to MHz (rounded)
        mhz=$(awk -v v="$val" 'BEGIN{printf "%d", (v/1000)+0.5}')
    else
        mhz=$(awk -v cpu="$i" 'BEGIN{p=-1}
            /^processor[[:space:]]*:/ {p=$3}
            /^cpu MHz[[:space:]]*:/ && p==cpu {printf "%d", $4+0.5; exit}
            END{if(p!=cpu) print "0"}' /proc/cpuinfo)
    fi
    if [ -z "$mhz" ]; then mhz=0; fi
    if [ ! "$i" -lt "1" ]; then
        echo -n " | "
    fi
    if [ "$mhz" -ge 1000 ]; then
        ghz=$(awk -v m="$mhz" 'BEGIN{printf "%.2f", m/1000}')
        echo -n "$i: $ghz GHz"
    else
        echo -n "$i: $mhz MHz"
    fi
    i=$((i+1))
done

