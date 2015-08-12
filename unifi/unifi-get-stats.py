#!/usr/bin/env python
#
# Get stats from a Unifi AP controller using the API
#
# Requires the unifi python module
#

import argparse
import json

from unifi.controller import Controller

parser = argparse.ArgumentParser()
parser.add_argument('-c', '--controller', default='unifi', help='the controller address (default "unifi")')
parser.add_argument('-u', '--username', default='admin', help='the controller username (default("admin")')
parser.add_argument('-p', '--password', default='', help='the controller password')
parser.add_argument('-b', '--port', default='8443', help='the controller port (default "8443")')
parser.add_argument('-v', '--version', default='v2', help='the controller base version (default "v2")')
parser.add_argument('-s', '--siteid', default='default', help='the site ID, UniFi >=3.x only (default "default")')
args = parser.parse_args()

c = Controller(args.controller, args.username, args.password, args.version, args.siteid)

aps = c.get_aps()
total = guests = users = rx = tx = 0
data = dict(all=1)

for ap in aps:
    data[ap['name']] = dict(uptime=ap['uptime'], total=ap['num_sta'], guests=ap['guest-num_sta'], users=ap['user-num_sta'],
                            tx=ap['stat']['tx_bytes'], rx=ap['stat']['rx_bytes'])
    total += ap['num_sta']
    guests += ap['guest-num_sta']
    users += ap['user-num_sta']
    rx += ap['stat']['rx_bytes']
    tx += ap['stat']['tx_bytes']

data["all"] = dict( total=total, guests=guests, users=users, rx=rx, tx=tx )
print json.dumps(data)
