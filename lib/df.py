#!/usr/bin/env python

import subprocess
import json

space = []

df = subprocess.Popen(["df", "-P", "-k"], stdout=subprocess.PIPE)
output = df.communicate()[0]

for line in output.split("\n")[1:]:
    if len(line):
        try:
            device, size, used, available, percent, mountpoint = line.split()
            space.append(
                dict(
                    mountpoint=mountpoint,
                    available=available,
                    size=size,
                    percent=percent,
                )
            )
        except:
            pass

print(json.dumps(dict(space=space), indent=4))
