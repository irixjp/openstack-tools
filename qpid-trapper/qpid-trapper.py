#!/usr/bin/env python
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#


import optparse
import threading
import time
from qpid.messaging import *
from qpid.util import URL
from qpid.log import enable, DEBUG, WARN

parser = optparse.OptionParser(usage="usage: %prog [options]",
                               description="OpenStack QPID Trapper messages from the supplied address.")

parser.add_option("-b", "--broker", default="localhost",
                  help="connect to specified BROKER (default %default)")
parser.add_option("-r", "--reconnect", action="store_true",
                  help="enable auto reconnect")
parser.add_option("-i", "--reconnect-interval", type="float", default=3,
                  help="interval between reconnect attempts")
parser.add_option("-l", "--reconnect-limit", type="int",
                  help="maximum number of reconnect attempts")

parser.add_option("-p", "--print", dest="format", default="%(M)s",
                  help="format string for printing messages (default %default)")
parser.add_option("-v", dest="verbose", action="store_true",
                  help="enable logging")

#parser.add_option("-N", "--nova", default="nova",
#                  help="exchange(topic) of nova (default %default)")
#parser.add_option("-V", "--volume", default="volume_fanout",
#                  help="exchange(fanout) of nova-volume (default %default)")
#parser.add_option("-S", "--scheduler", default="scheduler_fanout",
#                  help="exchange(fanout) of nova-scheduler (default %default)")
#parser.add_option("-R", "--cert", default="cert_fanout",
#                  help="exchange(fanout) of nova-cert (default %default)")
#parser.add_option("-L", "--console", default="console_fanout",
#                  help="exchange(fanout) of nova-console (default %default)")
#parser.add_option("-A", "--consoleauth", default="consoleauth_fanout",
#                  help="exchange(fanout) of nova-consoleauth (default %default)")
#parser.add_option("-T", "--network", default="network_fanout",
#                  help="exchange(fanout) of nova-network (default %default)")
#parser.add_option("-M", "--compute", default="compute_fanout",
#                  help="exchange(fanout) of nova-compute (default %default)")

opts, args = parser.parse_args()

if opts.verbose:
  enable("qpid", DEBUG)
else:
  enable("qpid", WARN)


class Formatter:
  def __init__(self, message):
    self.message = message
    self.environ = {"M": self.message,
                    "P": self.message.properties,
                    "C": self.message.content}
  def __getitem__(self, st):
    return eval(st, self.environ)


def drain(addr, options):
  print addr + " :drain starting."
  conn = Connection(opts.broker,
             reconnect=opts.reconnect,
             reconnect_interval=opts.reconnect_interval,
             reconnect_limit=opts.reconnect_limit)
  conn.open()
  ssn = conn.session()
  rcv = ssn.receiver(addr + options)

  while True:
    try:
      msg = rcv.fetch(timeout=30)
      print addr + ": " + opts.format % Formatter(msg)
      ssn.acknowledge()

    except Empty:
      pass

exchanges=["nova",
           "compute_fanout",
           "cert_fanout",
           "console_fanout",
           "consoleauth_fanout",
           "network_fanout",
           "volume_fanout",
           "scheduler_fanout", ]

try:
  for exchange in exchanges:
    threads = []
    t = threading.Thread(target=drain, args=(exchange, ";{mode:browse}" ,))
    t.setDaemon(True)
    threads.append(t)
    t.start()  

  while True:
    time.sleep(10)

except ReceiverError, e:
  print e
except KeyboardInterrupt:
  pass

