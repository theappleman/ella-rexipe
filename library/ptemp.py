#!/usr/bin/env python

import os
try:
    import json
except ImportError:
    import simplejson as json

TEMPDIR="/sys/bus/iio/devices/iio:device0/"
msg = {}

with open(os.path.join(TEMPDIR, "in_temp0_raw")) as rawf:
    msg["raw"] = float(rawf.read())

with open(os.path.join(TEMPDIR, "in_temp0_offset")) as offsetf:
    msg["offset"] = float(offsetf.read())

with open(os.path.join(TEMPDIR, "in_temp0_scale")) as scalef:
    msg["scale"] = float(scalef.read())

msg["result"]=((msg["scale"] / 1000.0) * (msg["raw"] + msg["offset"]))

print(json.dumps(msg))
