#!/usr/bin/env python

import subprocess
import json

space = []

df = subprocess.Popen(["df", "-i"], stdout=subprocess.PIPE)
output = df.communicate()[0]

for line in output.split("\n")[1:]:
    if len(line):
        try:
            device, size, used, available, percent, mountpoint = line.split()
            space.append(
                dict(
                    mountpoint=mountpoint,
                    available=available,
                    percent=percent,
                    size=size,
                )
            )
        except:
            pass

print(json.dumps(dict(inodes=space), indent=4))
