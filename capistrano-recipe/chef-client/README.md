Description
===========
Install Chef Client to single node(localhost or remote host)

Requirements
============
This recipe need internet connection.
I tested on CentOS6.3(x64)

Attributes
==========
config/default.rb




Usage
=====
If you want to install Chef-client to localhost.

`cap localhost setup_chef_client`

When you want to install to remote host.
Edit *config/deploy/single-node.rb* and change server hostname.

`cap single-node setup_chef_server`


