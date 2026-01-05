#!/usr/bin/env python3

import time

def read():
    with open("/proc/stat") as f:
        v = list(map(int, f.readline().split()[1:8]))
    return v, sum(v)

a, ta = read()
time.sleep(0.5)
b, tb = read()

diowait = b[4] - a[4]
dtotal  = tb - ta

print(f"{(diowait / dtotal * 100):.0f}" if dtotal else "0")
