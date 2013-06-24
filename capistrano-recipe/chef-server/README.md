Description
===========
Install Chef Server to single node(localhost or remote host)

Requirements
============
This recipe need internet connection.
I tested on CentOS6.3(x64)

Attributes
==========

Usage
=====
If you want to install Chef-server to localhost.

`cap localhost setup_chef_server`

When you want to install to remote host.
Edit *config/deploy/single-node.rb* and change server hostname.

`cap single-node setup_chef_server`

At last, edit */etc/chef/server.rb* to change from localhost to FQDN.

`chef_server_url "http://127.0.0.1:4000"`

