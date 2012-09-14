cc1: 192.168.128.100
  keystone-all
  glance-api
  glance-registry
  swift-all
  nova-api
  nova-scheduler
  nova-cert
  nova-console
  nova-consoleauth
  nova-xvpvncproxy
  nova-novncproxy

compute1: 192.168.128.111
  nova-compute
  nova-network

compute2: 192.168.128.112
  nova-compute
  nova-network

volume1: 192.168.128.121
  nova-volume

volume2: 192.168.128.122
  nova-volume

