#!/usr/bin/env python

import os
import portage

try:
    import json
except ImportError:
    import simplejson as json

message = {}

try:
    v = portage.vartree().dbapi

    message["udev"] = v.match("sys-fs/udev")
    message["systemd"] = v.match("sys-apps/systemd")
    message["failed"] = len(message["udev"]) == 1 and len(message["systemd"]) == 0

    message["installed"] = len(v.vartree.getallnodes())

except Exception as exc:
    message = dict(
        failed=True,
        msg=str(exc),
    )
finally:
    print(json.dumps(message))
