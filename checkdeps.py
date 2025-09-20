#!/usr/bin/env python3
import subprocess

deps = set()

# Get info on all installed packages
out = subprocess.run(["pacman", "-Qq"], capture_output=True, text=True, check=True)
packages = out.stdout.splitlines()

# Query detailed info
out = subprocess.run(["pacman", "-Qi"], capture_output=True, text=True, check=True)

for line in out.stdout.splitlines():
    if line.startswith("Depends On"):
        parts = line.split(":", 1)[1].strip().split()
        if parts == ['None']:
            continue
        for dep in parts:
            dep = dep.split("<")[0].split(">")[0].split("=")[0]  # strip version constraints
            if dep.endswith(".so"):
                dep = dep[:-3]
            deps.add(dep)

for i in deps:
    if i not in packages:
        print(i)
